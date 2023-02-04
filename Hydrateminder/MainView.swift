//
//  MainView.swift
//  Hydrateminder
//
//  Created by Justin Allen on 2/3/23.
//

import SwiftUI
import CoreData

struct ProgressCircle: View {
    
    var Percentage: Double
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width: CGFloat = min(geometry.size.width, geometry.size.height)
                let height = width
                
                let center = CGPoint(x: width * 0.5, y: height * 0.5)
                
                path.move(to: center)
                
                path.addArc(
                    center: center,
                    radius: width * 0.5,
                    startAngle: Angle(degrees: -90.0) + Angle(degrees: 0),
                    endAngle: Angle(degrees: -90.0) + Angle(degrees: Percentage / 100.0 * 360),
                    clockwise: false)
                
            }
            .fill(.teal)
            
            Circle()
                .fill(.background)
                .padding(48)
                .frame(width: min(geometry.size.width, geometry.size.height), height: min(geometry.size.width, geometry.size.height))
            
            Image(systemName: "drop")
                .font(.system(size: 72))
                .foregroundColor(.teal)
//                .resizable()
                .padding(96)
                .frame(width: min(geometry.size.width, geometry.size.height), height: min(geometry.size.width, geometry.size.height))
                
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(48)
    }
}

struct LogConsumed: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var AmountToAdd: Double = 0
    var ConsumptionEntryForToday: Consumption?
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Slider(value: $AmountToAdd, in: 0...8, step: 1.0) {
                    Text("Amount")
                } minimumValueLabel: {
                    Text("0oz")
                } maximumValueLabel: {
                    Text("8oz")
                }
                .padding()
                
                Spacer()

                Button {
//                    ShowAddConsumed = true
                    
                    if let today = ConsumptionEntryForToday {
                        today.consumed = today.consumed + AmountToAdd
                    }
                    else {
                        let todays = Consumption(context: viewContext)
                        todays.consumed = AmountToAdd
                        todays.goal = 64
                        todays.date = .now.startOfDay
                    }
                    
                    do {
                        try viewContext.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                    
                    dismiss()
             
                } label: {
                    HStack {
                        Text("Log \(AmountToAdd.formatted(.number)) \(AmountToAdd == 1 ? "ounce" : "ounces")")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(AmountToAdd == 0)
                .frame(maxWidth: .infinity)
                .padding()
                
            }
            .navigationTitle("Log Consumption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                    
                }
            }
        }
        
        
    }
}

struct HistoryLogView: View {
    
    
    @Environment(\.managedObjectContext) private var viewContext
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Consumption.date, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Consumption>
    
    
    var body: some View {
        
        List {
            
            ForEach(items) { item in
                 
                // if is today, don't show
                
                
                Text("\(item.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Date") \(item.consumed.formatted(.number)) ounces / \(item.goal.formatted(.number)) ounces")
            }
            
            
        }
    }
}

struct SettingsView: View {
    var body: some View {
        
        List {
            Text("Settings View Coming soon.")
        }
        
        
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date!
    }
    
    var endOfWeek: Date {
        var components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek)!
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components)!
    }
    
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }
}

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var ShowAddConsumed: Bool = false
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Consumption.date, ascending: true)
        ],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)", argumentArray: [Date.now.startOfDay, Date.now.endOfDay]),
        animation: .default)
    private var items: FetchedResults<Consumption>
    
    var ConsumptionEntryForToday: Consumption? {
        return items.first
    }
    
    var Consumed: Double {
        if let today = ConsumptionEntryForToday {
            return today.consumed
        }
        else { // TODO pull this from userdefaults.
            return 0
        }
    }
    var Target: Double {
        if let today = ConsumptionEntryForToday {
            return today.goal
        }
        else { // TODO pull this from userdefaults.
            return 64
        }
    }
    
    
    var Percentage: Double {
        Double(Consumed / Target) * 100
    }
    
    var body: some View {
        
        NavigationView {
            VStack {
                Spacer()
                VStack {
                    ProgressCircle(Percentage: Percentage)
                    
                    Text("\(Consumed.formatted(.number))oz / \(Target.formatted(.number))oz")
                        .bold()
                }
                .padding(.bottom, 44)
                Spacer()
                
                Button {
                    ShowAddConsumed = true
                } label: {
                    HStack {
                        Text("Log ")
                        Image(systemName: "drop")
                        Text(" Consumed")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                

                
            }
            
            
            
//            .padding(.bottom, 44)
            
            
            .navigationTitle("Hydrate Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                            .navigationTitle("Settings")
                    } label: {
                        Image(systemName: "gear")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        HistoryLogView()
                            .navigationTitle("History")
                    } label: {
                        Image(systemName: "clock")
                    }
                }
            }
            
        }
        
        .sheet(isPresented: $ShowAddConsumed) {
            LogConsumed(ConsumptionEntryForToday: ConsumptionEntryForToday)
                .presentationDetents([.medium])
                .interactiveDismissDisabled(true)
        }
        
        
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().preferredColorScheme(.dark)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        
//        MainView().preferredColorScheme(.light)
        
//        HistoryLogView().preferredColorScheme(.dark)
    }
}

//
//  MainView.swift
//  Hydrateminder
//
//  Created by Justin Allen on 2/3/23.
//

import SwiftUI
import CoreData
import StoreKit

// use this to find the directory for the Database.
// https://stackoverflow.com/questions/2268102/how-to-view-data-stored-in-core-data

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
    
//    var Consumed: Double {
//        if let today = ConsumptionEntryForToday {
//            return today.consumed
//        }
//        else { // TODO pull this from userdefaults.
//            return 0
//        }
//    }
//    var Target: Double {
//        if let today = ConsumptionEntryForToday {
//            return today.goal
//        }
//        else { // TODO pull this from userdefaults.
//            return 64
//        }
//    }
//
//    var Remaining: Double {
//        if let today = ConsumptionEntryForToday {
//            return today.goal - today.consumed
//        }
//        else { // TODO pull this from userdefaults.
//            return 64
//        }
//    }
    
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
        sortDescriptors: [NSSortDescriptor(keyPath: \Consumption.date, ascending: false)],
        animation: .easeInOut)
    private var items: FetchedResults<Consumption>
    
    
    var body: some View {
        
        List {
            
            Section {
                ForEach(items) { item in
                    // if is today, don't show
                    if let date = item.date {
                        if date.isToday {
                            ItemEntryToday(item)
                        }
                        else {
//                            ItemEntry(item)
                        }
                    }
                }
            }
            
            Section("History") {
                ForEach(items) { item in
                    // if is today, don't show
                    if let date = item.date {
                        if date.isToday {
//                            ItemEntryToday(item)
                        }
                        else {
                            ItemEntry(item)
                        }
                    }
                }
            }
            
            
        }
    }
    
    @ViewBuilder
    func ItemEntryToday(_ item: Consumption) -> some View {
        HStack {
            Text("Today")
            Spacer()
            Text(" \(item.consumed.formatted(.number)) ounces / \(item.goal.formatted(.number)) ounces")
        }
    }
    
    
    @ViewBuilder
    func ItemEntry(_ item: Consumption) -> some View {
        HStack {
            Text("\(item.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Date")")
            Spacer()
            Text(" \(item.consumed.formatted(.number)) ounces / \(item.goal.formatted(.number)) ounces")
        }
    }
    
    
}

struct SettingsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        
        List {
//            Text("Settings View Coming soon.")
            
            
            
            Section {
                Button {
                    StoreViewModel.shared.fetchPurchases()
                } label: {
                    Text("Restore Purchases")
                }
                
                
                Button {
                    StoreViewModel.shared.purchased.removeAll()
                } label: {
                    Text("Clear Purchases")
                }
                
                Button {
                    let paymentQueue = SKPaymentQueue.default()
                    paymentQueue.presentCodeRedemptionSheet()
                } label: {
                    Text("Redeem Offer Code")
                }
            }
            
            #if DEBUG
            
            Section("Debug") {
                Button {
                    
                    // clear the collection
                    
//                    let count = 5
                    var date: Date = .yesterday.startOfDay
                    Array(0...20).forEach { index in
                        print("Day \(index)")
                        let day = Consumption(context: viewContext)
                        day.date = date
                        day.goal = 64
                        day.consumed = Double(Int.random(in: 64...64))
                        date = date.dayBefore.startOfDay
                        
                        do {
                            try viewContext.save()
                        } catch {
                            // Replace this implementation with code to handle the error appropriately.
                            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                    }
                    
                    
//                    let yesterday = Consumption(context: viewContext)
//                    yesterday.date = .yesterday.startOfDay
//                    yesterday.goal = 64
//                    yesterday.consumed = 16
                    
                    do {
                        try viewContext.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                    
                    
                } label: {
                    Text("Create previous day entry")
                }
            }
            
            #endif
        }
        
        
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
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
    
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
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
        animation: .easeInOut)
    private var items: FetchedResults<Consumption>
    
    var ConsumptionEntryForToday: Consumption? {
        return items.first(where: { item in
            item.date?.isToday ?? false
        })
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
                        .onTapGesture {
                            ShowAddConsumed = true
                        }
                    
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

class StoreViewModel : ObservableObject {
    static let shared = StoreViewModel()
    
    let productIds: [String] = [
        "tech.justins.Hydrateminder.ProWidget",
        "tech.justins.Hydrateminder.UnlimitedDailyReminder",
//        "tech.justins.DogCamera.UnlockCustomSoundClip"
//        "tech.justins.DogCamera.Squeeky2"
    ]
    
    @Published var products: Set<Product> = Set()
    @Published var purchased: Set<Product> = Set()
    
    private init() {
        fetchPurchases()
    }
    
    private func fetchProducts() async throws -> [Product] {
        do {
            return try await Product.products(for: productIds)
        } catch {
            print(error)
            return []
        }
    }
    
    func fetchPurchases() {
        Task.init {
    
            do {
                if self.products.count == 0 {
                    let products = try await fetchProducts()
                    DispatchQueue.main.async {
                        print("products: \(products)")
                        self.products = Set( products )
                    }
                }
                
            } catch {
                print(error)
            }
            
            for await result in Transaction.currentEntitlements {
                
                switch result {
                
                case .unverified(_, _):
                    print("unverified")
                    break
                case .verified(let receipt):
//                    print(receipt.expirationDate)
                    let product = products.first { p in
                        p.id == receipt.productID
                    }
                    
                    await receipt.finish()
                    
                    
                    guard let product = product else { return  }
                    print("ProductID: \(product.id)")
                    DispatchQueue.main.async {
                        self.purchased.insert(product) //.append(product)
                    }
                    
                    print("verified")
                    print(self.purchased)
                    break
                }
                
            }
                        
        }
    }
    
    

}

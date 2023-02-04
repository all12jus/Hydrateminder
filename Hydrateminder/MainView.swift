//
//  MainView.swift
//  Hydrateminder
//
//  Created by Justin Allen on 2/3/23.
//

import SwiftUI

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
    
    @State var AmountToAdd: Float = 0
    
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

struct MainView: View {
    
    @State var ShowAddConsumed: Bool = false
    
    @State var Consumed: Float = 4
    var Target: Float = 64.0
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
        }
        
        .sheet(isPresented: $ShowAddConsumed) {
            LogConsumed()
                .presentationDetents([.medium])
                .interactiveDismissDisabled(true)
        }
        
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().preferredColorScheme(.dark)
        
        MainView().preferredColorScheme(.light)
    }
}

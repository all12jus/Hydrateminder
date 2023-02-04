//
//  MainView.swift
//  Hydrateminder
//
//  Created by Justin Allen on 2/3/23.
//

import SwiftUI

struct MainView: View {
    
    var Percentage: Int = 95
    
    var body: some View {
        
        NavigationView {
//            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            
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
                        endAngle: Angle(degrees: -90.0) + Angle(degrees: Double(Percentage) / 100.0 * 360),
                        clockwise: false)
                    
                }
                .fill(.teal)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(48)
            .padding(.bottom, 44)
            

            .navigationTitle("Hydrate Reminder")
            .navigationBarTitleDisplayMode(.inline)
        }
        
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

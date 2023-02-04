//
//  HydrateminderApp.swift
//  Hydrateminder
//
//  Created by Justin Allen on 2/3/23.
//

import SwiftUI

@main
struct HydrateminderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

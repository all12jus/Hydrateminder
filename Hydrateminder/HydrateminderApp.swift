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

    // PersistenceController.shared.container.viewContext
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    UIApplication.shared.registerForRemoteNotifications()
                    StoreViewModel.shared.fetchPurchases()

                    Task.init {
                        StoreViewModel.shared.fetchPurchases()
                    }
                }
        }
    }
}

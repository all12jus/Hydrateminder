//
//  Persistence.swift
//  Hydrateminder
//
//  Created by Justin Allen on 2/3/23.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    var sharedStoreURL: URL {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.tech.justins.Hydrateminder")
        return container!.appendingPathComponent("Hydrateminder", conformingTo: .database)
    }

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
//        let newItem = Consumption(context: viewContext)
//        newItem.date = .now
//        newItem.goal = 64
//        newItem.consumed = 8
//
//        let newItem2 = Consumption(context: viewContext)
//        newItem2.date = .now.dayBefore
//        newItem2.goal = 64
//        newItem2.consumed = 64
        
        let startDate = Date.now.startOfMonth
        for day in 0..<Date.now.day{
            let newItem2 = Consumption(context: viewContext)
            let dayDate = Calendar.current.date(byAdding: .day, value: day, to: startDate)
            newItem2.date = dayDate
            newItem2.goal = 64
            newItem2.consumed = day > Date.now.day / 2 ? 64 : Double(Int.random(in: 0..<64))
        }
        
//        for _ in 0..<10 {
//            let newItem = Item(context: viewContext)
//            newItem.timestamp = Date()
//        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Hydrateminder")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        else {
            // this should be working correctly.
            container.persistentStoreDescriptions.first!.url = sharedStoreURL
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

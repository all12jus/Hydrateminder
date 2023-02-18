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
            VStack (spacing: 16) {
 
                Slider(value: $AmountToAdd, in: 0...16, step: 1.0) {
                    Text("Amount")
                } minimumValueLabel: {
                    Text("0oz")
                } maximumValueLabel: {
                    Text("16oz")
                }
                .padding()
                
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
            .padding(.vertical, 32)
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



struct ReminderListView: View {
    
    @StateObject var viewModel: ReminderViewModel = .init()
    @Environment(\.managedObjectContext) private var viewContext
    
    // ReminderViewModel
    @ObservedObject var storeViewModel = StoreViewModel.shared
    var productID: String = "tech.justins.Hydrateminder.UnlimitedDailyReminder.Monthly"
    var priceText: String {
        get {
            if isPurchased {
                return "OWNED"
            }

            if ((product?.displayPrice) != nil) {
                return product!.displayPrice
            }

            return "$"
        }
    }
    var isPurchased: Bool {
        let product = StoreViewModel.shared.purchased.first(where: { p in
            p.id == self.productID
        })

        return  product != nil
    }

    var product: Product? {
        let product = StoreViewModel.shared.products.first(where: { p in
            p.id == self.productID
        })

        return  product
    }
    
    func TriggerPurchase() async {
        do {
            guard let product = product else { return }
            let result = try await product.purchase()
            switch result {
        
            case .success(let success_result):
                print("purchased")
            
                switch success_result {
            
                case .unverified(_, _):
                    print("unverified")
                case .verified(let receipt):
                    print("verified")
                    print(receipt)
                
                    let product = storeViewModel.products.first { p in
                        p.id == receipt.productID
                    }
                
                    await receipt.finish()
                    guard let product = product else { return print("No Product") }
                    DispatchQueue.main.async {
                        storeViewModel.purchased.insert(product)
                    }
                
                }

            case .userCancelled:
                print("user cancelled")
            case .pending:
                print("pending")
            @unknown default:
                print("unknown")
            }
        } catch {
            print("Purchase Failed \(error)")
        }
        
        
    }
    
    
    @ViewBuilder
    func BuyButton() -> some View {
        Button {
            Task {
                await TriggerPurchase()
            }
        } label: {
            Text(priceText)
        }
        .buttonStyle(.bordered)
//        .disabled(true)
    }
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Reminder.minutes, ascending: true)],
        animation: .easeInOut)
    private var items: FetchedResults<Reminder>
    
    @State var errorSaving: Bool = false
    @State var showAddTime: Bool = false
    @State private var addNewTimeDate = Date() //.beginningOfHour
    
    var body: some View {
        
        List {
            

            ForEach(items) { item in
                // if is today, don't show
                ItemEntry(item)
                    
            }
            .onDelete(perform: onDelete(_:))
            
            if (!isPurchased){
                Section {
                    HStack {
                        Text("Unlock Unlimited Reminders")
                        Spacer()
                        BuyButton()
                    }
                }
                
                
            }
            
        }
        .navigationTitle("Reminders")
        .toolbar(content: {
            ToolbarItem {
                Button("Add") {
                    showAddTime = true
                }
                .disabled(items.count >= 1 && !isPurchased)
            }
        })
        
        .alert("Error Saving", isPresented: $errorSaving) {
            
        }
        .popover(isPresented: $showAddTime) {
            
            AddNewTimePopover()
                .presentationDetents([.medium])
//                .interactiveDismissDisabled(true)
            
        }
    }
    
    func onDelete(_ offsets: IndexSet) {
        for index in offsets {
            let itemsToRemove = items[index]
            viewContext.delete(itemsToRemove)
        }
        
        viewModel.resetNotifications()
    }
    
    func minsToTime(_ input: Int16) -> String {
        let hours = (input / 60)
        let mins = input - (hours * 60)
        let meridiem = hours >= 12 ? "PM" : "AM"
        let minsFormatted = String(format: "%02d", mins)
        
        return "\(hours):\(minsFormatted) \(meridiem)"
    }
    
    func timeToMins(_ date: Date) -> Int16 {
        let calendar = Calendar.current

        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        return Int16((hour * 60) + minutes)
    }
    

    
    

    
    @ViewBuilder
    func AddNewTimePopover() -> some View {
        
        NavigationView {
            VStack {
                
                Spacer()
                DatePicker("", selection: $addNewTimeDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
//                            .pickerStyle(.segmented)
                            .datePickerStyle(.wheel)
                
                Spacer()
                
                Button {
                    // do this soon.
                    
                    viewModel.authorizeNotifications()
                                        
                    let newReminder = Reminder(context: viewContext)
                    newReminder.minutes = timeToMins(addNewTimeDate)
                    newReminder.active = true
                    do {
                        try newReminder.managedObjectContext?.save()
                        
//                        viewModel.addNotification(addNewTimeDate)
                        viewModel.resetNotifications() // this will also create the new one.
                        
                        showAddTime = false
                    }
                    catch {
                        errorSaving = true
                    }
                } label: {
                    Text("Add Reminder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Add Reminder")
        }
    }

    @ViewBuilder
    func ItemEntry(_ item: Reminder) -> some View {
        HStack {
            Text("\(minsToTime(item.minutes))")
            Spacer()
            Toggle("", isOn: Binding(get: {
                return item.active
            }, set: { value, _ in
                //
                item.active = !item.active
                do {
                    try item.managedObjectContext?.save()
                    viewModel.resetNotifications()
                }
                catch {
                    errorSaving = true
                }
            }))
        }
    }
    
    
}

struct SettingsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject var viewModel: ReminderViewModel = .init()
    
    var body: some View {
        
        List {
//            Text("Settings View Coming soon.")
            
            Section("") {
                NavigationLink {
                    ReminderListView()
                } label: {
                    Text("Reminders")
                }
            }
            
            
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
            
            
            //
            

            
            #if DEBUG
            
            Section("Debug") {
                
                Button {
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                } label: {
                    Text("Clear Notifications")
                }
                
                Button {
                    viewModel.resetNotifications()
                } label: {
                    Text("Reset Notifications")
                }

                
                
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
    var day: Int {
        return Calendar.current.component(.day,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
    var beginningOfHour: Date {
        return Calendar.current.date(bySetting: .minute, value: 0, of: self)!
    }
    
    var startOfPreviousMonth: Date {
        let dayInPreviousMonth = Calendar.current.date(byAdding: .month, value: -1, to: self)!
        return dayInPreviousMonth.startOfMonth
    }
    

}

extension Calendar {
    private var currentDate: Date { return Date() }
    
    func isDateInThisMonth(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .month)
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
                .presentationDetents([.height(200)]) // .medium
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
        "tech.justins.Hydrateminder.UnlimitedDailyReminder.Monthly",
        "tech.justins.Hydrateminder.UnlimitedDailyReminder.Yearly",
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

class ReminderViewModel : NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    override init() {
        super.init()
//        authorizeNotifications()
    }
    
    func authorizeNotifications() {
        UNUserNotificationCenter.current().requestAuthorization (options: [.sound, .alert, .badge]) { _, _ in
            
        }
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner, .badge])
    }
    
    func addNotification(_ date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Log Your Water Intake"
        content.subtitle = "Have you logged your water intake?"
        content.sound = UNNotificationSound.default
        
        let (hour, minutes) = timeToComponents(date)

        let components = DateComponents(calendar: .current, timeZone: .current, hour: hour, minute: minutes)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
        
        print(request.trigger.debugDescription)
        UNUserNotificationCenter.current().add(request)
    }
    
    func resetNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Log Your Water Intake"
        content.subtitle = "Have you logged your water intake?"
        content.sound = UNNotificationSound.default
        
        //  sortDescriptors: [NSSortDescriptor(keyPath: \Reminder.minutes, ascending: true)],
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Reminder")
          
        do {
            let reminders: [Reminder] = try PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [Reminder]
          
          reminders.filter { reminder in
              reminder.active
          }.forEach { reminder in
              let (hours, minutes) = minsToComponents(reminder.minutes)
              let components = DateComponents(calendar: .current, timeZone: .current, hour: hours, minute: minutes)

              let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
              
              print(request.trigger.debugDescription)
              UNUserNotificationCenter.current().add(request)
              
          }
          
        } catch let error as NSError {
        print("Could not fetch. \(error), \(error.userInfo)")
        }

        
        
        
    }
    
    func timeToComponents(_ date: Date) -> (Int, Int) {
        let calendar = Calendar.current

        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        return (hour, minutes)
    }
    
    func minsToComponents(_ input: Int16) -> (Int, Int) {
        let hours = (input / 60)
        let minutes = input - (hours * 60)
        
        return (Int(hours), Int(minutes))
    }
}


struct CalendarView: View {
    
    var body: some View {
        VStack {
            MonthView(calendar: Calendar.current, month: .now)
        }
        
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView().preferredColorScheme(.dark)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        
//        MainView().preferredColorScheme(.light)
        
//        HistoryLogView().preferredColorScheme(.dark)
    }
}

fileprivate extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}

fileprivate extension DateFormatter {
    static var month: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }

    static var monthAndYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    static var dayShort: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dddd"
        return formatter
    }
}


struct DayView: View {
    let calendar: Calendar
    let week: Date
    let day: Date
    
    @FetchRequest
//    (
//        sortDescriptors: [
//            NSSortDescriptor(keyPath: \Consumption.date, ascending: true)
//        ],
//        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)", argumentArray: [day.startOfDay, day.endOfDay]),
//        animation: .easeInOut)
    private var consumption: FetchedResults<Consumption>
    
    init(calendar: Calendar, week: Date, day: Date) {
        self.calendar = calendar
        self.week = week
        self.day = day
        self._consumption = FetchRequest(sortDescriptors: [
                                                        NSSortDescriptor(keyPath: \Consumption.date, ascending: true)
                                                    ]
                                            
                                        , predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)", argumentArray: [day.startOfDay, day.endOfDay]), animation: .default)
    }
    
    func getDateColor(day: Date) -> Color {
        // should be comparing against entry.date
        Color.blue
//        if self.calendar.isDateInToday(day) {
//            // today
//            return Color.label
//        }
//        else if day < Date.init() {
//            // before today
//            return Color.systemBackground
//        }
//        else {
//            // after today
//            return Color.systemBackground
//        }
    }
    
    func getDateFontColor(day: Date) -> Color {
        // should be comparing against entry.date
        Color.white
//        if self.calendar.isDateInToday(day) {
//            // today
//            return Color.systemBackground
//        }
//        else if day < Date.init() {
//            // before today
//            return Color.label
//        }
//        else {
//            // after today
//            return Color.label
//        }
    }
    
    func getDateOpacity(day: Date) -> Double {
        // should be comparing against entry.date
        if self.calendar.isDateInToday(day) {
            // today
            return 1
        }
        else if day < Date.init() {
            // before today
            return 0.7
        }
        else {
            // after today
            return 0.4
        }
    }
    
    var ConsumptionEntryForToday: Consumption? {
        return consumption.first(where: { item in
            item.date?.startOfDay == day.startOfDay
//            item.date?.isToday ?? false
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
    
    @ViewBuilder
    func BG() -> some View {
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
            

        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    var body: some View {
        let te = Text(String(self.calendar.component(.day, from: day)))
        .foregroundColor(getDateFontColor(day: day))
        let vw =
            Text("30")
            .lineSpacing(0)
            .hidden()
            .padding(8)
            .overlay(BG())
//            .background(getDateColor(day: day))
//            .clipShape(BG())
//            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5,height: 5)))
            .padding(.vertical, 4)
            .overlay(te)
            .opacity(getDateOpacity(day: day))
    
    
        if self.calendar.isDate(week, equalTo: day, toGranularity: .month) {
//            ProgressCircle(Percentage: Percentage)
             vw
        }
        else {
            vw.hidden()
        }
    }
    
}


struct MonthView: View {
    let calendar: Calendar
    let month: Date
    
    func getWeekDaysSorted() -> [String]{
        let weekDays = Calendar.current.shortWeekdaySymbols
        let sortedWeekDays = Array(weekDays[Calendar.current.firstWeekday - 1 ..< Calendar.current.shortWeekdaySymbols.count] + weekDays[0 ..< Calendar.current.firstWeekday - 1])
        return sortedWeekDays
    }
    
    func getDateColor(day: Date) -> Color {
        // should be comparing against entry.date
        Color.blue
//        if self.calendar.isDateInToday(day) {
//            // today
//            return Color.label
//        }
//        else if day < Date.init() {
//            // before today
//            return Color.systemBackground
//        }
//        else {
//            // after today
//            return Color.systemBackground
//        }
    }
    
    func getDateFontColor(day: Date) -> Color {
        // should be comparing against entry.date
        Color.white
//        if self.calendar.isDateInToday(day) {
//            // today
//            return Color.systemBackground
//        }
//        else if day < Date.init() {
//            // before today
//            return Color.label
//        }
//        else {
//            // after today
//            return Color.label
//        }
    }
    
    func getDateOpacity(day: Date) -> Double {
        // should be comparing against entry.date
        if self.calendar.isDateInToday(day) {
            // today
            return 1
        }
        else if day < Date.init() {
            // before today
            return 0.4
        }
        else {
            // after today
            return 0.7
        }
    }
    

//    @ViewBuilder
//    func DayView(_ week: Date, _ day: Date) -> some View {
//        let te = Text(String(self.calendar.component(.day, from: day)))
//        .foregroundColor(getDateFontColor(day: day))
//        let vw =
//            Text("30")
//            .lineSpacing(0)
//            .hidden()
//            .padding(8)
//            .background(getDateColor(day: day))
//            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5,height: 5)))
//            .padding(.vertical, 4)
//            .overlay(te)
//            .opacity(getDateOpacity(day: day))
//
//
//        if self.calendar.isDate(week, equalTo: day, toGranularity: .month) {
//            vw
//        }
//        else {
//            vw.hidden()
//        }
//    }

    
    var body: some View {
        // grab the month
        let monthInterval: DateInterval = calendar.dateInterval(of: .month, for: month)!
    
        // from the month grab the weeks. first day of the week
        let weeks: [Date] = calendar.generateDates(inside: monthInterval, matching: DateComponents(hour: 0, minute: 0, second: 0, weekday: calendar.firstWeekday))
    
        // for each week, grab each day in interval
        let firstDayOfMonth = calendar.generateDates(inside: monthInterval, matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0))[0]
    
    
        let formatter = DateFormatter.monthAndYear
        let monthString = formatter.string(from: firstDayOfMonth)
        Text(String(monthString)).font(.system(size: 36)).italic().bold().italic().bold().padding()
    
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 1), spacing: 0), count: 7), content: {
            ForEach(getWeekDaysSorted(), id: \.self) { day in
                let firstChar = String(day.first ?? " ".first!)
                Text("\(firstChar)").bold()
            }
        })
    
        ForEach(weeks, id: \.self) { week in
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: week)
            let days = calendar.generateDates(inside: weekInterval!, matching: DateComponents(hour:0, minute: 0, second: 0))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 1), spacing: 0), count: 7), content: {
                ForEach(days, id: \.self) { day in
//                    DayView(week, day)
                    DayView(calendar: calendar, week: week, day: day)
                }
            })
        }
    }
}

//
//  Hydrateminder_Widget.swift
//  Hydrateminder-Widget
//
//  Created by Justin Allen on 2/17/23.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    
    let viewContext = PersistenceController.shared.container.viewContext
    
    func placeholder(in context: Context) -> ConsumptionEntry {
        ConsumptionEntry(date: Date(), consumptions: nil, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (ConsumptionEntry) -> ()) {
//        let entry = ConsumptionEntry(date: Date(), consumptions: nil, configuration: configuration)
        
        
        let request = Consumption.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Consumption.date, ascending: true)]
        request.predicate = NSPredicate(format: "(date >= %@) AND (date <= %@)", Date.now.startOfMonth as CVarArg, Date.now.endOfMonth as CVarArg)
        
        do {
            let result = try viewContext.fetch(request)
            print(result)
            let entry = ConsumptionEntry(date: .now, consumptions: result, configuration: configuration)
            completion(entry)
//            entries.append(entry)
        }
        catch {
            print("Widget load failed.")
        }
        
        
//        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ConsumptionEntry] = []
        
        let request = Consumption.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Consumption.date, ascending: true)]
        request.predicate = NSPredicate(format: "(date >= %@) AND (date <= %@)", Date.now.startOfMonth as CVarArg, Date.now.endOfMonth as CVarArg)
        
        do {
            let result = try viewContext.fetch(request)
            
            print(result)
            
            let entry = ConsumptionEntry(date: .now, consumptions: result, configuration: configuration)
            entries.append(entry)
        }
        catch {
            print("Widget load failed.")
        }
        
//        let sortDescriptors = [NSSortDescriptor(keyPath: \Consumption.date, ascending: true)]
//        let predicate: NSPredicate? = nil
//        var fetchRequest: FetchRequest = FetchRequest(sortDescriptors: sortDescriptors, predicate: predicate)
//        fetchRequest.update()
//        let results = fetchRequest.wrappedValue
        
        
        

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = ConsumptionEntry(date: entryDate, consumption: nil, configuration: configuration)
//            entries.append(entry)
//        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct ConsumptionEntry: TimelineEntry {
    let date: Date
    let consumptions: [Consumption]?
    let configuration: ConfigurationIntent
}


//struct SimpleEntry: TimelineEntry {
//    let date: Date
//    let configuration: ConfigurationIntent
//}

struct Hydrateminder_WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
//        Text(entry.date, style: .time)
        if entry.consumptions == nil {
            Text("No consumptions")
        }
        else {
            VStack {
                MonthView(calendar: Calendar.current, month: entry.date, consumption: entry.consumptions!)
            }
            .padding(.bottom, 8)
        }
        
    }
}

struct Hydrateminder_Widget: Widget {
    let kind: String = "Hydrateminder_Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Hydrateminder_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemLarge])
    }
}

struct Hydrateminder_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Hydrateminder_WidgetEntryView(entry: ConsumptionEntry(date: Date(), consumptions: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
//            .preferredColorScheme(.dark)
    }
}


//
//  Views.swift
//  Hydrateminder
//
//  Created by Justin Allen on 2/17/23.
//



struct DayView: View {
    let calendar: Calendar
    let week: Date
    let day: Date
    
    let consumption: [Consumption]
    
    init(calendar: Calendar, week: Date, day: Date, consumption: [Consumption]) {
        self.calendar = calendar
        self.week = week
        self.day = day
        self.consumption = consumption
    }
        
//    func getDateFontColor(day: Date) -> Color {
//        // should be comparing against entry.date
//        Color.teal
//    }
    
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
            
//            Circle()
//                .fill(.background)
//                .padding(24) // 48
//                .frame(width: min(geometry.size.width, geometry.size.height), height: min(geometry.size.width, geometry.size.height))
//

        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    var body: some View {
        let te = Text(String(self.calendar.component(.day, from: day)))
            .foregroundColor(.teal)
        let vw =
            Text("30")
            .lineSpacing(0)
            .hidden()
            .padding(4)
            .overlay(BG())
            .padding(.vertical, 4)
            .overlay(te)
            .opacity(getDateOpacity(day: day))
    
    
        if self.calendar.isDate(week, equalTo: day, toGranularity: .month) {
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
    let consumption: [Consumption]
    
    func getWeekDaysSorted() -> [String]{
        let weekDays = Calendar.current.shortWeekdaySymbols
        let sortedWeekDays = Array(weekDays[Calendar.current.firstWeekday - 1 ..< Calendar.current.shortWeekdaySymbols.count] + weekDays[0 ..< Calendar.current.firstWeekday - 1])
        return sortedWeekDays
    }
            
    var body: some View {
        // grab the month
        let monthInterval: DateInterval = calendar.dateInterval(of: .month, for: month)!
    
        // from the month grab the weeks. first day of the week
        let weeks: [Date] = calendar.generateDates(inside: monthInterval, matching: DateComponents(hour: 0, minute: 0, second: 0, weekday: calendar.firstWeekday))
    
        // for each week, grab each day in interval
        let firstDayOfMonth = calendar.generateDates(inside: monthInterval, matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0))[0]
    
        let formatter = DateFormatter.monthAndYear
        let monthString = formatter.string(from: firstDayOfMonth)
        HStack {
            Image(uiImage: UIImage(named:"icon")!)
                .resizable()
                .frame(width: 40, height: 40)
                .mask(RoundedRectangle(cornerRadius: 8))
                .frame(width: 40, height: 40)
            Text(String(monthString)).font(.system(size: 24)).italic().bold().italic().bold().padding()
        }
        
    
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
                    DayView(calendar: calendar, week: week, day: day, consumption: consumption)
                }
            })
        }
    }
}

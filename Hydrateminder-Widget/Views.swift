//
//  Views.swift
//  Hydrateminder
//
//  Created by Justin Allen on 2/17/23.
//

import Foundation
import SwiftUI


struct DayView_: View {
    let calendar: Calendar
    let week: Date
    let day: Date
    
    @FetchRequest private var consumption: FetchedResults<Consumption> // this is not how you are going to do this for the widget.
    
    init(calendar: Calendar, week: Date, day: Date) {
        self.calendar = calendar
        self.week = week
        self.day = day
        self._consumption = FetchRequest(sortDescriptors: [
            NSSortDescriptor(keyPath: \Consumption.date, ascending: true)
        ], predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)", argumentArray: [day.startOfDay, day.endOfDay]), animation: .default)
    }
    
    func getDateColor(day: Date) -> Color {
        // should be comparing against entry.date
        Color.blue
    }
    
    func getDateFontColor(day: Date) -> Color {
        // should be comparing against entry.date
        Color.teal
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


struct MonthView_: View {
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
    }
    
    func getDateFontColor(day: Date) -> Color {
        // should be comparing against entry.date
        Color.teal
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
                    DayView_(calendar: calendar, week: week, day: day)
                }
            })
        }
    }
}

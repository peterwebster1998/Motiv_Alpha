/*
  CALm.swift
  Motiv

  Created by Peter Webster on 4/25/23.

//  CALm.swift
//  motiv-prerelease
//
//  Created by Peter Webster on 10/19/22.
*/

import Foundation
import SwiftUI

struct CALm : Codable{
    private var eventsDict: [String: [Event]]
    private var conflicts: [String: [Event]]
    private var eventSeries: [EventSeries]
    
    enum Repeat : String, Identifiable, CaseIterable, Codable{
        case Never = "Never"
        case Daily = "Daily"
        case Weekdaily = "Weekdaily"
        case Weekendly = "Weekendly"
        case Weekly = "Weekly"
        case Biweekly = "Biweekly"
        case Monthly = "Monthly"
        case Bimonthly = "Bimonthly"
        case Quarterly = "Quarterly"
        case Semiannually = "Semiannually"
        case Annually = "Annually"
        
        var id: String { self.rawValue }
    }
    // MARK: - Persistence
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(CALm.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try CALm(json: data)
    }
    
    // MARK: - CALm Methods
    init () {
        eventsDict = [:]
        conflicts = [:]
        eventSeries = []
    }
    
    func getDaysEvents(_ day: String) -> [Event]{
        //Check Previous day for event overnight event
        let tdh = TimeDateHelper()
        tdh.dateFormatter.dateFormat = "dd LLL yyyy"
        let date = tdh.dateFormatter.date(from: day)
        if date == nil {
            return []
        }
        let yesterdate = tdh.calendar.date(byAdding: .day, value: -1, to: date!)!
        var out : [Event] = []
        //If there are events in yesterdate, are there any that end the following day
        if eventsDict[tdh.dateString(yesterdate)]?.contains(where: {!(tdh.calendar.isDate($0.getStartTime(), inSameDayAs: tdh.calendar.date(byAdding: .minute, value: $0.getDuration(), to: $0.getStartTime())!))}) ?? false{
            let event = eventsDict[tdh.dateString(yesterdate)]!.last!
            //Filter out events that end exactly at midnight
            if tdh.calendar.date(byAdding: .minute, value: event.getDuration(), to: event.getStartTime())! > tdh.calendar.date(bySettingHour: 0, minute: 1, second: 0, of: date!)!{
                out.append(event)
            }
        }
        out.append(contentsOf: eventsDict[day] ?? [])
        return out
    }
    
    func isEvent(_ event: Event) -> Bool {
        let value = eventsDict[event.getDateKey()]?.contains(where: {event.id == $0.id}) ?? false
        return value
    }
    
    func getTasks(_ event: Event) -> [TDLm.Task]{
        return eventsDict[event.getDateKey()]!.first(where: {$0.getID() == event.getID()})!.getTasks()
    }
    
    func getDaysTasks(_ day: String) -> [TDLm.Task]{
        let daysEvents = eventsDict[day]!
        var daysTasks: [TDLm.Task] = []
        for i in daysEvents{
            daysTasks.append(contentsOf: getTasks(i))
        }
        return daysTasks
    }
    
    func getConflicts() -> [String:[Event]] {
        return conflicts
    }
    
    func isConflict(_ event: Event) -> Bool {
        let value = conflicts[event.getDateKey()]?.contains(where: {event.id == $0.id}) ?? false
        return value
    }
    
    mutating func refreshConflicts() {
//        print("Refreshing conflicts!")
        let tdh = TimeDateHelper()
        for day in conflicts.keys {
            if conflicts[day]!.first!.getStartTime() < Date() && tdh.dateString(Date()) != day{
                conflicts.removeValue(forKey: day)
            }
        }
    }
    
    func checkForConflict(day: String, event: CALm.Event) -> Bool {
        let daysEvents = getDaysEvents(day)
        var conflict = false
        for plan in daysEvents {
            //Check conflict is not with self
            if plan.getID() != event.getID(){
                var planConflict = false
                let planStart = plan.getStartTime()
                let planEnd = plan.getStartTime().addingTimeInterval(TimeInterval(plan.getDuration() * 60))
                let eventStart = event.getStartTime()
                let eventEnd = event.getStartTime().addingTimeInterval(TimeInterval(event.getDuration() * 60))
                
                //plan starts within event
                if  planStart >= eventStart && planStart < eventEnd{
                    planConflict = true
                    print("Conflict: Planned event starts within proposed event")
                }
                //plan ends within event
                if  planEnd > eventStart && planEnd < eventEnd{
                    planConflict = true
                    print("Conflict: Planned event ends within proposed event")
                }
                //plan starts before and ends after event
                if  planStart <= eventStart && planEnd >= eventEnd{
                    planConflict = true
                    print("Conflict: Planned event starts before and ends after proposed event")
                }
                //plan starts after and ends before event
                if  planStart >= eventStart && planEnd <= eventEnd{
                    planConflict = true
                    print("Conflict: Planned event starts after and ends before proposed event")
                }
                
                if planConflict{
                    conflict = true
                }
            }
        }
        return conflict
    }
    
    func getEventSeries(_ ID: UUID) -> EventSeries {
        return eventSeries.first(where: {$0.getID() == ID})!
    }
    
    mutating func addEventToDay(day: String, event: Event){
        var localEvent = event
        if event.getRepetition() != "Never" && event.getSeriesID() == nil{
            print("Creating Event Series")
            let series = EventSeries(event: event)
            eventSeries.append(series)
            localEvent.setSeriesID(series.getID())
        }
        if eventsDict[day] != nil {
            eventsDict[day]!.append(localEvent)
        } else {
            eventsDict[day] = [localEvent]
        }
        if event.getRepetition() != "Never" && event.getSeriesID() == nil{
            propagateSeries(eventSeries.last!)
        } else if event.getRepetition() != "Never"{
            let idx = eventSeries.firstIndex(where: {$0.seriesID == event.getSeriesID()})!
            eventSeries[idx].addEvent(event)
        }
    }
    
    mutating func addConflict(_ event: Event){
        var localEvent = event
        if event.getRepetition() != "Never" && event.getSeriesID() == nil{
            print("Creating Event Series")
            let series = EventSeries(event: event)
            eventSeries.append(series)
            localEvent.setSeriesID(series.getID())
        }
        if conflicts[event.getDateKey()] != nil {
            conflicts[event.getDateKey()]!.append(localEvent)
        } else {
            conflicts[event.getDateKey()] = [localEvent]
        }
        if event.getRepetition() != "Never" && event.getSeriesID() == nil{
            propagateSeries(eventSeries.last!)
        } else if event.getRepetition() != "Never"{
            let idx = eventSeries.firstIndex(where: {$0.seriesID == event.getSeriesID()})!
            eventSeries[idx].addEvent(event)
        }
    }
    
    mutating func deleteConflict(_ event: Event){
        let conflictIdx = conflicts[event.getDateKey()]!.firstIndex(where: {$0.id == event.id})
        if conflictIdx != nil {
            conflicts[event.getDateKey()]!.remove(at: conflictIdx!)
        }
        if conflicts[event.getDateKey()]!.count == 0 {
            conflicts.removeValue(forKey: event.getDateKey())
        }
        if event.getSeriesID() != nil {
            let seriesIdx = eventSeries.firstIndex(where: {$0.seriesID == event.getSeriesID()})!
            eventSeries[seriesIdx].deleteEvent(event)
        }
    }
    
    mutating func deleteEvent(_ event: Event){
        let eventIdx = eventsDict[event.getDateKey()]!.firstIndex(where: {$0.id == event.id})
        if eventIdx != nil {
            eventsDict[event.getDateKey()]!.remove(at: eventIdx!)
        }
        if eventsDict[event.getDateKey()]!.count == 0 {
            eventsDict.removeValue(forKey: event.getDateKey())
        }
        if event.getSeriesID() != nil {
            let seriesIdx = eventSeries.firstIndex(where: {$0.seriesID == event.getSeriesID()})!
            eventSeries[seriesIdx].deleteEvent(event)
        }
    }
    
    mutating func editEvent(event: Event, name: String, description: String, duration: Int, repetition: Repeat, time: Date){
        let tdh = TimeDateHelper()
        let newDateKey = tdh.dateString(time)
        if(event.getDateKey() == newDateKey){
            if isEvent(event){
                let eventIdx = eventsDict[event.getDateKey()]!.firstIndex(where: {$0.id == event.id})!
                eventsDict[event.getDateKey()]![eventIdx].editEvent(name: name, description: description, duration: duration, repetition: repetition, time: time)
            } else if isConflict(event){
                let eventIdx = conflicts[event.getDateKey()]!.firstIndex(where: {$0.id == event.id})!
                conflicts[event.getDateKey()]![eventIdx].editEvent(name: name, description: description, duration: duration, repetition: repetition, time: time)
            } else {
                print("Error: Edit Request Cannot Find Event")
            }
        } else {
            var localEvent = event
            localEvent.editEvent(name: name, description: description, duration: duration, repetition: repetition, time: time)
            if isEvent(event){
                let eventIdx = eventsDict[event.getDateKey()]!.firstIndex(where: {$0 == event})!
                eventsDict[event.getDateKey()]!.remove(at: eventIdx)
                if eventsDict[newDateKey] == nil { eventsDict[newDateKey] = [] }
                eventsDict[newDateKey]!.append(localEvent)
            } else if isConflict(event){
                let eventIdx = conflicts[event.getDateKey()]!.firstIndex(where: {$0 == event})!
                conflicts[event.getDateKey()]!.remove(at: eventIdx)
                if conflicts[newDateKey] == nil { conflicts[newDateKey] = [] }
                conflicts[newDateKey]!.append(localEvent)
            } else {
                print("Error: Edit Request Cannot Find Event")
            }
        }
    }
    
    mutating func updateEvent(_ event: Event){
        let tdh = TimeDateHelper()
        let idx = eventsDict[tdh.dateString(event.getStartTime())]?.firstIndex(where: {$0.getID() == event.getID()}) ?? nil
        if idx != nil {
            eventsDict[tdh.dateString(event.getStartTime())]![idx!] = event
        } else {
            let keys = eventsDict.keys
            let futureKeys = keys.filter({
                if tdh.dateFromString($0) != nil {
                    if tdh.dateFromString($0)! > Date() {
                        return true
                    }
                }
                return false
            })
            
            for key in futureKeys {
                if eventsDict[key]!.contains(where: {$0.getID() == event.getID()}) {
                    let idx = eventsDict[key]!.firstIndex(where: {$0.getID() == event.getID()})!
                    eventsDict[key]![idx] = event
                    break
                }
            }
            print("Couldn't find event in future checking past")
            
            for key in keys.filter({!futureKeys.contains($0)}) {
                if eventsDict[key]!.contains(where: {$0.getID() == event.getID()}) {
                    let idx = eventsDict[key]!.firstIndex(where: {$0.getID() == event.getID()})!
                    eventsDict[key]![idx] = event
                    break
                }
            }
            
            print("Couldnt find event to update, adding to model")
            self.addEventToDay(day: event.getDateKey(), event: event)
        }
    }
    
    mutating func addEventSeries(_ series: EventSeries){
        if !eventSeries.contains(where: {$0.getID() == series.getID()}){
            eventSeries.append(series)
            propagateSeries(series)
        } else {
            print("EventSeries already exists, not added")
        }
    }
    
    mutating func editEventSeries(oldEvent: Event, newEvent: Event){
        let idx = eventSeries.firstIndex(where: {$0.seriesID == oldEvent.getSeriesID()})!
        eventSeries[idx].modifySeries(oldEvent: oldEvent, newEvent: newEvent)
        propagateSeries(eventSeries[idx])
    }
    
    mutating func propagateSeries(_ series: EventSeries){
        let eventsArr = series.getSeries()
        for event in eventsArr {
            //Check if event already exists in eventsDict or conflicts
            //NOTE: this is only catching existence if the series event hasnt had its date changed
            let exists = (eventsDict[event.getDateKey()]?.contains(where: {$0.id == event.id}) ?? false) || (conflicts[event.getDateKey()]?.contains(where: {$0.id == event.id}) ?? false)
            let day = event.getDateKey()

            if !exists {
                //Check if creating event will cause conflict
                if checkForConflict(day: day, event: event){
                    addConflict(event)
                } else {
                    if eventsDict[day] != nil {
                        eventsDict[day]!.append(event)
                    } else {
                        eventsDict[day] = [event]
                    }
                }
            } else {
                //Update non conforming events to match series
                if (eventsDict[day]?.contains(where: {$0.id == event.id}) ?? false){
                    let idx = eventsDict[day]!.firstIndex(where: {$0.id == event.id})!
                    if eventsDict[day]![idx] != event{
                        eventsDict[day]![idx].editEvent(name: event.getName(), description: event.getDescription(), duration: event.getDuration(), repetition: Repeat(rawValue: event.getRepetition())!, time: event.getStartTime())
                    }
                } else if (conflicts[day]?.contains(where: {$0.id == event.id}) ?? false){
                    let idx = conflicts[day]!.firstIndex(where: {$0.id == event.id})!
                    if conflicts[day]![idx] != event{
                        conflicts[day]![idx].editEvent(name: event.getName(), description: event.getDescription(), duration: event.getDuration(), repetition: Repeat(rawValue: event.getRepetition())!, time: event.getStartTime())
                    }
                }
            }
        }
    }
    
    mutating func updateEventSeries(_ newSeries: EventSeries){
        let idx = eventSeries.firstIndex(where: {$0.getID() == newSeries.getID()})
        if idx != nil {
            eventSeries[idx!] = newSeries
        }
    }
    
    //MARK: - CALm.EventSeries
    struct EventSeries: Codable {
        private var series: [Event]
        private var repitition: Repeat
        private var habit: HABm.Habit?
        let seriesID: UUID

        init (event: Event){
            self.seriesID = UUID()
            var localEvent = event
            localEvent.setSeriesID(seriesID)
            self.series = []
            self.series.append(localEvent)
            self.repitition = Repeat(rawValue: event.getRepetition())!
            updateSeries()
        }
        
        init (event: Event, habit: HABm.Habit){
            self.seriesID = UUID()
            var localEvent = event
            localEvent.setSeriesID(seriesID)
            self.series = []
            self.series.append(localEvent)
            self.repitition = Repeat(rawValue: event.getRepetition())!
            updateSeries()
            self.habit = habit
        }
        
        mutating func updateSeries() {
            let tdh = TimeDateHelper()
            var preLoadNum: Int = 0
            let currentIdx: Int = series.firstIndex(where: {$0.getStartTime() >= Date()}) ?? series.count
            switch repitition {
            case .Daily:
                preLoadNum = 180 //~6 months
            case .Weekdaily:
                preLoadNum = 130 //~6 months
            case .Weekendly:
                preLoadNum = 52 //~6 months
            case .Weekly:
                preLoadNum = 24 //~6 months
            case .Biweekly:
                preLoadNum = 12 //~6 months
            case .Monthly:
                preLoadNum = 6 //~6 months
            case .Bimonthly:
                preLoadNum = 6 //~1 year
            case .Quarterly:
                preLoadNum = 4 //~1 year
            case .Semiannually:
                preLoadNum = 4 //~2 years
            case .Annually:
                preLoadNum = 4 //~4 years
            default:
                break
            }
            while series.count <= preLoadNum + currentIdx{
                let event = series.last!
                var startTime = event.getStartTime()
                let nextEvent: Event
                switch repitition {
                case .Daily:
                    startTime = tdh.calendar.date(byAdding: .day, value: 1, to: startTime)!
                case .Weekdaily:
                    startTime = tdh.calendar.date(byAdding: .day, value: 1, to: startTime)!
                    if tdh.weekdayFromDate(startTime) == "Sat"{
                        startTime = tdh.calendar.date(byAdding: .day, value: 2, to: startTime)!
                    } else if tdh.weekdayFromDate(startTime) == "Sun"{
                        startTime = tdh.calendar.date(byAdding: .day, value: 1, to: startTime)!
                    }
                case .Weekendly:
                    if tdh.weekdayFromDate(startTime) == "Sat"{
                        startTime = tdh.calendar.date(byAdding: .day, value: 1, to: startTime)!
                    } else if tdh.weekdayFromDate(startTime) == "Sun"{
                        startTime = tdh.calendar.date(byAdding: .day, value: 6, to: startTime)!
                    } else {
                        while tdh.weekdayFromDate(startTime) != "Sat"{
                            startTime = tdh.calendar.date(byAdding: .day, value: 1, to: startTime)!
                        }
                    }
                case .Weekly:
                    startTime = tdh.calendar.date(byAdding: .day, value: 7, to: startTime)!
                case .Biweekly:
                    startTime = tdh.calendar.date(byAdding: .day, value: 14, to: startTime)!
                case .Monthly:
                    startTime = tdh.calendar.date(byAdding: .month, value: 1, to: startTime)!
                case .Bimonthly:
                    startTime = tdh.calendar.date(byAdding: .month, value: 2, to: startTime)!
                case .Quarterly:
                    startTime = tdh.calendar.date(byAdding: .month, value: 3, to: startTime)!
                case .Semiannually:
                    startTime = tdh.calendar.date(byAdding: .month, value: 6, to: startTime)!
                case .Annually:
                    startTime = tdh.calendar.date(byAdding: .year, value: 1, to: startTime)!
                default:
                    break
                }
                
                nextEvent = Event(startTime: startTime, durationMins: event.getDuration(), eventName: event.getName(), description: event.getDescription(), repetition: Repeat(rawValue: event.getRepetition())!, seriesID: seriesID)
                series.append(nextEvent)
            }
        }
        
        mutating func modifyInstance(oldEvent: Event, newEvent: Event){
            let idx = series.firstIndex(where: {$0.id == oldEvent.id})!
            series.remove(at: idx)
            series.insert(newEvent, at: idx)
        }
        
        mutating func modifySeries(oldEvent: Event, newEvent: Event){
            let tdh = TimeDateHelper()
            var idx = series.firstIndex(where: {$0.id == oldEvent.id})!
            series.remove(at: idx)
            series.insert(newEvent, at: idx)
            let startTime = tdh.getTimeOfDayHrsMins(newEvent.getStartTime())
            let timeComponents = startTime.split(separator: ":")
            let hr = Int(timeComponents[0])!
            let min = Int(timeComponents[1])!
            while idx < series.count - 1{
                idx += 1
                let time = tdh.calendar.date(bySettingHour: hr, minute: min, second: 0, of: series[idx].getStartTime())!
                series[idx].editEvent(name: newEvent.getName(), description: newEvent.getDescription(), duration: newEvent.getDuration(), repetition: Repeat(rawValue: newEvent.getRepetition())!, time: time)
            }
        }
        
        mutating func addEvent(_ event: Event){
            let idx = series.firstIndex(where: {$0.getStartTime() > event.getStartTime()}) ?? series.count
            if idx != series.count {
                series.insert(event, at: idx)
            } else {
                series.append(event)
            }
        }
        
        mutating func deleteEvent(_ event: Event){
            let idx = series.firstIndex(where: {$0.id == event.id})!
            series.remove(at: idx)
        }
        
        mutating func setHabit(_ habit: HABm.Habit){
            self.habit = habit
        }
        
        mutating func deleteHabit(){
            self.habit = nil
        }
        
        func getSeries() -> [Event]{
            return series
        }
        
        func getID() -> UUID{
            return seriesID
        }
        
        func getHabit() -> HABm.Habit?{
            return habit
        }
        
       
    }
    //MARK: -  CALm.Event
    struct Event : Hashable, Codable, Identifiable{
        
        private var dateKey: String
        private var startTime: Date
        private var durationMins: Int
        private var eventName: String
        private var description: String
        private var repetition: Repeat
        private var tasks: [TDLm.Task]?
        private var overNighter: Bool
        internal let id: UUID
        private var seriesID: UUID?
        
        //MARK: - Init
        init(startTime: Date, durationMins: Int, eventName: String, description: String, repetition: Repeat, id: UUID? = nil, eventTasks: [TDLm.Task]? = nil, seriesID: UUID? = nil){
            self.startTime = startTime
            self.durationMins = durationMins
            self.eventName = eventName
            self.description = description
            self.repetition = repetition
            self.tasks = eventTasks
            self.id = (id == nil) ? UUID() : id!
            self.seriesID = seriesID
            
            let tdh = TimeDateHelper()
            self.dateKey = tdh.dateString(startTime)
            if !tdh.calendar.isDate(startTime, inSameDayAs: tdh.calendar.date(byAdding: .minute, value: durationMins, to: startTime)!){
                self.overNighter = true
            } else {
                self.overNighter = false
            }
        }
        
        //MARK: - Protocol Stubs
        //Hashable Stub
        static func == (lhs: CALm.Event, rhs: CALm.Event) -> Bool {
            if (lhs.dateKey == rhs.dateKey) && (lhs.startTime == rhs.startTime) && (lhs.durationMins == rhs.durationMins) && (lhs.eventName == rhs.eventName) && (lhs.description == rhs.description) && (lhs.repetition == rhs.repetition) && (lhs.id == rhs.id) && (lhs.seriesID == rhs.seriesID) && (lhs.overNighter == rhs.overNighter) && (lhs.tasks == rhs.tasks){
                return true
            } else {
                return false
            }
        }
        
        // MARK: - Getters
        func getName() -> String{
            return eventName
        }
        func getStartTime() -> Date {
            return startTime
        }
        
        func getDuration() -> Int {
            return durationMins
        }
        
        func getDescription() -> String {
            return description
        }
        
        func getRepetition() -> String {
            return repetition.rawValue
        }
        
        func getDateKey() -> String {
            return dateKey
        }
        
        func getTasks() -> [TDLm.Task]{
            return tasks ?? []
        }
        
        func getID() -> UUID {
            return id
        }
        
        func getSeriesID() -> UUID? {
            return seriesID
        }
        
        func getOverNighter() -> Bool {
            return overNighter
        }
        
        //MARK: - Setters
        mutating func setDuration(_ duration: Int){
            self.durationMins = duration
        }
        
        mutating func editEvent(name: String, description: String, duration: Int, repetition: Repeat, time: Date){
            self.eventName = name
            self.description = description
            self.durationMins = duration
            self.repetition = repetition
            self.startTime = time
            
            let tdh = TimeDateHelper()
            self.dateKey = tdh.dateString(time)
        }
        
        mutating func setSeriesID(_ id: UUID){
            self.seriesID = id
        }
        
        mutating func addTask(_ task: TDLm.Task){
            if self.tasks == nil {
                self.tasks = []
            }
            self.tasks!.append(task)
        }
        
        mutating func deleteTask(_ task: TDLm.Task){
            let idx = self.tasks!.firstIndex(where: {$0.getID() == task.getID()})
            if idx != nil {
                self.tasks!.remove(at: idx!)
            }
        }
    }
    
}

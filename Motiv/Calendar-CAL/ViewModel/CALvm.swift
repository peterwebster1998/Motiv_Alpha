//
//  CALvm.swift
//  motiv-prerelease
//  --> moved to Motiv on 4/24/23
//
//  Created by Peter Webster on 10/19/22.
//

import SwiftUI

class CALvm: ObservableObject {
    
    enum viewContext {
        case Month
        case Week
        case Day
    }
    
    // MARK: - Variables
    
    @Published private var model: CALm
    @Published private(set) var viewType: viewContext
    @Published var contextSwitch: Bool
    @Published var startUp: Bool
    @Published var deleteMode: Bool
    @Published var editMode: Bool
    @Published var createEvent: Bool
    @Published var createTask: Bool
    @Published var eventConflict: Bool
    @Published var conflictResolved: Bool
    @Published var conflictsUpdated: Bool
    @Published var refreshWindows: Bool
    @Published var editSeries: Bool

    // MARK: - Init
    
    init (){
        if let url = Autosave.url, let autosavedCALm = try? CALm(url: url){
            model = autosavedCALm
        } else {
            //First time startup
            model = CALm()
        }
        
        self.viewType = viewContext.Month
        self.contextSwitch = false
        self.startUp = true
        self.createEvent = false
        self.createTask = false
        self.deleteMode = false
        self.editMode = false
        self.eventConflict = false
        self.conflictResolved = false
        self.conflictsUpdated = false
        self.refreshWindows = false
        self.editSeries = false
        
        //Removes conflicts now in the past
        model.refreshConflicts()
    }
    // MARK: - ViewModel Getters & Setters
    
    func getViewContext() -> String{
        switch viewType {
        case .Month:
            return "Month"
        case .Week:
            return "Week"
        case .Day:
            return "Day"
        }
    }
    
    func setViewContext(_ input: String){
        switch input {
        case "m":
            viewType = viewContext.Month
        case "w":
            viewType = viewContext.Week
        case "d":
            viewType = viewContext.Day
        default:
            viewType = viewContext.Day
        }
    }
    
    func getDaysEvents(_ day: String) -> [CALm.Event] {
        model.getDaysEvents(day)
    }
    
    func getDaysTasks(_ day: String) -> [TDLm.ToDoList.Task]{
        model.getDaysTasks(day)
    }
    
    func checkForConflict(day: String, event: CALm.Event) -> Bool {
        let conflict = model.checkForConflict(day: day, event: event)
        if conflict {
            addConflict(event)
        }
        return conflict
    }
    
    func getConflicts() -> [[CALm.Event]] {
        let conflictDict = model.getConflicts()
        var conflictArr : [[CALm.Event]] = []
        for day in conflictDict.keys{
            conflictArr.append(conflictDict[day]!)
        }
        return conflictArr
    }
    
    func isConflict(_ event: CALm.Event) -> Bool {
        return model.isConflict(event)
    }
    
    func getTasks(_ event: CALm.Event) -> TDLm.ToDoList? {
        return model.getTasks(event)
    }
    // MARK: - Intent(s)
    func addEventToDay(day: String, event: CALm.Event) -> Bool{
        if !checkForConflict(day: day, event: event){
            model.addEventToDay(day: day, event: event)
            autosave()
            return true
        } else {
            eventConflict = true
            createEvent = false
            return false
        }
    }
    
    func deleteEvent(_ event: CALm.Event){
        model.deleteEvent(event)
        autosave()
    }
    
    func editEvent(event: CALm.Event, name: String, description: String, duration: Int, repetition: CALm.Repeat, time: Date) -> Bool{
        // Conflict Check
        let tempTDH = TimeDateHelper()
        let newEvent = CALm.Event(dateKey: tempTDH.dateString(time), startTime: time, durationMins: duration, eventName: name, description: description, repetition: repetition, id: event.getID())
        if !eventConflict {
            let conflict = checkForConflict(day: tempTDH.dateString(time), event: newEvent)
            if !conflict {
                model.editEvent(event: event, name: name, description: description, duration: duration, repetition: repetition, time: time)
                autosave()
                return true
            } else {
                editMode = false
                eventConflict = true
                model.deleteEvent(event)
                return false
            }
        } else {
            model.editEvent(event: event, name: name, description: description, duration: duration, repetition: repetition, time: time)
            autosave()
            return true
        }
    }
    
    func editEventSeries(event: CALm.Event, name: String, description: String, duration: Int, repetition: CALm.Repeat, time: Date) -> Bool{
        // Conflict Check
        let tempTDH = TimeDateHelper()
        let newEvent = CALm.Event(dateKey: tempTDH.dateString(time), startTime: time, durationMins: duration, eventName: name, description: description, repetition: repetition, id: event.getID(), eventTasks: getTasks(event), seriesID: event.getSeriesID())
        let conflict = checkForConflict(day: tempTDH.dateString(time), event: newEvent)
        if !conflict {
            model.editEventSeries(oldEvent: event, newEvent: newEvent)
            autosave()
            return true
        } else {
            editMode = false
            eventConflict = true
            model.deleteEvent(event)
            return false
        }
    }
    func addTaskToEvent(event: CALm.Event, task: TDLm.ToDoList.Task){
        model.addTaskToEvent(event: event, task: task)
        autosave()
    }
    
    func toggleEventsTaskState(event: CALm.Event, task: TDLm.ToDoList.Task){
        model.toggleEventsTaskState(event: event, task: task)
        autosave()
    }
    
    func deleteTaskInEvent(event: CALm.Event, task: TDLm.ToDoList.Task){
        model.deleteTaskInEvent(event: event, task: task)
        autosave()
    }
    
    func addConflict(_ event: CALm.Event){
        model.addConflict(event)
        autosave()
    }
    
    func deleteConflict(_ event: CALm.Event){
        model.deleteConflict(event)
        autosave()
    }
    // MARK: - Persistence
    private func save(to url: URL){
        let thisfunc = "\(String(describing: self)).\(#function)"
        do {
            let data: Data = try model.json()
            try data.write(to: url)
            print("\(thisfunc) successful!")
        } catch {
            print("Calendar viewModel \(thisfunc) error = \(error)")
        }
    }
    
    private struct Autosave {
        static let filename = "Autosaved.calm"
        static var url: URL?{
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
    }
    
    private func autosave() {
        if let url = Autosave.url {
            save(to: url)
            print("Autosaved")
        }
    }
}

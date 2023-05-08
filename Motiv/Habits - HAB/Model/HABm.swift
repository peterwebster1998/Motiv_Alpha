//
//  HABm.swift
//  Motiv
//
//  Created by Peter Webster on 5/7/23.
//

import Foundation

struct HABm: Codable {
    
    private var habits: [Habit]
    // MARK: - Persistence
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(HABm.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try HABm(json: data)
    }
    
    // MARK: - HABm Methods
    init(){
        self.habits = [Habit(name: "Plan", notes: "If you fail to plan, you plan to fail", repetition: ["daily"])]
    }
    
    func getHabits() -> [Habit]{
        return habits
    }
    
    func getHabit(_ name: String) -> Habit?{
        return habits.first(where: {$0.getName() == name})
    }
    
    mutating func addHabit(_ habit: Habit){
        habits.append(habit)
    }
    
    mutating func deleteHabit(_ name: String) -> Bool {
        let idx = habits.firstIndex(where: {$0.getName() == name})
        if idx != nil {
            habits.remove(at: idx!)
            return true
        } else {
            return false
        }
    }
    
    mutating func updateHabit(_ habit: Habit){
        let hab = habits.contains(where: {$0.getID() == habit.getID()})
        if hab {
            let idx = habits.firstIndex(where: {$0.getID() == habit.getID()})!
            habits[idx] = habit
        } else {
            print("Could not find habit in list, added to end")
            habits.append(habit)
        }
    }
    
    // MARK: - HABm Habit
    struct Habit: Codable , Hashable{
        private let ID: UUID
        private var name: String
        private var notes: String
        private var tasks: [TDLm.Task]
        private var repetition: [String]
        private var count: Int
        private var streak: Int
        private var bestStreak: Int
        private var lastCompleted: Date
        
        init(name: String, notes: String, repetition: [String]){
            self.ID = UUID()
            self.name = name
            self.notes = notes
            self.tasks = []
            self.repetition = repetition
            self.count = 0
            self.streak = 0
            self.bestStreak = 0
            self.lastCompleted = Date().advanced(by: -86400)
        }
        
        // MARK: - Getters
        func getID() -> UUID {
            return ID
        }
        
        func getName() -> String{
            return name
        }
        
        func getNotes() -> String{
            return notes
        }
        
        func getTasks() -> [TDLm.Task]{
            return tasks
        }
        
        func getRepetition() -> [String]{
            return repetition
        }
        
        func getCount() -> Int {
            return count
        }
        
        func getStreak() -> Int {
            return streak
        }
        
        func getBestStreak() -> Int {
            return bestStreak
        }
        
        func getLastCompletion() -> Date {
            return lastCompleted
        }
        
        func getStats() -> [Int]{
            return [count, bestStreak, streak]
        }
        
        // MARK: - Setters
        mutating func complete(){
            count += 1
            lastCompleted = Date()
            manageStreaks()
        }
        
        private mutating func manageStreaks(){
            //Do stuff
        }
        
        mutating func addTask(_ task: TDLm.Task){
            tasks.append(task)
        }
        
        mutating func setName(_ str: String){
            self.name = str
        }
        
        mutating func setNotes(_ str: String){
            self.notes = str
        }
        
        mutating func deleteTask(_ task: TDLm.Task) -> Bool {
            let idx = tasks.firstIndex(where: {$0.getID() == task.getID()})
            if idx != nil {
                tasks.remove(at: idx!)
                return true
            } else {
                return false
            }
        }
        
        mutating func updateTask(_ task: TDLm.Task) -> Bool {
            let idx = tasks.firstIndex(where: {$0.getID() == task.getID()})
            if idx != nil {
                tasks[idx!] = task
                return true
            } else {
                return false
            }
        }
    }
}

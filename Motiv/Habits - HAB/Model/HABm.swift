//
//  HABm.swift
//  Motiv
//
//  Created by Peter Webster on 5/7/23.
//

import Foundation

struct HABm: Codable {
    
    
    
    struct Habit: Codable {
        private var name: String
        private var notes: String
        private var tasks: [TDLm.Task]
        private var repetition: [String]
        private var count: Int
        private var streak: Int
        private var streakRecord: Int
        private var lastCompleted: Date
        
        init(name: String, notes: String, repetition: [String]){
            self.name = name
            self.notes = notes
            self.tasks = []
            self.repetition = repetition
            self.count = 0
            self.streak = 0
            self.streakRecord = 0
            self.lastCompleted = Date()
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
        
        func getRecord() -> Int {
            return streakRecord
        }
        
        func getLastCompletion() -> Date {
            return lastCompleted
        }
    }
}

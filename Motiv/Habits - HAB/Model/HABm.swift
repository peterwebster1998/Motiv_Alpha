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
        self.habits = [Habit(name: "Plan", notes: "When you fail to plan, you plan to fail - Richard Williams", repetition: (.Daily, 1))]
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
    struct Habit: Codable, Hashable {
        private let ID: UUID
        private var name: String
        private var notes: String
        private var tasks: [TDLm.Task]
        private var repetition: (repetitionPeriod, Int)
        private var count: Int
        private var streak: Int
        private var bestStreak: Int
        private var lastStreakDay: Date
        private var lastCompleted: Date
        private var lastCompletedCount: Int
        private var undoState: (Int, Int, Int, Date, Date, Int)

        enum repetitionPeriod : String, Identifiable, CaseIterable, Hashable, Codable {
            case Daily = "Daily"
            case Weekly = "Weekly"
            case Monthly = "Monthly"
            case Quarterly = "Quarterly"
            case Annually = "Annually"
            case Decennially = "Decennially"
            case Centennially = "Centennially"
            
            var id: String { self.rawValue }
        }
        
        init(name: String, notes: String, repetition: (repetitionPeriod, Int)){
            self.ID = UUID()
            self.name = name
            self.notes = notes
            self.tasks = []
            self.repetition = repetition
            self.count = 0
            self.streak = 0
            self.bestStreak = 0
            self.lastStreakDay = Date(timeIntervalSince1970: 0)
            self.lastCompleted = Date(timeIntervalSince1970: 0)
            self.lastCompletedCount = 0
            self.undoState = (self.count, self.streak, self.bestStreak, self.lastStreakDay, self.lastCompleted, self.lastCompletedCount)
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
            return [repetition.0.rawValue, String(repetition.1)]
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
            undoState = (count, streak, bestStreak, lastStreakDay, lastCompleted, lastCompletedCount)
            count += 1
            manageStreaks()
        }
        
        private mutating func manageStreaks(){
            let tdh = TimeDateHelper()
            let now = Date()
            var cont = true
            
            /* CURRENT DECISION ON STREAK LOGIC
             - streak can only be increased once per day
             - streak is not lost until >timePeriod has passed since lastCompleted
             - lastCompletion is only updated after timePeriods requirement is met, starting a new timePeriod
             */
            
            // Update last completion
            if !tdh.calendar.isDate(lastCompleted, inSameDayAs: now){
                if count == lastCompletedCount + repetition.1 {
                    lastCompleted = now
                    lastCompletedCount = count
                }
            } else if tdh.calendar.isDate(lastStreakDay, inSameDayAs: now){
                cont = false
            } else {
                cont = false
            }
            
            // Update streaks if appropriate
            if cont {
                switch repetition.0 {
                case .Daily:
                    if now < tdh.calendar.date(byAdding: .day, value: 1, to: lastCompleted)!{
                        streak += 1
                    } else {
                        streak = 1
                    }
                case .Weekly:
                    if now < tdh.calendar.date(byAdding: .day, value: 7, to: lastCompleted)!{
                        streak += 1
                    } else {
                        streak = 1
                    }
                case .Monthly:
                    if now < tdh.calendar.date(byAdding: .month, value: 1, to: lastCompleted)!{
                        streak += 1
                    } else {
                        streak = 1
                    }
                case .Quarterly:
                    if now < tdh.calendar.date(byAdding: .quarter, value: 1, to: lastCompleted)!{
                        streak += 1
                    } else {
                        streak = 1
                    }
                case .Annually:
                    if now < tdh.calendar.date(byAdding: .year, value: 1, to: lastCompleted)!{
                        streak += 1
                    } else {
                        streak = 1
                    }
                case .Decennially:
                    if now < tdh.calendar.date(byAdding: .year, value: 10, to: lastCompleted)!{
                        streak += 1
                    } else {
                        streak = 1
                    }
                case .Centennially:
                    if now < tdh.calendar.date(byAdding: .year, value: 100, to: lastCompleted)!{
                        streak += 1
                    } else {
                        streak = 1
                    }
                }
                
                if streak > bestStreak {
                    bestStreak = streak
                }
                lastStreakDay = now
            }
        }
        
        mutating func undoComplete(){
            count = undoState.0
            streak = undoState.1
            bestStreak = undoState.2
            lastStreakDay = undoState.3
            lastCompleted = undoState.4
            lastCompletedCount = undoState.5
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
        
        mutating func setRepetition(_ arr: (repetitionPeriod, Int)){
            self.repetition = arr
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
        
        // MARK: - Protocol Stubs
        static func == (lhs: HABm.Habit, rhs: HABm.Habit) -> Bool {
            return (lhs.ID == rhs.ID) && (lhs.name == rhs.name) && (lhs.notes == rhs.notes) && (lhs.tasks == rhs.tasks) && (lhs.repetition == rhs.repetition) && (lhs.count == rhs.count) && (lhs.streak == rhs.streak) && (lhs.bestStreak == rhs.bestStreak) && (lhs.lastStreakDay == rhs.lastStreakDay) && (lhs.lastCompleted == rhs.lastCompleted) && (lhs.lastCompletedCount == rhs.lastCompletedCount) && (lhs.undoState == rhs.undoState)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ID)
            hasher.combine(name)
            hasher.combine(notes)
            hasher.combine(tasks)
            hasher.combine(repetition.0)
            hasher.combine(repetition.1)
            hasher.combine(count)
            hasher.combine(streak)
            hasher.combine(bestStreak)
            hasher.combine(lastStreakDay)
            hasher.combine(lastCompleted)
            hasher.combine(lastCompletedCount)
            hasher.combine(undoState.0)
            hasher.combine(undoState.1)
            hasher.combine(undoState.2)
            hasher.combine(undoState.3)
            hasher.combine(undoState.4)
            hasher.combine(undoState.5)
        }
        
        enum CodingKeys: String, CodingKey {
            case ID
            case name
            case notes
            case tasks
            case repetitionPeriod
            case repetitionCount
            case count
            case streak
            case bestStreak
            case lastStreakDay
            case lastCompleted
            case lastCompletedCount
            case undoStateCount
            case undoStateStreak
            case undoStateBestStreak
            case undoStateLastStreakDay
            case undoStateLastCompleted
            case undoStateLastCompletedCount
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            ID = try values.decode(UUID.self, forKey: .ID)
            name = try values.decode(String.self, forKey: .name)
            notes = try values.decode(String.self, forKey: .notes)
            tasks = try values.decode([TDLm.Task].self, forKey: .tasks)
            let repetitionPeriod = try values.decode(Habit.repetitionPeriod.self, forKey: .repetitionPeriod)
            let repetitionCount = try values.decode(Int.self, forKey: .repetitionCount)
            repetition = (repetitionPeriod, repetitionCount)
            count = try values.decode(Int.self, forKey: .count)
            streak = try values.decode(Int.self, forKey: .streak)
            bestStreak = try values.decode(Int.self, forKey: .bestStreak)
            lastStreakDay = try values.decode(Date.self, forKey: .lastStreakDay)
            lastCompleted = try values.decode(Date.self, forKey: .lastCompleted)
            lastCompletedCount = try values.decode(Int.self, forKey: .lastCompletedCount)
            let undoStateCount = try values.decode(Int.self, forKey: .undoStateCount)
            let undoStateStreak = try values.decode(Int.self, forKey: .undoStateStreak)
            let undoStateBestStreak = try values.decode(Int.self, forKey: .undoStateBestStreak)
            let undoStateLastStreakDay = try values.decode(Date.self, forKey: .undoStateLastStreakDay)
            let undoStateLastCompleted = try values.decode(Date.self, forKey: .undoStateLastCompleted)
            let undoStateLastCompletedCount = try values.decode(Int.self, forKey: .undoStateLastCompletedCount)
            undoState = (undoStateCount, undoStateStreak, undoStateBestStreak, undoStateLastStreakDay, undoStateLastCompleted, undoStateLastCompletedCount)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(ID, forKey: .ID)
            try container.encode(name, forKey: .name)
            try container.encode(notes, forKey: .notes)
            try container.encode(tasks, forKey: .tasks)
            try container.encode(repetition.0, forKey: .repetitionPeriod)
            try container.encode(repetition.1, forKey: .repetitionCount)
            try container.encode(count, forKey: .count)
            try container.encode(streak, forKey: .streak)
            try container.encode(bestStreak, forKey: .bestStreak)
            try container.encode(lastStreakDay, forKey: .lastStreakDay)
            try container.encode(lastCompleted, forKey: .lastCompleted)
            try container.encode(lastCompletedCount, forKey: .lastCompletedCount)
            try container.encode(undoState.0, forKey: .undoStateCount)
            try container.encode(undoState.1, forKey: .undoStateStreak)
            try container.encode(undoState.2, forKey: .undoStateBestStreak)
            try container.encode(undoState.3, forKey: .undoStateLastStreakDay)
            try container.encode(undoState.4, forKey: .undoStateLastCompleted)
            try container.encode(undoState.5, forKey: .undoStateLastCompletedCount)
        }
    }
}

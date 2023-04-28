//
//  TDLm.swift
//  Motiv
//
//  Created by Peter Webster on 4/25/23.
//

import Foundation

struct TDLm : Codable{
    private var taskDict : [UUID: Task]
    private var tasksListDict : [String: [Task]]
    private var subtaskDict: [UUID: [Task]]
    
    // MARK: - Persistence
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(TDLm.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try TDLm(json: data)
    }
    // MARK: - TDLm Methods
    init(){
        self.taskDict = [:]
        self.tasksListDict = [:]
        self.subtaskDict = [:]
        
        self.tasksListDict["General To Dos"] = []
        self.tasksListDict["Bucket List"] = []
    }
    
    func getTask(_ ID: UUID) -> Task? {
        return taskDict[ID]
    }
    
    func getSubtasks(_ ID: UUID) -> [Task] {
        return subtaskDict[ID] ?? []
    }
    
    func getTaskList(_ key: String) -> [Task]{
        return tasksListDict[key] ?? []
    }
    
    func getTaskListKeys() -> [String]{
        return tasksListDict.keys.sorted()
    }
    
    mutating func addList(_ str: String){
        if tasksListDict[str] == nil{
            tasksListDict[str] = []
        }
    }
    
    mutating func addTask(key: String, name: String, description: String?, parentTaskID: UUID?, deadline: Date?){
        var task = Task(key: key, name: name, description: description, parentTaskID: parentTaskID, deadline: deadline)
        
        // If no deadline but is subtask, check parentTask for deadline
        if deadline == nil && parentTaskID != nil {
            task.setDeadline(taskDict[parentTaskID!]!.getDeadline())
        } else {
            //Cannot have a deadline that exceeds that of a parent task
            if parentTaskID != nil && taskDict[parentTaskID!]!.getDeadline() != nil{
                task.setDeadline((deadline! < taskDict[parentTaskID!]!.getDeadline()!) ? deadline : taskDict[parentTaskID!]!.getDeadline())
            }
        }
        
        //Add corrected task to relevant dicts
        taskDict[task.getID()] = task
        
        if tasksListDict[key] == nil {
            tasksListDict[key] = []
        }
        tasksListDict[key]!.append(task)
        
        if parentTaskID != nil {
            if subtaskDict[parentTaskID!] == nil {
                subtaskDict[parentTaskID!] = []
                var parentTask = taskDict[parentTaskID!]!
                parentTask.setHasSubtasks(true)
                updateTask(parentTask)
            }
            subtaskDict[parentTaskID!]!.append(task)
        }
    }
    
    mutating func updateTask(_ task: Task){
        let ID = task.getID()
        let key = task.getKey()
        taskDict[ID] = task
        
        let idx = tasksListDict[key]!.firstIndex(where: {$0.getID() == ID})!
        tasksListDict[key]!.insert(task, at: idx)
        tasksListDict[key]!.remove(at: idx+1)
        
        if task.isSubtask() {
            let parentID = task.getParentTaskID()!
            let idxx = subtaskDict[parentID]!.firstIndex(where: {$0.getID() == ID})!
            subtaskDict[parentID]!.insert(task, at: idxx)
            subtaskDict[parentID]!.remove(at: idxx+1)
        }
        
        if task.containsSubtasks() && task.getDeadline() != nil {
            //Adjust deadlines of subtasks appropriately
            let deadline = task.getDeadline()!
            for sub in subtaskDict[ID]! {
                if sub.getDeadline() != nil{
                    if deadline < sub.getDeadline()!{
                        var subTask = sub
                        subTask.setDeadline(deadline)
                        updateTask(subTask)
                    }
                }
            }
        }
    }
    
    mutating func deleteTask(_ ID: UUID) -> Bool{
        if taskDict[ID] == nil {
            return false
        } else {
            //Solo Task
            let task = taskDict[ID]!
            taskDict.removeValue(forKey: ID)
            
            //Remove from task list
            let taskList = tasksListDict[task.getKey()]
            if taskList != nil {
                let idx = taskList!.firstIndex(where: {$0.getID() == ID})!
                if taskList!.count > 1 {
                    tasksListDict[task.getKey()]!.remove(at: idx)
                } else {
                    tasksListDict.removeValue(forKey: task.getKey())
                }
            }
            
            //Remove Subtasks
            if task.containsSubtasks(){
                let subTasks = subtaskDict[ID]!
                for sub in subTasks{
                    let outcome = deleteTask(sub.getID())
                    if !outcome {
                        print("Failed removing subtasks")
                    }
                }
            }
            
            //Remove self as subtask
            if task.isSubtask() {
                let idx = subtaskDict[task.getParentTaskID()!]!.firstIndex(where: {$0.getID() == ID})!
                subtaskDict[task.getParentTaskID()!]!.remove(at: idx)
                if subtaskDict[task.getParentTaskID()!]!.count == 0 {
                    subtaskDict.removeValue(forKey: task.getParentTaskID()!)
                }
            }
            return true
        }
    }
    // MARK: - TDLm.Task
    struct Task: Codable {
        private let id: UUID
        private let key: String
        private var name: String
        private var description: String?
        private var completed: Bool
        private let parentTaskID: UUID?
        private var hasSubtasks: Bool
        private var deadline: Date?
        
        // MARK: - Init
        init(key: String, name: String, description: String?, parentTaskID: UUID?, deadline: Date?){
            self.id = UUID()
            self.key = key
            self.name = name
            self.description = description
            self.completed = false
            self.parentTaskID = parentTaskID
            self.hasSubtasks = false
            self.deadline = deadline
        }
        
        // MARK: - Getters
        func getID() -> UUID {
            return self.id
        }
        
        func getKey() -> String {
            return self.key
        }
        
        func getName() -> String {
            return self.name
        }
        
        func getDescription() -> String {
            return self.description ?? ""
        }
        
        func getCompleted() -> Bool {
            return self.completed
        }
        
        func getParentTaskID() -> UUID? {
            return self.parentTaskID
        }
        
        func containsSubtasks() -> Bool {
            return self.hasSubtasks
        }
        
        func isSubtask() -> Bool {
            return (self.parentTaskID == nil) ? false : true
        }
        
        func getDeadline() -> Date? {
            return self.deadline
        }
        
        // MARK: - Setters
        mutating func setDeadline(_ time: Date?){
            self.deadline = time
        }
        
        mutating func setHasSubtasks(_ val: Bool){
            self.hasSubtasks = val
        }
        
    }
}

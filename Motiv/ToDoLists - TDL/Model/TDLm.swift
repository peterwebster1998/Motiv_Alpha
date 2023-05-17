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
    
    func getTodaysToDos() -> [Task]{
        let tdh = TimeDateHelper()
        var taskList = getTaskList(tdh.dateString(Date()))
        taskList.append(contentsOf: getTaskList("General To Dos"))
        return taskList
    }
    
    func existsInTDL(_ task: Task) -> Bool{
        return (taskDict[task.getID()] != nil) ? true : false
    }
    
    mutating func addList(_ str: String){
        if tasksListDict[str] == nil{
            tasksListDict[str] = []
        }
    }
    
    mutating func deleteList(_ str: String){
        if tasksListDict[str] != nil {
            let taskList = tasksListDict[str]!
            for t in taskList {
                let out = deleteTask(t.getID())
                if !out { print("Failed to delete task: \(t.getName())")}
            }
            tasksListDict.removeValue(forKey: str)
            print("Deleted List: \(str)")
        }
    }
    
    mutating func editListName(_ newName: String, listname: String){
        let list = tasksListDict[listname]!
        for i in list {
            addTask(key: newName, name: i.getName(), description: (i.getDescription() == "") ? nil : i.getDescription(), parentTaskID: i.getParentTaskID(), deadline: i.getDeadline())
            if i.isParentTask() {
                var subs = subtaskDict[i.getID()]!
                var idx = 0
                var newParentIDidx: [Int] = []
                var parentID = [tasksListDict[newName]!.first(where: {$0.getName() == i.getName()})!.getID()]
                while idx != subs.count {
                    if newParentIDidx.count != 0 {
                        if idx == newParentIDidx[0]{
                            newParentIDidx.removeFirst()
                            parentID.removeFirst()
                        }
                    }
                    addTask(key: newName, name: subs[idx].getName(), description: (subs[idx].getDescription() == "") ? nil : subs[idx].getDescription(), parentTaskID: parentID[0], deadline: subs[idx].getDeadline())
                    if subs[idx].isParentTask() {
                        newParentIDidx.append(subs.count)
                        subs.append(contentsOf: subtaskDict[subs[idx].getID()]!)
                        parentID.append(subtaskDict[parentID[0]]!.first(where: {$0.getName() == subs[idx].getName()})!.getID())
                    }
                    idx += 1
                }
            }
        }
        deleteList(listname)
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
        
        if parentTaskID == nil {
            if tasksListDict[key] == nil {
                tasksListDict[key] = []
            }
            tasksListDict[key]!.append(task)
        }
        
        if deadline != nil {
            let tdh = TimeDateHelper()
            let dateKey = tdh.dateString(task.getDeadline()!)
            if tasksListDict[dateKey] == nil {
                tasksListDict[dateKey] = []
            }
            tasksListDict[dateKey]!.append(task)
        }
        
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
        let oldTask = taskDict[ID]!
        var newTask = task
        let tdh = TimeDateHelper()
        
        if oldTask.getDeadline() != nil {
            let deadline = oldTask.getDeadline()!
            let dateKey = tdh.dateString(deadline)
            let idx = tasksListDict[dateKey]!.firstIndex(where: {$0.getID() == ID})!
            if newTask.getDeadline() != nil {
                if dateKey != tdh.dateString(newTask.getDeadline()!) {
                    tasksListDict[dateKey]!.remove(at: idx)
                    if tasksListDict[dateKey]!.count == 0 {
                        tasksListDict.removeValue(forKey: dateKey)
                    }
                    var newDateKey = tdh.dateString(newTask.getDeadline()!)
                    if newTask.isSubtask() && taskDict[newTask.getParentTaskID()!]!.getDeadline() != nil {
                        if newTask.getDeadline()! > taskDict[newTask.getParentTaskID()!]!.getDeadline()! {
                            newDateKey = tdh.dateString(taskDict[newTask.getParentTaskID()!]!.getDeadline()!)
                            newTask.setDeadline(taskDict[newTask.getParentTaskID()!]!.getDeadline())
                        }
                    }
                    if tasksListDict[newDateKey] == nil {
                        tasksListDict[newDateKey] = []
                    }
                    tasksListDict[newDateKey]!.append(newTask)
                } else {
                    tasksListDict[dateKey]!.insert(newTask, at: idx)
                    tasksListDict[dateKey]!.remove(at: idx+1)
                }
            } else {
                tasksListDict[dateKey]!.remove(at: idx)
                if tasksListDict[dateKey]!.count == 0 {
                    tasksListDict.removeValue(forKey: dateKey)
                }
            }
        } else {
            if newTask.getDeadline() != nil {
                let newDateKey = tdh.dateString(newTask.getDeadline()!)
                if tasksListDict[newDateKey] == nil {
                    tasksListDict[newDateKey] = []
                }
                tasksListDict[newDateKey]!.append(newTask)
                
            }
        }
        
        taskDict[ID] = newTask
        
        if !newTask.isSubtask() {
            let idx = tasksListDict[key]!.firstIndex(where: {$0.getID() == ID})!
            tasksListDict[key]!.insert(newTask, at: idx)
            tasksListDict[key]!.remove(at: idx+1)
        } else {
            let parentID = newTask.getParentTaskID()!
            let idxx = subtaskDict[parentID]!.firstIndex(where: {$0.getID() == ID})!
            subtaskDict[parentID]!.insert(newTask, at: idxx)
            subtaskDict[parentID]!.remove(at: idxx+1)
        }
        
        if newTask.isParentTask() && newTask.getDeadline() != nil {
            //Adjust deadlines of subtasks appropriately
            let deadline = newTask.getDeadline()!
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
            
            //Remove Subtasks
            if task.isParentTask(){
                let subTasks = subtaskDict[ID]!
                for sub in subTasks{
                    let outcome = deleteTask(sub.getID())
                    if !outcome {
                        print("Failed removing subtasks")
                    }
                }
            }
            
            //Remove from task list if not subtask
            if !task.isSubtask() {
                let taskList = tasksListDict[task.getKey()]
                if taskList != nil {
                    let idx = taskList!.firstIndex(where: {$0.getID() == ID})!
                    if taskList!.count > 1 {
                        tasksListDict[task.getKey()]!.remove(at: idx)
                    } else {
                        tasksListDict.removeValue(forKey: task.getKey())
                    }
                }
            } else {
                //Remove self as subtask
                if task.isSubtask() {
                    let idx = subtaskDict[task.getParentTaskID()!]!.firstIndex(where: {$0.getID() == ID})!
                    subtaskDict[task.getParentTaskID()!]!.remove(at: idx)
                    if subtaskDict[task.getParentTaskID()!]!.count == 0 {
                        var parentTask = taskDict[task.getParentTaskID()!]!
                        parentTask.setHasSubtasks(false)
                        updateTask(parentTask)
                        subtaskDict.removeValue(forKey: task.getParentTaskID()!)
                    }
                }
            }
            
            if task.getDeadline() != nil {
                let tdh = TimeDateHelper()
                let dateKey = tdh.dateString(task.getDeadline()!)
                let idx = tasksListDict[dateKey]!.firstIndex(where: {$0.getID() == ID})!
                tasksListDict[dateKey]!.remove(at: idx)
                if tasksListDict[dateKey]!.count == 0{
                    tasksListDict.removeValue(forKey: dateKey)
                }
            }
            
            taskDict.removeValue(forKey: ID)
            print("\tDeleted Task: \(task.getName())")
            
            return true
        }
    }
    
    // MARK: - TDLm.Task
    struct Task: Codable, Hashable {
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
        
        func isSubtask() -> Bool {
            return (self.parentTaskID == nil) ? false : true
        }
        
        func isParentTask() -> Bool {
            return self.hasSubtasks
        }
        func getDeadline() -> Date? {
            return self.deadline
        }
        
        // MARK: - Setters
        mutating func setName(_ str: String){
            if str != "" {
                self.name = str
            }
        }
        mutating func setDescription(_ str: String){
            if str == "" {
                self.description = nil
            } else {
                self.description = str
            }
        }
        mutating func setDeadline(_ time: Date?){
            self.deadline = time
        }
        
        mutating func setHasSubtasks(_ val: Bool){
            self.hasSubtasks = val
        }
        
        mutating func toggleCompletion(){
            self.completed.toggle()
        }
        
    }
}

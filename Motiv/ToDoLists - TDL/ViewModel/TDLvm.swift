//
//  TDLvm.swift
//  Motiv
//
//  Created by Peter Webster on 4/26/23.
//

import SwiftUI

class TDLvm: ObservableObject {
    
    enum TDLviewTypes {
        case ToDoLists
        case ToDosByDay
        case AllToDos
        case List
        case Task
        
        func toString() -> String {
            switch self {
            case .ToDoLists:
                return "lists"
            case .ToDosByDay:
                return "byDay"
            case .AllToDos:
                return "all"
            case .List:
                return "list"
            case .Task:
                return "task"
            }
        }
    }
    // MARK: - Variables
    @Published private var model: TDLm
    @Published private(set) var viewContext: TDLviewTypes
    @Published var previousViewContext: String?
    @Published var selectedList: String?
    @Published var selectedTask: TDLm.Task?
    @Published var createMode: Bool
    
    // MARK: - Init
    init (){
        if let url = Autosave.url, let autosavedTDLm = try? TDLm(url: url){
            model = autosavedTDLm
        } else {
            //First time startup
            model = TDLm()
        }
        
        self.viewContext = TDLviewTypes.ToDoLists
        self.createMode = false
    }
    // MARK: - ViewModel Getters & Setters
    func getViewContext() -> TDLviewTypes{
        return self.viewContext
    }
    
    func setViewContext(_ input: String){
        switch input {
        case "task":
            viewContext = .Task
        case "all":
            viewContext = .AllToDos
        case "byDay":
            viewContext = .ToDosByDay
        case "lists":
            viewContext = .ToDoLists
        case "list":
            viewContext = .List
        default:
            viewContext = .ToDoLists
        }
    }
    func getTask(_ ID: UUID) -> TDLm.Task? {
        return model.getTask(ID)
    }
    
    func getSubtasks(_ ID: UUID) -> [TDLm.Task]{
        return model.getSubtasks(ID)
    }
    
    func getTaskListKeys() -> [String]{
        return model.getTaskListKeys()
    }
    
    func getTaskList(_ key: String) -> [TDLm.Task]{
        return model.getTaskList(key)
    }
    
    func getAllTaskLists() -> [[TDLm.Task]]{
        let keys = getTaskListKeys()
        var lists: [[TDLm.Task]] = [[]]
        for k in keys {
            lists.append(getTaskList(k))
        }
        return lists
    }
    
    func addTask(key: String, name: String, description: String?, parentTaskID: UUID?, deadline: Date?){
        model.addTask(key: key, name: name, description: description, parentTaskID: parentTaskID, deadline: deadline)
        if parentTaskID != nil {
            selectedTask = model.getTask(parentTaskID!)
        }
        autosave()
    }
    
    func deleteTask(_ ID: UUID){
        let result = model.deleteTask(ID)
        print((result) ? "delete successful" : "delete unsuccessful")
        autosave()
    }
    
    func updateTask(_ task: TDLm.Task){
        model.updateTask(task)
        autosave()
    }
    
    func addList(_ str: String){
        model.addList(str)
        autosave()
    }
    
    func getCompletionStatus(_ str: String) -> String {
        switch viewContext {
        case .List:
            let task = model.getTaskList(selectedList!).first(where: {$0.getName() == str})
            if task == nil {
                return ""
            }
            let subs = model.getSubtasks(task!.getID())
            let count = subs.count
            if count != 0 {
                let completed = subs.filter({$0.getCompleted()}).count
                return "\(completed)/\(count)"
            } else {
                return ""
            }
        case .Task:
            let task = selectedTask
            let subs = model.getSubtasks(task!.getID())
            if subs.first(where: {$0.getName() == str}) != nil {
                let subTask = subs.first(where: {$0.getName() == str})!
                if subTask.isParentTask(){
                    let sublist = getSubtasks(subTask.getID())
                    return "\(sublist.filter({$0.getCompleted()}).count)/\(sublist.count)"
                } else {
                    return ""
                }
            }
            let count = subs.count
            if count != 0 {
                let completed = subs.filter({$0.getCompleted()}).count
                return "\(completed)/\(count)"
            } else {
                return ""
            }
        default:
            let list = model.getTaskList(str)
            let count = list.count
            let completed = list.filter({$0.getCompleted()}).count
            return "\(completed)/\(count)"
        }
    }
    
    // MARK: - Persistence
    private func save(to url: URL){
        let thisfunc = "\(String(describing: self)).\(#function)"
        do {
            let data: Data = try model.json()
            try data.write(to: url)
            print("\(thisfunc) successful!")
        } catch {
            print("ToDoList viewModel \(thisfunc) error = \(error)")
        }
    }
    
    private struct Autosave {
        static let filename = "Autosaved.tdlm"
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


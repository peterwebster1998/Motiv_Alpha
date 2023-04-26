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
        case Task
    }
    // MARK: - Variables
    @Published private var model: TDLm
    @Published private(set) var viewContext: TDLviewTypes
    
    // MARK: - Init
    init (){
        if let url = Autosave.url, let autosavedTDLm = try? TDLm(url: url){
            model = autosavedTDLm
        } else {
            //First time startup
            model = TDLm()
        }
        
        self.viewContext = TDLviewTypes.ToDoLists
    }
    // MARK: - ViewModel Getters & Setters
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
    }
    
    func deleteTask(_ ID: UUID){
        let result = model.deleteTask(ID)
        print((result) ? "delete successful" : "delete unsuccessful")
    }
    
    func updateTask(_ task: TDLm.Task){
        model.updateTask(task)
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


//
//  TDLm.swift
//  Motiv
//
//  Created by Peter Webster on 4/25/23.
//

import Foundation

struct TDLm {
    private var tasksDict : [String: [Task]]
    private var subtaskDict: [UUID: [Task]]
    
    init(){
        self.tasksDict = [:]
        self.subtaskDict = [:]
    }
    
    struct Task {
        private let id: UUID
        private let key: String
        private var name: String
        private var description: String?
        private var completed: Bool
        private let parentTaskID: UUID?
        private var hasSubtasks: Bool
        
        init(key: String, name: String, description: String?, parentTaskID: UUID?){
            self.id = UUID()
            self.key = key
            self.name = name
            self.description = description
            self.completed = false
            self.parentTaskID = parentTaskID
            self.hasSubtasks = false
        }
        
    }
}

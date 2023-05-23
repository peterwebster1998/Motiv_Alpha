//
//  HABvm.swift
//  Motiv
//
//  Created by Peter Webster on 5/7/23.
//

import SwiftUI

class HABvm: ObservableObject {
    
    enum HABviewTypes {
        case All
        case One
        case New
        case Task
    }
    
    // MARK: - Variables
    @Published private var model: HABm
    @Published private(set) var viewContext: HABviewTypes
    @Published var selectedHabit: HABm.Habit?
    @Published var selectedTask: TDLm.Task?
    @Published var updated: Bool
    @Published var deleteMode: Bool
    @Published var addTask: Bool
    @Published var addNote: Bool
    @Published var pressAndHold: Bool
    @Published var habitElement: String
    
    // MARK: - Init
    init (){
        if let url = Autosave.url, let autosavedHABm = try? HABm(url: url){
            model = autosavedHABm
        } else {
            //First time startup
            model = HABm()
        }
        
        self.viewContext = .All
        self.updated = false
        self.deleteMode = false
        self.addTask = false
        self.addNote = false
        self.pressAndHold = false
        self.habitElement = ""
    }
    
    // MARK: - ViewModel Getters & Setters
    func setViewContext(_ str: String){
        switch str {
        case "all":
            viewContext = .All
        case "one":
            viewContext = .One
        case "new":
            viewContext = .New
        case "task":
            viewContext = .Task
        default:
            viewContext = .All
        }
    }
    func getHabits() -> [HABm.Habit]{
        return model.getHabits()
    }
    
    func getHabit(_ name: String) -> HABm.Habit?{
        return model.getHabit(name)
    }
    
    func addHabit(_ habit: HABm.Habit){
        model.addHabit(habit)
        updated = true
        autosave()
    }
    
    func deleteHabit(_ name: String) -> Bool {
        let result = model.deleteHabit(name)
        updated = true
        autosave()
        return result
    }
    
    func updateHabit(_ habit: HABm.Habit){
        model.updateHabit(habit)
        updated = true
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
            print("Habits viewModel \(thisfunc) error = \(error)")
        }
    }
    
    private struct Autosave {
        static let filename = "Autosaved.habm"
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

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
    }
    
    // MARK: - Variables
    @Published private var model: HABm
    @Published private(set) var viewContext: HABviewTypes
    @Published var selectedHabit: HABm.Habit?
    
    // MARK: - Init
    init (){
        if let url = Autosave.url, let autosavedHABm = try? HABm(url: url){
            model = autosavedHABm
        } else {
            //First time startup
            model = HABm()
        }
        
        self.viewContext = .All
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
    }
    
    func deleteHabit(_ name: String) -> Bool {
        return model.deleteHabit(name)
    }
    
    func updateHabit(_ habit: HABm.Habit){
        model.updateHabit(habit)
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

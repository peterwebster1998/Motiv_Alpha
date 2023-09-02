/*
  HomeViewModel.swift
  Motiv

  Created by Peter Webster on 4/25/23.

 //
 //  HomeViewModel.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 4/11/23.
 //
*/

import SwiftUI

class HomeViewModel : ObservableObject {
    
    @Published private var model: HomeModel
    @Published var currentActiveModule: HomeModel.Module?
    @Published var appSelect: Bool
    @Published var dragFinished: Bool

    init(){
        if let url = Autosave.url, let autosavedHomeModel = try? HomeModel(url: url){
            model = autosavedHomeModel
        } else {
            //First time startup
            model = HomeModel()
        }
        
        self.currentActiveModule = nil
        self.appSelect = false
        self.dragFinished = false
    }
    
    func getApps() -> [HomeModel.Module]{
        return model.getApps()
    }
    
    func getNavBubbleApps() -> [HomeModel.Module]{
        return model.getNavBubbleApps()
    }
    
    func getDailyPlan() -> ([TDLm.Task], [HABm.Habit]){
        return model.getDailyPlan()
    }
    
    func getCompletedPlanItems() -> ([TDLm.Task], [HABm.Habit]){
        return model.getCompletedPlanItems()
    }
    // MARK: - Intents
    func addModule(name: String, appImage: String, view: HomeModel.Module.ModuleType){
        model.addModule(HomeModel.Module(name: name, appImage: appImage, view: view))
        autosave()
    }
    
    func addToDailyPlan(_ arr: [TDLm.Task]){
        var localArr = arr
        while localArr.count != 0 {
            model.addToDailyPlan(localArr.removeFirst())
        }
        model.updateDailyPlanStatus()
        autosave()
    }
    
    func addToDailyPlan(_ arr: [HABm.Habit]){
        var localArr = arr
        while localArr.count != 0 {
            model.addToDailyPlan(localArr.removeFirst())
        }
        model.updateDailyPlanStatus()
        autosave()
    }
    
    func togglePlanItemCompletion(_ task: TDLm.Task){
        model.togglePlanItemCompletion(task)
        autosave()
    }
    
    func togglePlanItemCompletion(_ habit: HABm.Habit){
        model.togglePlanItemCompletion(habit)
        autosave()
    }
    
    func newDaysPlan(){
        model.planned()
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
            print("Home viewModel: \(thisfunc) \nError = \(error)")
        }
    }
    
    private struct Autosave {
        static let filename = "Autosaved.homeModel"
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

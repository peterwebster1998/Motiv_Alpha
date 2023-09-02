/*
  HomeModel.swift
  Motiv

  Created by Peter Webster on 4/25/23.

 //
 //  HomeModel.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 4/11/23.
 //
*/

import Foundation
import SwiftUI

struct HomeModel : Codable{
    private var apps: [Module]
    private var navBubbleAppShortcuts: [Module]
    private var dailyPlan: ([TDLm.Task], [HABm.Habit])
    private var completedPlanItems: ([TDLm.Task], [HABm.Habit])
    
    // MARK: - Persistence
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(HomeModel.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try HomeModel(json: data)
    }
    
    //MARK: - HomeModel Methods
    init(){
        self.apps = []
        apps.append(Module(name: "ToDo's", appImage: "checklist", view: .TDL))
        apps.append(Module(name: "Calendar", appImage: "calendar", view: .CAL))
        apps.append(Module(name: "Habits", appImage: "person.fill.checkmark", view: .HAB))
        self.navBubbleAppShortcuts = apps
        apps.append(Module(name: "FlashCards", appImage: "rectangle.stack", view: .FLC))
        apps.append(Module(name: "Recipe Box", appImage: "list.bullet.rectangle", view: .RBX))
        self.dailyPlan = ([],[])
        self.completedPlanItems = ([],[])
    }
    
    func getApps() -> [Module]{
        return apps
    }
    
    mutating func addModule(_ new: Module){
        apps.append(new)
    }
    
    func getNavBubbleApps() -> [Module]{
        return navBubbleAppShortcuts
    }
    
    func getDailyPlan() -> ([TDLm.Task], [HABm.Habit]){
        return dailyPlan
    }
    
    func getCompletedPlanItems() -> ([TDLm.Task], [HABm.Habit]){
        return completedPlanItems
    }
    
    mutating func addToDailyPlan(_ task: TDLm.Task){
        dailyPlan.0.append(task)
    }
    
    mutating func addToDailyPlan(_ habit: HABm.Habit){
        dailyPlan.1.append(habit)
    }
    
    mutating func updateDailyPlanStatus(){
        let tdh = TimeDateHelper()
        //Move Completed Items to the appropriate place
        let completedTasks = dailyPlan.0.filter({$0.getCompleted()})
        if completedTasks.count != 0 {
            dailyPlan.0 = dailyPlan.0.filter({!$0.getCompleted()})
            completedPlanItems.0.append(contentsOf: completedTasks)
        }
        let completedHabits = dailyPlan.1.filter({tdh.calendar.isDateInToday($0.getLastCompletion())})
        if completedHabits.count != 0 {
            dailyPlan.1 = dailyPlan.1.filter({!tdh.calendar.isDateInToday($0.getLastCompletion())})
            completedPlanItems.1.append(contentsOf: completedHabits)
        }
        
        let uncompletedTasks = completedPlanItems.0.filter({!$0.getCompleted()})
        if uncompletedTasks.count != 0 {
            completedPlanItems.0 = completedPlanItems.0.filter({$0.getCompleted()})
            dailyPlan.0.append(contentsOf: uncompletedTasks)
        }
        let uncompletedHabits = completedPlanItems.1.filter({!tdh.calendar.isDateInToday($0.getLastCompletion())})
        if uncompletedHabits.count != 0 {
            completedPlanItems.1 = completedPlanItems.1.filter({tdh.calendar.isDateInToday($0.getLastCompletion())})
            dailyPlan.1.append(contentsOf: uncompletedHabits)
        }
        
        //Remove Duplicates
            // From Plan
        var plan = dailyPlan
        plan.0 = plan.0.sorted(by: {$0.getName() < $1.getName()})
        plan.1 = plan.1.sorted(by: {$0.getName() < $1.getName()})
        plan.0 = plan.0.filter { task in
            let idx = plan.0.firstIndex(where: {$0.getID() == task.getID()})!
            if idx < plan.0.count - 1{
                if plan.0[idx].getID() == plan.0[idx+1].getID(){
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        plan.1 = plan.1.filter { habit in
            let idx = plan.1.firstIndex(where: {$0.getID() == habit.getID()})!
            if idx < plan.1.count - 1{
                if plan.1[idx].getID() == plan.1[idx+1].getID(){
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
            // From Completed
        var complete = completedPlanItems
        complete.0 = complete.0.sorted(by: {$0.getName() < $1.getName()})
        complete.1 = complete.1.sorted(by: {$0.getName() < $1.getName()})
        complete.0 = complete.0.filter { task in
            let idx = complete.0.firstIndex(where: {$0.getID() == task.getID()})!
            if idx < complete.0.count - 1{
                if complete.0[idx].getID() == complete.0[idx+1].getID(){
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        complete.1 = complete.1.filter { habit in
            let idx = complete.1.firstIndex(where: {$0.getID() == habit.getID()})!
            if idx < complete.1.count - 1{
                if complete.1[idx].getID() == complete.1[idx+1].getID(){
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        
        dailyPlan = plan
        completedPlanItems = complete
    }
    
    mutating func togglePlanItemCompletion(_ task: TDLm.Task){
        if dailyPlan.0.contains(where: {$0.getID() == task.getID()}){
            dailyPlan.0[dailyPlan.0.firstIndex(where: {$0.getID() == task.getID()})!].toggleCompletion()
        } else if completedPlanItems.0.contains(where: {$0.getID() == task.getID()}){
            completedPlanItems.0[completedPlanItems.0.firstIndex(where: {$0.getID() == task.getID()})!].toggleCompletion()
        }
        updateDailyPlanStatus()
    }

    mutating func togglePlanItemCompletion(_ habit: HABm.Habit){
        if dailyPlan.1.contains(where: {$0.getID() == habit.getID()}){
            dailyPlan.1[dailyPlan.1.firstIndex(where: {$0.getID() == habit.getID()})!].complete()
        } else if completedPlanItems.1.contains(where: {$0.getID() == habit.getID()}){
            completedPlanItems.1[completedPlanItems.1.firstIndex(where: {$0.getID() == habit.getID()})!].undoComplete()
        }
        updateDailyPlanStatus()
    }
    
    mutating func planned(){
        completedPlanItems = ([], [])
    }
    
    //MARK: - Protocol Stubs
    enum CodingKeys: CodingKey {
        case apps, navBubbleAppShortcuts, dailyPlanTasks, dailyPlanHabits, completedPlanItemsTasks, completedPlanItemsHabits
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dailyPlanTasks: [TDLm.Task] = dailyPlan.0
        let dailyPlanHabits: [HABm.Habit] = dailyPlan.1
        let completedPlanTasks: [TDLm.Task] = completedPlanItems.0
        let completedPlanHabits: [HABm.Habit] = completedPlanItems.1
        let appArr: [Module] = apps
        let navApps: [Module] = navBubbleAppShortcuts
        try container.encode(dailyPlanTasks, forKey: .dailyPlanTasks)
        try container.encode(dailyPlanHabits, forKey: .dailyPlanHabits)
        try container.encode(completedPlanTasks, forKey: .completedPlanItemsTasks)
        try container.encode(completedPlanHabits, forKey: .completedPlanItemsHabits)
        try container.encode(appArr, forKey: .apps)
        try container.encode(navApps, forKey: .navBubbleAppShortcuts)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apps = try container.decode([Module].self, forKey: .apps)
        navBubbleAppShortcuts = try container.decode([Module].self, forKey: .navBubbleAppShortcuts)
        let dailyPlanTasks = try container.decode([TDLm.Task].self, forKey: .dailyPlanTasks)
        let dailyPlanHabits = try container.decode([HABm.Habit].self, forKey: .dailyPlanHabits)
        dailyPlan = (dailyPlanTasks, dailyPlanHabits)
        let completedPlanTasks = try container.decode([TDLm.Task].self, forKey: .completedPlanItemsTasks)
        let completedPlanHabits = try container.decode([HABm.Habit].self, forKey: .completedPlanItemsHabits)
        completedPlanItems = (completedPlanTasks, completedPlanHabits)
    }
    
    //MARK: - HomeModel.Module
    struct Module: Hashable, Codable{
        
        enum ModuleType: Codable{
            case TDL
            case CAL
            case HAB
            case RBX
            case FLC
        }
        
        private let name: String
        private let appImage: String
        private let appView: ModuleType
        
        init(name: String, appImage: String, view: ModuleType){
            self.name = name
            self.appImage = appImage
            self.appView = view
        }
        
        func getName() -> String{
            return name
        }
        
        func getAppImage() -> String{
            return appImage
        }
        
        func getView() -> AnyView{
            switch appView {
            case .TDL:
               return AnyView(TDLv())
            case .CAL:
                return AnyView(CALv())
            case .HAB:
                return AnyView(HABv())
            case .RBX:
                return AnyView(RBXv())
            case .FLC:
                return AnyView(FLCv())
            }
        }
        
        static func == (lhs: HomeModel.Module, rhs: HomeModel.Module) -> Bool {
            return (lhs.name == rhs.name) && (lhs.appImage == rhs.appImage) && (rhs.appView == lhs.appView)
        }
        
        func hash(into hasher: inout Hasher){
            hasher.combine(name)
            hasher.combine(appImage)
            hasher.combine(appView)
        }
        
        //Mark: - Persistence
        enum CodingKeys: CodingKey {
            case name, appImage, appView
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let nameStr: String = name
            let appImgStr: String = appImage
            try container.encode(nameStr, forKey: .name)
            try container.encode(appImgStr, forKey: .appImage)
            try container.encode(appView, forKey: .appView)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            appImage = try container.decode(String.self, forKey: .appImage)
            appView = try container.decode(ModuleType.self, forKey: .appView)
        }
    }
}

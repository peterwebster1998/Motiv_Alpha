//
//  CALvSpecialEvents.swift
//  Motiv
//
//  Created by Peter Webster on 6/5/23.
//

import SwiftUI

struct PlanTomorrowEventView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var calVM: CALvm
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @State var toDo: Bool = true
    
    var body: some View {
        ZStack{
            VStack(spacing: 0){
                TomorrowsScheduleViewPanel(geo: geo).frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.5)
                TaskAndHabitSelectionPanel(geo: geo, toDo: $toDo).frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.4)
            }
            if calVM.specialEvent{
                AddTaskOrHabitView(geo: geo, toDo: $toDo)
            }
        }.task{
            tdh.setDateInView(tdh.calendar.date(byAdding: .day, value: 1, to: Date())!)
        }
    }
}

struct TomorrowsScheduleViewPanel: View {
    @EnvironmentObject var calVM: CALvm
    let geo: GeometryProxy
    
    var body: some View{
        ScrollView{
            HStack(spacing: 0){
                timeBar
                GeometryReader{ localGeo in
                    ZStack{
                        BackgroundLines(geo: localGeo)
                        ScheduledEventsView(geo: localGeo)
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: geo.size.height * 1.5)
        }
    }
    
    var timeBar: some View{
        ZStack{
            VStack(spacing: 0){
                ForEach(hoursOfDay, id: \.self){ hour in
                    DayHourTile(geo: geo, hour: "\(hour):00")
                }
            }
            timeIndicatorView(geo: geo)
        }.frame(maxWidth: geo.size.width * 0.2, maxHeight: .infinity)
    }
}

struct BackgroundLines: View{
    let geo: GeometryProxy
    
    var body: some View{
        VStack(spacing: 0){
            ForEach(hoursOfDay, id: \.self){ hr in
                VStack(spacing: 0){
                    threeSideRect(width: 1, openEdge: .bottom).frame(maxWidth: .infinity, maxHeight: geo.size.height/96)
                    threeSideRect(width: 1, openEdge: .bottom).frame(maxWidth: .infinity, maxHeight: geo.size.height/96)
                    threeSideRect(width: 1, openEdge: .bottom).frame(maxWidth: .infinity, maxHeight: geo.size.height/96)
                    if hr != "23"{
                        threeSideRect(width: 1, openEdge: .bottom).frame(maxWidth: .infinity, maxHeight: geo.size.height/96)
                    } else {
                        Rectangle().stroke(.gray, lineWidth: 1).frame(maxWidth: .infinity, maxHeight: geo.size.height/96)
                    }
                }
            }
        }.foregroundColor(.gray).frame(maxHeight: .infinity)
    }
}

struct TaskAndHabitSelectionPanel: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var calVM: CALvm
    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var habVM: HABvm
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @Binding var toDo: Bool
    @State var tasks: [TDLm.Task] = []
    @State var habits: [HABm.Habit] = []

    var body: some View{
        ZStack{
            VStack{
                topBar
                tasksAndHabitsTile
            }
            addTaskOrHabitButton
        }.task{
            updateTasksAndHabits()
        }
    }
    
    var topBar: some View{
        HStack(spacing: 0){
            Text("To Dos").foregroundColor(toDo ? .black : .gray).onTapGesture {if !toDo{ toDo = true }}
            Text("|")
            Text("Habits").foregroundColor(toDo ? .gray : .black).onTapGesture {if toDo { toDo = false }}
            Spacer()
        }.font(.title)
    }
    
    @ViewBuilder
    var tasksAndHabitsTile: some View{
        RoundedRectangle(cornerRadius: 15).stroke(.gray, lineWidth: 1).foregroundColor(.clear).frame(maxWidth: geo.size.width * 0.925)
            .overlay(
                ScrollView{
                    if toDo{
                        ForEach(tasks, id: \.self){ item in
                            VStack{
                                HStack{
                                    Image(systemName: item.getCompleted() ? "checkmark.square" : "square")
                                    Text(item.getName())
                                }.font(.title2)
                                Divider()
                            }
                        }
                    } else {
                        ForEach(habits, id: \.self){ item in
                            VStack{
                                HStack{
                                    Image(systemName: "square")
                                    Text(item.getName())
                                }.font(.title2)
                                Divider()
                            }
                        }
                    }
                }.foregroundColor(.black)
            )
    }
    
    @ViewBuilder
    var addTaskOrHabitButton: some View {
        Capsule().stroke(.gray, lineWidth: 1.5).foregroundColor(.white)
            .frame(maxWidth: geo.size.width * 0.2, maxHeight: geo.size.height * 0.1)
            .position(x: geo.size.width/2, y: geo.size.height * 0.9)
            .overlay(
                Text("Add \(toDo ? "Task" : "Habit")").font(.title2).foregroundColor(.black)
            ).onTapGesture {
                calVM.specialEvent = true
            }
    }
    
    func updateTasksAndHabits() {
        tasks = homeVM.todaysToDos.0
        habits = homeVM.todaysToDos.1
        tasks.append(contentsOf: tdlVM.getTaskList(tdh.dateString(tdh.dateInView)))
        habits.append(contentsOf: habVM.getHabits().filter({$0.getRepetitionPeriod() == .Daily}))
        tasks = tasks.filter({$0.getCompleted()})
        habits = habits.filter({tdh.calendar.isDate(tdh.dateInView, inSameDayAs: $0.getLastCompletion())})
        tasks = tasks.sorted(by: {$0.getName() < $1.getName()})
        habits = habits.sorted(by: {$0.getName() < $1.getName()})
        tasks = tasks.filter { task in
            let idx = tasks.firstIndex(where: {$0 == task})!
            if idx < tasks.count - 1{
                if tasks[idx].getID() == tasks[idx+1].getID(){
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        habits = habits.filter { habit in
            let idx = habits.firstIndex(where: {$0 == habit})!
            if idx < habits.count - 1{
                if habits[idx].getID() == habits[idx+1].getID(){
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        homeVM.completedToDos = ([],[])
        homeVM.todaysToDos = (tasks, habits)
    }
}

struct AddTaskOrHabitView: View {
    private enum additionChoice{
            case New
            case Existing
        }
    
    
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var calVM: CALvm
    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var habVM: HABvm
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @Binding var toDo: Bool
    @State private var newOrExisting: additionChoice?
    
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.7).onTapGesture {
                calVM.specialEvent = false
            }
            interractionAreaSwitchView.scaleEffect(0.85).background(RoundedRectangle(cornerRadius: 15).frame(maxWidth: geo.size.width * 0.925, maxHeight: geo.size.height * 0.9).foregroundColor(.white))
        }.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea(edges: [.bottom])
    }
    
    @ViewBuilder
    var interractionAreaSwitchView: some View {
        if newOrExisting == nil {
            VStack{
                Button{
                    newOrExisting = .New
                    if toDo {
                        tdlVM.setViewContext("list")
                        tdlVM.createMode = true
                    } else {
                        habVM.setViewContext("new")
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.white).overlay(Text("Create New Task").foregroundColor(.black).padding())
                }.padding()
                Button{
                    newOrExisting = .Existing
                    if toDo {
                        tdlVM.setViewContext("lists")
                    } else {
                        habVM.setViewContext("all")
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.white).overlay(Text("Choose From Exisiting Task").foregroundColor(.black).padding())
                }.padding()
            }.font(.title2).frame(maxWidth: geo.size.width * 0.5, maxHeight: geo.size.height * 0.4)
        } else if newOrExisting == .New {
            CreateNewTaskOrHabitView(geo: geo, toDo: $toDo)
        } else {
            SelectExistingTaskOrHabitView(geo: geo, toDo: $toDo)
        }
    }
}
//To Do: Complete Implementation for adding existing or new tasks or habits to next days TODO list
struct CreateNewTaskOrHabitView: View{
    let geo: GeometryProxy
    @Binding var toDo: Bool
    
    var body: some View {
        Text("Stuff")
    }
}

struct SelectExistingTaskOrHabitView: View{
    let geo: GeometryProxy
    @Binding var toDo: Bool
    
    var body: some View {
        Text("Stuff")
    }
}

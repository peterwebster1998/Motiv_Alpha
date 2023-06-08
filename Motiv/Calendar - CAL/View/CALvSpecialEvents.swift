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
                Divider()
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
            ScrollViewReader{ calProx in
                Group{
                    GeometryReader{ localGeo in
                        DayTimeBar(geo: localGeo).position(x: geo.size.width * 0.1, y: geo.size.height * 1.25)
                        ZStack{
                            BackgroundLines(geo: localGeo)
                            ScheduledEventsView(geo: localGeo)
                        }.position(x: geo.size.width * 0.6, y: geo.size.height * 1.25)
                    }
                }.frame(maxWidth: .infinity, minHeight: geo.size.height * 2.5).padding(.top)
                    .onAppear{calProx.scrollTo("12", anchor: .center)}
            }
        }
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
            VStack{
                Spacer()
                addTaskOrHabitButton.padding()
            }
        }.task{
            updateTasksAndHabits()
        }.onChange(of: calVM.specialEvent){ val in
            if !val{
                updateTasksAndHabits()
                print("Tasks: \(tasks)")
                print("Habits: \(habits)")
            }
        }
    }
    
    var topBar: some View{
        HStack(spacing: 0){
            Text("To Dos").foregroundColor(toDo ? .black : .gray).onTapGesture {if !toDo{ toDo = true }}
            Text("|").padding(.horizontal)
            Text("Habits").foregroundColor(toDo ? .gray : .black).onTapGesture {if toDo { toDo = false }}
            Spacer()
        }.font(.title).padding([.top, .leading, .trailing])
    }
    
    @ViewBuilder
    var tasksAndHabitsTile: some View{
        RoundedRectangle(cornerRadius: 15).stroke(.gray, lineWidth: 1).foregroundColor(.clear).frame(maxWidth: geo.size.width * 0.925)
            .overlay(
                ScrollView{
                    if toDo{
                        VStack{
                            ForEach(tasks, id: \.self){ item in
                                HStack{
                                    Image(systemName: item.getCompleted() ? "checkmark.square" : "square").padding(.horizontal)
                                    Text(item.getName())
                                    Spacer()
                                }.font(.title2)
                                Divider()
                            }
                        }.padding(.vertical)
                    } else {
                        VStack{
                            ForEach(habits, id: \.self){ item in
                                HStack{
                                    Image(systemName: "square").padding(.horizontal)
                                    Text(item.getName())
                                    Spacer()
                                }.font(.title2)
                                Divider()
                            }
                        }.padding(.vertical)
                    }
                }.foregroundColor(.black)
            )
    }
    
    @ViewBuilder
    var addTaskOrHabitButton: some View {
        Capsule().stroke(.gray, lineWidth: 1.5).background(.white)
            .frame(maxWidth: geo.size.width * 0.3, maxHeight: geo.size.height * 0.0625)
            .overlay(
                Text("Add \(toDo ? "Task" : "Habit")").font(.title2).foregroundColor(.black)
            ).onTapGesture {
                calVM.specialEvent = true
            }
    }
    
    func updateTasksAndHabits() {
        var list = homeVM.todaysToDos
        //Get Existing List Items
        tasks = list.0
        habits = list.1
        //Add Tasks from day and daily habits to List
        list.0.append(contentsOf: tdlVM.getTaskList(tdh.dateString(tdh.dateInView)))
        list.1.append(contentsOf: habVM.getHabits().filter({$0.getRepetitionPeriod() == .Daily}))
        //Remove Completed Items
        list.0 = list.0.filter({!$0.getCompleted()})
        list.1 = list.1.filter({!tdh.calendar.isDate(tdh.dateInView, inSameDayAs: $0.getLastCompletion())})
        //Remove Duplicates
        list.0 = list.0.sorted(by: {$0.getName() < $1.getName()})
        list.1 = list.1.sorted(by: {$0.getName() < $1.getName()})
        list.0 = list.0.filter { task in
            let idx = list.0.firstIndex(where: {$0 == task})!
            if idx < list.0.count - 1{
                if list.0[idx].getID() == list.0[idx+1].getID(){
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        list.1 = list.1.filter { habit in
            let idx = list.1.firstIndex(where: {$0 == habit})!
            if idx < list.1.count - 1{
                if list.1[idx].getID() == list.1[idx+1].getID(){
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        print("Local Calculated List\nTasks: \(list.0)\nHabits: \(list.1)\n")
        (tasks, habits) = list
        //Update ViewModel
        homeVM.completedToDos = ([],[])
        homeVM.todaysToDos = list
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
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.white).overlay(Text("Create New \(toDo ? "Task" : "Habit")").foregroundColor(.black).padding())
                }.padding()
                Button{
                    newOrExisting = .Existing
                    if toDo {
                        tdlVM.setViewContext("lists")
                    } else {
                        habVM.setViewContext("all")
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.white).overlay(Text("Choose From Exisiting \(toDo ? "Task" : "Habit")").foregroundColor(.black).padding())
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
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var calVM: CALvm
    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var habVM: HABvm
    let geo: GeometryProxy
    @Binding var toDo: Bool
    
    var body: some View {
        if toDo {
            CreateForm(geo: geo, inPlan: true)
                .onChange(of: tdlVM.createMode){ val in
                    if !val {
                        tdlVM.setViewContext("lists")
                        calVM.specialEvent = false
                    }
                }
        } else {
            CreateHabitView(geo: geo)
                .onChange(of: habVM.selectedHabit){ val in
                    if val != nil {
                        habVM.setViewContext("all")
                        homeVM.todaysToDos.1.append(habVM.selectedHabit!)
                        habVM.selectedHabit = nil
                        calVM.specialEvent = false
                    }
                }
        }
    }
}

struct SelectExistingTaskOrHabitView: View{
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var calVM: CALvm
    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var habVM: HABvm
    let geo: GeometryProxy
    @Binding var toDo: Bool
    @State var selectionOverlayText: String = "Exit Selection"
    
    var body: some View {
        ZStack{
            if toDo {
                TDLv(inPlan: true)
            } else {
                HABv(inPlan: true)
            }
            selectionOverlay
        }
    }
    
    @ViewBuilder
    var selectionOverlay: some View {
        VStack{
            HStack{
                Spacer()
                Button{
                    if toDo {
                        switch tdlVM.viewContext{
                        case .Task:
                            homeVM.todaysToDos.0.append(tdlVM.selectedTask!)
                        case .List:
                            homeVM.todaysToDos.0.append(contentsOf: tdlVM.getTaskList(tdlVM.selectedList!))
                        default:
                            break
                        }
                        tdlVM.setViewContext("lists")
                        tdlVM.selectedList = nil
                        tdlVM.selectedTask = nil
                    } else {
                        switch habVM.viewContext {
                        case .One:
                            homeVM.todaysToDos.1.append(habVM.selectedHabit!)
                        case .Task:
                            homeVM.todaysToDos.0.append(habVM.selectedTask!)
                        default:
                            break
                        }
                        habVM.setViewContext("all")
                        habVM.selectedHabit = nil
                        habVM.selectedTask = nil
                    }
                    calVM.specialEvent = false

                } label: {
                    Rectangle().frame(maxWidth: UIScreen.main.bounds.width * 0.3, maxHeight: UIScreen.main.bounds.height * 0.085).foregroundColor(.white).overlay(
                        Text(selectionOverlayText).foregroundColor(.black)
                            .onChange(of: tdlVM.viewContext) { _ in
                                switch tdlVM.viewContext {
                                case .List:
                                    selectionOverlayText = "Add List to Plan"
                                case .Task:
                                    selectionOverlayText = "Add to Plan"
                                default:
                                    selectionOverlayText = "Exit Selection"
                                }
                            }
                            .onChange(of: habVM.viewContext) { _ in
                                switch habVM.viewContext {
                                case .One:
                                    selectionOverlayText = "Add to Plan"
                                case .Task:
                                    selectionOverlayText = "Add task to Plan"
                                default:
                                    selectionOverlayText = "Exit Selection"
                                }
                            }
                    )
                }
            }
            Spacer()
        }
    }
}


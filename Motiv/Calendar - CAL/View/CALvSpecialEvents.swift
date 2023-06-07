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
            addTaskOrHabitButton
        }.task{
            updateTasksAndHabits()
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
            .position(x: geo.size.width/2, y: geo.size.height * 0.95)
            .overlay(
                Text("Add \(toDo ? "Task" : "Habit")").font(.title2).foregroundColor(.black)
            ).onTapGesture {
                calVM.specialEvent = true
            }
    }
    
    func updateTasksAndHabits() {
        //Get Existing List Items
        tasks = homeVM.todaysToDos.0
        habits = homeVM.todaysToDos.1
        //Add Tasks from day and daily habits to List
        tasks.append(contentsOf: tdlVM.getTaskList(tdh.dateString(tdh.dateInView)))
        habits.append(contentsOf: habVM.getHabits().filter({$0.getRepetitionPeriod() == .Daily}))
        //Remove Completed Items
        tasks = tasks.filter({$0.getCompleted()})
        habits = habits.filter({tdh.calendar.isDate(tdh.dateInView, inSameDayAs: $0.getLastCompletion())})
        //Remove Duplicates
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
        //Update ViewModel
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
    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var habVM: HABvm
    let geo: GeometryProxy
    @Binding var toDo: Bool
    
    var body: some View {
        if toDo {
           
        } else {
            
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

   
//struct CreateNewTaskView: View {
//    @EnvironmentObject var viewModel: HABvm
//    @EnvironmentObject var TDLviewModel: TDLvm
//    let geo: GeometryProxy
//
//    var body: some View {
//        CreateForm(geo: geo, inHabit: true)
//            .onChange(of: TDLviewModel.createMode){ val in
//                if !val {
//                    TDLviewModel.setViewContext("lists")
//                    viewModel.addTask = false
//                }
//            }
//    }
//}

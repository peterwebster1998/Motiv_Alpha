//
//  HABvTaskInterraction.swift
//  Motiv
//
//  Created by Peter Webster on 5/12/23.
//

import SwiftUI


struct AddTaskToHabitView: View {
    
    private enum taskChoice{
        case New
        case Existing
    }
    
    @EnvironmentObject var viewModel: HABvm
    @EnvironmentObject var TDLviewModel: TDLvm
    let geo: GeometryProxy
    @State private var newOrExisting: taskChoice?
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.5).onTapGesture {
                viewModel.addTask = false
            }
            interractionAreaSwitchView.scaleEffect(0.85).background(RoundedRectangle(cornerRadius: 15).frame(maxWidth: geo.size.width * 0.9, maxHeight: geo.size.height * 0.95).foregroundColor(.white))
        }.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
    }
    
    @ViewBuilder
    var interractionAreaSwitchView: some View {
        if newOrExisting == nil {
            VStack{
                Button{
                    newOrExisting = .New
                    TDLviewModel.setViewContext("list")
                    TDLviewModel.createMode = true
                } label: {
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.white).overlay(Text("Create New Task").foregroundColor(.black).padding())
                }.padding()
                Button{
                    newOrExisting = .Existing
                    TDLviewModel.setViewContext("lists")
                } label: {
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.white).overlay(Text("Choose From Exisiting Task").foregroundColor(.black).padding())
                }.padding()
            }.font(.title2).frame(maxWidth: UIScreen.main.bounds.width * 0.5, maxHeight: UIScreen.main.bounds.height * 0.4)
        } else if newOrExisting == .New {
            CreateNewTaskView(geo: geo)
        } else {
            SelectExistingTaskView()
        }
    }
}

struct SelectExistingTaskView: View {
    @EnvironmentObject var viewModel: HABvm
    @EnvironmentObject var TDLviewModel: TDLvm
    @State var selectionOverlayText: String = "Exit Selection"
    
    var body: some View {
        ZStack{
            TDLv(inHabit: true)
            selectionOverlay
        }
    }
    
    @ViewBuilder
    var selectionOverlay: some View {
        VStack{
            HStack{
                Spacer()
                Button{
                    var updatedHabit = viewModel.selectedHabit!
                    switch TDLviewModel.viewContext {
                    case .List:
                        let tasks = TDLviewModel.getTaskList(TDLviewModel.selectedList!)
                        for i in tasks{
                            updatedHabit.addTask(i)
                        }
                        viewModel.updateHabit(updatedHabit)
                        viewModel.selectedHabit = updatedHabit
                        viewModel.addTask = false
                    case .Task:
                        updatedHabit.addTask(TDLviewModel.selectedTask!)
                        viewModel.updateHabit(updatedHabit)
                        viewModel.selectedHabit = updatedHabit
                        viewModel.addTask = false
                    default:
                        viewModel.addTask = false
                    }
                } label: {
                    Rectangle().frame(maxWidth: UIScreen.main.bounds.width * 0.3, maxHeight: UIScreen.main.bounds.height * 0.085).foregroundColor(.white).overlay(
                        Text(selectionOverlayText).foregroundColor(.black)
                            .onChange(of: TDLviewModel.viewContext) { _ in
                                switch TDLviewModel.viewContext {
                                case .List:
                                    selectionOverlayText = "Add List to Habit"
                                case .Task:
                                    selectionOverlayText = "Add to Habit"
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

struct CreateNewTaskView: View {
    @EnvironmentObject var viewModel: HABvm
    @EnvironmentObject var TDLviewModel: TDLvm
    let geo: GeometryProxy
    
    var body: some View {
        CreateForm(geo: geo, inHabit: true)
            .onChange(of: TDLviewModel.createMode){ val in
                if !val {
                    TDLviewModel.setViewContext("lists")
                    viewModel.addTask = false
                }
            }
    }
}

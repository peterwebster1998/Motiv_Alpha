//
//  CALvHabitInterration.swift
//  Motiv
//
//  Created by Peter Webster on 5/21/23.
//

import SwiftUI

struct PairWithHabitView: View {
    
    private enum habitChoice{
        case New
        case Existing
    }
    
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var habitVM : HABvm
    let geo: GeometryProxy
    @State private var newOrExisting: habitChoice?
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.5).onTapGesture {
                viewModel.pairWithHabit = false
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
                } label: {
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.white).overlay(Text("Create New Habit").foregroundColor(.black).padding())
                }.padding()
                Button{
                    newOrExisting = .Existing
                } label: {
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.white).overlay(Text("Choose From Exisiting Habit").foregroundColor(.black).padding())
                }.padding()
            }.font(.title2).frame(maxWidth: UIScreen.main.bounds.width * 0.5, maxHeight: UIScreen.main.bounds.height * 0.4)
        } else if newOrExisting == .New {
            CreateNewHabitView(geo: geo)
        } else {
            SelectExistingHabitView()
        }
    }
}

struct SelectExistingHabitView: View {
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var habitVM: HABvm
    @State var selectionOverlayText: String = "Exit Selection"
    
    var body: some View {
        ZStack{
            HABv()
            selectionOverlay
        }
    }
    
    @ViewBuilder
    var selectionOverlay: some View {
        VStack{
            HStack{
                Spacer()
                Button{
                    switch habitVM.viewContext {
                    case .One:
                        var habit = habitVM.selectedHabit!
                        var updatedSeries = viewModel.getEventSeries(viewModel.eventSelected!.getSeriesID()!)
                        habit.linkToEventSeries(updatedSeries.getID())
                        updatedSeries.setHabit(habit)
                        viewModel.updateEventSeries(updatedSeries)
                        viewModel.pairWithHabit = false
                        habitVM.updateHabit(habit)
                        habitVM.setViewContext("all")
                        habitVM.selectedHabit = nil
                    default:
                        viewModel.pairWithHabit = false
                    }
                } label: {
                    Rectangle().frame(maxWidth: UIScreen.main.bounds.width * 0.3, maxHeight: UIScreen.main.bounds.height * 0.1).foregroundColor(.white).overlay(
                        Text(selectionOverlayText).foregroundColor(.black)
                            .onChange(of: habitVM.viewContext) { _ in
                                switch habitVM.viewContext {
                                case .One:
                                    selectionOverlayText = "Select Habit"
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

struct CreateNewHabitView: View {
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var habitVM: HABvm
    let geo: GeometryProxy
    
    var body: some View {
        CreateHabitView(geo: geo)
            .onChange(of: habitVM.selectedHabit){val in
                if val != nil {
                    var habit = habitVM.selectedHabit!
                    var updatedSeries = viewModel.getEventSeries(viewModel.eventSelected!.getSeriesID()!)
                    habit.linkToEventSeries(updatedSeries.getID())
                    updatedSeries.setHabit(habit)
                    viewModel.updateEventSeries(updatedSeries)
                    viewModel.pairWithHabit = false
                    habitVM.selectedHabit!.linkToEventSeries(updatedSeries.getID())
                    habitVM.setViewContext("all")
                    habitVM.selectedHabit = nil
                }
            }
    }
}

/*
  CALv.swift
  Motiv

  Created by Peter Webster on 4/25/23.

 //
 //  CALv.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 10/19/22.
 //
*/

import SwiftUI

struct CALv: View {
    
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    
    var body: some View {
        GeometryReader{ geo in
            ZStack{
                VStack(spacing: 0){
                    CALBanner(currentDate: timeDateHelper.dateInView)
                    Divider()
                    switch viewModel.viewType {
                    case .Month:
                        MonthView()
                    case .Week:
                        WeekView(geo: geo)
                    case .Day:
                        DayView(geo: geo)
                    case .Event:
                        EventView(geo: geo)
                    case .Edit:
                        EditEventView(geo: geo)
                    }
                }
                if viewModel.pairWithHabit {
                    PairWithHabitView(geo: geo)
                }
                if viewModel.createTask {
                    AddTaskFormView(geo: geo)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).onAppear {
                timeDateHelper.today()
            }
            .sheet(isPresented: $viewModel.eventConflict){
                ConflictView()
            }
        }
    }
}

struct CALBanner: View {
    
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var habitVM: HABvm
    @State var currentDate: Date
    @State private var pickerDate: Date = Date()
    //    @State private var showPicker: Bool = false
    
    var body: some View {
        VStack{
            ZStack{
                HStack{
                    switch viewModel.viewType{
                    case .Day:
                        Text(timeDateHelper.dateString(currentDate)).padding().font(.largeTitle).frame(maxWidth: .infinity).overlay(
                            DatePicker("Date", selection: $pickerDate, displayedComponents: [.date])
                                .labelsHidden()
                                .opacity(0.02)
                        )
                    case .Event:
                        Text(viewModel.eventSelected!.getName()).font(.largeTitle).frame(maxWidth: UIScreen.main.bounds.width * 0.75).multilineTextAlignment(.center)
                    case .Edit:
                        Text(viewModel.eventSelected!.getName()).font(.largeTitle).frame(maxWidth: UIScreen.main.bounds.width * 0.75).multilineTextAlignment(.center)
                    default:
                        Text(timeDateHelper.monthYearStr(currentDate)).padding().font(.largeTitle).frame(maxWidth: .infinity).overlay(
                            DatePicker("Date", selection: $pickerDate, displayedComponents: [.date])
                                .labelsHidden()
                                .opacity(0.02)
                        )
                    }
                }
                switch viewModel.viewType{
                case .Event:
                    HStack{
                        Button {
                            viewModel.setViewContext(viewModel.lastContext!)
                            viewModel.eventSelected = nil
                            viewModel.lastContext = nil
                        } label: {
                            Image(systemName: "chevron.left").foregroundColor(Color.black).font(.title)
                        }.padding()
                        Spacer()
                        Menu {
                            eventDropDownMenu
                        } label: {
                            Image(systemName: "slider.horizontal.3").foregroundColor(Color.black).font(.title)
                        }.padding()
                    }
                    
                case .Edit:
                    HStack{
                        Button {
                            viewModel.setViewContext("e")
                        } label: {
                            Image(systemName: "chevron.left").foregroundColor(Color.black).font(.title)
                        }.padding()
                        Spacer()
                        
                    }
                default:
                    HStack{
                        Button{
                            homeVM.currentActiveModule = nil
                        } label:{
                            Image(systemName: "house").font(.title)
                        }
                        .padding()
                        Spacer()
                        Menu {
                            timeframeContextDropdownMenu
                        } label: {
                            Image(systemName: "calendar").font(.title)
                        }
                        .padding()
                    }
                }
            }
            switch viewModel.viewType{
            case .Month:
                weekdayLabels
            case .Event:
                EmptyView()
            default:
                timeOfDayScale
            }
        }
        .foregroundColor(Color.black)
        .onChange(of: timeDateHelper.dateInView){ value in
            currentDate = value
        }
        .onChange(of: pickerDate){ value in
            //            showPicker.toggle()
            timeDateHelper.setDateInView(value)
            timeDateHelper.isRefresh = true
        }
        .onAppear {
            pickerDate = timeDateHelper.dateInView
        }
    }
    
    @ViewBuilder
    var timeframeContextDropdownMenu: some View{
        //Today
        Button{
            timeDateHelper.today()
        } label:{
            Text("Today").bold()
        }
        //Month
        Button{
            viewModel.setViewContext("m")
            timeDateHelper.isRefresh = true
        }label: {
            Text("Month")
        }
        //Week
        Button{
            viewModel.setViewContext("w")
        }label: {
            Text("Week")
        }
        //Day
        Button{
            viewModel.setViewContext("d")
        }label: {
            Text("Day")
        }
        //Conflicts
        if viewModel.getConflicts().count != 0 {
            Button{
                viewModel.eventConflict = true
            } label: {
                Text("Conflicts")
            }
        }
    }
    
    @ViewBuilder
    var eventDropDownMenu: some View {
        // Delete item
        Button {
            viewModel.deleteMode = true
        } label: {
            Text("Delete")
            Spacer()
            Image(systemName: "trash")
        }
        // Edit item
        Button {
            viewModel.setViewContext("edit")
            viewModel.deleteMode = false
        } label: {
            Text("Edit")
            Spacer()
            Image(systemName: "pencil")
        }
        // Edit Event Series
        if viewModel.eventSelected!.getSeriesID() != nil{
            Button {
                viewModel.setViewContext("edit")
                viewModel.editSeries = true
                viewModel.deleteMode = false
            } label: {
                Text("Edit Series")
                Spacer()
                Image(systemName: "pencil")
            }
            
            if viewModel.getEventSeries(viewModel.eventSelected!.getSeriesID()!).getHabit() == nil {
                Button {
                    viewModel.pairWithHabit = true
                } label: {
                    Text("Pair With Habit")
                    Spacer()
                    Image(systemName: "link")
                }
            } else {
                Button {
                    homeVM.currentActiveModule = homeVM.getApps().first(where: {$0.getName() == "Habits"})
                    habitVM.selectedHabit = viewModel.getEventSeries(viewModel.eventSelected!.getSeriesID()!).getHabit()!
                    habitVM.setViewContext("one")
                    viewModel.setViewContext("m")
                    viewModel.eventSelected = nil
                } label: {
                    Text("Go To Habit")
                    Spacer()
                    Image(systemName: "person.fill.checkmark")
                }
            }
        }
    }
    
    @ViewBuilder
    var weekdayLabels: some View{
        HStack{
            Text("Sun").weekdayLabel()
            Text("Mon").weekdayLabel()
            Text("Tue").weekdayLabel()
            Text("Wed").weekdayLabel()
            Text("Thu").weekdayLabel()
            Text("Fri").weekdayLabel()
            Text("Sat").weekdayLabel()
        }
    }
    
    @ViewBuilder
    var timeOfDayScale: some View{
        HStack{
            EmptyView() //Add time of day scale
        }
    }
}

extension Text {
    func weekdayLabel() -> some View{
        self.font(.subheadline).frame(maxWidth: .infinity, alignment: .center)
    }
}

struct CALv_Previews: PreviewProvider {
    static var previews: some View {
        CALv()
    }
}


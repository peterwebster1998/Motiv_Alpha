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
        VStack(spacing: 0){
            CALBanner(currentDate: timeDateHelper.dateInView)
            Divider()
            switch viewModel.viewType {
            case .Month:
                MonthView()
                //                let _ = print("MONTH VIEW - [\(timeDateHelper.dateString(timeDateHelper.temporalHorizons[0])) - \(timeDateHelper.dateString(timeDateHelper.temporalHorizons[1]))]")
            case .Week:
                WeekView()
                //                let _ = print("WEEK VIEW")
            case .Day:
                DayView()
                //                let _ = print("DAY VIEW")
            }
        }.onAppear {
            timeDateHelper.today()
        }
        .sheet(isPresented: $viewModel.eventConflict){
            ConflictView()
        }
        /*
         Month View:
         - Scroll vertically continuously between months
         - Show each day, when tapped switch to Day View context
         Week View
         - Scroll horizontally to view all 7 days together vertically stacked
         - Set Origin to current time of day? Maybe
         Day View
         - Scroll vertically to view all events for that day, including scheduled sleep hours
         - Default Origin should also be current time
         - Based on model, events should be shown for the 1.5 hrs previous to current time and 3.5 hrs afterwards for a 5 hr window
         */
    }
}

struct CALBanner: View {
    
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var homeVM: HomeViewModel
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
                    default:
                        Text(timeDateHelper.monthYearStr(currentDate)).padding().font(.largeTitle).frame(maxWidth: .infinity).overlay(
                            DatePicker("Date", selection: $pickerDate, displayedComponents: [.date])
                                .labelsHidden()
                                .opacity(0.02)
                        )
                    }
                }
                HStack{
                    Button{
                        homeVM.currentActiveModule = nil
                    } label:{
                        Image(systemName: "house")
                    }
                    .padding()
                    Spacer()
                    Menu {
                        timeframeContextDropdownMenu
                    } label: {
                        Image(systemName: "calendar").padding().imageScale(.large)
                    }
                }
            }
            switch viewModel.viewType{
            case .Month:
                weekdayLabels
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


/*
  CALvMonth.swift
  Motiv

  Created by Peter Webster on 4/25/23.

 //
 //  CALvMonth.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 10/26/22.
 //
*/

import SwiftUI

struct MonthView: View {
    
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    
//    init(){
//        print("Init MonthView")
//    }
    
    var body: some View {
        ScrollView{
            ScrollViewReader{ proxy in
                ForEach(timeDateHelper.temporalRange, id: \.self){ month in
                    VStack{
                        monthLabel(month: month[0])
                        monthGrid(month: month)
                    }
                    
                }.onChange(of: timeDateHelper.scrollToToday) { value in
                    if !value { return }
                    let month = timeDateHelper.getFirstOfMonth(timeDateHelper.dateInView)
                    proxy.scrollTo(month, anchor: .top)
                    timeDateHelper.scrollToToday = false
                    timeDateHelper.isRefresh = false
                    viewModel.startUp = false
                }
                .onChange(of: timeDateHelper.isRefresh){value in
                    if !value { return }
                    let month = timeDateHelper.getFirstOfMonth(timeDateHelper.dateInView)
                    proxy.scrollTo(month, anchor: .top)
                    timeDateHelper.isRefresh = false
                    print("Refreshing, scrolling to: \(month)")
                    timeDateHelper.refreshed = true
                }
                .onAppear {
                    let month = timeDateHelper.getFirstOfMonth(timeDateHelper.dateInView)
                    proxy.scrollTo(month, anchor: .top)
                    viewModel.contextSwitch = false
                    print("onAppear scrolling to date: \(month)")
                }
            }
            
        }
        .onAppear {
            timeDateHelper.isRefresh = false
        }
        .onDisappear{
            viewModel.contextSwitch = true
        }
    }
}

struct cell: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    let dayInMonth: Date
    
    var body: some View {
        let isToday = timeDateHelper.dateString(Date()) == timeDateHelper.dateString(dayInMonth) ? true : false
        
        if isToday {
            ZStack{
                Capsule(style: .continuous)
                    .strokeBorder(Color.gray)
                    .background(Capsule(style: .continuous).foregroundColor(Color.gray))
                    .aspectRatio(0.618, contentMode: .fill)
                Text(timeDateHelper.dayNoString(dayInMonth))
                    .bold()
                    .foregroundColor(Color.white)
            }
        } else {
            ZStack {
                Capsule(style: .continuous)
                    .strokeBorder(Color.gray)
                    .aspectRatio(0.618, contentMode: .fill)
                Text(timeDateHelper.dayNoString(dayInMonth))
            }
        }
    }
}

struct emptyCell: View {
    var body: some View {
        Capsule(style: .continuous)
            .stroke(Color.gray)
            .aspectRatio(0.618, contentMode: .fill)
            .opacity(0.33)
    }
}

struct monthGrid: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let month: [Date]
    
    let dayColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(month: [Date]){
        self.month = month
    }
    
    var body: some View {
        LazyVGrid(columns: dayColumns, spacing: 20){
            //align first day with appropriate doy of week label
            switch timeDateHelper.weekdayFromDate(month[0]){
            case "Mon":
                emptyCell()
            case "Tue":
                emptyCell()
                emptyCell()
            case "Wed":
                emptyCell()
                emptyCell()
                emptyCell()
            case "Thu":
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
            case "Fri":
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
            case "Sat":
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
            default:
                EmptyView()
            }
            
            //create cells for all days within month
            ForEach(month, id: \.self){ day in
                cell(dayInMonth: day)
                    .onTapGesture {
                        timeDateHelper.setDateInView(day)
                        viewModel.setViewContext("d")
                    }
            }
            
            //fill out the rest of the row with empty cells
            switch timeDateHelper.weekdayFromDate(month.last!){
            case "Fri":
                emptyCell()
            case "Thu":
                emptyCell()
                emptyCell()
            case "Wed":
                emptyCell()
                emptyCell()
                emptyCell()
            case "Tue":
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
            case "Mon":
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
            case "Sun":
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
                emptyCell()
            default:
                EmptyView()
            }
        }
    }
}

struct monthLabel: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let month: Date
    
    var body: some View {
        Text(timeDateHelper.monthStrFromDate(month))
            .font(.title)
            .multilineTextAlignment(.leading)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { geo in
                    Rectangle()
                        .opacity(0)
                        .preference(key: MonthLabelYOffsetPreferenceKey.self, value: {
                            let value = geo.frame(in: .global).maxY
                            if value < 0.5 * UIScreen.main.bounds.size.height && value > 0 {
//                                        if timeDateHelper.isRefresh && !viewModel.startUp{
//                                            let _ = print("break - refresh: \(month)")
//                                        }
                                return true
                            } else {
                                return false
                            }
                        }())
                })
            .onPreferenceChange(MonthLabelYOffsetPreferenceKey.self) { value in
//                if value {
//                    print("break")
//                }
                if value && !timeDateHelper.isRefresh && !viewModel.contextSwitch{
                    timeDateHelper.setDateInView(month)
                }
            }
    }
}

struct MonthLabelYOffsetPreferenceKey: PreferenceKey {
    typealias Value = Bool
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct CALvMonth_Previews: PreviewProvider {
    static var previews: some View {
        MonthView()
    }
}

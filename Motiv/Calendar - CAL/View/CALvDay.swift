/*
  CALvDay.swift
  Motiv

  Created by Peter Webster on 4/25/23.


 //
 //  CALvDay.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 10/26/22.
 //
*/

import SwiftUI

struct DayView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy

    var body: some View {
        ZStack{
            ScrollViewReader{ proxy in
                ScrollView{
                    TimeOfDayView()
                        .gesture(swipeToChangeDay)
                }.onAppear{
                    let hour = hourToScrollTo()
                    proxy.scrollTo(hour, anchor: .top)
                }.onChange(of: timeDateHelper.scrollToToday){ _ in
                    let hour = hourToScrollTo()
                    proxy.scrollTo(hour, anchor: .top)
                }
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    AddEventButton()
                        .padding()
                        .foregroundColor(Color.gray)
                }
            }
        }.sheet(isPresented: $viewModel.createEvent){
            CreateEventView(geo: geo)
        }
    }
    
    var swipeToChangeDay: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                let dayBefore = timeDateHelper.calendar.date(byAdding: .day, value: -1, to: timeDateHelper.dateInView)!
                let dayAfter = timeDateHelper.calendar.date(byAdding: .day, value: 1, to: timeDateHelper.dateInView)!
                if abs(horizontal) > abs(vertical) {
                    if horizontal > 0 {
                        timeDateHelper.setDateInView(dayBefore)
                    } else {
                        timeDateHelper.setDateInView(dayAfter)
                    }
                }
            }
    }
    
    func hourToScrollTo() -> String {
        let isToday = (timeDateHelper.dateString(Date()) == timeDateHelper.dateString(timeDateHelper.dateInView))
        var hour = ""
        if !isToday { hour = "08:00" }
        else {
            let time = timeDateHelper.getTimeOfDayHrsMins(Date())
            let hrSeg = time.split(separator: ":")[0]
            var hr = Int(hrSeg)!
            hr = (hr == 12) ? 0: hr
            hr = (timeDateHelper.getAMPM(Date()) == "PM") ? hr+12 : hr
            hr = (hr > 19) ? 19 : hr
            hour = ((String(hr).count == 1) ? "0"+String(hr): String(hr)) + ":00"
        }
        return hour
    }
}

struct AddEventButton: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let buttonSize: CGFloat = 75
    
    var body: some View {
        Button {
            print("Add Event!!")
            viewModel.createEvent = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: buttonSize))
                .background(
                    Circle()
                        .frame(width: buttonSize, height: buttonSize, alignment: .center)
                        .foregroundColor(Color.white)
                )
        }
    }
}


struct TimeOfDayView: View {
    
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    
    private let hoursInDay: [String] = ["00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"]
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0){
                ZStack{
                    VStack(spacing: 0){
                        ForEach(hoursInDay, id: \.self){ hour in
                            DayHourTile(geo: geo, hour: hour)
                                .id(hour)
                        }
                    }
                    timeIndicatorView(geo: geo)
                }.frame(maxWidth: geo.size.width * 0.2, maxHeight: .infinity)
                
                ZStack{
                    VStack(spacing: 0){
                        ForEach(hoursInDay, id: \.self){hr in
                            VStack(spacing:0){
                                threeSideRect(width: 1, openEdge: .bottom)
                                if hr != "23:00"{
                                    threeSideRect(width: 1, openEdge: .bottom)
                                } else {
                                    Rectangle().strokeBorder(style: StrokeStyle(lineWidth: 1))
                                }
                            }.foregroundColor(Color.gray).frame(maxHeight: .infinity)
                        }
                    }
                    ScheduledEventsView(geo: geo)
                }.frame(maxWidth: geo.size.width * 0.80, maxHeight: .infinity)
            }
        }.frame(width: UIScreen.main.bounds.width , height: UIScreen.main.bounds.height * 0.9 * 4)
    }
}

struct DayHourTile: View {
    let geo: GeometryProxy
    let hour: String
    @State var y: CGFloat = 0
    
    var body: some View {
        ZStack{
            Text(hour).padding(.vertical).position(x: geo.size.width * 0.075, y: geo.size.height / (24 * 16))
            DayHourScaleLines().foregroundColor(.gray)
        }.frame(maxWidth: geo.size.width * 0.2, maxHeight: geo.size.height / 24)
    }
}

struct DayHourScaleLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.7, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.7, y: rect.maxY * 0.01))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY * 0.01))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY * 0.24))
        path.addLine(to: CGPoint(x: rect.maxX * 0.9, y: rect.maxY * 0.24))
        path.addLine(to: CGPoint(x: rect.maxX * 0.9, y: rect.maxY * 0.26))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY * 0.26))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY * 0.49))
        path.addLine(to: CGPoint(x: rect.maxX * 0.8, y: rect.maxY * 0.49))
        path.addLine(to: CGPoint(x: rect.maxX * 0.8, y: rect.maxY * 0.51))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY * 0.51))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY * 0.74))
        path.addLine(to: CGPoint(x: rect.maxX * 0.9, y: rect.maxY * 0.74))
        path.addLine(to: CGPoint(x: rect.maxX * 0.9, y: rect.maxY * 0.76))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY * 0.76))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY * 0.99))
        path.addLine(to: CGPoint(x: rect.maxX * 0.7, y: rect.maxY * 0.99))
        path.addLine(to: CGPoint(x: rect.maxX * 0.7, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        return path
    }
}

struct threeSideRect: Shape {
    var width: CGFloat
    var openEdge: Edge
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch openEdge {
        case .top:
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))//leading
            path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))//bottom
            path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))//trailing
        case .leading:
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))//top
            path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))//bottom
            path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))//trailing
        case .bottom:
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))//leading
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))//top
            path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))//trailing
        case .trailing:
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))//leading
            path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))//bottom
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))//top
        }
        return path
    }
}

struct timeIndicatorArrow: Shape {
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: 0.8*rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0.8*rect.maxX, y: rect.midY * 1.02))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY * 1.02))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY * 0.98))
        path.addLine(to: CGPoint(x: 0.8*rect.maxX, y: rect.midY * 0.98))
        path.addLine(to: CGPoint(x: 0.8*rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        
        return path
    }
}

struct timeIndicatorView: View {
    
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    let geo: GeometryProxy
    @State private var y : CGFloat = 0
    
    var body: some View {
        timeIndicatorArrow().frame(maxWidth: .infinity, maxHeight: 10).position(x: geo.size.width * 0.1, y: y)
            .opacity((timeDateHelper.dateString(Date()) == timeDateHelper.dateString(timeDateHelper.dateInView)) ? 100 : 0)
            .onAppear{
                let height = geo.size.height
                let minuteHeight = height / (24 * 60)
                let time = timeDateHelper.getTimeOfDayHrsMins(Date()).split(separator: ":")
                var hr = Int(time[0])!
                hr = (hr == 12) ? 0: hr
                hr = (timeDateHelper.getAMPM(Date()) == "PM") ? hr+12 : hr
                let min = Int(time[1])!
                y = CGFloat((hr *  60) + min) * minuteHeight
                print("Time indicator Y: \(y)")
                print("Height: \(height), Time: \(time), Hr: \(hr), Min: \(min)")
            }
    }
}

struct ScheduledEventsView: View {
    
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    
    var body: some View {
        ForEach(viewModel.getDaysEvents(timeDateHelper.dateString(timeDateHelper.dateInView)), id: \.self){ event in
            let data = calculateYandDuration(event: event, day: timeDateHelper.dateInView)
            EventTileDayView(geo: geo, event: event, height: data[1], y: data[0])
        }
    }
    
    func calculateYandDuration(event: CALm.Event, day: Date) -> [CGFloat]{
        let overNighter = event.getOverNighter()
        let hourHeight = geo.size.height / 24
        let startTime = timeDateHelper.getTimeOfDayHrsMins(event.getStartTime()).split(separator: ":")
        let hr = pmHourAdjustment(event: event, hour: CGFloat(Int(startTime[0])!))
        let min = CGFloat(Int(startTime[1])!)/60
        var y = (hr+min) * hourHeight
        var duration: CGFloat
        if !overNighter {
            duration = (CGFloat(event.getDuration())/60) * hourHeight
        } else {
            duration = (24-(hr+(min))) * hourHeight
        }
        if !timeDateHelper.calendar.isDate(day, inSameDayAs: event.getStartTime()){
            let yesterdaysDuration = 24-(hr+min)
            duration = ((CGFloat(event.getDuration())/60)-yesterdaysDuration) * hourHeight
            y = 0
        }
        
        return [y, duration]
    }
    
    func pmHourAdjustment(event: CALm.Event, hour: CGFloat) -> CGFloat {
        var hr = hour
        hr = (hr == 12) ? 0: hr
        hr = (timeDateHelper.getAMPM(event.getStartTime()) == "PM") ? hr+12 : hr
        return hr
    }
}

struct EventTileDayView: View {
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var homeVM: HomeViewModel
    let geo: GeometryProxy
    let event: CALm.Event
    let height: CGFloat
    let y: CGFloat
    
    var body: some View {
        EventTile()
            .frame(width: geo.size.width * 0.8, height: height)
            .overlay (
                Text(event.getName()).foregroundColor(Color.black)
            )
            .foregroundColor(Color.green)
            .position(x: geo.size.width * 0.4, y: y + (height / 2))
            .onTapGesture {
                viewModel.eventSelected = event
                viewModel.setViewContext("e")
                if homeVM.currentActiveModule == nil{
                    homeVM.currentActiveModule = homeVM.getApps().first(where: {$0.getName() == "Calendar"})
                    viewModel.lastContext = "home"
                } else {
                    viewModel.lastContext = "d"
                }
            }
    }
}

struct EventTile: View {
    
    var body: some View {
        GeometryReader{ geo in
            RoundedRectangle(cornerRadius: 10)
                .colorMultiply(Color(red: 0.75, green: 0.75, blue: 0.75))
                .frame(width: geo.size.width - (geo.size.height * 0.025), height: geo.size.height * 0.975)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .overlay(
                RoundedRectangle(cornerRadius: 10).padding(5)
            )
        }
    }
}



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
    
    var body: some View {
        ZStack{
            ScrollViewReader{ proxy in
                ScrollView{
                    TimeOfDayView()
                        .gesture(
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
                        )
                }.onAppear{
                    let today = Date()
                    let isToday = (timeDateHelper.dateString(today) == timeDateHelper.dateString(timeDateHelper.dateInView))
                    let time = timeDateHelper.getTimeOfDayHrsMins(today)
                    let hrSeg = time.split(separator: ":")[0]
                    var hr = Int(hrSeg)!
                    hr = (timeDateHelper.getAMPM(today) == "PM") ?  hr+9 : hr-3
                    var hour = ((String(hr).count == 1) ? "0"+String(hr): String(hr)) + ":00"
                    if !isToday { hour = "06:00" }
                    proxy.scrollTo(String(hour))
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
            CreateEventView()
        }
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
        HStack(spacing: 0){
            VStack{
                ForEach(hoursInDay, id: \.self){ hour in
                    Text(hour).padding().id(hour)
                }
            }.overlay (
                GeometryReader { geo in
                    timeIndicatorView(geo: geo)
                }
            )
            
            VStack(spacing:0){
                ForEach(hoursInDay, id: \.self){hr in
                    VStack(spacing:0){
                        threeSideRect(width: 1, openEdge: .bottom)
                        if hr != "23:00"{
                            threeSideRect(width: 1, openEdge: .bottom)
                        } else {
                            Rectangle().strokeBorder(style: StrokeStyle(lineWidth: 1))
                        }
                    }.foregroundColor(Color.gray)
                }
            }.overlay(
                GeometryReader { geo in
                    ScheduledEventsView(geo: geo)
                }
            )
        }
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
        timeIndicatorArrow().frame(maxWidth: .infinity, maxHeight: 10).position(x: geo.frame(in: .local).midX, y: y)
            .opacity((timeDateHelper.dateString(Date()) == timeDateHelper.dateString(timeDateHelper.dateInView)) ? 100 : 0)
            .onAppear{
                let height = geo.frame(in: .local).maxY
                let minuteHeight = height / (24 * 60)
                let time = timeDateHelper.getTimeOfDayHrsMins(Date()).split(separator: ":")
                var hr = Int(time[0])!
                hr = (timeDateHelper.getAMPM(Date()) == "AM") ? hr : hr + 12
                let min = Int(time[1])!
                y = CGFloat((hr *  60) + min) * minuteHeight
            }
    }
}

struct ScheduledEventsView: View {
    
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    @State private var eventSelected : CALm.Event?
    
    var body: some View {
        ForEach(viewModel.getDaysEvents(timeDateHelper.dateString(timeDateHelper.dateInView)), id: \.self){ event in
            let data = calculateYandDuration(event: event, day: timeDateHelper.dateInView)
            EventTileDayView(geo: geo, event: event, eventSelected: $eventSelected, height: data[1], y: data[0])
        }.sheet(item: $eventSelected) { event in
            eventInterractionSheet(eventBinding: $eventSelected)
        }
    }
    
    func calculateYandDuration(event: CALm.Event, day: Date) -> [CGFloat]{
        let overNighter = event.getOverNighter()
        let hourHeight = geo.size.height/24
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
        if (hr == 12){hr = 0}
        if (timeDateHelper.getAMPM(event.getStartTime()) == "PM"){hr += 12}
        return hr
    }
}

struct EventTileDayView: View {
    let geo: GeometryProxy
    let event: CALm.Event
    @Binding var eventSelected: CALm.Event?
    let height: CGFloat
    let y: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .frame(width: geo.frame(in: .local).maxX, height: height)
            .border(.black, width: 0.75)
            .overlay (
                Text(event.getName()).foregroundColor(Color.black)
            )
            .foregroundColor(Color.blue)
            .position(x: geo.frame(in: .local).midX, y: y + (height / 2))
            .onTapGesture {
                eventSelected = event
            }
    }
}

struct CALvDay_Previews: PreviewProvider {
    static var previews: some View {
        DayView()
    }
}

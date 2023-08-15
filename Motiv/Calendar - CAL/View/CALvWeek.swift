/*
  CALvWeek.swift
  Motiv

  Created by Peter Webster on 4/25/23.

 //
 //  CALvWeek.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 10/26/22.
 //
*/

import SwiftUI

//Local constants
internal let hoursPerScreenWidth: CGFloat = 5
internal let timeBarHeightProportion: CGFloat = 0.05
internal let scheduleViewHeightProportion: CGFloat = 1 - timeBarHeightProportion
internal let dayHeightProportion: CGFloat = scheduleViewHeightProportion / 7
internal let dateBarWidthProportion: CGFloat = 0.15

struct WeekView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    @State var datesInView: [Date] = []
    
    var body: some View {
        GeometryReader{ geo in
            ZStack{
                ScrollView(.horizontal){
                    ScrollViewReader{ scrollProxy in
                        SevenDayScheduleView(geo: geo, scrollProxy: scrollProxy, datesInView: $datesInView)
                    }
                }
                DateBar(geo: geo, datesInView: $datesInView)
                
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        AddEventButton()
                            .padding()
                            .foregroundColor(Color.gray)
                    }
                }
            }
        }.frame(maxWidth: .infinity)
            .onAppear{
                datesInView.append(timeDateHelper.dateInView)
                for num in 1...6{
                    datesInView.append(timeDateHelper.calendar.date(byAdding: .day, value: num, to: timeDateHelper.dateInView)!)
                }
                if datesInView.contains(where: {timeDateHelper.calendar.isDateInToday($0)}){
                    datesInView = []
                    timeDateHelper.today()
                    datesInView.append(timeDateHelper.dateInView)
                    for num in 1...6{
                        datesInView.append(timeDateHelper.calendar.date(byAdding: .day, value: num, to: timeDateHelper.dateInView)!)
                    }
                }
            }.onChange(of: timeDateHelper.dateInView){day in
                datesInView = [day]
                for num in 1...6 {
                    datesInView.append(timeDateHelper.calendar.date(byAdding: .day, value: num, to: timeDateHelper.dateInView)!)
                }
            }.sheet(isPresented: $viewModel.createEvent){
                CreateEventView(geo: geo)
            }
    }
}

struct DateBar: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    @Binding var datesInView: [Date]
    @GestureState var dragGestureState: CGSize = .zero
    @State var dragOffsetY: CGFloat = .zero
    
    var body: some View{
        HStack(spacing: 0){
            VStack(spacing: 0){
                ForEach(datesInView, id: \.self){ date in
                    let dateStrComponents: [Substring] = timeDateHelper.dateString(date).split(separator: " ")
                    let dayNameStr: String = timeDateHelper.weekdayFromDate(date)
                    let dateStr: String = dayNameStr + "\n" + dateStrComponents[1] + "\n" + dateStrComponents[0]
                    Rectangle()
                        .opacity(0.9)
                        .overlay(
                            Text(dateStr)
                                .foregroundColor(
                                    (timeDateHelper.dateString(date) != timeDateHelper.dateString(Date())) ? Color.black : Color.white
                                )
                                .multilineTextAlignment(.center)
                        )
                }
            }
        }.frame(maxWidth: geo.size.width * dateBarWidthProportion, maxHeight: geo.size.height * scheduleViewHeightProportion)
            .position(x: geo.size.width * (dateBarWidthProportion/2), y: geo.size.height * ((scheduleViewHeightProportion/2)+timeBarHeightProportion))
            .foregroundColor(Color.gray)
            .gesture(customVerticalDragGesture)
    }
    
    var customVerticalDragGesture: some Gesture{
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged{ value in
                let height = value.translation.height
                if height >= dragOffsetY + (geo.size.height * dayHeightProportion){
                    dragOffsetY = height
                    DispatchQueue.main.async {
                        dayPast()
                    }
                } else if height <= dragOffsetY - (geo.size.height * dayHeightProportion){
                    dragOffsetY = height
                    DispatchQueue.main.async {
                        dayFuture()
                    }
                }
            }
            .onEnded{ _ in
                dragOffsetY = .zero
            }
    }
    
    func dayFuture(){
        datesInView.removeFirst()
        datesInView.append(timeDateHelper.calendar.date(byAdding: .day, value: 1, to: datesInView.last!)!)
        timeDateHelper.setDateInView(datesInView.first!)
    }
    
    func dayPast(){
        datesInView.removeLast()
        datesInView.insert(timeDateHelper.calendar.date(byAdding: .day, value: -1, to: datesInView.first!)!, at: 0)
        timeDateHelper.setDateInView(datesInView.first!)
    }
}

struct SevenDayScheduleView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    let scrollProxy: ScrollViewProxy
    @Binding var datesInView: [Date]
    
    var body: some View{
        VStack(spacing: 0){
            TimeBar(geo: geo, datesInView: $datesInView)
            ScheduledEventsHorizontalView(geo: geo, datesInView: $datesInView)
        }.frame(width: geo.size.width * (24/hoursPerScreenWidth), height: geo.size.height)
            .onAppear{
                print("calculating scroll")
                var precomputedDatesInView: [Date] = [timeDateHelper.dateInView]
                for i in 1...6 {
                    precomputedDatesInView.append(timeDateHelper.calendar.date(byAdding: .day, value: i, to: timeDateHelper.dateInView)!)
                }
                if !precomputedDatesInView.contains(where: {timeDateHelper.calendar.isDate(Date(), inSameDayAs: $0)}){
                    scrollProxy.scrollTo("06", anchor: .leading)
                } else {
                    let currentTime = timeDateHelper.getTimeOfDayHrsMins(Date()).split(separator: ":")
                    var scrollHour = String(currentTime.first!)
                    scrollHour = timeAdjustment(scrollHour)
                    scrollProxy.scrollTo(scrollHour, anchor: .leading)
                }
            }
            .onChange(of: timeDateHelper.scrollToToday){value in
                if value {
                    let currentTime = timeDateHelper.getTimeOfDayHrsMins(Date()).split(separator: ":")
                    var scrollHour = String(currentTime.first!)
                    scrollHour = timeAdjustment(scrollHour)
                    scrollProxy.scrollTo(scrollHour, anchor: .leading)
                }
            }
    }
    
    func timeAdjustment(_ str: String) -> String {
        let events = viewModel.getDaysEvents(timeDateHelper.dateString(Date()))
        var newStr = str
        if events.contains(where: {$0.getStartTime() < Date() && timeDateHelper.calendar.date(byAdding: .minute, value: $0.getDuration(), to: $0.getStartTime())! > Date()}){
            let event = events.first(where: {$0.getStartTime() < Date() && timeDateHelper.calendar.date(byAdding: .minute, value: $0.getDuration(), to: $0.getStartTime())! > Date()})!
            let eventStart = timeDateHelper.getTimeOfDayHrsMins(event.getStartTime()).split(separator: ":")
            newStr = String(eventStart.first!)
            newStr = (String(eventStart.last!) != "00") ? newStr : String(Int(newStr)!-1)
        }
        var hr = Int(newStr)!
        hr = (hr == 12 && timeDateHelper.getAMPM(Date()) == "AM") ? 0: hr
        if newStr == str || Int(newStr)! <= Int(String(timeDateHelper.getTimeOfDayHrsMins(Date()).split(separator: ":").first!))!{
            hr = (timeDateHelper.getAMPM(Date()) == "PM") ? hr+12 : hr
        }
        hr = (hr != 0) ? hr-1 : hr
        newStr = (String(hr).count == 1) ? "0"+String(hr) : String(hr)
        newStr = (Int(newStr)! > Int(24-hoursPerScreenWidth)) ? String(Int(24-hoursPerScreenWidth)) : newStr
        return newStr
    }
}

struct TimeBar: View{
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    let geo: GeometryProxy
    @Binding var datesInView: [Date]
    
    var body: some View {
        ZStack{
            HStack(spacing: 0){
                ForEach(hoursOfDay, id: \.self){ hour in
                    WeekHourTile(geo: geo, hour: hour).id(hour)
                }
            }
            if datesInView.contains(where: {timeDateHelper.calendar.isDate($0, inSameDayAs: Date())}){
                TimeBarCursor(geo: geo)
            }
        }
    }
    
    
}

struct WeekHourTile: View {
    let geo: GeometryProxy
    let hour: String
    
    var body: some View {
        Rectangle().frame(width: geo.size.width / hoursPerScreenWidth, height: geo.size.height * timeBarHeightProportion).foregroundColor(.white).overlay(
            ZStack{
                Text(hour + ":00")
                WeekHourScaleLines()
            }.foregroundColor(.black)
        )
    }
}

struct WeekHourScaleLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.7))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.7))
        path.addLine(to: CGPoint(x: rect.maxX * 0.01, y: rect.maxY * 0.7))
        path.addLine(to: CGPoint(x: rect.maxX * 0.01, y: rect.maxY * 0.97))
        path.addLine(to: CGPoint(x: rect.maxX * 0.24, y: rect.maxY * 0.97))
        path.addLine(to: CGPoint(x: rect.maxX * 0.24, y: rect.maxY * 0.9))
        path.addLine(to: CGPoint(x: rect.maxX * 0.26, y: rect.maxY * 0.9))
        path.addLine(to: CGPoint(x: rect.maxX * 0.26, y: rect.maxY * 0.97))
        path.addLine(to: CGPoint(x: rect.maxX * 0.49, y: rect.maxY * 0.97))
        path.addLine(to: CGPoint(x: rect.maxX * 0.49, y: rect.maxY * 0.8))
        path.addLine(to: CGPoint(x: rect.maxX * 0.51, y: rect.maxY * 0.8))
        path.addLine(to: CGPoint(x: rect.maxX * 0.51, y: rect.maxY * 0.97))
        path.addLine(to: CGPoint(x: rect.maxX * 0.74, y: rect.maxY * 0.97))
        path.addLine(to: CGPoint(x: rect.maxX * 0.74, y: rect.maxY * 0.9))
        path.addLine(to: CGPoint(x: rect.maxX * 0.76, y: rect.maxY * 0.9))
        path.addLine(to: CGPoint(x: rect.maxX * 0.76, y: rect.maxY * 0.97))
        path.addLine(to: CGPoint(x: rect.maxX * 0.99, y: rect.maxY * 0.97))
        path.addLine(to: CGPoint(x: rect.maxX * 0.99, y: rect.maxY * 0.7))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.7))

        return path
    }
}

struct TimeBarCursor: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    let geo: GeometryProxy
    
    var body: some View{
        let day: CGFloat = geo.size.width * (24/hoursPerScreenWidth)
        let time: [Substring] = timeDateHelper.getTimeOfDayHrsMins(Date()).split(separator: ":")
        var hr: CGFloat = CGFloat(Int(time[0])!)
        let min: CGFloat = CGFloat(Int(time[1])!)
        hr = (hr == 12 && timeDateHelper.getAMPM(Date()) == "AM") ? 0: hr
        hr = (timeDateHelper.getAMPM(Date()) == "PM") ? hr+12 : hr
        let x: CGFloat = (day/24)*(hr+(min/60))
        return timeCursorArrow().frame(maxWidth: 10, maxHeight: .infinity).position(x: x, y: geo.size.height * (timeBarHeightProportion/2)).foregroundColor(.black)
    }
}

struct timeCursorArrow: Shape{
    
    func path(in rect: CGRect) -> Path{
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0.8*rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX * 1.02, y: 0.8*rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX * 1.02, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX * 0.98, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX * 0.98, y: 0.8*rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: 0.8*rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        
        return path
    }
}

struct ScheduledEventsHorizontalView: View{
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    @Binding var datesInView: [Date]
    
    var body: some View{
        GeometryReader{ newGeo in
            ZStack{
                WeekViewBackground()
                WeeksScheduledEvents(geo: newGeo, datesInView: $datesInView)
            }
        }.frame(width: geo.size.width * (24/hoursPerScreenWidth), height: geo.size.height * scheduleViewHeightProportion)
//        let _ = print("====== width: \(geo.size.width * (24/hoursPerScreenWidth)), height: \(geo.size.height * scheduleViewHeightProportion)")
    }
}

struct WeekViewBackground: View {
    var body: some View {
        HStack(spacing: 0){
            ForEach(hoursOfDay, id: \.self){ hour in
                if hour == "00"{
                    Rectangle().foregroundColor(.white).border(.gray, width: 1)
                } else {
                    threeSideRect(width: 1, openEdge: .leading)
                }
                threeSideRect(width: 1, openEdge: .leading)
            }
        }.foregroundColor(.gray)
    }
}

struct WeeksScheduledEvents: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    @Binding var datesInView: [Date]
    
    var body: some View {
        let dayHeight: CGFloat = geo.size.height/7
        ForEach(datesInView, id: \.self){ day in
            let daysEvents: [CALm.Event] = viewModel.getDaysEvents(timeDateHelper.dateString(day))
            let y: CGFloat = ((CGFloat(datesInView.firstIndex(of: day)!)+0.5) * dayHeight)
            Group{
                ForEach(daysEvents, id: \.self){ event in
                    let data = calculateXandDuration(event: event, day: day)
                    EventTileWeekView(geo: geo, event: event, width: data[1], height: dayHeight, x:data[0], y: y)
                }
            }
        }
        
        if datesInView.contains(where: {timeDateHelper.calendar.isDate($0, inSameDayAs: Date())}){
            CurrentDayTimeBar(geo: geo, datesInView: $datesInView)
        }
    }
    
    func calculateXandDuration(event: CALm.Event, day: Date) -> [CGFloat]{
        var overNighter: Bool = false
        if !timeDateHelper.calendar.isDate(event.getStartTime(), inSameDayAs: timeDateHelper.calendar.date(byAdding: .minute, value: event.getDuration(), to: event.getStartTime())!){
            overNighter = true
        }
        let startTime: [Substring] = timeDateHelper.getTimeOfDayHrsMins(event.getStartTime()).split(separator: ":")
        var duration: CGFloat
        var hr: CGFloat = CGFloat(Int(startTime[0])!)
        hr = (hr == 12 && timeDateHelper.getAMPM(event.getStartTime()) == "AM") ? 0 : hr
        hr = (timeDateHelper.getAMPM(event.getStartTime()) == "PM") ? hr+12 : hr
        let min: CGFloat = CGFloat(Int(startTime[1])!)/60
        if !overNighter{
            duration = (CGFloat(event.getDuration())/60) * (geo.size.width / 24)
        } else {
            duration = (24-(hr+min)) * (geo.size.width / 24)
        }
        var x: CGFloat = ((hr + min) * (geo.size.width / 24)) + (duration/2)
        if !timeDateHelper.calendar.isDate(day, inSameDayAs: event.getStartTime()){
            duration = ((CGFloat(event.getDuration())/60)-(24-(hr+min))) * (geo.size.width / 24)
            x = duration/2
        }
        return [x, duration]
    }
}

struct EventTileWeekView: View {
    @EnvironmentObject var viewModel: CALvm
    let geo : GeometryProxy
    let event: CALm.Event
    let width: CGFloat
    let height: CGFloat
    let x : CGFloat
    let y : CGFloat
    
    var body: some View{
        EventTile()
            .overlay(Text(event.getName()).multilineTextAlignment(.center).foregroundColor(.black).padding())
            .frame(width: width, height: height)
            .position(x: x, y: y)
            .foregroundColor(.green)
            .onTapGesture {
                viewModel.eventSelected = event
                viewModel.lastContext = "w"
                viewModel.setViewContext("e")
            }
    }
}

struct CurrentDayTimeBar: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    let geo: GeometryProxy
    @Binding var datesInView: [Date]
    
    var body: some View {
        let idx: Int = datesInView.firstIndex(where: {timeDateHelper.calendar.isDate($0, inSameDayAs: Date())}) ?? 42
        if idx == 42{
            return AnyView(EmptyView())
        }
        let time: [Substring] = timeDateHelper.getTimeOfDayHrsMins(Date()).split(separator: ":")
        var hr: CGFloat = CGFloat(Int(time[0])!)
        let min: CGFloat = CGFloat(Int(time[1])!)
        hr = (hr == 12 && timeDateHelper.getAMPM(Date()) == "AM") ? 0: hr
        hr = (timeDateHelper.getAMPM(Date()) == "PM") ? hr+12 : hr
        let x: CGFloat = (geo.size.width / 24) * (hr + (min/60))
        let y: CGFloat = ((geo.size.height / 7) * (CGFloat(idx)+0.5))
        return AnyView(
            TimeRNBar()
                .frame(maxWidth: 10, maxHeight: ((geo.size.height / 7)*1.01))
                .position(x: x, y: y)
                .foregroundColor(.black)
                .opacity(0.9)
        )
    }
}

struct TimeRNBar: Shape {
    
    func path(in rect: CGRect) -> Path{
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + (rect.height * 0.075)))
        path.addLine(to: CGPoint(x: rect.midX * 1.1, y: rect.minY + (rect.height * 0.15)))
        path.addLine(to: CGPoint(x: rect.midX * 1.1, y: rect.minY + (rect.height * 0.85)))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + (rect.height * 0.925)))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + (rect.height * 0.925)))
        path.addLine(to: CGPoint(x: rect.midX * 0.9, y: rect.minY + (rect.height * 0.85)))
        path.addLine(to: CGPoint(x: rect.midX * 0.9, y: rect.minY + (rect.height * 0.15)))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + (rect.height * 0.075)))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}


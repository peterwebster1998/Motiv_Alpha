/*
  CALvConflicts.swift
  Motiv

  Created by Peter Webster on 4/25/23.

 //
 //  CALvConflicts.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 3/1/23.
 //
*/

import SwiftUI

struct ConflictView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    @State private var conflicts : [[CALm.Event]] = []
    @State private var selection : Bool = false
    @State private var dayInView : [CALm.Event] = []
    
    var body: some View {
        VStack {
            ConflictBanner
            Divider()
            if conflicts.count != 0 {
                if selection {
                    ConflictResolutionView(conflicts: $dayInView)
                } else {
                    ScrollView {
                        ForEach(conflicts, id: \.self){ day in
                            DaysConflictsTile(conflicts: day)
                                .onTapGesture {
                                    dayInView = day
                                    selection = true
                                }
                            Divider()
                        }
                    }
                }
            } else {
                Spacer()
                Text("All Conflicts Resolved!")
                Spacer()
            }
        }.onAppear{
            conflicts = viewModel.getConflicts()
            if conflicts.count == 1 {
                dayInView = conflicts.first!
                selection = true
            }
        }.onChange(of: viewModel.conflictResolved){ value in
            if value {
                self.conflicts = viewModel.getConflicts()
                if conflicts.count == 1 {
                    dayInView = conflicts.first!
                    selection = true
                } else if conflicts.count == 0 {
                    selection = false
                    dayInView = []
                }
                viewModel.conflictResolved = false
            }
        }.onChange(of: viewModel.conflictsUpdated){ value in
            if value {
                self.conflicts = viewModel.getConflicts()
                if conflicts.count == 1 {
                    dayInView = conflicts.first!
                    selection = true
                }
                viewModel.conflictsUpdated = false
            }
        }
    }
    
    var ConflictBanner: some View {
        ZStack {
            HStack {
                Button {
                    if selection {
                        dayInView = []
                        selection = false
                    } else {
                        viewModel.eventConflict = false
                    }
                } label: {
                    Image(systemName: "chevron.left").padding().font(.largeTitle)
                }
                Spacer()
            }
            Text("Conflicts").padding().font(.largeTitle)
        }.foregroundColor(.black)
    }
}

struct DaysConflictsTile: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let conflicts : [CALm.Event]
    
    
    var body: some View {
        HStack{
            //            let _ = print(conflicts)
            Text(conflicts.first!.getDateKey()).padding().font(.title)
            Spacer()
            Text(String(conflicts.count)).padding().font(.title)
        }
    }
}

struct ConflictResolutionView: View {
    @EnvironmentObject var timeDateHelper : TimeDateHelper
    @EnvironmentObject var viewModel : CALvm
    @Binding var conflicts : [CALm.Event]
    
    var body: some View {
        VStack{
            ConflictResolutionDateNavigator()
            Divider()
            ScrollViewReader{ proxy in
                ScrollView{
                    HStack(spacing: 0){
                        VStack{
                            ForEach(hoursOfDay, id: \.self){ hour in
                                Text("\(hour):00").padding().id(hour)
                            }
                        }
                        VStack(spacing:0){
                            ForEach(hoursOfDay, id: \.self){hr in
                                VStack(spacing:0){
                                    threeSideRect(width: 1, openEdge: .bottom)
                                    if hr != "23"{
                                        threeSideRect(width: 1, openEdge: .bottom)
                                    } else {
                                        Rectangle().strokeBorder(style: StrokeStyle(lineWidth: 1))
                                    }
                                }.foregroundColor(Color.gray)
                            }
                        }.overlay(
                            GeometryReader { geo in
                                ConflictScheduledEventsView(geo: geo, conflicts: $conflicts)
                            }
                        )
                    }
                }.task{
                    let startTime = conflicts.first!.getStartTime()
                    timeDateHelper.setDateInView(startTime)
                    let hour = hourToScrollTo(startTime)
                    proxy.scrollTo(hour, anchor: .top)
                    print("Conflict starttime: \(timeDateHelper.getTimeOfDayHrsMins(startTime) + " " + timeDateHelper.getAMPM(startTime))\nScroll Hour: \(hour)")
                }
            }
        }
        
    }
    
    func hourToScrollTo(_ time: Date) -> String {
        let timeStr = timeDateHelper.getTimeOfDayHrsMins(time)
        let hrSeg = timeStr.split(separator: ":")[0]
        var hr = Int(hrSeg)!
        hr = (hr == 12 && timeDateHelper.getAMPM(time) == "AM") ? 0: hr
        hr = (timeDateHelper.getAMPM(time) == "PM") ? hr+12 : hr
        hr = (hr != 0) ? hr-2 : hr
        hr = (hr > 13) ? 13 : hr
        return (String(hr).count == 1) ? "0"+String(hr): String(hr)
    }
}

struct ConflictResolutionDateNavigator: View {
    @EnvironmentObject var timeDateHelper : TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    
    var body: some View {
        ZStack{
            HStack{
                Button {
                    let weekEarlier = timeDateHelper.calendar.date(byAdding: .day, value: -7, to: timeDateHelper.dateInView)!
                    if weekEarlier < Date() {
                        timeDateHelper.setDateInView(Date())
                    } else {
                        timeDateHelper.setDateInView(weekEarlier)
                    }
                } label: {
                    Image(systemName: "chevron.left.2")
                        .opacity((Date() >= timeDateHelper.calendar.date(byAdding: .day, value: -7, to: timeDateHelper.dateInView)!) ? 0.2 : 1)
                }.padding()
                Button {
                    let dayEarlier = timeDateHelper.calendar.date(byAdding: .day, value: -1, to: timeDateHelper.dateInView)!
                    if dayEarlier < Date() {
                        timeDateHelper.setDateInView(Date())
                    } else {
                        timeDateHelper.setDateInView(dayEarlier)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .opacity((Date() >= timeDateHelper.calendar.date(byAdding: .day, value: -1, to: timeDateHelper.dateInView)!) ? 0.2 : 1)
                }.padding()
                Spacer()
                Button {
                    timeDateHelper.setDateInView(timeDateHelper.calendar.date(byAdding: .day, value: 1, to: timeDateHelper.dateInView)!)
                } label: {
                    Image(systemName: "chevron.right")
                }.padding()
                Button {
                    timeDateHelper.setDateInView(timeDateHelper.calendar.date(byAdding: .day, value: 7, to: timeDateHelper.dateInView)!)
                } label: {
                    Image(systemName: "chevron.right.2")
                }.padding()
            }.foregroundColor(.black)
            Text("\(timeDateHelper.dateString(timeDateHelper.dateInView))").font(.title).padding()
        }
    }
}

struct ConflictScheduledEventsView: View {
    
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    @Binding var conflicts: [CALm.Event]
    @State var availableTimeWindows: [[CGFloat]] = [[0,0]]
    
    var body: some View {
        let height = geo.size.height
        let minuteHeight = height / (24*60)
        //Scheduled Events
        var daysEvents = viewModel.getDaysEvents(timeDateHelper.dateString(timeDateHelper.dateInView))
        ForEach(daysEvents, id: \.self){ event in
            let data = calculateYandDuration(event: event, day: timeDateHelper.dateInView)
            EventTileViewWrapping(geo: geo, event: event, duration: data[1], y: data[0], x: geo.size.width * (1/4), offsetY: 0)
        }.onChange(of: timeDateHelper.dateInView){_ in
            //Still bugging, does not reload position of overnighter when switching between its days, but loads in correct position when first loaded on either day
            daysEvents = []
            let newEvents = viewModel.getDaysEvents(timeDateHelper.dateString(timeDateHelper.dateInView))
            daysEvents = newEvents
        }
        
        //Conflicts
        ForEach(conflicts, id: \.self){ event in
            let startTime = timeDateHelper.getTimeOfDayHrsMins(event.getStartTime()).split(separator: ":")
            let hr = pmHourAdjustment(event: event, hour: CGFloat(Int(startTime[0])!))
            let min = CGFloat(Int(startTime[1])!)
            let y = ((hr *  60) + min) * minuteHeight
            let duration = CGFloat(event.getDuration()) * minuteHeight
            ConflictTileView(availableTimeWindows: $availableTimeWindows, geo: geo, event: event, duration: duration, y: y, x: geo.size.width * (3/4))
        }
        
        AvailableTimeWindowView(geo: geo, conflicts: $conflicts, windows: $availableTimeWindows)
    }
    
    func calculateYandDuration(event: CALm.Event, day: Date) -> [CGFloat]{
        let overNighter = event.getOverNighter()
        let sameDay = timeDateHelper.calendar.isDate(day, inSameDayAs: event.getStartTime())
        let hourHeight = geo.size.height/24
        let startTime = timeDateHelper.getTimeOfDayHrsMins(event.getStartTime()).split(separator: ":")
        let hr = pmHourAdjustment(event: event, hour: CGFloat(Int(startTime[0])!))
        let min = CGFloat(Int(startTime[1])!)/60
        var y = (hr+min) * hourHeight
        var duration: CGFloat
        if !sameDay {
            let yesterdaysDuration = 24-(hr+min)
            duration = ((CGFloat(event.getDuration())/60)-yesterdaysDuration) * hourHeight
            y = 0
        } else if overNighter{
            duration = (24-(hr+(min))) * hourHeight
        } else {
            duration = (CGFloat(event.getDuration())/60) * hourHeight
        }
        
        return [y, duration]
    }
    
    func pmHourAdjustment(event: CALm.Event, hour: CGFloat) -> CGFloat {
        var hr = hour
        if (hr == 12 && timeDateHelper.getAMPM(event.getStartTime()) == "AM"){hr = 0}
        if (timeDateHelper.getAMPM(event.getStartTime()) == "PM"){hr += 12}
        return hr
    }
    
}

struct EventTileView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    let color: Color
    @State var event: CALm.Event
    @Binding var duration: CGFloat
    @Binding var y: CGFloat
    @Binding var x: CGFloat
    @State private var selected: Bool = false
    @Binding var offsetY: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4).frame(width: geo.size.width/2, height: duration)
            .border(.black, width: 0.75)
            .gesture((event.getOverNighter()) ? nil : gestureFunc)
            .overlay (
                ZStack{
                    if selected {
                        HStack{
                            Button{
                                //Remove 15mins from duration
                                duration -= geo.size.height/(24*4)
                                let durationMins = 15 * round(((duration/geo.size.height)*24*60)/15)
                                let success = updateEvent()
                                if !success {
                                    print("Couldn't change duration of event: \(event), duration: \(durationMins)")
                                }
                                if round(((duration/geo.size.height)*24*60)/15) == 0{
                                    if viewModel.isConflict(event) {
                                        viewModel.deleteConflict(event)
                                        print("deleting conflict")
                                    } else {
                                        viewModel.deleteEvent(event)
                                        print("deleting event")
                                    }
                                    viewModel.conflictResolved = true
                                    
                                }
                            } label: {
                                Image(systemName: "rectangle.arrowtriangle.2.inward").foregroundColor(.black).font(.body).padding(2)
                            }
                            Spacer()
                            VStack{
                                Button{
                                    if viewModel.isConflict(event) {
                                        viewModel.deleteConflict(event)
                                        print("deleting conflict")
                                    } else {
                                        viewModel.deleteEvent(event)
                                        print("deleting event")
                                    }
                                    viewModel.conflictResolved = true
                                } label: {
                                    Image(systemName: "trash").foregroundColor(.black).font(.body).padding(2)
                                }
                                Spacer()
                            }
                        }
                    }
                    Text(event.getName()).foregroundColor(Color.black)
                }
            )
            .foregroundColor(color)
            .position(x: x, y: y + (duration / 2) + offsetY)
            .onChange(of: timeDateHelper.dateInView){ _ in
                let dateString = timeDateHelper.dateString(timeDateHelper.dateInView)
                let eventDate = event.getDateKey()
                if dateString != eventDate && !event.getOverNighter(){
                    let success = updateEvent()
                    if !success {
                        print("Error changing date of event")
                    }
                }
            }
        
        
    }
    
    var gestureFunc : some Gesture {
        let dragFunc = DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged{ value in
                let verticalDrag = value.translation.height
                let height = geo.size.height
                let quarterHrHeight = height / (24*4)
                offsetY = CGFloat(Int(verticalDrag / quarterHrHeight)) * quarterHrHeight
            }
            .onEnded{value in
                y += offsetY
                offsetY = .zero
                let success = updateEvent()
                if !success {
                    print("Error Event Not Updated")
                } else {
                    print("Event Updated: \(event)")
                }
            }
        let tapFunc = TapGesture()
            .onEnded { _ in
                selected.toggle()
            }
        
        let gestureFunc = dragFunc.sequenced(before: tapFunc)
        return gestureFunc
    }
    
    func updateEvent() -> Bool{
        let height = geo.size.height
        let timeHeightProportion = abs(y/height) * 24
        var hr = CGFloat(Int(timeHeightProportion))
        //        hr = (hr < 23) ? hr+1 : hr // +1 because the first hour of the day is 00
        var min = (timeHeightProportion - hr)*60
        min = (min <= 60) ? min : min-60 // covers edge case of hr being 11pm and therefore minute count being calculated with adjusted hr value instead of true hr value
        let durationInt = Int((duration/height) * 24*60)
        min = 15 * round(min/15)
        if (min == 60) {
            hr += 1
            min = 0
        }
        
        let result = viewModel.editEvent(event: event, name: event.getName(), description: event.getDescription(), duration: durationInt, repetition: CALm.Repeat(rawValue: event.getRepetition())!, time: timeDateHelper.calendar.date(bySettingHour: Int(hr), minute: Int(min), second: 0, of: timeDateHelper.dateInView)!)
        viewModel.conflictsUpdated = result
        viewModel.refreshWindows = true
        return result
    }
}

struct EventTileViewWrapping: View {
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    let geo: GeometryProxy
    @State var event: CALm.Event
    @State var duration: CGFloat
    @State var y: CGFloat
    @State var x: CGFloat
    @State var offsetY: CGFloat = 0
    
    var body: some View {
        EventTileView(geo: geo, color: .blue, event: event, duration: $duration, y: $y, x: $x, offsetY: $offsetY)
    }
}

struct ConflictTileView: View {
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @Binding var availableTimeWindows: [[CGFloat]]
    let geo: GeometryProxy
    @State var event: CALm.Event
    @State var duration: CGFloat
    @State var y: CGFloat
    @State var x: CGFloat
    @State var offsetY: CGFloat = 0
    
    var nextToAvailableTimeWindow: Bool {
        for item in availableTimeWindows {
            if Int(item[0]) <= Int(y) && Int(item[0]+item[1]) >= Int(y+duration){
                return true
            }
        }
        return false
    }
    
    
    var body: some View{
        EventTileView(geo: geo, color: .red, event: event, duration: $duration, y: $y, x: $x, offsetY: $offsetY)
        if nextToAvailableTimeWindow {
            Button{
                print("Attempting to resolve conflict, adding event: \(event)")
                let success = viewModel.addEventToDay(day: timeDateHelper.dateString(timeDateHelper.dateInView), event: event)
                print("Success: \(success)")
                if success {
                    viewModel.deleteConflict(event)
                    viewModel.conflictResolved = true
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .font(.title)
            }.position(x: geo.size.width * 3/7, y: y + offsetY + duration/2)
            
        }
    }
}

struct AvailableTimeWindowView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    @Binding var conflicts: [CALm.Event]
    @Binding var windows: [[CGFloat]]
    @State private var minDurationOfConflict: Int = 0
    
    var body: some View {
        ForEach(windows.indices, id: \.self){ idx in
            let item = windows[idx]
            if item[1] >= ((CGFloat(minDurationOfConflict)/60) * (geo.size.height/24)){
                TimeWindows(y: item[0], duration: item[1], x: geo.size.width/4, width: geo.size.width/2)
                    .modifier(PulseAnimation(duration: 1, minOpacity: 0.3))
            }
        }.onAppear{
            self.windows = getWindows()
            self.minDurationOfConflict = getMinDurationOfConflict()
        }.onChange(of: timeDateHelper.dateInView){ _ in
            self.windows = getWindows()
            self.minDurationOfConflict = getMinDurationOfConflict()
        }.onChange(of: viewModel.refreshWindows){ value in
            if value {
                self.windows = getWindows()
                self.minDurationOfConflict = getMinDurationOfConflict()
                viewModel.refreshWindows = false
            }
        }
    }
    
    func getWindows() -> [[CGFloat]]{
        var freeTime: [Float] = [0, 24]
        var daysEvents: [CALm.Event] = viewModel.getDaysEvents(timeDateHelper.dateString(timeDateHelper.dateInView))
        //Check for overnighter
        if daysEvents.first!.getOverNighter(){
            let startTime = timeDateHelper.getTimeAsHrsFloat(daysEvents.first!.getStartTime())
            let yesterdaysDuration = 24-startTime
            let todaysDuration = (Float(daysEvents.first!.getDuration())/60) - yesterdaysDuration
            freeTime[0] = todaysDuration
            daysEvents.removeFirst()
        }
        for event in daysEvents{
            let startTime = timeDateHelper.getTimeAsHrsFloat(event.getStartTime())
            let endTime = startTime + (Float(event.getDuration())/60)
            if freeTime.contains(startTime) && freeTime.contains(endTime){
                freeTime.remove(at: freeTime.firstIndex(of: startTime)!)
                freeTime.remove(at: freeTime.firstIndex(of: endTime)!)
            } else if freeTime.contains(startTime) && !freeTime.contains(endTime) {
                let idx = freeTime.firstIndex(of: startTime)!
                freeTime.append(endTime)
                freeTime.remove(at: idx)
            } else if !freeTime.contains(startTime) && freeTime.contains(endTime){
                let idx = freeTime.firstIndex(of: endTime)!
                freeTime.append(startTime)
                freeTime.remove(at: idx)
            } else {
                freeTime.append(startTime)
                freeTime.append(endTime)
            }
        }
        
        freeTime = freeTime.sorted()
        if freeTime.last! > Float(24) {
            freeTime.removeLast()
            if freeTime.count % 2 != 0{
                freeTime.removeLast()
            }
        }
        var windows: [[CGFloat]] = []
        for i in stride(from: 0, to: freeTime.count, by: 2){
            let startTime = CGFloat(freeTime[i])
            let endTime = CGFloat(freeTime[i+1])
            let duration = (endTime - startTime) * (geo.size.height / 24)
            let y = geo.size.height * (startTime/24)
            windows.append([y, duration])
        }
        return windows
    }
    
    func getMinDurationOfConflict() -> Int{
        var minDuration: Int = .max
        for event in conflicts {
            minDuration = (event.getDuration() < minDuration) ? event.getDuration() : minDuration
        }
        //        print("minDurationOfConflict: \(minDuration)")
        return minDuration
    }
}

struct TimeWindows: View {
    let y: CGFloat
    let duration: CGFloat
    let x: CGFloat
    let width: CGFloat
    
    var body: some View {
        Rectangle()
            .frame(width: width, height: duration)
            .foregroundColor(.clear)
            .border(.mint, width: 5)
            .position(x: x, y: y + (duration/2))
    }
}

struct PulseAnimation: ViewModifier {
    @State private var opacity: Double = 1
    let duration: Double
    let minOpacity: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear{
                let baseAnimation = Animation.linear(duration: duration)
                let repeated = baseAnimation.repeatForever(autoreverses: true)
                withAnimation(repeated){
                    self.opacity = minOpacity
                }
            }
    }
}

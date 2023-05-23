/*
 CALvEventInteraction.swift
 Motiv
 
 Created by Peter Webster on 4/25/23.
 
 //
 //  CALvEventInterraction.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 1/26/23.
 //
 */

import SwiftUI

//Required Variables
internal let hoursOfDay = ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
internal let minuteIntervals = ["00", "15", "30", "45"]
internal let monthsOfYear = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

struct CreateEventView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    let geo: GeometryProxy
    @State private var nameToPass: String = ""
    @State private var description: String = ""
    @State private var startTime: Date = Date()
    @State private var duration: Int = 0
    @State private var repetition: CALm.Repeat = .Never
    
    //Picker Variables
    @State private var pickerTime: String = ""
    @State private var pickerHour: String = ""
    @State private var pickerMin: String = ""
    
    @State private var pickerMonth: String = ""
    @State private var pickerDay: Int = 0
    @State private var pickerYear: Int = 2020
    
    @State private var daysOfMonth: ClosedRange<Int> = 1...31
    
    @State private var monthSelect : Bool = false
    @State private var daySelect : Bool = false
    @State private var yearSelect : Bool = false
    @State private var timeSelect : Bool = false
    @State private var repeatSelect : Bool = false
    
    var body: some View {
        VStack {
            Group {
                ZStack {
                    Text("Create New Event").font(.largeTitle)
                    HStack {
                        Button {
                            viewModel.createEvent = false
                        } label: {
                            Image(systemName: "chevron.backward").padding()
                        }
                        Spacer()
                    }
                }
            }
            Group {
                Divider()
                Text("Event Name").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding(.horizontal)
                TextField("Name", text: $nameToPass).padding(.horizontal)
            }
            Group {
                Divider()
                Text("Description").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding(.horizontal)
                TextEditor(text: $description).frame(maxWidth: geo.size.width * 0.9, maxHeight: 150, alignment: .topLeading)
            }
            Group{
                Divider()
                Text("Time/Date").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding(.horizontal)
                HStack{
                    Spacer()
                    Text(pickerTime == "" ? "Time" : pickerTime).padding().font(.title).overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.gray, lineWidth: 3)
                    ).onTapGesture {
                        timeSelect = true
                    }
                    .sheet(isPresented: $timeSelect){
                        VStack{
                            HStack{
                                Picker("Hour", selection: $pickerHour){
                                    ForEach(hoursOfDay, id: \.self){
                                        Text($0)
                                    }
                                }.pickerStyle(WheelPickerStyle())
                                Text(":")
                                Picker("Minute", selection: $pickerMin){
                                    ForEach(minuteIntervals, id: \.self){
                                        Text($0)
                                    }
                                }.pickerStyle(WheelPickerStyle())
                            }
                            Spacer()
                            Button {
                                if pickerHour != ""{
                                    pickerMin = (pickerMin == "") ? "00" : pickerMin
                                    pickerTime = pickerHour + ":" + pickerMin
                                } else if pickerMin != "" {
                                    pickerHour = "00"
                                    pickerTime = pickerHour + ":" + pickerMin
                                } else {
                                    pickerHour = "00"
                                    pickerMin = "00"
                                    pickerTime = "00:00"
                                }
                                timeSelect = false
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                    
                    
                    Spacer()
                    Text(pickerMonth == "" ? "Month" : pickerMonth).padding().font(.title).overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.gray, lineWidth: 3)
                    ).onTapGesture {
                        monthSelect = true
                    }
                    .popover(isPresented: $monthSelect){
                        VStack{
                            Picker("Month", selection: $pickerMonth){
                                ForEach(monthsOfYear, id: \.self){
                                    Text($0)
                                }
                            }.pickerStyle(WheelPickerStyle())
                            Spacer()
                            Button {
                                monthSelect = false
                                //                                if pickerMonth != ""{
                                //                                    let cal = timeDateHelper.calendar
                                //                                    let numDaysinMonth = cal.range(of: .day, in: .month, for: cal.date(from: DateComponents(year: pickerYear, month: monthsOfYear.firstIndex(of: pickerMonth)!+1))!)!.upperBound - 1
                                //                                    daysOfMonth = 1...numDaysinMonth
                                ////                                    print("\(pickerMonth) has \(numDaysinMonth) days")
                                //                                }
                            } label: {
                                Text("Done")
                            }
                            
                        }
                    }
                    Spacer()
                    Text("\(pickerDay)").padding().font(.title).overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.gray, lineWidth: 3)
                    ).onTapGesture {
                        daySelect = true
                    }
                    .popover(isPresented: $daySelect){
                        VStack{
                            Picker("Day", selection: $pickerDay){
                                ForEach(daysOfMonth, id: \.self){
                                    Text(String($0))
                                }
                            }.pickerStyle(WheelPickerStyle())
                            Spacer()
                            Button {
                                daySelect = false
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                    
                    Spacer()
                    Text(String(pickerYear)).padding().font(.title).overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.gray, lineWidth: 3)
                    ).onTapGesture {
                        yearSelect = true
                    }
                    .popover(isPresented: $yearSelect){
                        VStack{
                            Picker("Year", selection: $pickerYear){
                                ForEach(2020...2100, id: \.self){
                                    Text(String($0))
                                }
                            }.pickerStyle(WheelPickerStyle())
                            Spacer()
                            Button {
                                yearSelect = false
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                    Spacer()
                }.foregroundColor(Color.black)
                Divider()
                Group{
                    Text("Duration").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding(.horizontal)
                    HStack{
                        Button {
                            duration -= 15
                            duration = (duration < 0) ? 0 : duration
                        } label: {
                            Image(systemName: "minus.rectangle").font(.title).foregroundColor(Color.gray)
                        }
                        Text(timeDateHelper.convertMinstoHrsMins(duration)).font(.title).foregroundColor(Color.black).padding()
                        Button {
                            duration += 15
                        } label: {
                            Image(systemName: "plus.rectangle").font(.title).foregroundColor(Color.gray)
                        }
                    }
                    HStack{
                        Spacer()
                        Text("End Time:\t\(getEndTime())").padding(.horizontal)
                    }
                }
                Divider()
                Group{
                    Text("Repeat").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding(.horizontal)
                    Button {
                        repeatSelect = true
                    } label: {
                        Text(repetition.id).padding().font(.title).overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(.gray, lineWidth: 3)
                        )
                    }
                    .popover(isPresented: $repeatSelect) {
                        VStack{
                            Picker("Repetition", selection: $repetition){
                                ForEach(CALm.Repeat.allCases){
                                    Text($0.rawValue).tag($0)
                                }
                            }.pickerStyle(WheelPickerStyle())
                            Spacer()
                            Button {
                                repeatSelect = false
                            } label: {
                                Text("Done")
                            }
                        }.foregroundColor(Color.black)
                    }
                }.foregroundColor(Color.black)
                Divider()
            }
            Spacer()
            Button {
                if nameToPass != "" && duration != 0{
                    print("Create Event!")
                    let cal = timeDateHelper.calendar
                    let startTime = cal.date(from: DateComponents(year: pickerYear, month: monthsOfYear.firstIndex(of: pickerMonth)! + 1, day: Int(pickerDay), hour: Int(pickerHour), minute: Int(pickerMin)))
                    let dateKey = timeDateHelper.dateString(startTime!)
                    let event = CALm.Event(dateKey: dateKey, startTime: startTime!, durationMins: duration, eventName: nameToPass, description: description, repetition: repetition)
                    let success = viewModel.addEventToDay(day: dateKey, event: event)
                    if success {
                        viewModel.createEvent = false
                    }
                }
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray, lineWidth: 1.5)
                        .frame(width:75, height:50)
                    Text("Create").foregroundColor(Color.black)
                }
            }
        }.onAppear{
            let dateString = timeDateHelper.dateString(timeDateHelper.dateInView)
            let dateStringArr = dateString.split(separator: " ")
            pickerMonth = String(dateStringArr[1])
            pickerDay = Int(dateStringArr[0])!
            pickerYear = Int(dateStringArr[2])!
            daysOfMonth = 1...timeDateHelper.calendar.range(of: .day, in: .month, for: timeDateHelper.dateInView)!.upperBound-1
        }.onChange(of: pickerMonth){ value in
            let monthNo = monthsOfYear.firstIndex(where: {$0 == value})! + 1
            daysOfMonth = 1...timeDateHelper.calendar.range(of: .day, in: .month, for: timeDateHelper.calendar.date(from: DateComponents(year: pickerYear, month: monthNo, day: 1))!)!.upperBound-1
        }.onChange(of: pickerYear){ _ in
            let monthNo = monthsOfYear.firstIndex(where: {$0 == pickerMonth})! + 1
            daysOfMonth = 1...timeDateHelper.calendar.range(of: .day, in: .month, for: timeDateHelper.calendar.date(from: DateComponents(year: pickerYear, month: monthNo, day: 1))!)!.upperBound-1
        }
    }
    
    private func getEndTime() -> String {
        if pickerTime == "" {
            return ""
        } else {
            var hr = Int(pickerHour)! + Int(duration/60)
            var min = Int(pickerMin)! + (duration%60)
            if min > 59 {
                min -= 60
                hr += 1
            }
            hr = hr%24
            return String(hr) + ":" + (min == 0 ? "00": String(min))
        }
    }
}

struct EventView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var HABviewModel: HABvm
    let geo: GeometryProxy
    @State private var event: CALm.Event = CALm.Event(dateKey: "0000", startTime: Date(), durationMins: 0, eventName: "Placeholder Event", description: "", repetition: .Never)
    @State private var taskList: [TDLm.Task] = []
    @State private var completedHabit: Bool = false
    
    var body: some View {
        ZStack{
            VStack{
                Divider()
                dateTimeDurationBar
                Divider()
                descriptionTile
                Divider()
                if event.getSeriesID() != nil{
                    if viewModel.getEventSeries(event.getSeriesID()!).getHabit() != nil{
                        habitTile
                        Divider()
                    }
                }
                tasksTile
                Spacer()
            }
        }.alert(isPresented:$viewModel.deleteMode){
            Alert(
                title: Text("Are you sure you want to delete: \("'")\(event.getName())\("'")?"),
                message: Text("This action cannot be undone"),
                primaryButton: .destructive(Text("Delete"), action: {
                    viewModel.deleteMode = false
                    viewModel.deleteEvent(event)
                    viewModel.setViewContext(viewModel.lastContext!)
                    viewModel.lastContext = nil
                    viewModel.eventSelected = nil
                }),
                secondaryButton: .cancel({
                    viewModel.deleteMode = false
                }))
        }.onAppear{
            setVariables()
        }.onChange(of: viewModel.eventSelected){ val in
            if val != nil{
                setVariables()
            }
        }
    }
    
    func setVariables(){
        event = viewModel.eventSelected!
        taskList = event.getTasks()
        if event.getSeriesID() != nil{
            if viewModel.getEventSeries(event.getSeriesID()!).getHabit() != nil{
                let habit = viewModel.getEventSeries(event.getSeriesID()!).getHabit()!
                if habit.getTasks().count < 0{
                    taskList.append(contentsOf: habit.getTasks())
                }
            }
        }
    }
    
    var dateTimeDurationBar: some View{
        HStack{
            Spacer()
            Group{
                Text(event.getDateKey()).frame(alignment: .center)
                Text("\(timeDateHelper.getTimeOfDayHrsMins(event.getStartTime())) \(timeDateHelper.getAMPM(event.getStartTime()))")
            }
            Spacer()
            Group{
                Image(systemName: "timer")
                Text(timeDateHelper.convertMinstoHrsMins(event.getDuration()))
            }
            Spacer()
            Group{
                Image(systemName: "repeat")
                Text(event.getRepetition())
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    var descriptionTile: some View {
        HStack{
            Text("Description").font(.title).padding()
            Spacer()
        }
        Text(event.getDescription()).frame(maxWidth: .infinity, alignment: .leading).padding()
    }
    
    var habitTile: some View {
        HStack{
            Text("Habit: \(viewModel.getEventSeries(event.getSeriesID()!).getHabit()!.getName())").font(.title).padding()
            Spacer()
            Button {
                //Complete Habit
                var habit = viewModel.getEventSeries(event.getSeriesID()!).getHabit()!
                if !completedHabit{
                    habit.complete()
                    completedHabit = true
                } else {
                    habit.undoComplete()
                    completedHabit = false
                }
                HABviewModel.updateHabit(habit)
            } label: {
                Image(systemName: completedHabit ? "arrow.uturn.backward" : "checkmark").font(.title).foregroundColor(.black).padding().overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1.5).foregroundColor(.clear)
                )
            }.padding()
        }
    }
    
    @ViewBuilder
    var tasksTile: some View {
        HStack{
            Text("Tasks:").font(.title).padding()
            Spacer()
            Button{
                viewModel.createTask = true
            } label: {
                Image(systemName: "plus").font(.title).padding()
            }
        }.foregroundColor(.black)
        
        RoundedRectangle(cornerRadius: 15).stroke(.gray, lineWidth: 1).frame(maxWidth: geo.size.width * 0.9, maxHeight: geo.size.height * 0.6).foregroundColor(.clear).overlay(
            ScrollView{
                ForEach(taskList, id: \.self){ task in
                    ElementTile(title: task.getName())
                    Divider()
                }
            }
        )
    }
}

struct AddTaskFormView: View {
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var TDH: TimeDateHelper
    let geo: GeometryProxy
    @State private var event: CALm.Event = CALm.Event(dateKey: "", startTime: Date(), durationMins: 0, eventName: "", description: "", repetition: .Never)
    @State private var nameToPass: String = ""
    @State private var description: String = ""
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.7)
            addTaskForm.frame(maxWidth: geo.size.width * 0.9, maxHeight: geo.size.height * 0.7)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            .task{
                event = viewModel.eventSelected!
            }
    }
    
    @ViewBuilder
    var addTaskForm: some View{
        RoundedRectangle(cornerRadius: 15).foregroundColor(.white).overlay(
            VStack(spacing: 0){
                ZStack{
                    Text("Create New Task").font(.largeTitle)
                    HStack {
                        Button {
                            viewModel.createTask = false
                        } label: {
                            Image(systemName: "chevron.backward").font(.title).padding()
                        }
                        Spacer()
                    }
                }
                Divider()
                Text("Task Name").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding()
                TextField("Name", text: $nameToPass).padding()
                Divider()
                Text("Description").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding()
                TextEditor(text: $description).overlay(
                    RoundedRectangle(cornerRadius: 7.5).stroke(.gray, lineWidth: 1).foregroundColor(.clear)
                ).padding()
                Divider()
                Button {
                    if nameToPass != ""{
                        let task : TDLm.Task
                        if description != "" {
                            task = TDLm.Task(key: TDH.dateString(event.getStartTime()), name: nameToPass, description: description, parentTaskID: nil, deadline: event.getStartTime())
                        } else {
                            task = TDLm.Task(key: TDH.dateString(event.getStartTime()), name: nameToPass, description: nil, parentTaskID: nil, deadline: event.getStartTime())
                        }
                        //Currently broken for some reason, task is added to event but local event is not updated
                        event.addTask(task)
                        viewModel.updateEvent(event)
                        viewModel.eventSelected = event
                    }
                    viewModel.createTask = false
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray, lineWidth: 1.5)
                            .frame(width:75, height:50)
                        Text("Create")
                    }
                }.padding()
            }.foregroundColor(.black)
        )
    }
}

struct EditEventView: View {
    
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    let geo: GeometryProxy
    @State private var eventName = ""
    @State private var description = ""
    @State private var duration = 0
    @State private var repetition = CALm.Repeat.Never
    @State private var startTime = Date()
    @State private var event: CALm.Event = CALm.Event(dateKey: "", startTime: Date(), durationMins: 0, eventName: "", description: "", repetition: .Never)
    @State private var eventSeries: CALm.EventSeries?
    @State private var habitDeleted: Bool = false
    @State private var repeatSelect : Bool = false
    @State private var durationSelect : Bool = false

    
    
    var body: some View {
        VStack{
            ScrollView {
                Group{
                    dateTimeTile
                    Divider()
                    durationTile
                    Divider()
                    repetitionTile
                    Divider()
                    descriptionTile
                    Divider()
                }
                if event.getSeriesID() != nil{
                    if viewModel.getEventSeries(event.getSeriesID()!).getHabit() != nil {
                        habitTile
                        Divider()
                    }
                }
                if event.getTasks().count > 0 {
                    tasksTile
                }
            }
            Spacer()
            confirmButton
            Spacer()
            
        }.foregroundColor(.black).onAppear {
            event = viewModel.eventSelected!
            eventName = event.getName()
            description = event.getDescription()
            duration = event.getDuration()
            repetition = CALm.Repeat(rawValue: event.getRepetition())!
            startTime = event.getStartTime()
            if event.getSeriesID() != nil {
                eventSeries = viewModel.getEventSeries(event.getSeriesID()!)
            }
        }
    }

    @ViewBuilder
    var dateTimeTile: some View {
        HStack {
            Text("Start Date & Time:").padding()
            Spacer()
            DatePicker("", selection: $startTime).labelsHidden()
            Spacer()
        }
    }
    
    @ViewBuilder
    var durationTile: some View {
        HStack{
            Text("Duration: ").padding(.horizontal)
            Spacer()
            Button {
                duration -= 15
                duration = (duration < 0) ? 0 : duration
            } label: {
                Image(systemName: "minus.rectangle")
            }.foregroundColor(.black)
            Label(timeDateHelper.convertMinstoHrsMins(duration), systemImage: "timer")
                .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 10))
            Button {
                duration += 15
            } label: {
                Image(systemName: "plus.rectangle")
            }.foregroundColor(.black)
            Spacer()
        }
    }
    
    @ViewBuilder
    var repetitionTile: some View {
        HStack{
            Text("Repetition: ").padding(.horizontal)
            Spacer()
            Button{
                repeatSelect = true
            } label: {
                Label(repetition.rawValue, systemImage: "repeat")
                    .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }.popover(isPresented: $repeatSelect) {
                VStack{
                    Picker("Repetition", selection: $repetition){
                        ForEach(CALm.Repeat.allCases){
                            Text($0.rawValue).tag($0)
                        }
                    }.pickerStyle(WheelPickerStyle())
                    Spacer()
                    Button {
                        repeatSelect = false
                    } label: {
                        Text("Done")
                    }
                }
            }.foregroundColor(Color.black)
            Spacer()
        }
    }
    
    @ViewBuilder
    var descriptionTile: some View {
        HStack{
            Text("Description").font(.title).padding()
            Spacer()
        }
        TextEditor(text: $description).frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading).padding()
    }
    
    var habitTile: some View {
        HStack{
            Text("Habit: \(viewModel.getEventSeries(event.getSeriesID()!).getHabit()!.getName())").font(.title).padding()
            Spacer()
            Button {
                if !habitDeleted {
                    eventSeries!.deleteHabit()
                }
                habitDeleted.toggle()
            } label: {
                Text(!habitDeleted ? "Unlink from Habit" : "Undo").font(.title2).padding().overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1.5).foregroundColor(.clear)
                )
            }.padding()
        }
    }
    
    @ViewBuilder
    var tasksTile: some View {
        HStack{
            Text("Tasks:").font(.title).padding()
            Spacer()
        }
       
        RoundedRectangle(cornerRadius: 5).stroke(lineWidth: 0.2).overlay(
            ScrollView{
                let eventTasks = viewModel.eventSelected!.getTasks()
                if eventTasks.count > 0 {
                    ForEach(eventTasks, id: \.self){ task in
                        HStack{
                            Button  {
                                //Deleting Task
                                print("Deleting Task - \(task.getName())")
                                event.deleteTask(task)
                            } label: {
                                Image(systemName: "trash").padding(.horizontal)
                            }.padding(.horizontal)
                            Text(task.getName())
                            Spacer()
                        }.padding()
                    }
                }
            }.foregroundColor(Color.black).font(.title2)
        ).frame(maxWidth: geo.size.width * 0.85, maxHeight: geo.size.height * 0.5)
    }
    
    var confirmButton: some View {
        Button {
            //Make edits
            if !viewModel.editSeries{
                let success = viewModel.editEvent(event: event, name: eventName, description: description, duration: duration, repetition: repetition, time: startTime)
                if success {
                    event = CALm.Event(dateKey: timeDateHelper.dateString(startTime), startTime: startTime, durationMins: duration, eventName: eventName, description: description, repetition: repetition,/* eventTasks: viewModel.getTasks(event),*/ seriesID: event.getSeriesID())
                    viewModel.eventSelected = event
                    viewModel.setViewContext("e")
                }
            } else {
                let success = viewModel.editEventSeries(event: event, name: eventName, description: description, duration: duration, repetition: repetition, time: startTime)
                if success {
                    event = CALm.Event(dateKey: timeDateHelper.dateString(startTime), startTime: startTime, durationMins: duration, eventName: eventName, description: description, repetition: repetition, eventTasks: event.getTasks(), seriesID: event.getSeriesID())
                    if habitDeleted {
                        viewModel.updateEventSeries(eventSeries!)
                    }
                    viewModel.eventSelected = event
                    viewModel.editSeries = false
                    viewModel.setViewContext("e")
                }
            }
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray, lineWidth: 1.5)
                    .frame(width: 175, height:50)
                Text("Confirm Changes").foregroundColor(Color.black)
            }
        }
    }
}


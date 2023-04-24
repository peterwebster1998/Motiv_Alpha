//
//  CALvEventInterraction.swift
//  motiv-prerelease
//  --> moved to Motiv on 4/24/23
//
//  Created by Peter Webster on 1/26/23.
//

import SwiftUI

//Required Variables
internal let hoursOfDay = ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
internal let minuteIntervals = ["00", "15", "30", "45"]
internal let monthsOfYear = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

struct CreateEventView: View {
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
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
                TextEditor(text: $description).frame(maxWidth: UIScreen.screenWidth, maxHeight: 150, alignment: .topLeading)
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

struct eventInterractionSheet: View {
    
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @EnvironmentObject var viewModel: CALvm
    @Binding var eventBinding : CALm.Event?
    @State private var event: CALm.Event = CALm.Event(dateKey: "0000", startTime: Date(), durationMins: 0, eventName: "Placeholder Event", description: "", repetition: .Never)
    
    var body: some View {
        VStack{
            ZStack{
                HStack{
                    Button {
                        eventBinding = nil
                    } label: {
                        Image(systemName: "chevron.left").foregroundColor(Color.black).font(.title)
                    }
                    Spacer()
                    Menu {
                        dropDownMenu
                    } label: {
                        Image(systemName: "slider.horizontal.3").padding().foregroundColor(Color.black)
                    }
                }
                Text(event.getName()).font(.largeTitle)
            }.padding()
            Divider()
            HStack{
                Spacer()
                Group{
                    Text(timeDateHelper.dateString(event.getStartTime())).frame(alignment: .center)
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
            Divider()
            HStack{
                Text("Description").font(.title).padding()
                Spacer()
            }
            Text(event.getDescription()).frame(maxWidth: .infinity, alignment: .leading).padding()
            Divider()
            //Insert ToDo interraction here
            HStack{
                Text("Tasks:").font(.title).padding()
                Spacer()
            }
            ZStack{
                RoundedRectangle(cornerRadius: 5).stroke(lineWidth: 0.2).frame(maxWidth: UIScreen.screenWidth*0.85)
                ScrollView{
                    let eventTasks = viewModel.getTasks(event)
                    if eventTasks != nil {
                        ForEach(eventTasks!.getTasks(), id: \.self){ task in
                            HStack{
                                Button  {
                                    //Toggle Task State
                                    print("Task State Toggled - \(task.taskTitle)")
                                    viewModel.toggleEventsTaskState(event: event, task: task)
                                } label: {
                                    if task.complete {
                                        Image(systemName: "checkmark.square").padding(.horizontal)
                                    } else {
                                        Image(systemName: "square").padding(.horizontal)
                                    }
                                }.padding(.horizontal)
                                if task.complete {
                                    Text(task.taskTitle).strikethrough()
                                } else {
                                    Text(task.taskTitle)
                                }
                                Spacer()
                            }.padding()
                        }
                        Button {
                            //Add task to event
                            print("Add additional tasks")
                            viewModel.createTask = true
                        } label: {
                            Text("+ Add New Task")
                        }.padding()
                    } else {
                        Button {
                            //Add task to event
                            print("Add first task")
                            viewModel.createTask = true
                        } label: {
                            Text("+ Add First Task")
                        }.padding()
                    }
                }.foregroundColor(Color.black).font(.title2)
            }
            Spacer()
        }.sheet(isPresented: $viewModel.createTask) {
            //Create task view
            AddTaskFormView(event: event)
        }.alert(isPresented:$viewModel.deleteMode){
            Alert(
                title: Text("Are you sure you want to delete: \("'")\(event.getName())\("'")?"),
                message: Text("This action cannot be undone"),
                primaryButton: .destructive(Text("Delete"), action: {
                viewModel.deleteMode = false
                viewModel.deleteEvent(event)
                eventBinding = nil
                }),
                secondaryButton: .cancel({
                    viewModel.deleteMode = false
                }))
        }.sheet(isPresented: $viewModel.editMode){
            EditEventSheet(eventBinding: $event)
        }.onAppear(){
            event = eventBinding!
        }
        
    }
    
    @ViewBuilder
    var dropDownMenu: some View {
        // Delete item
        Button {
            viewModel.deleteMode = true
            viewModel.editMode = false
        } label: {
            Text("Delete")
            Spacer()
            Image(systemName: "trash")
        }
        // Edit item
        Button {
            viewModel.editMode = true
            viewModel.deleteMode = false
        } label: {
            Text("Edit")
            Spacer()
            Image(systemName: "pencil")
        }
        // Edit Event Series
        if event.getSeriesID() != nil{
            Button {
                viewModel.editMode = true
                viewModel.editSeries = true
                viewModel.deleteMode = false
            } label: {
                Text("Edit Series")
                Spacer()
                Image(systemName: "pencil")
            }
        }
    }
}

struct AddTaskFormView: View {
    
    @EnvironmentObject var viewModel: CALvm
    let event: CALm.Event
    @State private var nameToPass: String = ""
    @State private var description: String = ""
    
    var body: some View {
        VStack {
            ZStack{
                Text("Create New Task").font(.largeTitle)
                HStack {
                    Button {
                        viewModel.createTask = false
                    } label: {
                        Image(systemName: "chevron.backward").padding()
                    }
                    Spacer()
                }
            }
            Divider()
            Text("Task Name").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding()
            TextField("Name", text: $nameToPass)
            Divider()
            Text("Description").frame(maxWidth: .infinity, alignment: .leading).font(.title2).padding()
            TextEditor(text: $description).frame(maxWidth: UIScreen.screenWidth, maxHeight: 150, alignment: .topLeading)
            Divider()
            Spacer()
            Button {
                if nameToPass != ""{
                    let task : TDLm.ToDoList.Task
                    let taskNo = event.getTasks()?.tasks.count ?? 0
                    if description != "" {
                        task = TDLm.ToDoList.Task(taskTitle: nameToPass, taskNo: taskNo, description: description)
                    } else {
                        task = TDLm.ToDoList.Task(taskTitle: nameToPass, taskNo: taskNo)
                    }
                    viewModel.addTaskToEvent(event: event, task: task)
                }
                viewModel.createTask = false
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray, lineWidth: 1.5)
                        .frame(width:75, height:50)
                    Text("Create").foregroundColor(Color.black)
                }
            }
        }
    }
}

struct EditEventSheet: View {
    
    @EnvironmentObject var viewModel: CALvm
    @EnvironmentObject var timeDateHelper: TimeDateHelper
    @Binding var eventBinding: CALm.Event
    @State private var eventName = ""
    @State private var description = ""
    @State private var duration = 0
    @State private var repetition = CALm.Repeat.Never
    @State private var startTime = Date()
    @State private var event: CALm.Event = CALm.Event(dateKey: "", startTime: Date(), durationMins: 0, eventName: "", description: "", repetition: .Never)
    
    //Picker Variables
    @State private var repeatSelect : Bool = false
    @State private var durationSelect : Bool = false
    
    
    var body: some View {
        VStack{
            ZStack{
                HStack{
                    Button {
                        viewModel.editMode = false
                    } label: {
                        Image(systemName: "chevron.left").foregroundColor(Color.black).font(.title)
                    }
                    Spacer()
                }
                TextField(eventName, text: $eventName).font(.largeTitle).multilineTextAlignment(.center).padding(.horizontal)
            }.padding()
            Divider()
            // Start Date & Time Manipulation
            HStack {
                Text("Start Date & Time:").padding(.horizontal)
                Spacer()
                DatePicker("", selection: $startTime).labelsHidden()
                Spacer()
            }
            Divider()
            // Duration Manipulation
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
            Divider()
            // Repetition Manipulation
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
            Group{
                Divider()
                HStack{
                    Text("Description").font(.title).padding()
                    Spacer()
                }
                TextEditor(text: $description).frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading).padding()
                Divider()
            }
            //Insert ToDo interraction here
            Group{
                HStack{
                    Text("Tasks:").font(.title).padding()
                    Spacer()
                }
                ZStack{
                    RoundedRectangle(cornerRadius: 5).stroke(lineWidth: 0.2).frame(maxWidth: UIScreen.screenWidth*0.85)
                    ScrollView{
                        let eventTasks = viewModel.getTasks(event)
                        if eventTasks != nil {
                            ForEach(eventTasks!.getTasks(), id: \.self){ task in
                                HStack{
                                    Button  {
                                        //Deleting Task
                                        print("Deleting Task - \(task.taskTitle)")
                                        viewModel.deleteTaskInEvent(event: event, task: task)
                                    } label: {
                                        Image(systemName: "trash").padding(.horizontal)
                                    }.padding(.horizontal)
                                    Text(task.taskTitle)
                                    Spacer()
                                }.padding()
                            }
                        }
                    }.foregroundColor(Color.black).font(.title2)
                }
            }
            Group{
                Spacer()
                Button {
                    //Make edits
                    if !viewModel.editSeries{
                        let success = viewModel.editEvent(event: event, name: eventName, description: description, duration: duration, repetition: repetition, time: startTime)
                        if success {
                            eventBinding = CALm.Event(dateKey: timeDateHelper.dateString(startTime), startTime: startTime, durationMins: duration, eventName: eventName, description: description, repetition: repetition, eventTasks: viewModel.getTasks(event), seriesID: event.getSeriesID())
                            viewModel.editMode = false
                        }
                    } else {
                        let success = viewModel.editEventSeries(event: event, name: eventName, description: description, duration: duration, repetition: repetition, time: startTime)
                        if success {
                            eventBinding = CALm.Event(dateKey: timeDateHelper.dateString(startTime), startTime: startTime, durationMins: duration, eventName: eventName, description: description, repetition: repetition, eventTasks: viewModel.getTasks(event), seriesID: event.getSeriesID())
                            viewModel.editSeries = false
                            viewModel.editMode = false
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
                Spacer()
            }
        }.onAppear {
            event = eventBinding
            eventName = event.getName()
            description = event.getDescription()
            duration = event.getDuration()
            repetition = CALm.Repeat(rawValue: event.getRepetition())!
            startTime = event.getStartTime()
        }
    }
}


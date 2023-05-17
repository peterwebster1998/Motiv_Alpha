//
//  HABv.swift
//  Motiv
//
//  Created by Peter Webster on 5/7/23.
//

import SwiftUI

struct HABv: View {
    @EnvironmentObject var viewModel: HABvm
    @State var height: CGFloat = UIScreen.main.bounds.height * 0.1
    
    var body: some View {
        GeometryReader { geo in
            ZStack{
                HABBanner(geo: geo).position(x: UIScreen.main.bounds.midX, y: height/2)
                HABBody(geo: geo).frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.9).position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.height * 0.55)
                if viewModel.addTask {
                    AddTaskToHabitView(geo: geo)
                }
                if viewModel.pressAndHold{
                    HABPressAndHoldView()
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct HABBanner: View {
    @EnvironmentObject var viewModel: HABvm
    @EnvironmentObject var homeViewModel: HomeViewModel
    let geo: GeometryProxy
    @State var bannerText: String = "Habits"
    
    var body: some View {
        VStack(spacing: 0){
            ZStack{
                Text(bannerText).font(.largeTitle)
                    .onLongPressGesture(minimumDuration: 1, maximumDistance: 10){
                        if viewModel.viewContext == .One{
                            viewModel.habitElementToEdit = "Name"
                            viewModel.pressAndHold = true
                        }
                    }
                bannerButtons
            }
            DividerLine(geo: geo)
        }.onChange(of: viewModel.viewContext){_ in
            switch viewModel.viewContext{
            case .All:
                bannerText = "Habits"
            case .New:
                bannerText = "New Habit"
            case .One:
                bannerText = viewModel.selectedHabit!.getName()
            case .Task:
                bannerText = viewModel.selectedTask!.getName()
            }
        }.onChange(of: viewModel.selectedHabit){_ in
            switch viewModel.viewContext{
            case .All:
                bannerText = "Habits"
            case .New:
                bannerText = "New Habit"
            case .One:
                bannerText = viewModel.selectedHabit!.getName()
            case .Task:
                bannerText = viewModel.selectedTask!.getName()
            }
        }
    }
    
    @ViewBuilder
    var bannerButtons: some View {
        HStack{
            switch viewModel.viewContext {
            case .All:
                Button{
                    homeViewModel.appSelect = true
                } label: {
                    Image(systemName: "square.grid.3x3.fill").padding()
                }
            case .Task:
                Button{
                    viewModel.setViewContext("one")
                    viewModel.selectedTask = nil
                } label: {
                    Image(systemName: "chevron.left").padding()
                }
            default:
                Button{
                    viewModel.setViewContext("all")
                    viewModel.selectedHabit = nil
                } label: {
                    Image(systemName: "chevron.left").padding()
                }
            }
            
            Spacer()
            if viewModel.viewContext == .All {
                Button{
                    viewModel.setViewContext("new")
                } label: {
                    Image(systemName: "plus").padding()
                }
            } else if viewModel.viewContext == .One {
                Menu{
                    habitMenu
                } label: {
                    Image(systemName: "slider.horizontal.3").padding()
                }
            }
        }.foregroundColor(.black).font(.title)
    }
    
    @ViewBuilder
    var habitMenu: some View {
        Button{
            //Check to see if want to create new task or pair with existing tasks
            viewModel.addTask = true
        } label: {
            HStack{
                Image(systemName: "plus")
                Text("Add Task")
            }.foregroundColor(.black)
        }
        Button{
            viewModel.selectedHabit!.undoComplete()
            viewModel.updateHabit(viewModel.selectedHabit!)
        } label: {
            HStack{
                Image(systemName: "arrow.uturn.backward")
                Text("Undo")
            }.foregroundColor(.black)
        }
        Button{
            viewModel.deleteMode = true
        } label: {
            HStack{
                Image(systemName: "trash")
                Text("Delete Habit")
            }.foregroundColor(.black)
        }
    }
}

struct HABBody: View {
    @EnvironmentObject var viewModel: HABvm
    let geo: GeometryProxy
    
    var body: some View{
        ZStack{
            switch viewModel.viewContext{
            case .All:
                AllHabitsView(geo: geo)
            case .One:
                HabitView(geo: geo)
            case .New:
                CreateHabitView()
            case .Task:
                TDLTaskView(geo: geo, task: viewModel.selectedTask!, inHabit: true)
            }
        }.alert(isPresented:$viewModel.deleteMode){
            Alert(
                title: Text("Are you sure you want to delete: \("'")\(viewModel.selectedHabit!.getName())\("'")?"),
                message: Text("This action cannot be undone"),
                primaryButton: .destructive(Text("Delete"), action: {
                    viewModel.deleteMode = false
                    let result = viewModel.deleteHabit(viewModel.selectedHabit!.getName())
                    if result{
                        viewModel.setViewContext("all")
                        viewModel.selectedHabit = nil
                    } else {
                        print("Deletig habit \("'")\(viewModel.selectedHabit!.getName())\("'") was unsuccessful")
                    }
                }),
                secondaryButton: .cancel({
                    viewModel.deleteMode = false
                }))
        }
    }
}

struct AllHabitsView: View {
    @EnvironmentObject var viewModel: HABvm
    let geo: GeometryProxy
    @State var habits: [HABm.Habit] = []
    
    let habitCols = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView{
            if habits.filter({$0.getRepetitionPeriod() == .Daily}).count > 0{
                Text("Daily").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: habitCols){
                    ForEach(habits.filter({$0.getRepetitionPeriod() == .Daily}), id: \.self){ habit in
                        HabitTileView(geo: geo, habit: habit).padding(.vertical)
                            .onTapGesture {
                                viewModel.selectedHabit = habit
                                viewModel.setViewContext("one")
                            }
                    }
                }.padding(.horizontal)
            }
            if habits.filter({$0.getRepetitionPeriod() == .Weekly}).count > 0{
                DividerLine(geo: geo)
                Text("Weekly").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: habitCols){
                    ForEach(habits.filter({$0.getRepetitionPeriod() == .Weekly}), id: \.self){ habit in
                        HabitTileView(geo: geo, habit: habit).padding(.vertical)
                            .onTapGesture {
                                viewModel.selectedHabit = habit
                                viewModel.setViewContext("one")
                            }
                    }
                }.padding(.horizontal)
            }
            if habits.filter({$0.getRepetitionPeriod() == .Monthly}).count > 0{
                DividerLine(geo: geo)
                Text("Monthly").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: habitCols){
                    ForEach(habits.filter({$0.getRepetitionPeriod() == .Monthly}), id: \.self){ habit in
                        HabitTileView(geo: geo, habit: habit).padding(.vertical)
                            .onTapGesture {
                                viewModel.selectedHabit = habit
                                viewModel.setViewContext("one")
                            }
                    }
                }.padding(.horizontal)
            }
            if habits.filter({$0.getRepetitionPeriod() == .Quarterly}).count > 0{
                DividerLine(geo: geo)
                Text("Quarterly").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: habitCols){
                    ForEach(habits.filter({$0.getRepetitionPeriod() == .Quarterly}), id: \.self){ habit in
                        HabitTileView(geo: geo, habit: habit).padding(.vertical)
                            .onTapGesture {
                                viewModel.selectedHabit = habit
                                viewModel.setViewContext("one")
                            }
                    }
                }.padding(.horizontal)
            }
            if habits.filter({$0.getRepetitionPeriod() == .Annually}).count > 0{
                DividerLine(geo: geo)
                Text("Annually").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: habitCols){
                    ForEach(habits.filter({$0.getRepetitionPeriod() == .Annually}), id: \.self){ habit in
                        HabitTileView(geo: geo, habit: habit).padding(.vertical)
                            .onTapGesture {
                                viewModel.selectedHabit = habit
                                viewModel.setViewContext("one")
                            }
                    }
                }.padding(.horizontal)
            }
            if habits.filter({$0.getRepetitionPeriod() == .Decennially}).count > 0{
                DividerLine(geo: geo)
                Text("Decennially (10 Years)").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: habitCols){
                    ForEach(habits.filter({$0.getRepetitionPeriod() == .Decennially}), id: \.self){ habit in
                        HabitTileView(geo: geo, habit: habit).padding(.vertical)
                            .onTapGesture {
                                viewModel.selectedHabit = habit
                                viewModel.setViewContext("one")
                            }
                    }
                }.padding(.horizontal)
            }
            if habits.filter({$0.getRepetitionPeriod() == .Centennially}).count > 0{
                DividerLine(geo: geo)
                Text("Centennially (100 Years)").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: habitCols){
                    ForEach(habits.filter({$0.getRepetitionPeriod() == .Centennially}), id: \.self){ habit in
                        HabitTileView(geo: geo, habit: habit).padding(.vertical)
                            .onTapGesture {
                                viewModel.selectedHabit = habit
                                viewModel.setViewContext("one")
                            }
                    }
                }.padding(.horizontal)
            }
            Spacer()
        }.font(.title2).task{
            habits = viewModel.getHabits()
        }.onChange(of: viewModel.updated){val in
            if val {
                habits = viewModel.getHabits()
            }
        }
    }
}

struct HabitView: View {
    @EnvironmentObject var viewModel: HABvm
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @State var habit: HABm.Habit = HABm.Habit(name: "place", notes: "holders", repetition: (.Daily, 1))
    
    var body: some View {
        VStack{
            statsBar
            DividerLine(geo: geo)
            HStack{
                Text("Last Completion:").padding(.horizontal)
                Spacer()
                Text("\(tdh.getTimeOfDayHrsMins(habit.getLastCompletion())) \(tdh.getAMPM(habit.getLastCompletion())) \(tdh.dateString(habit.getLastCompletion()))").padding(.horizontal)
            }
            HStack{
                Text("Frequency:").padding(.horizontal)
                Spacer()
                Text(habit.getRepetition()).padding(.horizontal)
            }
            Group{
            Text("Notes:").frame(maxWidth: .infinity, alignment: .leading).font(.title).padding()
            Text(habit.getNotes())
            }.onLongPressGesture(minimumDuration: 1, maximumDistance: 10){
                viewModel.habitElementToEdit = "Notes"
                viewModel.pressAndHold = true
            }
            Text("Tasks:").frame(maxWidth: .infinity, alignment: .leading).font(.title).padding()
            ZStack{
                RoundedRectangle(cornerRadius: 15).stroke(.black, lineWidth: 2).foregroundColor(.clear)
                ScrollView{
                    ForEach(habit.getTasks(), id: \.self){ task in
                        ElementTile(title: task.getName(), inHabit: true).scaleEffect(0.95)
                        DividerLine(geo: geo, screenProportion: 0.64, lineWidth: 2)
                    }
                }
            }.frame(maxWidth: UIScreen.main.bounds.width * 0.85, maxHeight: UIScreen.main.bounds.height * 0.5)
            Spacer()
        }.task {
            habit = viewModel.selectedHabit!
        }.onChange(of: viewModel.selectedHabit){ val in
            if val != nil{
                habit = viewModel.selectedHabit!
            }
        }
    }
    
    var statsBar: some View {
        HStack{
            HStack{
                Image(systemName: "flame")
                Text("Streak: \(habit.getStreak())")
            }.padding(.horizontal)
            HStack{
                Image(systemName: "star.circle")
                Text("Best: \(habit.getBestStreak())")
            }.padding(.horizontal)
            HStack{
                Image(systemName: "checkmark.seal")
                Text("Total: \(habit.getCount())")
            }.padding(.horizontal)
        }.font(.title3).frame(maxWidth: .infinity)
    }
}

struct CreateHabitView: View {
    @EnvironmentObject var viewModel: HABvm
    @State var nameField: String = ""
    @State var notesField: String = ""
    @State var timePeriod: HABm.Habit.repetitionPeriod = .Daily
    @State var periodStr: String = "Day"
    @State var numStr: String = ""
    @State var count: Int = 0
    
    var body: some View {
        VStack{
            Text("Name").font(.title).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
            TextField("Enter Name Here", text: $nameField).padding(.horizontal)
            Text("Notes").font(.title).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
            TextField("Start typing here", text: $notesField).padding(.horizontal)
            Text("Repetition").font(.title).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
            HStack{
                TextField("Count", text: $numStr).padding(.horizontal)
                    .keyboardType(.numberPad)
                    .onChange(of: numStr){ val in
                        let onlyNumeric = val.filter{ "0123456789".contains($0) }
                        if onlyNumeric != val {
                            numStr = onlyNumeric
                            count = Int(onlyNumeric)!
                        } else {
                            count = Int(val) ?? 0
                        }
                    }
                Text("times per").padding(.horizontal)
                Menu {
                    timePeriodOptions
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10).stroke(.gray, lineWidth: 1).foregroundColor(.clear)
                        Text(periodStr)
                    }
                }
            }.frame(maxWidth: UIScreen.main.bounds.width * 0.8, maxHeight: UIScreen.main.bounds.height * 0.2, alignment: .center)
            Button{
                if nameField != "" && count != 0 && !simplifyValues(){
                    viewModel.addHabit(HABm.Habit(name: nameField, notes: notesField, repetition: (timePeriod, count)))
                    viewModel.selectedHabit = viewModel.getHabit(nameField)
                    viewModel.setViewContext("one")
                }
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 10).stroke(.gray, lineWidth: 1).foregroundColor(.clear)
                    Text("Create")
                }.frame(maxWidth: UIScreen.main.bounds.width * 0.2, maxHeight: UIScreen.main.bounds.height * 0.05)
            }.padding()
        }.foregroundColor(.black).font(.title3)
            .onChange(of: count){ val in
                numStr = String(val)
            }
    }
    
    @ViewBuilder
    var timePeriodOptions: some View {
        Button{
            timePeriod = .Daily
            periodStr = "Day"
        } label: {
            Text("Day")
        }
        Button{
            timePeriod = .Weekly
            periodStr = "Week"
        } label: {
            Text("Week")
        }
        Button{
            timePeriod = .Monthly
            periodStr = "Month"
        } label: {
            Text("Month")
        }
        Button{
            timePeriod = .Quarterly
            periodStr = "Quarter"
        } label: {
            Text("Quarter")
        }
        Button{
            timePeriod = .Annually
            periodStr = "Year"
        } label: {
            Text("Year")
        }
        Button{
            timePeriod = .Decennially
            periodStr = "Decade"
        } label: {
            Text("Decade")
        }
        Button{
            timePeriod = .Centennially
            periodStr = "Century"
        } label: {
            Text("Century")
        }
    }
    
    func simplifyValues() -> Bool {
        switch timePeriod{
        case .Daily:
            return false
        case .Weekly:
            if count % 7 == 0 {
                timePeriod = .Daily
                periodStr = "Day"
                count = count / 7
                return true
            } else {
                return false
            }
        case .Monthly:
            if count % 4 == 0 {
                timePeriod = .Weekly
                periodStr = "Week"
                count = count / 4
                return true
            } else {
                return false
            }
        case .Quarterly:
            if count % 3 == 0 {
                timePeriod = .Monthly
                periodStr = "Month"
                count = count / 3
                return true
            } else {
                return false
            }
        case .Annually:
            if count % 4 == 0 {
                timePeriod = .Quarterly
                periodStr = "Quarter"
                count = count / 4
                return true
            } else {
                return false
            }
        case .Decennially:
            if count % 10 == 0 {
                timePeriod = .Annually
                periodStr = "Year"
                count = count / 10
                return true
            } else {
                return false
            }
        case .Centennially:
            if count % 10 == 0 {
                timePeriod = .Decennially
                periodStr = "Decade"
                count = count / 10
                return true
            } else {
                return false
            }
        }
    }
}

struct HabitTileView: View {
    @EnvironmentObject var viewModel: HABvm
    let geo: GeometryProxy
    @State var habit: HABm.Habit
    @State var recentlyCompleted: Bool = false
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 15).foregroundColor(.mint)
            VStack(spacing: 0){
                Text(habit.getName()).bold().padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
                DividerLine(geo: geo, screenProportion: 0.25, lineWidth: 2).padding(.vertical)
                HStack{
                    Image(systemName: "flame").padding(.horizontal)
                    Spacer()
                    Text("\(habit.getStreak())").padding(.horizontal)
                }
                HStack{
                    Image(systemName: "star.circle").padding(.horizontal)
                    Spacer()
                    Text("\(habit.getBestStreak())").padding(.horizontal)
                }
                HStack{
                    Image(systemName: "checkmark.seal").padding(.horizontal)
                    Spacer()
                    Text("\(habit.getCount())").padding(.horizontal)
                }
                Button{
                    var updatedHabit = habit
                    if !recentlyCompleted{
                        updatedHabit.complete()
                        recentlyCompleted = true
                    } else {
                        updatedHabit.undoComplete()
                        recentlyCompleted = false
                    }
                    viewModel.updateHabit(updatedHabit)
                    habit = updatedHabit
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2).foregroundColor(.clear).padding(.horizontal)
                        Image(systemName: (!recentlyCompleted) ? "checkmark" : "arrow.uturn.backward").padding()
                    }.padding(.vertical)
                }
            }.font(.title2).foregroundColor(.black)
        }.frame(maxHeight: UIScreen.main.bounds.height * 0.25)
    }
}

struct HABPressAndHoldView: View {
    @EnvironmentObject var viewModel: HABvm
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.5).ignoresSafeArea()
            if viewModel.habitElementToEdit == "Notes" {
                HABNotesEditTile(habit: viewModel.selectedHabit!, notes: viewModel.selectedHabit!.getNotes())
            } else if viewModel.habitElementToEdit == "Name"{
                HABNameEditTile(habit: viewModel.selectedHabit!, name: viewModel.selectedHabit!.getName())
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct HABNotesEditTile: View {
    @EnvironmentObject var viewModel: HABvm
    let habit: HABm.Habit
    @State var notes: String
    
    var body: some View {
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, maxHeight: UIScreen.main.bounds.height * 0.15)
                .foregroundColor(.white)
                .overlay(
                    TextField(habit.getNotes(), text: $notes).font(.subheadline).padding()
                )
            Button{
                var updatedHabit = habit
                updatedHabit.setNotes(notes)
                viewModel.updateHabit(updatedHabit)
                viewModel.selectedHabit = updatedHabit
                viewModel.pressAndHold = false
            } label: {
                RoundedRectangle(cornerRadius: 10).foregroundColor(.white).overlay(Text("Done").foregroundColor(.black))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.2, maxHeight: UIScreen.main.bounds.height * 0.075)
            }
        }
    }
}

struct HABNameEditTile: View {
    @EnvironmentObject var viewModel: HABvm
    let habit: HABm.Habit
    @State var name: String
    
    var body: some View{
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, maxHeight: UIScreen.main.bounds.height * 0.15)
                .foregroundColor(.white)
                .overlay(
                    TextField(habit.getName(), text: $name).font(.largeTitle).padding()
                )
            Button{
                var updatedHabit = habit
                updatedHabit.setName(name)
                viewModel.updateHabit(updatedHabit)
                viewModel.selectedHabit = updatedHabit
                viewModel.pressAndHold = false
            } label: {
                RoundedRectangle(cornerRadius: 10).foregroundColor(.white).overlay(Text("Done").foregroundColor(.black))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.2, maxHeight: UIScreen.main.bounds.height * 0.075)
            }
        }
    }
}

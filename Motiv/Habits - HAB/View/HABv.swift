//
//  HABv.swift
//  Motiv
//
//  Created by Peter Webster on 5/7/23.
//

import SwiftUI

struct HABv: View {
    @State var height: CGFloat = UIScreen.main.bounds.height * 0.1

    var body: some View {
        HABBanner().position(x: UIScreen.main.bounds.midX, y: height/2)
        HABBody().frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.9).position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.height * 0.55)
    }
}

struct HABBanner: View {
    @EnvironmentObject var viewModel: HABvm
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State var bannerText: String = "Habits"
    
    var body: some View {
        ZStack{
            Text(bannerText).font(.largeTitle)
            bannerButtons
        }.onChange(of: viewModel.viewContext){_ in
            switch viewModel.viewContext{
            case .All:
                bannerText = "Habits"
            case .New:
                bannerText = "New Habit"
            case .One:
                bannerText = viewModel.selectedHabit!.getName()
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

    var body: some View{
        Group{
            switch viewModel.viewContext{
            case .All:
                AllHabitsView()
            case .One:
                HabitView()
            case .New:
                CreateHabitView()
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
    @State var habits: [HABm.Habit] = []
    
    let habitCols = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: habitCols){
            ForEach(habits, id: \.self){ habit in
                HabitTileView(habit: habit).padding(.vertical)
                    .onTapGesture {
                        viewModel.selectedHabit = habit
                        viewModel.setViewContext("one")
                    }
            }
        }.padding().task{
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
    @State var habit: HABm.Habit = HABm.Habit(name: "place", notes: "hold", repetition: (.Daily, 1))
    
    var body: some View {
        VStack{
            statsBar
            DividerLine(screenProportion: 0.8, lineWidth: 2)
            HStack{
                Text("Last Completion:").padding(.horizontal)
                Spacer()
                Text("\(tdh.getTimeOfDayHrsMins(habit.getLastCompletion())) \(tdh.getAMPM(habit.getLastCompletion())) \(tdh.dateString(habit.getLastCompletion()))").padding(.horizontal)
            }
            Text("Notes:").frame(maxWidth: .infinity, alignment: .leading).font(.title).padding()
            Text(habit.getNotes())
            Text("Tasks:").frame(maxWidth: .infinity, alignment: .leading).font(.title).padding()
            ZStack{
                RoundedRectangle(cornerRadius: 15).stroke(.black, lineWidth: 2).foregroundColor(.clear)
                ScrollView{
                    ForEach(habit.getTasks(), id: \.self){ task in
                        ElementTile(title: task.getName())
                        DividerLine(screenProportion: 0.64, lineWidth: 2)
                    }
                }
            }.frame(maxWidth: UIScreen.main.bounds.width * 0.85, maxHeight: UIScreen.main.bounds.height * 0.5)
            Spacer()
        }.task {
            habit = viewModel.selectedHabit!
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
    @State var habit: HABm.Habit
    @State var recentlyCompleted: Bool = false
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 15).foregroundColor(.mint)
            VStack(spacing: 0){
                Text(habit.getName()).bold().padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
                DividerLine(screenProportion: 0.25, lineWidth: 2).padding(.vertical)
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

struct HABv_Previews: PreviewProvider {
    static var previews: some View {
        HABv()
    }
}

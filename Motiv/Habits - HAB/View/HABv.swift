//
//  HABv.swift
//  Motiv
//
//  Created by Peter Webster on 5/7/23.
//

import SwiftUI

struct HABv: View {
    var body: some View {
        HABBanner()
        HABBody()
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
                    Image(systemName: "square.grid.3x3.fill")
                }
            default:
                Button{
                    viewModel.setViewContext("all")
                    viewModel.selectedHabit = nil
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            
            Spacer()
            if viewModel.viewContext == .All {
                Button{
                    viewModel.setViewContext("new")
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct HABBody: View {
    @EnvironmentObject var viewModel: HABvm

    var body: some View{
        switch viewModel.viewContext{
        case .All:
            AllHabitsView()
        case .One:
            HabitView()
        case .New:
            CreateHabitView()
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
                HabitTileView(habit: habit)
                    .onTapGesture {
                        viewModel.selectedHabit = habit
                        viewModel.setViewContext("one")
                    }
            }
        }.task{
            habits = viewModel.getHabits()
        }
    }
}

struct HabitView: View {
    @EnvironmentObject var viewModel: HABvm
    @State var habit: HABm.Habit = HABm.Habit(name: "place", notes: "hold", repetition: ["ers"])
    
    var body: some View {
        VStack{
            statsBar
            DividerLine(screenProportion: 0.8, lineWidth: 2)
            HStack{
                Text("Last Completion:")
                Spacer()
                Text("\(habit.getLastCompletion())")
            }
            Text("Notes:").frame(width: .infinity, alignment: .leading).font(.title)
            Text(habit.getNotes())
        }.task {
            habit = viewModel.selectedHabit!
        }
    }
    
    var statsBar: some View {
        HStack{
            Text("Streak: \(habit.getStreak())")
            Text("Best: \(habit.getBestStreak())")
            Text("Total: \(habit.getCount())")
        }.font(.title2)
    }
}

struct CreateHabitView: View {
    
    var body: some View {
        Text("Create Habit View!")
        Text("Hurry up and figure out the repetition logic")
    }
}

struct HabitTileView: View {
    let habit: HABm.Habit
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 15).foregroundColor(.mint)
            VStack{
                Text(habit.getName()).padding()
                DividerLine(screenProportion: 0.25, lineWidth: 2)
                HStack{
                    Image(systemName: "flame").padding()
                    Spacer()
                    Text("\(habit.getStreak())")
                }
                HStack{
                    ZStack{
                        Image(systemName: "flame")
                        Image(systemName: "flame").offset(x: 10, y: 0)
                    }.padding()
                    Spacer()
                    Text("\(habit.getBestStreak())")
                }
                HStack{
                    Image(systemName: "checkmark.seal").padding()
                    Spacer()
                    Text("\(habit.getCount())")
                }
            }.font(.title2).foregroundColor(.black)
        }
    }
}

struct HABv_Previews: PreviewProvider {
    static var previews: some View {
        HABv()
    }
}

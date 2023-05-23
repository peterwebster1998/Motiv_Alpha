//
//  HABvHabitInterraction.swift
//  Motiv
//
//  Created by Peter Webster on 5/18/23.
//

import SwiftUI

struct AddNoteToHabitView: View {
    @EnvironmentObject var viewModel: HABvm
    @EnvironmentObject var TDLviewModel: TDLvm
    let geo: GeometryProxy
    @State var habit: HABm.Habit = HABm.Habit(name: "place", note: "holders", repetition: (.Daily, 1))
    @State var note: String = ""
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.5)
            VStack{
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.white)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, maxHeight: UIScreen.main.bounds.height * 0.15)
                    .foregroundColor(.white)
                    .overlay(
                        TextField("Enter new note!", text: $note).font(.largeTitle).padding()
                    )
                Button{
                    var updatedHabit = habit
                    updatedHabit.addNote(note)
                    viewModel.updateHabit(updatedHabit)
                    viewModel.selectedHabit = updatedHabit
                    viewModel.addNote = false
                } label: {
                    RoundedRectangle(cornerRadius: 10).foregroundColor(.white).overlay(Text("Done").foregroundColor(.black))
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.2, maxHeight: UIScreen.main.bounds.height * 0.075)
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            .task {
                habit = viewModel.selectedHabit!
            }
    }
}
                
struct HABPressAndHoldView: View {
    @EnvironmentObject var viewModel: HABvm
    let geo: GeometryProxy
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture {
                viewModel.pressAndHold = false
            }
            if viewModel.habitElement == "Notes" {
                HABNotesTile(geo: geo)
            } else if viewModel.habitElement == "Name"{
                HABNameEditTile(habit: viewModel.selectedHabit!, name: viewModel.selectedHabit!.getName())
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct HABNotesTile: View {
    @EnvironmentObject var viewModel: HABvm
    let geo: GeometryProxy
    @State var habit: HABm.Habit = HABm.Habit(name: "place", note: "holders", repetition: (.Daily, 1))
    @State var notes: [String] = []
    
    var body: some View {
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.85, maxHeight: UIScreen.main.bounds.height * 0.85)
                .foregroundColor(.white)
                .overlay(
                    VStack{
                        HStack{
                            Text("Notes:").frame(maxWidth: .infinity, alignment: .leading).font(.title).padding()
                            Spacer()
                            Button{
                                notes.append("Enter new note...")
                            } label: {
                                Image(systemName: "plus").font(.title).padding().foregroundColor(.black)
                            }
                        }
                        DividerLine(geo: geo, screenProportion: 0.8, lineWidth: 1.5).foregroundColor(.gray)
                        ScrollView{
                            VStack{
                                ForEach(notes.indices, id: \.self){ idx in
                                    TextField(notes[idx], text: $notes[idx]).font(.title3).padding()
                                    DividerLine(geo: geo, screenProportion: 0.8, lineWidth: 1.5).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                )
        }.task{
            habit = viewModel.selectedHabit!
            notes = habit.getNotes()
        }.onChange(of: notes){ val in
            var updatedHabit = habit
            updatedHabit.setNotes(notes)
            viewModel.updateHabit(updatedHabit)
            viewModel.selectedHabit = updatedHabit
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


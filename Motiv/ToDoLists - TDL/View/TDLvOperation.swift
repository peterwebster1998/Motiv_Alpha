//
//  TDLvOperation.swift
//  Motiv
//
//  Created by Peter Webster on 4/28/23.
//

import SwiftUI

struct TDLCreateView: View {
    @EnvironmentObject var viewModel: TDLvm
    let geo: GeometryProxy
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.5)
            CreateForm(geo: geo)
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}

struct CreateForm: View {
    @EnvironmentObject var viewModel: TDLvm
    @EnvironmentObject var habVM: HABvm
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @State var height: CGFloat = UIScreen.main.bounds.height * 0.2
    @State var expanded: Bool = false
    @State var insertNameTitle: String = ""
    @State var nameField: String = ""
    @State var descriptionField: String = ""
    @State var deadlineField: Date = Date()
    @State var inHabit: Bool? = nil
    @State var inPlan: Bool? = nil
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .frame(maxWidth: geo.size.width * 0.75, maxHeight: height)
            .foregroundColor(.white)
            .animation(.linear(duration: 0.1), value: height)
            .overlay(
                formOptions
            )
            .task{
                switch viewModel.viewContext {
                case .List:
                    insertNameTitle = "Task Name"
                case .Task:
                    insertNameTitle = "Subtask Name"
                default:
                    insertNameTitle = "List Name"
                }
            }
    }
    
    @ViewBuilder
    var formOptions: some View {
        VStack{
            HStack{
                Button{
                    viewModel.createMode = false
                } label: {
                    Image(systemName: "xmark").padding().font(.title2)
                }
                Spacer()
                Button {
                    print("Creating item!")
                    if nameField != ""{
                        let des = (descriptionField == "") ? nil : descriptionField
                        let deadline = (deadlineField < Date()) ? nil : deadlineField
                        if inHabit == nil && inPlan == nil{
                            switch viewModel.viewContext {
                            case .List:
                                let key = viewModel.selectedList!
                                viewModel.addTask(key: key, name: nameField, description: des, parentTaskID: nil, deadline: deadline)
                            case .Task:
                                let key = viewModel.selectedList!
                                let parentID = viewModel.selectedTask!.getID()
                                viewModel.addTask(key: key, name: nameField, description: des, parentTaskID: parentID, deadline: deadline)
                            default:
                                viewModel.addList(nameField)
                            }
                        } else if inHabit != nil {
                            var updatedHabit = habVM.selectedHabit!
                            updatedHabit.addTask(TDLm.Task(key: "Habit",name: nameField, description: des, parentTaskID: nil, deadline: deadline))
                            habVM.updateHabit(updatedHabit)
                            habVM.selectedHabit = updatedHabit
                        } else if inPlan != nil {
                            viewModel.addTask(key: tdh.dateString(tdh.dateInView), name: nameField, description: des, parentTaskID: nil, deadline: deadline)
                            let task = viewModel.getTaskList(tdh.dateString(tdh.dateInView)).first(where: {$0.getName() == nameField})!
                            homeVM.addToDailyPlan([task])
                        }
                    }
                    viewModel.createMode = false
                } label: {
                    Text("Create").padding().font(.title2)
                }
            }
            if expanded || viewModel.viewContext == .ToDoLists || viewModel.viewContext == .AllToDos{
                Text(insertNameTitle).padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
            }
            TextField("Enter Name", text: $nameField).padding().frame(maxWidth: .infinity, alignment: .center)
            if expanded{
                DividerLine(geo: geo, screenProportion: 0.5, lineWidth: 1.5).foregroundColor(.gray)
                Text("Description").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter Description", text: $descriptionField).padding().frame(maxWidth: .infinity, alignment: .center)
                DividerLine(geo: geo, screenProportion: 0.5, lineWidth: 1.5).foregroundColor(.gray)
                Text("Deadline").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                DatePicker("Choose Date", selection: $deadlineField).labelsHidden()
            }
            if viewModel.viewContext == .List || viewModel.viewContext == .Task{
                HStack{
                    Spacer()
                    Button {
                        expanded.toggle()
                        height = expanded ? geo.size.height * 0.45 : geo.size.height * 0.2
                    } label: {
                        HStack{
                            Text(expanded ? "Less" : "More").font(.title3)
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        }.padding()
                    }
                }
            }
        }.foregroundColor(.black)
    }
}

struct TDLPressAndHoldView: View {
    @EnvironmentObject var viewModel: TDLvm
    
    var body: some View {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
            .onTapGesture{
                viewModel.editDeleteTitle = nil
                viewModel.pressAndHold = false
            }
        if viewModel.pressAndHold{
            VStack {
                ElementTile(title: (viewModel.viewContext == .List || viewModel.viewContext == .Task) ? viewModel.selectedTask!.getName() : viewModel.selectedList!)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.9, maxHeight: UIScreen.main.bounds.height * 0.15)
                HStack {
                    if viewModel.viewContext != .List && viewModel.viewContext != .Task {
                        Button{
                            viewModel.editMode = true
                        } label: {
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundColor(.white)
                                .overlay(Image(systemName: "pencil"))
                        }
                    }
                    Button{
                        viewModel.deleteMode = true
                    } label: {
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundColor(.white)
                            .overlay(Image(systemName: "trash"))
                    }
                }.foregroundColor(.black).font(.title)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.6, maxHeight: UIScreen.main.bounds.height * 0.075)
            }.alert(isPresented:$viewModel.deleteMode){
                Alert(
                    title: Text("Are you sure you want to delete: \("'")\((viewModel.viewContext == .List || viewModel.viewContext == .Task) ? viewModel.selectedTask!.getName() : viewModel.selectedList!)\("'")?"),
                    message: Text("This action cannot be undone"),
                    primaryButton: .destructive(Text("Delete"), action: {
                        if viewModel.selectedTask != nil{
                            viewModel.deleteTask(viewModel.selectedTask!.getID())
                            if viewModel.selectedTask!.isSubtask(){
                                viewModel.selectedTask = viewModel.getTask(viewModel.selectedTask!.getParentTaskID()!)
                            } else {
                                viewModel.selectedTask = nil
                            }
                        } else if viewModel.selectedList != nil {
                            viewModel.deleteList(viewModel.selectedList!)
                            viewModel.selectedList = nil
                        }
                        viewModel.editDeleteTitle = nil
                        viewModel.deleteMode = false
                        viewModel.pressAndHold = false
                    }),
                    secondaryButton: .cancel({
                        viewModel.deleteMode = false
                    }))
            }
        }
    }
}

struct TDLEditListView: View {
    @EnvironmentObject var viewModel: TDLvm
    @State var newName: String = ""
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.5)
            EditListForm
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    var EditListForm: some View {
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, maxHeight: UIScreen.main.bounds.height * 0.15)
                .foregroundColor(.white)
                .overlay(
                    TextField(viewModel.selectedList ?? "", text: $newName).font(.largeTitle).padding()
                )
            Button{
                viewModel.editListName(newName)
                viewModel.editMode = false
                viewModel.pressAndHold = false
            } label: {
                RoundedRectangle(cornerRadius: 10).foregroundColor(.white).overlay(Text("Done").foregroundColor(.black))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.2, maxHeight: UIScreen.main.bounds.height * 0.075)
            }
        }.task {
            newName = viewModel.selectedList!
        }
    }
}

struct TDLEditTaskView: View {
    @EnvironmentObject var viewModel: TDLvm
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.5).ignoresSafeArea()
            if viewModel.taskElementToEdit == "Deadline"{
                DeadlineEditTile(task: viewModel.selectedTask!, date: viewModel.selectedTask!.getDeadline() ?? Date())
            } else if viewModel.taskElementToEdit == "Description" {
                DescriptionEditTile(task: viewModel.selectedTask!, description: viewModel.selectedTask!.getDescription())
            } else if viewModel.taskElementToEdit == "Name"{
                NameEditTile(task: viewModel.selectedTask!, name: viewModel.selectedTask!.getName())
            }
        }
    }
}

struct NameEditTile: View {
    @EnvironmentObject var viewModel: TDLvm
    let task: TDLm.Task
    @State var name: String
    
    var body: some View {
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, maxHeight: UIScreen.main.bounds.height * 0.15)
                .foregroundColor(.white)
                .overlay(
                    TextField(task.getName(), text: $name).font(.largeTitle).padding()
                )
            Button{
                var newTask = task
                newTask.setName(name)
                viewModel.updateTask(newTask)
                viewModel.selectedTask = newTask
                viewModel.editMode = false
            } label: {
                RoundedRectangle(cornerRadius: 10).foregroundColor(.white).overlay(Text("Done").foregroundColor(.black))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.2, maxHeight: UIScreen.main.bounds.height * 0.075)
            }
        }
    }
}

struct DeadlineEditTile: View {
    @EnvironmentObject var viewModel: TDLvm
    let task: TDLm.Task
    @State var date: Date
    
    var body: some View {
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, maxHeight: UIScreen.main.bounds.height * 0.15)
                .overlay(
                    DatePicker("Select new deadline", selection: $date).labelsHidden()
                )
            Button{
                var newTask = task
                newTask.setDeadline(date)
                viewModel.updateTask(newTask)
                viewModel.selectedTask = newTask
                viewModel.editMode = false
            } label: {
                RoundedRectangle(cornerRadius: 10).foregroundColor(.white).overlay(Text("Done").foregroundColor(.black))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.2, maxHeight: UIScreen.main.bounds.height * 0.075)
            }
        }
    }
}

struct DescriptionEditTile: View {
    @EnvironmentObject var viewModel: TDLvm
    let task: TDLm.Task
    @State var description: String
    
    var body: some View {
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, maxHeight: UIScreen.main.bounds.height * 0.15)
                .overlay(
                    TextField(task.getDescription(), text: $description).padding()
                )
            Button{
                var newTask = task
                newTask.setDescription(description)
                viewModel.updateTask(newTask)
                viewModel.selectedTask = newTask
                viewModel.editMode = false
            } label: {
                RoundedRectangle(cornerRadius: 10).foregroundColor(.white).overlay(Text("Done").foregroundColor(.black))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.2, maxHeight: UIScreen.main.bounds.height * 0.075)
            }
        }
    }
}

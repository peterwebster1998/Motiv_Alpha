//
//  TDLv.swift
//  Motiv
//
//  Created by Peter Webster on 4/25/23.
//

import SwiftUI

struct TDLv: View {
    @EnvironmentObject var viewModel: TDLvm
    
    var body: some View {
        ZStack{
            VStack{
                TDLBanner()
                TDLBody()
            }
            if viewModel.createMode{
                TDLCreateView()
            }
        }
    }
}

struct TDLBanner: View {
    @EnvironmentObject var viewModel: TDLvm
    @EnvironmentObject var homeVM: HomeViewModel
    @State var bannerText: String = "To Do Lists"
    
    var body: some View{
        VStack(spacing: 0){
            ZStack {
                Text(bannerText).padding().frame(maxWidth: UIScreen.main.bounds.width * 0.75)
                HStack {
                    Button{
                        switch viewModel.viewContext{
                        case .Task:
                            if viewModel.selectedTask!.isSubtask(){
                                viewModel.selectedTask = viewModel.getTask(viewModel.selectedTask!.getParentTaskID()!)
                            } else {
                                viewModel.selectedTask = nil
                                viewModel.setViewContext("list")
                            }
                        case .List:
                            viewModel.selectedList = nil
                            viewModel.setViewContext(viewModel.previousViewContext!)
                            viewModel.previousViewContext = nil
                        default:
                            homeVM.appSelect = true
                        }
                    } label: {
                        switch viewModel.viewContext{
                        case .Task:
                            Image(systemName: "chevron.left").padding()
                        case .List:
                            Image(systemName: "chevron.left").padding()
                        default:
                            Image(systemName: "square.grid.3x3.fill").padding()
                        }
                    }
                    Spacer()
                    Button{
                        viewModel.createMode = true
                    } label: {
                        Image(systemName: "plus").padding()
                    }
                }
            }.foregroundColor(.black).font(.largeTitle)
            DividerLine(screenProportion: 0.6)
        }.onChange(of: viewModel.viewContext){ val in
            switch viewModel.viewContext {
            case .ToDoLists:
                bannerText = "To Do Lists"
            case .ToDosByDay:
                bannerText = "Day's To Dos"
            case .AllToDos:
                bannerText = "All To Dos"
            case .List:
                bannerText = viewModel.selectedList!
            case .Task:
                bannerText = viewModel.selectedTask!.getName()
            }
        }.onChange(of: viewModel.selectedTask){value in
            if viewModel.viewContext == .Task && value != nil{
                bannerText = value!.getName()
            }
        }
    }
}

struct TDLBody: View {
    @EnvironmentObject var viewModel: TDLvm
    @EnvironmentObject var tdh: TimeDateHelper
    @State var lists: [String] = []
    
    var body: some View {
        switch viewModel.viewContext {
        case .Task:
            TDLTaskView(task: viewModel.selectedTask!)
        default:
            TDLListView(lists: $lists)
                .task{
                    generateListsVals()
                }
                .onChange(of: viewModel.viewContext){ _ in
                    generateListsVals()
                }
                .onChange(of: viewModel.createMode){ _ in
                    generateListsVals()
                }
        }
    }
    
    func generateListsVals(){
        switch viewModel.viewContext {
        case .ToDoLists:
            lists = viewModel.getTaskListKeys()
            lists = removeDateKeys(lists)
        case .ToDosByDay:
            lists = viewModel.getTaskListKeys()
            lists = retriveDateKeys(lists)
        case .AllToDos:
            lists = viewModel.getTaskListKeys()
        case .List:
            lists = []
            for t in viewModel.getTaskList(viewModel.selectedList!){
                lists.append(t.getName())
            }
        case .Task:
            lists = []
        }
    }
    
    func removeDateKeys(_ list: [String]) -> [String]{
        var newList: [String] = []
        for str in list{
            if !tdh.isDate(str) {
                newList.append(str)
            }
        }
        return newList
    }
    
    func retriveDateKeys(_ list: [String]) -> [String]{
        var newList: [String] = []
        for str in list{
            if tdh.isDate(str) {
                newList.append(str)
            }
        }
        return newList
    }
}

struct TDLListView: View {
    @EnvironmentObject var viewModel: TDLvm
    @Binding var lists: [String]
    
    var body: some View {
        ScrollView{
            ForEach(lists, id: \.self){ list in
                ElementTile(title: list)
                    .onTapGesture {
                        switch viewModel.viewContext {
                        case .List:
                            viewModel.selectedTask = viewModel.getTaskList(viewModel.selectedList!).first(where: {$0.getName() == list})
                            viewModel.setViewContext("task")
                        default:
                            viewModel.selectedList = list
                            viewModel.previousViewContext = viewModel.viewContext.toString()
                            viewModel.setViewContext("list")
                            
                        }
                    }
                DividerLine().foregroundColor(.gray)
            }
            if lists.count == 0 {
                Text("There are currently no elements in this list").padding()
            }
        }
    }
}

struct ElementTile: View {
    @EnvironmentObject var viewModel: TDLvm
    let title: String
    @State var task: TDLm.Task? = nil
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 5).foregroundColor(.clear)
            HStack{
                if viewModel.viewContext == .List || viewModel.viewContext == .Task{
                    if task != nil {
                        Button{
                            task!.toggleCompletion()
                            viewModel.updateTask(task!)
                        } label: {
                            Image(systemName: (task!.getCompleted()) ? "checkmark.square" : "square")
                        }.padding()
                    }
                }
                Text(title)
                    .padding()
                Spacer()
                Text(viewModel.getCompletionStatus(title))
                    .padding()
            }.frame(maxWidth: .infinity)
                .foregroundColor(.black)
                .font(.title)
        }.task{
            if viewModel.viewContext == .List {
                task = viewModel.getTaskList(viewModel.selectedList!).first(where: {$0.getName() == title})
            } else if viewModel.viewContext == .Task {
                task = viewModel.getSubtasks(viewModel.selectedTask!.getID()).first(where: {$0.getName() == title})
            }
        }
    }
}

struct DividerLine: View {
    @State var screenProportion: CGFloat = 0.9
    @State var lineWidth: CGFloat = 2
    let screenWidth = UIScreen.main.bounds.size.width
    
    var body: some View {
        RoundedRectangle(cornerRadius: lineWidth/2).frame(maxWidth: screenWidth * screenProportion, maxHeight: lineWidth, alignment: .center)
    }
}

struct TDLTaskView: View {
    @EnvironmentObject var viewModel: TDLvm
    @EnvironmentObject var tdh: TimeDateHelper
    @State var task: TDLm.Task
    
    var body: some View {
        VStack{
            if task.getDescription() != ""{
                Text("Description").frame(maxWidth: .infinity, alignment: .leading).padding().font(.title2)
                Text(task.getDescription()).font(.subheadline).multilineTextAlignment(.leading).padding(.horizontal)
                DividerLine(screenProportion: 0.8, lineWidth: 2)
            }
            if task.getDeadline() != nil {
                Text("Deadline: \(tdh.dateString(task.getDeadline()!))").frame(maxWidth: .infinity, alignment: .leading).padding().font(.title2)
                DividerLine(screenProportion: 0.8, lineWidth: 2)
            }
            Text("Subtasks:").frame(maxWidth: .infinity, alignment: .leading).padding().font(.title)
            RoundedRectangle(cornerRadius: 5)
                .foregroundColor(.clear)
                .border(.black, width: 2)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                .overlay(
                    VStack{
                        if task.isParentTask() {
                            ForEach(viewModel.getSubtasks(task.getID()), id: \.self){ sub in
                                ElementTile(title: sub.getName())
                                    .onTapGesture {
                                        viewModel.selectedTask = sub
                                    }
                                DividerLine(screenProportion: 0.64, lineWidth: 2)
                            }
                        } else {
                            Text("This task currently does not have any subtasks").padding()
                        }
                        Spacer()
                    }
            )
        }.onChange(of: viewModel.selectedTask){ value in
            if value != nil {
                task = value!
            }
        }
    }
}

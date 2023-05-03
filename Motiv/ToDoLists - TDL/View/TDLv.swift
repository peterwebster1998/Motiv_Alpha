//
//  TDLv.swift
//  Motiv
//
//  Created by Peter Webster on 4/25/23.
//

import SwiftUI

struct TDLv: View {
    @EnvironmentObject var viewModel: TDLvm
    @State var height: CGFloat = UIScreen.main.bounds.height * 0.1
    
    var body: some View {
        ZStack{
            TDLBody().frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.9).position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.height * 0.55)
            TDLBanner(height: $height).position(x: UIScreen.main.bounds.midX, y: height/2)
            if viewModel.createMode{
                TDLCreateView()
            } else if viewModel.editMode && viewModel.viewContext == .ToDoLists{
                TDLEditListView()
            } else if viewModel.pressAndHold{
                TDLPressAndHoldView()
            } else if viewModel.editMode && viewModel.viewContext == .Task{
                TDLEditTaskView()
            }
        }.onAppear{viewModel.setViewContext("lists")}
    }
}

struct TDLBanner: View {
    @EnvironmentObject var viewModel: TDLvm
    @State var bannerText: String = "To Do Lists"
    @Binding var height: CGFloat
    
    var body: some View{
        VStack(spacing: 0){
            BannerTile(bannerText: $bannerText, height: $height).font(.largeTitle)
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

struct BannerTile: View {
    @EnvironmentObject var viewModel: TDLvm
    @EnvironmentObject var homeVM: HomeViewModel
    @Binding var bannerText: String
    @Binding var height: CGFloat
    @State var tapped: Bool = false
    @State var otherOptions: [String] = []
    let animationDuration: Double = 0.25
    @State var opacity: Double = 0
    
    var body: some View {
        Rectangle().foregroundColor(.white)
            .frame(maxWidth: UIScreen.main.bounds.width , maxHeight: height)
            .animation(.easeInOut(duration: animationDuration), value: height)
            .overlay(
                VStack{
                    ZStack{
                        bannerButtons
                        Text(bannerText).padding().multilineTextAlignment(.center)
                            .onTapGesture {
                                if viewModel.viewContext != .Task && viewModel.viewContext != .List{
                                    if !tapped {
                                        setOtherOptions()
                                        tapped = true
                                        height = height * 3
                                        height = min(height, UIScreen.main.bounds.height * 0.3)
                                    } else {
                                        setViewContext(bannerText)
                                    }
                                }
                            }
                    }
                    DividerLine(screenProportion: 0.64, lineWidth: 2)
                    if tapped {
                        Text(otherOptions[0]).padding()
                            .opacity(opacity)
                            .animation(.easeInOut(duration: animationDuration).delay(animationDuration * 0.25), value: opacity)
                            .onTapGesture {
                                setViewContext(otherOptions[0])
                            }
                        DividerLine(screenProportion: 0.64, lineWidth: 2)
                            .opacity(opacity)
                            .animation(.easeInOut(duration: animationDuration).delay(animationDuration * 0.5), value: opacity)
                        Text(otherOptions[1]).padding()
                            .opacity(opacity)
                            .animation(.easeInOut(duration: animationDuration).delay(animationDuration * 0.75), value: opacity)
                            .onTapGesture {
                                setViewContext(otherOptions[1])
                            }
                        DividerLine(screenProportion: 0.64, lineWidth: 2)
                            .opacity(opacity)
                            .animation(.easeInOut(duration: animationDuration).delay(animationDuration), value: opacity)
                    }
                }.foregroundColor(.black)
            )
            .onLongPressGesture(minimumDuration: 1, maximumDistance: 20){
                if viewModel.viewContext == .Task{
                    viewModel.taskElementToEdit = "Name"
                    viewModel.editMode = true
                }
            }.onChange(of: height){ _ in
               opacity = (height >= UIScreen.main.bounds.height * 0.2) ? 1 : 0
            }
    }
    
    var bannerButtons: some View {
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
    }
    
    func setOtherOptions(){
        if viewModel.viewContext == .ToDoLists {
            otherOptions = []
            otherOptions.append(contentsOf: ["Day's To Dos", "All To Dos"])
        } else if viewModel.viewContext == .ToDosByDay {
            otherOptions = []
            otherOptions.append(contentsOf: ["To Do Lists", "All To Dos"])
        } else {
            otherOptions = []
            otherOptions.append(contentsOf: ["To Do Lists", "Day's To Dos"])
        }
    }
    
    func setViewContext(_ str: String){
        if str == "To Do Lists"{
            viewModel.setViewContext("lists")
        } else if str == "Day's To Dos" {
            viewModel.setViewContext("byDay")
        } else if str == "All To Dos" {
            viewModel.setViewContext("all")
        }
        tapped = false
        height = height / 3
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
                .onChange(of: viewModel.deleteMode){ _ in
                    generateListsVals()
                }
                .onChange(of: viewModel.editMode){ _ in
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
            RoundedRectangle(cornerRadius: 15).foregroundColor(.white)
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
        }.onTapGesture {
            if !viewModel.pressAndHold{
                switch viewModel.viewContext {
                case .Task:
                    viewModel.selectedTask = viewModel.getSubtasks(viewModel.selectedTask!.getID()).first(where: {$0.getName() == title})
                case .List:
                    viewModel.selectedTask = viewModel.getTaskList(viewModel.selectedList!).first(where: {$0.getName() == title})
                    viewModel.setViewContext("task")
                default:
                    viewModel.selectedList = title
                    viewModel.previousViewContext = viewModel.viewContext.toString()
                    viewModel.setViewContext("list")
                }
            }
        }
        .gesture(pressAndHoldToEditAndDelete)
        .task{
            if viewModel.viewContext == .List {
                task = viewModel.getTaskList(viewModel.selectedList!).first(where: {$0.getName() == title})
            } else if viewModel.viewContext == .Task {
                task = viewModel.getSubtasks(viewModel.selectedTask!.getID()).first(where: {$0.getName() == title})
            }
        }
    }
    
    var pressAndHoldToEditAndDelete: some Gesture{
        let gesture = LongPressGesture(minimumDuration: 1, maximumDistance: 30).onEnded{ _ in
            if viewModel.viewContext == .List {
                viewModel.selectedTask = task
            } else if viewModel.viewContext != .Task {
                viewModel.selectedList = title
            } else {
                viewModel.selectedTask = task
            }
            viewModel.pressAndHold = true
            viewModel.editDeleteTitle = title
            print("Pressed and held!")
        }
        return gesture
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
                Group{
                    Text("Description").frame(maxWidth: .infinity, alignment: .leading).padding().font(.title2)
                    Text(task.getDescription()).font(.subheadline).multilineTextAlignment(.leading).padding(.horizontal)
                }.onLongPressGesture(minimumDuration: 1, maximumDistance: 20){
                    viewModel.taskElementToEdit = "Description"
                    viewModel.editMode = true
                    print("Edit mode!")
                }
                DividerLine(screenProportion: 0.8, lineWidth: 2)
            }
            if task.getDeadline() != nil {
                HStack{
                    Text("Deadline: ").padding()
                    Spacer()
                    Spacer()
                    Text((tdh.isToday(task.getDeadline()!)) ? tdh.getTimeOfDayHrsMins(task.getDeadline()!) : tdh.dateString(task.getDeadline()!)).padding()
                    Spacer()
                }.font(.title2).onLongPressGesture(minimumDuration: 1, maximumDistance: 20){
                    viewModel.taskElementToEdit = "Deadline"
                    viewModel.editMode = true
                }
                DividerLine(screenProportion: 0.8, lineWidth: 2)
            }
            Text("Subtasks:").frame(maxWidth: .infinity, alignment: .leading).padding().font(.title)
            
            ScrollView{
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
                }.overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black, lineWidth: 2)
                        .foregroundColor(.clear)
                        .frame(width: UIScreen.main.bounds.width * 0.8, alignment: .center)
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                .padding()
            }
        }.onChange(of: viewModel.selectedTask){ value in
            if value != nil {
                task = value!
            }
        }
    }
}

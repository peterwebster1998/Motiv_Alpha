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
        VStack{
            TDLBanner()
            TDLBody()
        }
    }
}

struct TDLBanner: View {
    @EnvironmentObject var viewModel: TDLvm
    @State var bannerText: String = "To Do Lists"

    var body: some View{
        VStack(spacing: 0){
            ZStack {
                Text(bannerText)
                HStack {
                    Button{
                        print("Back in TDLv")
                    } label: {
                        Image(systemName: "chevron.left").padding()
                    }
                    Spacer()
                }
            }.foregroundColor(.black).font(.largeTitle)
                .onChange(of: viewModel.viewContext){ val in
                    switch viewModel.viewContext {
                    case .ToDoLists:
                        bannerText = "To Do Lists"
                    case .ToDosByDay:
                        bannerText = "Day's To Dos"
                    case .AllToDos:
                        bannerText = "All To Dos"
                    case .Task:
                        bannerText = "TaskName Placeholder"
                    }
                }
            DividerLine(screenProportion: 0.6)
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
            TDLTaskView()
        default:
            TDLListView(lists: lists)
                .onAppear{
                switch viewModel.viewContext {
                case .ToDoLists:
                    lists = viewModel.getTaskListKeys()
                    lists = removeDateKeys(lists)
                case .ToDosByDay:
                    lists = viewModel.getTaskListKeys()
                    lists = retriveDateKeys(lists)
                case .AllToDos:
                    lists = viewModel.getTaskListKeys()
                case .Task:
                    lists = []
                }
            }
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
    let lists: [String]
    
    var body: some View {
        ScrollView{
            ForEach(lists, id: \.self){ list in
                Text(list).foregroundColor(.black).font(.title).padding().frame(maxWidth: .infinity, alignment: .leading)
                DividerLine().foregroundColor(.gray)
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
    
    var body: some View {
        EmptyView()
    }
}

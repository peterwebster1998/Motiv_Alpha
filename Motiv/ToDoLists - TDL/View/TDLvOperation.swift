//
//  TDLvOperation.swift
//  Motiv
//
//  Created by Peter Webster on 4/28/23.
//

import SwiftUI

struct TDLCreateView: View {
    @EnvironmentObject var viewModel: TDLvm
    
    
    var body: some View {
        ZStack{
            Color.gray.opacity(0.5)
            CreateForm()
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}

struct CreateForm: View {
    @EnvironmentObject var viewModel: TDLvm
    let screenWidth = UIScreen.main.bounds.width
    @State var height: CGFloat = UIScreen.main.bounds.height * 0.2
    @State var expanded: Bool = false
    @State var insertNameTitle: String = ""
    @State var nameField: String = ""
    @State var descriptionField: String = ""
    @State var deadlineField: Date = Date()
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .frame(maxWidth: screenWidth * 0.75, maxHeight: height)
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
                        switch viewModel.viewContext {
                        case .List:
                            let key = viewModel.selectedList!
                            let des = (descriptionField == "") ? nil : descriptionField
                            let deadline = (deadlineField < Date()) ? nil : deadlineField
                            viewModel.addTask(key: key, name: nameField, description: des, parentTaskID: nil, deadline: deadline)
                        case .Task:
                            let key = viewModel.selectedList!
                            let des = (descriptionField == "") ? nil : descriptionField
                            let parentID = viewModel.selectedTask!.getID()
                            let deadline = (deadlineField < Date()) ? nil : deadlineField
                            viewModel.addTask(key: key, name: nameField, description: des, parentTaskID: parentID, deadline: deadline)
                        default:
                            viewModel.addList(nameField)
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
                DividerLine(screenProportion: 0.5, lineWidth: 2).foregroundColor(.gray)
                Text("Description").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter Description", text: $descriptionField).padding().frame(maxWidth: .infinity, alignment: .center)
                DividerLine(screenProportion: 0.5, lineWidth: 2).foregroundColor(.gray)
                Text("Deadline").padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
                DatePicker("Choose Date", selection: $deadlineField).labelsHidden()
            }
            if viewModel.viewContext == .List || viewModel.viewContext == .Task{
                HStack{
                    Spacer()
                    Button {
                        expanded.toggle()
                        height = expanded ? screenHeight * 0.45 : screenHeight * 0.2
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

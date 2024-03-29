/*
  HomeView.swift
  Motiv

  Created by Peter Webster on 4/25/23.

 //
 //  HomeView.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 4/11/23.
 //
*/

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var HABvm: HABvm
    
    var body: some View {
        GeometryReader{ geo in
            ZStack{
                if !HABvm.getHabit("Plan")!.linkedToEventSeries(){
                    //TO DO: Complete implementation
                    ScheduleDailyPlanView(geo: geo)
                } else {
                    if viewModel.currentActiveModule == nil {
                        CompositeHomeView(geo: geo)
                    } else {
                        ModuleView(geo: geo)
                    }
//                    let _ = print("x: \(geo.size.width), y: \(geo.size.height)")
                    HomeNavBubble(x: geo.size.width + (buttonSize * 0.35) , y: geo.size.height * 0.6)
                }
                
            }
        }.sheet(isPresented: $viewModel.appSelect){
            AppsNavigatorView()
        }
    }
}

struct AppSelectButton: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        Button{
            viewModel.appSelect = true
        } label: {
            Image(systemName: "square.grid.3x3.fill")
                .padding()
                .font(.title)
                .foregroundColor(.black)
        }
    }
}

struct ModuleView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    let geo: GeometryProxy
    
    var body: some View {
        let mod = viewModel.currentActiveModule
        if mod != nil {
            return AnyView(mod!.getView())
        } else {
            return AnyView(EmptyView())
        }
    }
}

struct CompositeHomeView: View{
    @EnvironmentObject var calVM: CALvm
    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @State var dragOffset: CGFloat = 0
    @State var toDoHeight: CGFloat = 0
    
    var body: some View {
        ZStack{
            CalendarComponentView(geo: geo)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { toDoHeight = geo.size.height * 0.3 }
            blurTransitionRect
                .frame(width: geo.size.width, height: geo.size.height * 0.1)
                .position(x: geo.size.width * 0.5, y: 0)
            ToDoComponentView(geo: geo, dragOffset: $dragOffset)
                .frame(maxWidth: .infinity, maxHeight: toDoHeight + dragOffset)
                .position(x: geo.size.width * 0.5, y: geo.size.height - ((toDoHeight + dragOffset)/2))
                .animation(.linear(duration: 0.15), value: toDoHeight)
            HomeViewBanner()
                .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.1)
                .position(x: geo.size.width * 0.5, y: geo.size.height * 0.05)
        }.task{
            toDoHeight = (geo.size.height * 0.3)
        }.onChange(of: viewModel.dragFinished){ val in
            if val {
                toDoHeight += dragOffset
                dragOffset = 0
                viewModel.dragFinished = false
            }
        }
    }
    
    @ViewBuilder
    var blurTransitionRect: some View{
        let gradient = LinearGradient(gradient: Gradient(stops: [.init(color: .clear, location: 0), .init(color: .white, location: 0.6)]), startPoint: .bottom, endPoint: .top)
        
        Rectangle()
            .foregroundColor(.white)
            .mask(gradient)
            .edgesIgnoringSafeArea(.top)
    }
}

struct HomeViewBanner: View {
    @EnvironmentObject var tdh: TimeDateHelper
    
    var body: some View {
        Capsule().fill(.white).shadow(radius: 5).overlay(
            HStack(spacing: 0){
                AppSelectButton()
                Spacer()
                Text(tdh.dateString(Date())).font(.largeTitle).foregroundColor(.black)
                Spacer()
                Image(systemName: "house").font(.title).foregroundColor(.black).padding(.horizontal)
            }
        )
    }
}

struct CalendarComponentView: View {
    @EnvironmentObject var tdh: TimeDateHelper
    @EnvironmentObject var calVM: CALvm
    let geo: GeometryProxy
    
    var body: some View {
        ScrollView{
            ScrollViewReader { scrollProxy in
                TimeOfDayView(geo: geo)
                    .onAppear{
                        let time: [Substring] = tdh.getTimeOfDayHrsMins(Date()).split(separator: ":")
                        var hour: Int = Int(time[0])!
                        hour = (hour == 12 && tdh.getAMPM(Date()) == "AM") ? 0 : hour
                        hour = (tdh.getAMPM(Date()) == "PM" && !tdh.is24hour()) ? hour+12: hour
                        hour = (hour > 2) ? hour-2 : hour
                        let currentTime: String = (hour < 10) ? ("0"+String(hour)) : String(hour)
//                        print("Scrolling to \(currentTime)")
                        scrollProxy.scrollTo((hour > 18) ? "18" : currentTime, anchor: .top)
                    }
            }
        }
    }
}

struct ToDoComponentView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var habVM: HABvm
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @Binding var dragOffset: CGFloat
    @State var toDo: Bool = true
    @State var tasks: [TDLm.Task] = []
    @State var habits: [HABm.Habit] = []
    @State var elementStateToggled: Bool = false
    
    var body: some View {
        VStack(spacing: 0){
            ToDoComponentViewHeader(geo: geo, dragOffset: $dragOffset, toDo: $toDo)
            if toDo{
                if tasks.count != 0{
                    tasksList
                } else {
                    emptyListPanel
                }
            } else {
                if habits.count != 0{
                    habitsList
                } else {
                    emptyListPanel
                }
            }
        }.task{
            var list = homeVM.getDailyPlan()
            list.0.append(contentsOf: homeVM.getCompletedPlanItems().0)
            list.1.append(contentsOf: homeVM.getCompletedPlanItems().1)
            (tasks, habits) = list
        }.onChange(of: elementStateToggled){val in
            if val{
                var list = homeVM.getDailyPlan()
                list.0.append(contentsOf: homeVM.getCompletedPlanItems().0)
                list.1.append(contentsOf: homeVM.getCompletedPlanItems().1)
                (tasks, habits) = list
                elementStateToggled = false
            }
        }
    }
    
    @ViewBuilder
    var tasksList: some View {
        ScrollView{
            ForEach(tasks, id: \.self) { element in
                ZStack{
                    RoundedRectangle(cornerRadius: 15).foregroundColor(.white)
                    HStack{
                        Button{
                            var task = element
                            task.toggleCompletion()
                            tdlVM.updateTask(task)
                            homeVM.togglePlanItemCompletion(element)
                            elementStateToggled = true
                        } label: {
                            Image(systemName: (element.getCompleted()) ? "checkmark.square" : "square")
                        }.padding()
                        Text(element.getName())
                            .padding()
                        Spacer()
                    }.frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .font(.title)
                }
                DividerLine(geo: geo).foregroundColor(.gray)
            }
        }.background(.white)
    }
    
    @ViewBuilder
    var habitsList: some View {
        ScrollView {
            ForEach(habits, id: \.self) { element in
                ZStack{
                    RoundedRectangle(cornerRadius: 15).foregroundColor(.white)
                    HStack{
                        Button{
                            var habit = element
                            habit.complete()
                            habVM.updateHabit(habit)
                            homeVM.togglePlanItemCompletion(element)
                            elementStateToggled = true
                        } label: {
                            Image(systemName: tdh.calendar.isDate(Date(), inSameDayAs:(element.getLastCompletion())) ? "checkmark.square" : "square")
                        }.padding()
                        Text(element.getName())
                            .padding()
                        Spacer()
                    }.frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .font(.title)
                }
                DividerLine(geo: geo).foregroundColor(.gray)
            }
        }.background(.white)
    }
    
    var emptyListPanel: some View {
        Rectangle().foregroundColor(.white).frame(maxWidth: .infinity).ignoresSafeArea(edges: [.bottom]).overlay{
            Text("No \(toDo ? "tasks" : "habits") in list").font(.title3).foregroundColor(.gray).padding()
        }
    }
}

struct ToDoComponentViewHeader: View {
    @EnvironmentObject var viewModel: HomeViewModel
    let geo: GeometryProxy
    @Binding var dragOffset: CGFloat
    @Binding var toDo: Bool
    
    var body: some View {
        ToDoHeaderTabBar(toDo: $toDo)
            .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.065)
            .background(.clear)
            .gesture(DragGesture(minimumDistance: 15, coordinateSpace: .global)
                .onChanged{ val in
                    dragOffset = 0 - (val.translation.height)
                }
                .onEnded{ _ in
                    viewModel.dragFinished = true
                }
            )
    }
}

struct ToDoHeaderTabBar: View {
    @Binding var toDo: Bool
    
    var body: some View {
        ZStack{
            TabBarShape()
                .fill(Color.white)
                .shadow(radius: 5)
            HStack{
                Spacer()
                Text("To Dos").foregroundColor(toDo ? .black : .gray).onTapGesture {if !toDo{ toDo = true }}
                Text("|")
                Text("Habits").padding(.trailing, 10).foregroundColor(toDo ? .gray : .black).onTapGesture {if toDo { toDo = false }}
            }.font(.title)
        }
    }
}

struct TabBarShape: Shape{
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.9))
        path.addLine(to: CGPoint(x: rect.maxX * 0.4, y: rect.maxY * 0.9))
        path.addCurve(to: CGPoint(x: rect.maxX * 0.5, y: rect.minY), control1:CGPoint(x: rect.maxX * 0.475, y: rect.maxY * 0.875),  control2:CGPoint(x: rect.maxX * 0.4875, y: rect.maxY * 0.13))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        return path
    }
    
    var body: some View {
        self.fill(.clear)
    }
}

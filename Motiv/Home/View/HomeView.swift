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
    
    var body: some View {
        GeometryReader{ geo in
            ZStack{
                if viewModel.currentActiveModule == nil {
                    CompositeHomeView(geo: geo)
                } else {
                    ModuleView()
                }
                let _ = print("x: \(geo.size.width), y: \(geo.size.height)")
                HomeNavBubble(x: geo.size.width + (buttonSize * 0.35) , y: geo.size.height * 0.6)
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
    
    var body: some View {
        let mod = viewModel.currentActiveModule
        if mod != nil {
            return AnyView(mod!.getView())
        } else {
            return AnyView(EmptyView())
        }
    }
}

//struct CompositeHomeView: View{
//    @EnvironmentObject var calVM: CALvm
//    @EnvironmentObject var tdlVM: TDLvm
//    @EnvironmentObject var viewModel: HomeViewModel
//    @EnvironmentObject var tdh: TimeDateHelper
//
//    var body: some View {
//        VStack(spacing: 0){
//            HomeViewBanner()
//            Divider()
//            GeometryReader{ geo in
//                VStack(spacing: 0){
//                    CalendarComponentView().frame(width: geo.size.width, height: geo.size.height * 0.7, alignment: .center)
//                    Divider()
//                    Divider()
//                    ToDoComponentView().frame(width: geo.size.width, height: geo.size.height * 0.3, alignment: .center)
//                }
//            }
//        }
//    }
//}

struct CompositeHomeView: View{
    @EnvironmentObject var calVM: CALvm
    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @State var toDoHeight: CGFloat = 0
    
    var body: some View {
        ZStack{
            CalendarComponentView().frame(maxWidth: .infinity, maxHeight: .infinity)
            blurTransitionRect
                .frame(width: geo.size.width, height: geo.size.height * 0.05)
                .position(x: geo.size.width * 0.5, y: geo.size.height * 0.25)
            ToDoComponentView(geo: geo, height: $toDoHeight)
                .frame(maxWidth: .infinity, maxHeight: toDoHeight)
                .position(x: geo.size.width * 0.5, y: geo.size.height - (toDoHeight/2))
            HomeViewBanner()
                .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.1)
                .position(x: geo.size.width * 0.5, y: geo.size.height * 0.05)
        }.task{
            toDoHeight = geo.size.height * 0.3
        }
    }
    
    @ViewBuilder
    var blurTransitionRect: some View{
        ZStack{
            Rectangle()
                .foregroundColor(.clear)
//            UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        }.edgesIgnoringSafeArea(.top)
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
    
    var body: some View {
        ScrollView{
            ScrollViewReader { scrollProxy in
                TimeOfDayView()
                    .onAppear{
                        let time: [Substring] = tdh.getTimeOfDayHrsMins(Date()).split(separator: ":")
                        var hour: Int = Int(time[0])!
                        hour = (hour == 12) ? hour-12 : hour
                        hour = (tdh.getAMPM(Date()) == "PM") ? hour+12: hour
                        hour = (hour > 2) ? hour-2 : hour
                        let currentTime: String = ((hour < 10) ? ("0"+String(hour)) : String(hour)) + ":00"
                        print("Scrolling to \(currentTime)")
                        scrollProxy.scrollTo((hour > 15) ? "15:00" : currentTime, anchor: .top)
                    }
            }
        }
    }
}

struct ToDoComponentView: View {
    @EnvironmentObject var tdh : TimeDateHelper
    @EnvironmentObject var tdlVM: TDLvm
    let geo: GeometryProxy
    @Binding var height: CGFloat

    var body: some View {
        VStack{
            ToDoComponentViewHeader()
            
            ScrollView {
                ForEach(tdlVM.getTodaysToDos(), id: \.self) { element in
                    ZStack{
                        RoundedRectangle(cornerRadius: 15).foregroundColor(.white)
                        HStack{
                            Button{
                                var task = element
                                task.toggleCompletion()
                                tdlVM.updateTask(task)
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
                    DividerLine().foregroundColor(.gray)
                }
            }
        }.background(.white)
    }
}

struct ToDoComponentViewHeader: View {
    
    var body: some View {
        HStack{
            Text("Todays To Dos:").font(.title).padding()
            Spacer()
        }.background(.gray).border(.black)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

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
                    CompositeHomeView()
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
        }.foregroundColor(.black)
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

struct CompositeHomeView: View{
    @EnvironmentObject var calVM: CALvm
//    @EnvironmentObject var tdlVM: TDLvm
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var tdh: TimeDateHelper
    
    var body: some View {
        VStack(spacing: 0){
            HomeViewBanner()
            Divider()
            GeometryReader{ geo in
                VStack(spacing: 0){
                    CalendarComponentView().frame(width: geo.size.width, height: geo.size.height * 0.55, alignment: .center)
                    Divider()
                    Divider()
//                    ToDoComponentView().frame(width: geo.size.width, height: geo.size.height * 0.45, alignment: .center)
                }
            }
        }
    }
}

struct HomeViewBanner: View {
    @EnvironmentObject var tdh: TimeDateHelper
    
    var body: some View {
        ZStack{
            HStack{
                AppSelectButton()
                Spacer()
                Image(systemName: "house").font(.title).foregroundColor(.black).padding(.horizontal)
            }
            Text(tdh.dateString(Date())).font(.largeTitle).padding()
        }
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
                        let currentTime : String = String(hour) + ":00"
                        scrollProxy.scrollTo(currentTime, anchor: .top)
                    }
            }
        }
    }
}

//struct ToDoComponentView: View {
//    @EnvironmentObject var tdh : TimeDateHelper
//    @EnvironmentObject var tdlVM: TDLvm
//
//    var body: some View {
//        VStack{
//            HStack{
//                Text("Todays To Dos:").font(.title).padding()
//                Spacer()
//            }.background(.gray).border(.black)
//            ScrollView {
//                ForEach(tdlVM.getTodaysToDos(), id: \.self) { element in
//                    TasksView(content: element)
//                    Divider()
//                }
//            }
//        }
//    }
//}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

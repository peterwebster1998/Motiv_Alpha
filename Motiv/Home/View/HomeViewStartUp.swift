//
//  HomeViewStartUp.swift
//  Motiv
//
//  Created by Peter Webster on 6/5/23.
//

import SwiftUI

struct ScheduleDailyPlanView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var calVM: CALvm
    @EnvironmentObject var habVM: HABvm
    @EnvironmentObject var tdh: TimeDateHelper
    let geo: GeometryProxy
    @State var plannedTime: Date = Date()
    @State var confirm: Bool = false
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.7)
            interractionPanel.frame(maxWidth: geo.size.width * 0.9, maxHeight: geo.size.height * 0.9)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            .alert(isPresented: $confirm){
                Alert(
                    title: Text("Confirm Time Selection"),
                    message: Text("This can always be updated at another time"),
                    primaryButton: .default(Text("Confirm"), action:{
                        let event = CALm.Event(startTime: plannedTime, durationMins: 15, eventName: "Plan", description: "Plan Tomorrows Event", repetition: .Daily)
                        var habit = habVM.getHabit("Plan")!
                        let eventSeries = CALm.EventSeries(event: event, habit: habit)
                        habit.linkToEventSeries(eventSeries.getID())
                        habVM.updateHabit(habit)
                        calVM.addEventSeries(eventSeries)
                    }),
                    secondaryButton: .cancel({
                        confirm = false
                    })
                )
                
            }
    }
    
    @ViewBuilder
    var interractionPanel: some View {
        RoundedRectangle(cornerRadius: 15).foregroundColor(.white).overlay(
            VStack{
                Group{ //Header
                    Text("Choose Daily Planning Time").font(.title).foregroundColor(.black).padding()
                    Text("Planning your days is a crucial component for personal success").foregroundColor(.black).opacity(0.75).padding(.horizontal)
                }
                Spacer()
                Group{ //Selection Panel
                    DividerLine(geo: geo, screenProportion: 0.825)
                    Text("Select when to plan everyday:").foregroundColor(.black).padding(.horizontal)
                    DatePicker("", selection: $plannedTime, displayedComponents: .hourAndMinute).datePickerStyle(WheelDatePickerStyle()).labelsHidden().padding().foregroundColor(.black)
                    DividerLine(geo: geo, screenProportion: 0.825)
                }
                Spacer()
                Text("Current selection: \(tdh.getTimeOfDayHrsMins(plannedTime)) \(tdh.getAMPM(plannedTime))").font(.title2).padding()
                Spacer()
                Button{
                    confirm = true
                } label: {
                    Capsule().stroke(.gray, lineWidth: 1.5).foregroundColor(.white).frame(maxWidth: geo.size.width * 0.5, maxHeight: geo.size.height * 0.1).padding().overlay(Text("Confirm Time").font(.title2).padding())
                }
            }.foregroundColor(.black)
        )
    }
}



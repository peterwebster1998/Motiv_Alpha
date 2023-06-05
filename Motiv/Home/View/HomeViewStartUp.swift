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
    @State var plannedTime: Date
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
                        let event = CALm.Event(dateKey: tdh.dateString(Date()), startTime: plannedTime, durationMins: 15, eventName: "Plan", description: "Plan Tomorrows Event", repetition: .Daily)
                        var habit = habVM.getHabit("Plan")!
                        let eventSeries = CALm.EventSeries(event: event, habit: habit)
                        habit.linkToEventSeries(eventSeries.getID())
                        habVM.updateHabit(habit)
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
                Text("Choose Daily Planning Time").font(.title).foregroundColor(.black).padding()
                Text("Planning your days are a crucial component for personal success").foregroundColor(.gray).padding(.horizontal)
                DatePicker("Select when to plan daily:", selection: $plannedTime, displayedComponents: .hourAndMinute)
                Text("Your selection: \(tdh.getTimeOfDayHrsMins(plannedTime))")
                Button{
                    confirm = true
                } label: {
                    Capsule().overlay(Text("Confirm Time"))
                }
            }
        )
    }
}



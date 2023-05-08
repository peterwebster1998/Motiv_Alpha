//
//  MotivApp.swift
//  Motiv
//
//  Created by Peter Webster on 4/24/23.
//

import SwiftUI

@main
struct MotivApp: App {

    @StateObject var HOMEviewModel: HomeViewModel = HomeViewModel()
    @StateObject var TDLviewModel: TDLvm = TDLvm()
    @StateObject var CALviewModel: CALvm = CALvm()
    @StateObject var HABviewModel: HABvm = HABvm()
    @StateObject var timeDateHelper: TimeDateHelper = TimeDateHelper()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(HOMEviewModel)
                .environmentObject(TDLviewModel)
                .environmentObject(CALviewModel)
                .environmentObject(HABviewModel)
                .environmentObject(timeDateHelper)
        }
    }
}

//
//  TimeDateHelper.swift
//  motiv-prerelease
//  --> moved to Motiv on 4/24/23
//
//  Created by Peter Webster on 10/27/22.
//

import Foundation

class TimeDateHelper: ObservableObject {
    
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    @Published private(set) var dateInView: Date
    private(set) var temporalHorizons: [Date]
    private(set) var temporalRange: [[Date]]
    @Published var scrollToToday: Bool
    @Published var isRefresh: Bool
    @Published var refreshed: Bool
    
    
    init() {
        dateInView = Date()
        scrollToToday = false
        isRefresh = true
        refreshed = false
        temporalHorizons = [
            calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date.distantPast,
            calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date.distantFuture
        ]
        print("Initial temporal horizons: \(temporalHorizons)")
        temporalRange = [[Date]]()
        //Manually create first range of values before class instantiation
        var idxDate = temporalHorizons[0]
        var month = [Date]()
        while idxDate <= temporalHorizons[1]{
            month.append(idxDate)
            idxDate += (60 * 60 * 24)
            if dayNoString(idxDate) == "01"{
                temporalRange.append(month)
                month = []
            }
        }
    }
    
    func today(){
        scrollToToday = true
//        isRefresh = true
        setDateInView(Date())
    }
    
    func getTimeOfDayHrsMins(_ date: Date) -> String {
        dateFormatter.dateFormat = "hh:mm"
        return dateFormatter.string(from: date)
    }
    
    func getAMPM(_ date: Date) -> String {
        dateFormatter.dateFormat = "a"
        return dateFormatter.string(from: date)
    }
    
    func monthYearStr(_ date: Date) -> String{
        dateFormatter.dateFormat = "LLL yyyy"
        return dateFormatter.string(from: date)
    }
    
    func dateString(_ date: Date) -> String{
        dateFormatter.dateFormat = "dd LLL yyyy"
        return dateFormatter.string(from: date)
    }
    
    func dayNoString(_ date: Date) -> String{
        let str = dateString(date)
        return String(str[..<str.index(str.startIndex, offsetBy: 2)])
    }
    
    func getTimeAsHrsFloat(_ time: Date) -> Float {
        let pm: Bool = (getAMPM(time) == "PM") ? true : false
        let hrMin = getTimeOfDayHrsMins(time).split(separator: ":")
        let hr = Float(hrMin[0])!
        let min = Float(hrMin[1].prefix(2))!
//        print("\thrMin: \(hrMin), hr: \(hr), min: \(min)")
        var out = hr + (min/60)
        out = pm ? out+12 : out
        if hr == 12 {
            out -= 12
        }
        return out
    }
    
    func weekdayFromDate(_ date: Date) -> String{
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
    }
    
    func monthStrFromDate(_ date: Date) -> String{
        dateFormatter.dateFormat = "LLLL"
        return dateFormatter.string(from: date)
    }
    
    func convertMinstoHrsMins(_ numMins: Int) -> String {
        let hrs = Int(numMins/60)
        let mins = numMins % 60
        return String(hrs) + ":" + ((mins == 0) ? "00" : String(mins))
    }
    
    func getFirstOfMonth(_ date: Date) -> Date {
        if date >= temporalHorizons[0] && date <= temporalHorizons[1]{
            let month = temporalRange.first(where:{monthYearStr($0[0]) == monthYearStr(date)})!
            return month[0]
        } else {
            print("First of month not available, returning input date")
            return date
        }
        
    }
    
    func setDateInView(_ day: Date){
        self.dateInView = day
        print("+++++++++\(day) is now in view")
//        if approachingTemporalHorizon() {
//            self.isRefresh = true
//            adjustTemporalRange()
//        }
    }
    
    func approachingTemporalHorizon() -> Bool {
        (dateInView < calendar.date(byAdding: .month, value: 6, to: temporalHorizons[0])!) || (dateInView > calendar.date(byAdding: .month, value: -6, to: temporalHorizons[1])!) || (dateInView < temporalHorizons[0]) || (dateInView > temporalHorizons[1]) ? true : false
    }
    
    func adjustTemporalRange() {
        print("Adjusting temporal range")
        if dateInView < temporalHorizons[0] || dateInView > temporalHorizons[1]{
            renewTemporalRange()
            print("\tRenewed Temporal Range: \(temporalHorizons)")
        } else if dateInView < calendar.date(byAdding: .month, value: 6, to: temporalHorizons[0])! {
            addSixMonthsPast()
            print("\tAdded 6 months past: \(temporalHorizons)")
        } else if dateInView > calendar.date(byAdding: .month, value: -6, to: temporalHorizons[1])!{
            addSixMonthsFuture()
            print("\tAdded 6 months future: \(temporalHorizons)")
        }
        
        if temporalRange.count >= 84 {
            if dateInView < calendar.date(byAdding: .month, value: 6, to: temporalHorizons[0])! {
                removeSixMonthsFuture()
                print("\tRemoved 6 months future: \(temporalHorizons)")

            } else if dateInView > calendar.date(byAdding: .month, value: -6, to: temporalHorizons[1])!{
                removeSixMonthsPast()
                print("\tRemoved 6 months past: \(temporalHorizons)")
            }
        }
    }
    
    func renewTemporalRange(){
        temporalHorizons = [
            calendar.date(byAdding: .year, value: -1, to: dateInView) ?? Date.distantPast,
            calendar.date(byAdding: .year, value: 1, to: dateInView) ?? Date.distantFuture
        ]
        temporalRange = [[]]
        var idxDate = temporalHorizons[0]
        var month = [Date]()
        while idxDate <= temporalHorizons[1]{
            month.append(idxDate)
            idxDate += (60 * 60 * 24)
            if dayNoString(idxDate) == "01"{
                temporalRange.append(month)
                month = []
            }
        }
    }
    
    func addMonthPast(){
        var idxDate = calendar.date(byAdding: .month, value: -1, to: temporalRange[0][0])!
//        idxDate += 60 * 60
        var month = [Date]()
        while idxDate < temporalRange[0][0] {
            month.append(idxDate)
            idxDate += 60 * 60 * 24
        }
        temporalRange.insert(month, at: 0)
        temporalHorizons[0] = temporalRange[0][0]
    }
    
    func addSixMonthsPast(){
        if dayNoString(temporalHorizons[0]) != "01" {
            temporalRange.removeFirst()
        }
        for _ in 1...6 {
            addMonthPast()
        }
    }
    
    func addMonthFuture(){
        var idxDate = calendar.date(byAdding: .month, value: 1, to: temporalRange.last![0])!
        var month = [Date]()
        let endDay = String(calendar.range(of: .day, in: .month, for: idxDate)!.upperBound - 1)
        while dayNoString(idxDate) != endDay {
            month.append(idxDate)
            idxDate += 60 * 60 * 24
        }
        month.append(idxDate)
        temporalRange.append(month)
        temporalHorizons[1] = temporalRange.last!.last!
    }
    
    func addSixMonthsFuture(){
        if dayNoString(temporalHorizons[1]) != String(calendar.range(of: .day, in: .month, for: temporalHorizons[1])!.upperBound) {
            temporalRange.removeLast()
        }
        for _ in 1...6 {
            addMonthFuture()
        }
    }
    
    func removeMonthPast(){
        temporalRange.removeFirst()
        temporalHorizons[0] = temporalRange[0][0]
    }
    
    func removeSixMonthsPast(){
        for _ in 1...6 {
            removeMonthPast()
        }
    }
    
    func removeMonthFuture(){
        temporalRange.removeLast()
        temporalHorizons[1] = temporalRange.last!.last!
    }
    
    func removeSixMonthsFuture(){
        for _ in 1...6 {
            removeMonthFuture()
        }
    }
}

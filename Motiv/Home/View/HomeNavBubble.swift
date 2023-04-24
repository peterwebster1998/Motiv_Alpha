//
//  HomeNavBubble.swift
//  motiv-prerelease
//  --> moved to Motiv on 4/24/23
//
//  Created by Peter Webster on 4/13/23.
//

import SwiftUI

internal let buttonSize: CGFloat = 70

struct HomeNavBubble: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @State var x: CGFloat
    @State var y: CGFloat
    @State var dragOffset: CGSize = .zero
    @State var inDrag: Bool = false
    @State var moduleSelection: HomeModel.Module?
    
    var body: some View {
        ZStack{
            if inDrag {
                SurroundingNavView(dragOffset: $dragOffset, moduleSelection: $moduleSelection)
            }
            CentralButton()
                .frame(width: buttonSize)
//                .animation(Animation.spring(), value: dragOffset)
        }
        .position(x: x + dragOffset.width, y: y + dragOffset.height)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged{ value in
                    dragOffset = value.translation
                    if dragOffset.magnitude > 100{
                        inDrag = true
                    }
                }
                .onEnded{ _ in
                    inDrag = false
                    dragOffset = .zero
                    if moduleSelection != nil {
                        viewModel.currentActiveModule = moduleSelection
                        moduleSelection = nil
                    }
                }
        )
    }
}

struct CentralButton: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        Circle()
            .shadow(radius: 5)
            .overlay(Image(systemName: "house")
                .foregroundColor(.black)
                .font(.title)
            ).foregroundColor(.white)
            .onTapGesture {
                viewModel.currentActiveModule = nil
            }
            
    }

}

extension CGSize {
    var magnitude: CGFloat {
        return CGFloat(sqrt(pow(width, 2) + pow(height, 2)))
    }
    
    var inverse: CGSize {
        return CGSize(width: 0-width, height: 0-height)
    }
    
    static func - (_ a: CGSize, _ b: CGSize) -> CGSize {
        return CGSize(width: a.width - b.width, height: a.height - b.height)
    }
    
    static func + (_ a: CGSize, _ b: CGSize) -> CGSize {
        return CGSize(width: a.width + b.width, height: a.height + b.height)
    }
}

struct SurroundingNavView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var dragOffset: CGSize
    @Binding var moduleSelection: HomeModel.Module?
    let size = buttonSize * 3.5
    @State var lastOffset: CGSize = .zero
    @State var lastDeltaOffset: CGSize = .zero
    @State var deltaOffset: CGSize = .zero
    @State var deltaDeltaOffset: CGSize = .zero
    @State var holdOffsetValue: CGSize = .zero
    @State var makingNavSelection: Bool = false
    @State var dragIterations: Int = 0

    var body: some View {
        ZStack{
            Donut(holeSize: buttonSize * 1.2)
                .foregroundColor(.gray)
                .blur(radius: buttonSize * 0.1)
                .opacity(0.65)
            DonutNavTiles(holeSize: buttonSize * 1.2, dragOffset: $dragOffset, holdOffset: $holdOffsetValue, makingNavSelection: $makingNavSelection, moduleSelection: $moduleSelection)
        }.frame(width: size, height: size)
            .offset((makingNavSelection) ? (holdOffsetValue - dragOffset): .zero)
            .onChange(of: dragOffset){value in
                    deltaOffset = value - lastOffset
                    deltaDeltaOffset = lastDeltaOffset - deltaOffset
                    print("deltaOffset: \(deltaOffset.magnitude)")
                    print("deltadeltaOffset: \(deltaDeltaOffset.magnitude)")
                if dragIterations > 5{
                    if deltaDeltaOffset.magnitude > 5 && !makingNavSelection{
                        makingNavSelection = true
                        holdOffsetValue = dragOffset
                        print("NavSelection True!!\n============================")
                        
                    }
                }
                lastOffset = value
                lastDeltaOffset = deltaOffset
                dragIterations += 1
            }
    }
}

struct Donut: Shape {
    var holeSize: CGFloat
    
        func path(in rect: CGRect) -> Path {
            let outerRadius = min(rect.width, rect.height) / 2
            let innerRadius = holeSize / 2
            let center = CGPoint(x: rect.midX, y: rect.midY)
            
            var path = Path()
            path.addArc(center: center, radius: outerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
            path.addArc(center: center, radius: innerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
            path.closeSubpath()
            
            return path
        }
}

struct DonutNavTiles: View {
    @EnvironmentObject var viewModel: HomeViewModel
    let holeSize: CGFloat
    @Binding var dragOffset: CGSize
    @Binding var holdOffset: CGSize
    @Binding var makingNavSelection: Bool
    @Binding var moduleSelection: HomeModel.Module?
    @State var noSegments: Int = 0
    @State var appShortcuts: [HomeModel.Module] = []

    var body: some View {
        GeometryReader{ geo in
            ForEach(appShortcuts, id: \.self){ app in
                let idx = appShortcuts.firstIndex(of: app)!
                DonutSegment(holeSize: holeSize, noSegments: noSegments, idx: idx)
                    .foregroundColor(.clear)
                    .overlay(
                        ZStack{
                            let offset: CGSize = dragOffset - holdOffset
                            if offset.magnitude > holeSize/2{
                                let segIdx = calculateSegIdx(offset: offset)
                                if makingNavSelection && segIdx == idx {
                                    DonutSegment(holeSize: holeSize * 1.05, noSegments: noSegments, idx: idx)
                                        .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.95, alignment: .center)
                                        .position(x: geo.size.width/2, y: geo.size.height/2)
                                        .foregroundColor(.white)
                                        .onAppear{
                                            moduleSelection = app
                                        }
                                }
                            }
                            Image(systemName: app.getAppImage())
                                .foregroundColor(.black)
                                .position(getSegmentCenter(geo: geo, idx: idx))
                        }
                        
                    )
            }
        }.onAppear{
            appShortcuts = viewModel.getNavBubbleApps()
            noSegments = appShortcuts.count
        }
    }
    
    
    
    func getSegmentCenter(geo: GeometryProxy, idx: Int) -> CGPoint {
        let innerRadius = holeSize/2
        let outerRadius = min(geo.size.width, geo.size.height)/2
        let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
        let offsetAngle: Angle = .degrees(180)
        let segmentAngle: Angle = .degrees(Double(360/noSegments))
        let startAngle: Angle = offsetAngle + (segmentAngle * Double(idx))
        let endAngle: Angle = offsetAngle + (segmentAngle * Double(idx+1))
        
        let centerRadius = innerRadius + ((outerRadius - innerRadius)/2)
        let centerAngle = startAngle + ((endAngle - startAngle)/2)
        let centerHoriz = cos(centerAngle.radians)
        let centerVert = sin(centerAngle.radians)
        let segmentCenter = CGPoint(x: center.x + (centerRadius*centerHoriz), y: center.y + (centerRadius*centerVert))
        return segmentCenter
        
    }
    
    func calculateSegIdx(offset: CGSize) -> Int {
//        print("=======================================")
//        print("offset: \(offset)")
        var direction: Angle = Angle.radians(atan(Double(offset.height/offset.width)))
        if offset.width < 0 {
            direction = .radians(direction.radians + .pi)
        }
        direction = .radians(direction.radians.truncatingRemainder(dividingBy: 2 * .pi))
        var proportionRotated: Double = direction.radians / (2 * .pi)
        proportionRotated = (proportionRotated < 0) ? 1.0+proportionRotated : proportionRotated
        var segIdx: Double = (proportionRotated * Double(noSegments)) - Double((noSegments/2))
        segIdx = (segIdx < 0) ? Double(noSegments) + segIdx : segIdx
//        print("direction: \(direction.radians), proportionRotated: \(proportionRotated)")
//        print("segIdx: \(segIdx)")
//        print("+++++++++++++++++++++++++++++++++++++++")
        return Int(segIdx)
    }
}

struct DonutSegment: Shape {
    var holeSize: CGFloat
    var noSegments: Int
    var idx: Int
        
    func path(in rect: CGRect) -> Path {
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = holeSize / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let offsetAngle: Angle = .degrees(180)
        let segmentAngle: Angle = .degrees(Double(360/noSegments))
        let startAngle: Angle = offsetAngle + (segmentAngle * Double(idx)) + .degrees(1)
        let endAngle: Angle = offsetAngle + (segmentAngle * Double(idx+1)) - .degrees(1)
        
        let outerResult = getStartAndEndFromCurve(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle)
        let outerCurveStart: CGPoint = outerResult.0
        let outerCurveEnd: CGPoint = outerResult.1
        let innerResult = getStartAndEndFromCurve(center: center, radius: innerRadius, startAngle: startAngle, endAngle: endAngle)
        let innerCurveStart: CGPoint = innerResult.0
        let innerCurveEnd: CGPoint = innerResult.1
       
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.move(to: outerCurveStart)
        path.addLine(to: innerCurveStart)
        path.move(to: outerCurveEnd)
        path.addLine(to: innerCurveEnd)
        path.closeSubpath()
    
        return path
    }
    
    func getStartAndEndFromCurve(center: CGPoint, radius: CGFloat, startAngle: Angle, endAngle: Angle) -> (CGPoint, CGPoint){
        var start: CGPoint, end: CGPoint = .zero
        
        let startHoriz = cos(startAngle.radians)
        let startVert = sin(startAngle.radians)
        start = CGPoint(x: center.x + (radius*startHoriz), y: center.y + (radius*startVert))
        
        let endHoriz = cos(endAngle.radians)
        let endVert = sin(endAngle.radians)
        end = CGPoint(x: center.x + (radius*endHoriz), y: center.y + (radius*endVert))

        return (start, end)
    }
    
}

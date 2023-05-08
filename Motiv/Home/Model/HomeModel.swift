/*
  HomeModel.swift
  Motiv

  Created by Peter Webster on 4/25/23.

 //
 //  HomeModel.swift
 //  motiv-prerelease
 //
 //  Created by Peter Webster on 4/11/23.
 //
*/

import Foundation
import SwiftUI

struct HomeModel : Codable{
    private var apps: [Module]
    private var navBubbleAppShortcuts: [Module]
    
    // MARK: - Persistence
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(HomeModel.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try HomeModel(json: data)
    }
    
    //MARK: - HomeModel Methods
    init(){
        self.apps = []
        apps.append(Module(name: "ToDo's", appImage: "checklist", view: AnyView(TDLv())))
        apps.append(Module(name: "Calendar", appImage: "calendar", view: AnyView(CALv())))
        apps.append(Module(name: "Habits", appImage: "person.fill.checkmark", view: AnyView(HABv())))
        apps.append(Module(name: "FlashCards", appImage: "rectangle.stack", view: AnyView(FLCv())))
        self.navBubbleAppShortcuts = apps
        apps.append(Module(name: "Recipe Box", appImage: "list.bullet.rectangle", view: AnyView(RBXv())))
    }
    
    func getApps() -> [Module]{
        return apps
    }
    
    mutating func addModule(_ new: Module){
        apps.append(new)
    }
    
    func getNavBubbleApps() -> [Module]{
        return navBubbleAppShortcuts
    }
    
    struct Module : View, Hashable, Codable{
        
        private let name: String
        private let appImage: String
        private let viewStruct: AnyView
        
        init(name: String, appImage: String, view: AnyView){
            self.name = name
            self.appImage = appImage
            self.viewStruct = view
        }
        
        var body: some View {
            return viewStruct
        }
        
        func getName() -> String{
            return name
        }
        
        func getAppImage() -> String{
            return appImage
        }
        
        func getView() -> AnyView{
            return viewStruct
        }
        
        static func == (lhs: HomeModel.Module, rhs: HomeModel.Module) -> Bool {
            return (lhs.name == rhs.name) && (lhs.appImage == rhs.appImage) && (type(of: rhs.viewStruct) == type(of: lhs.viewStruct))
        }
        
        func hash(into hasher: inout Hasher){
            hasher.combine(name)
            hasher.combine(appImage)
            hasher.combine(ObjectIdentifier(type(of: viewStruct)))
        }
        
        //Mark: - Persistence
        enum CodingKeys: CodingKey {
            case name, appImage, viewStruct
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(appImage, forKey: .appImage)
            let data = try NSKeyedArchiver.archivedData(withRootObject: viewStruct, requiringSecureCoding: false)
            try container.encode(data, forKey: .viewStruct)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            appImage = try container.decode(String.self, forKey: .appImage)
            let data = try container.decode(Data.self, forKey: .viewStruct)
            guard let view = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? AnyView else {
                throw DecodingError.dataCorruptedError(forKey: .viewStruct, in: container, debugDescription: "View data is corrupted")
            }
            viewStruct = view
        }
    }
}

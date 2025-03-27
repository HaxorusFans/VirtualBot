//
//  CoreType.swift
//  VirtualBot
//  Created by ZXL on 2025/2/21
        

import Foundation
import SwiftCSV

// 根据参数创建枚举实例
func defineACore(type: String) -> CoreType {
    switch type {
    case "SerialPort":
        return .SerialPort
    case "MIX_RPC":
        return .MIX_RPC
    default:
        fatalError("Unknown core type")
    }
}


enum SingletonVBotFactory {
    case VBotFactory
    static private(set) var VBotArmyRepo:[VBotArmy] = []
    
    func newEmptyArmy(id:UUID) {
        var army = VBotArmy(id: id)
        SingletonVBotFactory.VBotArmyRepo.append(army)
    }
    
    // ARO (after receipt of order)
    func ARO(id:UUID, order:String, strongOrder:Bool) {
        do {
            let csvFile: CSV = try CSV<Named>(url: URL(fileURLWithPath: order))
            var categorySet:Set<String> = []
            // Access rows
            for row in csvFile.rows {
                if let category = row["category"] {
                    categorySet.insert(category)
                }
            }
            
            if let index = SingletonVBotFactory.VBotArmyRepo.firstIndex(where: { army in
                army.id == id
            }){
                SingletonVBotFactory.VBotArmyRepo[index].addVBots(order: order, types: categorySet, strongOrder: strongOrder)
            }
            
        } catch {
            print("Error loading CSV file: \(error)")
        }
    }
    
    func changeOrderMode(id:UUID, strongOrder:Bool){
        if let index = SingletonVBotFactory.VBotArmyRepo.firstIndex(where: { VBArmy in
            VBArmy.id == id
        }){
            SingletonVBotFactory.VBotArmyRepo[index].changeOrderMode(strongOrder: strongOrder)
        }
    }
    
    func killArmy(id:UUID){
        if let index = SingletonVBotFactory.VBotArmyRepo.firstIndex(where: { army in
            army.id == id
        }){
            SingletonVBotFactory.VBotArmyRepo[index].terminate()
            SingletonVBotFactory.VBotArmyRepo.remove(at: index)
        }
    }
}

struct VBotArmy:Identifiable{
    var id: UUID
    var name: String = "new case"
    var army: [VBot] = []
    
    mutating func addVBots(order:String, types:Set<String>, strongOrder:Bool){
        for type in types {
            let coreType: CoreType = defineACore(type: type)
            let bot = coreType.Bot
            bot.stratWithCase(newCasePath: order, strongOrder: strongOrder)
            self.army.append(bot)
        }
    }
    
    mutating func rename(name:String){
        self.name = name
    }
    
    mutating func changeOrderMode(strongOrder:Bool){
        for vbot in army {
            vbot.VBcase?.strongOrder = strongOrder
        }
    }
    
    mutating func terminate(){
        for vbot in army {
            vbot.core.terminate()
        }
        army.removeAll()
    }
}


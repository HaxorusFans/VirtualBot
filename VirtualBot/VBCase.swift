//
//  VBCase.swift
//  VirtualBot
//  Created by ZXL on 2025/1/17
        

import Foundation
import SwiftCSV



class VBCase{
    
    var anchorDelegate:UpdateVBotAnchor?
    
    var coreType:CoreType
    
    //MARK: - cmdSet
    
    private var _cmdSet:[String:[Int:TwoStepsResponse]] = ["@defaultCmd":[0: TwoStepsResponse(responseBody: "No valid command is loaded!", responseDelimiter: "")]]
    func cmdSet() -> [String:[Int:TwoStepsResponse]]{
        _cmdSet
    }
    
    
    //MARK: - cmdArr
    
    private var _cmdArr:[String] = []
    func cmdArr() -> [String]{
        _cmdArr
    }
    
    
    //MARK: - anchor
    private var _schedule:Int
    private(set) var anchor:Int = 0
    func schedule()-> Int{
        _schedule
    }
    
    func resetAnchor(){
        anchor = 0
        self.anchorDelegate?.updateAnchor(anchor: anchor)
    }
    
    
    
    //MARK: - delimiter
    private var delimiter = ""
    
    //MARK: - delimiter
    private var csvFile: CSV<Named>?
    
   
    //MARK: - Order Mode
    //StrongOrder :Bool
    //true_1  -> 当case的时间点未达到（达到：即等于或大于）某个命令最早出现的时间点，将会返回报错信息
    //true_2  -> 当未按照case顺序接收指令，将会返回报错信息
    //false -> 当case的时间点未达到（达到：即等于或大于）某个命令最早出现的时间点，将会返回该命令在其第一个时间点返回的内容
    var strongOrder:Bool
    let name:String?
    
    init(casePath: String, coreType: CoreType, strongOrder: Bool) {
        self.coreType = coreType
        let url = URL(fileURLWithPath: casePath)
        name = url.lastPathComponent
        self.strongOrder = strongOrder
        do {
           
            let _csvFile: CSV = try CSV<Named>(url: url)
            
            // Access rows
            var i:Int = 0
            for row in _csvFile.rows {
                if let type = row["category"], type == self.coreType.type {
                    if let _ = _cmdSet[row["command"]!] {
                        _cmdSet[row["command"]!]![i] = TwoStepsResponse(responseBody: row["response"]!, responseDelimiter: row["delimiter"] ?? "")
                    }else{
                        _cmdSet[row["command"]!] = [i: TwoStepsResponse(responseBody: row["response"]!, responseDelimiter: row["delimiter"] ?? "")]
                        _cmdSet[row["command"]!]![-1] = TwoStepsResponse(responseBody: "Sending this instruction is not in case order.", responseDelimiter: "")
                    }
                    _cmdArr.append(row["command"]!)
                    i += 1
                }
            }
            _schedule = _cmdArr.count-1
            csvFile = _csvFile
        } catch {
            _schedule = 0
            print("Error loading CSV file: \(error)")
        }
    }
    
    func echoResponse(cmd: String) -> String{
        if cmd == "" {
            return self.delimiter
        }
        
        if cmd.hasPrefix("echo ") {
            return echoUUIDResp(rawStr: cmd)
        }
        
        let cmds = Array(_cmdSet.keys)
        if !cmds.contains(cmd) {
            return _cmdSet["@defaultCmd"]![0]!.echoMe(onlyBody: true)
        }
        
        // 当前cmd出现在schedule中的所有位置
        var indexs:[Int] = Array(_cmdSet[cmd]!.keys)
        // 如果anchor命中indexs中的某个位置，直接返回该位置的内容
        if indexs.contains(anchor){
            self.delimiter = _cmdSet[cmd]![anchor]!.responseDelimiter
            let resp = _cmdSet[cmd]![anchor]!.echoMe()
            anchor += 1
            self.anchorDelegate?.updateAnchor(anchor: anchor)
            return resp
        }
        
        // 如果anchor未命中indexs中的任何位置，将anchor加入indexs并从小到大排序，然后选择anchor左边第一个位置作为命中位置
        // 注意，每个指令都有一个-1，而anchor最小为0，所以anchor最小只能在数组中的第二个位置，即index == 1
        // 如果anchor是左边第二个位置，且strongOrder == false，则选择anchor右边第一个位置作为命中位置
        
        // e.g.: -1, anchor, x, y, z
        indexs.append(anchor)
        indexs.sort()
        
        let hitPoint = indexs.firstIndex(of: anchor)
        if strongOrder {
//            if hitPoint == 1 {
//                return _cmdSet[cmd]![-1]!.echoMe(onlyBody: true)
//            }else{
//                self.delimiter = _cmdSet[cmd]![indexs[hitPoint! - 1]]!.responseDelimiter
//                return _cmdSet[cmd]![indexs[hitPoint! - 1]]!.echoMe()
//            }
            return _cmdSet[cmd]![-1]!.echoMe(onlyBody: true)
        }else{
            if hitPoint == 1 {
                self.delimiter = _cmdSet[cmd]![indexs[hitPoint! + 1]]!.responseDelimiter
                return _cmdSet[cmd]![indexs[hitPoint! + 1]]!.echoMe()
            }else{
                self.delimiter = _cmdSet[cmd]![indexs[hitPoint! - 1]]!.responseDelimiter
                return _cmdSet[cmd]![indexs[hitPoint! - 1]]!.echoMe()
            }
        }
        // return "[class: VBCase] [func: echoResponse] - Unknown error occurred!"
    }
    
}



struct TwoStepsResponse {
    var responseBody: String
    var responseDelimiter: String
    func echoMe(onlyBody: Bool = false) -> String {
        if onlyBody || responseDelimiter == ""{
            return  "\(self.responseBody)"
        }
        return "\(self.responseBody)\r\n\(self.responseDelimiter)"
    }
}


func echoUUIDResp (rawStr: String) -> String {
    let rang = NSRange(rawStr.startIndex... , in: rawStr)
    let recordRegex = try? NSRegularExpression(pattern: #"(?<=echo ).*"#, options: [])
    guard let echoUUID_R = recordRegex?.firstMatch(in: rawStr, range: rang) else {
        return "Error echo, unknown reason"
    }
    
    let echoUUID = Range(echoUUID_R.range, in: rawStr)!
    return "\(String(rawStr[echoUUID]))\r\n] :-) "
}

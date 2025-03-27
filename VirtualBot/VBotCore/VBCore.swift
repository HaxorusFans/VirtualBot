//
//  CoreDelegate.swift
//  VirtualBot
//  Created by ZXL on 2025/1/9
        

import Foundation



struct Message:Identifiable {
    var id = UUID()
    //ceil(n/2)
    let turn:Int
    let text:String
    let date:String
    let botFlag: Bool
}

class VBCore {
    private(set) var VBcase: VBCase?
    private(set) var _coreName: String = "uninitialized"
    private(set) var _displayCoreName: String = "uninitialized"
    private(set) var _session: [Message] = []
    private(set) var _coreType:CoreType
    var sessionDelegate:UpdateVBotSession?
    let dateFormatter = DateFormatter()
    
    
    func setCoreName(displayPrefix:String, name: String){
        _coreName = name
        _displayCoreName = "\(displayPrefix): \(name)"
    }
    
    func displayCoreName() -> String {
        return _displayCoreName
    }
    
    func coreName() -> String {
        return _coreName
    }
    
    func initVBCase(newCase: VBCase) {
        VBcase = newCase
    }
    
    func appendSession(message: Message){
        _session.append(message)
        self.sessionDelegate?.updateSession(session: _session)
    }
    
    func cleanSession() {
        _session.removeAll()
        self.sessionDelegate?.updateSession(session: _session)
    }
    
    func matchCase(command: String?) -> String? {
        
        guard command != nil else {
            return "Command is nil"
        }
        
        guard VBcase != nil else {
            return "Case is not initialized"
        }
        
        let command = (command?.trimmingCharacters(in: .whitespacesAndNewlines))!
        
        return VBcase!.echoResponse(cmd: command)
    }
    
    func checkReady() -> Bool{
        if let _ = self.VBcase{
            return true
        }
        return false
    }
    
    func begin() {
    }
    
    func terminate() {
    }
    
    init(coreType: CoreType) {
        _coreType = coreType
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    }
}


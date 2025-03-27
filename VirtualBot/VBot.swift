//
//  VBot.swift
//  VirtualBot
//  Created by ZXL on 2025/1/17
        

import Foundation

protocol UpdateVBotSession {
    func updateSession(session:[Message])
}

protocol UpdateVBotAnchor {
    func updateAnchor(anchor:Int)
}

class VBot: UpdateVBotSession, UpdateVBotAnchor, ObservableObject, Identifiable{
    
    
    
    //MARK: - VBot core
    
    let core: VBCore
    var displayVBotName: String {
        get {
            core.displayCoreName()
        }
    }
    var VBotName: String {
        get {
            core.coreName()
        }
    }
   
    
    
    //MARK: - VBot VBCase
    @Published var VBcase: VBCase?
    @Published var anchor:Int?
    func loadNewCase(newCasePath:String, strongOrder:Bool) {
        VBcase = VBCase(casePath: newCasePath, coreType: core._coreType, strongOrder: strongOrder)
        self.core.initVBCase(newCase: VBcase!)
        anchor = VBcase!.anchor
    }
    var VBcmdset: [String:[Int:TwoStepsResponse]] {
        get {
            VBcase?.cmdSet() ?? [:]
        }
    }
    var VBcmdarr: [String] {
        get {
            VBcase?.cmdArr() ?? []
        }
    }
    
    func stratWithCase(newCasePath: String, strongOrder:Bool){
        self.loadNewCase(newCasePath: newCasePath, strongOrder: strongOrder)
        self.VBcase!.anchorDelegate = self
        self.core.begin()
    }
    
    func updateAnchor(anchor: Int) {
        self.anchor = anchor
    }
    
    func resetSession(){
        self.VBcase?.resetAnchor()
    }
    
    
    //MARK: - VBot session (a part of VBCore)
    @Published var session: [Message] = []
    func updateSession(session: [Message]) {
        DispatchQueue.main.async {
            self.session = session
        }
    }
    
    
    func cleanSession(){
        DispatchQueue.main.async {
            self.core.cleanSession()
        }
    }
    
    func autoPlay(){
        let schedule = VBcase!.schedule()
        while anchor! <= schedule {
            let turn = Int(ceil(Double(self.session.count/2)))
            let cmd = self.VBcase!.cmdArr()[anchor!]
            let resp = self.VBcase!.echoResponse(cmd: cmd)
            
            DispatchQueue.main.async {
                self.core.appendSession(message: Message(turn: turn, text: cmd, date: self.core.dateFormatter.string(from: Date()), botFlag: false))
                
                self.core.appendSession(message: Message(turn: turn, text: resp, date: self.core.dateFormatter.string(from: Date()), botFlag: true))
            }
        }
    }
    
    func autoPlay1(cmd:String){
        let turn = Int(ceil(Double(self.session.count/2)))
        let resp = self.VBcase!.echoResponse(cmd: cmd)
        DispatchQueue.main.async {
            self.core.appendSession(message: Message(turn: turn, text: cmd, date: self.core.dateFormatter.string(from: Date()), botFlag: false))
            self.core.appendSession(message: Message(turn: turn, text: resp, date: self.core.dateFormatter.string(from: Date()), botFlag: true))
        }
    }
    
    
    
    
    //MARK: - init
    init(core: VBCore) {
        self.core = core
        core.sessionDelegate = self
    }
}

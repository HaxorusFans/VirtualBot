//
//  CoreType.swift
//  VirtualBot
//  Created by ZXL on 2025/2/24
        

import Foundation

enum CoreType {
    case SerialPort
    case MIX_RPC
    
    var type: String{
        switch self {
            case .MIX_RPC:
                "MIX_RPC"
            case .SerialPort:
                "SerialPort"
        }
    }
    
    var Bot: VBot{
        switch self {
            case .MIX_RPC:
                VBot(core: SerialPortCore())
            case .SerialPort:
                VBot(core: MIX_RPCCore())
        }
    }
}

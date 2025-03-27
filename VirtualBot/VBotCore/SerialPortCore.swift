//
//  SerialPortCore.swift
//  VirtualBot
//
//  Created by ZXL on 2024/10/24.
//

import Foundation

class SerialPortCore:VBCore {
    private var parentDescriptor: Int32 = 0
    private var childDescriptor: Int32 = 0
    private var parentHandle: FileHandle?
    private var childHandle: FileHandle?
    private var full_buffer: Data = Data()
    private var buffer: String = ""
    var vbCase: VBCase?
    
    init() {
        super.init(coreType: .SerialPort)
        parentDescriptor = 0
        childDescriptor = 0
        guard Darwin.openpty(&parentDescriptor, &childDescriptor, nil, nil, nil) != -1 else {
            fatalError("Failed to spawn PTY")
        }
        
        // 获取从设备名称
        if let slaveName = ptsname(parentDescriptor) {
            //self.setCoreName(name: "SerialPort: \(String(cString: slaveName))")
            self.setCoreName(displayPrefix: "SerialPort", name: String(cString: slaveName))
            print("PTY Slave Name: \(_coreName)")
        } else {
            perror("ptsname")
        }
        
        parentHandle = FileHandle(fileDescriptor: parentDescriptor, closeOnDealloc: true)
        childHandle = FileHandle(fileDescriptor: childDescriptor, closeOnDealloc: true)
    }
    
    override func begin() {
        readOutput()
    }
    
    
    func sendCommand(_ command: String) {
        if let data = (command + "\r").data(using: .utf8) {
            childHandle?.write(data) // 发送命令到子进程
        }
    }
    
    func readOutput() {
        parentHandle?.readabilityHandler = { handle in
            let outputData = handle.availableData
            if outputData.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            self.parentHandle?.write(outputData)  // 回显
            var str = String(data: outputData, encoding: .utf8) ?? ""
            str = str.replacingOccurrences(of: "\n", with: "\r")
            self.buffer.append(str)
            // 检查缓冲区中是否有完整的输出
            while let newlineIndex = self.buffer.range(of: "\r")?.upperBound {
                self.parentHandle?.write("\r\n".data(using: .utf8)!)  // 回显
                var completeOutput = String(self.buffer.prefix(upTo: newlineIndex))
                self.buffer.removeSubrange(..<newlineIndex)
                print("Output: \(completeOutput)")
                completeOutput = completeOutput.trimmingCharacters(in: .newlines)
                self.appendSession(message: Message(turn: Int(ceil(Double(self._session.count/2))), text: completeOutput, date: self.dateFormatter.string(from: Date()), botFlag: false))
                self.sessionDelegate?.updateSession(session: self._session)
                if let matchedOutput = self.matchCase(command: completeOutput) {
                    print("Output: \(matchedOutput)")
                    self.appendSession(message: Message(turn: Int(ceil(Double(self._session.count/2))), text: matchedOutput, date: self.dateFormatter.string(from: Date()), botFlag: true))
                    self.sessionDelegate?.updateSession(session: self._session)
                    let matchedOutput_data = matchedOutput.data(using: .utf8)!
                    self.parentHandle?.write(matchedOutput_data)  // 回显
//                    self.parentHandle?.write("] :-) \r\n".data(using: .utf8)!)  // 回显
                    self.parentHandle?.write("\r\n".data(using: .utf8)!)  // 回显
                }
            }
        }
    }
    
    
    
    override func terminate() {
        parentHandle?.readabilityHandler = nil
        close(parentDescriptor)
        close(childDescriptor)
    }
}

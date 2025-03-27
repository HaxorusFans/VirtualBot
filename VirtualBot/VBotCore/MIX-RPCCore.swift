//
//  MIX-RPCCore.swift
//  VirtualBot
//  Created by ZXL on 2025/1/9
        

import Foundation
import Network

//从服务器协议，当从服务器出现新的连接，调用代理方实现的方法维护客户端ID与从客户端NWConnection的对应关系
protocol MIX_RPCSlaveDelegate{
    // 建立客户端ID与从客户端NWConnection的对应关系
    func buildSlaveConnectionsDirt(identity: String, connection: NWConnection)
}



//主服务器协议，当主服务器编辑好返回的消息，调用代理方实现的方法将消息返回
protocol MIX_RPCMasterDelegate{
    // 建立主客户端Socket与客户端ID的对应关系
    func buildMasterConnectionsDirt(endpoint: String, identity: String)
    
    // 通过主客户端connection中的Endpoint匹配对应的客户端connection, 并发送响应
    func respondToClient(connectionEndpoint:String, reponse: Data)
    
    // 移除主客户端Socket与客户端ID的对应关系
    func removeConnectionRecord(connectionEndpoint: String)
    
    // 匹配command的response
    func getResult(command: String) -> String
    
    // 添加对话
    func addNewSession(message: String, botFlag: Bool)
}



class MIX_RPCCore:VBCore, MIX_RPCMasterDelegate, MIX_RPCSlaveDelegate {
    
    var masterServer:VBTCPServer?
    var slaveServer:VBTCPServer?
    
    //Identity:一对 主/从服务器 的Identity是相同的
    
    // e.g.  endpoint : (第三次握手收到的的)Identity
    var masterConnectionDict:[String:String] = [:]
    // e.g.  (第三次握手收到的的)Identity: connection
    var slaveConnectionDict:[String:NWConnection] = [:]
    
    init() {
        // 使用函数查找端口对
        super.init(coreType: .MIX_RPC)
        if let (port1, port2) = findAvailablePortPair() {
            print("找到可用端口对: \(port1) 和 \(port2)")
            self.masterServer = VBTCPServer(port: port1)
            self.slaveServer = VBTCPServer(port: port2)
            self.masterServer?.masterServerDelegate = self
            self.slaveServer?.slaveServerDelegate = self
            self.masterServer?.start()
            self.slaveServer?.start()
            //self.setCoreName(name: "MIX-RPC: \(port1)")
            self.setCoreName(displayPrefix: "MIX-RPC", name: "\(port1)")
            print("我的名字是\(self.coreName())")
        } else {
            print("未找到满足条件的端口对")
        }
    }
    
    // 检查指定端口是否可用
    func isPortFree(port: UInt16) -> Bool {
        
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        if socketFD < 0 {
            print("Failed to create socket")
            return false
        }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY.bigEndian
        
        let addrPointer = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
        }
        
        let result = bind(socketFD, addrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
        close(socketFD)
        return result == 0
    }

    // 查找一对满足条件的可用端口
    func findAvailablePortPair() -> (UInt16, UInt16)? {
        for port in 1000...9999 {
            let secondPort = UInt16(port) + 10000
            if secondPort > 65535 {
                continue // 跳过超出范围的端口
            }
            if isPortFree(port: UInt16(port)) && isPortFree(port: secondPort) {
                return (UInt16(port), secondPort)
            }
        }
        return nil // 未找到满足条件的端口对
    }
    
    
    
    // MARK: - 重写VBCore方法
    // 重写VBCore类begin()方法
    override func begin() {
        masterServer?.ready = true
        slaveServer?.ready = true
    }
    
    //重写VBCore类terminate()方法
    override func terminate() {
        masterServer?.stop()
        slaveServer?.stop()
    }
    
    
    
    // MARK: - 实现slaveServer（从服务器）需要的代理方法
    func buildSlaveConnectionsDirt(identity: String, connection: NWConnection) {
        slaveConnectionDict[identity] = connection
    }
    
    
    
    // MARK: - 实现masterServer（主服务器）需要的代理方法
    func buildMasterConnectionsDirt(endpoint: String, identity: String) {
        masterConnectionDict[endpoint] = identity
    }
    
    func respondToClient(connectionEndpoint: String, reponse: Data) {
        if  let identity = masterConnectionDict[connectionEndpoint], let slaveConnection = slaveConnectionDict[identity]{
            print("\(String(describing: self.slaveServer?.listener?.port))向\(slaveConnection.endpoint)回复内容：")
            send(reponse, to: slaveConnection)
        }else{
            print("respondToClient error")
            print(masterConnectionDict)
            print(slaveConnectionDict)
        }
    }
    
    func removeConnectionRecord(connectionEndpoint: String) {
        if let identity = masterConnectionDict[connectionEndpoint] {
            masterConnectionDict.removeValue(forKey: connectionEndpoint)
            if let _ = slaveConnectionDict[identity] {
                slaveConnectionDict.removeValue(forKey: identity)
            }
        }
    }
    
    func getResult(command: String) -> String{
        return self.matchCase(command: command)!
    }
    
    func addNewSession(message: String, botFlag: Bool){
        self.appendSession(message: Message(turn: Int(ceil(Double(self._session.count/2))), text: message, date: self.dateFormatter.string(from: Date()), botFlag: botFlag))
        self.sessionDelegate?.updateSession(session: self._session)
    }
    
}


// MARK: - TCP服务器
// 拥有MIX_RPCMasterDelegate代理对象时为MIX_RPC主服务器
// 拥有MIX_RPCSlaveDelegate代理对象时为MIX_RPC从服务器
/*
    使用代理的原因：
        无需各自编写主服务器和从服务器的Class
        专注 端到端之间的连接过程 和 消息的通用预处理
        预定义作为主/从服务器时的其它行为，具体的行为（例如如何组织响应内容，向何处发送响应等）通过对应的协议交由代理方灵活实现
*/
class VBTCPServer{
    private let encodings:[String.Encoding] = [.utf8, .ascii, .isoLatin1]
    private(set) var listener: NWListener?
    private var connectionStatusDict: [String:Bool] = [:]
    private var identity:String = ""
    var ready: Bool = false
    
    // 使用buffer暂存请求内容，内容完整时再进行处理
    var connectionsArr: [NWConnection] = []
    var connectionsBufferDirt: [String:Data] = [:]
    
    
    var masterServerDelegate:MIX_RPCMasterDelegate?
    var slaveServerDelegate:MIX_RPCSlaveDelegate?
    
    
    init(port: UInt16) {
        do {
            // 创建监听器，绑定到指定端口
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
        } catch {
            print("Failed to create listener: \(error)")
        }
    }
    
    
    func start() {
        sleep(1)
        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("监听成功")
            case .failed(let error):
                print("监听失败 with error: \(error)")
            default:
                break
            }
        }
        
        // 新连接处理
        listener?.newConnectionHandler = { [weak self] connection in
            guard let self = self, self.ready else {
                print(connection.debugDescription)
                return
            }
            print("新的连接请求")
            connectionsArr.append(connection)
            self.handleConnection(connection)
        }
        
        // 开始监听
        listener?.start(queue: .main)
    }
    
    
    private func handleConnection(_ newConnection: NWConnection) {
        newConnection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.connectionStatusDict[newConnection.endpoint.debugDescription] = false
                print("连接成功: \(newConnection.endpoint)")
                self.receive(on: newConnection)
            case .failed(let error):
                print("连接失败 failed: \(error)")
            default:
                break
            }
        }
        newConnection.start(queue: .main)
    }
    
    
    private func appendInBuffer(endpoint: String, data: Data) {
        if let _ = connectionsBufferDirt[endpoint] {
            connectionsBufferDirt[endpoint]?.append(data)
        }else{
            connectionsBufferDirt[endpoint] = data
        }
    }
    
    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 0, maximumLength: 1024) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                if !self.connectionStatusDict[connection.endpoint.debugDescription]! {
                    self.handshake(connection, data)
                }else {
                    
                    let endpoint = connection.endpoint.debugDescription
                    
                    print("\(String(describing: self.listener?.port))从\(connection.endpoint)收到消息：")
                    //加入缓冲区
                    self.appendInBuffer(endpoint: endpoint, data: data)
                    
                    let receiveStr = self.tryStringConversion(data: self.connectionsBufferDirt[endpoint]!,encodings: self.encodings)
                    
                    if let _ = receiveStr, receiveStr!.hasSuffix("}") {
                        let fullData = self.connectionsBufferDirt.removeValue(forKey: endpoint)
                        if let index = fullData?.startIndex {
                            let offset = fullData!.first == 0x00 ? 2 : 9
                            let index1 = fullData!.index(index, offsetBy: offset)
                            if let jsonData = fullData?[index1...] {
                                do {
                                    let handledJsonData = self.handleRequestArgs(in: jsonData)
                                    let _ = self.tryStringConversion(data: handledJsonData,encodings: self.encodings)
                                    let msg = try JSONDecoder().decode(RPCReuqest.self, from: handledJsonData)
                                    let cmd = "\(msg.method) \(msg.argsAsString ?? "")"
                                    print("收到的命令是 \(cmd)")
                                    self.masterServerDelegate?.addNewSession(message: cmd, botFlag: false)
                                    //从VBCase中取出对应的返回
                                    let result = self.masterServerDelegate?.getResult(command: cmd)
                                    
                                    var resp:[String:Any] = [:]
                                    if msg.method == "server.mode" {
                                        resp = RPCResponse(msg: msg, result: "normal")
                                        self.masterServerDelegate?.addNewSession(message: "normal", botFlag: true)
                                    }
                                    else if msg.method == "server.all_methods" {
                                        resp = RPCResponse(msg: msg, result: ["": [["doc":"","name":"fun_1"]]])
                                        self.masterServerDelegate?.addNewSession(message: String(describing: ["": [["doc":"","name":"fun_1"]]]), botFlag: true)
                                    }
                                    else{
                                        resp = RPCResponse(msg: msg, result: result!)
                                        self.masterServerDelegate?.addNewSession(message: result!, botFlag: true)
                                    }
                                    
                                    if let respData = try? JSONSerialization.data(withJSONObject: resp, options: []) {
                                        let len = respData.count
                                        var a = Data(self.build_respon_head(len))
                                        a.append(respData)
                                        self.masterServerDelegate?.respondToClient(connectionEndpoint: connection.endpoint.debugDescription ,reponse: a)
                                        print(self.tryStringConversion(data: a, encodings: self.encodings) ?? "没有内容")
                                    }
                                } catch {
                                    print("Error parsing JSON: \(error)")
                                }
                            }
                        }
                    }
                    else{
                        print("数据未完整，继续接收")
                    }
                }
            }
            else{
                print("收到空数据")
            }
                    
            if isComplete {
                print("Connection closed by remote.")
                connection.cancel()
                self.masterServerDelegate?.removeConnectionRecord(connectionEndpoint: connection.endpoint.debugDescription)
            } else if let error = error {
                print("Error: \(error)")
                connection.cancel()
            } else {
                // 继续接收
                self.receive(on: connection)
            }
        }
    }
    
    
    
    private func handshake(_ connection:NWConnection, _ acceptdData: Data) {
        print("\(connection.endpoint)")
        let content_str = String(describing: String(data: acceptdData, encoding: .utf8))
        print("接收到握手信息\(content_str)")
        print("接收到的Data\(acceptdData)")
        
        let len = acceptdData.count
        if len == 10 {
            let data = Data([0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x7f,0x03])
            send(data, to: connection)
            print("握手第一步结束")
        }
        else if len == 54 {
            var data = Data([0x00,0x4e,0x55,0x4c,0x4c,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00])
            send(data, to: connection)
            
            data = Data([0x04,0x29,0x05,0x52,0x45,0x41,0x44,0x59,0x0b,0x53,0x6f,0x63,0x6b,0x65,0x74,0x2d,0x54,0x79,0x70,0x65,0x00,0x00,0x00,0x06,0x52,0x4f,0x55,0x54,0x45,0x52,0x08,0x49,0x64,0x65,0x6e,0x74,0x69,0x74,0x79,0x00,0x00,0x00,0x00])
            send(data, to: connection)
            print("握手第二步结束")
            
        }
        else if len == 79 {
            self.connectionStatusDict[connection.endpoint.debugDescription]! = true
            self.masterServerDelegate?.buildMasterConnectionsDirt(endpoint: connection.endpoint.debugDescription, identity: content_str)
            self.slaveServerDelegate?.buildSlaveConnectionsDirt(identity: content_str, connection: connection)
            print("握手第三步结束")
        }
    }
    
    
    
    private func build_respon_head(_ number: Int) -> [UInt8]{
        //let value = UInt64(number) & 0xFFFFFFFFFFFFFFFF
        let value_str = String(format: "%016x", number)
        
        var bytes: [UInt8] = []
        for i in stride(from: 0, to: value_str.count, by: 2) {
            let start = value_str.index(value_str.startIndex, offsetBy: i)
            let end = value_str.index(start, offsetBy: 2)
            let part = String(value_str[start..<end])
            if let byte = UInt8(part, radix: 16) {
                bytes.append(byte)
            } else {
                print("无效的16进制字符串")
                break
            }
        }
        bytes.insert(0x02, at: 0)
        return bytes
    }
    
    
    private func tryStringConversion(data: Data, encodings: [String.Encoding]) -> String? {
        for encoding in encodings {
            if let receiveStr = String(data: data, encoding: encoding) {
                print("使用编码 \(encoding) 成功转换: \(receiveStr)")
                return receiveStr
            }
        }
        print("所有编码方式均失败")
        return nil
    }
    
    private func handleRequestArgs(in jsonData: Data) -> Data {
        // 将字符串解析为 JSON 数据
        guard var jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            fatalError("Invalid JSON string")
        }
        
        // 递归处理 JSON 数据
        func escapeDictionaries(_ value: Any) -> Any {
            if var dict = value as? [String: Any] {
                // 如果是字典，递归处理每个值
//                for (key, value) in dict {
//                    dict[key] = escapeDictionaries(value)
//                }
//                // 返回字典的 JSON 字符串形式
//                if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
//                   let jsonString = String(data: data, encoding: .utf8) {
//                    return jsonString
//                }
            }
            else if let array = value as? [Any] {
                // 如果是数组，递归处理每个元素
                return array.map {
                    return escapeDictionaries($0)
                }
            }
            // 如果是其他类型，直接返回
            return value
        }
        
        // 递归处理 JSON 数据，但跳过最外层字典
        for (key, value) in jsonObject {
            jsonObject[key] = escapeDictionaries(value)
        }
        
        // 将处理后的 JSON 数据转换回字符串
        guard let escapedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
            fatalError("Failed to serialize JSON")
        }
        
        return escapedData
    }
    
    func stop() {
        listener?.cancel()
        for connection in connectionsArr {
            connection.cancel()
        }
        print("Server stopped")
    }
}



// MARK: - MIX_RPC请求的基本格式
struct RPCReuqest: Codable {
    let jsonrpc: String
    let id: String
    let method: String
    let args: [Argument]?
    let kwargs: [String:String]?
    
    // 定义一个泛型 Argument，用于表示混合类型
    // 使用 Codable 协议以支持 JSON 编码和解码
    enum Argument: Codable {
        case string(String)
        case number(Int)
        case double(Double)
        
        // 实现编码器
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .number(let value):
                try container.encode(value)
            case .double(let value):
                try container.encode(value)
            }
        }
        
        // 实现解码器
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let intValue = try? container.decode(Int.self) {
                self = .number(intValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .double(doubleValue)
            } else {
                throw DecodingError.typeMismatch(Argument.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type"))
            }
        }
        
        // 将 Argument 转换为字符串
        var stringValue: String {
            switch self {
            case .string(let value):
                return value
            case .number(let value):
                return String(value)
            case .double(let value):
                return String(value)
            }
        }
    }
    
    //一个计算属性，用于将 args 转换为连接后的字符串
    var argsAsString: String? {
        guard let args = args else { return nil }
        return args.map { $0.stringValue }.joined(separator: " ")
    }
}



// MARK: - 组装MIX_RPC通信格式的响应（主体部分，未包含响应头）
func RPCResponse(msg:RPCReuqest, result: Any) -> [String:Any]{
    var resp:[String:Any] = [:]
    resp = [
        "jsonrpc": msg.jsonrpc,
        "method": msg.method,
        "id": msg.id,
        "result":result
    ]
    return resp
}



// MARK: - 发送数据
func send(_ data: Data, to connection: NWConnection) {
    connection.send(content: data, completion: .contentProcessed({ error in
        if let error = error {
            print("Failed to send data: \(error)")
        } else {
            print("Data sent successfully")
        }
    }))
}

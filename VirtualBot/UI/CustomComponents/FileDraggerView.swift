//
//  FileDraggerView.swift
//  VirtualBot
//
//  Created by ZXL on 2024/12/11.
//

import Foundation
import SwiftUI
import Cocoa

class NSFileDraggerView: NSView {
    private var allowedExtensions: [String] = []
    private var goodURLS: [URL] = []
    private var acceptsDirectory: Bool = false
    var onFileDragged: (([URL]) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // 注册拖拽类型，告诉视图我们希望它支持哪些类型的拖拽
        registerForDraggedTypes([.fileURL]) // 注册拖拽类型
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL]) // 注册拖拽类型
    }
    
    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if isFileTypeAllowed(sender){
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.5).cgColor
            return .copy
        } else {
            return []
        }
    }
    
    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func draggingEnded(_ sender: any NSDraggingInfo) {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        if let _ = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [:]) as? [URL] {
            onFileDragged?(goodURLS)
            return true
        }
        return false
    }
    
    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if isFileTypeAllowed(sender) {
            return .copy
        } else {
            return []
        }
    }
    
    private func isFileTypeAllowed(_ sender: NSDraggingInfo) -> Bool {
        // 从拖放数据中读取 URL 并检查扩展名
        if let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            goodURLS.removeAll()
            for item in items {
                if item.hasDirectoryPath && acceptsDirectory{
                    goodURLS.append(item)
                }else{
                    let fileExtension = item.pathExtension.lowercased()
                    if allowedExtensions.contains(fileExtension) {
                        goodURLS.append(item)
                    }
                }
            }
            if goodURLS.count > 0 {
                return true
            }
        }
        return false
    }
    
    func setAllowedExtensions(extensions: [String]){
        self.allowedExtensions = extensions
    }
    
    func setAcceptsDirectory(flag: Bool){
        self.acceptsDirectory = flag
    }
}

struct FileDraggerView: NSViewRepresentable {
    typealias NSViewType = NSFileDraggerView
    var fileUSage:(([URL]) -> Void)
    let allowedExtensions: [String]
    let acceptsDirectory: Bool
    init(fileUSage: @escaping ([URL]) -> Void, allowedExtensions: [String], acceptsDirectory: Bool = false) {
        self.fileUSage = fileUSage
        self.allowedExtensions = allowedExtensions
        self.acceptsDirectory = acceptsDirectory
    }
    
    func makeNSView(context: Context) -> NSFileDraggerView {
        let view = NSFileDraggerView()
        // 设置文件拖拽回调，传递文件路径
        view.onFileDragged = { fileURL in
            self.fileUSage(fileURL)  // 当 CSV 文件被拖拽时，传递文件路径
        }
        return view
    }
    
    func updateNSView(_ nsView: NSFileDraggerView, context: Context) {
        nsView.setAllowedExtensions(extensions: self.allowedExtensions)
        nsView.setAcceptsDirectory(flag: self.acceptsDirectory)
    }
}

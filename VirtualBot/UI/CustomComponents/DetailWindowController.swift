//
//  DetailWindowController.swift
//  Reddit-macOS
//
//  Created by Carson Katri on 7/31/19.
//  Copyright © 2019 Carson Katri. All rights reserved.
//

import Cocoa
import SwiftUI

/// A class to handle opening windows for posts when doubling clicking the entry
class DetailWindowController<RootView : View>: NSWindowController {
    convenience init(rootView: RootView) {
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 500, height: 500))
        
        window.styleMask.insert(.resizable)
        
        self.init(window: window)
    }
}

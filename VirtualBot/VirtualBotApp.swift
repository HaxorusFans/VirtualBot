//
//  VirtualBotApp.swift
//  VirtualBot
//
//  Created by ZXL on 2024/10/23.
//

import SwiftUI

@main
struct VirtualBotApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            mainWindow_V2()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onDisappear {
                    NSApplication.shared.terminate(nil)
                }
        }
        //.windowStyle(HiddenTitleBarWindowStyle())
        //.windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
    }
}

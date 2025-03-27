//
//  mainWindow.swift
//  VirtualBot
//
//  Created by ZXL on 2024/10/24.
//

import SwiftUI

struct mainWindow: View {
    @State var botArmy: [VBot] = []
    @State var botCopyed: [String:Bool] = [:]
    @State var showXBtn: Bool = false
    @State var seletedBot: String?

    var body: some View {
        NavigationView(content: {
            VStack{
                VStack(spacing:0){
                    if !botArmy.isEmpty {
                        List(selection: $seletedBot){
                            ForEach(botArmy){ bot in
                                NavigationLink(
                                    destination:
                                        VBotView(bot: bot),
                                    tag: bot.VBotName,
                                    selection: $seletedBot,
                                    label: {
                                        mainButton(botArmy: $botArmy, botCopyed: $botCopyed, seletedBot: $seletedBot, showXBtn: $showXBtn, bot: bot)
                                    }
                                )
                                .frame(maxWidth: .infinity)
                                .onTapGesture(count: 2) {
                                    self.seletedBot = bot.VBotName
                                    let detailView = VBotView(bot: bot)
                                    let controller = DetailWindowController(rootView: detailView)
                                    controller.window?.title = bot.VBotName
                                    controller.showWindow(nil)
                                }
                                .onTapGesture(count: 1) {
                                    self.seletedBot = bot.VBotName
                                }
                            }
                        }
                        .frame(minWidth: 250)
                        .listStyle(SidebarListStyle())
                    }else{
                        Spacer()
                        .frame(minWidth: 250)
                        .listStyle(SidebarListStyle())
                    }
                }
                mainFooter(botArmy: $botArmy, botCopyed: $botCopyed, seletedBot: $seletedBot)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar), with: nil)
                    }) {
                        Label("Toggle Sidebar", systemImage: "sidebar.left")
                            
                    }
                    .focusable(false)
                }
                ToolbarItem {
                    Button(action: {
                        withAnimation {
                            showXBtn.toggle()
                        }
                    }) {
                        if #available(macOS 12.0, *) {
                            Label("Modify", systemImage: showXBtn ? "pencil.tip.crop.circle.badge.minus" : "pencil.tip.crop.circle")
                                .symbolRenderingMode(showXBtn ? .multicolor : .monochrome)
                        } else {
                            // Fallback on earlier versions
                            Label("Modify", systemImage: showXBtn ? "pencil.tip.crop.circle.badge.minus" : "pencil.tip.crop.circle")
                        }
                    }
                    .focusable(false)
                }
            }
        })
    }
}



struct mainButton:View {
    @Binding var botArmy: [VBot]
    @Binding var botCopyed: [String:Bool]
    @Binding var seletedBot: String?
    @Binding var showXBtn:Bool
    var bot:VBot
    
    var body: some View {
        HStack(spacing:10){
            if showXBtn == true {
                Button(action: {
                    if let index = botArmy.firstIndex(where: { $0.VBotName == bot.VBotName }) {
                        if index == botArmy.count - 1 && index > 0 {
                            self.seletedBot = botArmy[index - 1].VBotName
                        }
                        else if index < botArmy.count - 1 {
                            self.seletedBot = botArmy[index + 1].VBotName
                        }
                        else{
                            self.seletedBot = nil
                        }
                        bot.core.terminate()
                        botArmy.remove(at: index)
                        botCopyed.removeValue(forKey: bot.VBotName)
                    }
                }, label: {
                    if #available(macOS 12.0, *) {
                        Image(systemName: "minus.circle.fill")
                            .symbolRenderingMode(.multicolor)
                    } else {
                        // Fallback on earlier versions
                        Image(systemName: "minus.circle.fill")
                    }
                })
                .buttonStyle(BorderlessButtonStyle())
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            Text(bot.displayVBotName)
            Spacer()
        }
    }
}



struct mainFooter:View {
    @Binding var botArmy: [VBot]
    @Binding var botCopyed: [String:Bool]
    @Binding var seletedBot: String?
    @State var seletedVBCores: String?
    var body: some View {
        HStack{
            if let seletedCores = seletedVBCores, seletedCores == "MIX-RPC"{
                Button(action: {
                    let bot = VBot(core: MIX_RPCCore())
                    botArmy.append(bot)
                    botCopyed.updateValue(false, forKey: bot.VBotName)
                    self.seletedBot = bot.VBotName
                }, label: {
                    Image(systemName: "plus.circle")
                    Text("Add a MIX-RPC Virtual Bot")
                })
                
            }else{
                Button(action: {
                    let bot = VBot(core: SerialPortCore())
                    botArmy.append(bot)
                    botCopyed.updateValue(false, forKey: bot.VBotName)
                    self.seletedBot = bot.VBotName
                }, label: {
                    Image(systemName: "plus.circle")
                    Text("Add a SerialPort Virtual Bot")
                })
                
            }
            Menu(""){
                Button(action: {
                    seletedVBCores = "SerialPort"
                }) {
                    Text("SerialPort")
                }
                .buttonStyle(DefaultButtonStyle())
                
                Button(action: {
                    seletedVBCores = "MIX-RPC"
                }) {
                    Text("MIX-RPC")
                }
                .buttonStyle(DefaultButtonStyle())
            }
            .frame(maxWidth:20)
            .menuStyle(BorderlessButtonMenuStyle())
            
        }
        .padding()
        .focusable(false)
        .buttonStyle(BorderlessButtonStyle())
    }
}




#Preview {
    mainWindow()
}

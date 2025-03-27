//
//  caseView.swift
//  VirtualBot
//
//  Created by zeng.xiaolei1    on 2025/2/25.
//

import SwiftUI


struct caseView: View {
    @State var VBArmy: VBotArmy
    @State private var isHovering: Bool = false
    @State var strongOrder:Bool = false
    @State var showPopover:Bool = false
    
    var body: some View {
        mainCaseView(VBArmy: $VBArmy, strongOrder: $strongOrder, showPopover: $showPopover)
    }
}

struct mainCaseView:View, FileSpaceDelegate {
    @EnvironmentObject var factory:factory_DataViewModel
    
    @Binding var VBArmy:VBotArmy
    @Binding var strongOrder:Bool
    @Binding var showPopover: Bool
    
    @State private var selectedBot:VBot?
    @State private var opacity = 0.3
    @State private var scheduleFinish:Bool = false
    @State private var botCopyed:Bool = false
    @State private var showTralingSidebar:Bool = true
    
    var body: some View{
        HStack {
            if !VBArmy.army.isEmpty {
                HSplitView{
                    ZStack{
                        ChatSpace(bot: selectedBot ?? VBArmy.army.first!)
//                        .onAppear {
//                            if let _ = selectedBot.VBcase() {
//                                self.strongOrder = selectedBot.VBcase()!.strongOrder
//                            }
//                        }
                        .padding()
                    }
                    if showTralingSidebar {
                        TralingSidebar_V2(VBArmy: $VBArmy, showTralingSidebar: $showTralingSidebar, selectedBot: $selectedBot)
                    }
                }
                .toolbar {
                    ToolbarItem {
                        if let _ = selectedBot {
                            ToggleOrderButton_V2(VBArmy: $VBArmy, strongOrder: $strongOrder, showPopover: $showPopover)
                        }
                    }
                    ToolbarItem {
                        Button(action: {
                            selectedBot?.cleanSession()
                        }) {
                            Label("Clean chat space", systemImage: "trash")
                        }
                    }
                    ToolbarItem {
                        Button {
                            for bot in VBArmy.army {
                                bot.resetSession()
                            }
                            scheduleFinish = false
                        } label: {
                            Label("Reset Schedule", systemImage: "arrow.counterclockwise")
//                            Image(systemName: "arrow.counterclockwise.circle")
                        }
                        
                    }
                    ToolbarItem {
                        Button {
                            for bot in VBArmy.army {
                                bot.autoPlay()
                            }
                            scheduleFinish = true
                        } label: {
                            Label("Auto Play", systemImage: (scheduleFinish ? "play.slash" : "play"))
                        }
                    }
                    ToolbarItem {
                        Button(action: {
                            showTralingSidebar.toggle()
                        }) {
                            Label("Trailing sidebar", systemImage: "sidebar.trailing")
                        }
                    }
                    ToolbarItem(placement: .navigation){
                        Button(action: {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(selectedBot!.VBotName, forType: .string)
                            botCopyed.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                botCopyed.toggle()
                            }
                        }, label: {
                            Label("Copy core name", systemImage: botCopyed ? "checkmark" : "doc.on.doc")
                        })
                        .buttonStyle(BorderlessButtonStyle())
                        .focusable(false)
                        .frame(width: 20)
                    }
                }
                .animation(nil)
            }
            else{
                FileSpace(delegate: self)
                    .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 200)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
        }
        .onDisappear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0.3
            }
        }
    }
    
    func handleDrop(URLS: [URL]) {
        SingletonVBotFactory.VBotFactory.ARO(id: self.VBArmy.id, order: URLS.last!.path, strongOrder: strongOrder)
        self.VBArmy = SingletonVBotFactory.VBotArmyRepo.first(where: { VBArmy in
            VBArmy.id == self.VBArmy.id
        })!
        self.selectedBot = self.VBArmy.army.first!
        factory.repo = SingletonVBotFactory.VBotArmyRepo
    }
}

//MARK: - TralingSidebarV2
struct TralingSidebar_V2:View {
    @Binding var VBArmy:VBotArmy
    @Binding var showTralingSidebar:Bool
    @State var selectedItem:String?
    @Binding var selectedBot:VBot?
    var body: some View {
        VStack(spacing:0){
            List(selection: $selectedItem) {
                ForEach(VBArmy.army) { bot in
                    VBotItem(bot: bot, selectedItem: $selectedItem, selectedBot: $selectedBot)
                        .onTapGesture {
                            selectedItem = bot.displayVBotName
                            selectedBot = bot
                        }
                        .tag(bot.displayVBotName)
                }
                
            }
            .frame(minWidth: 200)
            .frame(maxWidth: .infinity)
            .listStyle(SidebarListStyle())
            .animation(nil)
        }
        .onAppear{
            if let _ = selectedBot {
                
            }else{
                selectedBot = VBArmy.army.first
            }
            selectedItem = selectedBot?.displayVBotName
        }
    }
}


struct VBotItem:View {
    @ObservedObject var bot:VBot
    @Binding var selectedItem:String?
    @State var nameCopyed:Bool = false
    @Binding var selectedBot:VBot?
    var body: some View {
        DisclosureGroup {
            LazyVStack{
                ForEach(Array(bot.VBcmdarr.enumerated()), id: \.0){index, cmd in
                    CmdItem(bot: bot, index: index, cmd: cmd)
                }
            }
                .onTapGesture {
                    selectedItem = bot.displayVBotName
                    selectedBot = bot
                }
        } label: {
            Text(bot.displayVBotName)
                .frame(maxWidth:.infinity, alignment: .leading)
                .background(
                    VisualEffectView(material: .sidebar, blendingMode: .behindWindow).opacity(0.01)
                )
                .onTapGesture {
                    selectedItem = bot.displayVBotName
                    selectedBot = bot
                }
        }
        .frame(maxHeight: .infinity)
    }
}

struct ToggleOrderButton_V2: View {
    @EnvironmentObject var factory:factory_DataViewModel
    @Binding var VBArmy:VBotArmy
    @Binding var strongOrder: Bool
    @Binding var showPopover: Bool

    var body: some View {
        Button {
            strongOrder.toggle()
            SingletonVBotFactory.VBotFactory.changeOrderMode(id: VBArmy.id,strongOrder: strongOrder)
        } label: {
            // 根据系统版本选择使用多色样式
            if #available(macOS 12.0, *) {
                Label("Switch order mode", systemImage: strongOrder ? "rectangle.split.1x2.fill" : "waveform.path.ecg.rectangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(strongOrder ? .green : .red)
            } else {
                Label("", systemImage: strongOrder ? "rectangle.split.1x2.fill" : "waveform.path.ecg.rectangle.fill")
            }
        }
        .onHover { flag in
            showPopover = flag
        }
        .popover(isPresented: $showPopover, arrowEdge: .trailing) {
            Label(
                strongOrder ? "当前强顺序模式, 必须遵循case顺序发送指令。点击切换。" :
                              "当前弱顺序模式, 允许任意顺序发送指令。点击切换。",
                systemImage: strongOrder ? "rectangle.split.1x2.fill" : "waveform.path.ecg.rectangle.fill"
            )
            .padding(20)
            .frame(width: 250, height: 80)
        }
    }
}
//MARK: - Preview
#Preview {
    VBotView(bot: VBot(core: SerialPortCore()))
}


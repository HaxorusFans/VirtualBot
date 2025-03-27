//
//  VBotView.swift
//  VirtualBot
//  Created by ZXL on 2024/12/13
        

import SwiftUI

protocol FileSpaceDelegate{
    func handleDrop(URLS: [URL])
}

struct VBotView: View {
    @ObservedObject var bot:VBot
    @State private var isHovering: Bool = false
    @State var strongOrder:Bool = false
    @State var showPopover:Bool = false
    
    var body: some View {
        mainVbotView(bot: bot, strongOrder: $strongOrder, showPopover: $showPopover)
    }
}

struct mainVbotView:View, FileSpaceDelegate {
    @ObservedObject var bot:VBot
    @Binding var strongOrder:Bool
    @State private var opacity = 0.3
    @Binding var showPopover: Bool
    @State var showTralingSidebar:Bool = false
    @State var botCopyed1:Bool = false
    var body: some View{
        HStack {
            if bot.VBcase != nil {
                HSplitView{
                    ZStack{
                        ChatSpace(bot: bot)
                            .onAppear {
                                if let _ = bot.VBcase {
                                    self.strongOrder = bot.VBcase!.strongOrder
                                }
                            }
                            .padding()
                    }
                    
                    if showTralingSidebar {
                        TralingSidebar(bot: bot, showTralingSidebar: $showTralingSidebar)
                    }
                }
                .toolbar {
                    ToolbarItem {
                        ToggleOrderButton(bot: bot, strongOrder: $strongOrder, showPopover: $showPopover)
                    }
                    ToolbarItem {
                        Button(action: {
                            bot.cleanSession()
                        }) {
                            Label("Clean chat space", systemImage: "trash")
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
                            pasteboard.setString(bot.VBotName, forType: .string)
                            botCopyed1.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                botCopyed1.toggle()
                            }
                        }, label: {
                            Image(systemName: botCopyed1 ? "checkmark" : "doc.on.doc")
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
        bot.stratWithCase(newCasePath: URLS.last!.path, strongOrder: strongOrder)
    }
}


//MARK: - File Space
struct FileSpace:View {
    @State private var droppedFiles: [String] = []
    var delegate:FileSpaceDelegate?
    let allowedExtensions = ["csv"]
    var body: some View {
        if #available(macOS 12.0, *) {
            VStack{
                Label("Feed a case(.csv) to me", systemImage: "plus.viewfinder")
                    .font(.title2)
                    .foregroundStyle(Color.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [10, 2]))
                    )
                    .background(
                        FileDraggerView(fileUSage: { URLS in
                            handleDrop(URLS: URLS)
                        }, allowedExtensions: allowedExtensions)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                    .animation(nil)
            }
            .frame(maxWidth: .infinity)
            .background()
            .padding()
        } else {
            // Fallback on earlier versions
            VStack{
                Label("Feed a case(.csv) to me", systemImage: "plus.viewfinder")
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [10, 2]))
                    )
                    .background(
                        FileDraggerView(fileUSage: { URLS in
                            handleDrop(URLS: URLS)
                        }, allowedExtensions: allowedExtensions)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                    .animation(nil)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    private func handleDrop(URLS: [URL]){
        DispatchQueue.main.async {
            self.delegate?.handleDrop(URLS: URLS)
        }
    }
}


//MARK: - Chat Space
struct ChatSpace:View {
    @ObservedObject var bot:VBot
    var body: some View {
        ScrollViewReader{ scrollViewProxy in
            ScrollView{
                LazyVStack{
                    ForEach(bot.session ,id: \.id){ messgae in
                        if messgae.botFlag {
                            MessageBubble_RX(message: messgae)
                                .id(messgae.id)
                        }else{
                            MessageBubble_TX(message: messgae)
                                .id(messgae.id)
                        }
                    }
                    Spacer()
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
                .padding()
                
            }
            .onChange(of: bot.session.count) { _ in
                scrollViewProxy.scrollTo(bot.session.last?.id, anchor: .center)
            }
        }
        .frame(minWidth: 300, minHeight: 200)
        .frame(maxWidth: .infinity)
        .navigationTitle("\(bot.displayVBotName)  |  \(bot.VBcase!.name!)")
    }
}


struct ToggleOrderButton: View {
    @ObservedObject var bot: VBot
    @Binding var strongOrder: Bool
    @Binding var showPopover: Bool

    var body: some View {
        Button {
            if let _ = bot.VBcase {
                bot.VBcase!.strongOrder.toggle()
                strongOrder = bot.VBcase!.strongOrder
            }
        } label: {
            // 根据系统版本选择使用多色样式
            if #available(macOS 12.0, *) {
                Label("", systemImage: strongOrder ? "rectangle.split.1x2.fill" : "waveform.path.ecg.rectangle.fill")
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


//MARK: - Traling Sidebar
struct TralingSidebar:View {
    @ObservedObject var bot:VBot
    @Binding var showTralingSidebar:Bool
    var body: some View {
        VStack(spacing:0){
            VStack(spacing:0){
                HStack(spacing:15){
                    Spacer()
                    Button {
                        bot.resetSession()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    Button {
                        bot.autoPlay()
                    } label: {
                        Image(systemName: "play.circle")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    Spacer()
                }
                .padding(.vertical, 5)
                Divider()
            }
            .background(
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
            )
            
            
            List {
                ForEach(Array(bot.VBcase!.cmdArr().enumerated()), id: \.0) { index ,cmd in
                    CmdItem(bot: bot, index: index, cmd: cmd)
                }
            }
            .frame(minWidth: 200)
            .frame(maxWidth: .infinity)
            .listStyle(SidebarListStyle())
            .animation(nil)
        }
    }
}

struct CmdItem:View {
    @ObservedObject var bot:VBot
    @State var index:Int
    @State var cmd:String
    @State var cmdCopyed:Bool = false
    var body: some View {
        HStack{
            Button {
                bot.autoPlay1(cmd: cmd)
            } label: {
                if index == bot.anchor {
                    Image(systemName: "location")
//                        .renderingMode(.template) // 强制使用模板渲染模式
//                        .foregroundColor(.blue)    // 设置为蓝色
                }else if index < (bot.anchor)!{
                    Image(systemName: "checkmark")
//                        .renderingMode(.template) // 强制使用模板渲染模式
//                        .foregroundColor(.green)    // 设置为绿色
                }else{
                    Image(systemName: "minus")
//                        .renderingMode(.template) // 强制使用模板渲染模式
//                        .foregroundColor(.gray)    // 设置为灰色
                }
                Text(" ")
            }
            .background(
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow).opacity(0.01)
            )
            .buttonStyle(BorderlessButtonStyle())
        
            Text(cmd)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    VisualEffectView(material: .sidebar, blendingMode: .behindWindow).opacity(0.01)
                )
            Button(action: {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(cmd, forType: .string)
                cmdCopyed.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    cmdCopyed.toggle()
                }
            }, label: {
                Image(systemName: cmdCopyed ? "checkmark" : "doc.on.doc")
                    .animation(nil)
//                Image(systemName: "play.fill")
            })
            .buttonStyle(BorderlessButtonStyle())
            .focusable(false)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        // 修改这里，使用 .followsWindowActiveState
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}



//MARK: - Preview
#Preview {
    VBotView(bot: VBot(core: SerialPortCore()))
}

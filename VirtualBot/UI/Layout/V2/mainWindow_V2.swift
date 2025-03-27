//
//  mainWindow_V2.swift
//  VirtualBot
//  Created by ZXL on 2025/2/24
        

import SwiftUI

class factory_DataViewModel: ObservableObject {
    @Published var repo:[VBotArmy] = []
}

struct mainWindow_V2: View {
    @ObservedObject var factory = factory_DataViewModel()
    @State var botCopyed: [String:Bool] = [:]
    @State var showXBtn: Bool = false
    @State var seletedArmy: UUID?

    var body: some View {
        NavigationView(content: {
            VStack{
                VStack(spacing:0){
                    if !factory.repo.isEmpty {
                        List(selection: $seletedArmy){
                            ForEach(factory.repo){ VBArmy in
                                NavigationLink(
                                    destination:
                                        caseView(VBArmy: VBArmy)
                                        .environmentObject(factory)
                                    ,
                                    tag: VBArmy.id,
                                    selection: $seletedArmy,
                                    label: {
                                        mainButton_V2(seletedArmy: $seletedArmy, showXBtn: $showXBtn, VBArmy: VBArmy)
                                            .environmentObject(factory)
                                    }
                                )
                                .frame(maxWidth: .infinity)
                                
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
                mainFooter_V2(seletedArmy: $seletedArmy)
                    .environmentObject(factory)
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



struct mainButton_V2:View {
    @EnvironmentObject var factory:factory_DataViewModel
    @Binding var seletedArmy: UUID?
    @Binding var showXBtn:Bool
    @State var editable:Bool = false
    @State var VBArmy:VBotArmy
    
    var body: some View {
        HStack(spacing:10){
            if showXBtn == true {
                Button(action: {
                    if let index = factory.repo.firstIndex(where: { $0.id == VBArmy.id }) {
                        if index == factory.repo.count - 1 && index > 0 {
                            self.seletedArmy = factory.repo[index - 1].id
                        }
                        else if index < factory.repo.count - 1 {
                            self.seletedArmy = factory.repo[index + 1].id
                        }
                        else{
                            self.seletedArmy = nil
                        }
                        SingletonVBotFactory.VBotFactory.killArmy(id: VBArmy.id)
                        factory.repo = SingletonVBotFactory.VBotArmyRepo
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
            
            if seletedArmy == VBArmy.id {
                TextField("", text: $VBArmy.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
            }else{
                Text(VBArmy.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}



struct mainFooter_V2:View {
    @EnvironmentObject var factory:factory_DataViewModel
    @Binding var seletedArmy: UUID?
    var body: some View {
        HStack{
            Button(action: {
                let id = UUID()
                SingletonVBotFactory.VBotFactory.newEmptyArmy(id: id)
                factory.repo = SingletonVBotFactory.VBotArmyRepo
                seletedArmy = id
            }, label: {
                Image(systemName: "plus.circle")
                Text("Add a case")
            })
        }
        .padding()
        .focusable(false)
        .buttonStyle(BorderlessButtonStyle())
    }
}




#Preview {
    mainWindow_V2()
}

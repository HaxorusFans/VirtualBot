//
//  VBotView.swift
//  VirtualBot
//  Created by ZXL on 2024/12/13

import SwiftUI

struct MessageBubble_TX: View {
    let message:Message
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Text(message.date)
                    .font(.footnote)
                    .foregroundColor(.gray)    // 设置为灰色
            }
            HStack(alignment: .top) {
                Spacer()
                if #available(macOS 12.0, *) {
                    Text(message.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(20) // 限制显示 2 行
                        .truncationMode(.tail) // 超出部分显示省略号
                        .chatBubble(
                            position: .trailingBottom,
                            cornerRadius: 17,
                            color: .green.opacity(0.5)
                        )
                        .frame(maxWidth: 350, alignment: .trailing)
                        .textSelection(.enabled)
                } else {
                    // Fallback on earlier versions
                    Text(message.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .chatBubble(
                            position: .trailingBottom,
                            cornerRadius: 17,
                            color: .green.opacity(0.5)
                        )
                        .frame(maxWidth: 350, alignment: .trailing)
                }
            }
        }
    }
}

struct MessageBubble_RX: View {
    let message:Message
    var body: some View {
        VStack{
            HStack{
                Text(message.date)
                    .font(.footnote)
                    .foregroundColor(.gray)    // 设置为灰色
                Spacer()
            }
            HStack(alignment: .top) {
                if #available(macOS 12.0, *) {
                    Text(message.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(20) // 限制显示 2 行
                        .truncationMode(.tail) // 超出部分显示省略号
                        .chatBubble(
                            position: .leadingBottom,
                            cornerRadius: 17,
                            color: .blue.opacity(0.5)
                        )
                        .frame(maxWidth: 350, alignment: .leading)
                        .textSelection(.enabled)
                } else {
                    // Fallback on earlier versions
                    Text(message.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .chatBubble(
                            position: .leadingBottom,
                            cornerRadius: 17,
                            color: .blue.opacity(0.5)
                        )
                        .frame(maxWidth: 350, alignment: .leading)
                }
                Spacer()
            }
        }
    }
}

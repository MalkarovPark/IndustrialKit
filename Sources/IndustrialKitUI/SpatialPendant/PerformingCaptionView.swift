//
//  PerformingCaptionView.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI
import IndustrialKit

struct PerformingCaptionView: View
{
    let name: String
    let performing_state: PerformingState
    
    public init(name: String, performing_state: PerformingState)
    {
        self.name = name
        self.performing_state = performing_state
    }
    
    public var body: some View
    {
        ZStack
        {
            Rectangle()
                .fill(.clear)
            #if os(macOS)
                .frame(height: 32)
            #else
                .frame(height: 40)
            #endif
                .glassEffect(.clear, in: .capsule(style: .continuous))
            
            VStack
            {
                Text(name)
                #if os(macOS)
                    .font(.system(size: 14, design: .rounded))
                #else
                    .font(.system(size: 18, design: .rounded))
                #endif
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            
            HStack
            {
                Spacer()
                Image(systemName:"circlebadge.fill")
                #if !os(visionOS)
                    .foregroundColor(performing_state.color)
                #else
                    .foregroundColor(.clear)
                    .glassEffect(.regular.tint(performing_state.color).interactive(), in: .circle)
                #endif
                #if os(macOS)
                    .padding(.trailing, 10)
                    .font(.system(size: 14))
                #elseif os(iOS)
                    .padding(.trailing, 10)
                    .font(.system(size: 18))
                #elseif os(visionOS)
                    .padding(.trailing, 12)
                    .font(.system(size: 18))
                #endif
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview
{
    struct PreviewContainer: View
    {
        @State private var current_state_index: Int = 0
        
        var body: some View
        {
            PerformingCaptionView(
                name: "Workspace",
                performing_state: PerformingState.allCases[current_state_index]
            )
            .frame(width: pendant_content_width)
            .padding()
            #if !os(visionOS)
            .background(.secondary.opacity(0.1))
            #endif
            .onReceive(
                Timer.publish(every: 1.5, on: .main, in: .common)
                    .autoconnect()
            )
            { _ in
                current_state_index =
                (current_state_index + 1) % PerformingState.allCases.count
            }
        }
    }
    
    return PreviewContainer()
}

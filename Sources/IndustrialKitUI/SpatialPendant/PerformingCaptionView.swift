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
                    .foregroundColor(performing_state.color)
                #if os(macOS)
                    .padding(.trailing, 10)
                    .font(.system(size: 14))
                #else
                    .padding(.trailing, 10)
                    .font(.system(size: 18))
                #endif
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview
{
    PerformingCaptionView(name: "Workspace", performing_state: .none)
        .frame(width: pendant_content_width)
        .frame(width: pendant_content_width)
        .padding()
        .background(.secondary.opacity(0.25))
}

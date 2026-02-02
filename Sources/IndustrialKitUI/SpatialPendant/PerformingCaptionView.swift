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
                .glassEffect(.clear, in: .capsule(style: .continuous))//.rect(cornerRadius: 16, style: .continuous))
            
            VStack
            {
                Text(name)
                #if os(macOS)
                    .font(.system(size: 14, design: .rounded))
                #else
                    .font(.system(size: 16, design: .rounded))
                #endif
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            
            HStack
            {
                Spacer()
                Image(systemName:"circlebadge.fill")
                    .foregroundColor(performing_state.color)
                    .padding(.trailing, 10)
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: 32)
    }
}

#Preview
{
    PerformingCaptionView(name: "Workspace", performing_state: .completed)
        .frame(width: 200)
}

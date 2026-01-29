//
//  ToolControlView.swift
//  IndustrialKit
//
//  Created by Artem on 30.01.2026.
//

import SwiftUI
import IndustrialKit

struct ToolControlView: View
{
    @ObservedObject var tool: Tool
    
    var body: some View
    {
        VStack(alignment: .center, spacing: 16)
        {
            ZStack
            {
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                
                ScrollView
                {
                    Text("Tool")
                }
            }
            .frame(width: 200)
        }
    }
}

#Preview
{
    ToolControlView(tool: Tool())
}

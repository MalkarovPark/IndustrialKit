//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI
import IndustrialKit

struct OperationControl: View
{
    @ObservedObject var tool: Tool
    
    var body: some View
    {
        Rectangle()
            .fill(.clear)
            .frame(width: 80, height: 80)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Previews
struct OperationControl_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var tool = Tool()
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                Spacer()
                
                OperationControl(tool: tool)
                    .padding()
            }
            .frame(width: 400, height: 400)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

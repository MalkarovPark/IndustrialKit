//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Artem on 30.01.2026.
//

import SwiftUI
import IndustrialKit

struct WorkspaceControlView: View
{
    @ObservedObject var workspace: Workspace
    
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
                    Text("Workspace")
                }
            }
            .frame(width: 200)
        }
    }
}

#Preview
{
    WorkspaceControlView(workspace: Workspace())
}

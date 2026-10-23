//
//  PerformingControlView.swift
//  IndustrialKit
//
//  Created by Artem on 23.10.2026.
//

import SwiftUI

public struct PerformingControlView: View
{
    let reset_performing: () -> Void
    let start_pause_performing: () -> Void
    
    var program_performed: Bool
    
    public init(
        reset_performing: @escaping () -> Void,
        start_pause_performing: @escaping () -> Void,
        
        program_performed: Bool
    )
    {
        self.reset_performing = reset_performing
        self.start_pause_performing = start_pause_performing
        
        self.program_performed = program_performed
    }
    
    public var body: some View
    {
        HStack(spacing: 2)
        {
            Button(action: reset_performing)
            {
                Image(systemName: "stop.fill")
                    .modifier(CircleButtonImageFramer())
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            
            Divider()
                .frame(height: 24)
            
            Button(action: start_pause_performing)
            {
                Image(systemName: program_performed ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .modifier(CircleButtonImageFramer())
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
        }
        #if os(macOS)
        .padding(4)
        #endif
        #if !os(visionOS)
        .glassEffect(.regular.interactive())
        #else
        .controlSize(.large)
        .buttonStyle(.borderless)
        .glassBackgroundEffect()
        .frame(depth: 24)
        #endif
        #if os(macOS) || os(iOS)
        .padding(10)
        #else
        .padding(16)
        #endif
    }
}

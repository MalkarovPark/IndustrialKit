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
        HStack(spacing: 0)
        {
            Button(action: reset_performing)
            {
                Image(systemName: "stop.fill")
                #if !os(visionOS)
                    .imageScale(.large)
                #endif
                #if os(macOS)
                    .frame(width: 36, height: 36)
                #else
                    .frame(width: 44, height: 44)
                #endif
                #if os(iOS)
                    .tint(.black)
                #endif
            }
            #if !os(iOS)
            .buttonStyle(.borderless)
            #else
            .buttonStyle(.plain)
            #endif
            .buttonBorderShape(.circle)
            
            Divider()
                .frame(height: 24)
            
            Button(action: start_pause_performing)
            {
                Image(systemName: program_performed ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                #if !os(visionOS)
                    .imageScale(.large)
                #endif
                #if os(macOS)
                    .frame(width: 36, height: 36)
                #else
                    .frame(width: 44, height: 44)
                #endif
                #if os(iOS)
                    .tint(.black)
                #endif
            }
            #if !os(iOS)
            .buttonStyle(.borderless)
            #else
            .buttonStyle(.plain)
            #endif
            .buttonBorderShape(.circle)
        }
        .clipShape(.capsule(style: .continuous))
        .glassEffect(.regular.interactive(), in: .capsule(style: .continuous))
        #if os(macOS) || os(iOS)
        .padding(10)
        #else
        .padding(16)
        #endif
    }
}

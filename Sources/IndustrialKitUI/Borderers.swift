//
//  Borderers.swift
//  IndustrialKit
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI

public struct ViewBorderer: ViewModifier
{
    public init()
    {
        
    }
    
    public func body(content: Content) -> some View
    {
        content
            .clipShape(RoundedRectangle(
                cornerRadius: {
                #if os(macOS)
                    6.5
                #elseif os(iOS)
                    7.5
                #elseif os(visionOS)
                    22.5
                #endif
                }(),
                style: .continuous)
            )
        #if !os(visionOS)
            .overlay
            {
                RoundedRectangle(
                    cornerRadius: {
                    #if os(macOS)
                        6.5
                    #elseif os(iOS)
                        7.5
                    #elseif os(visionOS)
                        22.5
                    #endif
                    }(),
                    style: .continuous
                )
                .stroke(.black.opacity(0.1), lineWidth: 1)
            }
            .allowsTightening(false)
        //.shadow(color: .black.opacity(0.1), radius: 4)
        #endif
    }
}

public struct ListBorderer: ViewModifier
{
    public init()
    {
        
    }
    
    public func body(content: Content) -> some View
    {
        ZStack
        {
            Rectangle()
            #if !os(visionOS)
                .foregroundColor(.white)
            #else
                .foregroundStyle(.thinMaterial)
            #endif
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            content
                .listStyle(.plain)
        }
        .modifier(ViewBorderer())
    }
}

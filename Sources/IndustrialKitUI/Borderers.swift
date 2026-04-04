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
        #if os(macOS)
            .clipShape(RoundedRectangle(cornerRadius: 6.5, style: .continuous))
        #elseif os(iOS)
            .clipShape(RoundedRectangle(cornerRadius: 7.5, style: .continuous))
        #elseif os(visionOS)
            .clipShape(RoundedRectangle(cornerRadius: 22.5, style: .continuous)) //.clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        #endif
        #if !os(visionOS)
            .shadow(color: .black.opacity(0.1), radius: 4)
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

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
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 4)
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

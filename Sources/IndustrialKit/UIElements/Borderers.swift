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
            .clipShape(RoundedRectangle(cornerRadius: 4.5, style: .continuous))
        #else
            .clipShape(RoundedRectangle(cornerRadius: 7.5, style: .continuous))
        #endif
            .shadow(radius: 1)
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            content
                .listStyle(.plain)
        }
        .modifier(ViewBorderer())
    }
}

#if os(iOS)
public struct ButtonBorderer: ViewModifier
{
    @State private var pressed = false
    
    public init()
    {
        
    }
    
    public func body(content: Content) -> some View
    {
        content
            .buttonStyle(.bordered)
            .foregroundStyle(.primary)
            .tint(.white)
            .background
            {
                Rectangle()
                    .foregroundStyle(pressed ? Color.init(red: 0.914, green: 0.914, blue: 0.922) : Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)) //(cornerRadius: 7.5, style: .continuous))
            .shadow(radius: 1)
            .onLongPressGesture(perform: {}, onPressingChanged:
            { pressing in
                pressed = pressing
            })
    }
}

public struct PickerBorderer: ViewModifier
{
    @State private var pressed = false
    
    public init()
    {
        
    }
    
    public func body(content: Content) -> some View
    {
        content
            .buttonStyle(.borderless)
            .foregroundStyle(.primary)
            .tint(.primary)
            .background
            {
                Rectangle()
                    .foregroundStyle(pressed ? Color.init(red: 0.914, green: 0.914, blue: 0.922) : Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 7.5, style: .continuous))
            .shadow(radius: 1)
            .onLongPressGesture(perform: {}, onPressingChanged:
            { pressing in
                pressed = pressing
            })
    }
}
#endif

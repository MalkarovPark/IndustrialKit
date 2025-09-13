//
//  ViewCloseButton.swift
//  IndustrialKit
//
//  Created by Artem on 06.11.2023.
//

import SwiftUI

public struct ViewCloseButton: ViewModifier
{
    @Binding public var is_presented: Bool
    
    public init(is_presented: Binding<Bool>)
    {
        self._is_presented = is_presented
    }
    
    public func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .topLeading)
            {
                Button(action: { is_presented.toggle() })
                {
                    Image(systemName: "xmark")
                        .modifier(CircleButtonImageFramer())
                }
                .keyboardShortcut(.cancelAction)
                .modifier(CircleButtonGlassBorderer())
                .padding(10)
            }
    }
}

public struct ViewCloseFuncButton: ViewModifier
{
    let close_action: (() -> ())
    
    public init(close_action: @escaping () -> ())
    {
        self.close_action = close_action
    }
    
    public func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .topLeading)
            {
                Button(action: close_action)
                {
                    Image(systemName: "xmark")
                        .modifier(CircleButtonImageFramer())
                }
                .keyboardShortcut(.cancelAction)
                .modifier(CircleButtonGlassBorderer())
                .padding(10)
            }
    }
}

// MARK: - Glass Button Modifiers
public struct CircleButtonGlassBorderer: ViewModifier
{
    public init()
    {
        
    }
    
    public func body(content: Content) -> some View
    {
        content
            .buttonBorderShape(.circle)
        #if os(macOS)
            .buttonStyle(.glass)
        #elseif os(iOS)
            .glassEffect(.regular.interactive())
        #else
            .glassBackgroundEffect()
        #endif
            //.padding()
    }
}

public struct CircleButtonImageFramer: ViewModifier
{
    public init()
    {
        
    }
    
    public func body(content: Content) -> some View
    {
        content
            .imageScale(.large)
        #if os(macOS)
            .frame(width: 16, height: 16)
        #else
            .frame(width: 24, height: 24)
        #endif
            .padding(6)
        #if os(iOS)
            .padding(4)
            .foregroundStyle(.black)
        #endif
    }
}

// MARK: - Previews
#Preview
{
    ZStack
    {
        Rectangle()
            .foregroundStyle(.white)
            .frame(width: 320, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 16)
        
        Rectangle()
            .foregroundStyle(.mint.opacity(0.25))
            .modifier(ViewCloseButton(is_presented: .constant(true)))
            .frame(width: 320, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    .padding(32)
}

#Preview
{
    @Previewable @State var is_presented: Bool = false
    
    VStack()
    {
        Button("View Sheet")
        {
            is_presented = true
        }
        .sheet(isPresented: $is_presented)
        {
            Rectangle()
                .foregroundStyle(.mint.opacity(0.25))
                .frame(width: 320, height: 240)
                .modifier(ViewCloseButton(is_presented: .constant(true)))
        }
    }
    .frame(width: 640, height: 480)
}

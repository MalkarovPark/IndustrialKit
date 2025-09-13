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
                        .imageScale(.large)
                        .frame(width: 16, height: 16)
                    #if os(iOS)
                        .padding(6)
                        .foregroundStyle(.black)
                    #endif
                }
                .keyboardShortcut(.cancelAction)
                .buttonBorderShape(.circle)
                #if os(macOS)
                .buttonStyle(.glass)
                #elseif os(iOS)
                .glassEffect(.regular.interactive())
                #else
                .glassBackgroundEffect()
                #endif
                .padding(8)
                #if !os(macOS)
                .padding(.top, 4)
                #endif
                #if !os(visionOS)
                .controlSize(.extraLarge)
                #endif
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
                        .imageScale(.large)
                    #if os(macOS)
                        .frame(width: 16, height: 16)
                    #else
                        .frame(width: 24, height: 24)
                    #endif
                        .padding(6)
                    #if os(iOS)
                        .padding(6)
                        .foregroundStyle(.black)
                    #endif
                }
                .keyboardShortcut(.cancelAction)
                #if !os(visionOS)
                .modifier(CircleButtonGlassBorderer())
                #else
                .buttonBorderShape(.circle)
                .glassBackgroundEffect()
                #endif
                .keyboardShortcut(.cancelAction)
                .padding(8)
                #if !os(macOS)
                .padding(.top, 4)
                #endif
            }
    }
}

#if os(macOS) || os(iOS)
// MARK: - Glass Button Modifiers
public struct CircleButtonGlassBorderer: ViewModifier
{
    public func body(content: Content) -> some View
    {
        content
            .buttonBorderShape(.circle)
        #if os(macOS)
            .buttonStyle(.glass)
        #else
            .glassEffect(.regular.interactive())
        #endif
            //.padding()
    }
}

public struct CircleButtonImageFramer: ViewModifier
{
    public func body(content: Content) -> some View
    {
        content
            .imageScale(.large)
        #if os(macOS)
            .frame(width: 16, height: 16)
        #else
            .frame(width: 24, height: 24)
        #endif
            .padding(8)
        #if os(iOS)
            .padding(6)
            .foregroundStyle(.black)
        #endif
    }
}
#endif

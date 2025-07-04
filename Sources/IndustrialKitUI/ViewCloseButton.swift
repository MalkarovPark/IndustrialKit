//
//  ViewCloseButton.swift
//  IndustrialKit
//
//  Created by Artem on 06.11.2023.
//

import SwiftUI

//@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
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
                }
                .keyboardShortcut(.cancelAction)
                #if !os(iOS)
                .buttonStyle(.bordered)
                #else
                // .foregroundStyle(.primary)
                .modifier(ButtonBorderer())
                #endif
                #if os(visionOS)
                .buttonBorderShape(.circle)
                #endif
                .padding()
                #if os(visionOS)
                .padding(8)
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
                }
                #if !os(iOS)
                .buttonStyle(.bordered)
                #else
                // .foregroundStyle(.primary)
                .modifier(ButtonBorderer())
                #endif
                #if os(visionOS)
                .buttonBorderShape(.circle)
                #endif
                .keyboardShortcut(.cancelAction)
                .padding()
                #if os(visionOS)
                .padding(8)
                #endif
            }
    }
}

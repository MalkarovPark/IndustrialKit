//
//  SheetCaption.swift
//  IndustrialKit
//
//  Created by Artem Malkarov on 04.09.2024.
//

import SwiftUI

public struct SheetCaption: ViewModifier
{
    @Binding var is_presented: Bool
    
    let label: String
    
    public init(is_presented: Binding<Bool>, label: String)
    {
        self._is_presented = is_presented
        self.label = label
    }
    
    public func body(content: Content) -> some View
    {
        VStack(spacing: 0)
        {
            ZStack
            {
                HStack(alignment: .center)
                {
                    Text(label)
                        .padding(0)
                    #if os(visionOS)
                        .font(.title2)
                        .padding(.vertical)
                    #endif
                }
                
                HStack(spacing: 0)
                {
                    Button(action: { is_presented = false })
                    {
                        Image(systemName: "xmark")
                    }
                    .keyboardShortcut(.cancelAction)
                    #if !os(visionOS)
                    .buttonStyle(.borderless)
                    .controlSize(.extraLarge)
                    #else
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    #endif
                    .padding()
                    
                    Spacer()
                }
            }
            
            #if !os(visionOS)
            Divider()
            #endif
            
            content
        }
        #if os(macOS)
        .fitted()
        #endif
    }
}

extension View
{
    @ViewBuilder
    func fitted() -> some View
    {
        if #available(macOS 15.0, *)
        {
            self.presentationSizing(.fitted)
        }
    }
}

#Preview
{
    VStack()
    {
        EmptyView()
    }
    .frame(width: 320, height: 240)
    .modifier(SheetCaption(is_presented: .constant(true), label: "Text"))
}

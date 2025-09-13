//
//  SheetCaption.swift
//  IndustrialKit
//
//  Created by Artem on 04.09.2024.
//

import SwiftUI

public struct SheetCaption: ViewModifier
{
    @Binding var is_presented: Bool
    
    let label: String
    let plain: Bool
    
    public init(is_presented: Binding<Bool>, label: String = String(), plain: Bool = true)
    {
        self._is_presented = is_presented
        self.label = label
        self.plain = plain
    }
    
    public func body(content: Content) -> some View
    {
        ZStack(alignment: .top)//(spacing: 0)
        {
            if plain
            {
                VStack(spacing: 0)
                {
                    #if os(macOS)
                    Spacer(minLength: 52)
                    #elseif os(iOS)
                    Spacer(minLength: 70)
                    #else
                    Spacer(minLength: 56)
                    #endif
                    content
                }
            }
            else
            {
                content
            }
            
            ZStack
            {
                if plain
                {
                    HStack(alignment: .center)
                    {
                        Text(label)
                            .padding(0)
                            .font(.title3)
                        #if os(visionOS)
                            .font(.title2)
                            .padding(.vertical)
                        #endif
                    }
                    .padding(.horizontal, 8)
                    .padding(8)
                }
                else
                {
                    HStack(alignment: .center)
                    {
                        Text(label)
                            .padding(0)
                            .font(.title3)
                        #if os(visionOS)
                            .font(.title2)
                            .padding(.vertical)
                        #endif
                    }
                    .padding(.horizontal, 8)
                    .padding(8)
                    //.glassEffect()
                }
                
                HStack(spacing: 0)
                {
                    Button(action: { is_presented = false })
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
                            .padding(4)
                            .foregroundStyle(.black)
                        #endif
                    }
                    .keyboardShortcut(.cancelAction)
                    .modifier(CircleButtonGlassBorderer())
                    .keyboardShortcut(.cancelAction)
                    .padding(8)
                    #if !os(macOS)
                    .padding(.top, 4)
                    #endif
                    
                    Spacer()
                }
            }
            .background
            {
                if !plain
                {
                    Rectangle()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(.ultraThinMaterial)
                }
            }
        }
        /*content
            .navigationTitle(label)
            .toolbar
            {
                ToolbarItem(placement: .cancellationAction)
                {
                    Button("Dismiss", systemImage: "xmark")
                    {
                        is_presented = false
                    }
                }
            }*/
        #if os(macOS) || os(visionOS)
        .presentationSizing(.fitted)
        #endif
    }
}

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
            .modifier(SheetCaption(is_presented: .constant(true), label: "Label"))
            .frame(width: 320, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    .padding(32)
}

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
            .modifier(SheetCaption(is_presented: .constant(true), label: "Label", plain: false))
            .frame(width: 320, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    .padding(32)
}

// MARK: - Previews
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
                .modifier(SheetCaption(is_presented: $is_presented, label: "Label"))
        }
    }
    .frame(width: 640, height: 480)
}

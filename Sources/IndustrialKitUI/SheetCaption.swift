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
    let with_spacing: Bool
    
    public init(is_presented: Binding<Bool>, label: String = String(), caption_spacing: Bool = true)
    {
        self._is_presented = is_presented
        self.label = label
        self.with_spacing = caption_spacing
    }
    
    public func body(content: Content) -> some View
    {
        ZStack(alignment: .top)//(spacing: 0)
        {
            if with_spacing
            {
                VStack(spacing: 0)
                {
                    Spacer(minLength: 68)
                    content
                }
            }
            else
            {
                content
            }
            
            ZStack
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
                .glassEffect()
                
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
                    }
                    .keyboardShortcut(.cancelAction)
                    #if !os(visionOS)
                    .controlSize(.extraLarge)
                    #else
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    #endif
                    .buttonBorderShape(.circle)
                    .buttonStyle(.glass)
                    .padding()
                    
                    Spacer()
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
        .fitted()
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
    @Previewable @State var is_presented: Bool = false
    
    VStack()
    {
        Button("View Sheet")
        {
            is_presented = true
        }
        .sheet(isPresented: $is_presented)
        {
            //EmptyView()
            Rectangle()
                .foregroundStyle(.mint.opacity(0.25))
                .frame(width: 320, height: 240)
                .modifier(SheetCaption(is_presented: $is_presented, label: "Label"))
        }
    }
    .frame(width: 640, height: 480)
}

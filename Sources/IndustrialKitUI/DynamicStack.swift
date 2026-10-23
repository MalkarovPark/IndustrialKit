//
//  DynamicStack.swift
//  IndustrialKit
//
//  Created by Artem on 11.11.2024.
//

import SwiftUI

public struct DynamicStack<Content: View>: View
{
    @ViewBuilder var content: () -> Content
    
    @Binding var is_vertical: Bool
    
    var horizontal_alignment = HorizontalAlignment.center
    var vertical_alignment = VerticalAlignment.center
    var spacing: CGFloat?
    
    public init(
        is_vertical: Binding<Bool>,
        horizontal_alignment: HorizontalAlignment = .center,
        vertical_alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    )
    {
        self.horizontal_alignment = horizontal_alignment
        self.vertical_alignment = vertical_alignment
        self.spacing = spacing
        self._is_vertical = is_vertical
        self.content = content
    }
    
    public var body: some View
    {
        if is_vertical
        {
            VStack(alignment: horizontal_alignment, spacing: spacing, content: content)
        }
        else
        {
            HStack(alignment: vertical_alignment, spacing: spacing, content: content)
        }
    }
}

#Preview
{
    @Previewable @State var is_vertical = false
    DynamicStack(is_vertical: $is_vertical, spacing: 16)
    {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.cyan)
        
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.mint)
        
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.indigo)
    }
    .padding()
    .overlay(alignment: .bottomLeading)
    {
        Button(is_vertical ? "Vertical" : "Horizontal")
        {
            is_vertical.toggle()
        }
        .buttonStyle(.glass)
        .padding(32)
    }
}

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
    
    @Binding var is_compact: Bool
    
    var horizontal_alignment = HorizontalAlignment.center
    var vertical_alignment = VerticalAlignment.center
    var spacing: CGFloat?
    
    public init(
        @ViewBuilder content: @escaping () -> Content,
        is_compact: Binding<Bool>,
        horizontal_alignment: HorizontalAlignment = .center,
        vertical_alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil
    )
    {
        self.horizontal_alignment = horizontal_alignment
        self.vertical_alignment = vertical_alignment
        self.spacing = spacing
        self._is_compact = is_compact
        self.content = content
    }
    
    public var body: some View
    {
        if is_compact
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
    DynamicStack(content: {
        Rectangle()
            .fill(Color.cyan)
            .padding(.trailing)
        
        Rectangle()
            .fill(Color.mint)
    }, is_compact: .constant(false), spacing: 0)
    .padding()
}

#Preview
{
    DynamicStack(content: {
        Rectangle()
            .fill(Color.cyan)
            .padding(.bottom)
        
        Rectangle()
            .fill(Color.mint)
    }, is_compact: .constant(true), spacing: 0)
    .padding()
}

//
//  DynamicStack.swift
//  IndustrialKit
//
//  Created by Artem on 11.11.2024.
//

import SwiftUI

struct DynamicStack<Content: View>: View
{
    @ViewBuilder var content: () -> Content
    
    @Binding var is_compact: Bool
    
    var horizontal_alignment = HorizontalAlignment.center
    var vertical_alignment = VerticalAlignment.center
    var spacing: CGFloat?
    
    var body: some View
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

//
//  ProgramItemView.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI

public struct ProgramItemView: View
{
    @Binding var name: String
    
    let count: Int
    
    let index: Int?
    
    let on_update: () -> Void
    let on_duplicate: () -> Void
    let on_delete: () -> Void
    
    @State private var to_rename = false
    @State private var new_name = String()
    
    @FocusState private var is_focused: Bool
    
    public init(
        name: Binding<String>,
        count: Int,
        index: Int? = nil,
        
        on_update: @escaping () -> Void,
        on_duplicate: @escaping () -> Void,
        on_delete: @escaping () -> Void
    )
    {
        self._name = name
        self.count = count
        self.index = index
        
        self.on_update = on_update
        self.on_duplicate = on_duplicate
        self.on_delete = on_delete
    }
    
    public var body: some View
    {
        HStack
        {
            if !to_rename
            {
                Text(name)
                #if os(macOS)
                    .font(.system(size: 16, design: .rounded))
                #else
                    .font(.system(size: 18, design: .rounded))
                #endif
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.leading, 16)
            }
            else
            {
                TextField("Name", text: $new_name)
                    .textFieldStyle(.plain)
                    .focused($is_focused)
                    .labelsHidden()
                    .padding(.leading, 16)
                    .onSubmit
                    {
                        name = new_name
                        to_rename = false
                    }
                #if os(macOS)
                    .onExitCommand
                    {
                        to_rename = false
                    }
                #endif
                    .onAppear
                    {
                        is_focused = true
                    }
                    .onChange(of: is_focused)
                    { _, new_value in
                        if !new_value
                        {
                            to_rename = false
                        }
                    }
            }
            
            Spacer()
            
            AdaptiveDotGrid(count: count, square_size: 24)
                .frame(width: 48, height: 48)
        }
        .overlay(alignment: .topLeading)
        {
            if let index
            {
                Text("\(index)")
                    .font(.system(size: program_index_font_size))
                    .foregroundStyle(.tertiary)
                    .frame(height: 20)
                    .lineLimit(1)
                    .padding(.leading, 6)
                    .allowsHitTesting(false)
            }
        }
        .background
        {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
            #if !os(visionOS)
                .fill(.quinary)
            #else
                .fill(.thinMaterial)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: 64)
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
        .contextMenu
        {
            Button
            {
                on_duplicate()
                on_update()
            }
            label:
            {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            
            Button("Rename", systemImage: "pencil")
            {
                to_rename = true
                new_name = name
            }
            
            Divider()
            
            Button(role: .destructive)
            {
                on_delete()
                on_update()
            }
            label:
            {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Sizes
#if os(macOS)
let program_item_height: CGFloat = 36
let program_item_light_size: CGFloat = 8
let program_item_light_padding: CGFloat = 12

let program_index_font_size: CGFloat = 10
#elseif os(iOS)
let program_item_height: CGFloat = 48
let program_item_light_size: CGFloat = 10
let program_item_light_padding: CGFloat = 12

let program_index_font_size: CGFloat = 10
#elseif os(visionOS)
let program_item_height: CGFloat = 48
let program_item_light_size: CGFloat = 12
let program_item_light_padding: CGFloat = 12

let program_index_font_size: CGFloat = 10
#endif

// MARK: - Preview
#Preview
{
    @Previewable @State var name: String = "Test"
    
    ProgramItemView(name: $name, count: 4, on_update: {}, on_duplicate: {}, on_delete: {})
        .padding(.horizontal, 8)
        .frame(width: pendant_content_width)
}

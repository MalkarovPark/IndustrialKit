//
//  NewElementButton.swift
//  IndustrialKit
//
//  Created by Artem on 22.02.2026.
//

import SwiftUI
import IndustrialKit

public struct NewElementButton: View
{
    private var with_name: Bool = true
    
    @Binding var is_expanded: Bool
    @State private var new_item_name = ""
    
    private var add_name_action: (String) -> Void
    private var names: [String]?
    
    private var add_action: () -> ()
    
    public init(
        with_name: Bool = false,
        
        is_expanded: Binding<Bool>,
        
        names: [String]? = nil,
        
        add_name_action: @escaping (String) -> Void = { _ in },
        add_action: @escaping () -> () = {}
    )
    {
        self.with_name = with_name
        
        self._is_expanded = is_expanded
        
        self.names = names
        
        self.add_name_action = add_name_action
        self.add_action = add_action
    }
    
    @Namespace private var glass_pane
    @FocusState private var is_focused: Bool
    
    public var body: some View
    {
        HStack
        {
            if !is_expanded { Spacer() }
            
            HStack(spacing: 0)
            {
                if is_expanded
                {
                    // Editor
                    TextField("Name", text: $new_item_name)
                        .frame(maxWidth: .infinity)
                        .textFieldStyle(.plain)
                        .padding(.leading, 14)
                        .focused($is_focused)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75))
                        {
                            is_expanded = false
                            new_item_name = .init()
                        }
                    })
                    {
                        Image(systemName: "xmark")
                            .padding(.horizontal, 6)
                        #if os(iOS)
                            .opacity(0.5)
                        #endif
                    }
                    #if !os(iOS)
                    .buttonStyle(.borderless)
                    #else
                    .buttonStyle(.plain)
                    #endif
                    .buttonBorderShape(.circle)
                    .contentShape(Circle())
                    .keyboardShortcut(.cancelAction)
                }
                
                // Button
                Button(action:
                { withAnimation(.spring(response: 0.35, dampingFraction: 0.75))
                    {
                        if is_expanded
                        {
                            is_expanded = false
                            name_process()
                            
                            is_focused = false
                        }
                        else
                        {
                            if with_name
                            {
                                is_expanded = true
                                
                                is_focused = true
                            }
                            else
                            {
                                add_action()
                            }
                        }
                    }
                })
                {
                    Image(systemName: is_expanded ? "checkmark" : "plus")
                    #if os(macOS)
                        .padding(.horizontal, 9.25)
                    #elseif os(iOS)
                        .padding(.horizontal, 10.5)
                        .opacity(0.5)
                    #elseif os(visionOS)
                        .padding(.horizontal, 11.25)
                    #endif
                }
                #if !os(iOS)
                .buttonStyle(.borderless)
                #else
                .buttonStyle(.plain)
                #endif
                .buttonBorderShape(.circle)
                .keyboardShortcut(is_expanded ? .defaultAction : nil)
            }
            .clipShape(.capsule(style: .continuous))
            #if os(macOS)
            .frame(height: 36)
            #else
            .frame(height: 44)
            #endif
            #if !os(visionOS)
            .imageScale(.large)
            #endif
            .glassEffect(.regular.interactive(), in: .capsule(style: .continuous))
            #if os(macOS) || os(iOS)
            .padding(10)
            #else
            .padding(16)
            #endif
        }
    }
    
    private func name_process()
    {
        if new_item_name.isEmpty
        {
            new_item_name = "Name"
        }
        
        if names != nil
        {
            new_item_name = unique_name(for: new_item_name, in: names!)
        }
        
        add_name_action(new_item_name)
        new_item_name = ""
    }
}

#Preview
{
    @Previewable @State var is_expanded = false
    
    ZStack
    {
        NewElementButton(with_name: true, is_expanded: $is_expanded, add_name_action: { new_name in print(new_name) })
    }
    .frame(width: 256)
}

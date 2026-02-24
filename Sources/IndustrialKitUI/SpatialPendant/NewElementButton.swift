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
    //@State private var is_expanded = false
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
    
    @Namespace private var pane_glass
    
    public var body: some View
    {
        GlassEffectContainer
        {
            HStack(spacing: 0)
            {
                if !is_expanded
                {
                    Spacer()
                    
                    // Button
                    Button(action: { withAnimation(/*.spring(response: 0.35, dampingFraction: 0.85)*/)
                        {
                            if with_name
                            {
                                is_expanded = true
                            }
                            else
                            {
                                add_action()
                            }
                        }
                    })
                    {
                        Image(systemName: "plus")
                            .modifier(CircleButtonImageFramer())
                    }
                    .modifier(CircleButtonGlassBorderer())
                    #if os(macOS) || os(iOS)
                    .padding(10)
                    #else
                    .padding(16)
                    #endif
                }
                else
                {
                    // Editor
                    HStack(spacing: 0)
                    {
                        TextField("Name", text: $new_item_name)
                            .frame(maxWidth: .infinity)
                            .textFieldStyle(.plain)
                            .padding(.leading, 14)
                        
                        Button(action: {
                            withAnimation(/*.spring(response: 0.35, dampingFraction: 0.75)*/)
                            {
                                is_expanded = false
                                name_process()
                            }
                        })
                        {
                            Image(systemName: "checkmark")
                                .modifier(CircleButtonImageFramer())
                        }
                        .buttonStyle(.plain)
                        .buttonBorderShape(.circle)
                        .contentShape(Circle())
                        .keyboardShortcut(.defaultAction)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75))
                            {
                                is_expanded = false
                            }
                        })
                        {
                            Image(systemName: "xmark")
                                .modifier(CircleButtonImageFramer())
                        }
                        .buttonStyle(.plain)
                        .buttonBorderShape(.circle)
                        .contentShape(Circle())
                        .padding(.trailing, 6)
                    }
                    #if os(macOS)
                    .frame(height: 36)
                    #else
                    .frame(height: 44)
                    #endif
                    .imageScale(.large)
                    .glassEffect(.regular.interactive(), in: .capsule(style: .continuous))
                    .matchedGeometryEffect(id: "glass", in: pane_glass)
                    #if os(macOS) || os(iOS)
                    .padding(10)
                    #else
                    .padding(16)
                    #endif
                }
            }
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
            new_item_name = mismatched_name(name: new_item_name, names: names!)
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
        NewElementButton(with_name: true, is_expanded: $is_expanded)
            //.border(.gray)
            //.padding()
    }
    .frame(width: 256)
}

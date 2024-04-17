//
//  AddNewView.swift
//  IndustrialKit
//
//  Created by Artem on 12.04.2024.
//

import SwiftUI

public struct AddNewView: View
{
    @Binding var is_presented: Bool
    
    @State private var new_item_name = ""
    
    private var on_item_add: (String) -> Void
    private var names: [String]?
    
    public init(is_presented: Binding<Bool>, on_item_add: @escaping (String) -> Void)
    {
        self._is_presented = is_presented
        self.on_item_add = on_item_add
    }
    
    public init(is_presented: Binding<Bool>, names: [String], on_item_add: @escaping (String) -> Void)
    {
        self._is_presented = is_presented
        self.on_item_add = on_item_add
        self.names = names
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            TextField("Name", text: $new_item_name)
                .padding(.trailing)
                .frame(minWidth: 96)
            
            Button("Add")
            {
                name_perform()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }
    
    private func name_perform()
    {
        if new_item_name == ""
        {
            new_item_name = "Name"
        }
        
        if names != nil
        {
            new_item_name = mismatched_name(name: new_item_name, names: names!)
        }
        
        on_item_add(new_item_name)
        is_presented = false
    }
}

#Preview
{
    AddNewView(is_presented: .constant(true), on_item_add: { _ in })
}

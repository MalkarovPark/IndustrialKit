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
    
    private var add_item: (String) -> Void
    private var names: [String]?
    
    public init(is_presented: Binding<Bool>, add_item: @escaping (String) -> Void)
    {
        self._is_presented = is_presented
        self.add_item = add_item
    }
    
    public init(is_presented: Binding<Bool>, names: [String], add_item: @escaping (String) -> Void)
    {
        self._is_presented = is_presented
        self.add_item = add_item
        self.names = names
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            TextField("Name", text: $new_item_name)
                .padding(.trailing)
                .frame(minWidth: 128, maxWidth: 256)
            #if os(iOS) || os(visionOS)
                .frame(idealWidth: 256)
                .textFieldStyle(.roundedBorder)
            #endif
            
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
        
        add_item(new_item_name)
        is_presented = false
    }
}

#Preview
{
    AddNewView(is_presented: .constant(true), add_item: { _ in })
}

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
    
    @State private var new_file_name = ""
    
    private var add_file: (String) -> Void
    private var names: [String]?
    
    public init(is_presented: Binding<Bool>, add_file: @escaping (String) -> Void)
    {
        self._is_presented = is_presented
        self.add_file = add_file
    }
    
    public init(is_presented: Binding<Bool>, names: [String], add_file: @escaping (String) -> Void)
    {
        self._is_presented = is_presented
        self.add_file = add_file
        self.names = names
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            TextField("Name", text: $new_file_name)
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
        if new_file_name == ""
        {
            new_file_name = "Name"
        }
        
        if names != nil
        {
            new_file_name = mismatched_name(name: new_file_name, names: names!)
        }
        
        add_file(new_file_name)
        is_presented = false
    }
}

#Preview
{
    AddNewView(is_presented: .constant(true), add_file: { _ in })
}

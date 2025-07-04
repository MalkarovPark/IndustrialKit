//
//  ControlProgramTextView.swift
//  IndustrialKit
//
//  Created by Artem Malkarov on 23.06.2025.
//

import SwiftUI
import IndustrialKit

public struct ControlProgramTextView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    @State private var code_editor_text: String
    
    public init(elements: Binding<[WorkspaceProgramElement]>)
    {
        self._elements = elements
        self._code_editor_text = State(initialValue: elements_to_code(elements: elements.wrappedValue))
    }
    
    public var body: some View
    {
        let code_binding = Binding<String>(
            get: { code_editor_text },
            set:
                { new_value in
                    code_editor_text = new_value
                    elements = code_to_elements(code: new_value)
                }
        )
        
        return VStack
        {
            TextEditor(text: code_binding)
                .textFieldStyle(.plain)
                .font(.custom("Menlo", size: 12))
        }
    }
}

#Preview
{
    ControlProgramTextView(elements: .constant([WorkspaceProgramElement]()))
}

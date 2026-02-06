//
//  LogicElementsViews.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 26.11.2023.
//

import SwiftUI
import IndustrialKit

public struct JumpElementView: View
{
    @ObservedObject var element: JumpLogicElement
    
    @ObservedObject var workspace: Workspace
    
    let on_update: () -> ()
    
    @State private var picker_is_presented = false
    
    public init(
        element: JumpLogicElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        self.workspace = workspace
        
        self.on_update = on_update
        
        if self.workspace.marks_names.count > 0 && self.element.target_mark_name == ""
        {
            self.element.target_mark_name = self.workspace.marks_names[0]
        }
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            HStack
            {
                let target_mark_name = Binding(
                    get: { element.target_mark_name },
                    set:
                        { new_value in
                            element.target_mark_name = new_value
                            
                            on_update()
                        }
                )
                
                #if !os(macOS)
                Text("Jump to")
                #endif
                
                Picker("Jump to", selection: target_mark_name) // Target mark picker
                {
                    if workspace.marks_names.count > 0
                    {
                        ForEach(workspace.marks_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    else
                    {
                        Text("None")
                    }
                }
                .onAppear
                {
                    
                }
                .buttonStyle(.bordered)
                .disabled(workspace.marks_names.count == 0)
            }
        }
    }
}

public struct ComparatorElementView: View
{
    @ObservedObject var element: ComparatorLogicElement
    @ObservedObject var workspace: Workspace
    
    private let on_update: () -> ()
    
    @State private var picker_is_presented = false
    
    public init(
        element: ComparatorLogicElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        self.workspace = workspace
        
        self.on_update = on_update
        
        if self.workspace.marks_names.count > 0 && self.element.target_mark_name == ""
        {
            self.element.target_mark_name = self.workspace.marks_names[0]
        }
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            HStack(spacing: 8)
            {
                let value_index = Binding(
                    get: { [element.value_index] },
                    set:
                        { new_value in
                            //element.value_index = new_value[0]
                            if let first = new_value.first
                            {
                                element.value_index = first
                                on_update()
                            }
                        }
                )
                
                let value2_index = Binding(
                    get: { [element.value2_index] },
                    set:
                        { new_value in
                            //element.value2_index = new_value[0]
                            if let first = new_value.first
                            {
                                element.value2_index = first
                                on_update()
                            }
                        }
                )
                
                let compare_type = Binding(
                    get: { element.compare_type },
                    set:
                        { new_value in
                            element.compare_type = new_value
                            
                            on_update()
                        }
                )
                
                Text("If value of")
                    .frame(minWidth: 60)
                
                RegistersSelector(text: "\(element.value_index)", registers_count: workspace.registers.count, colors: registers_colors, indices: value_index, names: ["Value 1"])
                
                Button(element.compare_type.rawValue)
                {
                    picker_is_presented = true
                }
                .popover(isPresented: $picker_is_presented)
                {
                    CompareTypePicker(compare_type: compare_type)
                    #if !os(macOS)
                        .presentationDetents([.height(96)])
                    #endif
                }
                
                Text("value of")
                    .frame(minWidth: 48)
                
                RegistersSelector(text: "\(element.value2_index)", registers_count: workspace.registers.count, colors: registers_colors, indices: value2_index, names: ["Value 2"])
            }
            .padding(.bottom)
            
            HStack
            {
                let target_mark_name = Binding(
                    get: { element.target_mark_name },
                    set:
                        { new_value in
                            element.target_mark_name = new_value
                            
                            on_update()
                        }
                )
                
                #if !os(macOS)
                Text("jump to")
                #endif
                
                Picker("jump to", selection: target_mark_name) // Target mark picker
                {
                    if workspace.marks_names.count > 0
                    {
                        ForEach(workspace.marks_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    else
                    {
                        Text("None")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(workspace.marks_names.count == 0)
            }
        }
    }
}

public struct CompareTypePicker: View
{
    @Binding var compare_type: CompareType
    
    public init(compare_type: Binding<CompareType>)
    {
        self._compare_type = compare_type
    }
    
    public var body: some View
    {
        Picker("Compare", selection: $compare_type)
        {
            ForEach(CompareType.allCases, id: \.self)
            { compare_type in
                Text(compare_type.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding()
    }
}

public struct MarkLogicElementView: View
{
    @ObservedObject var element: MarkLogicElement
    
    @ObservedObject var workspace: Workspace
    
    let on_update: () -> ()
    
    public init(
        element: MarkLogicElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        self.workspace = workspace
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        let name = Binding(
            get: { element.name },
            set:
                { new_value in
                    element.name = new_value
                    
                    on_update()
                }
        )
        
        HStack
        {
            Text("Name")
            TextField("Mark Name", text: name) // Mark name field
                .textFieldStyle(.roundedBorder)
        }
    }
}

//MARK: - Previews
struct IMALogicPreviewsContainer: PreviewProvider
{
    static var previews: some View
    {
        LogicContainer()
    }

    struct LogicContainer: View
    {
        @StateObject var workspace = Workspace()

        var body: some View
        {
            LogicView(workspace: workspace)
                .onAppear
                {
                    workspace.elements.append(MarkLogicElement(name: "Mark"))
                }
        }
    }

    struct LogicView: View
    {
        @ObservedObject var workspace: Workspace
        //var mark = MarkLogicElement(name: "Mark")
        
        var body: some View
        {
            VStack(alignment: .leading, spacing: 8)
            {
                /*Text("Logic")
                    .font(.custom("Line Seed Sans", size: 20))
                    .foregroundStyle(.gray)
                    .fontWeight(.medium)
                    .opacity(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .top], 8)*/
                
                HStack(alignment: .top)
                {
                    ComparatorElementView(element: ComparatorLogicElement(), workspace: workspace)
                        .modifier(PreviewBorder())

                    MarkLogicElementView(element: workspace.elements.first as? MarkLogicElement ?? MarkLogicElement(), workspace: workspace)
                        .modifier(PreviewBorder())
                }
            }
            .padding()
        }
    }
    
    private struct PreviewBorder: ViewModifier
    {
        public func body(content: Content) -> some View
        {
            content
                .padding()
                .frame(width: 256)
                .background(.bar)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 8)
                .padding()
        }
    }
}


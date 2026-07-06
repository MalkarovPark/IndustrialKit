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
    
    @ObservedObject var program: ProductionProgram
    
    let on_update: () -> ()
    
    public init(
        element: JumpLogicElement,
        program: ProductionProgram,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        self.program = program
        
        self.on_update = on_update
        
        if self.program.mark_names.filter({ !$0.isEmpty }).count > 0 && self.element.target_mark_name.isEmpty
        {
            self.element.target_mark_name = self.program.mark_names[0]
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
                    if program.mark_names.count > 0
                    {
                        ForEach(program.mark_names, id: \.self)
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
                .disabled(program.mark_names.count == 0)
            }
        }
    }
}

public struct ComparatorElementView: View
{
    @ObservedObject var element: ComparatorLogicElement
    @ObservedObject var workspace: Workspace
    @ObservedObject var program: ProductionProgram
    
    private let on_update: () -> ()
    
    #if os(macOS)
    private let registers_selector_width: CGFloat = 40
    #elseif os(iOS)
    private let registers_selector_width: CGFloat = 56
    #elseif os(visionOS)
    private let registers_selector_width: CGFloat = 72
    #endif
    
    public init(
        element: ComparatorLogicElement,
        workspace: Workspace,
        program: ProductionProgram,
        
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        self.workspace = workspace
        self.program = program
        
        self.on_update = on_update
        
        if self.program.mark_names.filter({ !$0.isEmpty }).count > 0 && self.element.target_mark_name.isEmpty
        {
            self.element.target_mark_name = self.program.mark_names[0]
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
                
                RegistersSelector(text: "\(element.value_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: value_index, names: ["Value 1"])
                    .frame(width: registers_selector_width)
                
                CompareTypePicker(compare_type: compare_type)
                
                Text("value of")
                
                RegistersSelector(text: "\(element.value2_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: value2_index, names: ["Value 2"])
                    .frame(width: registers_selector_width)
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
                    if program.mark_names.count > 0
                    {
                        ForEach(program.mark_names, id: \.self)
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
                .disabled(program.mark_names.count == 0)
            }
        }
    }
}

public struct CompareTypePicker: View
{
    @Binding var compare_type: CompareType
    
    @State private var picker_is_presented = false
    
    public init(compare_type: Binding<CompareType>)
    {
        self._compare_type = compare_type
    }
    
    public var body: some View
    {
        Button
        {
            picker_is_presented = true
        }
        label:
        {
            Image(systemName: compare_type.rawValue)
            #if os(macOS)
                .frame(width: 16, height: 16)
            #elseif os(iOS)
                .frame(width: 20, height: 20)
            #elseif os(visionOS)
                .frame(width: 20, height: 20)
            #endif
        }
        .popover(isPresented: $picker_is_presented)
        {
            Picker("Compare", selection: $compare_type)
            {
                ForEach(CompareType.allCases, id: \.self)
                { compare_type in
                    Image(systemName: compare_type.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()
            #if os(iOS)
            .presentationDetents([.height(96)])
            #endif
        }
        .buttonBorderShape(.circle)
        .buttonStyle(.bordered)
    }
}

public struct MarkLogicElementView: View
{
    @ObservedObject var element: MarkLogicElement
    @ObservedObject var workspace: Workspace
    @ObservedObject var program: ProductionProgram
    
    let on_update: () -> ()
    
    public init(
        element: MarkLogicElement,
        workspace: Workspace,
        program: ProductionProgram,
        
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        self.workspace = workspace
        self.program = program
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        let name = Binding(
            get: { element.name },
            set:
                { new_value in
                    element.name = new_value
                }
        )
        
        HStack
        {
            Text("Name")
            TextField("None", text: name)
                .textFieldStyle(.roundedBorder)
                .onSubmit
                {
                    workspace.elements_check(program: program)
                    
                    on_update()
                }
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
                    workspace.programs.append(ProductionProgram(name: "Program"))
                    workspace.select_program(named: "Program")
                    
                    if let selected_program = workspace.selected_program
                    {
                        selected_program.elements.append(JumpLogicElement())
                        selected_program.elements.append(ComparatorLogicElement())
                        selected_program.elements.append(MarkLogicElement(name: "Mark"))
                    }
                }
        }
    }
    
    struct LogicView: View
    {
        @ObservedObject var workspace: Workspace
        
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
                
                VStack
                {
                    if let selected_program = workspace.selected_program
                    {
                        if let element = selected_program.elements[0] as? JumpLogicElement,
                           let element2 = selected_program.elements[1] as? ComparatorLogicElement,
                           let element3 = selected_program.elements[2] as? MarkLogicElement
                        {
                            JumpElementView(element: element, program: selected_program)
                                .modifier(PreviewBorder())
                            
                            ComparatorElementView(element: element2, workspace: workspace, program: selected_program)
                                .modifier(PreviewBorder())
                            
                            MarkLogicElementView(element: element3, workspace: workspace, program: selected_program)
                                .modifier(PreviewBorder())
                        }
                    }
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
                .frame(width: element_control_width)
                .padding()
                .background(.bar)
            #if !os(visionOS)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 8)
            #else
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            #endif
                .padding()
        }
    }
}


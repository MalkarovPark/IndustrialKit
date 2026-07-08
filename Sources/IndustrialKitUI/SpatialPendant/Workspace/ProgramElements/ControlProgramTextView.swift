//
//  ControlProgramTextView.swift
//  IndustrialKit
//
//  Created by Artem on 23.06.2025.
//

import SwiftUI
import IndustrialKit

public struct ControlProgramTextView: View
{
    @ObservedObject var program: ProductionProgram
    @ObservedObject var workspace: Workspace
    
    @Binding var code_editor_text: String
    //@State private var code_editor_text: String = ""
    
    /*public init(program: ProductionProgram, workspace: Workspace)
    {
        self.program = program
        self.workspace = workspace
    }*/
    
    public var body: some View
    {
        VStack
        {
            TextEditor(text: $code_editor_text)
                .textFieldStyle(.plain)
            #if os(macOS)
                .font(.custom("Menlo", size: 12))
            #else
                .font(.custom("Menlo", size: 16))
            #endif
        }
        .onAppear
        {
            code_editor_text = program.code
        }
        .onDisappear
        {
            program.code = code_editor_text
        }
    }
}

// MARK: - Previews
struct ControlTextView_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var workspace = Workspace()
        
        @State private var code_editor_text = ""
        
        var body: some View
        {
            HStack(spacing: 16)
            {
                if let selected_program = workspace.selected_program
                {
                    VStack
                    {
                        ProgramPreviewView(workspace: workspace, program: selected_program)
                        //ControlProgramTextView(program: selected_program)
                    }
                    .modifier(ViewBorderer())
                    
                    VStack
                    {
                        ControlProgramTextView(program: selected_program, workspace: workspace, code_editor_text: $code_editor_text)
                            .overlay(alignment: .bottomLeading)
                            {
                                VStack
                                {
                                    Button
                                    {
                                        if let selected_program = workspace.selected_program
                                        {
                                            selected_program.code = code_editor_text
                                        }
                                    }
                                    label:
                                    {
                                        Image(systemName: "chevron.left")
                                            .frame(width: 2, height: 16)
                                    }
                                    .buttonStyle(.bordered)
                                    #if !os(macOS)
                                    .buttonBorderShape(.circle)
                                    #endif
                                    
                                    Button
                                    {
                                        if let selected_program = workspace.selected_program
                                        {
                                            code_editor_text = selected_program.code
                                        }
                                    }
                                    label:
                                    {
                                        Image(systemName: "chevron.right")
                                            .frame(width: 2, height: 16)
                                    }
                                    .buttonStyle(.bordered)
                                    #if !os(macOS)
                                    .buttonBorderShape(.circle)
                                    #endif
                                }
                                .padding(10)
                            }
                    }
                    .modifier(ViewBorderer())
                }
            }
            .padding()
            .frame(width: 440)
            .onAppear
            {
                let robot = Robot(name: "6DOF Robot")
                robot.is_placed = true
                robot.add_program(PositionProgram(name: "Square"))
                
                let tool = Tool(name: "Gripper")
                tool.is_placed = true
                tool.add_program(OperationProgram(name: "Bite"))
                
                let tool2 = Tool(name: "Sensor")
                tool2.is_placed = true
                
                workspace.robots.append(robot)
                workspace.tools.append(tool)
                workspace.tools.append(tool2)
                
                workspace.programs.append(ProductionProgram(name: "Program"))
                workspace.select_program(named: "Program")
                
                Changer.internal_modules.append(ChangerModule(name: "Module"))
                Changer.internal_modules_list.append("Random")
                
                Changer.external_modules.append(ChangerModule(name: "Module"))
                Changer.external_modules_list.append("Defaults")
            }
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    private struct ProgramPreviewView: View
    {
        @ObservedObject var workspace: Workspace
        
        @ObservedObject var program: ProductionProgram
        
        @State private var dragging_element_id: UUID?
        
        private let columns: [GridItem] = [.init(.adaptive(minimum: element_card_maximum, maximum: element_card_maximum), spacing: 0)]
        
        var body: some View
        {
            VStack
            {
                ScrollView
                {
                    LazyVGrid(columns: columns, spacing: element_card_spacing)
                    {
                        ForEach($program.elements)
                        { $element in
                            ElementItemView(
                                workspace: workspace,
                                program: program,
                                element: element,
                                on_update: {}
                            )
                            {
                                if let index = program.elements.firstIndex(where: { $0.id == element.id })
                                {
                                    workspace.reset_performing()
                                    program.elements.remove(at: index)
                                    workspace.elements_check(program: program)
                                }
                            }
                            .onDrag
                            {
                                workspace.reset_performing()
                                
                                dragging_element_id = element.id
                                return NSItemProvider(object: element.id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: ElementDropDelegate(
                                    workspace: workspace,
                                    program: program,
                                    
                                    current_element: element,
                                    dragging_element_id: $dragging_element_id,
                                    
                                    on_update: {}
                                )
                            )
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if !os(visionOS)
            .background(.white)
            #else
            .background(.thickMaterial)
            #endif
            .overlay(alignment: .bottomLeading)
            {
                Menu
                {
                    Section(header: Text("Performer"))
                    {
                        ForEach(PerformerType.allCases, id: \.self)
                        { type in
                            Button(type.rawValue)
                            {
                                workspace.selected_program?.add_element(type.element)
                            }
                            .tag(type)
                        }
                    }
                    
                    Section(header: Text("Modifier"))
                    {
                        ForEach(ModifierType.allCases, id: \.self)
                        { type in
                            Button(type.rawValue)
                            {
                                workspace.selected_program?.add_element(type.element)
                            }
                            .tag(type)
                        }
                    }
                    
                    Section(header: Text("Logic"))
                    {
                        ForEach(LogicType.allCases, id: \.self)
                        { type in
                            Button(type.rawValue)
                            {
                                workspace.selected_program?.add_element(type.element)
                            }
                            .tag(type)
                        }
                    }
                }
                label:
                {
                    Image(systemName: "plus")
                }
                .pickerStyle(.menu)
                .buttonStyle(.bordered)
                #if !os(macOS)
                .buttonBorderShape(.circle)
                #endif
                .padding(10)
            }
        }
    }
}

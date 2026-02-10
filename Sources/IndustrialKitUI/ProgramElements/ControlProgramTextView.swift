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
            HStack
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
                let robot = Robot(name: "6DOF")
                robot.is_placed = true
                robot.add_program(PositionProgram(name: "Square"))
                
                let tool = Tool(name: "Gripper")
                tool.is_placed = true
                tool.add_program(OperationProgram(name: "Close"))
                
                workspace.robots.append(robot)
                workspace.tools.append(tool)
                
                workspace.programs.append(ProductionProgram(name: "Program"))
                workspace.select_program(name: "Program")
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
        
        @State private var view_program_as_text = false
        
        var body: some View
        {
            VStack
            {
                if !view_program_as_text
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
                                    element: element
                                )
                                { if let index = program.elements.firstIndex(where: { $0.id == element.id })
                                    {
                                        program.elements.remove(at: index)
                                        workspace.elements_check(program: program)
                                    }
                                }
                                .onDrag
                                {
                                    dragging_element_id = element.id
                                    return NSItemProvider(object: element.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text], delegate: ElementDropDelegate(current_element: element, program: program, dragging_element_id: $dragging_element_id, workspace: workspace))
                                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                            }
                        }
                        #if os(macOS)
                        .padding(.vertical, 16)//.padding(8)
                        #else
                        .padding(.vertical, 16)//.padding(8)
                        #endif
                    }
                }
                else
                {
                    //ControlProgramTextView(program: program, workspace: workspace, code_editor_text: $code_editor_text)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white)
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
                .padding(10)
            }
        }
    }
    
    private struct ElementItemView: View
    {
        @ObservedObject var workspace: Workspace
        @ObservedObject var program: ProductionProgram
        @ObservedObject var element: WorkspaceProgramElement
        
        @State private var element_view_presented = false
        
        #if os(iOS)
        @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
        #endif
        
        let on_delete: () -> ()
        
        var body: some View
        {
            ZStack
            {
                Rectangle()
                    .fill(element.color.opacity(0.25))
                
                Image(systemName: element.symbol_name)
                    .foregroundStyle(element.color)
                    .font(.system(size: element_card_font_size))
                    .frame(width: 24, height: 24)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .frame(width: element_card_scale, height: element_card_scale)
            .contentShape(Rectangle())
            .overlay(alignment: .topLeading)
            {
                if element.performing_state != .none
                {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(element.performing_state.color)
                        .font(.system(size: element_card_light_size))
                        .padding(element_card_light_padding)
                }
            }
            .onTapGesture
            {
                element_view_presented.toggle()
            }
            .popover(isPresented: $element_view_presented)
            {
                WorkspaceProgramElementView(element: element, workspace: workspace, program: program)
                {
                    workspace.objectWillChange.send()
                }
                .padding()
            }
            .contextMenu
            {
                Button(role: .destructive)
                {
                    on_delete()
                }
                label:
                {
                    Label("Delete", systemImage: "trash")
                }
            }
            .help(element.info)
        }
    }
    
    private struct ElementDropDelegate: DropDelegate
    {
        let current_element: WorkspaceProgramElement
        let program: ProductionProgram
        
        @Binding var dragging_element_id: UUID?
        
        let workspace: Workspace
        
        #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
        #endif
        
        func dropEntered(info: DropInfo)
        {
            guard let dragging_id = dragging_element_id else { return }
            
            if dragging_id != current_element.id,
               let from_index = program.elements.firstIndex(where: { $0.id == dragging_id }),
               let to_index = program.elements.firstIndex(where: { $0.id == current_element.id })
            {
                withAnimation
                {
                    program.elements.move(fromOffsets: IndexSet(integer: from_index), toOffset: to_index > from_index ? to_index + 1 : to_index)
                }
            }
        }
        
        func performDrop(info: DropInfo) -> Bool
        {
            dragging_element_id = nil
            return true
        }
    }
}

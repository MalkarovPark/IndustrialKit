//
//  ToolControlView.swift
//  IndustrialKit
//
//  Created by Artem on 30.01.2026.
//

import SwiftUI
import IndustrialKit
import UniformTypeIdentifiers

// MARK: - Control View
struct ToolControlView: View
{
    @ObservedObject var tool: Tool
    
    @State private var dragging_program_id: UUID?
    @State private var new_program_view_presented = false
    
    @Namespace private var animation_namespace
    
    @State private var code_value = 0
    
    public init(tool: Tool)
    {
        self.tool = tool
    }
    
    var body: some View
    {
        VStack(alignment: .center, spacing: 10)
        {
            // MARK: Caption
            PerformingCaptionView(name: tool.name, performing_state: tool.performing_state)
                .frame(width: 200)
            
            // MARK: Programs
            ZStack
            {
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                
                ScrollView
                {
                    LazyVStack(spacing: 8)
                    {
                        ForEach(tool.programs)
                        { program in
                            if tool.selected_program == nil
                            {
                                ProgramItemView(
                                    name: Binding(
                                        get: { program.name },
                                        set: { new_value in
                                            if let index = tool.programs.firstIndex(where: { $0.id == program.id })
                                            {
                                                tool.programs[index].name = mismatched_name(name: new_value, names: tool.programs_names)//new_value
                                            }
                                        }
                                    ),
                                    count: program.codes_count,
                                    on_delete:
                                    {
                                        if let index = tool.programs.firstIndex(where: { $0.id == program.id })
                                        {
                                            tool.programs.remove(at: index)
                                        }
                                    }
                                )
                                .matchedGeometryEffect(id: program.id, in: animation_namespace)
                                .onTapGesture
                                {
                                    select_program(program)
                                }
                                .onDrag
                                {
                                    dragging_program_id = program.id
                                    return NSItemProvider(object: program.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text],
                                        delegate: ProgramDropDelegate(current_program: program, tool: tool, dragging_program_id: $dragging_program_id))
                                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                            }
                        }
                        .animation(.spring(), value: tool.programs)
                    }
                    .padding(8)
                    
                    Spacer(minLength: 48)
                }
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                
                /*if let program = tool.selected_program
                {
                    PositionProgramView(tool: tool, program: program)
                    {
                        deselect_program()
                    }
                    .matchedGeometryEffect(id: program.id, in: animation_namespace)
                    .zIndex(1)
                }*/
            }
            .frame(width: 200)
            .overlay(alignment: .bottomTrailing)
            {
                HStack(spacing: 0)
                {
                    if tool.selected_program != nil
                    {
                        //PerformingControlView(tool: tool)
                    }
                    
                    Spacer()
                    
                    Button(action: add_item)
                    {
                        Image(systemName: "plus")
                            .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                            .modifier(CircleButtonImageFramer())
                    }
                    .disabled(tool.program_performed)
                    #if os(macOS)
                    .popover(isPresented: $new_program_view_presented, arrowEdge: .leading)
                    {
                        AddNewView(is_presented: $new_program_view_presented, names: tool.programs_names) { new_name in
                            tool.add_program(OperationsProgram(name: new_name))
                        }
                    }
                    #else
                    .popover(isPresented: $new_program_view_presented, arrowEdge: .trailing)
                    {
                        AddNewView(is_presented: $new_program_view_presented, names: tool.programs_names) { new_name in
                            tool.add_program(OperationsProgram(name: new_name))
                        }
                    }
                    #endif
                    .modifier(CircleButtonGlassBorderer())
                    #if os(macOS) || os(iOS)
                    .padding(10)
                    #else
                    .padding(16)
                    #endif
                }
            }
            
            // MARK: Controls
            // ??
        }
    }
    
    // MARK: Functions
    private func add_item()
    {
        if tool.selected_program == nil
        {
            new_program_view_presented = true
        }
        else
        {
            if let program = tool.selected_program
            {
                program.add_code(OperationCode(code_value))
                //tool.update_position_program_entity(by: program)
            }
        }
    }
    
    private func select_program(_ program: OperationsProgram)
    {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
        {
            // Editor handling
            tool.selected_program = program
            //tool.update_position_program_entity(by: program)
            
            //tool.toggle_position_program_visibility()
            
            // Performing Handling
            tool.select_program(name: program.name)
        }
    }
    
    private func deselect_program()
    {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
        {
            tool.deselect_program()
        }
    }
}

private struct ProgramDropDelegate: DropDelegate
{
    let current_program: OperationsProgram
    let tool: Tool
    
    @Binding var dragging_program_id: UUID?
    
    func dropEntered(info: DropInfo)
    {
        guard let dragging_id = dragging_program_id else { return }
        
        if dragging_id != current_program.id,
           let from_index = tool.programs.firstIndex(where: { $0.id == dragging_id }),
           let to_index = tool.programs.firstIndex(where: { $0.id == current_program.id })
        {
            withAnimation
            {
                tool.programs.move(fromOffsets: IndexSet(integer: from_index), toOffset: to_index > from_index ? to_index + 1 : to_index)
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool
    {
        dragging_program_id = nil
        return true
    }
}

// MARK: - Previews
struct ToolControlView_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var tool = Tool(name: "Gripper")
        
        var body: some View
        {
            ZStack
            {
                FloatingView(alignment: .trailing)
                {
                    ToolControlView(tool: tool)
                        .padding(8)
                }
                .padding(10)
            }
            .frame(height: 480)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

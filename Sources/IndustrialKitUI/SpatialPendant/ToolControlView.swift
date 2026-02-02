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
                
                if let program = tool.selected_program
                {
                    OperationProgramView(tool: tool, program: program)
                    {
                        deselect_program()
                    }
                    .matchedGeometryEffect(id: program.id, in: animation_namespace)
                    .zIndex(1)
                }
            }
            .frame(width: 200)
            .overlay(alignment: .bottomTrailing)
            {
                HStack(spacing: 0)
                {
                    if tool.selected_program != nil
                    {
                        PerformingControlView(tool: tool)
                    }
                    
                    Spacer()
                    
                    Button(action: add_item)
                    {
                        Image(systemName: "plus")
                            //.contentTransition(.symbolEffect(.replace.offUp.byLayer))
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
            OperationControl(tool: tool)
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

// MARK: - Program View
struct OperationProgramView: View
{
    @ObservedObject var tool: Tool
    
    @ObservedObject var program: OperationsProgram
    var dismiss_function: () -> ()
    @State private var dragging_point_id: UUID?
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            HStack
            {
                Text(program.name)
                #if os(macOS)
                    .font(.system(size: 14, design: .rounded))
                #else
                    .font(.system(size: 16, design: .rounded))
                #endif
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(8)
            .overlay(alignment: .leading)
            {
                Button(action: dismiss_function)
                {
                    Image(systemName: "chevron.left")
                    #if os(iOS)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                    #endif
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            
            Divider()
            
            ScrollView
            {
                /*LazyVStack(spacing: 8)
                {
                    ForEach($program.points)
                    { $point in
                        PositionItemView(
                            tool: tool,
                            program: program,
                            point_item: point
                        )
                        { if let index = program.points.firstIndex(where: { $0.id == point.id })
                            {
                                program.points.remove(at: index)
                                tool.update_position_program_entity(by: program)
                            }
                        }
                        .onDrag
                        {
                            dragging_point_id = point.id
                            return NSItemProvider(object: point.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: PositionDropDelegate(current_point: point, program: program, dragging_point_id: $dragging_point_id, tool: tool))
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                    
                    Spacer(minLength: 48)
                }
                .padding(8)*/
            }
            
            /*Button(action: { program.add_point(PositionPoint(x: 0, y: 0, z: 0)) })
            {
                Image(systemName: "plus")
            }*/
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

//...

private struct PerformingControlView: View
{
    @ObservedObject var tool: Tool
    
    var body: some View
    {
        HStack(spacing: 2)
        {
            Button(action: {
                tool.reset_performing()
            })
            {
                Image(systemName: "stop.fill")
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .modifier(CircleButtonImageFramer())
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            
            Divider()
                .frame(height: 24)
            
            Button(action: {
                tool.start_pause_performing()
            })
            {
                Image(systemName: tool.program_performed ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .modifier(CircleButtonImageFramer())
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
        }
        #if os(macOS)
        .padding(4)
        #endif
        #if !os(visionOS)
        .glassEffect(.regular.interactive())
        #else
        .controlSize(.large)
        .buttonStyle(.borderless)
        .glassBackgroundEffect()
        .frame(depth: 24)
        #endif
        #if os(macOS) || os(iOS)
        .padding(10)
        #else
        .padding(16)
        #endif
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
            .onAppear
            {
                tool.codes = [
                    OperationCodeInfo(value: 0, name: "Close", symbol: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", info: "UwU"),
                    OperationCodeInfo(value: 1, name: "Open", symbol: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", info: "OwO")
                ]
            }
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

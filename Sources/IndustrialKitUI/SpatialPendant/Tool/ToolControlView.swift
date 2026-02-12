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
                .frame(width: pendant_content_width)
            
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
                                                tool.programs[index].name = mismatched_name(name: new_value, names: tool.programs_names)
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
                                    tool.reset_performing()
                                    
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
                
                if tool.codes.count == 0
                {
                    Text("No Acceptable")
                        #if os(macOS)
                        .font(.system(size: 12))
                        #else
                        .font(.system(size: 14))
                        #endif
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: pendant_content_width)
            .overlay(alignment: .bottomTrailing)
            {
                HStack(spacing: 0)
                {
                    if tool.selected_program != nil
                    {
                        PerformingControlView(tool: tool)
                    }
                    
                    Spacer()
                    
                    if tool.codes.count > 0
                    {
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
                                tool.add_program(OperationProgram(name: new_name))
                            }
                        }
                        #else
                        .popover(isPresented: $new_program_view_presented, arrowEdge: .trailing)
                        {
                            AddNewView(is_presented: $new_program_view_presented, names: tool.programs_names) { new_name in
                                tool.add_program(OperationProgram(name: new_name))
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
                program.add_code(tool.current_operation)
                //tool.update_position_program_entity(by: program)
            }
        }
    }
    
    private func select_program(_ program: OperationProgram)
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
    let current_program: OperationProgram
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
private struct OperationProgramView: View
{
    @ObservedObject var tool: Tool
    
    @ObservedObject var program: OperationProgram
    var dismiss_function: () -> ()
    @State private var dragging_code_id: UUID?
    
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
                    .font(.system(size: 18, design: .rounded))
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
                        .font(.system(size: 20))
                        .padding(4)
                        .contentShape(Rectangle())
                    #endif
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            
            Divider()
            
            ScrollView
            {
                LazyVStack(spacing: 8)
                {
                    ForEach($program.codes)
                    { $code in
                        OperationItemView(
                            tool: tool,
                            program: program,
                            code_item: code
                        )
                        { if let index = program.codes.firstIndex(where: { $0.id == code.id })
                            {
                                program.codes.remove(at: index)
                                //tool.update_position_program_entity(by: program)
                            }
                        }
                        .onDrag
                        {
                            dragging_code_id = code.id
                            return NSItemProvider(object: code.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: OperationDropDelegate(current_code: code, program: program, dragging_code_id: $dragging_code_id, tool: tool))
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                    
                    Spacer(minLength: 48)
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

private struct OperationItemView: View
{
    @ObservedObject var tool: Tool
    @ObservedObject var program: OperationProgram
    @ObservedObject var code_item: OperationCode
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    let on_delete: () -> ()
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(code_item.performing_state.color)
                .font(.system(size: 6))
                .padding(.leading, 6)
            
            ZStack
            {
                Rectangle()
                    .fill(.clear)
                    .frame(maxWidth: .infinity, maxHeight: 256)
                    .overlay
                    {
                        HStack(spacing: 0)
                        {
                            ZStack
                            {
                                //Text(tool.code_info(code_item.value).name)
                                    //.font(.system(size: 10))
                                
                                Picker(tool.code_info(code_item.value).name, selection: $code_item.value)
                                {
                                    if tool.codes.count > 0
                                    {
                                        ForEach(tool.codes.map { $0.value }, id:\.self)
                                        { code in
                                            Text(tool.code_info(code).name)
                                                .lineLimit(1)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .font(.system(size: 4))
                                .disabled(tool.codes.count == 0)
                                .frame(maxWidth: .infinity)
                                .pickerStyle(.menu)
                                .buttonStyle(.plain)
                                .labelsHidden()
                                #if !os(macOS)
                                .scaleEffect(0.8)
                                #endif
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
            }
            .frame(height: 24)
            
            Image(systemName: tool.code_info(code_item.value).symbol)
                //.foregroundColor(.secondary)
                .font(.system(size: 12))
                .frame(width: 24, height: 24)
        }
        .contentShape(Rectangle())
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
    }
}

private struct OperationDropDelegate: DropDelegate
{
    let current_code: OperationCode
    let program: OperationProgram
    
    @Binding var dragging_code_id: UUID?
    
    let tool: Tool
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    #endif
    
    func dropEntered(info: DropInfo)
    {
        guard let dragging_id = dragging_code_id else { return }
        
        if dragging_id != current_code.id,
           let from_index = program.codes.firstIndex(where: { $0.id == dragging_id }),
           let to_index = program.codes.firstIndex(where: { $0.id == current_code.id })
        {
            withAnimation
            {
                program.codes.move(fromOffsets: IndexSet(integer: from_index), toOffset: to_index > from_index ? to_index + 1 : to_index)
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool
    {
        dragging_code_id = nil
        //robot.update_position_program_entity(by: program)
        return true
    }
}

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
            #if os(macOS)
            .frame(height: 480)
            #else
            .frame(height: 600)
            #endif
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

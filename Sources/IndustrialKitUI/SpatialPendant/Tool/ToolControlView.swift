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
public struct ToolControlView: View
{
    @ObservedObject var tool: Tool
    
    let shows_program_indices: Bool
    
    let on_update: () -> ()
    
    @State private var dragging_program_id: UUID?
    @State private var new_program_view_presented = false
    
    @Namespace private var animation_namespace
    
    @State private var new_view_is_expanded = false
    
    @State private var code_value = 0
    
    public init(
        tool: Tool,
        shows_program_indices: Bool = false,
        
        on_update: @escaping () -> Void = { }
    )
    {
        self.tool = tool
        self.shows_program_indices = shows_program_indices
        
        self.on_update = on_update
    }
    
    public var body: some View
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
                        ForEach(Array(tool.programs.enumerated()), id: \.element.id)
                        { index, program in
                            if tool.selected_program == nil
                            {
                                ProgramItemView(
                                    name: Binding(
                                        get: { program.name },
                                        set: { new_value in
                                            if let index = tool.programs.firstIndex(where: { $0.id == program.id })
                                            {
                                                tool.programs[index].name = unique_name(for: new_value, in: tool.program_names)
                                                
                                                on_update()
                                            }
                                        }
                                    ),
                                    count: program.codes_count,
                                    on_delete:
                                    {
                                        if let index = tool.programs.firstIndex(where: { $0.id == program.id })
                                        {
                                            tool.reset_performing()
                                            tool.programs.remove(at: index)
                                            
                                            on_update()
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
                                .onDrop(
                                    of: [.text],
                                    delegate: ProgramDropDelegate(
                                        tool: tool,
                                        
                                        current_program: program,
                                        dragging_program_id: $dragging_program_id,
                                        
                                        on_update: on_update
                                    )
                                )
                                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                                .overlay(alignment: .topLeading)
                                {
                                    if shows_program_indices
                                    {
                                        Text("\(index)")
                                            .font(.system(size: program_index_font_size))
                                            .foregroundStyle(.tertiary)
                                            .frame(height: 20)
                                            .lineLimit(1)
                                            .padding(.leading, 6)
                                            .allowsHitTesting(false)
                                    }
                                }
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
                    OperationProgramView(
                        tool: tool,
                        program: program,
                        on_update: on_update
                    )
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
                        
                        Spacer()
                    }
                    
                    if tool.codes.count > 0
                    {
                        NewElementButton(
                            with_name: tool.selected_program == nil,
                            is_expanded: $new_view_is_expanded,
                            names: tool.program_names,
                            add_name_action:
                                { new_name in
                                    tool.add_program(OperationProgram(name: new_name))
                                    
                                    on_update()
                                },
                            add_action:
                                {
                                    add_item()
                                }
                        )
                        .disabled(tool.program_performed)
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
        if let program = tool.selected_program
        {
            program.add_code(tool.current_operation)
            
            on_update()
        }
    }
    
    private func select_program(_ program: OperationProgram)
    {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
        {
            // Dismiss new program view
            if new_view_is_expanded { new_view_is_expanded = false }
            
            // Editor handling
            tool.selected_program = program
            
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
    let tool: Tool
    
    let current_program: OperationProgram
    @Binding var dragging_program_id: UUID?
    
    let on_update: () -> ()
    
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
        on_update()
        return true
    }
}

// MARK: - Program View
private struct OperationProgramView: View
{
    @ObservedObject var tool: Tool
    
    @ObservedObject var program: OperationProgram
    
    let on_update: () -> ()
    
    let dismiss_function: () -> ()
    
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
                .keyboardShortcut(.cancelAction)
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
                        {
                            if let index = program.codes.firstIndex(where: { $0.id == code.id })
                            {
                                program.codes.remove(at: index)
                                
                                on_update()
                            }
                        }
                        .onDrag
                        {
                            dragging_code_id = code.id
                            return NSItemProvider(object: code.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: OperationDropDelegate(
                                tool: tool,
                                program: program,
                                
                                current_code: code,
                                dragging_code_id: $dragging_code_id,
                                
                                on_update: on_update
                            )
                        )
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
    
    let on_delete: () -> ()
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(code_item.performing_state.color)
                .font(.system(size: program_item_light_size))
                .padding(.leading, program_item_light_padding)
            
            ZStack
            {
                Rectangle()
                    .fill(.clear)
                    .overlay
                    {
                        HStack(spacing: 0)
                        {
                            ZStack
                            {
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
                                .font(.system(size: operation_item_font_size))
                                .disabled(tool.codes.count == 0)
                                .frame(maxWidth: .infinity)
                                .pickerStyle(.menu)
                                .buttonStyle(.plain)
                                .labelsHidden()
                                #if !os(macOS)
                                .scaleEffect(0.95)
                                #endif
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
            }
            .frame(height: 24)
            
            Image(systemName: tool.code_info(code_item.value).symbol_name)
                .font(.system(size: operatioin_item_image_size))
                .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                .frame(width: 24)
        }
        .frame(height: program_item_height)
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
    let tool: Tool
    let program: OperationProgram
    
    let current_code: OperationCode
    @Binding var dragging_code_id: UUID?
    
    let on_update: () -> ()
    
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
        on_update()
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

// MARK: - Sizes
#if os(macOS)
let operation_item_font_size: CGFloat = 4
let operatioin_item_image_size: CGFloat = 12
#else
let operation_item_font_size: CGFloat = 4
let operatioin_item_image_size: CGFloat = 14
#endif

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
                    ToolControlView(tool: tool, shows_program_indices: true)
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
                    OperationCodeInfo(value: 0, name: "Close", symbol_name: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", description: "UwU"),
                    OperationCodeInfo(value: 1, name: "Open", symbol_name: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", description: "OwO")
                ]
            }
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

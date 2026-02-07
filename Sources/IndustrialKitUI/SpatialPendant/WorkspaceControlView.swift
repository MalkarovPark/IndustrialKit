//
//  WorkspaceControlView.swift
//  IndustrialKit
//
//  Created by Artem on 30.01.2026.
//

import SwiftUI
import IndustrialKit
import UniformTypeIdentifiers

// MARK: - Control View
struct WorkspaceControlView: View
{
    @ObservedObject var workspace: Workspace
    
    @State private var dragging_program_id: UUID?
    @State private var new_program_view_presented = false
    
    @Namespace private var animation_namespace
    
    @State private var code_value = 0
    
    public init(workspace: Workspace)
    {
        self.workspace = workspace
    }
    
    var body: some View
    {
        VStack(alignment: .center, spacing: 10)
        {
            // MARK: Caption
            PerformingCaptionView(name: "Workspace", performing_state: workspace.performing_state)
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
                        ForEach(workspace.programs)
                        { program in
                            if workspace.selected_program == nil
                            {
                                ProgramItemView(
                                    name: Binding(
                                        get: { program.name },
                                        set: { new_value in
                                            if let index = workspace.programs.firstIndex(where: { $0.id == program.id })
                                            {
                                                workspace.programs[index].name = mismatched_name(name: new_value, names: workspace.programs_names)
                                            }
                                        }
                                    ),
                                    count: program.elements_count,
                                    on_delete:
                                    {
                                        if let index = workspace.programs.firstIndex(where: { $0.id == program.id })
                                        {
                                            workspace.programs.remove(at: index)
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
                                        delegate: ProgramDropDelegate(current_program: program, workspace: workspace, dragging_program_id: $dragging_program_id))
                                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                            }
                        }
                        .animation(.spring(), value: workspace.programs)
                    }
                    .padding(8)
                    
                    Spacer(minLength: 48)
                }
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                
                if let program = workspace.selected_program
                {
                    ProductionProgramView(workspace: workspace, program: program)
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
                    if workspace.selected_program != nil
                    {
                        PerformingControlView(workspace: workspace)
                    }
                    
                    Spacer()
                    
                    Button(action: add_item)
                    {
                        Image(systemName: "plus")
                            //.contentTransition(.symbolEffect(.replace.offUp.byLayer))
                            .modifier(CircleButtonImageFramer())
                    }
                    .disabled(workspace.program_performed)
                    #if os(macOS)
                    .popover(isPresented: $new_program_view_presented, arrowEdge: .leading)
                    {
                        AddNewView(is_presented: $new_program_view_presented, names: workspace.programs_names) { new_name in
                            workspace.add_program(ProductionProgram(name: new_name))
                        }
                    }
                    #else
                    .popover(isPresented: $new_program_view_presented, arrowEdge: .trailing)
                    {
                        AddNewView(is_presented: $new_program_view_presented, names: workspace.programs_names) { new_name in
                            workspace.add_program(ProductionProgram(name: new_name))
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
            ElementControl(workspace: workspace)
        }
    }
    
    // MARK: Functions
    private func add_item()
    {
        if workspace.selected_program == nil
        {
            new_program_view_presented = true
        }
        else
        {
            if let selected_program = workspace.selected_program
            {
                clone_element(workspace.current_element, to: selected_program)
            }
        }
    }
    
    private func select_program(_ program: ProductionProgram)
    {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
        {
            // Editor handling
            workspace.selected_program = program
            
            // Performing Handling
            workspace.select_program(name: program.name)
        }
    }
    
    private func deselect_program()
    {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
        {
            workspace.deselect_program()
        }
    }
}

private struct ProgramDropDelegate: DropDelegate
{
    let current_program: ProductionProgram
    let workspace: Workspace
    
    @Binding var dragging_program_id: UUID?
    
    func dropEntered(info: DropInfo)
    {
        guard let dragging_id = dragging_program_id else { return }
        
        if dragging_id != current_program.id,
           let from_index = workspace.programs.firstIndex(where: { $0.id == dragging_id }),
           let to_index = workspace.programs.firstIndex(where: { $0.id == current_program.id })
        {
            withAnimation
            {
                workspace.programs.move(fromOffsets: IndexSet(integer: from_index), toOffset: to_index > from_index ? to_index + 1 : to_index)
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
private struct ProductionProgramView: View
{
    @ObservedObject var workspace: Workspace
    
    @ObservedObject var program: ProductionProgram
    
    var dismiss_function: () -> ()
    
    @State private var dragging_element_id: UUID?
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: element_card_maximum, maximum: element_card_maximum), spacing: 0)]
    
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
                                //workspace.update_position_program_entity(by: program)
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
                //.border(.gray)
                #if os(macOS)
                .padding(.vertical, 16)//.padding(8)
                #else
                .padding(.vertical, 16)//.padding(8)
                #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

private struct ElementItemView: View
{
    @ObservedObject var workspace: Workspace
    @ObservedObject var program: ProductionProgram
    @ObservedObject var element: WorkspaceProgramElement
    
    @State private var position_item_view_presented = false
    
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
                .foregroundColor(element.color)
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
                    .foregroundColor(element.performing_state.color)
                    .font(.system(size: element_card_light_size))
                    .padding(4)
            }
        }
        .onTapGesture
        {
            position_item_view_presented.toggle()
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
        //robot.update_position_program_entity(by: program)
        return true
    }
}

private struct PerformingControlView: View
{
    @ObservedObject var workspace: Workspace
    
    var body: some View
    {
        HStack(spacing: 2)
        {
            Button(action: {
                workspace.reset_performing()
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
                workspace.start_pause_performing()
            })
            {
                Image(systemName: workspace.program_performed ? "pause.fill" : "play.fill")
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
struct WorkspaceControl_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var workspace = Workspace()
        
        //
        private let columns: [GridItem] = [.init(.adaptive(minimum: element_card_maximum, maximum: element_card_maximum), spacing: 0)]
        
        @State private var element = MathModifierElement()
        //
        
        var body: some View
        {
            ZStack
            {
                FloatingView(alignment: .trailing)
                {
                    WorkspaceControlView(workspace: workspace)
                        .padding(8)
                }
                .padding(10)
            }
            .frame(height: 480)
            .onAppear
            {
                let robot = Robot(name: "6DOF")
                robot.is_placed = true
                robot.add_program(PositionsProgram(name: "Square"))
                
                let tool = Tool(name: "Gripper")
                tool.is_placed = true
                tool.add_program(OperationsProgram(name: "Close"))
                
                workspace.robots.append(robot)
                workspace.tools.append(tool)
            }
            
            ZStack()
            {
                ScrollView
                {
                    LazyVGrid(columns: columns, spacing: element_card_spacing)
                    {
                        ElementItemView(workspace: workspace, program: ProductionProgram(), element: RobotPerformerElement())
                        {
                            
                        }
                        
                        ElementItemView(workspace: workspace, program: ProductionProgram(), element: MathModifierElement())
                        {
                            
                        }
                        
                        
                        ElementItemView(workspace: workspace, program: ProductionProgram(), element: JumpLogicElement())
                        {
                            
                        }
                        
                        /*ElementItemView(workspace: workspace, program: ProductionProgram(), element: element)
                        {
                            
                        }*/
                    }
                }
                //.border(.green)
                .padding()
            }
            .frame(width: 256, height: 256)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

let element_card_maximum = element_card_scale + element_card_spacing

#if os(macOS)
let element_card_scale: CGFloat = 35//40
let element_card_spacing: CGFloat = 10
let element_card_font_size: CGFloat = 14 //16
let element_card_light_size: CGFloat = 5 //6
#else
let element_card_scale: CGFloat = 40
let element_card_spacing: CGFloat = 10
let element_card_font_size: CGFloat = 16
let element_card_light_size: CGFloat = 6
#endif

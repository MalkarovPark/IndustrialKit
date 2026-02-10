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
    
    @State private var registers_view_presented = false
    
    @State private var registers_updated = false
    
    @State private var code_editor_text = ""
    
    let on_update: () -> ()
    
    public init(
        workspace: Workspace,
        on_update: @escaping () -> Void = {}
    )
    {
        self.workspace = workspace
        
        self.on_update = on_update
    }
    
    @State private var view_program_as_text = false
    
    var body: some View
    {
        VStack(alignment: .center, spacing: 10)
        {
            // MARK: Caption
            PerformingCaptionView(name: "Workspace", performing_state: workspace.performing_state)
                .frame(width: pendant_content_width)
                .overlay(alignment: .leading)
                {
                    HStack
                    {
                        Button
                        {
                            registers_view_presented = true
                            registers_updated = false
                        }
                        label:
                        {
                            Image(systemName: "number")
                                .padding(.leading, 10)
                        }
                        .buttonStyle(.borderless)
                        .overlay(alignment: .topTrailing)
                        {
                            if registers_updated
                            {
                                ZStack
                                {
                                    Image(systemName: "circle.fill")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 6))
                                    
                                    Image(systemName: "circle.fill")
                                        .foregroundStyle(.pink)
                                        .font(.system(size: 3))
                                }
                                .padding(0.5)
                            }
                        }
                        .onChange(of: workspace.registers)
                        { _, _ in
                            if !registers_view_presented
                            {
                                registers_updated = true
                            }
                        }
                        
                        Button(action: { workspace.cycled.toggle() })
                        {
                            if workspace.cycled
                            {
                                Image(systemName: "repeat")
                            }
                            else
                            {
                                Image(systemName: "repeat.1")
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .sheet(isPresented: $registers_view_presented)
                {
                    RegistersDataView(is_presented: $registers_view_presented, workspace: workspace)
                    {
                        //document_handler.document_update_registers()
                    }
                    .onDisappear()
                    {
                        registers_view_presented = false
                    }
                    #if os(macOS)
                    .frame(width: 420, height: 480)
                    #elseif os(visionOS)
                    .frame(width: 600, height: 600)
                    #endif
                }
            
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
                    ProductionProgramView(view_program_as_text: $view_program_as_text, code_editor_text: $code_editor_text, workspace: workspace, program: program, on_update: on_update)
                    {
                        deselect_program()
                    }
                    .matchedGeometryEffect(id: program.id, in: animation_namespace)
                    .zIndex(1)
                }
            }
            .frame(width: pendant_content_width)
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
                            
                            on_update()
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
                if !view_program_as_text
                {
                    clone_element(workspace.current_element, to: selected_program)
                }
                else
                {
                    if !code_editor_text.isEmpty { code_editor_text += "\n" }
                    code_editor_text += workspace.current_element.code_string
                }
                
                on_update()
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
    @Binding var view_program_as_text: Bool
    
    @Binding var code_editor_text: String
    
    @ObservedObject var workspace: Workspace
    
    @ObservedObject var program: ProductionProgram
    
    var on_update: () -> () = {}
    
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
            .overlay(alignment: .trailing)
            {
                Button(action: { view_program_as_text.toggle() })
                {
                    Image(systemName: view_program_as_text ? "text.justify.left" : "square.grid.2x2")
                        .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    #if os(iOS)
                        .font(.system(size: 20))
                        .padding(4)
                        .contentShape(Rectangle())
                    #endif
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
            /*.background
            {
                if view_program_as_text
                {
                    Rectangle()
                        .fill(.white)
                        .transition(.move(edge: .trailing))
                        .animation(.easeInOut(duration: 0.3), value: view_program_as_text)
                }
            }*/
            
            Divider()
            
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
                                element: element,
                                on_update: on_update
                            )
                            { if let index = program.elements.firstIndex(where: { $0.id == element.id })
                                {
                                    program.elements.remove(at: index)
                                    workspace.elements_check(program: program)
                                    
                                    on_update()
                                }
                            }
                            .onDrag
                            {
                                dragging_element_id = element.id
                                return NSItemProvider(object: element.id.uuidString as NSString)
                            }
                            .onDrop(of: [.text], delegate: ElementDropDelegate(current_element: element, program: program, dragging_element_id: $dragging_element_id, workspace: workspace, on_update: on_update))
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            else
            {
                ControlProgramTextView(program: program, workspace: workspace, code_editor_text: $code_editor_text)
                    .transition(.move(edge: .trailing))
                    .onDisappear
                    {
                        view_program_as_text = false
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: view_program_as_text)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
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
    
    let on_update: () -> ()
    
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
            WorkspaceProgramElementView(element: element, workspace: workspace, program: program, on_update: on_update)
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

let element_card_maximum = element_card_scale + element_card_spacing

#if os(macOS)
let element_card_scale: CGFloat = 35//40
let element_card_spacing: CGFloat = 10
let element_card_font_size: CGFloat = 14 //16
let element_card_light_size: CGFloat = 5 //6
let element_card_light_padding: CGFloat = 3
#else
let element_card_scale: CGFloat = 60
let element_card_spacing: CGFloat = 16
let element_card_font_size: CGFloat = 24
let element_card_light_size: CGFloat = 8
let element_card_light_padding: CGFloat = 6
#endif

private struct ElementDropDelegate: DropDelegate
{
    let current_element: WorkspaceProgramElement
    let program: ProductionProgram
    
    @Binding var dragging_element_id: UUID?
    
    let workspace: Workspace
    
    let on_update: () -> ()
    
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
                
                on_update()
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool
    {
        dragging_element_id = nil
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
        
        var body: some View
        {
            ZStack
            {
                FloatingView(alignment: .trailing)
                {
                    WorkspaceControlView(workspace: workspace /*, on_update: { print("Program Updated") } */)
                        .padding(8)
                }
                .padding(10)
            }
            .frame(height: 480)
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
            }
            
            VStack
            {
                HStack
                {
                    ElementItemView(workspace: workspace, program: ProductionProgram(), element: RobotPerformerElement(), on_update: {})
                    {
                        
                    }
                    
                    ElementItemView(workspace: workspace, program: ProductionProgram(), element: MathModifierElement(), on_update: {})
                    {
                        
                    }
                }
                
                HStack
                {
                    ElementItemView(workspace: workspace, program: ProductionProgram(), element: JumpLogicElement(), on_update: {})
                    {
                        
                    }
                    
                    ElementItemView(workspace: workspace, program: ProductionProgram(), element: JumpLogicElement(), on_update: {})
                    {
                        
                    }
                    .hidden()
                }
            }
            .frame(width: 160, height: 160)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

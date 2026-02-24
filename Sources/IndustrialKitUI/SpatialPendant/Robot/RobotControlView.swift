//
//  RobotControlView.swift
//  IndustrialKit
//
//  Created by Artem on 19.01.2026.
//

import SwiftUI
import IndustrialKit
import UniformTypeIdentifiers

// MARK: - Control View
public struct RobotControlView: View
{
    @ObservedObject var robot: Robot
    
    @State private var dragging_program_id: UUID?
    @State private var new_program_view_presented = false
    
    let on_update: () -> ()
    
    public init(
        robot: Robot,
        on_update: @escaping () -> Void = { }
    )
    {
        self.robot = robot
        
        self.on_update = on_update
    }
    
    @Namespace private var animation_namespace
    
    @State private var new_view_is_expanded = false
    
    public var body: some View
    {
        VStack(alignment: .center, spacing: 10)
        {
            // MARK: Caption
            PerformingCaptionView(name: robot.name, performing_state: robot.performing_state)
                .frame(width: pendant_content_width)
            
            // MARK: Program
            ZStack
            {
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                
                ScrollView
                {
                    LazyVStack(spacing: 8)
                    {
                        ForEach(robot.programs)
                        { program in
                            if robot.selected_program == nil
                            {
                                ProgramItemView(
                                    name: Binding(
                                        get: { program.name },
                                        set: { new_value in
                                            if let index = robot.programs.firstIndex(where: { $0.id == program.id })
                                            {
                                                robot.programs[index].name = mismatched_name(name: new_value, names: robot.programs_names)//new_value
                                            }
                                        }
                                    ),
                                    count: program.points_count,
                                    on_delete:
                                    {
                                        if let index = robot.programs.firstIndex(where: { $0.id == program.id })
                                        {
                                            robot.programs.remove(at: index)
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
                                        delegate: ProgramDropDelegate(current_program: program, robot: robot, dragging_program_id: $dragging_program_id))
                                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                            }
                        }
                        .animation(.spring(), value: robot.programs)
                    }
                    .padding(8)
                    
                    Spacer(minLength: 48)
                }
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                
                if let program = robot.selected_program
                {
                    PositionProgramView(robot: robot, program: program)
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
                    if robot.selected_program != nil
                    {
                        PerformingControlView(robot: robot)
                        
                        Spacer()
                    }
                    
                    NewElementButton(
                        with_name: robot.selected_program == nil,
                        is_expanded: $new_view_is_expanded,
                        names: robot.programs_names,
                        add_name_action:
                            { new_name in
                                robot.add_program(PositionProgram(name: new_name))
                                
                                on_update()
                            },
                        add_action:
                            {
                                add_item()
                            }
                    )
                    .disabled(robot.program_performed)
                }
            }
            
            // MARK: Controls
            VStack(alignment: .center, spacing: 10)
            {
                PositionPane(robot: robot)
                
                PositionControl(robot: robot)
                    .frame(width: 120)
            }
        }
    }
    
    // MARK: Functions
    private func add_item()
    {
        if let program = robot.selected_program
        {
            program.add_point(PositionPoint(x: robot.pointer_position.x, y: robot.pointer_position.y, z: robot.pointer_position.z, r: robot.pointer_position.r, p: robot.pointer_position.p, w: robot.pointer_position.w))
            robot.update_position_program_entity(by: program)
            
            on_update()
        }
    }
    
    private func select_program(_ program: PositionProgram)
    {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
        {
            // Dismiss new program view
            if new_view_is_expanded { new_view_is_expanded = false }
            
            // Editor handling
            robot.selected_program = program
            robot.update_position_program_entity(by: program)
            
            robot.toggle_position_program_visibility()
            
            // Performing Handling
            robot.select_program(name: program.name)
        }
    }
    
    private func deselect_program()
    {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
        {
            robot.deselect_program()
        }
    }
}

private struct ProgramDropDelegate: DropDelegate
{
    let current_program: PositionProgram
    let robot: Robot
    
    @Binding var dragging_program_id: UUID?
    
    func dropEntered(info: DropInfo)
    {
        guard let dragging_id = dragging_program_id else { return }
        
        if dragging_id != current_program.id,
           let from_index = robot.programs.firstIndex(where: { $0.id == dragging_id }),
           let to_index = robot.programs.firstIndex(where: { $0.id == current_program.id })
        {
            withAnimation
            {
                robot.programs.move(fromOffsets: IndexSet(integer: from_index), toOffset: to_index > from_index ? to_index + 1 : to_index)
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
private struct PositionProgramView: View
{
    @ObservedObject var robot: Robot
    
    @ObservedObject var program: PositionProgram
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
                    ForEach($program.points)
                    { $point in
                        PositionItemView(
                            robot: robot,
                            program: program,
                            point_item: point
                        )
                        { if let index = program.points.firstIndex(where: { $0.id == point.id })
                            {
                                robot.reset_moving()
                                
                                program.points.remove(at: index)
                                robot.update_position_program_entity(by: program)
                            }
                        }
                        .onDrag
                        {
                            robot.reset_moving()
                            
                            dragging_point_id = point.id
                            return NSItemProvider(object: point.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: PositionDropDelegate(current_point: point, program: program, dragging_point_id: $dragging_point_id, robot: robot))
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                    
                    Spacer(minLength: 48)
                }
                .padding(8)
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

private struct PositionItemView: View
{
    @ObservedObject var robot: Robot
    @ObservedObject var program: PositionProgram
    @ObservedObject var point_item: PositionPoint
    
    @State private var position_item_view_presented = false
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    let on_delete: () -> ()
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(point_item.performing_state.color)
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
                                Text("X \(String(format: "%.0f", point_item.x)) Y \(String(format: "%.0f", point_item.y)) Z \(String(format: "%.0f", point_item.z))")
                                    .font(.system(size: position_item_font_size))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                            Divider()
                            
                            ZStack
                            {
                                Text("R \(String(format: "%.0f", point_item.r)) P \(String(format: "%.0f", point_item.p)) W \(String(format: "%.0f", point_item.w))")
                                    .font(.system(size: position_item_font_size))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
            }
            .popover(isPresented: $position_item_view_presented,
                     arrowEdge: .trailing)
            {
                #if os(macOS)
                PositionPointView(robot: robot, program: program, point: point_item, position_item_view_presented: $position_item_view_presented)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                #else
                PositionPointView(robot: robot, program: program, point: point_item, position_item_view_presented: $position_item_view_presented, is_compact: horizontal_size_class == .compact)
                    .presentationDetents([.height(496)])
                #endif
            }
        }
        .frame(height: program_item_height)
        .contentShape(Rectangle())
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
    }
}

private struct PositionDropDelegate: DropDelegate
{
    let current_point: PositionPoint
    let program: PositionProgram
    
    @Binding var dragging_point_id: UUID?
    
    let robot: Robot
    
    func dropEntered(info: DropInfo)
    {
        guard let dragging_id = dragging_point_id else { return }
        
        if dragging_id != current_point.id,
           let from_index = program.points.firstIndex(where: { $0.id == dragging_id }),
           let to_index = program.points.firstIndex(where: { $0.id == current_point.id })
        {
            withAnimation
            {
                program.points.move(fromOffsets: IndexSet(integer: from_index), toOffset: to_index > from_index ? to_index + 1 : to_index)
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool
    {
        dragging_point_id = nil
        robot.update_position_program_entity(by: program)
        return true
    }
}

private struct PositionPointView: View
{
    @ObservedObject var robot: Robot
    @ObservedObject var program: PositionProgram
    
    @ObservedObject var point: PositionPoint
    @Binding var position_item_view_presented: Bool
    
    #if os(iOS)
    let is_compact: Bool
    #endif

    var body: some View
    {
        VStack(spacing: 16)
        {
            #if os(iOS)
            if is_compact
            {
                HStack
                {
                    Text("Position")
                        .font(.title2)
                    
                    Spacer()
                    
                    Button
                    {
                        position_item_view_presented = false
                    }
                    label:
                    {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                }
            }
            #endif
            
            PositionView(position: positionBinding())
            
            Divider()
            
            HStack
            {
                Text("Type")
                    .fontWeight(.light)
                
                Spacer()
                
                Picker("Type", selection: $point.move_type)
                {
                    ForEach(MoveType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                #if !os(macOS)
                .buttonStyle(.plain)
                #endif
            }
            
            Divider()
            
            HStack
            {
                Text("Speed (mm/s)")
                    .fontWeight(.light)
                
                Spacer()
                
                TextField("0", value: $point.move_speed, format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(macOS)
                    .frame(width: 60)
                #else
                    .frame(width: 80)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $point.move_speed, in: 0...100)
                    .labelsHidden()
            }
            //#endif
        }
        .padding()
    }

    private func positionBinding() -> Binding<(x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)>
    {
        Binding(
            get:
            {
                (
                    x: point.x,
                    y: point.y,
                    z: point.z,
                    r: point.r,
                    p: point.p,
                    w: point.w
                )
            },
            set:
            { new_value in
                var new_point = PositionPoint(x: new_value.x, y: new_value.y, z: new_value.z, r: new_value.r, p: new_value.p, w: new_value.w)
                robot.point_shift(&new_point)
                
                point.x = new_point.x
                point.y = new_point.y
                point.z = new_point.z
                point.r = new_point.r
                point.p = new_point.p
                point.w = new_point.w
                
                robot.update_position_program_entity(by: program)
            }
        )
    }
}

private struct PerformingControlView: View
{
    @ObservedObject var robot: Robot
    
    var body: some View
    {
        HStack(spacing: 2)
        {
            Button(action: {
                robot.reset_moving()
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
                robot.start_pause_moving()
            })
            {
                Image(systemName: robot.program_performed ? "pause.fill" : "play.fill")
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
let position_item_font_size: CGFloat = 8
#else
let position_item_font_size: CGFloat = 10
#endif

// MARK: - Previews
struct RobotControlView_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var robot = Robot(name: "6DOF Robot")
        
        var body: some View
        {
            ZStack
            {
                FloatingView(alignment: .trailing)
                {
                    RobotControlView(robot: robot)
                        .padding(8)
                }
                .padding(10)
            }
            #if os(macOS)
            .frame(height: 480)
            #else
            .frame(height: 600)
            #endif
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

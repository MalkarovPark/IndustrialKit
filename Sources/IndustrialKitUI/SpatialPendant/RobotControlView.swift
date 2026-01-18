//
//  RobotControlView.swift
//  IndustrialKit
//
//  Created by Artem Malkarov on 19.01.2026.
//

import SwiftUI
import IndustrialKit
import UniformTypeIdentifiers

public struct RobotControlView: View
{
    @ObservedObject var robot: Robot
    
    @State private var dragging_program_id: UUID?
    @State private var new_program_view_presented = false
    @State private var selected_program: PositionsProgram? = nil
    @State private var single_program_edit = false
    
    @Namespace private var animation_namespace
    
    public init(robot: Robot)
    {
        self.robot = robot
    }
    
    public var body: some View
    {
        VStack(alignment: .center, spacing: 16)
        {
            ZStack
            {
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular/*.tint(.white)*/, in: .rect(cornerRadius: 16, style: .continuous))
                
                ScrollView
                {
                    LazyVStack(spacing: 8)
                    {
                        ForEach(robot.programs)
                        { program in
                            if selected_program == nil //selectedProgram == nil //selectedProgram?.id != program.id
                            {
                                ProgramItemView(
                                    name: Binding(
                                        get: { program.name },
                                        set: { newValue in
                                            if let index = robot.programs.firstIndex(where: { $0.id == program.id })
                                            {
                                                robot.programs[index].name = mismatched_name(name: newValue, names: robot.programs_names)//newValue
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
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
                                    {
                                        selected_program = program
                                        robot.update_position_program_entity(by: program)
                                        
                                        single_program_edit = true
                                        robot.toggle_position_program_visibility()
                                    }
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
                
                if let program = selected_program
                {
                    PositionProgramView(robot: robot, program: program)
                    {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
                        {
                            selected_program = nil
                            
                            single_program_edit = false
                            robot.toggle_position_program_visibility()
                        }
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
                    Button(action: add_item)
                    {
                        Image(systemName: "plus")
                            .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                            .modifier(CircleButtonImageFramer())
                    }
                    #if os(macOS)
                    .popover(isPresented: $new_program_view_presented, arrowEdge: .leading)
                    {
                        AddNewView(is_presented: $new_program_view_presented, names: robot.programs_names) { new_name in
                            robot.add_program(PositionsProgram(name: new_name))
                        }
                    }
                    #else
                    .popover(isPresented: $new_program_view_presented, arrowEdge: .trailing)
                    {
                        AddNewView(is_presented: $new_program_view_presented, names: robot.programs_names) { new_name in
                            robot.add_program(PositionsProgram(name: new_name))
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
            
            VStack(alignment: .center, spacing: 10)
            {
                PositionPane(robot: robot)
                
                PositionControl(robot: robot)
                    .frame(width: 120)
            }
        }
        .padding(16)
        .background
        {
            Rectangle()
                .fill(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))
                .padding(8)
        }
    }
    
    private func add_item()
    {
        if !single_program_edit
        {
            new_program_view_presented = true
        }
        else
        {
            if let program = selected_program
            {
                program.add_point(PositionPoint(x: robot.pointer_position.x, y: robot.pointer_position.y, z: robot.pointer_position.z, r: robot.pointer_position.r, p: robot.pointer_position.p, w: robot.pointer_position.w))
                robot.update_position_program_entity(by: program)
            }
        }
    }
}

struct ProgramDropDelegate: DropDelegate
{
    let current_program: PositionsProgram
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

struct ProgramItemView: View
{
    @Binding var name: String
    let count: Int
    let on_delete: () -> Void
    
    @State private var to_rename = false
    @State private var new_name = String()
    @FocusState private var is_focused: Bool
    
    var body: some View
    {
        HStack
        {
            if !to_rename
            {
                Text(name)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
            }
            else
            {
                TextField("Name", text: $new_name)
                    .textFieldStyle(.plain)
                    .focused($is_focused)
                    .labelsHidden()
                    .padding(.leading, 16)
                    .onSubmit
                    {
                        name = new_name
                        to_rename = false
                    }
                #if os(macOS)
                    .onExitCommand
                    {
                        to_rename = false
                    }
                #endif
                    .onAppear
                    {
                        is_focused = true
                    }
                    .onChange(of: is_focused)
                    { _, new_value in
                        if !new_value
                        {
                            to_rename = false
                        }
                    }
            }
            
            Spacer()
            
            AdaptiveDotGrid(count: count, square_size: 24)
                .frame(width: 48, height: 48)
        }
        .background(.quinary)
        .frame(maxWidth: .infinity, maxHeight: 64)
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
        .contextMenu
        {
            Button("Rename", systemImage: "pencil")
            {
                to_rename = true
                new_name = name
            }
            
            Divider()
            
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

struct AdaptiveDotGrid: View
{
    let count: Int
    let square_size: CGFloat
    let spacing_ratio: CGFloat = 0.75

    private var side: Int
    {
        if count > 1
        {
            Int(ceil(sqrt(Double(count))))
        }
        else
        {
            Int(ceil(sqrt(Double(2))))
        }
    }

    var body: some View
    {
        GeometryReader
        { _ in
            let spacing = square_size / CGFloat(side) * spacing_ratio
            let dot_size = (square_size - spacing * CGFloat(side - 1)) / CGFloat(side)

            VStack(spacing: spacing)
            {
                ForEach(0..<side, id: \.self)
                { row in
                    HStack(spacing: spacing)
                    {
                        ForEach(0..<side, id: \.self)
                        { column in
                            let index = row * side + (side - 1 - column)

                            if index < count
                            {
                                Circle()
                                    .fill(.tertiary)
                                    .frame(width: dot_size, height: dot_size)
                            }
                            else
                            {
                                Color.clear
                                    .frame(width: dot_size, height: dot_size)
                            }
                        }
                    }
                }
            }
            .frame(width: square_size, height: square_size)
        }
        .frame(width: square_size, height: square_size)
    }
}

// MARK: - Position Program
struct PositionProgramView: View
{
    @ObservedObject var robot: Robot
    
    @ObservedObject var program: PositionsProgram
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
                                program.points.remove(at: index)
                                robot.update_position_program_entity(by: program)
                            }
                        }
                        .onDrag
                        {
                            dragging_point_id = point.id
                            return NSItemProvider(object: point.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: PositionDropDelegate(current_point: point, program: program, dragging_point_id: $dragging_point_id, robot: robot))
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
                .padding(8)
            }
            
            /*Button(action: { program.add_point(PositionPoint(x: 0, y: 0, z: 0)) })
            {
                Image(systemName: "plus")
            }*/
        }
        //.background(.quinary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        //.clipShape(.rect(cornerRadius: 8, style: .continuous))
        //.padding(8)
    }
}

struct PositionDropDelegate: DropDelegate
{
    let current_point: PositionPoint
    let program: PositionsProgram
    @Binding var dragging_point_id: UUID?
    
    let robot: Robot
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    #endif
    
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

struct PositionItemView: View
{
    @ObservedObject var robot: Robot
    @ObservedObject var program: PositionsProgram
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
                                Text("X \(String(format: "%.0f", point_item.x)) Y \(String(format: "%.0f", point_item.y)) Z \(String(format: "%.0f", point_item.z))")
                                    .font(.system(size: 8))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                            Divider()
                            
                            ZStack
                            {
                                Text("R \(String(format: "%.0f", point_item.r)) P \(String(format: "%.0f", point_item.p)) W \(String(format: "%.0f", point_item.w))")
                                    .font(.system(size: 8))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
            }
            .frame(height: 24)
            .popover(isPresented: $position_item_view_presented,
                     arrowEdge: .trailing)
            {
                #if os(macOS)
                PositionPointView(robot: robot, program: program, point: point_item, position_item_view_presented: $position_item_view_presented)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                #else
                PositionPointView(robot: robot, program: program, point: point_item, position_item_view_presented: $position_item_view_presented, is_compact: horizontal_size_class == .compact)
                    .presentationDetents([.height(576)])
                #endif
            }
        }
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

struct PositionPointView: View
{
    @ObservedObject var robot: Robot
    @ObservedObject var program: PositionsProgram
    
    @ObservedObject var point: PositionPoint
    @Binding var position_item_view_presented: Bool

    #if os(iOS)
    let is_compact: Bool
    #endif

    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            HStack
            {
                PositionView(position: positionBinding())
            }
            .padding([.horizontal, .top])
            #else
            if !is_compact
            {
                HStack
                {
                    PositionView(position: positionBinding())
                }
                .padding([.horizontal, .top])
            }
            else
            {
                VStack
                {
                    PositionView(position: positionBinding())
                }
                .padding([.horizontal, .top])
                
                Spacer()
            }
            #endif
            
            HStack
            {
                Picker("Type", selection: $point.move_type)
                {
                    ForEach(MoveType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                #if os(macOS)
                .frame(maxWidth: .infinity)
                #else
                .frame(width: 96)
                .buttonStyle(.borderedProminent)
                #endif
                
                Text("Speed")
                #if os(macOS)
                    .frame(width: 40)
                #else
                    .frame(width: 60)
                #endif
                TextField("0", value: $point.move_speed, format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(macOS)
                    .frame(width: 48)
                #else
                    .frame(maxWidth: .infinity)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $point.move_speed, in: 0...100)
                    .labelsHidden()
            }
            .padding()
        }
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
                
                /*point.x = new_value.x
                point.y = new_value.y
                point.z = new_value.z
                point.r = new_value.r
                point.p = new_value.p
                point.w = new_value.w*/
            }
        )
    }
}

#Preview
{
    RobotControlView(robot: Robot())
        .frame(width: 400, height: 480)
        .padding(.vertical, 64)
}

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
    
    let shows_program_indices: Bool
    
    @Binding var is_vertical: Bool
    
    let on_update: () -> ()
    
    @State private var dragging_program_id: UUID?
    @State private var new_program_view_presented = false
    
    public init(
        robot: Robot,
        
        shows_program_indices: Bool = false,
        is_vertical: Binding<Bool> = .constant(true),
        
        on_update: @escaping () -> Void = {}
    )
    {
        self.robot = robot
        
        self.shows_program_indices = shows_program_indices
        self._is_vertical = is_vertical
        
        self.on_update = on_update
    }
    
    @Namespace private var animation_namespace
    
    @State private var new_view_is_expanded = false
    @State private var position_pane_is_expanded = false
    
    public var body: some View
    {
        DynamicStack(is_vertical: $is_vertical, vertical_alignment: .center, spacing: 10) // VStack(alignment: .center, spacing: 10)
        {
            VStack(spacing: 10)
            {
                // MARK: Caption
                PerformingCaptionView(name: robot.name, performing_state: robot.performing_state)
                    .frame(maxWidth: is_vertical ? pendant_content_width : .infinity)
                    //.frame(width: pendant_content_width)
                
                // MARK: Program
                ZStack
                {
                    Rectangle()
                        .fill(.clear)
                        .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                    
                    ScrollView
                    {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible()),
                                count: is_vertical ? 1 : 3
                            ),
                            spacing: 8
                        )
                        {
                            ForEach(Array(robot.programs.enumerated()), id: \.element.id)
                            { index, program in
                                if robot.selected_program == nil
                                {
                                    ProgramItemView(
                                        name: Binding(
                                            get: { program.name },
                                            set: { new_value in
                                                if let index = robot.programs.firstIndex(where: { $0.id == program.id })
                                                {
                                                    robot.programs[index].name = unique_name(for: new_value, in: robot.program_names)
                                                    on_update()
                                                }
                                            }
                                        ),
                                        count: program.points_count,
                                        on_update: on_update,
                                        on_duplicate:
                                        {
                                            robot.add_program(clone_codable(program) ?? PositionProgram())
                                        },
                                        on_delete:
                                        {
                                            robot.programs.remove(at: index)
                                            on_update()
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
                                    .onDrop(
                                        of: [.text],
                                        delegate: ProgramDropDelegate(
                                            robot: robot,
                                            
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
                            .animation(.spring(), value: robot.programs)
                        }
                        .padding(8)
                        
                        Spacer(minLength: 48)
                    }
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))
                    
                    if let program = robot.selected_program
                    {
                        PositionProgramView(
                            robot: robot,
                            program: program,
                            is_vertical: $is_vertical,
                            on_update: on_update
                        )
                        {
                            deselect_program()
                        }
                        .matchedGeometryEffect(id: program.id, in: animation_namespace)
                        .zIndex(1)
                    }
                }
                .overlay(alignment: .bottomTrailing)
                {
                    HStack(spacing: 0)
                    {
                        if robot.selected_program != nil
                        {
                            PerformingControlView(
                                reset_performing: { robot.reset_moving() },
                                start_pause_performing: { robot.start_pause_moving() },
                                
                                program_performed: robot.program_performed
                            )
                            
                            Spacer()
                        }
                        
                        NewElementButton(
                            with_name: robot.selected_program == nil,
                            is_expanded: $new_view_is_expanded,
                            names: robot.program_names,
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
            }
            .frame(
                minWidth: pendant_content_width, maxWidth: is_vertical ? pendant_content_width : max_pendant_content_width,
                maxHeight: is_vertical ? max_pendant_content_height : pendant_content_height
            )
            
            // MARK: Controls
            VStack(alignment: .center, spacing: 10)
            {
                PositionPane (
                    robot: robot,
                    on_expand: { position_pane_is_expanded = true },
                    on_collapse: { position_pane_is_expanded = false }
                )
                .zIndex(1)
                
                if !position_pane_is_expanded
                {
                    PositionControl(robot: robot)
                        .frame(width: 120)
                        .transition(.scale(scale: 0, anchor: .center).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: Functions
    private func add_item()
    {
        if let program = robot.selected_program
        {
            program.add_point(PositionPoint(x: robot.pointer_position.x, y: robot.pointer_position.y, z: robot.pointer_position.z, r: robot.pointer_position.r, p: robot.pointer_position.p, w: robot.pointer_position.w))
            robot.update_program_entity(by: program)
            
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
            robot.update_program_entity(by: program)
            
            robot.toggle_position_program_visibility()
            
            // Performing Handling
            robot.select_program(named: program.name)
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
    let robot: Robot
    
    let current_program: PositionProgram
    @Binding var dragging_program_id: UUID?
    
    let on_update: () -> ()
    
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
        on_update()
        
        return true
    }
}

// MARK: - Program View
private struct PositionProgramView: View
{
    @ObservedObject var robot: Robot
    
    @ObservedObject var program: PositionProgram
    
    @Binding var is_vertical: Bool
    
    let on_update: () -> ()
    
    let dismiss_function: () -> ()
    
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
                    #if !os(macOS)
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
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible()),
                        count: is_vertical ? 1 : 3
                    ),
                    spacing: 8
                )
                {
                    ForEach(Array(program.points.enumerated()), id: \.element.id)
                    { index, point in
                        PositionItemView(
                            robot: robot,
                            program: program,
                            point_item: point,
                            point_index: index,
                            on_update: on_update
                        )
                        {
                            robot.reset_moving()
                            
                            program.points.remove(at: index)
                            robot.update_program_entity(by: program)
                        }
                        .onDrag
                        {
                            robot.reset_moving()
                            
                            dragging_point_id = point.id
                            return NSItemProvider(object: point.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: PositionDropDelegate(
                                robot: robot,
                                program: program,
                                
                                current_point: point,
                                dragging_point_id: $dragging_point_id,
                                
                                on_update: on_update
                            )
                        )
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
                .padding(8)
                
                Spacer(minLength: 48)
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
    
    let point_index: Int
    
    @State private var position_item_view_presented = false
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    let on_update: () -> ()
    let on_delete: () -> ()
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            Image(systemName: "circle.fill")
            #if !os(visionOS)
                .foregroundColor(point_item.performing_state.color)
            #else
                .foregroundColor(.clear)
                .glassEffect(.regular.tint(point_item.performing_state.color).interactive(), in: .circle)
            #endif
                .font(.system(size: program_item_light_size))
                .padding(.leading, program_item_light_padding)
            
            ZStack
            {
                VStack(spacing: 6)
                {
                    
                    ZStack
                    {
                        Text("X: \(String(format: "%.0f", point_item.x)) Y: \(String(format: "%.0f", point_item.y)) Z: \(String(format: "%.0f", point_item.z))")
                            .font(.system(size: position_item_font_size))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    //Divider()
                    
                    ZStack
                    {
                        Text("R: \(String(format: "%.0f", point_item.r)) P: \(String(format: "%.0f", point_item.p)) W: \(String(format: "%.0f", point_item.w))")
                            .font(.system(size: position_item_font_size))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .popover(
                isPresented: $position_item_view_presented,
                /*arrowEdge: {
                    #if os(macOS)
                    .bottom
                    #else
                    .top
                    #endif
                }()*/
            )
            {
                #if os(macOS)
                PositionPointView(robot: robot, program: program, point: point_item, point_index: point_index, position_item_view_presented: $position_item_view_presented)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                #elseif os(iOS)
                PositionPointView(robot: robot, program: program, point: point_item, point_index: point_index, position_item_view_presented: $position_item_view_presented, is_compact: horizontal_size_class == .compact)
                    .presentationDetents([.height(496)])
                #elseif os(visionOS)
                PositionPointView(robot: robot, program: program, point: point_item, point_index: point_index, position_item_view_presented: $position_item_view_presented)
                    .frame(width: 360)
                #endif
            }
            
            Image(systemName: point_item.move_type.symbol_name)
                .font(.system(size: program_item_light_size * 1.5))
                .frame(width: program_item_light_size * 2, height: program_item_light_size * 2)
                .padding(.trailing, program_item_light_padding)
        }
        .frame(height: program_item_height)
        .contentShape(Rectangle())
        .background
        {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
            #if !os(visionOS)
                .fill(.quinary)
            #else
                .fill(.thinMaterial)
            #endif
        }
        .onTapGesture
        {
            position_item_view_presented.toggle()
        }
        .contextMenu
        {
            Button
            {
                program.add_point(clone_codable(point_item) ?? PositionPoint())
                on_update()
            }
            label:
            {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            
            Divider()
            
            Button(role: .destructive)
            {
                on_delete()
                on_update()
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
    let robot: Robot
    let program: PositionProgram
    
    let current_point: PositionPoint
    @Binding var dragging_point_id: UUID?
    
    let on_update: () -> ()
    
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
        robot.update_program_entity(by: program)
        on_update()
        
        return true
    }
}

private struct PositionPointView: View
{
    @ObservedObject var robot: Robot
    @ObservedObject var program: PositionProgram
    
    @ObservedObject var point: PositionPoint
    
    let point_index: Int
    
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
            
            PositionView(position: position_binding(), with_steppers: true)
            
            Divider()
            
            HStack
            {
                let move_type = Binding(
                    get: { point.move_type },
                    set:
                        { new_value in
                            point.move_type = new_value
                            
                            robot.update_program_entity(by: program, point_index: point_index)
                        }
                )
                
                Text("Type")
                    .fontWeight(.light)
                
                Spacer()
                
                Picker("Type", selection: move_type)//$point.move_type)
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
            
            if point.move_type == .spline
            {
                let spline_point_bidnding = Binding<(x: Float, y: Float, z: Float)>(
                    get:
                        {
                            if let spline_point = point.spline_points?.first
                            {
                                return (x: spline_point.x, y: spline_point.y, z: spline_point.z)
                            }
                            else
                            {
                                return (x: 0, y: 0, z: 0)
                            }
                        },
                    set:
                        { new_value in
                            if point.spline_points?.first != nil
                            {
                                var new_point = PositionPoint(x: new_value.x, y: new_value.y, z: new_value.z)
                                robot.point_shift(&new_point)
                                
                                point.spline_points?[0] = SIMD3<Float>(new_point.x, new_point.y, new_point.z)
                                
                                robot.update_program_entity(by: program, point_index: point_index)
                            }
                        }
                )
                
                PositionView(location: spline_point_bidnding, with_steppers: true)
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
                Stepper("Speed", value: $point.move_speed, in: 0...100)
                    .labelsHidden()
                    #if os(visionOS)
                    .scaleEffect(0.8)
                    #endif
            }
        }
        .padding()
        .onAppear
        {
            robot.update_program_entity(by: program, point_index: point_index)
        }
        .onDisappear
        {
            robot.update_program_entity(by: program)
        }
    }

    private func position_binding() -> Binding<(x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)>
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
                
                robot.update_program_entity(by: program, point_index: point_index)
            }
        )
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
        
        @State var is_vertical = true
        
        var body: some View
        {
            ZStack
            {
                #if !os(visionOS)
                FloatingView(
                    alignment: .trailing,
                    on_overflow: { _ in is_vertical.toggle() }
                )
                {
                    RobotControlView(robot: robot, shows_program_indices: true, is_vertical: $is_vertical)
                        .padding(8)
                }
                .padding(10)
                #else
                RobotControlView(robot: robot, shows_program_indices: true, is_vertical: $is_vertical)
                    .padding(8)
                    .background(
                        GeometryReader
                        { geometry in
                            Rectangle()
                                .fill(.clear)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))
                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    )
                    .padding(10)
                #endif
            }
            #if !os(visionOS)
            .frame(minWidth: 640, minHeight: 480)
            #else
            .frame(minWidth: 800, minHeight: 480)
            #endif
            #if os(visionOS)
            .overlay(alignment: .topLeading)
            {
                Button(is_vertical ? "Vertical" : "Horizontal")
                {
                    withAnimation
                    {
                        is_vertical.toggle()
                    }
                }
                .padding()
            }
            #endif
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

/*import RealityKit
struct RobotTrajectoryView: View
{
    @State private var scene_content: RealityViewCameraContent?
    @ObservedObject private var robot = Robot(
        name: "6DOF Robot",
        entity: ModelEntity(
            mesh: .generateBox(size: Float(0.05), cornerRadius: Float(0.005)),
            materials: [SimpleMaterial(color: .systemMint, isMetallic: true)]
        )
    )
    @State private var opened = false
    @State private var camera_entity = Entity()
    
    @State private var selected_point_index = 0
    
    var body: some View
    {
        ZStack(alignment: .bottom)
        {
            RealityView
            { content in
                scene_content = content
                
                let camera = PerspectiveCamera()
                camera.position.z = 0.5
                content.add(camera)
            }
            .realityViewCameraControls(.orbit)
            .task { place_robot() }
            
            if opened
            {
                HStack(spacing: 0)
                {
                    Spacer()
                    
                    VStack(spacing: 0)
                    {
                        HStack
                        {
                            Button
                            {
                                if selected_point_index == 0 { selected_point_index = robot.selected_program!.points_count - 1 }
                                else { selected_point_index -= 1 }
                                robot.update_program_entity(by: robot.selected_program!, point_index: selected_point_index)
                            } label: { Image(systemName: "chevron.left").padding() }
                                .buttonStyle(.plain)
                            
                            Text("\(selected_point_index)")
                            
                            Button
                            {
                                if selected_point_index < robot.selected_program!.points_count - 1 { selected_point_index += 1 }
                                else { selected_point_index = 0 }
                                robot.update_program_entity(by: robot.selected_program!, point_index: selected_point_index)
                            } label: { Image(systemName: "chevron.right").padding() }
                                .buttonStyle(.plain)
                        }
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        PositionPointView(robot: robot, program: robot.selected_program!, point: robot.selected_program!.points[selected_point_index], point_index: selected_point_index, position_item_view_presented: .constant(true))
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .frame(width: 320)
                            .padding()
                    }
                }
                .overlay(alignment: .bottomLeading)
                {
                    HStack
                    {
                        Button
                        {
                            robot.start_pause_moving()
                            robot.objectWillChange.send()
                        }
                        label:
                        {
                            Image(systemName: robot.program_performed ? "pause.fill" : "play.fill")
                                .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                                .padding(8)
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.glass)
                        
                        Button
                        {
                            robot.reset_moving()
                        }
                        label:
                        {
                            Image(systemName: "stop.fill")
                                .padding(8)
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.glass)
                    }
                    .padding()
                }
            }
        }
        .frame(width: 700, height: 700)
        .overlay(alignment: .topLeading)
        {
            PositionPane(robot: robot)
                .padding()
        }
    }
    
    private func place_robot()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
        {
            scene_content?.add(robot.entity)
            robot.position.y = -250
            robot.position.z = -100
            
            robot.add_program(
                PositionProgram(
                    name: "Program",
                    points: [
                        .init(x: 0, y: 0, z: 0),
                        .init(x: 0, y: 100, z: 0, move_type: .spline, spline_points: [.init(x: 0, y: 50, z: 50)]),
                        .init(x: 0, y: 100, z: 100)
                        /*.init(x: 0, y: 0, z: 0),
                        .init(x: 0, y: 100, z: 0),
                        .init(x: 0, y: 100, z: 0, p: 90)*/
                    ]
                )
            )
            
            robot.select_program(at: 0)
            
            opened = true
            
            robot.model_entity?.isEnabled = false
            
            robot.show_working_area()
            robot.show_position_pointer()
            robot.show_position_program()
        }
    }
}

#Preview
{
    RobotTrajectoryView()
}*/

//
//  PositionControl.swift
//  IndustrialKit
//
//  Created by Artem on 15.01.2026.
//

import SwiftUI
import IndustrialKit

// MARK: - Position Control
public struct PositionControl: View
{
    @ObservedObject var robot: Robot
    
    @State private var tilt_x: CGFloat = 0
    @State private var tilt_y: CGFloat = 0
    @State private var is_touching = false
    
    private let max_tilt: CGFloat = 5
    private let panel_update_interval: TimeInterval = 0.016 // ~60 FPS
    
    @State private var is_central_pressed = false
    
    @State private var control_state: ControlState = .xy_movement
    
    public init(robot: Robot)
    {
        self.robot = robot
    }
    
    private enum ControlState: String, Equatable, CaseIterable
    {
        case xy_movement = "XY"
        case xz_movement = "XZ"
        case pw_movement = "PW"
        case pr_movement = "PR"
        
        var c1_image_name: String
        {
            switch self {
            case .xy_movement:
                "chevron.up"
            case .xz_movement:
                "arrow.up"
            case .pw_movement:
                "arrow.trianglehead.topright.capsulepath.clockwise"
            case .pr_movement:
                "arrow.trianglehead.topright.capsulepath.clockwise"
            }
        }
        
        var c2_image_name: String
        {
            switch self {
            case .xy_movement:
                "chevron.right"
            case .xz_movement:
                "chevron.right"
            case .pw_movement:
                "arrow.turn.up.right"
            case .pr_movement:
                "arrow.trianglehead.clockwise.rotate.90"
            }
        }
        
        var c3_image_name: String
        {
            switch self {
            case .xy_movement:
                "chevron.down"
            case .xz_movement:
                "arrow.down"
            case .pw_movement:
                "arrow.trianglehead.bottomleft.capsulepath.clockwise"
            case .pr_movement:
                "arrow.trianglehead.bottomleft.capsulepath.clockwise"
            }
        }
        
        var c4_image_name: String
        {
            switch self {
            case .xy_movement:
                "chevron.left"
            case .xz_movement:
                "chevron.left"
            case .pw_movement:
                "arrow.turn.up.left"
            case .pr_movement:
                "arrow.trianglehead.counterclockwise.rotate.90"
            }
        }
    }
    
    public var body: some View
    {
        ZStack
        {
            HStack(spacing: 0)
            {
                Image(systemName: control_state.c4_image_name)
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .animation(.easeInOut(duration: 0.3), value: control_state)
                
                Spacer()
                
                Image(systemName: control_state.c2_image_name)
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .animation(.easeInOut(duration: 0.3), value: control_state)
            }
            .font(.system(size: 16))
            .padding(10)
            .opacity(0.2)
            
            VStack(spacing: 0)
            {
                Image(systemName: control_state.c1_image_name)
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .animation(.easeInOut(duration: 0.3), value: control_state)
                
                Spacer()
                
                Image(systemName: control_state.c3_image_name)
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .animation(.easeInOut(duration: 0.3), value: control_state)
            }
            .font(.system(size: 16))
            .padding(10)
            .opacity(0.2)
            
            Rectangle()
                .fill(.clear)
            
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.quinary)
                .frame(width: 48, height: 48)
                .scaleEffect(is_central_pressed ? 0.85 : 1)
                .animation(
                    .interactiveSpring(
                        response: 0.35 + (0.2 * (1 - (is_central_pressed ? 0.85 : 1))),
                        dampingFraction: 0.6,
                        blendDuration: 0
                    ),
                    //.interactiveSpring(response: 0.35, dampingFraction: 0.6, blendDuration: 0),
                    value: is_central_pressed
                )
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onChanged
                        { _ in
                            is_central_pressed = true
                        }
                        .onEnded
                        { _ in
                            long_press_action()
                            is_central_pressed = false
                        }
                        .simultaneously(with:
                            TapGesture()
                                .onEnded
                                {
                                    is_central_pressed = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
                                    {
                                        //is_central_pressed = false
                                        tap_action()
                                        is_central_pressed = false
                                    }
                                }
                        )
                )
        }
        .frame(width: 120, height: 120)
        .glassEffect(.regular.tint(.white).interactive(), in: .rect(cornerRadius: 32, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .compositingGroup()
        .rotation3DEffect(.degrees(tilt_magnitude), axis: (x: tilt_x, y: tilt_y, z: 0), perspective: 0.12)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged
                { value in
                    update_tilt(location: value.location)
                    
                    if !is_touching
                    {
                        is_touching = true
                        start_continuous_update()
                    }
                }
                .onEnded { _ in reset_tilt() }
        )
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8), value: tilt_x)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8), value: tilt_y)
    }
    
    private var tilt_magnitude: Double
    {
        Double(sqrt(tilt_x * tilt_x + tilt_y * tilt_y))
    }
    
    // MARK: - Tilt logic
    private func update_tilt(location: CGPoint)
    {
        is_central_pressed = false
        
        let size: CGFloat = 120
        
        let nx = ((location.x / size) - 0.5) * 2
        let ny = ((location.y / size) - 0.5) * 2
        
        let clamped_x = max(-1, min(1, nx))
        let clamped_y = max(-1, min(1, ny))
        
        tilt_y = clamped_x * max_tilt
        tilt_x = -clamped_y * max_tilt
    }
    
    private func reset_tilt()
    {
        tilt_x = 0
        tilt_y = 0
        is_touching = false
    }
    
    // MARK: - Incremental control
    private var intensity: CGFloat
    {
        min(1, sqrt(tilt_x * tilt_x + tilt_y * tilt_y) / max_tilt)
    }
    
    private var curved_intensity: CGFloat
    {
        intensity * intensity
    }
    
    private func apply_incremental_control()
    {
        let dy = -Float(tilt_y / max_tilt) * Float(curved_intensity)
        let dx = Float(tilt_x / max_tilt) * Float(curved_intensity)
        
        switch control_state
        {
        case .xy_movement:
            robot.pointer_position.x += dx
            robot.pointer_position.y += dy
        case .xz_movement:
            robot.pointer_position.z += dx
            robot.pointer_position.y += dy
        case .pw_movement:
            robot.pointer_position.p += dx
            robot.pointer_position.w += dy
        case .pr_movement:
            robot.pointer_position.p += dx
            robot.pointer_position.r += dy
        }
    }
    
    // MARK: - Continuous update while touching
    private func start_continuous_update()
    {
        Task
        {
            while is_touching
            {
                apply_incremental_control()
                try? await Task.sleep(nanoseconds: UInt64(panel_update_interval * 1_000_000_000))
            }
        }
    }
    
    // MARK: – Central press
    private func tap_action()
    {
        switch control_state
        {
        case .xy_movement:
            control_state = .xz_movement
        case .xz_movement:
            control_state = .xy_movement
        case .pw_movement:
            control_state = .pr_movement
        case .pr_movement:
            control_state = .pw_movement
        }
    }
    
    private func long_press_action()
    {
        switch control_state
        {
        case .xy_movement:
            control_state = .pw_movement
        case .xz_movement:
            control_state = .pr_movement
        case .pw_movement:
            control_state = .xz_movement
        case .pr_movement:
            control_state = .xy_movement
        }
    }
}

// MARK: - Position Pane
public struct PositionPane: View
{
    @ObservedObject var robot: Robot

    @State private var is_expanded = true
    @State private var is_editor_mode = false
    @State private var is_central_pressed = false

    @Namespace private var pane_glass
    
    public init(robot: Robot)
    {
        self.robot = robot
    }

    public var body: some View
    {
        GlassEffectContainer
        {
            ZStack
            {
                if !is_expanded && !is_editor_mode
                {
                    HStack
                    {
                        Spacer()
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        #if os(macOS)
                            .frame(width: 32, height: 32)
                        #else
                            .frame(width: 40, height: 40)
                        #endif
                            .background(.clear)
                            .clipShape(Circle())
                            .glassEffect(.regular.interactive(), in: .circle)
                            .matchedGeometryEffect(id: "glass", in: pane_glass)
                            .contentShape(Circle())
                            .onTapGesture
                            {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                                {
                                    is_expanded = true
                                }
                            }
                    }
                    .frame(width: 120)
                    .transition(.opacity.combined(with: .scale(scale: 1.0)))
                }
                else if is_expanded && !is_editor_mode
                {
                    // Coordinate Pane
                    VStack(alignment: .center, spacing: 10)
                    {
                        ZStack
                        {
                            Text("X \(String(format: "%.0f", robot.pointer_position.x)) Y \(String(format: "%.0f", robot.pointer_position.y)) Z \(String(format: "%.0f", robot.pointer_position.z))")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        ZStack
                        {
                            Text("R \(String(format: "%.0f", robot.pointer_position.r)) P \(String(format: "%.0f", robot.pointer_position.p)) W \(String(format: "%.0f", robot.pointer_position.w))")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(8)
                    .frame(width: 120)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
                    .matchedGeometryEffect(id: "glass", in: pane_glass)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .scaleEffect(is_central_pressed ? 0.95 : 1)
                    .animation(
                        .interactiveSpring(response: 0.35, dampingFraction: 0.6, blendDuration: 0),
                        value: is_central_pressed
                    )
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onChanged { _ in
                                is_central_pressed = true
                            }
                            .onEnded { _ in
                                long_press_action()
                                is_central_pressed = false
                            }
                            .simultaneously(with:
                                TapGesture()
                                    .onEnded {
                                        tap_action()
                                    }
                            )
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                else if is_editor_mode
                {
                    // Editor
                    VStack(spacing: 0)
                    {
                        HStack
                        {
                            PositionView(position: $robot.pointer_position)
                                .opacity(is_editor_mode ? 1 : 0)
                        }
                        .padding(10)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                is_editor_mode = false
                            }
                        })
                        {
                            Image(systemName: "chevron.compact.down")
                            #if !os(macOS)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                            #endif
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 10)
                        .scaleEffect(is_editor_mode ? 1 : 0.01)
                        .contentShape(Rectangle())
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: is_editor_mode)
                    }
                    #if os(macOS)
                    .frame(width: is_editor_mode ? 280 : 120)
                    #else
                    .frame(width: is_editor_mode ? 576 : 120)
                    #endif
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
                    .matchedGeometryEffect(id: "glass", in: pane_glass)
                    .animation(.spring(response: 0.35, dampingFraction: 0.95), value: is_editor_mode)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.95), value: is_expanded)
    }

    // MARK: – Central press actions
    private func tap_action()
    {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.95))
        {
            is_editor_mode = true
        }
    }

    private func long_press_action()
    {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.95))
        {
            is_expanded = false
            is_editor_mode = false
        }
    }
}

// MARK: - Previews
struct PositionControl_Previews: PreviewProvider
{
    struct Container: View
    {
        @State private var is_spatial = false
        @State var is_pan = true
        
        @StateObject var robot = Robot()
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                Spacer()
                
                PositionPane(robot: robot)
                
                PositionControl(robot: robot)
                    .padding()
            }
            .frame(width: 400, height: 400)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

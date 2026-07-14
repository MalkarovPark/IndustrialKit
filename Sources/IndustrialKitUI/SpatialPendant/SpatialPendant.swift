//
//  SpatialPendant.swift
//  IndustrialKit
//
//  Created by Artem on 09.02.2024.
//

import SwiftUI
import IndustrialKit

import RealityKit

public struct SpatialPendant: View
{
    @ObservedObject var controller: PendantController
    @ObservedObject var workspace: Workspace
    
    let shows_program_indices: Bool
    
    let on_update_workspace: () -> ()
    let on_update_robot: () -> ()
    let on_update_tool: () -> ()
    
    public init(
        controller: PendantController,
        //workspace: Workspace,
        
        shows_program_indices: Bool = false,
        
        on_update_workspace: @escaping () -> () = {},
        on_update_robot: @escaping () -> () = {},
        on_update_tool: @escaping () -> () = {}
    )
    {
        self.controller = controller
        self.workspace = controller.workspace
        //self.workspace = workspace
        
        self.shows_program_indices = shows_program_indices
        
        self.on_update_workspace = on_update_workspace
        self.on_update_robot = on_update_robot
        self.on_update_tool = on_update_tool
    }
    
    public var body: some View
    {
        #if os(macOS) || os(iOS)
        FloatingView(alignment: .trailing)
        {
            ZStack
            {
                if is_opened
                {
                    ZStack
                    {
                        switch workspace.selected_object
                        {
                        case let robot as Robot:
                            RobotControlView(
                                robot: robot,
                                shows_program_indices: shows_program_indices,
                                on_update: on_update_robot
                            )
                        case let tool as Tool:
                            ToolControlView(
                                tool: tool,
                                shows_program_indices: shows_program_indices,
                                on_update: on_update_tool
                            )
                        case is Part:
                            ZStack
                            {
                                Rectangle()
                                    .fill(.clear)
                                    .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                            }
                        case .some(_):
                            Text("Nothing")
                        case .none:
                            WorkspaceControlView(
                                workspace: workspace,
                                on_update: on_update_workspace
                            )
                        }
                    }
                    .padding(8)
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .animation(.easeInOut(duration: 0.3), value: workspace.selected_object)
                }
                else
                {
                    ZStack
                    {
                        Rectangle()
                            .fill(.clear)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                    }
                    .frame(width: pendant_content_width)
                    .hidden()
                }
            }
        }
        .scaleEffect(is_opened ? 1.0 : 0.82, anchor: .center)
        .opacity(is_opened ? 1 : 0)
        .offset(x: is_opened ? 0 : 40)
        .allowsHitTesting(is_opened)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: is_opened)
        .animation(.easeInOut(duration: 0.25), value: is_opened)
        #else
        ZStack
        {
            switch workspace.selected_object
            {
            case let robot as Robot:
                RobotControlView(
                    robot: robot,
                    shows_program_indices: shows_program_indices,
                    on_update: on_update_robot
                )
            case let tool as Tool:
                ToolControlView(
                    tool: tool,
                    shows_program_indices: shows_program_indices,
                    on_update: on_update_tool
                )
            case is Part:
                EmptyView()
            case .some(_):
                Text("Nothing")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundStyle(.secondary)
            case .none:
                WorkspaceControlView(
                    workspace: workspace,
                    on_update: on_update_workspace
                )
            }
        }
        .padding(8)
        .contentTransition(.symbolEffect(.replace.offUp.byLayer))
        .animation(.easeInOut(duration: 0.3), value: workspace.selected_object)
        //.frame(width: pendant_content_width)
        #endif
    }
    
    private var is_opened: Bool
    {
        return controller.is_opened && !(workspace.selected_object is Part)
    }
}

#if os(macOS)
let pendant_content_width: CGFloat = 200
#elseif os(iOS)
let pendant_content_width: CGFloat = 240
#elseif os(visionOS)
let pendant_content_width: CGFloat = 280
#endif

#if os(visionOS)
/**
 A view that provides the universal spatial pendant for industrial applications.
 
 This pendant can change its content according to selected *workspace*, *robot* or *tool*.
 */
public struct SpatialPendantScene: SwiftUI.Scene
{
    var window_id: String
    let controller: PendantController
    
    public init(
        window_id: String = SPendantDefaultID,
        controller: PendantController
    )
    {
        self.window_id = window_id
        self.controller = controller
    }
    
    @SceneBuilder public var body: some SwiftUI.Scene
    {
        WindowGroup(id: window_id)
        {
            SpatialPendant(controller: controller)//, workspace: controller.workspace)
                .onDisappear(perform: controller.on_dismiss)
                .glassBackgroundEffect(in: .rect(cornerRadius: 24, style: .continuous))
                .frame(minHeight: 640, idealHeight: 640, maxHeight: 800)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
    }
}

///The default widow id of Spatial Pendant.
public let SPendantDefaultID = "pendant"
#endif

// MARK: - Previews
struct SpatialPendant_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var workspace = Workspace()
        @StateObject var pendant_controller = PendantController()
        
        @State private var is_pan = false
        #if os(macOS) || os(iOS)
        @State private var scene_content: RealityViewCameraContent?
        
        let stack_height: CGFloat = 480
        #else
        @State private var scene_content: RealityViewContent?
        
        let stack_height: CGFloat = 600
        #endif
        
        var body: some View
        {
            Group
            {
                ZStack
                {
                    SpatialPendant(
                        controller: pendant_controller,
                        shows_program_indices: true
                    )
                    #if os(visionOS)
                    .glassBackgroundEffect(in: .rect(cornerRadius: 24, style: .continuous))
                    #endif
                }
                #if !os(visionOS)
                .frame(minWidth: 480, minHeight: 480)
                #else
                .frame(minWidth: 800, minHeight: 480)
                #endif
                .padding(10)
                .background(alignment: .topLeading)
                {
                    Button(
                        workspace.selected_object is Robot
                        ? "Robot"
                        : workspace.selected_object is Tool
                        ? "Tool"
                        : workspace.selected_object is Part
                        ? "Part"
                        : "Workspace"
                    )
                    {
                        button_tap()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                
                HStack(spacing: 16)
                {
                    SpatialPendant(
                        controller: pendant_controller,
                        shows_program_indices: true
                    )
                    #if os(visionOS)
                    .glassBackgroundEffect(in: .rect(cornerRadius: 24, style: .continuous))
                    #endif
                    .frame(height: stack_height)
                    .padding(10)
                    .zIndex(1)
                    
                    #if !os(visionOS)
                    Spacer()
                    #endif
                    
                    WorkspaceControlView(workspace: workspace)
                        .padding(8)
                        .frame(height: stack_height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.tertiary, lineWidth: 1)
                        )
                        .padding(10)
                    
                    RobotControlView(robot: workspace.robot(named: "6DOF Robot"))
                        .padding(8)
                        .frame(height: stack_height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.tertiary, lineWidth: 1)
                        )
                        .padding(10)
                    
                    ToolControlView(tool: workspace.tool(named: "Gripper"))
                        .padding(8)
                        .frame(height: stack_height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.tertiary, lineWidth: 1)
                        )
                        .padding(10)
                }
                .frame(minWidth: 1024)
                .padding(80)
            }
            .onAppear
            {
                workspace_preparation()
                set_programs()
                initialize_current_element_defaults()
            }
        }
        
        @State var inc = 0
        
        private func button_tap()
        {
            switch inc
            {
            case 0:
                pendant_controller.is_opened = true
                workspace.deselect_object()
            case 1:
                workspace.select_robot(named: "6DOF Robot")
            case 2:
                workspace.select_tool(named: "Gripper")
            case 3:
                workspace.select_part(named: "Cup")
            default:
                pendant_controller.is_opened = false
            }
            
            inc += 1
            if inc > 3/*4*/ { inc = 0 }
        }
        
        private func workspace_preparation()
        {
            pendant_controller.workspace = workspace
            
            workspace.robots.append(Robot(name: "6DOF Robot"))
            workspace.robots.append(Robot(name: "Portal Robot"))
            
            workspace.tools.append(Tool(name: "Drill"))
            workspace.tools.append(Tool(name: "Gripper"))
            workspace.tool(named: "Gripper").codes = [
                .init(value: 0, name: "Close", symbol_name: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", description: "Close the Tool"),
                .init(value: 1, name: "Open", symbol_name: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", description: "Open the Tool")
            ]
            
            workspace.parts.append(Part(name: "Cup"))
            workspace.parts.append(Part(name: "Book"))
            
            button_tap()
        }
        
        private func set_programs()
        {
            workspace.add_program(
                ProductionProgram(
                    name: "Move Part",
                    elements: [
                        WriterModifierElement(inputs: [
                            WriterInput(value: 0, to: 0),
                            WriterInput(value: 90, to: 3),
                            WriterInput(value: 100, to: 4),
                            
                            WriterInput(value: 0, to: 5)
                        ]),
                        ToolPerformerElement(object_name: "Gripper", is_single_perfrom: true, opcode_index: 5),
                        RobotPerformerElement(
                            object_name: "6DOF Robot",
                            is_single_perfrom: true,
                            x_index: 1,
                            p_index: 3,
                            speed_index: 4
                        ),
                        
                        WriterModifierElement(inputs: [
                            WriterInput(value: 1, to: 5)
                        ]),
                        ToolPerformerElement(object_name: "Gripper", is_single_perfrom: true, opcode_index: 5),
                        MathModifierElement(expression: "100 - [1]", to_index: 1)
                    ]
                )
            )
            
            workspace.robot(named: "6DOF Robot").add_program(
                PositionProgram(
                    name: "Square",
                    points: [
                        .init(x: 0, y: 0, z: 50, p: 45),
                        .init(x: 0, y: 50, z: 50, p: 45),
                        .init(x: 0, y: 50, z: 0),
                        .init(x: 0, y: 0, z: 0)
                    ]
                )
            )
            
            workspace.robot(named: "6DOF Robot").pointer_position = (x: 100, y: 0, z: 0, r: 0, p: 90, w: 0)
            
            workspace.tool(named: "Gripper").add_program(
                OperationProgram(
                    name: "Double Bite",
                    codes: [
                        .init(0),
                        .init(1),
                        .init(0),
                        .init(1)
                    ]
                )
            )
        }
        
        private func initialize_current_element_defaults()
        {
            if let element = workspace.current_element as? RobotPerformerElement, element.object_name == ""
            {
                element.object_name = workspace.placed_robot_names.first ?? String()
                
                if workspace.robot(named: element.object_name).program_names.count > 0
                {
                    element.program_name = workspace.robot(named: element.object_name).program_names.first ?? ""
                }
            }
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

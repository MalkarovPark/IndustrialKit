//
//  SpatialPendantView.swift
//  IndustrialKit
//
//  Created by Artem on 09.02.2024.
//

import SwiftUI
import IndustrialKit

import RealityKit

public struct SpatialPendantView: View
{
    @ObservedObject var controller: PendantController
    @ObservedObject var workspace: Workspace
    
    let shows_program_indices: Bool
    
    let on_update_workspace: () -> ()
    let on_update_robot: () -> ()
    let on_update_tool: () -> ()
    
    public init(
        controller: PendantController,
        workspace: Workspace,
        
        shows_program_indices: Bool = false,
        
        on_update_workspace: @escaping () -> () = {},
        on_update_robot: @escaping () -> () = {},
        on_update_tool: @escaping () -> () = {}
    )
    {
        self.controller = controller
        self.workspace = workspace
        
        self.shows_program_indices = shows_program_indices
        
        self.on_update_workspace = on_update_workspace
        self.on_update_robot = on_update_robot
        self.on_update_tool = on_update_tool
    }
    
    public var body: some View
    {
        FloatingView(alignment: .trailing)
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
                            
                            /*Text("Part")
                            #if os(macOS)
                                .font(.system(size: 14, design: .rounded))
                            #else
                                .font(.system(size: 18, design: .rounded))
                            #endif
                                .foregroundStyle(.secondary)*/
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
        .scaleEffect(is_opened ? 1.0 : 0.82, anchor: .center)
        .opacity(is_opened ? 1 : 0)
        .offset(x: is_opened ? 0 : 40)
        .allowsHitTesting(is_opened)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: is_opened)
        .animation(.easeInOut(duration: 0.25), value: is_opened)
    }
    
    private var is_opened: Bool
    {
        return controller.is_opened && !(workspace.selected_object is Part)
    }
}

#if os(macOS)
let pendant_content_width: CGFloat = 200
#else
let pendant_content_width: CGFloat = 240
#endif

#if os(visionOS)
/**
 A view that provides the universal spatial pendant for industrial applications.
 
 This pendant can change its content according to selected *workspace*, *robot* or *tool*.
 */
public struct SpatialPendantScene: Scene
{
    var window_id: String
    let controller: PendantController
    let workspace: Workspace
    
    public init(window_id: String = SPendantDefaultID, controller: PendantController, workspace: Workspace = Workspace())
    {
        self.window_id = window_id
        self.controller = controller
        
        self.workspace = workspace
    }
    
    @SceneBuilder public var body: some Scene
    {
        WindowGroup(id: window_id)
        {
            SpatialPendantView()
                .environmentObject(controller)
                .environmentObject(workspace)
                .onDisappear(perform: controller.dismiss_pendant)
        }
        .windowResizability(.contentSize)
    }
}

///The default widow id of Spatial Pendant.
public let SPendantDefaultID = "pendant"

    /*.ornament(attachmentAnchor: .scene(.bottom))
    {
        if controller.add_item_button_avaliable
        {
            Button(action: add_item)
            {
                ZStack
                {
                    Image(systemName: "plus")
                        .resizable()
                        .imageScale(.large)
                        .padding()
                }
                .frame(width: 64, height: 64)
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            .glassBackgroundEffect()
            .frame(depth: 24)
            .padding(32)
        }
    }
    .ornament(attachmentAnchor: .scene(.trailing))
    {
        VStack(spacing: 0)
        {
            Button(action: reset_performing)
            {
                ZStack
                {
                    Rectangle()
                        .foregroundStyle(controller.view_type != nil ? .red : .secondary)
                        .glassBackgroundEffect()
                    Image(systemName: "stop")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                }
                .frame(width: 64, height: 64)
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            .padding([.horizontal, .top])
            
            Button(action: start_pause_performing)
            {
                ZStack
                {
                    Image(systemName: "playpause")
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                .frame(width: 64, height: 64)
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            .padding()
        }
        .glassBackgroundEffect()
        .disabled(controller.view_type == .tool && workspace.selected_tool.programs_count == 0)
    }
    .disabled(controller.view_type == nil)
    .ornament(attachmentAnchor: .scene(.top))
    {
        
    }*/
#endif

// MARK: - Previews
struct SpatialPendant_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var workspace = Workspace()
        @StateObject var pendant_controller = PendantController()
        
        @State private var is_pan = false
        @State private var scene_content: RealityViewCameraContent?
        
        /*var body: some View
        {
            ZStack
            {
                RealityView
                { content in
                    scene_content = content
                    scene_content?.camera = .virtual
                    
                    workspace.place_entity(in: content)
                }
                .realityViewCameraControls(is_pan ? .pan : .orbit)
                .highPriorityGesture(
                    TapGesture()
                        .targetedToAnyEntity()
                        .onEnded
                        { value in
                            workspace.process_tap(value: value)
                        }
                )
                .gesture(
                    TapGesture()
                        .onEnded
                        {
                            workspace.process_empty_tap()
                        }
                )
                .overlay(alignment: .topLeading)
                {
                    Button("Switch") { button_tap(); test() }
                        .buttonStyle(.bordered)
                        .padding()
                }
                .overlay(alignment: .bottomLeading)
                {
                    Button(action: { is_pan.toggle() })
                    {
                        Image(systemName: is_pan ? "move.3d" : "rotate.3d")
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                
                SpatialPendantView(controller: pendant_controller, workspace: workspace)
                    .padding(10)
            }
            .frame(height: 480)
            .onAppear
            {
                workspace_preparation()
            }
        }
        
        func test()
        {
            let main = ModelEntity()
            let sphere = ModelEntity(
                mesh: MeshResource.generateSphere(radius: 0.05),
                materials: [SimpleMaterial(color: .systemTeal, isMetallic: true)]
            )
            
            sphere.update_position((x: 0, y: 0, z: -100, r: 0, p: 0, w: 0))
            
            let cube = ModelEntity(
                mesh: MeshResource.generateBox(size: 0.1),
                materials: [SimpleMaterial(color: .purple, isMetallic: true)]
            )
            
            main.addChild(cube)
            main.addChild(sphere)
            //cube.addChild(sphere)
            
            let part = Part(name: "Test", entity: main)
            part.position.z = 400
            part.physics_enabled = true
            
            workspace.add_part(part)
        }*/
        
        var body: some View
        {
            ZStack
            {
                SpatialPendantView(
                    controller: pendant_controller,
                    workspace: workspace, shows_program_indices: true
                )
            }
            .frame(minWidth: 480, minHeight: 480)
            .padding(10)
            .onAppear { workspace_preparation() }
            .overlay(alignment: .topLeading)
            {
                Button("Switch") { button_tap() }
                    .buttonStyle(.bordered)
                    .padding()
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
                workspace.select_robot(name: "6DOF Robot")
            case 2:
                workspace.select_tool(name: "Gripper")
            case 3:
                workspace.select_part(name: "Cup")
            default:
                pendant_controller.is_opened = false
            }
            
            //print(workspace.selected_object?.name ?? "Nothing")
            
            inc += 1
            if inc > 4 { inc = 0 }
        }
        
        private func workspace_preparation()
        {
            workspace.robots.append(Robot(name: "6DOF Robot"))
            workspace.robots.append(Robot(name: "Portal Robot"))
            
            workspace.tools.append(Tool(name: "Drill"))
            workspace.tools.append(Tool(name: "Gripper"))
            
            workspace.tool_by_name("Gripper").codes = [
                OperationCodeInfo(value: 0, name: "Close", symbol_name: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", description: "UwU"),
                OperationCodeInfo(value: 1, name: "Open", symbol_name: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", description: "OwO")
            ]
            
            workspace.parts.append(Part(name: "Cup"))
            workspace.parts.append(Part(name: "Book"))
            
            //print("Added")
            
            button_tap()
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

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
    
    public init(controller: PendantController, workspace: Workspace)
    {
        self.controller = controller
        self.workspace = workspace
    }
    
    public var body: some View
    {
        FloatingView(alignment: .trailing)
        {
            ZStack
            {
                switch workspace.selected_object
                {
                case let robot as Robot:
                    RobotControlView(robot: robot)
                case let tool as Tool:
                    ToolControlView(tool: tool)
                case is Part:
                    ZStack
                    {
                        Rectangle()
                            .fill(.clear)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                        
                        Text("Part")
                            #if os(macOS)
                            .font(.system(size: 12))
                            #else
                            .font(.system(size: 14))
                            #endif
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: pendant_content_width)
                case .some(_):
                    Text("Nothing")
                case .none:
                    WorkspaceControlView(workspace: workspace)
                }
            }
            .contentTransition(.symbolEffect(.replace.offUp.byLayer))
            .animation(.easeInOut(duration: 0.3), value: workspace.selected_object)
            .padding(8)
        }
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
        
        var body: some View
        {
            ZStack
            {
                RealityView
                { content in
                    scene_content = content
                    #if os(macOS)
                    scene_content?.camera = .virtual
                    #else
                    scene_content?.camera = is_spatial ? .spatialTracking : .virtual
                    #endif
                    
                    workspace.place_entity(to: content)
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
                    Button("Switch") { button_tap() }
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
            .onAppear { workspace_preparation() }
        }
        
        /*var body: some View
        {
            ZStack
            {
                SpatialPendantView(controller: pendant_controller, workspace: workspace)
            }
            .frame(height: 480)
            .padding(10)
            .onAppear { workspace_preparation() }
            .overlay(alignment: .topLeading)
            {
                Button("Switch") { button_tap() }
                    .buttonStyle(.bordered)
                    .padding()
            }
        }*/
        
        @State var inc = 1
        
        private func button_tap()
        {
            switch inc
            {
            case 0:
                workspace.select_robot(name: "6DOF Robot")
            case 1:
                workspace.select_tool(name: "Gripper")
            case 2:
                workspace.select_part(name: "Cup")
            default:
                workspace.deselect_object()
            }
            
            print(workspace.selected_object?.name ?? "Nothing")
            
            inc += 1
            if inc > 3 { inc = 0 }
        }
        
        private func workspace_preparation()
        {
            workspace.robots.append(Robot(name: "6DOF Robot"))
            workspace.robots.append(Robot(name: "Portal Robot"))
            
            workspace.tools.append(Tool(name: "Drill"))
            workspace.tools.append(Tool(name: "Gripper"))
            
            workspace.tool_by_name("Gripper").codes = [
                OperationCodeInfo(value: 0, name: "Close", symbol: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", info: "UwU"),
                OperationCodeInfo(value: 1, name: "Open", symbol: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", info: "OwO")
            ]
            
            workspace.parts.append(Part(name: "Cup"))
            workspace.parts.append(Part(name: "Book"))
            
            print("Added")
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

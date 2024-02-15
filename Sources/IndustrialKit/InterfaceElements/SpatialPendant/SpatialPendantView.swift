//
//  SwiftUIView.swift
//  
//
//  Created by Malkarov Park on 09.02.2024.
//

#if os(visionOS)
import SwiftUI

/**
 A view that provides the universal spatial pendant for industrial applications.
 
 This pendant can change its content according to selected *workspace*, *robot* or *tool*.
 */
@available(visionOS 1.0, *)
@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct SpatialPendant: Scene
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

private struct SpatialPendantView: View
{
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    @State private var detail_view_presented = false
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack(spacing: 0)
            {
                Spacer(minLength: 72)
                
                switch controller.view_type
                {
                case .workspace:
                    Text("Worksapce program")
                        .bold()
                        .padding()
                case .robot:
                    RobotProgramView()
                    //Spacer(minLength: 64)
                case .tool:
                    ToolProgramView(tool: $workspace.selected_tool)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack
            {
                switch controller.view_type
                {
                case .workspace:
                    Text("Workspace")
                        .bold()
                case .robot:
                    RobotControl()
                case .tool:
                    ToolControl()
                default:
                    Text("Control")
                        .font(.system(size: 48, design: .rounded))
                        .foregroundStyle(.quaternary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 280)
            .background(.thinMaterial)
            .ornament(attachmentAnchor: .scene(.bottom)) //.overlay(alignment: .bottomTrailing)
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
        }
        .frame(width: 512, height: 828)
        .ornament(attachmentAnchor: .scene(.trailing))
        {
            VStack(spacing: 0)
            {
                Button(action: {})
                {
                    ZStack
                    {
                        Rectangle()
                            .foregroundStyle(controller.view_type != nil ? .red : .secondary)
                            .glassBackgroundEffect()
                        Image(systemName: "stop")
                            .resizable()
                            .frame(width: 24, height: 24)
                            //.scaledToFit()
                            .padding()
                    }
                    .frame(width: 64, height: 64)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .padding([.horizontal, .top])
                
                Button(action: {})
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
        }
        .disabled(controller.view_type == nil)
        .ornament(attachmentAnchor: .scene(.top))
        {
            if controller.view_type == .robot
            {
                ProgramPicker(programs_names: workspace.selected_robot.programs_names, selected_program_index: $workspace.selected_robot.selected_program_index)
            }
            else if controller.view_type == .tool
            {
                ProgramPicker(programs_names: workspace.selected_tool.programs_names, selected_program_index: $workspace.selected_tool.selected_program_index)
            }
        }
        .sheet(isPresented: $detail_view_presented)
        {
            DetailView(is_presented: $detail_view_presented)
        }
    }
    
    private func add_item()
    {
        switch controller.view_type
        {
        case .workspace:
            add_workspace_item()
        case .robot:
            add_robot_item()
        case .tool:
            add_tool_item()
        default:
            break
        }
    }
    
    private func add_workspace_item()
    {
        
    }
    
    private func add_robot_item()
    {
        workspace.selected_robot.selected_program.add_point(PositionPoint(x: workspace.selected_robot.pointer_location[0], y: workspace.selected_robot.pointer_location[1], z: workspace.selected_robot.pointer_location[2], r: workspace.selected_robot.pointer_rotation[0], p: workspace.selected_robot.pointer_rotation[1], w: workspace.selected_robot.pointer_rotation[2]))
        
        workspace.update_view()
        //workspace.selected_robot.selected_program.add_point(<#T##point: PositionPoint##PositionPoint#>)
    }
    
    private func add_tool_item()
    {
        workspace.selected_tool.selected_program.add_code(OperationCode(controller.new_opcode_value))
        workspace.update_view()
    }
}

//MARK: - Program Picker
private struct ProgramPicker: View
{
    @State private var add_program_view_presented = false
    
    let programs_names: [String]
    @Binding var selected_program_index: Int
    
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            Picker("Program", selection: $selected_program_index)
            {
                if programs_names.count > 0
                {
                    ForEach(0 ..< programs_names.count, id: \.self)
                    {
                        Text(programs_names[$0])
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .pickerStyle(.menu)
            .disabled(programs_names.count == 0)
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            
            Button(action: delete_program)
            {
                Image(systemName: "minus")
            }
            .buttonBorderShape(.circle)
            .padding(.horizontal)
            
            Button(action: { add_program_view_presented.toggle() })
            {
                Image(systemName: "plus")
            }
            .buttonBorderShape(.circle)
            .popover(isPresented: $add_program_view_presented)
            {
                AddProgramView(add_program_view_presented: $add_program_view_presented, selected_program_index: $workspace.selected_robot.selected_program_index)
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
    
    private func delete_program()
    {
        switch controller.view_type
        {
        case .robot:
            delete_positions_program()
        case .tool:
            delete_operations_program()
        default:
            break
        }
    }
    
    private func delete_positions_program()
    {
        if workspace.selected_robot.programs_names.count > 0
        {
            let current_spi = workspace.selected_robot.selected_program_index
            workspace.selected_robot.delete_program(index: current_spi)
            
            if workspace.selected_robot.programs_names.count > 1 && current_spi > 0
            {
                workspace.selected_robot.selected_program_index = current_spi - 1
            }
            else
            {
                workspace.selected_robot.selected_program_index = 0
            }
        }
    }
    
    private func delete_operations_program()
    {
        if programs_names.count > 0
        {
            let current_spi = selected_program_index
            workspace.selected_tool.delete_program(index: current_spi)
            
            if programs_names.count > 1 && current_spi > 0
            {
                selected_program_index = current_spi - 1
            }
            else
            {
                selected_program_index = 0
            }
            
            //update_data()
        }
    }
}

//MARK: - Add Program View
private struct AddProgramView: View
{
    @Binding var add_program_view_presented: Bool
    @Binding var selected_program_index: Int
    
    @State var new_program_name = ""
    
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            HStack(spacing: 12)
            {
                TextField("Name", text: $new_program_name)
                    .frame(width: 256)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add")
                {
                    add_program(controller.view_type!)
                }
                .fixedSize()
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
    }
    
    func add_program(_ type: pendant_selection_type)
    {
        switch type
        {
        case .robot:
            if new_program_name == ""
            {
                new_program_name = "None"
            }
            
            workspace.selected_robot.add_program(PositionsProgram(name: new_program_name))
            selected_program_index = workspace.selected_robot.programs_names.count - 1
        case .tool:
            if new_program_name == ""
            {
                new_program_name = "None"
            }
            
            workspace.selected_tool.add_program(OperationsProgram(name: new_program_name))
            selected_program_index = workspace.selected_tool.programs_names.count - 1
        default:
            break
        }
        
        //update_data()
        workspace.update_view()
        add_program_view_presented.toggle()
    }
}

//MARK: - Previews
#Preview
{
    SpatialPendantView()
}
#endif

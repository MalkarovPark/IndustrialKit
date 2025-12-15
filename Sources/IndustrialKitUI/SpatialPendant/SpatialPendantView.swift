//
//  SpatialPendantView.swift
//  IndustrialKit
//
//  Created by Artem on 09.02.2024.
//

#if os(visionOS)
import SwiftUI
import IndustrialKit

/**
 A view that provides the universal spatial pendant for industrial applications.
 
 This pendant can change its content according to selected *workspace*, *robot* or *tool*.
 */
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
                    WorkspaceProgramView()
                case .robot:
                    RobotProgramView()
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
                    WorkspaceControl()
                case .robot:
                    RobotControl()
                case .tool:
                    ToolControl()
                default:
                    EmptyView()
                    /*Text("Control")
                        .font(.system(size: 48, design: .rounded))
                        .foregroundStyle(.quaternary)*/
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 280)
            .background(.thinMaterial)
            .ornament(attachmentAnchor: .scene(.bottom))
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
            if controller.view_type == .robot
            {
                ProgramPicker(programs_names: workspace.selected_robot.programs_names, selected_program_index: $workspace.selected_robot.selected_program_index)
            }
            else if controller.view_type == .tool
            {
                ProgramPicker(programs_names: workspace.selected_tool.programs_names, selected_program_index: $workspace.selected_tool.selected_program_index)
            }
            else if controller.view_type == .workspace
            {
                WorkspaceToolbar()
            }
            
            /*if controller.view_type == .robot
            {
                ProgramPicker(programs_names: workspace.selected_robot.programs_names, selected_program_index: $workspace.selected_robot.selected_program_index)
            }
            else if controller.view_type == .tool
            {
                ProgramPicker(programs_names: workspace.selected_tool.programs_names, selected_program_index: $workspace.selected_tool.selected_program_index)
            }*/
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
        workspace.update_view()
        
        // Add new program element and save to file
        workspace.elements.append(element_from_struct(controller.new_program_element.file_info))
        workspace.elements_check()
        
        controller.elements_document_data_update.toggle()
    }
    
    private func add_robot_item()
    {
        workspace.selected_robot.selected_program.add_point(PositionPoint(x: workspace.selected_robot.pointer_position.x, y: workspace.selected_robot.pointer_position.y, z: workspace.selected_robot.pointer_position.z, r: workspace.selected_robot.pointer_position.r, p: workspace.selected_robot.pointer_position.p, w: workspace.selected_robot.pointer_position.w))
        
        workspace.update_view()
        controller.robots_document_data_update.toggle()
    }
    
    private func add_tool_item()
    {
        workspace.selected_tool.selected_program.add_code(OperationCode(controller.new_operation_code.value))
        
        workspace.update_view()
        controller.tools_document_data_update.toggle()
    }
    
    private func start_pause_performing()
    {
        switch controller.view_type
        {
        case .workspace:
            start_pause_workspace()
        case .robot:
            start_pause_robot()
        case .tool:
            start_pause_tool()
        default:
            break
        }
    }
    
    private func start_pause_workspace()
    {
        workspace.start_pause_performing()
    }
    
    private func start_pause_robot()
    {
        workspace.selected_robot.start_pause_moving()
    }
    
    private func start_pause_tool()
    {
        workspace.selected_tool.start_pause_performing()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
        {
            workspace.update_view()
        }
    }
    
    private func reset_performing()
    {
        switch controller.view_type
        {
        case .workspace:
            reset_workspace()
        case .robot:
            reset_robot()
        case .tool:
            reset_tool()
        default:
            break
        }
    }
    
    private func reset_workspace()
    {
        workspace.reset_performing()
        workspace.update_view()
    }
    
    private func reset_robot()
    {
        workspace.selected_robot.reset_moving()
    }
    
    private func reset_tool()
    {
        workspace.selected_tool.reset_performing()
        workspace.update_view()
    }
}

//MARK: - Workspace toolbar view
private struct WorkspaceToolbar: View
{
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    @State private var registers_view_presented = false
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            Button(action: { registers_view_presented = true })
            {
                Image(systemName: "number")
            }
            .labelsHidden()
            .buttonBorderShape(.circle)
            .padding(.trailing)
            
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
            .labelsHidden()
            .buttonBorderShape(.circle)
        }
        .padding()
        .glassBackgroundEffect()
        .sheet(isPresented: $registers_view_presented)
        {
            RegistersDataView(is_presented: $registers_view_presented)
            {
                controller.registers_document_data_update.toggle()
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
                switch controller.view_type
                {
                case .robot:
                    AddProgramView(add_program_view_presented: $add_program_view_presented, selected_program_index: $workspace.selected_robot.selected_program_index)
                case .tool:
                    AddProgramView(add_program_view_presented: $add_program_view_presented, selected_program_index: $workspace.selected_tool.selected_program_index)
                default:
                    EmptyView()
                }
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
            
            controller.robots_document_data_update.toggle()
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
            
            controller.tools_document_data_update.toggle()
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
            
            controller.robots_document_data_update.toggle()
        case .tool:
            if new_program_name == ""
            {
                new_program_name = "None"
            }
            
            workspace.selected_tool.add_program(OperationsProgram(name: new_program_name))
            selected_program_index = workspace.selected_tool.programs_names.count - 1
            
            controller.tools_document_data_update.toggle()
        default:
            break
        }
        
        workspace.update_view()
        add_program_view_presented.toggle()
    }
}

//MARK: - Previews
#Preview
{
    SpatialPendantView()
        .environmentObject(PendantController())
        .environmentObject(Workspace())
}
#endif

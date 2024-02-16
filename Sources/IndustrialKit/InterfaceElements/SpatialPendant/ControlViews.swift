//
//  SwiftUIView.swift
//  
//
//  Created by Artiom Malkarov on 15.02.2024.
//

#if os(visionOS)
import SwiftUI

//MARK: - Workspace
internal struct WorkspaceControl: View
{
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        ElementControl(new_program_element: $controller.new_program_element)
    }
}

//MARK: - Robot
internal struct RobotControl: View
{
    //@EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        PositionControl(location: $workspace.selected_robot.pointer_location, rotation: $workspace.selected_robot.pointer_rotation, scale: $workspace.selected_robot.space_scale)
            //.frame(width: 400)
    }
}

//MARK: - Tool
internal struct ToolControl: View
{
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            Picker("Code", selection: $controller.new_opcode_value)
            {
                if workspace.selected_tool.codes_count > 0
                {
                    ForEach(workspace.selected_tool.codes, id:\.self)
                    { code in
                        HStack
                        {
                            Text(workspace.selected_tool.code_info(code).label)
                                .font(.system(size: 24))
                            workspace.selected_tool.code_info(code).image
                                .font(.system(size: 24))
                        }
                    }
                }
                else
                {
                    Text("None")
                        .font(.title2)
                }
            }
            .disabled(workspace.selected_tool.codes_count == 0)
            .pickerStyle(.wheel)
            .frame(maxWidth: 400)
        }
    }
}

#Preview
{
    RobotControl()
}

#Preview
{
    ToolControl()
}
#endif

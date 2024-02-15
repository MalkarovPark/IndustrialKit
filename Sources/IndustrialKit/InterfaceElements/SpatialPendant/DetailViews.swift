//
//  SwiftUIView.swift
//  
//
//  Created by Artiom Malkarov on 15.02.2024.
//

#if os(visionOS)
import SwiftUI

internal struct DetailView: View
{
    @Binding var is_presented: Bool
    
    @EnvironmentObject var controller: PendantController
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Spacer(minLength: 72)
            
            switch controller.view_type
            {
            case .workspace:
                WorkspaceDetailView()
                    .padding()
            case .robot:
                RobotDetailView()
                    .padding()
            case .tool:
                ToolDetailView()
                    .padding()
            default:
                EmptyView()
            }
        }
        //.frame(width: 512, height: 512)
        .modifier(ViewCloseButton(is_presented: $is_presented))
    }
}

//MARK: - Workspace
internal struct WorkspaceDetailView: View
{
    var body: some View
    {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}

//MARK: - Robot
internal struct RobotDetailView: View
{
    @EnvironmentObject var controller: PendantController
    //@EnvironmentObject var workspace: Workspace
    
    @State var item_view_pos_location: [Float] = [0, 0, 0] // = [Float]()
    @State var item_view_pos_rotation: [Float] = [0, 0, 0] // = [Float]()
    
    @State var item_view_pos_type: MoveType = .fine
    @State var item_view_pos_speed = Float()
    
    var body: some View
    {
        VStack
        {
            PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
            
            HStack
            {
                Picker("Type", selection: $item_view_pos_type)
                {
                    ForEach(MoveType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 128)
                .buttonStyle(.borderedProminent)
                
                Text("Speed")
                    .frame(width: 60)
                TextField("0", value: $item_view_pos_speed, format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(macOS)
                    .frame(width: 48)
                #else
                    .frame(maxWidth: .infinity)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $item_view_pos_speed, in: 0...100)
                    .labelsHidden()
            }
            .padding()
            /*.onChange(of: item_view_pos_type)
            { _, new_value in
                if appeared
                {
                    point_item.move_type = new_value
                    update_workspace_data()
                }
            }
            .onChange(of: item_view_pos_speed)
            { _, new_value in
                if appeared
                {
                    point_item.move_speed = new_value
                    update_workspace_data()
                }
            }*/
        }
    }
}

//MARK: - Robot
internal struct ToolDetailView: View
{
    @State private var new_operation_code: Int = 0
    
    //@EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            Picker("Code", selection: $new_operation_code)
            {
                if workspace.selected_tool.codes_count > 0
                {
                    ForEach(workspace.selected_tool.codes, id:\.self)
                    { code in
                        HStack
                        {
                            Text(workspace.selected_tool.code_info(code).label)
                                .font(.title2)
                            workspace.selected_tool.code_info(code).image
                                .font(.title2)
                        }
                    }
                }
                else
                {
                    Text("None")
                        .font(.title2)
                        .padding()
                }
            }
            .disabled(workspace.selected_tool.codes_count == 0)
            .pickerStyle(.wheel)
            .frame(maxWidth: 256)
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview
{
    DetailView(is_presented: .constant(false))
}

#Preview
{
    WorkspaceDetailView()
}

#Preview
{
    RobotDetailView()
}

#Preview
{
    ToolDetailView()
}
#endif

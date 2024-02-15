//
//  SwiftUIView.swift
//  
//
//  Created by Artiom Malkarov on 15.02.2024.
//

#if os(visionOS)
import SwiftUI

//MARK: - Robot
internal struct RobotProgramView: View
{
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            List
            {
                if workspace.selected_robot.programs_count > 0
                {
                    if workspace.selected_robot.selected_program.points_count > 0
                    {
                        ForEach(workspace.selected_robot.selected_program.points, id: \.self)
                        { point in
                            PositionItemView(points: $workspace.selected_robot.selected_program.points, point_item: point, on_delete: remove_points)
                                .onDrag
                                {
                                    return NSItemProvider()
                                }
                        }
                        .onMove(perform: point_item_move)
                        .onDelete(perform: remove_points)
                        .onChange(of: workspace.robots)
                        { _, _ in
                            //update_data()
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .padding([.horizontal, .top])
        }
    }
    
    private func point_item_move(from source: IndexSet, to destination: Int)
    {
        workspace.selected_robot.selected_program.points.move(fromOffsets: source, toOffset: destination)
        workspace.selected_robot.selected_program.visual_build()
        //update_data()
    }
    
    private func remove_points(at offsets: IndexSet) //Remove robot point function
    {
        withAnimation
        {
            workspace.selected_robot.selected_program.points.remove(atOffsets: offsets)
        }
        
        //update_data()
        workspace.update_view()
        workspace.selected_robot.selected_program.selected_point_index = -1
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
            
            //update_data()
            workspace.update_view()
        }
    }
    
    private func add_point_to_program()
    {
        workspace.selected_robot.selected_program.add_point(PositionPoint(x: workspace.selected_robot.pointer_location[0], y: workspace.selected_robot.pointer_location[1], z: workspace.selected_robot.pointer_location[2], r: workspace.selected_robot.pointer_rotation[0], p: workspace.selected_robot.pointer_rotation[1], w: workspace.selected_robot.pointer_rotation[2]))
        
        //update_data()
        workspace.update_view()
    }
}

internal struct PositionItemView: View
{
    @Binding var points: [PositionPoint]
    
    @State var point_item: PositionPoint
    @State var position_item_view_presented = false
    
    @EnvironmentObject var workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(workspace.selected_robot.inspector_point_color(point: point_item)) //.gray)
            
            Spacer()
            
            HStack
            {
                Text("X: \(String(format: "%.0f", point_item.x)) Y: \(String(format: "%.0f", point_item.y)) Z: \(String(format: "%.0f", point_item.z))")
                    //.font(.caption)
                
                Divider()
                
                Text("R: \(String(format: "%.0f", point_item.r)) P: \(String(format: "%.0f", point_item.p)) W: \(String(format: "%.0f", point_item.w))")
                    //.font(.caption)
            }
            .popover(isPresented: $position_item_view_presented,
                     arrowEdge: .leading)
            {
                PositionPointView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], on_delete: on_delete)
            }
            
            Spacer()
        }
        .onTapGesture
        {
            position_item_view_presented.toggle()
        }
    }
}

internal struct PositionPointView: View
{
    @Binding var points: [PositionPoint]
    @Binding var point_item: PositionPoint
    @Binding var position_item_view_presented: Bool
    
    @State var item_view_pos_location = [Float]()
    @State var item_view_pos_rotation = [Float]()
    @State var item_view_pos_type: MoveType = .fine
    @State var item_view_pos_speed = Float()
    
    @State private var appeared = false
    
    @EnvironmentObject var workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    let button_padding = 12.0
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            HStack
            {
                PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
                    .onChange(of: item_view_pos_location)
                    { _, _ in
                        update_point_location()
                    }
                    .onChange(of: item_view_pos_rotation)
                    { _, _ in
                        update_point_rotation()
                    }
            }
            .padding([.horizontal, .top])
            
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
                    .frame(maxWidth: .infinity)
                    .keyboardType(.decimalPad)
                Stepper("Enter", value: $item_view_pos_speed, in: 0...100)
                    .labelsHidden()
            }
            .padding()
            .onChange(of: item_view_pos_type)
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
            }
        }
        .onAppear()
        {
            workspace.selected_robot.selected_program.selected_point_index = workspace.selected_robot.selected_program.points.firstIndex(of: point_item) ?? -1
            
            item_view_pos_type = point_item.move_type
            item_view_pos_speed = point_item.move_speed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                appeared = true
            }
        }
        .onDisappear()
        {
            workspace.selected_robot.selected_program.selected_point_index = -1
        }
    }
    
    //MARK: Point manage functions
    func update_point_location()
    {
        point_item.x = item_view_pos_location[0]
        point_item.y = item_view_pos_location[1]
        point_item.z = item_view_pos_location[2]
        
        workspace.selected_robot.point_shift(&point_item)
        
        update_workspace_data()
    }
    
    func update_point_rotation()
    {
        point_item.r = item_view_pos_rotation[0]
        point_item.p = item_view_pos_rotation[1]
        point_item.w = item_view_pos_rotation[2]
        
        update_workspace_data()
    }
    
    func update_workspace_data()
    {
        workspace.update_view()
        workspace.selected_robot.selected_program.visual_build()
        //update_data()
    }
}

//MARK: - Tool
internal struct ToolProgramView: View
{
    @Binding var tool: Tool
    
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            List
            {
                if workspace.selected_tool.programs_count > 0
                {
                    if workspace.selected_tool.selected_program.codes_count > 0
                    {
                        ForEach(workspace.selected_tool.selected_program.codes)
                        { code in
                            OperationItemView(codes: $workspace.selected_tool.selected_program.codes, code_item: code)
                                .onDrag
                            {
                                return NSItemProvider()
                            }
                        }
                        .onMove(perform: code_item_move)
                        .onDelete(perform: remove_codes)
                        .onChange(of: workspace.tools)
                        { _, _ in
                            //update_data()
                        }
                    }
                }
            }
        }
    }
    
    func code_item_move(from source: IndexSet, to destination: Int)
    {
        tool.selected_program.codes.move(fromOffsets: source, toOffset: destination)
        //update_data()
    }
    
    func remove_codes(at offsets: IndexSet) //Remove tool operation function
    {
        withAnimation
        {
            tool.selected_program.codes.remove(atOffsets: offsets)
        }
        
        //update_data()
    }
}

internal struct OperationItemView: View
{
    @Binding var codes: [OperationCode]
    
    @State var code_item: OperationCode
    @State private var new_code_value = 0
    @State private var update_data = false
    
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(workspace.selected_tool.inspector_code_color(code: code_item))
            
            Picker("Code", selection: $new_code_value)
            {
                if workspace.selected_tool.codes_count > 0
                {
                    ForEach(workspace.selected_tool.codes, id:\.self)
                    { code in
                        Text(workspace.selected_tool.code_info(code).label)
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .disabled(workspace.selected_tool.codes_count == 0)
            .frame(maxWidth: .infinity)
            .pickerStyle(.menu)
            .labelsHidden()
            .onChange(of: new_code_value)
            { _, new_value in
                if update_data
                {
                    code_item.value = new_code_value
                }
            }
        }
        .onAppear
        {
            update_data = false
            new_code_value = code_item.value
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                update_data = true
            }
        }
    }
    
    func delete_code_item()
    {
        workspace.selected_tool.selected_program.delete_code(index: workspace.selected_tool.selected_program.codes.firstIndex(of: code_item) ?? 0)
    }
}

#Preview
{
    RobotProgramView()
}

#Preview
{
    ToolProgramView(tool: .constant(Tool()))
}
#endif

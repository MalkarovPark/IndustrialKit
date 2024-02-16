//
//  PerformerElementsViews.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 26.11.2023.
//

#if os(visionOS)
import SwiftUI

internal struct RobotPerformerElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State private var object_name = ""
    @State private var is_single_perfrom = false
    @State private var is_program_by_index = false
    @State private var program_name = ""
    @State private var program_index_from = [Int]()
    
    @State private var location_indices = [Int]()
    @State private var rotation_indices = [Int]()
    @State private var speed_index = [Int]()
    
    @EnvironmentObject var workspace: Workspace
    @State private var picker_is_presented = false
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _object_name = State(initialValue: (_element.wrappedValue as! RobotPerformerElement).object_name)
        _is_single_perfrom = State(initialValue: (_element.wrappedValue as! RobotPerformerElement).is_single_perfrom)
        _is_program_by_index = State(initialValue: (_element.wrappedValue as! RobotPerformerElement).is_program_by_index)
        _program_name = State(initialValue: (_element.wrappedValue as! RobotPerformerElement).program_name)
        _program_index_from = State(initialValue: [(_element.wrappedValue as! RobotPerformerElement).program_index])
        
        _location_indices = State(initialValue: [(_element.wrappedValue as! RobotPerformerElement).x_index, (_element.wrappedValue as! RobotPerformerElement).y_index, (_element.wrappedValue as! RobotPerformerElement).z_index])
        _rotation_indices = State(initialValue: [(_element.wrappedValue as! RobotPerformerElement).r_index, (_element.wrappedValue as! RobotPerformerElement).p_index, (_element.wrappedValue as! RobotPerformerElement).w_index])
        _speed_index = State(initialValue: [(_element.wrappedValue as! RobotPerformerElement).speed_index])
        
        self.on_update = on_update
    }
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if workspace.placed_robots_names.count > 0
            {
                //MARK: Robot subview
                Picker("Name", selection: $object_name) //Robot picker
                {
                    ForEach(workspace.placed_robots_names, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                .onChange(of: object_name)
                { _, name in
                    if workspace.robot_by_name(name).programs_names.count > 0
                    {
                        program_name = workspace.robot_by_name(name).programs_names.first ?? ""
                    }
                    workspace.update_view()
                }
                .onAppear
                {
                    if object_name == ""
                    {
                        object_name = workspace.placed_robots_names.first!
                    }
                    else
                    {
                        workspace.update_view()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(workspace.placed_robots_names.count == 0)
                .frame(maxWidth: .infinity)
                .padding(.bottom)
                
                Picker("", selection: $is_single_perfrom)
                {
                    Text("Single").tag(true)
                    Text("Program").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding([.horizontal])
                
                if is_single_perfrom
                {
                    RegistersSelector(text: "Location X: \(location_indices[0]), Y: \(location_indices[1]), Z: \(location_indices[2])", registers_count: workspace.registers.count, colors: registers_colors, indices: $location_indices, names: ["X", "Y", "Z"])
                        .padding(.top)
                    
                    RegistersSelector(text: "Rotation R: \(rotation_indices[0]), P: \(rotation_indices[1]), W: \(rotation_indices[2])", registers_count: workspace.registers.count, colors: registers_colors, indices: $rotation_indices, names: ["R", "P", "W"])
                        .padding(.top)
                    
                    RegistersSelector(text: "Speed: \(speed_index[0])", registers_count: workspace.registers.count, colors: registers_colors, indices: $speed_index, names: ["Speed"])
                        .padding(.top)
                }
                else
                {
                    VStack(spacing: 0)
                    {
                        Picker("", selection: $is_program_by_index)
                        {
                            Text("Name").tag(false)
                            Text("Index").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .padding(.bottom)
                        
                        if is_program_by_index
                        {
                            RegistersSelector(text: "From: \(program_index_from[0])", registers_count: workspace.registers.count, colors: registers_colors, indices: $program_index_from, names: ["Program"])
                        }
                        else
                        {
                            Picker("Program", selection: $program_name) //Robot program picker
                            {
                                if workspace.robot_by_name(object_name).programs_names.count > 0
                                {
                                    ForEach(workspace.robot_by_name(object_name).programs_names, id: \.self)
                                    { name in
                                        Text(name)
                                    }
                                }
                                else
                                {
                                    Text("None")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(workspace.robot_by_name(object_name).programs_names.count == 0)
                        }
                    }
                    .padding(.top)
                    #if os(iOS) || os(visionOS)
                    .frame(minWidth: 256)
                    #endif
                }
            }
            else
            {
                Text("No robots placed in this workspace")
            }
        }
        .onChange(of: object_name)
        { _, new_value in
            (element as! RobotPerformerElement).object_name = new_value
            on_update()
        }
        .onChange(of: is_single_perfrom)
        { _, new_value in
            (element as! RobotPerformerElement).is_single_perfrom = new_value
            on_update()
        }
        .onChange(of: is_program_by_index)
        { _, new_value in
            (element as! RobotPerformerElement).is_program_by_index = new_value
            on_update()
        }
        .onChange(of: program_name)
        { _, new_value in
            (element as! RobotPerformerElement).program_name = new_value
            on_update()
        }
        .onChange(of: program_index_from)
        { _, new_value in
            (element as! RobotPerformerElement).program_index = new_value[0]
            on_update()
        }
        .onChange(of: location_indices)
        { _, new_value in
            (element as! RobotPerformerElement).x_index = new_value[0]
            (element as! RobotPerformerElement).y_index = new_value[1]
            (element as! RobotPerformerElement).z_index = new_value[2]
            on_update()
        }
        .onChange(of: rotation_indices)
        { _, new_value in
            (element as! RobotPerformerElement).r_index = new_value[0]
            (element as! RobotPerformerElement).p_index = new_value[1]
            (element as! RobotPerformerElement).w_index = new_value[2]
            on_update()
        }
        .onChange(of: speed_index)
        { _, new_value in
            (element as! RobotPerformerElement).speed_index = new_value[0]
            on_update()
        }
    }
}

internal struct ToolPerformerElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State private var object_name = ""
    @State private var is_single_perfrom = false
    @State private var is_program_by_index = false
    @State private var program_name = ""
    @State private var program_index_from = [Int]()
    
    @State private var opcode_index = [Int]()
    
    @EnvironmentObject var workspace: Workspace
    @State private var picker_is_presented = false
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _object_name = State(initialValue: (_element.wrappedValue as! ToolPerformerElement).object_name)
        _is_single_perfrom = State(initialValue: (_element.wrappedValue as! ToolPerformerElement).is_single_perfrom)
        _is_program_by_index = State(initialValue: (_element.wrappedValue as! ToolPerformerElement).is_program_by_index)
        _program_name = State(initialValue: (_element.wrappedValue as! ToolPerformerElement).program_name)
        _program_index_from = State(initialValue: [(_element.wrappedValue as! ToolPerformerElement).program_index])
        
        _opcode_index = State(initialValue: [(_element.wrappedValue as! ToolPerformerElement).opcode_index])
        
        self.on_update = on_update
    }
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if workspace.placed_tools_names.count > 0
            {
                //MARK: Robot subview
                Picker("Name", selection: $object_name) //Robot picker
                {
                    ForEach(workspace.placed_tools_names, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                .onChange(of: object_name)
                { _, name in
                    if workspace.tool_by_name(name).programs_names.count > 0
                    {
                        program_name = workspace.tool_by_name(name).programs_names.first ?? ""
                    }
                    workspace.update_view()
                }
                .onAppear
                {
                    if object_name == ""
                    {
                        object_name = workspace.placed_tools_names.first!
                    }
                    else
                    {
                        workspace.update_view()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(workspace.placed_tools_names.count == 0)
                .frame(maxWidth: .infinity)
                .padding(.bottom)
                
                Picker("", selection: $is_single_perfrom)
                {
                    Text("Single").tag(true)
                    Text("Program").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding([.horizontal])
                
                if is_single_perfrom
                {
                    RegistersSelector(text: "Opcode from \(opcode_index[0])", registers_count: workspace.registers.count, colors: registers_colors, indices: $opcode_index, names: ["Operation code"])
                        .padding(.top)
                }
                else
                {
                    VStack(spacing: 0)
                    {
                        Picker("", selection: $is_program_by_index)
                        {
                            Text("Name").tag(false)
                            Text("Index").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .padding(.bottom)
                        
                        if is_program_by_index
                        {
                            RegistersSelector(text: "From: \(program_index_from[0])", registers_count: workspace.registers.count, colors: registers_colors, indices: $program_index_from, names: ["Program"])
                        }
                        else
                        {
                            Picker("Program", selection: $program_name) //Robot program picker
                            {
                                if workspace.tool_by_name(object_name).programs_names.count > 0
                                {
                                    ForEach(workspace.tool_by_name(object_name).programs_names, id: \.self)
                                    { name in
                                        Text(name)
                                    }
                                }
                                else
                                {
                                    Text("None")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(workspace.tool_by_name(object_name).programs_names.count == 0)
                        }
                    }
                    .padding(.top)
                    #if os(iOS) || os(visionOS)
                    .frame(minWidth: 256)
                    #endif
                }
            }
            else
            {
                Text("No tools placed in this workspace")
            }
        }
        .onChange(of: object_name)
        { _, new_value in
            (element as! ToolPerformerElement).object_name = new_value
            on_update()
        }
        .onChange(of: is_single_perfrom)
        { _, new_value in
            (element as! ToolPerformerElement).is_single_perfrom = new_value
            on_update()
        }
        .onChange(of: is_program_by_index)
        { _, new_value in
            (element as! ToolPerformerElement).is_program_by_index = new_value
            on_update()
        }
        .onChange(of: program_name)
        { _, new_value in
            (element as! ToolPerformerElement).program_name = new_value
            on_update()
        }
        .onChange(of: program_index_from)
        { _, new_value in
            (element as! ToolPerformerElement).program_index = new_value[0]
            on_update()
        }
        .onChange(of: opcode_index)
        { _, new_value in
            (element as! ToolPerformerElement).opcode_index = new_value[0]
            on_update()
        }
    }
}

#Preview
{
    RobotPerformerElementView(element: .constant(RobotPerformerElement()), on_update: {})
        .environmentObject(Workspace())
}

#Preview
{
    ToolPerformerElementView(element: .constant(ToolPerformerElement()), on_update: {})
        .environmentObject(Workspace())
}
#endif

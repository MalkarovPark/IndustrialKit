//
//  PerformerElementsViews.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 26.11.2023.
//

import SwiftUI
import IndustrialKit

public struct RobotPerformerElementView: View
{
    @ObservedObject var element: RobotPerformerElement
    @ObservedObject var workspace: Workspace
    @State private var picker_is_presented = false
    
    let on_update: () -> ()
    
    public init(
        element: RobotPerformerElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        
        self.workspace = workspace
        
        self.on_update = on_update
        
        if self.element.object_name == ""
        {
            self.element.object_name = self.workspace.placed_robot_names.first ?? "???"
            
            if workspace.robot(named: element.object_name).program_names.count > 0
            {
                element.program_name = workspace.robot(named: element.object_name).program_names.first ?? ""
            }
        }
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if workspace.placed_robot_names.count > 0
            {
                // MARK: Robot subview
                let object_name = Binding(
                    get: { element.object_name },
                    set:
                        { new_value in
                            element.object_name = new_value
                            
                            if workspace.robot(named: new_value).program_names.count > 0
                            {
                                element.program_name = workspace.robot(named: new_value).program_names.first ?? ""
                            }
                            
                            on_update()
                        }
                )
                
                Picker("Name", selection: object_name) // Robot picker
                {
                    ForEach(workspace.placed_robot_names, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(workspace.placed_robot_names.count == 0)
                .frame(maxWidth: .infinity)
                .padding(.bottom)
                
                let is_single_perfrom = Binding(
                    get: { element.is_single_perfrom },
                    set:
                        { new_value in
                            element.is_single_perfrom = new_value
                            
                            on_update()
                        }
                )
                
                Picker("Is Single", selection: is_single_perfrom)
                {
                    Text("Single").tag(true)
                    Text("Program").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                
                if element.is_single_perfrom
                {
                    let location_indices = Binding(
                        get: { [element.x_index, element.y_index, element.z_index] },
                        set:
                            { new_value in
                                element.x_index = new_value[0]
                                element.y_index = new_value[1]
                                element.z_index = new_value[2]
                                
                                on_update()
                            }
                    )
                    
                    let rotation_indices = Binding(
                        get: { [element.r_index, element.p_index, element.w_index] },
                        set:
                            { new_value in
                                element.r_index = new_value[0]
                                element.p_index = new_value[1]
                                element.w_index = new_value[2]
                                
                                on_update()
                            }
                    )
                    
                    let speed_index = Binding(
                        get: { [element.speed_index] },
                        set:
                            { new_value in
                                //element.speed_index = new_value[0]
                                if let first = new_value.first
                                {
                                    element.speed_index = first
                                    on_update()
                                }
                            }
                    )
                    
                    let type_index = Binding(
                        get: { [element.type_index] },
                        set:
                            { new_value in
                                element.type_index = new_value[0]
                                
                                if let first = new_value.first
                                {
                                    element.type_index = first
                                    on_update()
                                }
                            }
                    )
                    
                    RegistersSelector(text: "Location X: \(element.x_index), Y: \(element.y_index), Z: \(element.z_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: location_indices, names: ["X", "Y", "Z"])
                        .padding(.top)
                    
                    RegistersSelector(text: "Rotation R: \(element.r_index), P: \(element.p_index), W: \(element.w_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: rotation_indices, names: ["R", "P", "W"])
                        .padding(.top)
                    
                    HStack(spacing: 16)
                    {
                        RegistersSelector(text: "Speed: \(element.speed_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: speed_index, names: ["Speed"])
                            //.padding(.trailing)
                        
                        RegistersSelector(text: "Type: \(element.type_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: type_index, names: ["Type"])
                    }
                    .padding(.top)
                }
                else
                {
                    VStack(spacing: 0)
                    {
                        let is_program_by_index = Binding(
                            get: { element.is_program_by_index },
                            set:
                                { new_value in
                                    element.is_program_by_index = new_value
                                    
                                    on_update()
                                }
                        )
                        
                        Picker("", selection: is_program_by_index)
                        {
                            Text("Name").tag(false)
                            Text("Index").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .padding(.bottom)
                        
                        if element.is_program_by_index
                        {
                            let program_index = Binding(
                                get: { [element.program_index] },
                                set:
                                    { new_value in
                                        //element.program_index = new_value[0]
                                        if let first = new_value.first
                                        {
                                            element.program_index = first
                                            on_update()
                                        }
                                    }
                            )
                            
                            RegistersSelector(text: "From: \(element.program_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: program_index, names: ["Program"])
                        }
                        else
                        {
                            Picker("Program", selection: $element.program_name) // Robot program picker
                            {
                                if workspace.robot(named: element.object_name).program_names.count > 0
                                {
                                    ForEach(workspace.robot(named: element.object_name).program_names, id: \.self)
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
                            .disabled(workspace.robot(named: element.object_name).program_names.count == 0)
                        }
                    }
                    .padding(.top)
                    #if !os(macOS)
                    .frame(minWidth: 256)
                    #endif
                }
            }
            else
            {
                Text("No robots placed in this workspace")
            }
        }
    }
}

public struct ToolPerformerElementView: View
{
    @ObservedObject var element: ToolPerformerElement
    @ObservedObject var workspace: Workspace
    @State private var picker_is_presented = false
    
    let on_update: () -> ()
    
    public init(
        element: ToolPerformerElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        
        self.workspace = workspace
        
        self.on_update = on_update
        
        if self.element.object_name == ""
        {
            self.element.object_name = self.workspace.placed_tool_names.first ?? "???"
            
            if workspace.tool(named: element.object_name).program_names.count > 0
            {
                element.program_name = workspace.tool(named: element.object_name).program_names.first ?? ""
            }
        }
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if workspace.placed_tool_names.count > 0
            {
                // MARK: Tool subview
                let object_name = Binding(
                    get: { element.object_name },
                    set:
                        { new_value in
                            element.object_name = new_value
                            
                            if workspace.robot(named: new_value).program_names.count > 0
                            {
                                element.program_name = workspace.robot(named: new_value).program_names.first ?? ""
                            }
                        }
                )
                
                Picker("Name", selection: object_name) // Tool picker
                {
                    ForEach(workspace.placed_tool_names, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(workspace.placed_tool_names.count == 0)
                .frame(maxWidth: .infinity)
                .padding(.bottom)
                
                let is_single_perfrom = Binding(
                    get: { element.is_single_perfrom },
                    set:
                        { new_value in
                            element.is_single_perfrom = new_value
                            
                            on_update()
                        }
                )
                
                Picker("Is Single", selection: is_single_perfrom)
                {
                    Text("Single").tag(true)
                    Text("Program").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                
                if element.is_single_perfrom
                {
                    let opcode_index = Binding(
                        get: { [element.opcode_index] },
                        set:
                            { new_value in
                                //element.opcode_index = new_value[0]
                                if let first = new_value.first
                                {
                                    element.opcode_index = first
                                    on_update()
                                }
                            }
                    )
                    
                    RegistersSelector(text: "Opcode from \(element.opcode_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: opcode_index, names: ["Operation code"])
                        .padding(.top)
                        .frame(width: 146)
                }
                else
                {
                    VStack(spacing: 0)
                    {
                        let is_program_by_index = Binding(
                            get: { element.is_program_by_index },
                            set:
                                { new_value in
                                    element.is_program_by_index = new_value
                                    
                                    on_update()
                                }
                        )
                        
                        Picker("", selection: is_program_by_index)
                        {
                            Text("Name").tag(false)
                            Text("Index").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .padding(.bottom)
                        
                        if element.is_program_by_index
                        {
                            let program_index = Binding(
                                get: { [element.program_index] },
                                set:
                                    { new_value in
                                        //element.program_index = new_value[0]
                                        if let first = new_value.first
                                        {
                                            element.program_index = first
                                            on_update()
                                        }
                                    }
                            )
                            
                            RegistersSelector(text: "From: \(element.program_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: program_index, names: ["Program"])
                        }
                        else
                        {
                            Picker("Program", selection: $element.program_name) // Robot program picker
                            {
                                if workspace.tool(named: element.object_name).program_names.count > 0
                                {
                                    ForEach(workspace.tool(named: element.object_name).program_names, id: \.self)
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
                            .disabled(workspace.tool(named: element.object_name).program_names.count == 0)
                        }
                    }
                    .padding(.top)
                    #if !os(macOS)
                    .frame(minWidth: 256)
                    #endif
                }
            }
            else
            {
                Text("No tools placed in this workspace")
            }
        }
    }
}

//MARK: - Previews
struct IMAPerformersPreviewsContainer: PreviewProvider
{
    static var previews: some View
    {
        PerformersContainer()
    }

    struct PerformersContainer: View
    {
        @StateObject var workspace = Workspace()

        var body: some View
        {
            PerformersView(workspace: workspace)
                .onAppear
                {
                    let robot = Robot(name: "6DOF")
                    robot.is_placed = true
                    robot.add_program(PositionProgram(name: "Square"))
                    
                    let tool = Tool(name: "Gripper")
                    tool.is_placed = true
                    tool.add_program(OperationProgram(name: "Close"))
                    
                    workspace.robots.append(robot)
                    workspace.tools.append(tool)
                }
                .environmentObject(workspace)
        }
    }

    struct PerformersView: View
    {
        @ObservedObject var workspace: Workspace
        
        var body: some View
        {
            VStack(alignment: .leading, spacing: 8)
            {
                /*Text("Performers")
                    .font(.custom("Line Seed Sans", size: 20))
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
                    .opacity(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .top], 8)*/
                
                HStack
                {
                    RobotPerformerElementView(element: RobotPerformerElement(), workspace: workspace, on_update: {})
                        .modifier(PreviewBorder())

                    ToolPerformerElementView(element: ToolPerformerElement(), workspace: workspace, on_update: {})
                        .modifier(PreviewBorder())
                }
            }
            .padding()
        }
    }
    
    private struct PreviewBorder: ViewModifier
    {
        public func body(content: Content) -> some View
        {
            content
                .padding()
            #if !os(visionOS)
                .frame(width: 256)
            #else
                .frame(width: 320)
            #endif
                .background(.bar)
            #if !os(visionOS)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 8)
            #else
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            #endif
                .padding()
        }
    }
}

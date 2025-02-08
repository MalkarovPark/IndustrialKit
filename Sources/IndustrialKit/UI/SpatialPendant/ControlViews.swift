//
//  ControlViews.swift
//  IndustrialKit
//
//  Created by Artem on 15.02.2024.
//

#if os(visionOS)
import SwiftUI

//MARK: - Workspace
internal struct WorkspaceControl: View
{
    @State private var element_type: ProgramElementType = .perofrmer
    @State private var performer_type: PerformerType = .robot
    @State private var modifier_type: ModifierType = .mover
    @State private var logic_type: LogicType = .comparator
    
    @EnvironmentObject var controller: PendantController
    
    var body: some View
    {
        HStack
        {
            // MARK: Type picker
            Picker("Type", selection: $element_type)
            {
                ForEach(ProgramElementType.allCases, id: \.self)
                { type in
                    Text(type.rawValue).tag(type)
                }
                .onChange(of: element_type)
                { _, _ in
                    build_element()
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 192)
            .labelsHidden()
            
            // MARK: Subtype pickers cases
            HStack
            {
                switch element_type
                {
                case .perofrmer:
                    Picker("Type", selection: $performer_type)
                    {
                        ForEach(PerformerType.allCases, id: \.self)
                        { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .onChange(of: performer_type) { _, _ in
                        build_element()
                    }
                case .modifier:
                    Picker("Type", selection: $modifier_type)
                    {
                        ForEach(ModifierType.allCases, id: \.self)
                        { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .onChange(of: modifier_type) { _, _ in
                        build_element()
                    }
                case .logic:
                    Picker("Type", selection: $logic_type)
                    {
                        ForEach(LogicType.allCases, id: \.self)
                        { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .onChange(of: logic_type) { _, _ in
                        build_element()
                    }
                }
            }
            .labelsHidden()
            .frame(width: 192)
            
            ZStack
            {
                controller.new_program_element.image
                    .foregroundColor(.white)
                    .imageScale(.large)
                    .animation(.easeInOut(duration: 0.2), value: controller.new_program_element.image)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(controller.new_program_element.color)
            .opacity(0.6)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(16)
            .animation(.easeInOut(duration: 0.2), value: controller.new_program_element.color)
        }
        .padding()
        .onAppear(perform: get_parameters)
    }
    
    private func get_parameters()
    {
        switch controller.new_program_element.file_info.identifier
        {
        case .robot_performer:
            element_type = .perofrmer
            performer_type = .robot
        case .tool_performer:
            element_type = .perofrmer
            performer_type = .tool
        case .mover_modifier:
            element_type = .modifier
            modifier_type = .mover
        case .writer_modifier:
            element_type = .modifier
            modifier_type = .writer
        case .math_modifier:
            element_type = .modifier
            modifier_type = .math
        case .changer_modifier:
            element_type = .modifier
            modifier_type = .changer
        case .observer_modifier:
            element_type = .modifier
            modifier_type = .observer
        case .cleaner_modifier:
            element_type = .modifier
            modifier_type = .cleaner
        case .jump_logic:
            element_type = .logic
            logic_type = .jump
        case .comparator_logic:
            element_type = .logic
            logic_type = .comparator
        case .mark_logic:
            element_type = .logic
            logic_type = .mark
        case .none:
            break
        }
    }
    
    private func build_element()
    {
        switch element_type
        {
        case .perofrmer:
            switch performer_type
            {
            case .robot:
                controller.new_program_element = RobotPerformerElement()
            case .tool:
                controller.new_program_element = ToolPerformerElement()
            }
        case .modifier:
            switch modifier_type
            {
            case .mover:
                controller.new_program_element = MoverModifierElement()
            case .writer:
                controller.new_program_element = WriterModifierElement()
            case .math:
                controller.new_program_element = MathModifierElement()
            case .changer:
                controller.new_program_element = ChangerModifierElement()
            case .observer:
                controller.new_program_element = ObserverModifierElement()
            case .cleaner:
                controller.new_program_element = CleanerModifierElement()
            }
        case .logic:
            switch logic_type
            {
            case .jump:
                controller.new_program_element = JumpLogicElement()
            case .comparator:
                controller.new_program_element = ComparatorLogicElement()
            case .mark:
                controller.new_program_element = MarkLogicElement()
            }
        }
    }
}

//MARK: - Robot
internal struct RobotControl: View
{
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        PositionControl(location: $workspace.selected_robot.pointer_location, rotation: $workspace.selected_robot.pointer_rotation, scale: $workspace.selected_robot.space_scale)
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
            Picker("Code", selection: $controller.new_operation_code)
            {
                if workspace.selected_tool.codes.count > 0
                {
                    ForEach(workspace.selected_tool.codes, id:\.self)
                    { code in
                        HStack
                        {
                            Text(code.name)
                                .font(.system(size: 24))
                            code.image
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
            .disabled(workspace.selected_tool.codes.count == 0)
            .pickerStyle(.wheel)
            .frame(maxWidth: 400)
        }
        .onAppear
        {
            if workspace.selected_tool.codes.count > 0
            {
                controller.new_operation_code = workspace.selected_tool.codes.first ?? OperationCodeInfo()
            }
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

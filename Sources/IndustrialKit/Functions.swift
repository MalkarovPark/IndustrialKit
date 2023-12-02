//
//  Functions.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 24.11.2022.
//

import Foundation
import SceneKit

/**
 Finds and update mismatched name.
 
 - Parameters:
    - name: A checked name.
    - names: A current array of names.
 
 - Returns: Name after validation. May differ from the input.
 */
public func mismatched_name(name: String, names: [String]) -> String
{
    var name_count = 1
    var name_postfix: String
    {
        return name_count > 1 ? " \(name_count)" : ""
    }
    
    if names.count > 0
    {
        for _ in 0..<names.count
        {
            for viewed_name in names
            {
                if viewed_name == name + name_postfix
                {
                    name_count += 1
                }
            }
        }
    }
    
    return name + name_postfix
}

///Transforms input position by origin rotation.
/// - Warning: All input/output arrays have only 3 values.
/// - Parameters:
///     - pointer_location: Input point location components – *x*, *y*, *z*.
///     - pointer_rotation: Input origin rotation components – *r*, *p*, *w*.
/// - Returns: Transformed inputed point location components – *x*, *y*, *z*.
public func origin_transform(pointer_location: [Float], origin_rotation: [Float]) -> [Float]
{
    let new_x, new_y, new_z: Float
    if origin_rotation.reduce(0, +) > 0 //If at least one rotation angle of the origin is not equal to zero
    {
        //Calculate new values for coordinates components by origin rotation angles
        new_x = pointer_location[0] * cos(origin_rotation[1].to_rad) * cos(origin_rotation[2].to_rad) + pointer_location[2] * sin(origin_rotation[1].to_rad) - pointer_location[1] * sin(origin_rotation[2].to_rad)
        new_y = pointer_location[1] * cos(origin_rotation[0].to_rad) * cos(origin_rotation[2].to_rad) - pointer_location[2] * sin(origin_rotation[0].to_rad) + pointer_location[0] * sin(origin_rotation[2].to_rad)
        new_z = pointer_location[2] * cos(origin_rotation[0].to_rad) * cos(origin_rotation[1].to_rad) + pointer_location[1] * sin(origin_rotation[0].to_rad) - pointer_location[0] * sin(origin_rotation[1].to_rad)
    }
    else
    {
        //Return original values
        new_x = pointer_location[0]
        new_y = pointer_location[1]
        new_z = pointer_location[2]
    }
    
    return [new_x, new_y, new_z]
}

/**
 Applies certain category bit mask int value for inputed node and all nested.
 
 - Parameters:
    - node: The node to which the bit mask number applies.
    - value: A new category bit mask value.
 */
public func apply_bit_mask(node: SCNNode, _ value: Int)
{
    node.categoryBitMask = value
    
    node.enumerateChildNodes
    { (_node, stop) in
        _node.categoryBitMask = value
    }
}

//MARK: - Conversion functions for space parameters
public func visual_scaling(_ numbers: [Float], factor: Float) -> [Float] //Scaling lengths by divider
{
    var new_numbers = [Float]()
    for number in numbers
    {
        new_numbers.append(number * factor)
    }
    
    return new_numbers
}

//MARK: Connection parameters view functions
internal func read_connection_parameters(connector: WorkspaceObjectConnector, _ parameters: [String]?)
{
    if parameters != nil && connector.parameters.count > 0
    {
        if parameters?.count == connector.parameters.count
        {
            for i in 0 ..< connector.parameters.count
            {
                switch connector.parameters[i].value
                {
                case is String:
                    connector.parameters[i].value = parameters?[i] ?? ""
                case is Int:
                    connector.parameters[i].value = Int(parameters![i]) ?? 0
                case is Float:
                    connector.parameters[i].value = Float(parameters![i]) ?? 0
                case is Bool:
                    connector.parameters[i].value = parameters![i] == "true"
                default:
                    break
                }
            }
        }
    }
}

internal func get_connection_parameters(connector: WorkspaceObjectConnector) -> [String]?
{
    if connector.parameters.count > 0
    {
        var parameters = [String]()
        
        for parameter in connector.parameters
        {
            switch parameter.value
            {
            case let value as String:
                parameters.append(value)
            case let value as Int:
                parameters.append(String(value))
            case let value as Float:
                parameters.append(String(value))
            case let value as Bool:
                parameters.append(String(value))
            default:
                break
            }
        }
        
        return parameters
    }
    else
    {
        return nil
    }
}

//MARK: - Pass functions
/**
 Pass selected preferences between robots.
 
 - Parameters:
    - origin_location: A flag to pass origin location.
    - origin_rotation: A flag to pass origin rotation.
    - space_scale: A flag to pass space scale.
    - from: A robot that preferences pass from.
    - to: Robot that preferences pass to.
 */
public func pass_robot_preferences(_ origin_location: Bool, _ origin_rotation: Bool, _ space_scale: Bool, from: Robot, to: Robot)
{
    if origin_location
    {
        to.origin_location = from.origin_location
    }
    
    if origin_rotation
    {
        to.origin_rotation = from.origin_rotation
    }
    
    if space_scale
    {
        to.space_scale = from.space_scale
    }
}

/**
 Pass selected programs between robots.
 
 - Parameters:
    - names: Names of passed programs.
    - from: A robot that programs pass from.
    - to: Robot that programs pass to.
 */
public func pass_positions_programs(names: [String], from: Robot, to: Robot)
{
    let programs = from.file_info.programs
    
    for name in names
    {
        for program in programs
        {
            if program.name == name
            {
                to.add_program(PositionsProgram(program_struct: program))
            }
        }
    }
}

///
/**
 Converts sturct to appropriate program element.
 
 - Parameters:
    - element_struct: A workspace program element struct.
 
 - Returns: Inherited from the workspace program element class instance.
 */
public func element_from_struct(_ element_struct: WorkspaceProgramElementStruct) -> WorkspaceProgramElement
{
    switch element_struct.identifier
    {
    case .robot_perofrmer:
        return RobotPerformerElement(element_struct: element_struct)
    case .tool_performer:
        return ToolPerformerElement(element_struct: element_struct)
    case .mover_modifier:
        return MoverModifierElement(element_struct: element_struct)
    case .writer_modifier:
        return WriterModifierElement(element_struct: element_struct)
    case .cleaner_modifier:
        return CleanerModifierElement(element_struct: element_struct)
    case .changer_modifier:
        return ChangerModifierElement(element_struct: element_struct)
    case .observer_modifier:
        return ObserverModifierElement(element_struct: element_struct)
    case .comparator_logic:
        return ComparatorLogicElement(element_struct: element_struct)
    case .mark_logic:
        return MarkLogicElement(element_struct: element_struct)
    case .none:
        return WorkspaceProgramElement()
    }
}

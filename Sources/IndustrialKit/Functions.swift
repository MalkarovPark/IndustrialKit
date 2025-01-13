//
//  Functions.swift
//  IndustrialKit
//
//  Created by Artem on 24.11.2022.
//

import Foundation
import SceneKit

/**
 Finds and updates mismatched name.
 
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
    let programs = from.programs
    
    for name in names
    {
        for program in programs
        {
            if program.name == name
            {
                to.add_program(clone_codable(program)!)
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
    case .robot_performer:
        return RobotPerformerElement(element_struct: element_struct)
    case .tool_performer:
        return ToolPerformerElement(element_struct: element_struct)
    case .mover_modifier:
        return MoverModifierElement(element_struct: element_struct)
    case .writer_modifier:
        return WriterModifierElement(element_struct: element_struct)
    case .math_modifier:
        return MathModifierElement(element_struct: element_struct)
    case .changer_modifier:
        return ChangerModifierElement(element_struct: element_struct)
    case .observer_modifier:
        return ObserverModifierElement(element_struct: element_struct)
    case .cleaner_modifier:
        return CleanerModifierElement(element_struct: element_struct)
    case .jump_logic:
        return JumpLogicElement(element_struct: element_struct)
    case .comparator_logic:
        return ComparatorLogicElement(element_struct: element_struct)
    case .mark_logic:
        return MarkLogicElement(element_struct: element_struct)
    case .none:
        return WorkspaceProgramElement()
    }
}

///Deep copy for codable objects.
func clone_codable<T: Codable>(_ object: T) -> T?
{
    do
    {
        let encoded = try JSONEncoder().encode(object)
        return try JSONDecoder().decode(T.self, from: encoded)
    }
    catch
    {
        print(error)
        return nil
    }
}

#if os(macOS)
//MARK: - Terminal Functions
/**
 Performs terminal command.
 
 - Parameters:
    - command: A terminal command.
 
 - Returns: Command text output.
 */
@discardableResult
public func perform_terminal_command(_ command: String) throws -> String?
{
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil

    try task.run()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    
    return String(data: data, encoding: .utf8)
}

/**
 Executes a terminal command and provides output asynchronously.

 - Parameters:
   - command: The terminal command.
   - output_handler: A closure that is called with each chunk of output (stdout and stderr) as a String.
        This closure is called multiple times, asynchronously, as the command produces output.
                 
 - Throws: An NSError with domain "TerminalCommandError" if the command exits with a non-zero status code.
        The error's userInfo contains the localized description of the error and the termination status.
 */
public func perform_terminal_command(_ command: String,  output_handler: @escaping (String) -> Void) throws
{
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil
    
    let fileHandle = pipe.fileHandleForReading
    
    task.launch()
    
    
    fileHandle.readabilityHandler =
    { fileHandle in
        let data = fileHandle.availableData
        if data.isEmpty
        {
            return
        }
        if let output = String(data: data, encoding: .utf8)
        {
            output_handler(output)
        }
    }
    
    task.waitUntilExit()
    
    
    if task.terminationStatus != 0
    {
        throw NSError(domain: "TerminalCommandError", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Command failed with status \(task.terminationStatus)"])
    }
    
    fileHandle.readabilityHandler = nil
}

/**
 Performs terminal app.
 
 - Parameters:
    - url: A terminal app url.
    - arguments: A string array of arguments.
 
 - Returns: Terminal text output.
 */
public func perform_code(at url: URL, with arguments: [String]) -> String?
{
    let command = "'\(url.path)' \(arguments.joined(separator: " "))" //Combine file path and arguments into one string
    
    let result = try? perform_terminal_command(command)
    
    return result
}

/**
 Converts a JSON string to an instance of the specified Codable type.
 
 - Parameters:
    - string: A JSON string representing the object.
 
 - Returns: An instance of the specified type if the string can be successfully parsed; otherwise, `nil`.
 */
public func string_to_codable<T: Codable>(from string: String) -> T?
{
    //Convert the string to Data
    guard let jsonData = string.data(using: .utf8)
    else
    {
        return nil
    }
    
    //Decode JSON into an instance of the specified type
    let decoder = JSONDecoder()
    do
    {
        let object = try decoder.decode(T.self, from: jsonData)
        return object
    }
    catch
    {
        print(error)
        return nil
    }
}

/**
 Converts a string to a SceneKit action.
 
 - Parameters:
    - string: A string representing the action and its parameters in the format `SCNActionName(param1, param2, ...)`.
 
 - Returns: A `SCNAction` if the string can be successfully parsed, otherwise `nil`.
 */
public func string_to_action(from string: String) -> SCNAction?
{
    let components = string.split(separator: "(")
    
    guard components.count == 2 else
    {
        print("Invalid format")
        return nil
    }
    
    let actionName = String(components[0]).trimmingCharacters(in: .whitespacesAndNewlines)
    let parametersString = components[1].dropLast() //Remove closing parenthesis
    
    //Parse parameters
    let parameters = parametersString.split(separator: ",").map
    { parameter in
        return parameter.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    switch actionName
    {
    case "moveBy":
        if parameters.count == 4,
           let x = Double(parameters[0]),
           let y = Double(parameters[1]),
           let z = Double(parameters[2]),
           let duration = Double(parameters[3])
        {
            return SCNAction.moveBy(x: CGFloat(x), y: CGFloat(y), z: CGFloat(z), duration: duration)
        }
    case "moveTo":
        if parameters.count == 4,
           let x = Double(parameters[0]),
           let y = Double(parameters[1]),
           let z = Double(parameters[2]),
           let duration = Double(parameters[3])
        {
            return SCNAction.move(to: SCNVector3(x, y, z), duration: duration)
        }
    case "rotateBy":
        if parameters.count == 4,
           let x = Double(parameters[0]),
           let y = Double(parameters[1]),
           let z = Double(parameters[2]),
           let duration = Double(parameters[3])
        {
            return SCNAction.rotateBy(x: CGFloat(x), y: CGFloat(y), z: CGFloat(z), duration: duration)
        }
    case "rotateTo":
        if parameters.count == 4,
           let x = Double(parameters[0]),
           let y = Double(parameters[1]),
           let z = Double(parameters[2]),
           let duration = Double(parameters[3])
        {
            return SCNAction.rotateTo(x: CGFloat(x), y: CGFloat(y), z: CGFloat(z), duration: duration)
        }
    case "fadeIn":
        if parameters.count == 1,
           let duration = Double(parameters[0])
        {
            return SCNAction.fadeIn(duration: duration)
        }
    case "fadeOut":
        if parameters.count == 1,
           let duration = Double(parameters[0])
        {
            return SCNAction.fadeOut(duration: duration)
        }
    case "scaleBy":
        if parameters.count == 2,
           let scale = Double(parameters[0]),
           let duration = Double(parameters[1])
        {
            return SCNAction.scale(by: CGFloat(scale), duration: duration)
        }
    case "scaleTo":
        if parameters.count == 2,
           let scale = Double(parameters[0]),
           let duration = Double(parameters[1])
        {
            return SCNAction.scale(to: CGFloat(scale), duration: duration)
        }
    case "sequence":
        //Format string: "sequence(action1, action2, ...)"
        let actions = parameters.compactMap { string_to_action(from: $0) }
        return SCNAction.sequence(actions)
    case "group":
        //Format string: "group(action1, action2, ...)"
        let actions = parameters.compactMap { string_to_action(from: $0) }
        return SCNAction.group(actions)
    case "removeAllActions":
        return SCNAction.run { node in node.removeAllActions() }
    default:
        print("Action \(actionName) not supported")
        return nil
    }
    
    print("Invalid parameters for action: \(actionName)")
    return nil
}

/**
 Sets the position or rotation of a node based on the provided string.
 
 - Parameters:
    - node: The `SCNNode` whose position or rotation is being set.
    - string: A string representing the action and its parameters in the format `setLocation(x, y, z)`, `setRotation(r, p, w)` or setPosition(x, y, z, r, p, w)`.
 
 > Rotation is specified in degrees.
 */
public func set_position(for node: SCNNode, from string: String)
{
    let components = string.split(separator: "(")
    
    guard components.count == 2
    else
    {
        print("Invalid format")
        return
    }
    
    let action_name = String(components[0]).trimmingCharacters(in: .whitespacesAndNewlines)
    let parameters_string = components[1].dropLast() // Remove closing parenthesis
    
    // Parse parameters
    let parameters = parameters_string.split(separator: ",").map
    { param in
        return param.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    switch action_name
    {
    case "setLocation":
        if parameters.count == 3,
           let x = Float(parameters[0]),
           let y = Float(parameters[1]),
           let z = Float(parameters[2])
        {
            node.position = SCNVector3(x, y, z)
        }
        else
        {
            print("Invalid parameters for location")
        }
        
    case "setLocationX":
        if parameters.count == 1,
           let x = Float(parameters[0])
        {
            node.position.x = CGFloat(x)
        }
        else
        {
            print("Invalid parameters for setLocationX")
        }
        
    case "setLocationY":
        if parameters.count == 1,
           let y = Float(parameters[0])
        {
            node.position.y = CGFloat(y)
        }
        else
        {
            print("Invalid parameters for setLocationY")
        }
        
    case "setLocationZ":
        if parameters.count == 1,
           let z = Float(parameters[0])
        {
            node.position.z = CGFloat(z)
        }
        else
        {
            print("Invalid parameters for setLocationZ")
        }
        
    case "setRotation":
        if parameters.count == 3,
           let r = Float(parameters[0]),
           let p = Float(parameters[1]),
           let w = Float(parameters[2])
        {
            node.eulerAngles = SCNVector3(r.to_rad, p.to_rad, w.to_rad)
        }
        else
        {
            print("Invalid parameters for rotation")
        }
        
    case "setRotationR":
        if parameters.count == 1,
           let r = Float(parameters[0])
        {
            node.eulerAngles.x = CGFloat(r.to_rad)
        }
        else
        {
            print("Invalid parameters for setRotationR")
        }
        
    case "setRotationP":
        if parameters.count == 1,
           let p = Float(parameters[0])
        {
            node.eulerAngles.y = CGFloat(p.to_rad)
        }
        else
        {
            print("Invalid parameters for setRotationP")
        }
        
    case "setRotationW":
        if parameters.count == 1,
           let w = Float(parameters[0])
        {
            node.eulerAngles.z = CGFloat(w.to_rad)
        }
        else
        {
            print("Invalid parameters for setRotationW")
        }
        
    case "setPosition":
        if parameters.count == 6,
           let x = Float(parameters[0]),
           let y = Float(parameters[1]),
           let z = Float(parameters[2]),
           let r = Float(parameters[3]),
           let p = Float(parameters[4]),
           let w = Float(parameters[5])
        {
            node.position = SCNVector3(x, y, z)
            node.eulerAngles = SCNVector3(r.to_rad, p.to_rad, w.to_rad)
        }
        else
        {
            print("Invalid parameters")
        }
        
    default:
        print("Action \(action_name) not supported")
    }
}
#endif

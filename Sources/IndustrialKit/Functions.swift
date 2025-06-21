//
//  Functions.swift
//  IndustrialKit
//
//  Created by Artem on 24.11.2022.
//

import Foundation
import SceneKit
import SwiftUI

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

/**
 Transforms input position by origin rotation.
 - Warning: All input/output arrays have only 3 values.
 - Parameters:
    - pointer_location: Input point location components – *x*, *y*, *z*.
    - pointer_rotation: Input origin rotation components – *r*, *p*, *w*.
 - Returns: Transformed inputed point location components – *x*, *y*, *z*.
*/
public func origin_transform(pointer_location: [Float], origin_rotation: [Float]) -> [Float]
{
    let new_x, new_y, new_z: Float
    if origin_rotation.reduce(0, +) > 0 // If at least one rotation angle of the origin is not equal to zero
    {
        // Calculate new values for coordinates components by origin rotation angles
        new_x = pointer_location[0] * cos(origin_rotation[1].to_rad) * cos(origin_rotation[2].to_rad) + pointer_location[2] * sin(origin_rotation[1].to_rad) - pointer_location[1] * sin(origin_rotation[2].to_rad)
        new_y = pointer_location[1] * cos(origin_rotation[0].to_rad) * cos(origin_rotation[2].to_rad) - pointer_location[2] * sin(origin_rotation[0].to_rad) + pointer_location[0] * sin(origin_rotation[2].to_rad)
        new_z = pointer_location[2] * cos(origin_rotation[0].to_rad) * cos(origin_rotation[1].to_rad) + pointer_location[1] * sin(origin_rotation[0].to_rad) - pointer_location[0] * sin(origin_rotation[1].to_rad)
    }
    else
    {
        // Return original values
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
public func visual_scaling(_ numbers: [Float], factor: Float) -> [Float] // Scaling lengths by divider
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
 Performs a terminal command and provides output asynchronously.

 - Parameters:
   - command: A terminal command.
   - output_handler: A closure that is called with each chunk of output (stdout and stderr) as a String.
        This closure is called multiple times, asynchronously, as the command produces output.
 
 - Returns: Text of command output.
                 
 - Throws: An NSError with domain "TerminalCommandError" if the command exits with a non-zero status code.
        The error's userInfo contains the localized description of the error and the termination status.
 */
public func perform_terminal_command(_ command: String, timeout: TimeInterval? = nil, output_handler: @escaping (String) -> Void = { _ in }) throws
{
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil
    
    let file_handle = pipe.fileHandleForReading
    var output_data = Data()
    let semaphore = DispatchSemaphore(value: 0)
    
    file_handle.readabilityHandler =
    { handle in
        let data = handle.availableData
        if data.isEmpty
        {
            return
        }
        output_data.append(data)
        if let output = String(data: data, encoding: .utf8)
        {
            output_handler(output)
        }
    }
    
    try task.run()
    
    // Wait for the process to exit asynchronously and signal the semaphore
    DispatchQueue.global().async
    {
        task.waitUntilExit()
        semaphore.signal()
    }
    
    let result: DispatchTimeoutResult
    if let timeout = timeout
    {
        result = semaphore.wait(timeout: .now() + timeout)
    }
    else
    {
        semaphore.wait()
        result = .success
    }
    
    file_handle.readabilityHandler = nil
    task.terminate() // Ensure termination in case it is still running
    
    if result == .timedOut
    {
        task.terminate()
        throw NSError(
            domain: "TerminalCommandError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Command timed out"]
        )
    }
    
    if task.terminationStatus != 0
    {
        throw NSError(
            domain: "TerminalCommandError",
            code: Int(task.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: "Command failed with status \(task.terminationStatus)"]
        )
    }
}

/**
 Performs terminal app.
 
 - Parameters:
    - url: A terminal app url.
    - arguments: A string array of arguments.
 
 - Returns: Terminal text output.
 */
public func perform_terminal_app(at url: URL, with arguments: [String], timeout: TimeInterval? = nil) -> String?
{
    let command = "'\(url.path)' \(arguments.joined(separator: " "))"
    var collected_output = ""
    
    do
    {
        try perform_terminal_command(command, timeout: timeout)
        { output in
            collected_output += output
        }
    }
    catch
    {
        print(error.localizedDescription)
    }
    
    return collected_output
}

public func perform_terminal_app(at url: URL, with arguments: [String] = [String](), timeout: TimeInterval? = nil, output_handler: @escaping (String) -> Void = { _ in })
{
    DispatchQueue.global(qos: .background).async
    {
        let command = "'\(url.path)' \(arguments.joined(separator: " "))"
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        do
        {
            try task.run()
        }
        catch
        {
            DispatchQueue.main.async
            {
                output_handler("Failed to launch process: \(error.localizedDescription)")
            }
            return
        }
        
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        pipe.fileHandleForReading.closeFile()
        task.waitUntilExit()
        
        if let output = String(data: outputData, encoding: .utf8)
        {
            DispatchQueue.main.async
            {
                output_handler(output)
            }
        }
    }
}

public func perform_terminal_app_sync(at url: URL, with arguments: [String])
{
    do
    {
        try perform_terminal_command("'\(url.path)' \(arguments.joined(separator: " "))", timeout: 0.1)
    }
    catch
    {
        print(error.localizedDescription)
    }
}
#endif

#if os(macOS)
//MARK: - Socket Works
private let response_count_limit: Int = 1024 * 1024

/**
 Sends a command to a UNIX socket and returns the response synchronously.

 - Parameters:
    - socket_path: A file system path to the UNIX domain socket.
    - command: The command string to send to the socket.

 - Returns: The response string from the socket, or `nil` if an error occurred.
 */
public func send_via_unix_socket(at socket_path: String, command: String) -> String?
{
    // Create socket
    let sockfd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard sockfd >= 0 else
    {
        return "Socket creation failed"
    }
    
    // Setup socket address
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    
    let path_cstring = socket_path.utf8CString
    if let base_address = path_cstring.withUnsafeBufferPointer({ $0.baseAddress })
    {
        strncpy(&addr.sun_path.0, base_address, MemoryLayout.size(ofValue: addr.sun_path))
    }
    
    let addr_size = socklen_t(MemoryLayout.size(ofValue: addr))
    
    // Connect to socket
    let result = withUnsafePointer(to: &addr)
    {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1)
        {
            connect(sockfd, $0, addr_size)
        }
    }
    
    guard result == 0 else
    {
        close(sockfd)
        return "Failed to connect to UNIX socket"
    }
    
    // Send command
    let command_to_send = command.utf8CString.dropLast()
    command_to_send.withUnsafeBufferPointer
    { buffer_ptr in
        write(sockfd, buffer_ptr.baseAddress!, buffer_ptr.count)
    }
    
    // Read response
    var response_data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)
    var is_receiving = true
    
    while is_receiving
    {
        let bytes_read = read(sockfd, &buffer, buffer.count)
        if bytes_read > 0
        {
            response_data.append(buffer, count: bytes_read)
        }
        else
        {
            is_receiving = false
        }
    }
    
    close(sockfd)
    
    return String(data: response_data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Invalid response"
}

/**
 Sends a command to a UNIX socket and receives the response asynchronously.

 - Parameters:
    - socket_path: A file system path to the UNIX domain socket.
    - command: The command string to send to the socket.
    - completion: A closure that returns the response string from the socket.

 - Note: The response is returned on the main thread.
 */
public func send_via_unix_socket(at socket_path: String, command: String, completion: @escaping (String) -> Void)
{
    DispatchQueue.global(qos: .userInitiated).async
    {
        guard let response = send_via_unix_socket(at: socket_path, command: command)
        else
        {
            DispatchQueue.main.async
            {
                completion("Failed to connect to UNIX socket")
            }
            return
        }
        
        // Call completion on main thread
        DispatchQueue.main.async
        {
            completion(response.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

/**
 Sends a command to a UNIX socket and receives the response asynchronously.

 - Parameters:
    - socket_path: A file system path to the UNIX domain socket.
    - arguments: A string array of arguments.
    - completion: A closure that returns the response string from the socket.

 - Note: The response is returned on the main thread.
 */
public func send_via_unix_socket(at socket_path: String, with arguments: [String], completion: @escaping (String) -> Void)
{
    send_via_unix_socket(at: socket_path, command: arguments.joined(separator: " "), completion: completion)
}

/**
 Sends a command to a UNIX socket and returns the response synchronously.

 - Parameters:
    - socket_path: A file system path to the UNIX domain socket.
    - arguments: A string array of arguments.

 - Returns: The response string from the socket, or `nil` if an error occurred.
 */
public func send_via_unix_socket(at socket_path: String, with arguments: [String]) -> String?
{
    return send_via_unix_socket(at: socket_path, command: arguments.joined(separator: " "))
}

/**
 Checks whether a process is currently listening on the specified Unix socket.
 
 This function uses the `lsof` utility to determine if any process is actively using
 the provided Unix domain socket path. It executes `lsof -U <path>` and analyzes the output.
 
 - Parameter path: The file system path to the Unix domain socket.
 - Returns: `true` if a process is using the socket at the given path, `false` otherwise.
 */
public func is_socket_active(at path: String) -> Bool
{
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
    process.arguments = ["-U", path]
    
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = Pipe()
    
    do
    {
        try process.run()
        process.waitUntilExit()
        
        let outputData = try? outputPipe.fileHandleForReading.readToEnd()
        let output = String(data: outputData ?? Data(), encoding: .utf8) ?? ""
        
        return output.contains(path)
    }
    catch
    {
        return false
    }
}
/*public func is_socket_active(at path: String) -> Bool
{
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
    process.arguments = ["-U", path]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()
    
    let group = DispatchGroup()
    group.enter()
    
    var output = ""
    let outputHandle = pipe.fileHandleForReading
    
    var didLeaveGroup = false
    let lock = NSLock()
    
    func safe_leave()
    {
        lock.lock()
        if !didLeaveGroup
        {
            didLeaveGroup = true
            group.leave()
        }
        lock.unlock()
    }
    
    outputHandle.readabilityHandler =
    { handle in
        let data = handle.availableData
        if data.isEmpty
        {
            outputHandle.readabilityHandler = nil
            safe_leave()
        }
        else
        {
            if let chunk = String(data: data, encoding: .utf8) {
                output += chunk
            }
        }
    }
    
    do
    {
        try process.run()
    }
    catch
    {
        outputHandle.readabilityHandler = nil
        safe_leave()
        return false
    }
    
    process.terminationHandler =
    { _ in
        outputHandle.readabilityHandler = nil
        safe_leave()
    }
    
    let timeoutResult = group.wait(timeout: .now() + 0.1)
    return timeoutResult == .success && output.contains(path)
}*/

/*public func is_socket_active(at path: String) -> Bool
{
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
    process.arguments = ["-U", path]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    
    do
    {
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output.contains(path)
    }
    catch
    {
        return false
    }
}*/
#endif

//MARK: - String functions
/**
 Converts a JSON string to an instance of the specified Codable type.
 
 - Parameters:
    - string: A JSON string representing the object.
 
 - Returns: An instance of the specified type if the string can be successfully parsed; otherwise, `nil`.
 */
public func string_to_codable<T: Codable>(from string: String) -> T?
{
    // Convert the string to Data
    guard let json_data = string.data(using: .utf8)
    else
    {
        return nil
    }
    
    // Decode JSON into an instance of the specified type
    let decoder = JSONDecoder()
    do
    {
        let object = try decoder.decode(T.self, from: json_data)
        return object
    }
    catch
    {
        print(error)
        return nil
    }
}

#if os(macOS)
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
    let parametersString = components[1].dropLast() // Remove closing parenthesis
    
    // Parse parameters
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
        // Format string: "sequence(action1, action2, ...)"
        let actions = parameters.compactMap { string_to_action(from: $0) }
        return SCNAction.sequence(actions)
    case "group":
        // Format string: "group(action1, action2, ...)"
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
            node.eulerAngles = SCNVector3(r, p, w)
        }
        else
        {
            print("Invalid parameters for rotation")
        }
        
    case "setRotationR":
        if parameters.count == 1,
           let r = Float(parameters[0])
        {
            node.eulerAngles.x = CGFloat(r)
        }
        else
        {
            print("Invalid parameters for setRotationR")
        }
        
    case "setRotationP":
        if parameters.count == 1,
           let p = Float(parameters[0])
        {
            node.eulerAngles.y = CGFloat(p)
        }
        else
        {
            print("Invalid parameters for setRotationP")
        }
        
    case "setRotationW":
        if parameters.count == 1,
           let w = Float(parameters[0])
        {
            node.eulerAngles.z = CGFloat(w)
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
            node.eulerAngles = SCNVector3(r, p, w)
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

//MARK: - Workspace program functions
/**
 Converts a string representation of a workspace program into an array of `WorkspaceProgramElement`.
 
 - Parameter code: A string containing the workspace program.
 - Returns: An array of `WorkspaceProgramElement` parsed from the input code.
 */
public func code_to_elements(code: String) -> [WorkspaceProgramElement]
{
    var elements: [WorkspaceProgramElement] = []
    
    let lines = code.split(separator: "\n")
    
    for line in lines
    {
        let trimmed_line = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let element = line_to_element(trimmed_line)
        {
            elements.append(element)
        }
    }
    
    return elements
    
    func line_to_element(_ input: String) -> WorkspaceProgramElement?
    {
        switch input
        {
        // Performers
        // p: r.(name).(program)
        case _ where match_regex(text: input, pattern: "p: r\\.\\((.*?)\\)\\.\\((.*?)\\)"):
            let data = extract_data_array(from: input, pattern: "p: r\\.\\((.*?)\\)\\.\\((.*?)\\)")
            return RobotPerformerElement(data_array: [data[0], data[1], "0", "false", "false", "0", "0", "0", "0", "0", "0", "0", "0"])
            
        // p: r.(name).index.[#]
        case _ where match_regex(text: input, pattern: "p: r\\.\\(([^()]*)\\)\\.index\\.\\[([^\\[\\]]*)\\]"):
            let data = extract_data_array(from: input, pattern: "p: r\\.\\(([^()]*)\\)\\.index\\.\\[([^\\[\\]]*)\\]")
            return RobotPerformerElement(data_array: [data[0], "", data[1], "false", "true", "0", "0", "0", "0", "0", "0", "0", "0"])
            
        // p: r.(name).single.[#, #, #, #, #, #, #, #]
        case _ where match_regex(text: input, pattern: "p: r\\.\\(([^()]*)\\)\\.single\\.\\[(\\d+), (\\d+), (\\d+), (\\d+), (\\d+), (\\d+), (\\d+), (\\d+)\\]"):
            let data = extract_data_array(from: input, pattern: "p: r\\.\\(([^()]*)\\)\\.single\\.\\[(\\d+), (\\d+), (\\d+), (\\d+), (\\d+), (\\d+), (\\d+), (\\d+)\\]")
            return RobotPerformerElement(
                data_array: [data[0], "", "0", "true", "false", data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8]])
            
        // p: t.(name).(program)
        case _ where match_regex(text: input, pattern: "p: t\\.\\((.*?)\\)\\.\\((.*?)\\)"):
            let data = extract_data_array(from: input, pattern: "p: t\\.\\((.*?)\\)\\.\\((.*?)\\)")
            return ToolPerformerElement(data_array: [data[0], data[1], "0", "false", "false", "0"])
            
        // p: t.(name).index.[#]
        case _ where match_regex(text: input, pattern: "p: t\\.\\(([^()]*)\\)\\.index\\.\\[([^\\[\\]]*)\\]"):
            let data = extract_data_array(from: input, pattern: "p: t\\.\\(([^()]*)\\)\\.index\\.\\[([^\\[\\]]*)\\]")
            return ToolPerformerElement(data_array: [data[0], "", data[1], "false", "true", "0"])
            
        // p: t.(name).single.[#]
        case _ where match_regex(text: input, pattern: "p: t\\.\\(([^()]*)\\)\\.single\\.\\[([^\\[\\]]*)\\]"):
            let data = extract_data_array(from: input, pattern: "p: t\\.\\(([^()]*)\\)\\.single\\.\\[([^\\[\\]]*)\\]")
            return ToolPerformerElement(data_array: [data[0], "", "0", "true", "false", data[1]])
        
        // Modifiers
        // m: [#] + [#]
        case _ where match_regex(text: input, pattern: "m: \\[([^\\[\\]]+)\\] \\+ \\[([^\\[\\]]+)\\]"):
            let data = extract_data_array(from: input, pattern: "m: \\[([^\\[\\]]+)\\] \\+ \\[([^\\[\\]]+)\\]")
            return MathModifierElement(data_array: ["+", data[0], data[1]])
            
        // m: [#] - [#]
        case _ where match_regex(text: input, pattern: "m: \\[([^\\[\\]]+)\\] - \\[([^\\[\\]]+)\\]"):
            let data = extract_data_array(from: input, pattern: "m: \\[([^\\[\\]]+)\\] - \\[([^\\[\\]]+)\\]")
            return MathModifierElement(data_array: ["-", data[0], data[1]])
            
        // m: [#] * [#]
        case _ where match_regex(text: input, pattern: "m: \\[([^\\[\\]]+)\\] \\* \\[([^\\[\\]]+)\\]"):
            let data = extract_data_array(from: input, pattern: "m: \\[([^\\[\\]]+)\\] \\* \\[([^\\[\\]]+)\\]")
            return MathModifierElement(data_array: ["·", data[0], data[1]])
            
        // m: [#] / [#]
        case _ where match_regex(text: input, pattern: "m: \\[([^\\[\\]]+)\\] / \\[([^\\[\\]]+)\\]"):
            let data = extract_data_array(from: input, pattern: "m: \\[([^\\[\\]]+)\\] / \\[([^\\[\\]]+)\\]")
            return MathModifierElement(data_array: ["÷", data[0], data[1]])
            
        // m: [#] ^ [#]
        case _ where match_regex(text: input, pattern: "m: \\[([^\\[\\]]+)\\] \\^ \\[([^\\[\\]]+)\\]"):
            let data = extract_data_array(from: input, pattern: "m: \\[([^\\[\\]]+)\\] \\^ \\[([^\\[\\]]+)\\]")
            return MathModifierElement(data_array: ["^", data[0], data[1]])
           
        // m: [#] move [#]
        case _ where match_regex(text: input, pattern: "m: \\[([^\\[\\]]+)\\] move \\[([^\\[\\]]+)\\]"):
            let data = extract_data_array(from: input, pattern: "m: \\[([^\\[\\]]+)\\] move \\[([^\\[\\]]+)\\]")
            return MoverModifierElement(data_array: ["Move", data[0], data[1]])
            
        // m: [#] copy [#]
        case _ where match_regex(text: input, pattern: "m: \\[([^\\[\\]]+)\\] copy \\[([^\\[\\]]+)\\]"):
            let data = extract_data_array(from: input, pattern: "m: \\[([^\\[\\]]+)\\] copy \\[([^\\[\\]]+)\\]")
            return MoverModifierElement(data_array: ["Duplicate", data[0], data[1]])
            
        // m: [#] write value
        case _ where match_regex(text: input, pattern: "m: \\[([^\\[\\]]+)\\] write (.*)"):
            let data = extract_data_array(from: input, pattern: "m: \\[([^\\[\\]]+)\\] write (.*)")
            return WriterModifierElement(data_array: [data[0], data[1]])
           
        // m: t.(name).observe.[#, #, #] [#, #, #]
        case _ where match_regex(text: input, pattern: "m: r\\.\\(([^()]*)\\)\\.observe\\.\\[(.*?)\\] \\[(.*?)\\]"):
            let data = extract_data_array(from: input, pattern: "m: r\\.\\(([^()]*)\\)\\.observe\\.\\[(.*?)\\] \\[(.*?)\\]")
            return ObserverModifierElement(data_array: ["Robot", data[0], data[1].replacingOccurrences(of: ", ", with: "|"), data[2].replacingOccurrences(of: ", ", with: "|")])
            
        // m: t.(name).observe.[#, #, #] [#, #, #]
        case _ where match_regex(text: input, pattern: "m: t\\.\\(([^()]*)\\)\\.observe\\.\\[(.*?)\\] \\[(.*?)\\]"):
            let data = extract_data_array(from: input, pattern: "m: t\\.\\(([^()]*)\\)\\.observe\\.\\[(.*?)\\] \\[(.*?)\\]")
            return ObserverModifierElement(data_array: ["Tool", data[0], data[1].replacingOccurrences(of: ", ", with: "|"), data[2].replacingOccurrences(of: ", ", with: "|")])
            
        // m: change.(name)
        case _ where match_regex(text: input, pattern: "m: change\\.\\(([^()]*)\\)"):
            let data = extract_data_array(from: input, pattern: "m: change\\.\\(([^()]*)\\)")
            return ChangerModifierElement(data_array: [data[0]])
            
        // m: clear
        case _ where match_regex(text: input, pattern: "m: clear"):
            return CleanerModifierElement()
            
        // Logic
        // l: if [#] = [#] jump.(name)
        case _ where match_regex(text: input, pattern: "l: if \\[([^\\[\\]]+)\\] = \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)"):
            let data = extract_data_array(from: input, pattern: "l: if \\[([^\\[\\]]+)\\] = \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)")
            return ComparatorLogicElement(data_array: ["=", data[0], data[1], data[2]])
            
        // l: if [#] > [#] jump.(name)
        case _ where match_regex(text: input, pattern: "l: if \\[([^\\[\\]]+)\\] = \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)"):
            let data = extract_data_array(from: input, pattern: "l: if \\[([^\\[\\]]+)\\] > \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)")
            return ComparatorLogicElement(data_array: [">", data[0], data[1], data[2]])
            
        // l: if [#] >= [#] jump.(name)
        case _ where match_regex(text: input, pattern: "l: if \\[([^\\[\\]]+)\\] >= \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)"):
            let data = extract_data_array(from: input, pattern: "l: if \\[([^\\[\\]]+)\\] >= \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)")
            return ComparatorLogicElement(data_array: ["⩾", data[0], data[1], data[2]])
            
        // l: if [#] < [#] jump.(name)
        case _ where match_regex(text: input, pattern: "l: if \\[([^\\[\\]]+)\\] < \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)"):
            let data = extract_data_array(from: input, pattern: "l: if \\[([^\\[\\]]+)\\] < \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)")
            return ComparatorLogicElement(data_array: ["<", data[0], data[1], data[2]])
            
        // l: if [#] <= [#] jump.(name)
        case _ where match_regex(text: input, pattern: "l: if \\[([^\\[\\]]+)\\] <= \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)"):
            let data = extract_data_array(from: input, pattern: "l: if \\[([^\\[\\]]+)\\] <= \\[([^\\[\\]]+)\\] jump\\.\\(([^()]*)\\)")
            return ComparatorLogicElement(data_array: ["⩽", data[0], data[1], data[2]])
            
        // l: jump.(name)
        case _ where match_regex(text: input, pattern: "l: jump\\.\\(([^()]*)\\)"):
            let data = extract_data_array(from: input, pattern: "l: jump\\.\\(([^()]*)\\)")
            return JumpLogicElement(data_array: [data[0]])
            
        // l: mark.(name)
        case _ where match_regex(text: input, pattern: "l: mark\\.\\(([^()]*)\\)"):
            let data = extract_data_array(from: input, pattern: "l: mark\\.\\(([^()]*)\\)")
            return MarkLogicElement(data_array: [data[0]])
            
        default:
            break
        }
        
        return nil
    }
}

/**
 Converts an array of `WorkspaceProgramElement` back into a string representation of a workspace program.
 
 - Parameter elements: An array of `WorkspaceProgramElement` to be converted into a string.
 - Returns: A string representation of the workspace program.
*/
public func elements_to_code(elements: [WorkspaceProgramElement]) -> String
{
    var code: String = ""
    
    for (index, element) in elements.enumerated()
    {
        code.append(element.code_string)
        
        if index < elements.count - 1
        {
            code.append("\n")
        }
    }
    
    return code
}

private func match_regex(text: String, pattern: String) -> Bool
{
    do
    {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        let match = regex.firstMatch(in: text, options: [], range: range)
        return match != nil
    }
    catch
    {
        print(error.localizedDescription)
        return false
    }
}

private func extract_data_array(from text: String, pattern regex: String) -> [String]
{
    do
    {
        let regex = try NSRegularExpression(pattern: regex)
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        var results: [String] = []

        for match in matches
        {
            for groupIndex in 1..<match.numberOfRanges
            {
                if let range = Range(match.range(at: groupIndex), in: text)
                {
                    results.append(String(text[range]))
                }
            }
        }

        return results
    }
    catch
    {
        print(error.localizedDescription)
        return []
    }
}

//MARK: - UI functions
private func colors_by_seed(seed: Int) -> [Color]
{
    var colors = [Color]()

    srand48(seed)
    
    for _ in 0..<256
    {
        var color = [Double]()
        for _ in 0..<3
        {
            let random_number = Double(drand48() * Double(128) + 64)
            
            color.append(random_number)
        }
        colors.append(Color(red: color[0] / 255, green: color[1] / 255, blue: color[2] / 255))
    }

    return colors
}

let registers_colors = colors_by_seed(seed: 5433)

#if os(macOS)
// MARK: Connector state strings
/**
 Splits the input string by spaces, but preserves substrings enclosed in { } as single elements.
 
 For example:
 Input:  "move_to {\"x\": 1, \"y\": 2} 0 0 0"
 Output: ["move_to", "{\"x\": 1, \"y\": 2}", "0", "0", "0"]
 
 - Parameter input: The full input string to split.
 - Returns: An array of string parts with braces-enclosed substrings kept intact.
 
 > This function can be used to decode input strings where one of the arguments is a JSON-formatted substring.
 */
public func safe_input_split(_ input: String) -> [String]
{
    var r: [String] = []
    var c = ""
    var b = false
    
    for ch in input
    {
        if ch == "{" { b = true; c.append(ch) }
        else if ch == "}" { b = false; c.append(ch) }
        else if ch == " " && !b
        {
            if !c.isEmpty { r.append(c); c = "" }
        }
        else
        {
            c.append(ch)
        }
    }
    if !c.isEmpty { r.append(c) }
    return r
}
#endif

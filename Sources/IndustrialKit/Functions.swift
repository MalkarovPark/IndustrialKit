//
//  Functions.swift
//  IndustrialKit
//
//  Created by Artem on 24.11.2022.
//

import Foundation
import SwiftUI
import RealityKit

/**
 Finds and updates mismatched name.
 
 - Parameters:
    - name: A checked name.
    - names: A current array of names.
 
 - Returns: Name after validation. May differ from the input.
 */
public func unique_name(for name: String, in names: [String]) -> String
{
    let set = Set(names)
    
    var candidate = name
    var counter = 2
    
    while set.contains(candidate)
    {
        candidate = "\(name) \(counter)"
        counter += 1
    }
    
    return candidate
}

/**
 Transforms input position by origin rotation.
 - Warning: All input/output arrays have only 3 values.
 - Parameters:
    - pointer_location: Input point location components – *x*, *y*, *z*.
    - pointer_rotation: Input origin rotation components – *r*, *p*, *w*.
 - Returns: Transformed inputed point location components – *x*, *y*, *z*.
*/
public func origin_transform(
    pointer_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ),
    origin_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    )
) -> (
    x: Float, y: Float, z: Float,
    r: Float, p: Float, w: Float
)
{
    var new_position = pointer_position
    
    if origin_position.r != 0 || origin_position.p != 0 || origin_position.w != 0 // If at least one rotation angle of the origin is not equal to zero
    {
        // Calculate new values for coordinates components by origin rotation angles
        new_position.x = pointer_position.x * cos(origin_position.p.to_rad) * cos(origin_position.w.to_rad) + pointer_position.z * sin(origin_position.p.to_rad) - pointer_position.y * sin(origin_position.w.to_rad)
        new_position.y = pointer_position.y * cos(origin_position.r.to_rad) * cos(origin_position.w.to_rad) - pointer_position.z * sin(origin_position.r.to_rad) + pointer_position.x * sin(origin_position.w.to_rad)
        new_position.z = pointer_position.z * cos(origin_position.r.to_rad) * cos(origin_position.p.to_rad) + pointer_position.y * sin(origin_position.r.to_rad) - pointer_position.x * sin(origin_position.p.to_rad)
    }
    
    return new_position
}

///Deep copy for codable objects.
public func clone_codable<T: WorkspaceProgramElement>(_ object: T) -> T?
{
    do
    {
        let encoded = try JSONEncoder().encode(object)
        let clone = try JSONDecoder().decode(T.self, from: encoded)
        clone.id = UUID()
        return clone
    }
    catch
    {
        //print(error)
        return nil
    }
}

/// Deep copy of any program element with preserving subclass and properties.
public func clone_element(_ element: WorkspaceProgramElement, to program: ProductionProgram)
{
    // Performer
    if let e = element as? RobotPerformerElement { insert(e); return }
    if let e = element as? ToolPerformerElement { insert(e); return }

    // Modifier
    if let e = element as? MoverModifierElement { insert(e); return }
    if let e = element as? WriterModifierElement { insert(e); return }
    if let e = element as? MathModifierElement { insert(e); return }
    if let e = element as? ChangerModifierElement { insert(e); return }
    if let e = element as? ObserverModifierElement { insert(e); return }
    if let e = element as? CleanerModifierElement { insert(e); return }

    // Logic
    if let e = element as? JumpLogicElement { insert(e); return }
    if let e = element as? ComparatorLogicElement { insert(e); return }
    if let e = element as? MarkLogicElement { insert(e); return }

    //print("clone_element: unsupported type:", type(of: element))
    
    func insert<T: WorkspaceProgramElement>(_ original: T)
    {
        if let copy = clone_codable(original)
        {
            program.add_element(copy)
        }
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
@MainActor public func pass_robot_preferences(_ origin_location: Bool, _ origin_rotation: Bool, _ space_scale: Bool, from: Robot, to: Robot)
{
    if origin_location
    {
        to.origin_position.x = from.origin_position.x
        to.origin_position.y = from.origin_position.y
        to.origin_position.z = from.origin_position.z
    }
    
    if origin_rotation
    {
        to.origin_position.r = from.origin_position.r
        to.origin_position.p = from.origin_position.p
        to.origin_position.w = from.origin_position.w
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
@MainActor public func pass_position_programs(names: [String], from: Robot, to: Robot)
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
        //print(error)
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
public func perform_terminal_command(_ command: String, timeout: TimeInterval? = nil, output_handler: @escaping @Sendable (String) -> Void = { _ in }) throws
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
    
    let output_queue = DispatchQueue(label: "output_data_queue")

    file_handle.readabilityHandler =
    { handle in
        let data = handle.availableData
        if data.isEmpty { return }
        
        output_queue.async
        {
            output_data.append(data)
        }
        
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
    let output_queue = DispatchQueue(label: "collected_output_queue")
    var collected_output = ""
    
    do
    {
        try perform_terminal_command(command, timeout: timeout)
        { output in
            output_queue.sync
            {
                collected_output += output
            }
        }
    }
    catch
    {
        //print(error.localizedDescription)
    }
    
    return collected_output
}

public func perform_terminal_app(
    at url: URL, with arguments: [String] = [String](),
    timeout: TimeInterval? = nil,
    output_handler: @escaping @Sendable (String) -> Void = { _ in }
)
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
        //print(error.localizedDescription)
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
public func send_via_unix_socket(
    at socket_path: String,
    command: String,
    completion: @escaping @Sendable (String) -> Void
)
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
public func send_via_unix_socket(at socket_path: String, with arguments: [String], completion: @Sendable @escaping (String) -> Void)
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
public func is_socket_active(at path: String) async -> Bool
{
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
    process.arguments = ["-U", path]
    
    let output_pipe = Pipe()
    process.standardOutput = output_pipe
    process.standardError = Pipe()
    
    do
    {
        try process.run()
    }
    catch
    {
        return false
    }
    
    return await withCheckedContinuation
    { continuation in
        Task
        {
            let output_data = try? output_pipe.fileHandleForReading.readToEnd()
            process.waitUntilExit()
            
            let output = String(data: output_data ?? Data(), encoding: .utf8) ?? ""
            continuation.resume(returning: output.contains(path))
        }
    }
}
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
        //print(error)
        return nil
    }
}

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

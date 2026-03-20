//
//  ToolConnector.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import SceneKit

/**
 This subtype provides control for industrial tool.
 
 Contains special function for operation code performation.
 */
open class ToolConnector: WorkspaceObjectConnector, @unchecked Sendable
{
    // MARK: - Device Handling
    /**
     Performs real tool by operation code value.
     
     - Parameters:
        - code: The operation code value of the operation performed by the real tool.
     */
    public func perform(code: Int) throws
    {
        start_process(code: code)
        
        while performing_state != .processing {} //Wait for performing state
        while performing_state == .processing {} //Wait for completion
        
        switch performing_state
        {
        case .error:
            throw NSError(domain: output_string ?? "Performing Error", code: 0, userInfo: nil)
        default:
            break
        }
    }
    
    /**
     Starts execution of a real tool operation by its operation code.
     
     This method initiates the operation but does not wait for it to complete.
     Use higher-level methods (e.g., `perform(code:)`) for synchronous execution.
     
     - Parameters:
        - code: The operation code identifying the tool action to be performed.
     */
    open func start_process(code: Int)
    {
        
    }
    
    private var performing_task = Task<Void, Error> {}
    
    /**
     Performs real tool by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the real tool.
        - completion: A completion function that is calls when the performing completes.
     */
    public func perform(code: Int, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
    {
        if !connected
        {
            completion(.failure(NSError(domain: "Not Connected to Tool", code: 0, userInfo: nil)))
            return
        }
        
        canceled = false
        
        performing_task = Task
        {
            do
            {
                try self.perform(code: code)
                if !canceled
                {
                    completion(.success(()))
                }
            }
            catch
            {
                completion(.failure(error))
            }
            
            canceled = false
        }
    }
    
    // MARK: - Sync Handling
    /// A tool model controller.
    public var model_controller: ToolModelController?
    
    override open func sync_with_device()
    {
        guard let current_device_state = current_device_state else { return }
        
        // Update current performing state
        performing_state = current_device_state.performing_state
        output_string = current_device_state.output_string
        
        // Update current output data
        if let output_data = current_device_state.output_data
        {
            current_device_output = output_data
        }
        
        // Apply model data
        if let model_controller = model_controller,
           let entity_animations = current_device_state.entity_animations,
           performing_state == .processing
        {
            model_controller.process_animation(by: entity_animations)
        }
    }
    
    open var current_device_state: ToolState?
    {
        return nil
    }
}

public struct ToolState: Codable
{
    public init(
        performing_state: PerformingState = .none,
        
        output_data: DeviceOutputData? = nil,
        output_string: String? = nil,
        
        entity_animations: [EntityAnimationData]? = nil
    )
    {
        self.performing_state = performing_state
        
        self.output_data = output_data
        self.output_string = output_string
        
        self.entity_animations = entity_animations
    }
    
    public var performing_state: PerformingState = .none
    
    public var output_data: DeviceOutputData?
    public var output_string: String?
    
    public var entity_animations: [EntityAnimationData]?
}

//MARK: - External Connector
public class ExternalToolConnector: ToolConnector, ExternalConnector, @unchecked Sendable
{
    /// Clone connector instance.
    open override func clone() -> Self
    {
        let copy = type(of: self).init()
        
        copy.module_name = module_name
        copy.package_url = package_url
        
        copy.external_parameters = external_parameters
        copy.parameters = parameters
        
        return copy
    }
    
    // MARK: Init functions
    /// An external module name
    public var module_name: String
    
    /// For access to code
    public var package_url: URL
    
    public init(
        _ module_name: String,
        package_url: URL,
        
        parameters: [ConnectionParameter]
    )
    {
        self.module_name = module_name
        self.package_url = package_url
        
        self.external_parameters = parameters
    }
    
    required init()
    {
        self.module_name = ""
        self.package_url = URL(fileURLWithPath: "")
    }
    
    /*deinit
    {
        stop_program_component()
    }*/
    
    // MARK: Program component handling
    public var program_component_enabled: Bool = false
    {
        didSet
        {
            program_component_enabled ?
            start_program_component() :
            stop_program_component()
        }
    }
    
    public func start_program_component()
    {
        Task
        {
            program_component_status = .starting
            
            if await !is_socket_active(at: socket_name)
            {
                perform_terminal_app_sync(
                    at: program_component_url,
                    with: [
                        socket_name,
                        " > /dev/null 2>&1 &"
                    ]
                )
            }
            
            let timeout_seconds: UInt64 = 2
            let check_interval: UInt64 = 100_000_000
            var attempts: UInt64 = 0
            let max_attempts = timeout_seconds * 10
            
            while await !is_socket_active(at: socket_name)
            {
                if attempts >= max_attempts
                {
                    program_component_status = .not_running
                    return
                }
                try? await Task.sleep(nanoseconds: check_interval)
                attempts += 1
            }
            
            program_component_status = .running
        }
    }
    
    public func stop_program_component()
    {
        send_via_unix_socket(at: socket_name, command: "stop")
        program_component_status = .not_running
    }
    
    @Published public var program_component_status: ProgramComponentStatus = .not_running
    
    public var program_component_url: URL
    {
        return package_url.appendingPathComponent("Code/Connector")
    }
    
    public var socket_name: String
    {
        return "/tmp/\(module_name)\(Int(bitPattern: id))_tool_connector_socket"
    }
    
    // MARK: Connection Handling
    override open var default_parameters: [ConnectionParameter]
    {
        return external_parameters
    }
    
    public var external_parameters = [ConnectionParameter]()
    
    override open func connection_process() async -> Bool
    {
        #if os(macOS)
        // Perform connection
        let arguments = ["connect"] + (connection_parameters_values?.map { "\($0)" } ?? [])
        
        guard let terminal_output: String = send_via_unix_socket(at: socket_name, with: arguments)
        else
        {
            connection_error = NSError(domain: "Couldn't perform external code", code: 0, userInfo: nil)
            return false
        }
        
        // Get output
        if let range = terminal_output.range(of: "\"([^\"]*)\"", options: .regularExpression)
        {
            connection_output_string = String(terminal_output[range]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        
        // Get connection result
        if let start = terminal_output.range(of: "<done:")?.upperBound,
           let end = terminal_output[start...].firstIndex(of: ">")
        {
            connection_output_string = terminal_output[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            return true
        }
        if let start = terminal_output.range(of: "<failed:")?.upperBound,
           let end = terminal_output[start...].firstIndex(of: ">")
        {
            connection_error = NSError(domain: terminal_output[start..<end].trimmingCharacters(in: .whitespacesAndNewlines), code: 0, userInfo: nil)
            return false
        }
        if terminal_output.contains("<done>")
        {
            connection_output_string = "Connected"
            return true
        }
        if terminal_output.contains("<failed>")
        {
            connection_error = NSError(domain: "Connection failed", code: 0, userInfo: nil)
            return false
        }
        
        connection_error = NSError(domain: "External module connector unavailable", code: 0, userInfo: nil)
        return false
        #else
        return false
        #endif
    }
    
    override open func disconnection_process()// async
    {
        #if os(macOS)
        guard let terminal_output: String = send_via_unix_socket(at: socket_name, with: ["disconnect"])
        else
        {
            connection_failure = true
            return
        }
        #endif
    }
    
    // MARK: Device Handling
    open override func start_process(code: Int)
    {
        #if os(macOS)
        let command = ["perform", "\(code)"]
        
        guard let terminal_output: String = send_via_unix_socket(
            at: socket_name,
            with: command
        )
        else
        {
            connection_error = NSError(domain: "Couldn't perform operation", code: 0, userInfo: nil)
            connection_failure = true
            connected = false
            return
        }
        #endif
    }
    
    open override var current_device_state: ToolState?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: socket_name, with: ["current_device_state"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let device_state: ToolState = string_to_codable(from: output)
        {
            return device_state
        }
        #endif
        
        connected = false
        return nil
    }
}

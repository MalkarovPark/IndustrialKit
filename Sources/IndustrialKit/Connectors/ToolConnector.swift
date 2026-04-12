//
//  ToolConnector.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import SceneKit

/// A connector that provides control over an industrial tool.
///
/// `ToolConnector` executes discrete operation codes on a real device
/// and synchronizes execution state with a virtual model.
///
/// It supports:
/// - Operation-based execution
/// - Synchronous and asynchronous performing
/// - Model animation synchronization
open class ToolConnector: ProductionObjectConnector, @unchecked Sendable
{
    // MARK: - Device Handling
    /// Performs a synchronous operation on the tool by operation code.
    ///
    /// Blocks execution until the operation completes or fails.
    ///
    /// - Parameter code: Operation code defining tool action.
    /// - Throws: Error if operation fails on device side.
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
    
    /// Starts execution of a tool operation without blocking.
    ///
    /// - Parameter code: Operation code defining tool action.
    open func start_process(code: Int) {}
    
    private var performing_task = Task<Void, Error> {}
    
    /// Performs a tool operation asynchronously with completion handler.
    ///
    /// - Parameters:
    ///   - code: Operation code defining tool action.
    ///   - completion: Completion result callback.
    public func perform(
        code: Int,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    )
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
    
    // MARK: - Tool Sync
    /// A model controller responsible for tool animation and visualization.
    ///
    /// Synchronizes tool state with entity-based animation system.
    public var model_controller: ToolModelController?
    
    /// Synchronizes tool state with device feedback.
    ///
    /// Updates:
    /// - Performing state
    /// - Output data
    /// - Entity animations
    ///
    /// Ensures consistency between simulation and real device behavior.
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
    
    /// The current state of the tool device.
    ///
    /// Must be overridden by subclasses to provide real device state.
    open var current_device_state: ToolState?
    {
        return nil
    }
}

/// A snapshot of tool execution state.
///
/// Contains:
/// - Performing state
/// - Output data
/// - Output string
/// - Entity animations for visualization
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
    
    /// Current performing state of the tool.
    public var performing_state: PerformingState = .none
    
    /// Output data produced by tool execution.
    public var output_data: DeviceOutputData?
    
    /// Human-readable output string from tool device.
    public var output_string: String?
    
    /// Animation data describing tool entity behavior.
    public var entity_animations: [EntityAnimationData]?
}

//MARK: - External Connector
/// A tool connector driven by an external runtime module.
///
/// Executes tool operations via socket communication with a
/// background process.
///
/// Supports:
/// - External execution lifecycle
/// - Operation dispatching
/// - Live model animation updates
public class ExternalToolConnector: ToolConnector, ExternalConnector, @unchecked Sendable
{
    // MARK: Initializators
    /// Creates an empty external tool connector instance.
    ///
    /// This initializer is required for dynamic instantiation and copying.
    /// The connector is created in an unconfigured state and must be
    /// configured before use.
    required init()
    {
        self.module_name = ""
        self.package_url = URL(fileURLWithPath: "")
    }
    
    /// Creates an external tool connector with module configuration.
    ///
    /// - Parameters:
    ///   - module_name: The name of the external module providing tool logic.
    ///   - package_url: The location of the external module package.
    ///   - parameters: A list of connection parameters for the external tool.
    ///
    /// This initializer prepares the connector for interaction with an
    /// external runtime responsible for performing tool operations.
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
    
    open override func copy() -> Self
    {
        let copy = type(of: self).init()
        
        copy.module_name = module_name
        copy.package_url = package_url
        
        copy.external_parameters = external_parameters
        copy.parameters = parameters
        
        return copy
    }
    
    /*deinit
    {
        stop_program_component()
    }*/
    
    // MARK: External Module
    /// The name of the external module controlling the tool.
    public var module_name: String
    
    /// The filesystem URL of the external package providing robot logic.
    public var package_url: URL
    
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
        #if os(macOS)
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
        #endif
    }
    
    public func stop_program_component()
    {
        #if os(macOS)
        send_via_unix_socket(at: socket_name, command: "stop")
        program_component_status = .not_running
        #endif
    }
    
    @Published public var program_component_status: ProgramComponentStatus = .not_running
    
    public var program_component_url: URL
    {
        return package_url.appendingPathComponent("Connector")
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
    
    /// A list of external connection parameters used for runtime configuration.
    ///
    /// This array defines parameters received from or passed to an external system.
    public var external_parameters = [ConnectionParameter]()
    
    override open func perform_connection() async -> Bool
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
    
    override open func perform_disconnection()// async
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

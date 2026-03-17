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
        while performing_state == .processing { }
        
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
            completion(
                .failure(NSError(domain: "Not Connected to Tool", code: 0, userInfo: nil))
            )
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
    
    // MARK: - Model Handling
    /// A tool model controller.
    public var model_controller: ToolModelController?
    
    override open func sync_with_device()
    {
        guard let current_tool_state = current_tool_state else { return }
        
        // Update current performing state
        performing_state = current_tool_state.performing_state
        output_string = current_tool_state.output_string
        
        // Apply model data
        if let model_controller = model_controller,
           let entity_animations = current_tool_state.entity_animations
        {
            model_controller.process_animation(by: entity_animations)
        }
    }
    
    open var current_tool_state: ToolState?
    {
        return nil
    }
    
    /*override open func reset_device_model()
    {
        if let model_controller = model_controller,
           let entity_animations = initial_entity_animations
        {
            model_controller.process_animation(by: entity_animations)
        }
    }
    
    open var initial_entity_animations: [EntityAnimationData]?
    {
        return nil//[]
    }*/
}

public struct ToolState: Codable
{
    public init(
        performing_state: PerformingState = .none,
        entity_animations: [EntityAnimationData]? = nil,
        
        output_string: String? = nil
    )
    {
        self.performing_state = performing_state
        self.entity_animations = entity_animations
        
        self.output_string = output_string
    }
    
    public var performing_state: PerformingState = .none
    public var entity_animations: [EntityAnimationData]?
    
    public var output_string: String?
}

//MARK: - External Connector
public class ExternalToolConnector: ToolConnector, @unchecked Sendable
{
    // MARK: Init functions
    /// An external module name
    public var module_name: String
    
    /// For access to code
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL, parameters: [ConnectionParameter])
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
    
    // MARK: Parameters import
    override open var default_parameters: [ConnectionParameter]
    {
        return external_parameters
    }
    
    public var external_parameters = [ConnectionParameter]()
    
    // MARK: Connection
    override open func connection_process() async -> Bool
    {
        #if os(macOS)
        // Perform connection
        let arguments = ["connect"] + (connection_parameters_values?.map { "\($0)" } ?? [])
        
        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: arguments)
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
        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["disconnect"])
        else
        {
            
            connection_failure = true
            return
        }
        #endif
    }
    
    // MARK: Performing
    private var state: PerformingState
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(
            at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket",
            with: ["performing_state"])
        else
        {
            return .completed //.error
        }
        
        return PerformingState(rawValue: output) ?? .completed //.error
        #else
        return PerformingState(rawValue: output) ?? .completed //.error
        #endif
    }
    
    open override func start_process(code: Int)
    {
        #if os(macOS)
        // Perform operation
        let command = ["perform", "\(code)"]
        
        guard let terminal_output: String = send_via_unix_socket(
            at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket",
            with: command)
        else
        {
            connection_error = NSError(domain: "Couldn't perform operation", code: 0, userInfo: nil)
            connection_failure = true
            connected = false
            return
        }
        
        // Process output
        while state == .processing && !canceled
        {
            sync_with_device()
        }
        
        model_controller?.reset_entities() // Remove entities actions if performing finished
        #endif
    }
    
    open override func reset_device()
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["reset_device"])
        else
        {
            connection_failure = true
            connected = false
            return
        }
        #endif
    }
    
    // MARK: State Data
    /*open override var current_device_state: DeviceState?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["current_device_state"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let device_state: DeviceState = string_to_codable(from: output)
        {
            return device_state
        }
        #endif
        
        connected = false
        return nil
    }
    
    open override var initial_device_state: DeviceState?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["initial_device_state"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let device_state: DeviceState = string_to_codable(from: output)
        {
            return device_state
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }
    
    // MARK: Model Sync
    open override var current_entity_animations: [EntityAnimationData]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["current_entity_animations"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let entity_animations: [EntityAnimationData] = string_to_codable(from: output)
        {
            return entity_animations
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }
    
    open override var initial_entity_animations: [EntityAnimationData]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["initial_entity_animations"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let entity_animations: [EntityAnimationData] = string_to_codable(from: output)
        {
            return entity_animations
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }*/
}

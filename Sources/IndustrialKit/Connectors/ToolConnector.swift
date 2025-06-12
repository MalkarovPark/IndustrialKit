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
open class ToolConnector: WorkspaceObjectConnector
{
    // MARK: - Device handling
    private var performing_task = Task {}
    
    /**
     Performs real tool by operation code value.
     
     - Parameters:
        - code: The operation code value of the operation performed by the real tool.
     */
    open func perform(code: Int)
    {
        
    }
    
    /**
     Performs real tool by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the real tool.
        - completion: A completion function that is calls when the performing completes.
     */
    public func perform(code: Int, completion: @escaping () -> Void)
    {
        canceled = false
        performing_task = Task
        {
            self.perform(code: code)
            
            if !canceled
            {
                // canceled = true
                completion()
            }
            canceled = false
        }
    }
    
    /// Inforamation code updated by connector.
    open var info_output: [Float]?
    {
        return nil
    }
    
    // MARK: - Model handling
    /// A tool model controller.
    public var model_controller: ToolModelController?
    
    override open func sync_device()
    {
        // model_controller?.nodes[safe: "Node", default: SCNNode()].runAction(SCNAction())
    }
}

//MARK: - External Connector
public class ExternalToolConnector: ToolConnector
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
        // fatalError("init() has not been implemented")
    }
    
    /// An array of default connection parameters.
    open var default_parameters: [ConnectionParameter]
    {
        return [ConnectionParameter]()
    }
    
    // MARK: Parameters import
    override open var parameters: [ConnectionParameter]
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
            if output != String()
            {
                output += "\n"
            }
            
            self.output += "Couldn't perform external code"
            return false
        }
        
        // Get output
        if let range = terminal_output.range(of: "\"([^\"]*)\"", options: .regularExpression)
        {
            if output != String()
            {
                output += "\n"
            }
            
            output += String(terminal_output[range]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        
        // Get connection result
        if let start = terminal_output.range(of: "<done:")?.upperBound,
           let end = terminal_output[start...].firstIndex(of: ">")
        {
            if !output.isEmpty { output += "\n" }
            output += terminal_output[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            return true
        }
        if let start = terminal_output.range(of: "<failed:")?.upperBound,
           let end = terminal_output[start...].firstIndex(of: ">")
        {
            if !output.isEmpty { output += "\n" }
            output += terminal_output[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            return false
        }
        if terminal_output.contains("<done>")
        {
            if !output.isEmpty { output += "\n" }
            output += "Done"
            return true
        }
        if terminal_output.contains("<failed>")
        {
            if !output.isEmpty { output += "\n" }
            output += "Failed"
            return false
        }
        
        if !output.isEmpty { output += "\n" }
        output += "External module connector unavailable"
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
            self.output += "Couldn't perform external code"
            connection_failure = true
            connected = false
            return
        }
        #endif
    }
    
    // MARK: Performing
    open override func perform(code: Int)//, completion: @escaping () -> Void)
    {
        #if os(macOS)
        // Perform operation
        let command = ["perform", "\(code)"]
        
        guard let terminal_output: String = send_via_unix_socket(
            at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket",
            with: command)
        else
        {
            self.output += "Couldn't perform operation"
            connection_failure = true
            connected = false
            return
        }
        
        // Output from external
        var output: String?
        {
            guard let output: String = send_via_unix_socket(
                at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket",
                with: ["sync_device"])
            else
            {
                return nil
            }
            
            return output
        }
        
        var state: (completed: Bool, nodes_actions: [String]?)
        {
            if let output = output
            {
                return tool_connector_state_decode(from: output)
            }
            else
            {
                return (completed: true, nodes_actions: nil)
            }
        }
        
        var is_actions_performing = false
        
        // Process output
        /*while !state.completed && !canceled
        {
            let state = state
            
            if !is_actions_performing
            {
                is_actions_performing = true
                
                if let actions = state.nodes_actions // Apply nodes actions by connector
                {
                    model_controller?.apply_nodes_actions(by: actions)
                    {
                        is_actions_performing = false
                    }
                }
            }
        }*/
        
        while !state.completed && !canceled
        {
            if !is_actions_performing
            {
                if let actions = state.nodes_actions
                {
                    is_actions_performing = true
                    
                    let semaphore = DispatchSemaphore(value: 0)
                    
                    model_controller?.apply_nodes_actions(by: actions)
                    {
                        is_actions_performing = false
                        
                        usleep(250_000)
                        
                        semaphore.signal()
                    }
                    
                    semaphore.wait()
                }
            }
        }
        
        model_controller?.remove_all_model_actions() // Remove nodes actions if performing finished
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
    
    // MARK: Info
    open override var info_output: [Float]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["info_output"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        let components = output.split(separator: " ")
        
        let floats: [Float] = components.compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
        
        return floats.isEmpty ? nil : floats
        #else
        return nil
        #endif
    }
    
    // MARK: Statistics
    open override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["updated_charts_data"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let charts: [WorkspaceObjectChart] = string_to_codable(from: output)
        {
            return charts
        }
        #endif
        
        connected = false
        return nil
    }
    
    open override func updated_states_data() -> [StateItem]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["updated_states_data"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            return states
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }

    open override func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["initial_charts_data"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let charts: [WorkspaceObjectChart] = string_to_codable(from: output)
        {
            return charts
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }

    open override func initial_states_data() -> [StateItem]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["initial_states_data"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            return states
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }
    
    // MARK: Modeling
    open override func sync_device()
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: ["sync_device"])
        else
        {
            connection_failure = true
            connected = false
            return
        }
        
        // Split the output into lines
        let lines = output.split(separator: "\n").map { String($0) }
        
        for i in 0..<lines.count // line in lines
        {
            // Split output into components
            let components: [String] = lines[i].split(separator: " ").map { String($0) }
            
            // Check that output contains exactly two parameters
            guard components.count == 2
            else
            {
                continue
            }
            
            if let action = string_to_action(from: components[1])
            {
                model_controller?.nodes[safe: components[0], default: SCNNode()].runAction(action)
            }
        }
        #endif
    }
}

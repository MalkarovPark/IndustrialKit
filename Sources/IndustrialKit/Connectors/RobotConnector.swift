//
//  RobotConnector.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import SceneKit

/**
 This subtype provides control for industrial robot.
 
 Contains special function for movement to point performation.
 */
open class RobotConnector: WorkspaceObjectConnector, @unchecked Sendable
{
    // MARK: - Parameters
    /**
     A robot cell origin position.
     
     Tuple with coordinates – *x*, *y*, *z* and angles – *r*, *p*, *w*.
     */
    public var origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// A robot cell box scale.
    public var space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    
    // MARK: - Device handling
    private var moving_task = Task {}
    
    /**
     Performs movement on real robot by target position.
     
     - Parameters:
        - point: The target position performed by the real robot.
     */
    open func move_to(point: PositionPoint)
    {
        
    }
    
    /**
     Performs movement on real robot by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the real robot.
        - update_model: Update model by connector.
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping @Sendable () -> Void)
    {
        if connected
        {
            canceled = false
            moving_task = Task
            {
                self.move_to(point: point)
                
                if !canceled
                {
                    completion()
                }
                canceled = false
            }
        }
        else
        {
            completion()
        }
    }
    
    // MARK: - Model handling
    /// A robot model controller.
    public var model_controller: RobotModelController?
    
    override open func sync_model()
    {
        
    }
}

//MARK: - External Connector
public class ExternalRobotConnector: RobotConnector
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

        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: arguments) else
        {
            if output != String()
            {
                output += "\n"
            }
            
            self.output += "Couldn't perform external code"
            return false
        }
        
        // Get output
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
        if !output.isEmpty { output += "\n" }
        
        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["disconnect"])
        else
        {
            self.output += "Disconnection operation not initiated"
            connection_failure = true
            return
        }
        
        self.output += terminal_output.isEmpty ? "Disconnected" : terminal_output
        #endif
    }
    
    // MARK: Performing
    override open var performing_state: (output: PerformingState, log: String)
    {
        return (output: state, log: String())
    }
    
    private var state: PerformingState
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(
            at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket",
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
    
    private var external_pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(
            at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket",
            with: ["sync_pointer"])
        else
        {
            return nil
        }
        
        let components = output.split(separator: " ").compactMap { Float($0) }
        return components.count == 6 ? (components[0], components[1], components[2],
                                        components[3], components[4], components[5]) : nil
        #else
        return nil
        #endif
    }
    
    private var external_nodes_positions: [String]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(
            at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket",
            with: ["sync_model"])
        else
        {
            return nil
        }
        
        let lines = output.components(separatedBy: "\n")
        return lines == [""] ? nil : lines
        #else
        return nil
        #endif
    }
    
    override open func move_to(point: PositionPoint)
    {
        #if os(macOS)
        // Perform to point moving
        let origin_position = ["\(origin_position.x)",  "\(origin_position.y)",  "\(origin_position.z)",
                               "\(origin_position.r)",  "\(origin_position.p)",  "\(origin_position.w)"]
        let command = ["move_to"] + [point.json_string()] + origin_position
        
        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: command)
        else
        {
            self.output += "Couldn't move to position"
            connection_failure = true
            connected = false
            return
        }
        
        // Process output
        while state == .processing && !canceled
        {
            sync_model()
        }
        #endif
    }
    
    open override func sync_model()
    {
        if let position = external_pointer_position // Update pointer node position by connector
        {
            model_controller?.update_pointer_position((x: position.x, y: position.y, z: position.z, r: position.r, p: position.p, w: position.w))
            
            if let nodes_positions = external_nodes_positions // Update nodes positions by connector (real device)
            {
                model_controller?.apply_nodes_positions(by: nodes_positions)
            }
            else // Update nodes positions by model controller (simulated device)
            {
                do
                {
                    try model_controller?.update_nodes(pointer_position: position, origin_position: origin_position)
                }
                catch
                {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    open override func reset_device()
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["reset_device"])
        else
        {
            connection_failure = true
            connected = false
            return
        }
        #endif
    }
    
    // MARK: Statistics
    open override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["updated_charts_data"])
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
        
        return nil
    }
    
    open override func updated_states_data() -> [StateItem]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["updated_states_data"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            connection_failure = true
            connected = false
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
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["initial_charts_data"])
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
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["initial_states_data"])
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
    /*open override func sync_model()
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["sync_model"])
        else
        {
            connection_failure = true
            connected = false
            return
        }
        
        // Split the output into lines
        let lines = output.split(separator: "\n").map { String($0) }
        
        for line in lines
        {
            // Split the line by space to separate node name and action string
            let components = line.split(separator: " ", maxSplits: 1).map { String($0) }
            
            // Ensure there are two components: the node name and the action string
            guard components.count == 2
            else
            {
                continue
            }
            
            set_position(for: model_controller?.nodes[safe: components[0], default: SCNNode()] ?? SCNNode(), from: components[1])
        }
        #endif
    }*/
}

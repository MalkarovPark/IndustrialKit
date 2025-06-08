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
open class RobotConnector: WorkspaceObjectConnector
{
    // MARK: - Parameters
    /**
     A robot pointer location.
     
     Array with three coordinates – [*x*, *y*, *z*].
     */
    public var pointer_location: [Float] = [0.0, 0.0, 0.0]
    
    /**
     A robot pointer rotation.
     
     Array with three angles – [*r*, *p*, *w*].
     */
    public var pointer_rotation: [Float] = [0.0, 0.0, 0.0]
    
    /**
     A robot cell origin location.
     
     Array with three coordinates – [*x*, *y*, *z*].
     */
    public var origin_location = [Float](repeating: 0, count: 3)
    
    /**
     A robot cell origin rotation.
     
     Array with three angles – [*r*, *p*, *w*].
     */
    public var origin_rotation = [Float](repeating: 0, count: 3)
    
    /// A robot cell box scale.
    public var space_scale = [Float](repeating: 200, count: 3)
    
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
    public func move_to(point: PositionPoint, completion: @escaping () -> Void)
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
        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["disconnect"])
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
    override open func move_to(point: PositionPoint)
    {
        #if os(macOS)
        // Prepare command for get output
        //let pointer_location = [point.x, point.y, point.z]
        //let pointer_rotation = [point.r, point.p, point.w]
                
        //let values = (pointer_location + pointer_rotation + origin_location + origin_rotation + [Float(point.move_speed)]).map { "\($0)" }
        //let command = ["move_to"] + values + [point.move_type.rawValue]
        
        let origin_position = (origin_location + origin_rotation).map { "\($0)" }        
        let command = ["move_to"] + origin_position + [point.json_string()]
        
        // Perform to point moving
        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_connector_socket", with: command)
        else
        {
            self.output += "Couldn't perform position"
            connection_failure = true
            connected = false
            return
        }
        
        // Output from external
        var output: String?
        {
            guard let output: String = send_via_unix_socket(
                at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket",
                with: ["sync_model"])
            else
            {
                return nil
            }
            
            return output
        }
        
        var state: (completed: Bool, pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)?, nodes_positions: [String]?)
        {
            if let output = output
            {
                let nodes_positions: [String]? = output.split(separator: "\n").map { String($0) }
                
                return (completed: Bool(), pointer_position: nil, nodes_positions: nil)
            }
            else
            {
                return (completed: true, pointer_position: nil, nodes_positions: nil)
            }
        }
        
        // Process output
        while !state.completed
        {
            let state = state
            
            if let position = state.pointer_position // Update pointer node position by connector
            {
                model_controller?.update_pointer_position(pos_x: position.x, pos_y: position.y, pos_z: position.z, rot_x: position.r, rot_y: position.p, rot_z: position.w)
                
                if let nodes_positions = state.nodes_positions // Update nodes positions by connector
                {
                    let updates: [(String, String)] = nodes_positions.compactMap
                    {
                        let components = $0.split(separator: " ", maxSplits: 1).map { String($0) }
                        return components.count == 2 ? (components[0], components[1]) : nil
                    }
                    
                    if let model_controller = model_controller // Process robot model parts
                    {
                        for (node_name, action_string) in updates
                        {
                            set_position(for: model_controller.nodes[safe: node_name, default: SCNNode()], from: action_string)
                        }
                    }
                }
                else // Update nodes positions by model controller
                {
                    model_controller?.update_nodes(pointer_location: [position.x, position.y, position.z], pointer_rotation: [position.r, position.p, position.w], origin_location: origin_location, origin_rotation: origin_rotation)
                }
            }
            
            usleep(100000)
        }
        #endif
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
    open override func sync_model()
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
    }
}

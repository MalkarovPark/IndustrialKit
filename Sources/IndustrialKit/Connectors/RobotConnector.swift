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
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping () -> Void)
    {
        canceled = false
        moving_task = Task
        {
            self.move_to(point: point)
            
            if !canceled
            {
                // canceled = true
                completion()
            }
            canceled = false
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

        guard let terminal_output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Connector"), with: arguments) else
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
        
        // Get output
        if let range = terminal_output.range(of: "\"([^\"]*)\"", options: .regularExpression)
        {
            if !output.isEmpty
            {
                output += "\n"
            }
            
            output += String(terminal_output[range]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        
        // Get connection result
        let is_success = terminal_output.contains("<done>")

        if let tag = is_success ? "//<done:" : "//<failed:",
           let range = terminal_output.range(of: tag),
           let end = terminal_output[range.upperBound...].firstIndex(of: ">")
        {
            output += terminal_output[range.upperBound..<end].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        else
        {
            return false
        }

        return is_success
        // Get connection result
        /*if terminal_output.contains("<done>")
        {
            return true
        }
        else
        {
            return false
        }*/
        
        // Get connection result
        /*if terminal_output.contains("<done>")
        {
            return true
        }
        else
        {
            return false
        }*/
        #else
        return false
        #endif
    }
    
    override open func disconnection_process() async
    {
        #if os(macOS)
        guard let terminal_output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Connector"), with: ["disconnect"])
        else
        {
            self.output += "Couldn't perform external code"
            return
        }
        #endif
    }
    
    // MARK: Performing
    override open func move_to(point: PositionPoint)
    {
        #if os(macOS)
        let pointer_location = [point.x, point.y, point.z]
        let pointer_rotation = [point.r, point.p, point.w]
        
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Connector"), with: ["update_nodes_positions"] + (pointer_location + pointer_rotation + origin_location + origin_rotation).map { "\($0)" })
        else
        {
            return
        }
        #endif
    }
    
    open override func reset_device()
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Connector"), with: ["reset_device"])
        else
        {
            return
        }
        #endif
    }
    
    // MARK: Statistics
    open override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Connector"), with: ["updated_charts_data"])
        else
        {
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
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Connector"), with: ["updated_states_data"])
        else
        {
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            return states
        }
        #endif
        
        return nil
    }

    open override func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Controller"), with: ["initial_charts_data"])
        else
        {
            return nil
        }
        
        if let charts: [WorkspaceObjectChart] = string_to_codable(from: output)
        {
            return charts
        }
        #endif
        
        return nil
    }

    open override func initial_states_data() -> [StateItem]?
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Controller"), with: ["initial_states_data"])
        else
        {
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            return states
        }
        #endif
        
        return nil
    }
    
    // MARK: Modeling
    open override func sync_model()
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Controller"), with: ["sync_model"])
        else
        {
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

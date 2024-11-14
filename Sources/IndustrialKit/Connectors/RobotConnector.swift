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
    //MARK: - Parameters
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
    
    ///A robot cell box scale.
    public var space_scale = [Float](repeating: 200, count: 3)
    
    //MARK: - Device handling
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
                //canceled = true
                completion()
            }
            canceled = false
        }
    }
    
    //MARK: - Model handling
    ///A robot model controller.
    public var model_controller: RobotModelController?
    
    override open func sync_model()
    {
        //model_controller?.nodes[safe: "Node", default: SCNNode()].runAction(SCNAction())
    }
}

//MARK: - External Connector
public class ExternalRobotConnector: RobotConnector
{
    //MARK: - Init functions
    ///An external module name
    public var module_name: String
    
    ///For access to code
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL)
    {
        self.module_name = module_name
        self.package_url = package_url
    }
    
    //MARK: - Connection
    override open func connection_process() async -> Bool
    {
        //Perform connection
        if let parameters = connection_parameters_values
        {
            guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: ["connect"] + (parameters).map { "\($0)" })
            else
            {
                self.output += "Couldn't perform external exec"
                
                return false
            }
        }
        else
        {
            guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: ["connect"])
            else
            {
                if output != String()
                {
                    output += "\n"
                }
                
                self.output += "Couldn't perform external exec"
                
                return false
            }
        }
        
        //Get output
        if let range = output.range(of: "\"([^\"]*)\"", options: .regularExpression)
        {
            if output != String()
            {
                output += "\n"
            }
            
            self.output += String(output[range]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        
        if output.contains("<done>")
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    override open func disconnection_process() async
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: ["disconnect"])
        else
        {
            self.output += "Couldn't perform external exec"
            
            return
        }
    }
    
    //MARK: - Performing
    override open func move_to(point: PositionPoint)
    {
        let pointer_location = [point.x, point.y, point.z]
        let pointer_rotation = [point.r, point.p, point.w]
        
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: ["update_nodes_positions"] + (pointer_location + pointer_rotation + origin_location + origin_rotation).map { "\($0)" })
        else
        {
            return
        }
    }
    
    open override func reset_device()
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: ["reset_device"])
        else
        {
            return
        }
    }
    
    //MARK: - Statistics
    open override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: ["updated_charts_data"])
        else
        {
            return nil
        }
        
        if let charts: [WorkspaceObjectChart] = string_to_codable(from: output)
        {
            return charts
        }
        
        return nil
    }
    
    open override func updated_states_data() -> [StateItem]?
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: ["updated_states_data"])
        else
        {
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            return states
        }
        
        return nil
    }

    open override func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["initial_charts_data"])
        else
        {
            return nil
        }
        
        if let charts: [WorkspaceObjectChart] = string_to_codable(from: output)
        {
            return charts
        }
        
        return nil
    }

    open override func initial_states_data() -> [StateItem]?
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["initial_states_data"])
        else
        {
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            return states
        }
        
        return nil
    }
    
    //MARK: - Modeling
    open override func sync_model()
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["sync_model"])
        else
        {
            return
        }
        
        //Split the output into lines
        let lines = output.split(separator: "\n").map { String($0) }
        
        var completed = [Bool](repeating: false, count: lines.count)

        for i in 0..<lines.count //line in lines
        {
            //Split output into components
            let components: [String] = lines[i].split(separator: " ").map { String($0) }

            //Check that output contains exactly two parameters
            guard components.count == 2
            else
            {
                return
            }
            
            if let action = string_to_action(from: components[1])
            {
                model_controller?.nodes[safe: components[0], default: SCNNode()].runAction(action, completionHandler: { local_completion(index: i) })
            }
        }
        
        func local_completion(index: Int)
        {
            completed[index] = true
            
            if completed.allSatisfy({ $0 == true })
            {
                //completion()
            }
        }
    }
}

//
//  ToolModelController.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import SceneKit

///Provides control over visual model for robot.
open class ToolModelController: ModelController
{
    /**
     Performs tool model action by operation code value.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool visual model.
     */
    open func nodes_perform(code: Int)
    {
        
    }
    
    /**
     Performs tool model action by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool visual model.
        - completion: A completion function that is calls when the performing completes.
     */
    open func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        nodes_perform(code: code)
        completion()
    }
    
    ///Stops connected model actions performation.
    public final func remove_all_model_actions()
    {
        for (_, node) in nodes //Remove all node actions
        {
            node.removeAllActions()
        }
        
        reset_nodes()
    }
    
    ///Inforamation code updated by model controller.
    public var info_output: [Float]?
}

//MARK: - External Model Controller
public class ExternalToolModelController: ToolModelController
{
    public var module_name: String //External module name
    public var package_url: URL //For access to code
    
    public init(_ module_name: String, package_url: URL)
    {
        self.module_name = module_name
        self.package_url = package_url
    }
    
    //MARK: Base
    open override func reset_nodes()
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["reset_nodes"])
        else
        {
            return
        }

        //Split output into components
        let components: [String] = output.split(separator: " ").map { String($0) }

        //Check that output contains exactly two parameters
        guard components.count == 2
        else
        {
            return
        }
        
        if let action = string_to_action(from: components[1])
        {
            nodes[safe: components[0], default: SCNNode()].runAction(action)
        }
    }

    open override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["updated_charts_data"])
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
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["updated_states_data"])
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

    //MARK: Special
    open override func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["nodes_perform", "\(code)"])
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
                completed.append(false)
                nodes[safe: components[0], default: SCNNode()].runAction(action, completionHandler: { local_completion(index: i) })
            }
        }
        
        func local_completion(index: Int)
        {
            completed[index] = true
            
            if completed.allSatisfy({ $0 == true })
            {
                completion()
            }
        }

        /*//Split output into components
        let components: [String] = output.split(separator: " ").map { String($0) }

        //Check that output contains exactly two parameters
        guard components.count == 2
        else
        {
            return
        }
        
        if let action = string_to_action(from: components[1])
        {
            nodes[safe: components[0], default: SCNNode()].runAction(action, completionHandler: completion)
        }*/
    }
}

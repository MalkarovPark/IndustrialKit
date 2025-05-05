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
    
    /// Stops connected model actions performation.
    public final func remove_all_model_actions()
    {
        for (_, node) in nodes // Remove all node actions
        {
            node.removeAllActions()
        }
        
        reset_nodes()
    }
    
    /// Inforamation code updated by model controller.
    open var info_output: [Float]?
    {
        return nil
    }
}

//MARK: - External Model Controller
public class ExternalToolModelController: ToolModelController
{
    // MARK: Init functions
    /// An external module name.
    public var module_name: String
    
    /// For access to code.
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL, nodes_names: [String])
    {
        self.module_name = module_name
        self.package_url = package_url
        
        self.external_nodes_names = nodes_names
    }
    
    required init()
    {
        self.module_name = ""
        self.package_url = URL(fileURLWithPath: "")
    }
    
    // MARK: Parameters import
    override open var nodes_names: [String]
    {
        return external_nodes_names
    }
    
    public var external_nodes_names = [String]()
    
    // MARK: Performing
    open override func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Controller"), with: ["nodes_perform", "\(code)"])
        else
        {
            return
        }

        // Split the output into lines
        let lines = output.split(separator: "\n").map { String($0) }
        
        var completed = [Bool](repeating: false, count: lines.count)

        for i in 0..<lines.count // line in lines
        {
            // Split output into components
            let components: [String] = lines[i].split(separator: " ").map { String($0) }

            // Check that output contains exactly two parameters
            guard components.count == 2
            else
            {
                return
            }
            
            if let action = string_to_action(from: components[1])
            {
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
        #else
        completion()
        #endif
    }
    
    open override func reset_nodes()
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Controller"), with: ["reset_nodes"])
        else
        {
            return
        }

        // Split the output into lines
        let lines = output.split(separator: "\n").map { String($0) }
        
        var completed = [Bool](repeating: false, count: lines.count)

        for i in 0..<lines.count // line in lines
        {
            // Split output into components
            let components: [String] = lines[i].split(separator: " ").map { String($0) }

            // Check that output contains exactly two parameters
            guard components.count == 2
            else
            {
                return
            }
            
            if let action = string_to_action(from: components[1])
            {
                nodes[safe: components[0], default: SCNNode()].runAction(action, completionHandler: { local_completion(index: i) })
            }
        }
        
        func local_completion(index: Int)
        {
            completed[index] = true
        }
        #endif
    }
    
    // MARK: Info
    open override var info_output: [Float]?
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Connector"), with: ["info_output"])
        else
        {
            return nil
        }
        
        let components = output.split(separator: " ")
        
        let floats: [Float] = components.compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
        
        return floats.isEmpty ? nil : floats
        
        /*let cleaned = output.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let components = cleaned.split(separator: ",")
        
        let floats: [Float] = components.compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
        
        return floats.isEmpty ? nil : floats*/
        #else
        return nil
        #endif
    }
    
    // MARK: Statistics
    open override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        #if os(macOS)
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Controller"), with: ["updated_charts_data"])
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
        guard let output: String = perform_terminal_app(at: package_url.appendingPathComponent("/Code/Controller"), with: ["updated_states_data"])
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
}

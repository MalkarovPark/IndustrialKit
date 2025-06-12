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
    
    /*
     /// Stops connected model actions performation.
     public final func remove_all_model_actions()
     {
         for (_, node) in nodes
         {
             node.removeAllActions()
         }

         #if os(macOS)
         for i in nodes_actions_completed.indices
         {
             nodes_actions_completed[i] = true
         }

         if !nodes_actions_completed.isEmpty
         {
             nodes_actions_completion?()
             nodes_actions_completion = nil
             nodes_actions_completed.removeAll()
         }
         #endif

         reset_nodes()
     }
     
     /// Inforamation code updated by model controller.
     open var info_output: [Float]?
     {
         return nil
     }
     
     private var nodes_actions_completed = [Bool]()
     private var nodes_actions_completion: (() -> Void)?
     
     #if os(macOS)
     /**
      Applies a sequence of actions to scene nodes based on string commands and calls a completion handler when all actions are finished.
      
      Each string in `lines` must follow the format `"nodeName action"`, where `nodeName` is the identifier of the node to apply the action to, and `action` is a string representing the action to perform.
      
      - Parameters:
      - lines: An array of command strings, each specifying a node name and an action.
      - completion: A closure called once all actions have been completed.
      */
     public func apply_nodes_actions(by lines: [String], completion: @escaping () -> Void = {})
     {
         if !nodes_actions_completed.isEmpty && nodes_actions_completed.contains(false)
         {
             return
         }

         nodes_actions_completed = [Bool](repeating: false, count: lines.count)
         nodes_actions_completion = completion
         let expected_count = lines.count

         for i in 0..<lines.count
         {
             let line = lines[i]

             if let range = line.range(of: " ")
             {
                 let name = String(line[..<range.lowerBound])
                 let command = String(line[range.upperBound...])

                 DispatchQueue.main.async
                 {
                     if let action = string_to_action(from: command)
                     {
                         let node = self.nodes[safe: name, default: SCNNode()]

                         let timeout: TimeInterval = 3.0
                         DispatchQueue.main.asyncAfter(deadline: .now() + timeout)
                         {
                             if self.nodes_actions_completed.count == expected_count &&
                                i < self.nodes_actions_completed.count &&
                                !self.nodes_actions_completed[i]
                             {
                                 self.local_completion(index: i)
                             }
                         }

                         node.runAction(action)
                         {
                             self.local_completion(index: i)
                         }
                     }
                     else
                     {
                         self.local_completion(index: i)
                     }
                 }
             }
             else
             {
                 self.local_completion(index: i)
             }
         }
     }

     private func local_completion(index: Int)
     {
         guard index < nodes_actions_completed.count else
         {
             return
         }

         nodes_actions_completed[index] = true

         if !nodes_actions_completed.contains(false)
         {
             nodes_actions_completion?()
             nodes_actions_completion = nil
             nodes_actions_completed.removeAll()
         }
     }
    */
    
    /// Stops connected model actions performation.
    public final func remove_all_model_actions()
    {
        for (_, node) in nodes // Remove all node actions
        {
            node.removeAllActions()
        }
        
        #if os(macOS)
        nodes_actions_completed.removeAll()
        #endif
        
        reset_nodes()
    }
    
    /// Inforamation code updated by model controller.
    open var info_output: [Float]?
    {
        return nil
    }
    
    #if os(macOS)
    /**
     Applies a sequence of actions to scene nodes based on string commands and calls a completion handler when all actions are finished.
     
     Each string in `lines` must follow the format `"nodeName action"`, where `nodeName` is the identifier of the node to apply the action to, and `action` is a string representing the action to perform.
     
     - Parameters:
     - lines: An array of command strings, each specifying a node name and an action.
     - completion: A closure called once all actions have been completed.
     */
    public func apply_nodes_actions(by lines: [String], completion: @escaping () -> Void = {})
    {
        if nodes_actions_completed.contains(false)
        {
            return
        }
        
        //var completed = [Bool](repeating: false, count: lines.count)
        nodes_actions_completed = [Bool](repeating: false, count: lines.count)
        
        for i in 0..<lines.count // line in lines
        {
            let line = lines[i]
            if let range = line.range(of: " ")
            {
                // Split output into components
                let name = String(line[..<range.lowerBound])
                let command = String(line[range.upperBound...])
                
                DispatchQueue.main.async
                {
                    if let action = string_to_action(from: command)
                    {
                        //self.is_nodes_updating = true
                        
                        /*self.nodes[safe: name, default: SCNNode()].runAction(action, completionHandler: {
                            local_completion(index: i)
                        })*/
                        self.nodes[safe: name, default: SCNNode()].runAction(action, completionHandler: {
                            self.local_completion(index: i, completion: completion)
                        })
                    }
                }
            }
            else
            {
                completion()
                //return
            }
        }
        
        /*func local_completion(index: Int)
        {
            completed[index] = true
            
            if completed.allSatisfy({ $0 == true })
            {
                completion()
            }
        }*/
    }
    
    private var nodes_actions_completed = [Bool]()
    
    private func local_completion(index: Int, completion: @escaping () -> Void = {})
    {
        if nodes_actions_completed.count > 0
        {
            nodes_actions_completed[index] = true
            
            if !nodes_actions_completed.contains(false) //nodes_actions_completed.allSatisfy({ $0 == true })
            {
                completion()
            }
        }
    }
    
    //internal var is_nodes_updating = false
    #endif
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
    
    // MARK: Modeling
    open override func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        #if os(macOS)
        //guard !is_nodes_updating else { return }
        //is_nodes_updating = true
        
        DispatchQueue.global(qos: .utility).async
        {
            send_via_unix_socket(at: "/tmp/\(self.module_name)_tool_controller_socket", with: ["nodes_perform", "\(code)"])
            { output in
                // Split the output into lines
                let lines = output.split(separator: "\n").map { String($0) }
                
                self.apply_nodes_actions(by: lines, completion: completion)
            }
        }
        
        #else
        completion()
        #endif
    }
    
    open override func reset_nodes()
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_controller_socket", with: ["reset_nodes"])
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
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_controller_socket", with: ["info_output"])
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
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_controller_socket", with: ["updated_charts_data"])
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
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_controller_socket", with: ["updated_states_data"])
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
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_controller_socket", with: ["initial_charts_data"])
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
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_controller_socket", with: ["initial_states_data"])
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

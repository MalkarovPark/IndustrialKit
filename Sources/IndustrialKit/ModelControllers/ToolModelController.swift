//
//  ToolModelController.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import RealityKit

///Provides control over visual model for robot.
open class ToolModelController: ModelController, @unchecked Sendable
{
    /// Cancel perform flag.
    public var canceled = false
    
    private var performing_task = Task<Void, Error> {}
    
    /**
     Performs tool model action by operation code value.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool visual model.
     */
    open func perform(code: Int) throws
    {
        //...
        
        /*if !canceled
        {
            pointer_position = (x: point.x, y: point.y, z: point.z,
                                r: point.r, p: point.p, w: point.w)
            do
            {
                try update_model()
            }
            catch
            {
                throw error
            }
        }*/
    }
    
    /**
     Performs tool model action by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool visual model.
        - completion: A completion function that is calls when the performing completes.
     */
    open func perform(code: Int, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
    {
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
    
    /// Stops connected model actions performation.
    public final func remove_all_model_actions()
    {
        /*for (_, node) in entities // Remove all node actions
        {
            node.removeAllActions()
        }
        
        #if os(macOS)
        entities_actions_performing_count = 0
        #endif*/
    }
    
    /// Inforamation code updated by model controller.
    open var info_output: [Float]?
    {
        return nil
    }
    
    /**
     Applies a sequence of actions to scene entities based on string commands and calls a completion handler when all actions are finished.
     
     Each string in `lines` must follow the format `"nodeName action"`, where `nodeName` is the identifier of the node to apply the action to, and `action` is a string representing the action to perform.
     
     - Parameters:
     - lines: An array of command strings, each specifying a node name and an action.
     - completion: A closure called once all actions have been completed.
     */
    public func apply_entities_actions(by lines: [String], completion: @escaping () -> Void = {})
    {
        /*#if os(macOS)
        if entities_actions_performing_count > 0
        {
            completion()
            return
        }
        
        entities_actions_performing_count = lines.count
        
        for i in 0..<lines.count // line in lines
        {
            let line = lines[i]
            if let range = line.range(of: " ")
            {
                // Split output into components
                let name = String(line[..<range.lowerBound])
                let command = String(line[range.upperBound...])
                
                if let action = string_to_action(from: command)
                {
                    self.entities[safe: name, default: Entity()].runAction(action, completionHandler: {
                        self.local_completion(index: i, completion: completion)
                    })
                }
                else
                {
                    completion()
                }
            }
            else
            {
                completion()
            }
        }
        #else
        completion()
        #endif*/
    }
    
    #if os(macOS)
    private var entities_actions_performing_count = 0
    
    private func local_completion(index: Int, completion: @escaping () -> Void = {})
    {
        if entities_actions_performing_count > 0
        {
            entities_actions_performing_count -= 1
            
            if entities_actions_performing_count == 0
            {
                completion()
            }
        }
    }
    #endif
}

//MARK: - External Model Controller
public class ExternalToolModelController: ToolModelController, @unchecked Sendable
{
    // MARK: Init functions
    /// An external module name.
    public var module_name: String
    
    /// For access to code.
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL, entities_names: [String])
    {
        self.module_name = module_name
        self.package_url = package_url
        
        self.external_entities_names = entities_names
    }
    
    required init()
    {
        self.module_name = ""
        self.package_url = URL(fileURLWithPath: "")
    }
    
    // MARK: Parameters import
    override open var entities_names: [String]
    {
        return external_entities_names
    }
    
    public var external_entities_names = [String]()
    
    // MARK: Modeling
    /*open override func entities_perform(code: Int, completion: @escaping @Sendable () -> Void)
    {
        #if os(macOS)
        DispatchQueue.global(qos: .utility).async
        {
            send_via_unix_socket(at: "/tmp/\(self.module_name)_tool_controller_socket", with: ["entities_perform", "\(code)"])
            { output in
                // Split the output into lines
                let lines = output.split(separator: "\n").map { String($0) }
                
                self.apply_entities_actions(by: lines, completion: completion)
            }
        }
        
        #else
        completion()
        #endif
    }*/
    
    open override func reset_entities()
    {
        #if os(macOS)
        send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_tool_controller_socket", with: ["reset_entities"])
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

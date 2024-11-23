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
    //MARK: - Device handling
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
                //canceled = true
                completion()
            }
            canceled = false
        }
    }
    
    ///Inforamation code updated by connector.
    public var info_output: [Float]?
    
    //MARK: - Model handling
    ///A tool model controller.
    public var model_controller: ToolModelController?
    
    override open func sync_model()
    {
        //model_controller?.nodes[safe: "Node", default: SCNNode()].runAction(SCNAction())
    }
}

#if os(macOS)
//MARK: - External Connector
public class ExternalToolConnector: ToolConnector
{
    //MARK: Init functions
    ///An external module name
    public var module_name: String
    
    ///For access to code
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL, parameters: [ConnectionParameter])
    {
        self.module_name = module_name
        self.package_url = package_url
        
        self.external_parameters = parameters
    }
    
    ///An array of default connection parameters.
    open var default_parameters: [ConnectionParameter]
    {
        return [ConnectionParameter]()
    }
    
    //MARK: Parameters import
    override open var parameters: [ConnectionParameter]
    {
        return external_parameters
    }
    
    public var external_parameters = [ConnectionParameter]()
    
    //MARK: Connection
    override open func connection_process() async -> Bool
    {
        //Perform connection
        let arguments = ["connect"] + (connection_parameters_values?.map { "\($0)" } ?? [])

        guard let terminal_output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: arguments) else
        {
            if output != String()
            {
                output += "\n"
            }
            
            self.output += "Couldn't perform external code"
            return false
        }
        
        //Get output
        if let range = terminal_output.range(of: "\"([^\"]*)\"", options: .regularExpression)
        {
            if output != String()
            {
                output += "\n"
            }
            
            output += String(terminal_output[range]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        
        //Get connection result
        if terminal_output.contains("<done>")
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
        guard let terminal_output: String = perform_code(at: package_url.appendingPathComponent("/Code/Connector"), with: ["disconnect"])
        else
        {
            self.output += "Couldn't perform external code"
            
            return
        }
    }
    
    //MARK: Performing
    open override func perform(code: Int, completion: @escaping () -> Void)
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["perform", "\(code)"])
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
    
    //MARK: Statistics
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
    
    //MARK: Modeling
    open override func sync_model()
    {
        guard let output: String = perform_code(at: package_url.appendingPathComponent("/Code/Controller"), with: ["sync_model"])
        else
        {
            return
        }
        
        //Split the output into lines
        let lines = output.split(separator: "\n").map { String($0) }
        
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
                model_controller?.nodes[safe: components[0], default: SCNNode()].runAction(action)
            }
        }
    }
}
#endif

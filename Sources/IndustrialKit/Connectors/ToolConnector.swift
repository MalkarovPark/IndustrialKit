//
//  ToolConnector.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation

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
}

//MARK: - External Connector
public class ExternalToolConnector: ToolConnector
{
    //MARK: - Init functions
    //External module name
    public var module_name: String
    
    ///For access to code
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL)
    {
        self.module_name = module_name
        self.package_url = package_url
    }
}

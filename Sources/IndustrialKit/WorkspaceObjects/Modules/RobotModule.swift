//
//  RobotModule.swift
//  IndustrialKit
//
//  Created by Artem on 26.06.2024.
//

import Foundation
import SceneKit

open class RobotModule: IndustrialModule
{
    //MARK: - Init functions
    public override init(name: String = String(), description: String = String(), package_file_name: String = String(), is_internal: Bool = Bool())
    {
        super.init(name: name, description: description, package_file_name: package_file_name, is_internal: is_internal)
        
        code_items = [
            //Controller
            CodeItem(name: "nodes_connect"),
            CodeItem(name: "reset_model"),
            
            CodeItem(name: "updated_charts_data"),
            CodeItem(name: "updated_states_data"),
            CodeItem(name: "reset_charts_data"),
            CodeItem(name: "reset_states_data"),
            
            CodeItem(name: "update_nodes_lengths"),
            CodeItem(name: "update_nodes"),
            CodeItem(name: "inverse_kinematic_calculation"),
            
            //Connector
            /*CodeItem(name: "connection_process"),
            CodeItem(name: "disconnection_process"),
            
            CodeItem(name: "move_to"),
            CodeItem(name: "pause_operations"),
            
            CodeItem(name: "updated_charts_data"),
            CodeItem(name: "updated_states_data"),
            CodeItem(name: "reset_charts_data"),
            CodeItem(name: "reset_states_data"),*/
        ]
    }
    
    //MARK: - Import functions
    override open var node: SCNNode
    {
        return SCNNode()
    }
    
    ///A model controller of the robot model.
    public var model_controller: RobotModelController
    {
        if is_internal
        {
            return RobotModelController()
        }
        else
        {
            return ExternalRobotModelController(name)
        }
    }
    
    ///A connector of the robot model.
    public var connector: RobotConnector
    {
        if is_internal
        {
            return RobotConnector()
        }
        else
        {
            return ExternalRobotConnector(name)
        }
    }
    
    //MARK: - Codable handling
    public required init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}

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
    public init(name: String = String(), description: String = String(), package_file_name: String = String(), is_internal: Bool = Bool(), model_controller: RobotModelController = RobotModelController(), connector: RobotConnector = RobotConnector(), node: SCNNode)
    {
        super.init(name: name, description: description, package_file_name: package_file_name, is_internal: is_internal)
        
        if is_internal
        {
            self.connector = connector
            self.model_controller = model_controller
            self.node = node
        }
        else
        {
            external_import()
        }
        
        code_items = default_code_items
    }
    
    ///Internal init.
    public init(name: String = String(), description: String = String(), model_controller: RobotModelController = RobotModelController(), connector: RobotConnector = RobotConnector(), node: SCNNode)
    {
        super.init(name: name, description: description, is_internal: true)
        
        self.connector = connector
        self.model_controller = model_controller
        self.node = node
        
        //code_items = default_code_items
    }
    
    ///External init.
    public init(name: String = String(), package_file_name: String = String())
    {
        super.init(name: name, package_file_name: package_file_name, is_internal: false)
        
        external_import()
        
        //code_items = default_code_items
    }
    
    private var default_code_items = [
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
    
    //MARK: - Components
    ///A model controller of the robot model.
    public var model_controller = RobotModelController()
    
    ///A connector of the robot model.
    public var connector = RobotConnector()
    
    //MARK: - Import functions
    override open func external_import()
    {
        connector = ExternalRobotConnector(name)
        model_controller = ExternalRobotModelController(name)
        node = external_node
    }
    
    override open var external_node: SCNNode
    {
        return SCNNode()
    }
    
    //MARK: - Codable handling
    public required init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
        
        external_import()
    }
}

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
    public override init(new_name: String = String(), description: String = String())
    {
        super.init(new_name: new_name, description: description)
    }
    
    //MARK: Module init for in-app mounting
    ///Internal init.
    public init(name: String = String(), description: String = String(), model_controller: RobotModelController, connector: RobotConnector, node: SCNNode)
    {
        super.init(name: name, description: description)
        
        self.connector = connector
        self.model_controller = model_controller
        self.node = node
    }
    
    ///External init
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        self.connector = ExternalRobotConnector(name)
        self.model_controller = ExternalRobotModelController(name)
        self.node = external_node
    }
    
    open override var default_code_items: [CodeItem]
    {
        return [
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
    
    //MARK: - Components
    ///A model controller of the robot model.
    public var model_controller = RobotModelController()
    
    ///A connector of the robot model.
    public var connector = RobotConnector()
    
    //MARK: - Import functions
    override open var external_node: SCNNode
    {
        return SCNNode()
    }
    
    //MARK: - Codable handling
    public required init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}

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
    public init(name: String = String(), description: String = String(), model_controller: RobotModelController, connector: RobotConnector, node: SCNNode, nodes_names: [String] = [String]())
    {
        super.init(name: name, description: description)
        
        self.connector = connector
        self.model_controller = model_controller
        self.node = node
        
        self.nodes_names = nodes_names
    }
    
    ///External init
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        /*self.connector = ExternalRobotConnector(name)
        self.model_controller = ExternalRobotModelController(name)
        self.node = external_node*/
        
        components_import()
    }
    
    open override var default_code_items: [CodeItem]
    {
        return [
            CodeItem(name: "Controller"),
            CodeItem(name: "Connector")
        ]
    }
    
    //MARK: - Components
    ///A model controller of the robot model.
    public var model_controller = RobotModelController()
    
    ///A connector of the robot model.
    public var connector = RobotConnector()
    
    /**
     A sequence of nodes names nested within the main node.
        
     > Used by model controller for nested nodes access.
     */
    public var nodes_names = [String]()
    
    //MARK: - Linked components init
    public var linked_model_module_name: String?
    public var linked_connector_module_name: String?
    public var linked_controller_module_name: String?
    
    ///Imports components from external or from other modules.
    private func components_import()
    {
        //Set visual model
        if let linked_name = linked_connector_module_name
        {
            if let index = Robot.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                node = Robot.internal_modules[index].node
            }
        }
        else
        {
            connector = ExternalRobotConnector(name)
        }
        
        //Set contoller
        if let linked_name = linked_controller_module_name
        {
            if let index = Robot.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                model_controller = Robot.internal_modules[index].model_controller
            }
        }
        else
        {
            model_controller = ExternalRobotModelController(name)
        }
        
        //Set connector
        if let linked_name = linked_connector_module_name
        {
            if let index = Robot.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                connector = Robot.internal_modules[index].connector
            }
        }
        else
        {
            node = external_node
        }
    }
    
    //MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case nodes_names
        
        //Linked
        case linked_model_module_name
        case linked_connector_module_name
        case linked_controller_module_name
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.nodes_names = try container.decode([String].self, forKey: .nodes_names)
        
        //Linked
        self.linked_model_module_name = try container.decodeIfPresent(String.self, forKey: .linked_model_module_name)
        self.linked_connector_module_name = try container.decodeIfPresent(String.self, forKey: .linked_connector_module_name)
        self.linked_controller_module_name = try container.decodeIfPresent(String.self, forKey: .linked_controller_module_name)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(nodes_names, forKey: .nodes_names)
        
        //Linked
        try container.encode(linked_model_module_name, forKey: .linked_model_module_name)
        try container.encode(linked_connector_module_name, forKey: .linked_connector_module_name)
        try container.encode(linked_controller_module_name, forKey: .linked_controller_module_name)
        
        try super.encode(to: encoder)
    }
}

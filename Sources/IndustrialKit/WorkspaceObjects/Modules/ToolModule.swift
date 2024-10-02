//
//  ToolModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation
import SceneKit

open class ToolModule: IndustrialModule
{
    //MARK: - Init functions
    public override init(new_name: String = String(), description: String = String())
    {
        super.init(new_name: new_name, description: description)
    }
    
    //MARK: Module init for in-app mounting
    ///Internal init.
    public init(name: String = String(), description: String = String(), model_controller: ToolModelController = ToolModelController(), connector: ToolConnector = ToolConnector(), operation_codes: [OperationCodeInfo] = [OperationCodeInfo](), node: SCNNode)
    {
        super.init(name: name, description: description)
        
        self.connector = connector
        self.model_controller = model_controller
        
        self.node = node
        
        self.codes = operation_codes
    }
    
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        self.connector = ExternalToolConnector(name)
        self.model_controller = ExternalToolModelController(name)
        //codes = operation_codes
        self.node = external_node
    }
    
    //MARK: - Designer functions
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
            
            CodeItem(name: "perform_nodes")
        ]
    }
    
    //MARK: - Components
    ///A model controller of the tool model.
    public var model_controller = ToolModelController()
    
    ///A connector of the tool model.
    public var connector = ToolConnector()
    
    ///Operation codes of the tool model.
    public var codes = [OperationCodeInfo]()
    
    override open var external_node: SCNNode
    {
        return SCNNode()
    }
    
    //MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case operation_codes
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.codes = try container.decode([OperationCodeInfo].self, forKey: .operation_codes)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(codes, forKey: .operation_codes)
        
        try super.encode(to: encoder)
    }
}

//MARK: - File
/*public struct FileHolder: Equatable
{
    public static func == (lhs: FileHolder, rhs: FileHolder) -> Bool
    {
        lhs.name == rhs.name
    }
    
    var name = String()
    var data = (Any).self
}*/

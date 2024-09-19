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
    public init(name: String = String(), description: String = String(), package_file_name: String = String(), is_internal: Bool = Bool(), model_controller: ToolModelController = ToolModelController(), connector: ToolConnector = ToolConnector(), operation_codes: [OperationCodeInfo] = [OperationCodeInfo](), node: SCNNode = SCNNode())
    {
        super.init(name: name, description: description, is_internal: is_internal)
        
        if is_internal
        {
            self.connector = connector
            self.model_controller = model_controller
            self.codes = operation_codes
            self.node = node
        }
        else
        {
            external_import()
            self.codes = operation_codes
        }
        
        code_items = default_code_items
    }
    
    ///Internal init.
    public init(name: String = String(), description: String = String(), model_controller: ToolModelController = ToolModelController(), connector: ToolConnector = ToolConnector(), node: SCNNode)
    {
        super.init(name: name, description: description, is_internal: true)
        
        self.connector = connector
        self.model_controller = model_controller
        self.node = node
        
        //code_items = default_code_items
    }
    
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
    }
    
    private var default_code_items = [
        //Controller
        CodeItem(name: "nodes_connect"),
        CodeItem(name: "reset_model"),
        
        CodeItem(name: "updated_charts_data"),
        CodeItem(name: "updated_states_data"),
        CodeItem(name: "reset_charts_data"),
        CodeItem(name: "reset_states_data"),
        
        CodeItem(name: "perform_nodes")
    ]
    
    //MARK: - Components
    ///A model controller of the tool model.
    public var model_controller = ToolModelController()
    
    ///A connector of the tool model.
    public var connector = ToolConnector()
    
    ///Operation codes of the tool model.
    public var codes = [OperationCodeInfo]()
    
    //MARK: - Import functions
    override open func external_import()
    {
        connector = ExternalToolConnector(name)
        model_controller = ExternalToolModelController(name)
        //codes = operation_codes
        node = external_node
    }
    
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
        
        external_import()
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

//
//  ToolModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation
import SceneKit

public class ToolModule: IndustrialModule
{
    //MARK: - Init functions
    public init(name: String = String(), description: String = String(), package_file_name: String = String(), is_internal_change: Bool = Bool(), operation_codes: [OperationCodeInfo] = [OperationCodeInfo]())
    {
        super.init(name: name, description: description, package_file_name: package_file_name)
        
        self.codes = operation_codes
        
        code_items = [
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
    
    //MARK: - Import functions
    override public var node: SCNNode
    {
        return SCNNode()
    }
    
    ///A model controller of the tool model.
    public var model_controller: ToolModelController
    {
        return ToolModelController()
    }
    
    ///A connector of the tool model.
    public var connector: ToolConnector
    {
        return ToolConnector()
    }
    
    ///Operation codes of the tool model.
    public var codes = [OperationCodeInfo]()
    
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

//
//  ToolModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation

public class ToolModule: IndustrialModule
{
    public var operation_codes = [OperationCodeInfo]()
    
    //MARK: - Init functions
    public init(name: String = String(), description: String = String(), package_file_name: String = String(), is_internal_change: Bool = Bool(), operation_codes: [OperationCodeInfo] = [OperationCodeInfo]())
    {
        super.init(name: name, description: description, package_file_name: package_file_name)
        
        self.operation_codes = operation_codes
        
        code_items = [
            //Controller
            CodeItem(name: "nodes_connect"),
            CodeItem(name: "reset_model"),
            
            CodeItem(name: "updated_charts_data"),
            CodeItem(name: "updated_states_data"),
            CodeItem(name: "reset_charts_data"),
            CodeItem(name: "reset_states_data"),
            
            CodeItem(name: "perform_nodes"),
            
            //Model Statistics
            //
        ]
    }
    
    //MARK: Codable handling
    enum CodingKeys: String, CodingKey
    {
        case operation_codes
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.operation_codes = try container.decode([OperationCodeInfo].self, forKey: .operation_codes)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(operation_codes, forKey: .operation_codes)
        
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

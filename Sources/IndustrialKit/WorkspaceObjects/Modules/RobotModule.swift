//
//  RobotModule.swift
//  IndustrialKit
//
//  Created by Artem on 26.06.2024.
//

import Foundation

public class RobotModule: IndustrialModule
{
    //MARK: - Init functions
    public init(name: String = String(), description: String = String(), package_file_name: String = String(), is_internal_change: Bool = Bool())
    {
        super.init(name: name, description: description, package_file_name: package_file_name)
        code_items = [
            //Model Controller
            CodeItem(name: "nodes_connect"),
            CodeItem(name: "nodes_update"),
            CodeItem(name: "reset_model"),
            
            //Model Statistics
            CodeItem(name: "model_charts_data"),
            CodeItem(name: "model_clear_charts_data"),
            CodeItem(name: "model_states_data"),
            CodeItem(name: "model_clear_states_data"),
            
            //Connector
            CodeItem(name: "connection_process"),
            CodeItem(name: "disconnection_process"),
            
            CodeItem(name: "move_to"),
            CodeItem(name: "pause_operations"),
            
            //Model Statistics
            CodeItem(name: "charts_data"),
            CodeItem(name: "clear_charts_data"),
            CodeItem(name: "states_data"),
            CodeItem(name: "clear_states_data")
        ]
    }
    
    //MARK: Codable handling
    public required init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}

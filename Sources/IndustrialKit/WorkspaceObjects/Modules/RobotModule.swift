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
    
    //MARK: Codable handling
    public required init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}

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
    public init(name: String = String(), description: String = String(), model_controller: ToolModelController = ToolModelController(), connector: ToolConnector = ToolConnector(), operation_codes: [OperationCodeInfo] = [OperationCodeInfo](), node: SCNNode, nodes_names: [String] = [String]())
    {
        super.init(name: name, description: description)
        
        self.connector = connector
        self.model_controller = model_controller
        
        self.node = node
        
        self.codes = operation_codes
        
        self.nodes_names = nodes_names
    }
    
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        /*self.node = external_node
        codes = exterrnal_codes
        self.model_controller = ExternalToolModelController(name)
        self.connector = ExternalToolConnector(name)*/
        
        components_import()
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
    
    /**
     A sequence of nodes names nested within the main node.
        
     > Used by model controller for nested nodes access.
     */
    public var nodes_names = [String]()
    
    //MARK: - Import functions
    open override var package_url: URL
    {
        do
        {
            var is_stale = false
            var local_url = try URL(resolvingBookmarkData: WorkspaceObject.modules_folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                return local_url
            }
            
            local_url = local_url.appendingPathComponent("\(name).tool")
            
            return local_url
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        return URL(filePath: "")
    }
    
    public var external_module_info: ToolModule?
    {
        do
        {
            let info_url = package_url.appendingPathComponent("/Info")
            
            if FileManager.default.fileExists(atPath: info_url.path)
            {
                return try JSONDecoder().decode(ToolModule.self, from: try Data(contentsOf: info_url))
            }
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    override open var external_node: SCNNode
    {
        return SCNNode()
    }
    
    public var external_codes: [OperationCodeInfo]
    {
        return [OperationCodeInfo]()
    }
    
    //MARK: - Linked components init
    public var linked_model_module_name: String?
    public var linked_codes_module_name: String?
    public var linked_connector_module_name: String?
    public var linked_controller_module_name: String?
    
    ///Imports components from external or from other modules.
    private func components_import()
    {
        //Set visual model from internal module
        if let linked_name = linked_connector_module_name
        {
            if let index = Tool.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                node = Tool.internal_modules[index].node
            }
        }
        else
        {
            node = external_node
        }
        
        //Set codes from internal module
        if let linked_name = linked_connector_module_name
        {
            if let index = Tool.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                codes = Tool.internal_modules[index].codes
            }
        }
        else
        {
            codes = external_codes
        }
        
        //Set contoller from internal module
        if let linked_name = linked_controller_module_name
        {
            if let index = Tool.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                model_controller = Tool.internal_modules[index].model_controller
            }
        }
        else
        {
            model_controller = ExternalToolModelController(name, package_url: package_url)
        }
        
        //Set connector from internal module
        if let linked_name = linked_connector_module_name
        {
            if let index = Robot.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                connector = Tool.internal_modules[index].connector
            }
        }
        else
        {
            connector = ExternalToolConnector(name)
        }
    }
    
    //MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case operation_codes
        
        case nodes_names
        
        //Linked
        case linked_model_module_name
        case linked_codes_module_name
        case linked_connector_module_name
        case linked_controller_module_name
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.codes = try container.decode([OperationCodeInfo].self, forKey: .operation_codes)
        
        self.nodes_names = try container.decode([String].self, forKey: .nodes_names)
        
        //Linked
        self.linked_model_module_name = try container.decodeIfPresent(String.self, forKey: .linked_model_module_name)
        self.linked_codes_module_name = try container.decodeIfPresent(String.self, forKey: .linked_codes_module_name)
        self.linked_connector_module_name = try container.decodeIfPresent(String.self, forKey: .linked_connector_module_name)
        self.linked_controller_module_name = try container.decodeIfPresent(String.self, forKey: .linked_controller_module_name)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(codes, forKey: .operation_codes)
        
        try container.encode(nodes_names, forKey: .nodes_names)
        
        //Linked
        try container.encode(linked_model_module_name, forKey: .linked_model_module_name)
        try container.encode(linked_codes_module_name, forKey: .linked_codes_module_name)
        try container.encode(linked_connector_module_name, forKey: .linked_connector_module_name)
        try container.encode(linked_controller_module_name, forKey: .linked_controller_module_name)
        
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

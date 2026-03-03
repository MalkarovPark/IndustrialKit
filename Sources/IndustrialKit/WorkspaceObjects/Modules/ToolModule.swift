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
    // MARK: - Module init functions for design
    public override init(
        new_name: String,
        description: String = String()
    )
    {
        super.init(new_name: new_name, description: description)
    }
    
    // MARK: Module init functions for in-app mounting
    /// Internal init.
    public init(
        name: String = String(),
        description: String = String(),
        
        operation_codes: [OperationCodeInfo] = [OperationCodeInfo](),
        
        model_controller: ToolModelController = ToolModelController(),
        connector: ToolConnector = ToolConnector()
    )
    {
        super.init(name: name, description: description)
        
        self.model_controller = model_controller
        self.codes = operation_codes
        self.connector = connector
    }
    
    /// External init
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        if let info = get_module_info()
        {
            external_module_info = info
            
            components_import()
        }
    }
    
    open override var extension_name: String { "tool" }
    
    // MARK: - Components
    /// A model controller of the tool model.
    public var model_controller = ToolModelController()
    
    /// A connector of the tool model.
    public var connector = ToolConnector()
    
    /// Operation codes of the tool model.
    public var codes = [OperationCodeInfo]()
    
    /**
     A sequence of nodes names nested within the main node.
        
     > Used by model controller for nested nodes access.
     */
    @Published public var entity_names = [String]()
    
    /// USDZ file name for for module build (designer).
    @Published public var entity_file_name: String?
    
    ///
    //@Published public var kinematic_function_code = String() //JS
    
    ///
    @Published public var device_state_code = String() //JS
    
    ///
    @Published public var connector_code = String() //Swift (Internal and External module)
    
    /**
     A sequence of connection parameters.
        
     > Used by connector.
     */
    @Published public var connection_parameters = [ConnectionParameter]()
    
    // MARK: - Import functions
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
    
    private func get_module_info() -> ToolModule?
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
    
    public var external_codes: [OperationCodeInfo]
    {
        return external_module_info?.codes ?? [OperationCodeInfo]()
    }
    
    /// Imports components from external or from other modules.
    private func components_import()
    {
        codes = external_codes
        //#if os(macOS)
        //model_controller = ExternalToolModelController(name.code_correct_format, package_url: package_url, entity_names: external_module_info?.entity_names ?? [String]())
        //#endif
        //#if os(macOS)
        //connector = ExternalToolConnector(name.code_correct_format, package_url: package_url, parameters: external_module_info?.connection_parameters ?? [ConnectionParameter]())
        //#endif
    }
    
    #if os(macOS)
    override open var program_components_paths: [(file: String, socket: String)]
    {
        return [
            (
                file: "/Code/Controller",
                socket: "/tmp/\(name.code_correct_format)_tool_controller_socket"
            ),
            (
                file: "/Code/Connector",
                socket: "/tmp/\(name.code_correct_format)_tool_connector_socket"
            )
        ]
    }
    #endif
    
    // MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case operation_codes
        
        case entity_names
        //case kinematic_function_code
        case entity_file_name
        
        case device_state_code
        
        case connection_parameters
        case connector_code
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.codes = try container.decode([OperationCodeInfo].self, forKey: .operation_codes)
        
        self.entity_names = try container.decode([String].self, forKey: .entity_names)
        //self.kinematic_function_code = try container.decode(String.self, forKey: .kinematic_function_code)
        self.entity_file_name = try container.decodeIfPresent(String.self, forKey: .entity_file_name)
        
        self.connection_parameters = try container.decode([ConnectionParameter].self, forKey: .connection_parameters)
        
        self.device_state_code = try container.decode(String.self, forKey: .device_state_code)
        self.connector_code = try container.decode(String.self, forKey: .connector_code)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(codes, forKey: .operation_codes)
        
        try container.encode(entity_names, forKey: .entity_names)
        //try container.encode(kinematic_function_code, forKey: .kinematic_function_code)
        try container.encode(entity_file_name, forKey: .entity_file_name)
        
        try container.encode(device_state_code, forKey: .device_state_code)
        
        try container.encode(connection_parameters, forKey: .connection_parameters)
        try container.encode(connector_code, forKey: .connector_code)
        
        try super.encode(to: encoder)
    }
}

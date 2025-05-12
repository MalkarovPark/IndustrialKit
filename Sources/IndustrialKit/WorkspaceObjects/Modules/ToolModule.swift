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
    // MARK: - Init functions
    public override init(new_name: String = String(), description: String = String())
    {
        super.init(new_name: new_name, description: description)
    }
    
    // MARK: Module init for in-app mounting
    /// Internal init.
    public init(
        name: String = String(),
        description: String = String(),
        
        node: SCNNode,
        
        operation_codes: [OperationCodeInfo] = [OperationCodeInfo](),
        
        model_controller: ToolModelController = ToolModelController(),
        connector: ToolConnector = ToolConnector()
    )
    {
        super.init(name: name, description: description)
        
        self.codes = operation_codes
        
        self.node = node
        self.model_controller = model_controller
        
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
    
    // MARK: - Designer functions
    open override var default_code_items: [String: String]
    {
        return ["Controller": String(), "Connector": String()]
    }
    
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
    @Published public var nodes_names = [String]()
    
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
    
    override open var external_node: SCNNode
    {
        if let main_scene_name = external_module_info?.main_scene_name
        {
            do
            {
                let scene_url = package_url.appendingPathComponent("/Resources.scnassets/\(main_scene_name)")
                
                if FileManager.default.fileExists(atPath: scene_url.path)
                {
                    let scene_data = try Data(contentsOf: scene_url)
                    
                    if let scene_source = SCNSceneSource(data: scene_data, options: nil)
                    {
                        if let external_scene = scene_source.scene(options: nil)
                        {
                            return external_scene.rootNode.clone()
                        }
                    }
                }
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        
        return SCNNode()
    }
    
    public var external_codes: [OperationCodeInfo]
    {
        return external_module_info?.codes ?? [OperationCodeInfo]()
    }
    
    // MARK: - Linked components init
    open override var default_linked_components: [String: String]
    {
        return [
            "Model": String(),
            "Codes": String(),
            "Controller": String(),
            "Connector": String()
        ]
    }
    
    /// Imports components from external or from other modules.
    private func components_import()
    {
        // Set visual model
        if let linked_name = linked_components["Model"]
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
        
        // Set codes from internal module
        if let linked_name = linked_components["Codes"]
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
        
        // Set contoller from internal module
        if let linked_name = linked_components["Controller"]
        {
            if let index = Tool.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                model_controller = Tool.internal_modules[index].model_controller
            }
        }
        else
        {
            #if os(macOS)
            model_controller = ExternalToolModelController(name.code_correct_format, package_url: package_url, nodes_names: external_module_info?.nodes_names ?? [String]())
            #endif
        }
        
        // Set connector from internal module
        if let linked_name = linked_components["Connector"]
        {
            if let index = Tool.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                connector = Tool.internal_modules[index].connector
            }
        }
        else
        {
            #if os(macOS)
            connector = ExternalToolConnector(name.code_correct_format, package_url: package_url, parameters: external_module_info?.connection_parameters ?? [ConnectionParameter]())
            #endif
        }
    }
    
    #if os(macOS)
    override open func start_program_components()
    {
        perform_terminal_app_sync(at: self.package_url.appendingPathComponent("/Code/Controller"), with: [" > /dev/null 2>&1 &"])
        perform_terminal_app_sync(at: self.package_url.appendingPathComponent("/Code/Connector"), with: [" > /dev/null 2>&1 &"])
    }
    
    override open func stop_program_components()
    {
        send_via_unix_socket(at: "/tmp/\(name.code_correct_format)_tool_controller_socket", command: "stop")
        send_via_unix_socket(at: "/tmp/\(name.code_correct_format)_tool_connector_socket", command: "stop")
    }
    #endif
    
    // MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case operation_codes
        
        case nodes_names
        case connection_parameters
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.codes = try container.decode([OperationCodeInfo].self, forKey: .operation_codes)
        
        self.nodes_names = try container.decode([String].self, forKey: .nodes_names)
        self.connection_parameters = try container.decode([ConnectionParameter].self, forKey: .connection_parameters)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(codes, forKey: .operation_codes)
        
        try container.encode(nodes_names, forKey: .nodes_names)
        try container.encode(connection_parameters, forKey: .connection_parameters)
        
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

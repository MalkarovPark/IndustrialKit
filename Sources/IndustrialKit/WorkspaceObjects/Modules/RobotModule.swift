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
        
        model_controller: RobotModelController,        
        connector: RobotConnector
    )
    {
        super.init(name: name, description: description)
        
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
    
    open override var default_code_items: [String: String]
    {
        return ["Controller": String(), "Connector": String()]
    }
    
    open override var extension_name: String { "robot" }
    
    // MARK: - Components
    /// A model controller of the robot model.
    public var model_controller = RobotModelController()
    
    /// A connector of the robot model.
    public var connector = RobotConnector()
    
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
            
            local_url = local_url.appendingPathComponent("\(name).robot")
            
            return local_url
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        return URL(filePath: "")
    }
    
    public var external_module_info: RobotModule?
    
    private func get_module_info() -> RobotModule?
    {
        do
        {
            let info_url = package_url.appendingPathComponent("/Info")
            
            if FileManager.default.fileExists(atPath: info_url.path)
            {
                return try JSONDecoder().decode(RobotModule.self, from: try Data(contentsOf: info_url))
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
    
    // MARK: - Linked components init
    open override var default_linked_components: [String: String]
    {
        return [
            "Model": String(),
            "Controller": String(),
            "Connector": String()
        ]
    }
    
    /// Imports components from external or from other modules.
    private func components_import()
    {
        // Set visual model from internal module
        if let linked_name = linked_components["Model"]
        {
            if let index = Robot.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                node = Robot.internal_modules[index].node
            }
        }
        else
        {
            node = external_node
        }
        
        // Set contoller
        if let linked_name = linked_components["Controller"], linked_name.isEmpty
        {
            if let index = Robot.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                model_controller = Robot.internal_modules[index].model_controller
            }
        }
        else
        {
            #if os(macOS)
            model_controller = ExternalRobotModelController(name, package_url: package_url, nodes_names: external_module_info?.nodes_names ?? [String]())
            #endif
        }
        
        // Set connector
        if let linked_name = linked_components["Connector"], linked_name.isEmpty
        {
            if let index = Robot.internal_modules.firstIndex(where: { $0.name == linked_name })
            {
                connector = Robot.internal_modules[index].connector
            }
        }
        else
        {
            #if os(macOS)
            connector = ExternalRobotConnector(name, package_url: package_url, parameters: external_module_info?.connection_parameters ?? [ConnectionParameter]())
            #endif
        }
    }
    
    #if os(macOS)
    private var controller_program_component_stopped: Bool = true
    private var connector_program_component_stopped: Bool = true
    
    override open func start_program_components()
    {
        //perform_terminal_app(at: self.package_url.appendingPathComponent("/Code/Controller"), with: ["&"])
        //perform_terminal_app(at: self.package_url.appendingPathComponent("/Code/Connector"), with: ["&"])
        
        /*DispatchQueue.global(qos: .background).async { perform_terminal_app(at: self.package_url.appendingPathComponent("/Code/Controller")) }
        DispatchQueue.global(qos: .background).async { perform_terminal_app(at: self.package_url.appendingPathComponent("/Code/Connector")) }*/
        
        DispatchQueue.global(qos: .background).async
        {
            if self.controller_program_component_stopped
            {
                self.controller_program_component_stopped = false
                perform_terminal_app(at: self.package_url.appendingPathComponent("/Code/Controller"), with: ["&"])
                //self.controller_program_component_stopped = true
            }
        }
        
        DispatchQueue.global(qos: .background).async
        {
            if self.connector_program_component_stopped
            {
                self.connector_program_component_stopped = false
                perform_terminal_app(at: self.package_url.appendingPathComponent("/Code/Connector"), with: ["&"])
                //self.connector_program_component_stopped = true
            }
        }
    }
    
    override open func stop_program_components()
    {
        send_via_unix_socket(socket_path: "/tmp/\(name)_robot_controller_socket", command: "stop")
        send_via_unix_socket(socket_path: "/tmp/\(name)_robot_connector_socket", command: "stop")
    }
    #endif
    
    // MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case nodes_names
        case connection_parameters
        
        // Linked
        case linked_model_module_name
        case linked_connector_module_name
        case linked_controller_module_name
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.nodes_names = try container.decode([String].self, forKey: .nodes_names)
        self.connection_parameters = try container.decode([ConnectionParameter].self, forKey: .connection_parameters)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(nodes_names, forKey: .nodes_names)
        try container.encode(connection_parameters, forKey: .connection_parameters)
        
        try super.encode(to: encoder)
    }
}

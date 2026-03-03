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
        
        origin_shift: (x: Float, y: Float, z: Float) = (0, 0, 0),
        default_origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (0, 0, 0, 0, 0, 0),
        
        end_entity_name: String = String(),
        
        model_controller: RobotModelController = RobotModelController(),
        connector: RobotConnector = RobotConnector()
    )
    {
        super.init(name: name, description: description)
        
        self.model_controller = model_controller
        
        self.origin_shift = origin_shift
        self.default_origin_position = default_origin_position
        
        self.end_entity_name = end_entity_name
        
        self.connector = connector
    }
    
    /// External init
    public override init(
        external_name: String
    )
    {
        super.init(external_name: external_name)
        
        if let info = get_module_info()
        {
            external_module_info = info
            
            components_import()
        }
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
    @Published public var entity_names = [String]()
    
    /**
     A sequence of connection parameters.
        
     > Used by connector.
     */
    @Published public var connection_parameters = [ConnectionParameter]()
    
    /// A robot cell box default shift.
    @Published public var origin_shift: (x: Float, y: Float, z: Float) = (x: 0, y: 0, z: 0)
    
    /// A robot cell box default position.
    @Published public var default_origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (0, 0, 0, 0, 0, 0)
    
    /// A robot model entity name for end-effector mounting.
    @Published public var end_entity_name: String = String()
    
    /// USDZ file name for for module build (designer).
    @Published public var entity_file_name: String?
    
    ///
    @Published public var kinematic_function_code = String() //JS
    
    ///
    @Published public var device_state_code = String() //JS
    
    ///
    @Published public var connector_code = String() //Swift (Internal and External module)
    
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
    
    public var external_origin_shift: (x: Float, y: Float, z: Float)
    {
        return external_module_info?.origin_shift ?? (x: 0, y: 0, z: 0)
    }
    
    /// Imports components from external or from other modules.
    private func components_import()
    {
        origin_shift = external_origin_shift
        //#if os(macOS)
        //model_controller = ExternalRobotModelController(name.code_correct_format, package_url: package_url, entity_names: external_module_info?.entity_names ?? [String]())
        //#endif
        //#if os(macOS)
        //connector = ExternalRobotConnector(name.code_correct_format, package_url: package_url, parameters: external_module_info?.connection_parameters ?? [ConnectionParameter]())
        //#endif
    }
    
    #if os(macOS)
    override open var program_components_paths: [(file: String, socket: String)]
    {
        return [
            (
                file: "/Code/Controller",
                socket: "/tmp/\(name.code_correct_format)_robot_controller_socket"
            ),
            (
                file: "/Code/Connector",
                socket: "/tmp/\(name.code_correct_format)_robot_connector_socket"
            )
        ]
    }
    #endif
    
    // MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case entity_names
        case origin_shift
        case default_origin_position
        case end_entity_name
        case kinematic_function_code
        case entity_file_name
        
        case device_state_code
        
        case connection_parameters
        case connector_code
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.entity_names = try container.decode([String].self, forKey: .entity_names)
        if let origin_shift = try container.decodeIfPresent([Float].self, forKey: .origin_shift)
        {
            self.origin_shift = (origin_shift[0], origin_shift[1], origin_shift[2])
        }
        if let default_origin_position = try container.decodeIfPresent([Float].self, forKey: .default_origin_position)
        {
            self.default_origin_position = (default_origin_position[0], default_origin_position[1], default_origin_position[2], default_origin_position[3], default_origin_position[4], default_origin_position[5])
        }
        self.end_entity_name = try container.decode(String.self, forKey: .end_entity_name)
        self.kinematic_function_code = try container.decode(String.self, forKey: .kinematic_function_code)
        self.entity_file_name = try container.decodeIfPresent(String.self, forKey: .entity_file_name)
        
        self.connection_parameters = try container.decode([ConnectionParameter].self, forKey: .connection_parameters)
        
        self.device_state_code = try container.decode(String.self, forKey: .device_state_code)
        self.connector_code = try container.decode(String.self, forKey: .connector_code)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(entity_names, forKey: .entity_names)
        try container.encode([origin_shift.x, origin_shift.y, origin_shift.z], forKey: .origin_shift)
        try container.encode([default_origin_position.x, default_origin_position.y, default_origin_position.z, default_origin_position.r, default_origin_position.p, default_origin_position.w], forKey: .default_origin_position)
        try container.encode(end_entity_name, forKey: .end_entity_name)
        try container.encode(kinematic_function_code, forKey: .kinematic_function_code)
        try container.encode(entity_file_name, forKey: .entity_file_name)
        
        try container.encode(device_state_code, forKey: .device_state_code)
        
        try container.encode(connection_parameters, forKey: .connection_parameters)
        try container.encode(connector_code, forKey: .connector_code)
        
        try super.encode(to: encoder)
    }
}

//
//  RobotModule.swift
//  IndustrialKit
//
//  Created by Artem on 26.06.2024.
//

import Foundation

/// A module that defines structure, behavior, and integration of an industrial robot.
///
/// `RobotModule` extends ``IndustrialModule`` by providing robot-specific
/// configuration, including kinematic structure, control logic,
/// and device connectivity.
///
/// The module encapsulates:
/// - A robot model controller for simulation and kinematics
/// - A connector for real device communication
/// - Spatial configuration (origin position and shift)
/// - Entity structure and end-effector definition
/// - Program components and external execution logic
///
/// Robot modules can be defined internally or imported from external packages,
/// enabling reusable and extensible robot configurations.
///
/// Subclass `RobotModule` to implement specialized robotic systems.
/// 
open class RobotModule: IndustrialModule
{
    // MARK: - Initializators
    // MARK: Module init functions for design
    /// Creates a robot module for design-time configuration.
    ///
    /// - Parameters:
    ///   - new_name: A module identifier.
    ///   - description: A textual description of the module.
    public override init(
        new_name: String,
        description: String = String()
    )
    {
        super.init(new_name: new_name, description: description)
    }
    
    // MARK: Module init functions for in-app mounting
    /// Creates a robot module for internal runtime usage.
    ///
    /// This initializer configures all core components of the robot,
    /// including spatial parameters, model controller, and connector.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - description: A textual description.
    ///   - default_origin_position: A default robot origin pose (position and orientation).
    ///   - origin_shift: A positional offset applied to the origin.
    ///   - end_entity_name: A name of the end-effector entity.
    ///   - model_controller: A controller responsible for robot model behavior.
    ///   - connector: A connector responsible for device communication.
    public init(
        name: String = String(),
        description: String = String(),
        
        default_origin_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        ) = (0, 0, 0, 0, 0, 0),
        
        origin_shift: (x: Float, y: Float, z: Float) = (0, 0, 0),
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
    
    /// Creates a robot module from an external package.
    ///
    /// The initializer attempts to load module metadata from an external
    /// information file and imports all available components.
    ///
    /// - Parameter external_name: A module identifier.
    public override init(
        external_name: String
    )
    {
        super.init(external_name: external_name)
        
        if let module_info = get_external_module_info()
        {
            external_module_info = module_info // Reserved
            
            components_import(from: module_info)
        }
    }
    
    /// A file extension representing the robot module package format.
    open override var file_extension_name: String { "robot" }
    
    // MARK: - Components
    /// A controller responsible for robot model behavior and kinematics.
    ///
    /// The controller manages entity hierarchy, joint transformations,
    /// and simulation performing.
    public var model_controller = RobotModelController()
    
    /// A connector responsible for communication with a real robot device.
    ///
    /// The connector manages connection lifecycle, parameter configuration,
    /// and synchronization between virtual and physical robot.
    public var connector = RobotConnector()
    
    /// A collection of entity node names within the robot model.
    ///
    /// Used by the model controller to access and manipulate nested nodes
    /// in the entity hierarchy.
    @Published public var entity_names = [String]()
    
    /// A collection of connection parameters used by the connector.
    ///
    /// Defines configuration required for establishing communication
    /// with a physical device.
    @Published public var connection_parameters = [ConnectionParameter]()
    
    /// A positional offset applied to the robot origin.
    ///
    /// Defines translation of the robot base within the workspace.
    @Published public var origin_shift: (x: Float, y: Float, z: Float) = (x: 0, y: 0, z: 0)
    
    /// A default robot origin pose.
    ///
    /// Contains position (x, y, z) and orientation (r, p, w)
    /// used as an initial configuration in the workspace.
    @Published public var default_origin_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (0, 0, 0, 0, 0, 0)
    
    /// A name of the entity used for end-effector mounting.
    ///
    /// Defines the attachment point for tools or external components.
    @Published public var end_entity_name: String = String()
    
    /// A file name of the USDZ entity used during module design.
    ///
    /// This value is used by the module builder for resource packaging.
    @Published public var entity_file_name: String?
    
    /// A source code string defining model controller logic.
    ///
    /// Typically contains JavaScript code used for dynamic model behavior.
    @Published public var model_controller_code = String() //JS
    
    /// A source code string defining connector logic.
    ///
    /// Contains Swift code used for internal or external module integration.
    @Published public var connector_code = String() //Swift (Internal and External module)
    
    // MARK: - Import Functions
    open override var package_url: URL
    {
        do
        {
            var is_stale = false
            var local_url = try URL(resolvingBookmarkData: ProductionObject.modules_folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                return local_url
            }
            
            local_url = local_url.appendingPathComponent("\(name).robot")
            
            return local_url
        }
        catch
        {
            //print(error.localizedDescription)
        }
        
        return URL(filePath: "")
    }
    
    /// A reference to imported external module information.
    ///
    /// Stores decoded metadata for reuse and inspection.
    public var external_module_info: RobotModule?
    
    /// Loads external module metadata from the package.
    ///
    /// - Returns: A decoded `RobotModule` instance or `nil` if unavailable.
    private func get_external_module_info() -> RobotModule?
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
            //print(error.localizedDescription)
        }
        
        return nil
    }
    
    /// Imports components from external module metadata.
    ///
    /// The method applies spatial configuration, entity structure,
    /// and initializes model controller using external code definitions.
    ///
    /// - Parameter module_info: A module containing external configuration.
    private func components_import(from module_info: RobotModule)
    {
        default_origin_position = module_info.default_origin_position
        
        origin_shift = module_info.origin_shift
        end_entity_name = module_info.end_entity_name
        
        model_controller = ExternalRobotModelController(
            entity_names: module_info.entity_names,
            code: module_info.model_controller_code
        )
        
        //#if os(macOS)
        //connector = ExternalRobotConnector(name.code_correct_format, package_url: package_url, parameters: external_module_info?.connection_parameters ?? [ConnectionParameter]())
        //#endif
    }
    
    #if os(macOS)
    override open var program_component_paths: [(file: String, socket: String)]
    {
        return [
            (
                file: "/Connector",
                socket: "/tmp/\(name.code_correct_format)_robot_connector_socket"
            )
        ]
    }
    #endif
    
    // MARK: - File Data
    enum CodingKeys: String, CodingKey
    {
        case default_origin_position
        
        case entity_file_name
        case entity_names
        case end_entity_name
        case origin_shift
        case model_controller_code
        
        case connection_parameters
        case connector_code
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.entity_file_name = try container.decodeIfPresent(String.self, forKey: .entity_file_name)
        self.entity_names = try container.decode([String].self, forKey: .entity_names)
        self.end_entity_name = try container.decode(String.self, forKey: .end_entity_name)
        if let origin_shift = try container.decodeIfPresent([Float].self, forKey: .origin_shift)
        {
            self.origin_shift = (origin_shift[0], origin_shift[1], origin_shift[2])
        }
        if let default_origin_position = try container.decodeIfPresent([Float].self, forKey: .default_origin_position)
        {
            self.default_origin_position = (default_origin_position[0], default_origin_position[1], default_origin_position[2], default_origin_position[3], default_origin_position[4], default_origin_position[5])
        }
        self.model_controller_code = try container.decode(String.self, forKey: .model_controller_code)
        
        self.connection_parameters = try container.decode([ConnectionParameter].self, forKey: .connection_parameters)
        self.connector_code = try container.decode(String.self, forKey: .connector_code)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(entity_file_name, forKey: .entity_file_name)
        try container.encode(entity_names, forKey: .entity_names)
        try container.encode(end_entity_name, forKey: .end_entity_name)
        try container.encode([origin_shift.x, origin_shift.y, origin_shift.z], forKey: .origin_shift)
        try container.encode([default_origin_position.x, default_origin_position.y, default_origin_position.z, default_origin_position.r, default_origin_position.p, default_origin_position.w], forKey: .default_origin_position)
        try container.encode(model_controller_code, forKey: .model_controller_code)
        
        try container.encode(connection_parameters, forKey: .connection_parameters)
        try container.encode(connector_code, forKey: .connector_code)
        
        try super.encode(to: encoder)
    }
}

//
//  ToolModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation

/// A module that defines structure and behavior of an industrial tool.
///
/// `ToolModule` extends ``IndustrialModule`` by providing configuration
/// for devices that perform discrete operations using operation codes.
///
/// The module encapsulates:
/// - A tool model controller for simulation and visualization
/// - A connector for real device communication
/// - A set of supported operation codes
/// - Entity structure and resource definitions
/// - External execution components
///
/// Tool modules can be defined internally or loaded from external packages,
/// enabling flexible integration of specialized equipment.
///
/// Subclass `ToolModule` to implement custom tool behavior.
open class ToolModule: IndustrialModule
{
    // MARK: - Initializers
    // MARK: Module init functions for design
    /// Creates a tool module for design-time configuration.
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
    /// Creates a tool module for internal runtime usage.
    ///
    /// This initializer configures operation codes, model controller,
    /// and connector for the tool.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - description: A textual description.
    ///   - operation_codes: A list of supported operation codes.
    ///   - model_controller: A controller responsible for tool model behavior.
    ///   - connector: A connector responsible for device communication.
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
    
    /// Creates a tool module from an external package.
    ///
    /// The initializer attempts to load module metadata from an external
    /// information file and imports its components.
    ///
    /// - Parameter external_name: A module identifier.
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        if let module_info = get_external_module_info()
        {
            external_module_info = module_info // Reserved
            
            components_import(from: module_info)
        }
    }
    
    /// A file extension representing the tool module package format.
    open override var file_extension_name: String { "tool" }
    
    // MARK: - Components
    /// A controller responsible for tool model behavior and visualization.
    ///
    /// The controller manages entity hierarchy and performing logic
    /// of the tool within a simulated environment.
    public var model_controller = ToolModelController()
    
    /// A connector responsible for communication with a real tool device.
    ///
    /// The connector handles connection lifecycle, parameter configuration,
    /// and synchronization with the physical device.
    public var connector = ToolConnector()
    
    /// A collection of operation codes supported by the tool.
    ///
    /// Each code defines a discrete operation that can be performed
    /// by the device.
    public var codes = [OperationCodeInfo]()
    
    /// A collection of entity node names within the tool model.
    ///
    /// Used by the model controller to access nested nodes
    /// in the entity hierarchy.
    @Published public var entity_names = [String]()
    
    /// A file name of the USDZ entity used during module design.
    ///
    /// Used by the module builder for packaging visual resources.
    @Published public var entity_file_name: String?
    
    /// A source code string defining model controller logic.
    ///
    /// Typically contains JavaScript code for dynamic tool behavior.
    @Published public var model_controller_code = String() //JS
    
    /// A source code string defining connector logic.
    ///
    /// Contains Swift code used for internal or external module integration.
    @Published public var connector_code = String() //Swift (Internal and External module)
    
    /// A collection of connection parameters used by the connector.
    ///
    /// Defines configuration required for establishing communication
    /// with the device.
    @Published public var connection_parameters = [ConnectionParameter]()
    
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
            
            local_url = local_url.appendingPathComponent("\(name).tool")
            
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
    public var external_module_info: ToolModule?
    
    private func get_external_module_info() -> ToolModule?
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
            //print(error.localizedDescription)
        }
        
        return nil
    }
    
    /// Imports components from external or from other modules.
    private func components_import(from module_info: ToolModule)
    {
        codes = module_info.codes
        model_controller = ExternalToolModelController(
            entity_names: module_info.entity_names,
            code: module_info.model_controller_code
        )
        
        #if os(macOS)
        connector = ExternalToolConnector(
            name.code_correct_format,
            package_url: package_url,
            
            parameters: external_module_info?.connection_parameters ?? [ConnectionParameter]()
        )
        #endif
    }
    
    #if os(macOS)
    /// A list of executable program components associated with the tool module.
    ///
    /// Defines runtime processes such as connector services
    /// and communication endpoints.
    override open var program_component_paths: [(file: String, socket: String)]
    {
        return [
            (
                file: "/Connector",
                socket: "/tmp/\(name.code_correct_format)_tool_connector_socket"
            )
        ]
    }
    #endif
    
    // MARK: - File Data
    enum CodingKeys: String, CodingKey
    {
        case operation_codes
        
        case entity_file_name
        case entity_names
        case model_controller_code
        
        case connection_parameters
        case connector_code
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.codes = try container.decode([OperationCodeInfo].self, forKey: .operation_codes)
        
        self.entity_file_name = try container.decodeIfPresent(String.self, forKey: .entity_file_name)
        self.entity_names = try container.decode([String].self, forKey: .entity_names)
        self.model_controller_code = try container.decode(String.self, forKey: .model_controller_code)
        
        self.connection_parameters = try container.decode([ConnectionParameter].self, forKey: .connection_parameters)
        self.connector_code = try container.decode(String.self, forKey: .connector_code)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(codes, forKey: .operation_codes)
        
        try container.encode(entity_file_name, forKey: .entity_file_name)
        try container.encode(entity_names, forKey: .entity_names)
        try container.encode(model_controller_code, forKey: .model_controller_code)
        
        try container.encode(connection_parameters, forKey: .connection_parameters)
        try container.encode(connector_code, forKey: .connector_code)
        
        try super.encode(to: encoder)
    }
}

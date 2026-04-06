//
//  ProductionObject.swift
//  IndustrialKit
//
//  Created by Artem on 29.10.2022.
//

import Foundation
import SwiftUI
#if canImport(RealityKit)
import RealityKit
#endif

/// A base class that represents a production object in a robotic workspace.
///
/// Use ``ProductionObject`` as a common abstraction for elements that form
/// the content of a robotic system, including equipment, tools, and parts.
///
/// A workspace object models a production entity by encapsulating:
/// - A unique identifier and name
/// - Spatial configuration within a coordinate system
/// - Physical properties of the object
/// - A visual representation as a RealityKit ``Entity``
///
/// This class serves as the foundation for all production elements.
/// The system provides built-in subclasses such as ``Robot``, ``Tool``,
/// and ``Part``.
///
/// You can subclass ``ProductionObject`` to define custom types of
/// production resources and extend system functionality.
/// 
@MainActor open class ProductionObject: ObservableObject, @preconcurrency Identifiable, @preconcurrency Equatable, @preconcurrency Hashable
{
    public static func == (lhs: ProductionObject, rhs: ProductionObject) -> Bool // Identity condition by names & types
    {
        return lhs.name == rhs.name && type(of: lhs) == type(of: rhs)
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    public var id = UUID()
    
    /// The name of the object in the workspace.
    ///
    /// The name identifies the object within a production configuration.
    /// Updating this value also updates the associated entity metadata.
    @Published public var name = String()
    {
        didSet
        {
            update_entity_model_identifier()
        }
    }
    
    /// The name of the module associated with the object.
    ///
    /// The module defines the control logic, scene description, and connectivity
    /// of the object.
    public var module_name = ""
    
    /// A Boolean value that indicates whether the module is internal.
    ///
    /// Internal modules are provided as part of the system,
    /// while external modules are loaded from external sources.
    public var is_internal_module = true
    
    /// Creates a new workspace object.
    public init()
    {
        
    }
    
    // MARK: - Initializers
    /// Creates a workspace object with the specified name.
    ///
    /// - Parameter name: The name of the object.
    public init(name: String)
    {
        self.name = name
    }
    
    /// Creates a workspace object and loads an entity resource.
    ///
    /// - Parameters:
    ///   - name: The name of the object.
    ///   - entity_name: The name of the entity resource.
    public init(
        name: String,
        entity_name: String
    )
    {
        self.name = name
        perform_load_entity(named: entity_name)
    }
    
    /// Creates a workspace object with a specified entity.
    ///
    /// - Parameters:
    ///   - name: The name of the object.
    ///   - entity: The entity that represents the object.
    public convenience init(
        name: String,
        entity: Entity
    )
    {
        self.init(name: name)
        self.model_entity = entity
        
        import_entity(model_entity)
    }
    
    /// Creates a workspace object and imports a module.
    ///
    /// - Parameters:
    ///   - name: The name of the object.
    ///   - module_name: The name of the module.
    ///   - is_internal: A Boolean value indicating whether the module is internal.
    public init(
        name: String,
        module_name: String,
        is_internal: Bool = true
    )
    {
        self.name = name
        self.is_internal_module = is_internal
        
        import_module(module_name, is_internal: is_internal)
    }
    
    // MARK: - Module handling
    /// A security-scoped bookmark for accessing the modules directory.
    ///
    /// Use this property to persist access to the folder that contains
    /// external modules across application launches.
    nonisolated(unsafe) public static var modules_folder_bookmark: Data?
    
    /// Imports a module that defines the object's functionality.
    ///
    /// Override this method to implement module loading and initialization.
    ///
    /// - Parameters:
    ///   - name: The module name.
    ///   - is_internal: Indicates whether the module is internal.
    open func import_module(_ name: String, is_internal: Bool = true) {}
    
    /// A Boolean value that indicates whether a compatible module is available.
    ///
    /// Override to provide module availability logic.
    open var has_avaliable_module: Bool { false }
    
    // MARK: - Object in workspace handling
    /// A Boolean value that indicates whether the object is placed in the workspace.
    ///
    /// When set to `true`, the associated entity becomes active in the scene.
    @Published public var is_placed = true
    {
        didSet
        {
            entity.isEnabled = is_placed
        }
    }
    
    /// Performs additional operations when removing the object from the workspace.
    ///
    /// Override to release resources or perform cleanup.
    open func on_remove() {}
    
    /// The spatial configuration of the object.
    ///
    /// The value represents the object's pose, including position (*x*, *y*, *z*)
    /// and orientation (*r*, *p*, *w*), in the workspace coordinate system.
    @Published public var position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            update_entity_position()
        }
    }
    
    // MARK: - Reality Functions
    #if canImport(RealityKit)
    /// The root entity that represents the object in a scene.
    public var entity = Entity()
    
    /// The entity used for visualization and simulation.
    public var model_entity: Entity?
    
    /// An entity loading state.
    //@Published public var entity_loaded = false
    
    /// Asynchronously loads an entity resource by name.
    ///
    /// The method attempts to load a model entity and, upon success,
    /// integrates it into the object using ``import_entity(_:)``.
    ///
    /// - Parameter name: The name of the entity resource.
    private func perform_load_entity(named name: String)
    {
        Task
        {
            do
            {
                let model_entity = try await Entity(named: name)
                
                //print("🥂 Loaded! (\(name))")
                
                import_entity(model_entity)
            }
            catch
            {
                //entity_loaded = false
                
                //print(error.localizedDescription)
            }
        }
    }
    
    /// Imports and configures a model entity.
    ///
    /// The method prepares the entity for interaction and simulation,
    /// and attaches it to the object's root entity.
    ///
    /// - Parameter model_entity: The entity to import.
    public func import_entity(_ model_entity: Entity?)
    {
        guard let model_entity = model_entity else { return }
        
        model_entity.generateCollisionShapes(recursive: true)
        model_entity.visit
        { entity in
            entity.components.set(entity_tag)
        }
        
        model_entity.components.set(InputTargetComponent())
        
        self.model_entity = model_entity
        self.entity.addChild(model_entity)
        
        //entity_loaded = true
        extend_entity_preparation(entity)
    }
    
    /// An identifier component assigned to entities of the object.
    ///
    /// Override to provide a custom identifier.
    open var entity_tag: ObjectEntityIdentifier
    {
        return ObjectEntityIdentifier(type: .none, name: name)
    }
    
    /// Updates the identifier associated with the entity hierarchy.
    public func update_entity_model_identifier()
    {
        guard let model_entity = model_entity else { return }
        
        model_entity.visit
        { entity in
            entity.components.remove(ObjectEntityIdentifier.self)
            entity.components.set(entity_tag)
        }
    }
    
    /// Extends the entity preparation process.
    ///
    /// Override to apply additional configuration after importing the entity.
    ///
    /// - Parameter entity: The entity to configure.
    open func extend_entity_preparation(_ entity: Entity) {}
    
    #if os(macOS) || os(iOS)
    /// Places the entity into the specified RealityKit scene content.
    ///
    /// This method ensures that the underlying model entity is available
    /// before performing placement. If the entity is not yet initialized,
    /// the method waits asynchronously until it becomes available.
    ///
    /// Optionally, the method can also apply the entity's spatial configuration
    /// after placement, including position updates.
    ///
    /// The placement process consists of two independent asynchronous steps:
    /// 1. Waiting for the model entity to become available.
    /// 2. Adding the entity to the scene content.
    /// 3. Optionally applying spatial positioning.
    ///
    /// - Parameters:
    ///   - content: The scene content container in which the entity will be placed.
    ///   - applying_position: A Boolean value that determines whether the entity's
    ///     spatial position should be applied after placement. Default is `false`.
    ///
    /// - Important: Position updates are executed asynchronously and may occur
    ///   after the entity has already been added to the scene.
    ///
    public func place_entity(
        in content: RealityViewCameraContent,
        applying_position: Bool = false
    )
    {
        Task
        {
            // Wait until bot.entity becomes available, then place it once
            while model_entity == nil
            {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            
            content.add(entity)
            
            extend_entity_placement(entity)
        }
        
        if applying_position
        {
            Task
            {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                
                update_entity_position() //entity.update_position(position)
            }
        }
    }
    #else
    public func place_entity(
        in content: RealityViewContent,
        applying_position: Bool = false
    )
    {
        Task
        {
            // Wait until bot.entity becomes available, then place it once
            while model_entity == nil
            {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            
            content.add(entity)
            
            extend_entity_placement(entity)
        }
        
        if applying_position
        {
            Task
            {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                
                update_entity_position() //entity.update_position(position)
            }
        }
    }
    #endif
    
    /// Updates the entity transform according to the current spatial configuration.
    public func update_entity_position()
    {
        entity.update_position(position)
    }
    
    /// Extends the placement process of the entity.
    ///
    /// Override to connect additional systems after placement.
    ///
    /// - Parameter entity: The placed entity.
    open func extend_entity_placement(_ entity: Entity)
    {
        //reality_controller.connect_entities(of: entity)
    }
    #endif
    
    // MARK: - File Hanlding
    /// Creates an object from serialized file data.
    ///
    /// - Parameter file: The stored object data.
    public convenience init(file: ProductionObjectFileData)
    {
        self.init()
        
        self.name = file.name
        self.module_name = file.module_name
        self.is_internal_module = file.is_internal_module
        
        self.position = (
            file.position[safe: 0] ?? 0,
            file.position[safe: 1] ?? 0,
            file.position[safe: 2] ?? 0,
            file.position[safe: 3] ?? 0,
            file.position[safe: 4] ?? 0,
            file.position[safe: 5] ?? 0
        )
        
        self.is_placed = file.is_placed
        
        import_module(module_name, is_internal: is_internal_module)
    }
    
    /// Returns a serialized representation of the object.
    ///
    /// - Returns: A structure containing object data.
    public func file_data() -> ProductionObjectFileData
    {
        return ProductionObjectFileData(
            name: name,
            
            module_name: module_name,
            is_internal_module: is_internal_module,
            
            position: [
                position.x, position.y, position.z,
                position.r, position.p, position.w
            ],
            
            is_placed: is_placed
        )
    }
    
    /// Creates an object by copying another object.
    ///
    /// - Parameter object: The source object.
    public convenience init(file_from_object object: ProductionObject)
    {
        self.init(
            file: ProductionObjectFileData(
                name: object.name,
                
                module_name: object.module_name,
                is_internal_module: object.is_internal_module,
                
                position: [
                    object.position.x, object.position.y, object.position.z,
                    object.position.r, object.position.p, object.position.w
                ],
                
                is_placed: object.is_placed
            )
        )
    }
}

// MARK: - File
/// A structure that represents serialized workspace object data.
///
/// Use this type to store and restore object configuration.
///
public struct ProductionObjectFileData: Codable
{
    public var name: String
    
    public var module_name: String
    public var is_internal_module: Bool
    
    public var position: [Float] // [x, y, z, r, p, w]
    
    public var is_placed: Bool
    
    public init(
        name: String,
        
        module_name: String,
        is_internal_module: Bool,
        
        position: [Float],
        
        is_placed: Bool
    )
    {
        self.name = name
        
        self.module_name = module_name
        self.is_internal_module = is_internal_module
        
        self.position = position
        
        self.is_placed = is_placed
    }
}

// MARK: - Entity Tag
/// An entity component that identifies a workspace object.
///
/// The identifier stores the object type and name for interaction
/// and processing in the scene.
///
public struct ObjectEntityIdentifier: Component
{
    /// The type of the workspace object associated with the entity.
    ///
    /// Use this property to classify entities by their functional role
    /// in the workspace.
    public var type: ProductionObjectType?
    
    /// The name of the workspace object associated with the entity.
    ///
    /// The name corresponds to the ``ProductionObject/name`` value
    /// and is used to identify the entity within the scene.
    public var name: String
    
    public init(
        type: ProductionObjectType? = .none,
        name: String
    )
    {
        self.type = type
        self.name = name
    }
}

// MARK: - Enums
/// Defines the execution scope of a process.
public enum ScopeType: String, Codable, Equatable, CaseIterable
{
    case operational = "Operational"
    case continious = "Continuous"
}

/// Defines the state of a technological operation.
public enum PerformingState: String, Codable, Equatable, CaseIterable
{
    case none = "None"
    case current = "Current"
    case processing = "Processing"
    case completed = "Completed"
    case error = "Error"
    
    /// A color that represents the current performing state.
    ///
    /// Use this property to visualize the state in user interfaces.
    /// Each state is mapped to a distinct color for quick recognition.
    public var color: Color
    {
        switch self
        {
        case .none: .gray
        case .current: .cyan
        case .processing: .yellow
        case .completed: .green
        case .error: .red
        }
    }
}

/*public protocol RoboticDevice
{
    
}*/

/// Defines the operation mode of a device.
public enum DeviceMode: String, CaseIterable, Codable
{
    case simulation = "Simulation"
    case real = "Real"
}

/// A protocol that represents a digital twin of a device.
///
/// A device twin synchronizes a virtual model with a physical or simulated device.
///
public protocol DeviceTwin: ProductionObject, ObservableObject
{
    /// The operating mode of the device.
    ///
    /// The mode defines whether the device operates in a simulated environment
    /// or interacts with a physical system.
    var device_mode: DeviceMode { get set }
    
    /// The connector that provides interaction with an external system.
    ///
    /// The connector enables communication with a physical device or
    /// an external control interface.
    var model_controller: ModelControllerType { get set }
    
    /// A type that represents the model controller of the device.
    ///
    /// Conforming types implement control logic in accordance with
    /// the device model.
    associatedtype ModelControllerType: ModelController
    
    /// The connector that provides interaction with an external system.
    ///
    /// The connector enables communication with a physical device or
    /// an external control interface.
    var connector: ConnectorType { get set }
    
    /// A type that represents the connector of the device.
    ///
    /// Conforming types implement communication with external systems.
    associatedtype ConnectorType: ProductionObjectConnector
    
    /// Connects the device to its data source.
    func connect_device()
    
    /// Disconnects the device from its data source.
    func disconnect_device()
    
    /// A Boolean value that indicates whether the digital twin is synchronized.
    ///
    /// When `true`, the virtual model state corresponds to the actual device state.
    var is_twin_sync: Bool { get set }
}

/// A protocol for objects that produce state output.
///
/// Provides mechanisms for periodic data acquisition and update.
///
public protocol StateOutputCapable: ProductionObject, ObservableObject
{
    /// The current state data of the device.
    ///
    /// The value represents the observable output of the device,
    /// including parameters obtained from the control system or sensors.
    var device_output: DeviceOutputData? { get set }
    
    /// A Boolean value that indicates whether the output update loop is active.
    var is_output_updating: Bool { get set }
    
    /// A Boolean value that enables or disables state updating.
    var state_update_enabled: Bool { get set }
    
    /// The task responsible for executing the state update loop.
    var output_update_task: Task<Void, Never>? { get set }
    
    /// The time interval between state updates, in nanoseconds.
    ///
    /// The interval defines the frequency of data acquisition.
    var state_update_interval: Double { get set }
    
    /// The scope that defines how state updates are performed.
    ///
    /// The scope determines whether updates are executed continuously
    /// or within a specific operational cycle.
    var update_scope_type: ScopeType { get set }
    
    /// Starts the state update process.
    func start_output_updating()
    
    /// Stops the state update process.
    func stop_output_updating()
    
    /// Updates the device state data.
    func update_statistics_data()
    
    /// Resets the device state data.
    func reset_device_output()
}

//
//  WorkspaceObject.swift
//  IndustrialKit
//
//  Created by Artem on 29.10.2022.
//

import Foundation

import SwiftUI
#if canImport(RealityKit)
import RealityKit
#endif

/**
 A base class of industrial production object.
 
 Industrial production objects are represented by equipment that provide technological operations performing.
 */
@MainActor
open class WorkspaceObject: ObservableObject, @preconcurrency Identifiable, @preconcurrency Equatable, @preconcurrency Hashable//, @preconcurrency Codable
{
    public static func == (lhs: WorkspaceObject, rhs: WorkspaceObject) -> Bool // Identity condition by names & types
    {
        return lhs.name == rhs.name && type(of: lhs) == type(of: rhs)
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    /// Object identifier.
    public var id = UUID()
    
    /// Object name in workspace.
    @Published public var name = String()
    {
        didSet
        {
            update_entity_model_identifier() //! Test
        }
    }
    
    /// A name of module to describe scene, controller and connector.
    public var module_name = ""
    
    /// A module access type identifier – external or internal.
    public var is_internal_module = true
    
    /// Object init function.
    public init()
    {
        
    }
    
    /**
     Inits object by name.
     
     Used for object mismatch.
     */
    public init(
        name: String
    )
    {
        self.name = name
    }
    
    public init(
        name: String,
        entity_name: String
    )
    {
        self.name = name
        perform_load_entity(named: entity_name)
    }
    
    public convenience init(
        name: String,
        entity: Entity
    )
    {
        self.init(name: name)
        self.model_entity = entity
        
        import_entity(model_entity)
    }
    
    /// Inits object by name and module name of installed module.
    public init(
        name: String,
        module_name: String,
        is_internal: Bool = true
    )
    {
        self.name = name
        self.is_internal_module = is_internal
        
        module_import_by_name(module_name, is_internal: is_internal)
    }
    
    // MARK: - Module handling
    /// Modules folder access bookmark.
    nonisolated(unsafe) public static var modules_folder_bookmark: Data?
    
    /**
     Imports module by name.
     - Parameters:
        - name: An installed module name.
     */
    open func module_import_by_name(_ name: String, is_internal: Bool = true)
    {
        
    }
    
    /**
     Indicates whether an available module is present for the workspace object.
     - Returns: `true` if a module is available, otherwise `false`.
     */
    open var has_avaliable_module: Bool { false }
    
    // MARK: - Object in workspace handling
    /// In workspace placement state.
    @Published public var is_placed = false
    {
        didSet
        {
            entity.isEnabled = is_placed
        }
    }
    
    /// Additional operations after remowing an object from the workspace.
    open func on_remove()
    {
        
    }
    
    /**
     A robot pointer position.
     
     Tuple with three coordinates – *x*, *y*, *z* and three angles – *r*, *p*, *w*.
     */
    @Published public var position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            update_model_position() //! Test
        }
    }
    
    // MARK: - Visual functions
    #if canImport(RealityKit)
    /// A complex workspace object entity.
    public var entity = Entity() //public var entity: Entity?
    
    /// A workspace object entity for visual modeling and physical simulation.
    public var model_entity: Entity?
    
    /// An entity loading state.
    //@Published public var entity_loaded = false
    
    private func perform_load_entity(named name: String)
    {
        Task
        {
            do
            {
                let model_entity = try await Entity(named: name)
                
                print("🥂 Loaded! (\(name))")
                
                import_entity(model_entity)
            }
            catch
            {
                //entity_loaded = false
                
                print(error.localizedDescription)
            }
        }
    }
    
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
    
    open var entity_tag: EntityModelIdentifier
    {
        return EntityModelIdentifier(type: .none, name: name)
    }
    
    public func update_entity_model_identifier()
    {
        guard let model_entity = model_entity else { return }
        
        model_entity.visit
        { entity in
            entity.components.remove(EntityModelIdentifier.self)
            entity.components.set(entity_tag)
        }
    }
    
    open func extend_entity_preparation(_ entity: Entity)
    {
        
    }
    
    /// Places entity to "scene" and connects with handling avalibility.
    public func place_entity(to content: RealityViewCameraContent)
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
    }
    
    /// Places entity to "scene" and connects with handling avalibility.
    public func place_entity_at_position(to content: RealityViewCameraContent)
    {
        place_entity(to: content)
        
        Task
        {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            update_model_position() //entity.update_position(position)
        }
    }
    
    public func update_model_position()
    {
        entity.update_position(position)
    }
    
    open func extend_entity_placement(_ entity: Entity)
    {
        //reality_controller.connect_entities(of: entity)
    }
    #endif
    
    // MARK: - Work with file system
    public convenience init(file: WorkspaceObjectFileData)
    {
        self.init()
        
        self.name = file.name
        self.module_name = file.module_name
        self.is_internal_module = file.is_internal_module
        
        self.position = (
            file.location[safe: 0] ?? 0,
            file.location[safe: 1] ?? 0,
            file.location[safe: 2] ?? 0,
            file.rotation[safe: 0] ?? 0,
            file.rotation[safe: 1] ?? 0,
            file.rotation[safe: 2] ?? 0
        )
        
        self.is_placed = file.is_placed
        
        module_import_by_name(module_name, is_internal: is_internal_module)
    }
    
    public func file_data() -> WorkspaceObjectFileData
    {
        return WorkspaceObjectFileData(
            name: name,
            
            module_name: module_name,
            is_internal_module: is_internal_module,
            
            location: [position.x, position.y, position.z],
            rotation: [position.r, position.p, position.w],
            
            is_placed: is_placed
        )
    }
    
    public convenience init(file_from_object object: WorkspaceObject)
    {
        self.init(
            file: WorkspaceObjectFileData(
                name: object.name,
                
                module_name: object.module_name,
                is_internal_module: object.is_internal_module,
                
                location: [object.position.x, object.position.y, object.position.z],
                rotation: [object.position.r, object.position.p, object.position.w],
                
                is_placed: object.is_placed
            )
        )
    }
}

// MARK: - File
public struct WorkspaceObjectFileData: Codable
{
    public var name: String
    
    public var module_name: String
    public var is_internal_module: Bool
    
    public var location: [Float] // [x, y, z]
    public var rotation: [Float] // [r, p, w]
    
    public var is_placed: Bool
    
    // MARK: - Init
    public init(
        name: String,
        
        module_name: String,
        is_internal_module: Bool,
        
        location: [Float],
        rotation: [Float],
        
        is_placed: Bool
    )
    {
        self.name = name
        
        self.module_name = module_name
        self.is_internal_module = is_internal_module
        
        self.location = location
        self.rotation = rotation
        
        self.is_placed = is_placed
    }
}

// MARK: - Entity Tag
public struct EntityModelIdentifier: Component
{
    public var type: WorkspaceObjectType?
    public var name: String

    public init(
        type: WorkspaceObjectType? = .none,
        name: String
    )
    {
        self.type = type
        self.name = name
    }
}

// MARK: - Enums
public enum ScopeType: String, Codable, Equatable, CaseIterable
{
    case selected = "Selected"
    case constant = "Constant"
}

public enum PerformingState: String, Codable, Equatable, CaseIterable
{
    case none = "None"
    case current = "Current"
    case processing = "Processing"
    case completed = "Completed"
    case error = "Error"
    
    public var color: Color
    {
        switch self
        {
        case .none:
            .gray
        case .current:
            .cyan
        case .processing:
            .yellow
        case .completed:
            .green
        case .error:
            .red
        }
    }
}

public protocol RoboticDevice
{
    
}

public protocol StateOutputCapable: RoboticDevice, WorkspaceObject, ObservableObject
{
    /// A device state data.
    var device_state: DeviceState? { get set }
    
    /// Flag indicating whether the update loop is active.
    var is_state_updating: Bool { get set }
    
    /// The task responsible for executing the update loop.
    var state_update_task: Task<Void, Never>? { get set }
    
    /// The interval between updates in nanoseconds.
    var state_update_interval: Double { get set }
    
    /// Defines the update timing scope.
    var update_scope_type: ScopeType { get set }
    
    /// Starts the update loop.
    func start_update_state()
    
    /// Stops the update loop.
    func reset_update_state()
    
    /// Updates statisitcs data by model controller (if demo is *true*) or connector (if demo is *false*).
    func update_statistics_data()
    
    /// Clears device state data.
    func reset_device_state()
}

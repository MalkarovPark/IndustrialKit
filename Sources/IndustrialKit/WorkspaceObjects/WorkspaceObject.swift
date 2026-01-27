//
//  WorkspaceObject.swift
//  IndustrialKit
//
//  Created by Artem on 29.10.2022.
//

import Foundation

#if canImport(RealityKit)
import RealityKit
#endif
import SwiftUI

/**
 A base class of industrial production object.
 
 Industrial production objects are represented by equipment that provide technological operations performing.
 */
@MainActor
open class WorkspaceObject: ObservableObject, @preconcurrency Identifiable, @preconcurrency Equatable, @preconcurrency Hashable//, @preconcurrency Codable
{
    public static func == (lhs: WorkspaceObject, rhs: WorkspaceObject) -> Bool // Identity condition by names
    {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    /// Object identifier.
    public var id = UUID()
    
    /// Object name in workspace.
    public var name = String()
    
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
    public init(name: String)
    {
        self.name = name
    }
    
    public init(name: String, entity_name: String)
    {
        self.name = name
        perform_load_entity(named: entity_name)
    }
    
    public convenience init(name: String, entity: Entity)
    {
        self.init(name: name)
        self.model_entity = entity
        perform_load_entity(model_entity)
    }
    
    /// Inits object by name and module name of installed module.
    public init(name: String, module_name: String, is_internal: Bool = true)
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
            if !is_placed
            {
                position = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
                on_remove()
            }
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
    public var position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    // MARK: - Update functions
    /// Flag indicating whether the update loop is active.
    private var updated = false
    
    /// The task responsible for executing the update loop.
    private var update_task: Task<Void, Never>?
    
    /// The interval between updates in nanoseconds.
    public var update_interval: Double = 0.01
    
    /// Defines the update timing scope.
    public var scope_type: ScopeType = ScopeType.selected
    
    /**
     Starts the update loop.
     
     This function sets the `updated` flag to `true` and initiates a new task that repeatedly calls the `update()` function on the main thread.  The loop runs as long as the `updated` flag remains `true`.  A sleep duration of approximately 1 millisecond is introduced between each update cycle. The task can be cancelled by calling `disable_update()`.
     */
    public func perform_update()
    {
        updated = true
        
        update_task = Task
        {
            while updated
            {
                try? await Task.sleep(nanoseconds: UInt64(update_interval * 1_000_000_000))
                await MainActor.run
                {
                    self.update()
                }
                
                if update_task == nil
                {
                    return
                }
            }
        }
    }
    
    /**
     Stops the update loop.
     
     This function sets the `updated` flag to `false`, cancels the `update_task`, and sets it to `nil`.  This effectively terminates the update loop initiated by `perform_update()`.
     */
    public func disable_update()
    {
        updated = false
        update_task?.cancel()
        update_task = nil
    }
    
    /**
     Called repeatedly within the update loop to perform updates.
     
     This function is called on the main thread by the `perform_update()` function as long as the `updated` flag is `true`. Subclasses should override this method to implement their specific update logic.
     
     > This function is called frequently, so it's crucial to keep its performing time as short as possible to avoid performance issues.
     */
    open func update()
    {
        
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
                
                perform_load_entity(model_entity)
            }
            catch
            {
                //entity_loaded = false
                print(error.localizedDescription)
            }
        }
    }
    
    public func perform_load_entity(_ model_entity: Entity?)
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
    
    /*public func update_entity_model_identifier(for model_entity: Entity?, entity_tag: EntityModelIdentifier)
    {
        guard let model_entity = model_entity else { return }
        
        model_entity.visit
        { entity in
            entity.components.remove(EntityModelIdentifier.self)
            entity.components.set(entity_tag)
        }
    }*/
    
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
            // Wait until bot.entity becomes available, then place it once
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            /*while model_entity == nil
            {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }*/
            
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
    
    // MARK: - UI functions
    /// Returns info for object card view (with UIImage).
    /*open var card_info: (title: String, subtitle: String, color: Color, image: UIImage, node: SCNNode)
    {
        return("Title", "Subtitle", Color.clear, UIImage(), SCNNode())
    }*/
    
    // MARK: - Work with file system
    /*private enum CodingKeys: String, CodingKey
    {
        case name
        
        case module_name
        case is_internal_module
        
        case location
        case rotation
        case is_placed
        
        case update_interval
        case scope_type
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        
        self.module_name = try container.decode(String.self, forKey: .module_name)
        self.is_internal_module = try container.decodeIfPresent(Bool.self, forKey: .is_internal_module) ?? true // self.is_internal_module = try container.decode(Bool.self, forKey: .is_internal_module)
        
        let location = try container.decode([Float].self, forKey: .location)
        let rotation = try container.decode([Float].self, forKey: .rotation)
        self.position = (location[0], location[1], location[2], rotation[0], rotation[1], rotation[2])
        
        self.is_placed = try container.decode(Bool.self, forKey: .is_placed)
        
        self.update_interval = try container.decodeIfPresent(Double.self, forKey: .update_interval) ?? 0.01
        self.scope_type = try container.decodeIfPresent(ScopeType.self, forKey: .scope_type) ?? .selected
        
        module_import_by_name(module_name, is_internal: self.is_internal_module)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(module_name, forKey: .module_name)
        try container.encode(is_internal_module, forKey: .is_internal_module)
        
        try container.encode([position.x, position.y, position.z], forKey: .location)
        try container.encode([position.r, position.p, position.w], forKey: .rotation)
        
        try container.encode(is_placed, forKey: .is_placed)
        
        try container.encode(update_interval, forKey: .update_interval)
        try container.encode(scope_type, forKey: .scope_type)
    }*/
    
    public convenience init(file: WorkspaceObjectFileData)
    {
        self.init()
        
        self.name = file.name
        self.module_name = file.module_name
        self.is_internal_module = file.is_internal_module
        
        /*self.position = (
         file.location[0],
         file.location[1],
         file.location[2],
         file.rotation[0],
         file.rotation[1],
         file.rotation[2]
         )*/
        self.position = (
            file.location[safe: 0] ?? 0,
            file.location[safe: 1] ?? 0,
            file.location[safe: 2] ?? 0,
            file.rotation[safe: 0] ?? 0,
            file.rotation[safe: 1] ?? 0,
            file.rotation[safe: 2] ?? 0
        )
        
        self.is_placed = file.is_placed
        self.update_interval = file.update_interval
        self.scope_type = file.scope_type
        
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
            
            is_placed: is_placed,
            
            update_interval: update_interval,
            scope_type: scope_type
        )
    }
    
    public convenience init(file_from_object object: WorkspaceObject)
    {
        self.init(file: WorkspaceObjectFileData(
            name: object.name,
            
            module_name: object.module_name,
            is_internal_module: object.is_internal_module,
            
            location: [object.position.x, object.position.y, object.position.z],
            rotation: [object.position.r, object.position.p, object.position.w],
            
            is_placed: object.is_placed,
            
            update_interval: object.update_interval,
            scope_type: object.scope_type
        ))
    }
}

// MARK: - File
public struct WorkspaceObjectFileData: Codable
{
    public var name: String
    
    public var module_name: String
    public var is_internal_module: Bool
    
    public var location: [Float]      // [x, y, z]
    public var rotation: [Float]      // [r, p, w]
    
    public var is_placed: Bool
    
    public var update_interval: Double
    public var scope_type: ScopeType
    
    // MARK: - Init
    public init(
        name: String,
        
        module_name: String,
        is_internal_module: Bool,
        
        location: [Float],
        rotation: [Float],
        
        is_placed: Bool,
        
        update_interval: Double,
        scope_type: ScopeType
    )
    {
        self.name = name
        
        self.module_name = module_name
        self.is_internal_module = is_internal_module
        
        self.location = location
        self.rotation = rotation
        
        self.is_placed = is_placed
        
        self.update_interval = update_interval
        self.scope_type = scope_type
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

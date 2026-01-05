//
//  WorkspaceObject.swift
//  IndustrialKit
//
//  Created by Artem on 29.10.2022.
//

import Foundation

//import SceneKit
import RealityKit
import SwiftUI

/**
 A base class of industrial production object.
 
 Industrial production objects are represented by equipment that provide technological operations performing.
 */
open class WorkspaceObject: Identifiable, Equatable, Hashable, ObservableObject, Codable, @unchecked Sendable // , NSCopying
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
    /// A workspace object entity for visual modeling and physical simulation.
    public var entity: Entity?
    
    private func perform_load_entity(named name: String)
    {
        Task
        { @MainActor in
            do
            {
                self.entity = try await Entity(named: name)
                
                print("🥂 Loaded! (\(name))")
                
                guard let entity = entity else { return }
                
                entity.generateCollisionShapes(recursive: true)
                
                entity.visit
                { entity in
                    print(EntityModelIdentifier(type: .robot, name: name))
                    entity.components.set(EntityModelIdentifier(type: .robot, name: name))
                    //entity.components.set(entity_tag)
                }
                
                entity.components.set(InputTargetComponent())
                
                extend_entity_preparation(entity)
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
    }
    
    open var entity_tag: Component
    {
        return EntityModelIdentifier(type: .none, name: name)
    }
    
    @MainActor open func extend_entity_preparation(_ entity: Entity)
    {
        
    }
    
    /// Places entity to "scene" and connects with handling avalibility.
    @MainActor public func place_entity(to content: RealityViewCameraContent)
    {
        Task
        { @MainActor in
            // Wait until bot.entity becomes available, then place it once
            while entity == nil
            {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            
            // Place entity
            guard let entity = entity else { return }
            
            content.add(entity)
            
            extend_entity_placement(entity)
        }
    }
    
    /// Places entity to "scene" and connects with handling avalibility.
    @MainActor public func place_entity_at_position(to content: RealityViewCameraContent)
    {
        place_entity(to: content)
        
        Task
        { @MainActor in
            // Wait until bot.entity becomes available, then place it once
            while entity == nil
            {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            
            // Place entity
            //guard let entity = entity else { return }
            
            update_model_position() //entity.update_position(position)
        }
    }
    
    @MainActor public func update_model_position()
    {
        entity?.update_position(position)
    }
    
    @MainActor open func extend_entity_placement(_ entity: Entity)
    {
        //reality_controller.connect_entities(of: entity)
    }
    #endif
    
    ///Old
    
    /// Scene file address.
    public var scene_address = ""
    
    /// Connected object scene node.
    //public var node: SCNNode?
    
    /// Name of node for connect to instance node variable.
    open var scene_node_name: String? { nil }
    
    /// Addres of internal folder with workspace objects scenes.
    open var scene_internal_folder_address: String? { nil }
    
    /// Folder access bookmark.
    nonisolated(unsafe) public static var folder_bookmark: Data?
    
    ///Old
    
    // MARK: - UI functions
    /// Returns info for object card view (with UIImage).
    /*open var card_info: (title: String, subtitle: String, color: Color, image: UIImage, node: SCNNode)
    {
        return("Title", "Subtitle", Color.clear, UIImage(), SCNNode())
    }*/
    
    // MARK: - Work with file system
    private enum CodingKeys: String, CodingKey
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
    }
}

// MARK: - Entity Tag
struct EntityModelIdentifier: Component
{
    var type: WorkspaceObjectType? = .none // Associated Workspace Object type
    var name = String() // Associated Workspace Object name
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

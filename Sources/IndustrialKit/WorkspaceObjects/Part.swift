//
//  Part.swift
//  IndustrialKit
//
//  Created by Artem on 28.08.2022.
//

import Foundation

#if canImport(RealityKit)
import RealityKit
#endif
import SwiftUI

/**
 A part in production complex class.
 
 Forms environment, and represent objects with which executing devices interact directly.
 */
open class Part: WorkspaceObject
{
    private var figure: String? // Part figure name
    private var lengths: [Float]? // lengths for part without scene figure
    private var figure_color: String? // Color hex for part without scene figure
    private var material_name: String? // Material for part without scene figure
    
    /// Physics body for part model node by physics type.
    /*public var physics: SCNPhysicsBody?
    {
        switch physics_type
        {
        case .ph_static:
            return .static()
        case .ph_dynamic:
            return .dynamic()
        case .ph_kinematic:
            let shape = SCNPhysicsShape(node: self.node ?? SCNNode(), options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
            return SCNPhysicsBody(type: .kinematic, shape: shape)
            // return .kinematic()
        default:
            return .none
        }
    }*/
    
    /**
     Physics type of part.
     
     > This variable is codable.
     */
    public var physics_type: PhysicsType = PhysicsType.ph_none // Physic body type
    
    /// The state of physics calculation for part node.
    public var enable_physics = false
    {
        didSet
        {
            /*if enable_physics
            {
                node?.physicsBody = physics // Return original physics
            }
            else
            {
                node?.physicsBody = nil // Remove physic body
            }*/
        }
    }
    
    // MARK: - Init functions
    public override init()
    {
        super.init()
    }
    
    public override init(name: String)
    {
        super.init(name: name)
    }
    
    public override init(name: String, entity_name: String)
    {
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Inits part by name and scene name.
    public init(name: String, scene_name: String)
    {
        super.init(name: name)
    }
    
    /// Inits part by name and part module.
    public init(name: String, module: PartModule, is_internal: Bool = true)
    {
        super.init(name: name)
        
        is_internal_module = is_internal
        module_import(module)
    }
    
    public override init(name: String, module_name: String, is_internal: Bool)
    {
        super.init(name: name, module_name: module_name, is_internal: is_internal)
    }
    
    override open func extend_entity_preparation(_ entity: Entity)
    {
        apply_physics3(to: entity)
    }
    
    func apply_physics(to entity: Entity)
    {
        /*entity.visit
        { child in
            child.components.remove(PhysicsBodyComponent.self)
            child.components.remove(PhysicsMotionComponent.self)
            child.components.remove(CollisionComponent.self)
        }*/
        
        var shapes: [ShapeResource] = []
        
        entity.visit
        { child in
            guard let model = child as? ModelEntity,
                  let mesh = model.model?.mesh
            else { return }
            
            let relativeTransform = child.transformMatrix(relativeTo: entity)
            
            let position = SIMD3<Float>(
                relativeTransform.columns.3.x,
                relativeTransform.columns.3.y,
                relativeTransform.columns.3.z
            )
            
            let rotation = simd_quatf(relativeTransform)
            
            let shape = ShapeResource.generateConvex(from: mesh)
            
            let offsetShape = shape.offsetBy(
                rotation: rotation, translation: position
            )
            
            shapes.append(offsetShape)
        }
        
        guard !shapes.isEmpty else { return }
        
        entity.components.set(CollisionComponent(shapes: shapes))
        
        entity.components.set(
            PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .dynamic
            )
        )
    }
    
    func apply_physics2(to entity: Entity)
    {
        entity.visit
        { child in
            child.components.remove(PhysicsBodyComponent.self)
            child.components.remove(CollisionComponent.self)
            child.components.remove(PhysicsMotionComponent.self)
        }
        
        var shapes: [ShapeResource] = []
        
        entity.visit
        { child in
            guard let model = child as? ModelEntity else { return }
            
            let bounds = model.visualBounds(relativeTo: entity)
            
            let size = bounds.extents
            let center = bounds.center
            
            if size.x < 0.0001 || size.y < 0.0001 || size.z < 0.0001
            {
                return
            }
            
            let shape = ShapeResource.generateBox(size: size)
            
            let positionedShape = shape.offsetBy(
                rotation: simd_quatf(), translation: center
            )
            
            shapes.append(positionedShape)
        }
        
        guard !shapes.isEmpty else { return }
        
        entity.components.set(CollisionComponent(shapes: shapes))
        
        entity.components.set(
            PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .dynamic
            )
        )
    }
    
    func apply_physics3(to entity: Entity)
    {
        entity.visit
        { child in
            child.components.remove(PhysicsBodyComponent.self)
            child.components.remove(CollisionComponent.self)
            child.components.remove(PhysicsMotionComponent.self)
        }
        
        var globalMin = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var globalMax = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        var models: [ModelEntity] = []
        
        entity.visit
        { child in
            guard let model = child as? ModelEntity else { return }
            
            let b = model.visualBounds(relativeTo: entity)
            
            globalMin = min(globalMin, b.min)
            globalMax = max(globalMax, b.max)
            
            models.append(model)
        }
        
        guard !models.isEmpty else { return }
        
        let center = (globalMin + globalMax) * 0.5
        
        var shapes: [ShapeResource] = []
        
        for model in models
        {
            let bounds = model.visualBounds(relativeTo: entity)
            let size = bounds.extents
            
            if size.x < 0.0001 || size.y < 0.0001 || size.z < 0.0001 { continue }
            
            let localCenter = bounds.center - center
            
            let shape = ShapeResource.generateBox(size: size)
                .offsetBy(rotation: simd_quatf(angle: 0, axis: SIMD3(0,1,0)), translation: localCenter)
            
            shapes.append(shape)
        }
        
        entity.components.set(CollisionComponent(shapes: shapes))
        
        entity.components.set(
            PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .dynamic
            )
        )
        
        entity.components.set(PhysicsMotionComponent())
        
        if var motion = entity.components[PhysicsMotionComponent.self] {
            motion.linearVelocity = [0.0001, 0, 0] // триггер broad-phase
            entity.components.set(motion)
        }
    }
    
    private func generate_collisions_recursively(_ entity: Entity)
    {
        if let model = entity as? ModelEntity
        {
            model.generateCollisionShapes(recursive: false)
        }
        
        for child in entity.children
        {
            generate_collisions_recursively(child)
        }
    }
    
    private func remove_child_physics(_ entity: Entity)
    {
        for child in entity.children
        {
            child.components.remove(PhysicsBodyComponent.self)
            child.components.remove(PhysicsMotionComponent.self)
            remove_child_physics(child)
        }
    }
    
    private func apply_compound_physics(to entity: Entity)
    {
        var body = PhysicsBodyComponent()
        
        body.mode = .dynamic
        body.massProperties = .default
        
        body.material = .generate(
            friction: 0.8,
            restitution: 0.05
        )
        
        entity.components.set(body)
        
        entity.components.set(PhysicsMotionComponent())
    }
    
    // MARK: - Module handling
    /**
     Sets modular components to object instance.
     - Parameters:
        - module: A part module.
     
     Set the following components:
     - Scene Node
     */
    public func module_import(_ module: PartModule)
    {
        module_name = module.name
        
        Task
        {
            while module.entity == nil
            {
                try await Task.sleep(nanoseconds: 30_000_000)
            }
            
            guard let entity = module.entity else { return }
            
            await MainActor.run
            {
                perform_load_entity(entity.clone(recursive: true))
            }
        }
        /*if let module_entity = module.entity
        {
            perform_load_entity(module_entity.clone(recursive: true))
        }*/
        
        //color_from_model()
    }
    
    /// Imported internal part modules.
    nonisolated(unsafe) public static var internal_modules = [PartModule]()
    
    /// Imported external part modules.
    nonisolated(unsafe) public static var external_modules = [PartModule]()
    
    public override func module_import_by_name(_ name: String, is_internal: Bool = true)
    {
        let modules = is_internal ? Part.internal_modules : Part.external_modules
        
        guard let index = modules.firstIndex(where: { $0.name == name })
        else
        {
            return
        }
        
        module_import(modules[index])
    }
    
    override open var has_avaliable_module: Bool
    {
        return is_internal_module ? Part.internal_modules.contains(where: { $0.name == module_name }) : Part.external_modules.contains(where: { $0.name == module_name })
    }
    
    /**
     Imports external modules by names.
     - Parameters:
        - name: A list of external modules names.
     */
    public static func external_modules_import(by names: [String])
    {
        Part.external_modules.removeAll()
        
        for name in names
        {
            Part.external_modules.append(PartModule(external_name: name))
        }
    }
    
    /// Performs loading to all entities from internal modules.
    public static func load_all_internal_modules_entities()
    {
        for module in Part.internal_modules
        {
            module.perform_load_entity()
        }
    }
    
    /// Performs loading to all entities from external modules.
    public static func load_all_external_modules_entities()
    {
        for module in Part.external_modules
        {
            module.perform_load_entity()
        }
    }
    
    private func color_import()
    {
        /*if node != nil
        {
            if figure_color != nil
            {
                color_to_model()
            }
            else
            {
                color_from_model()
            }
        }*/
    }
    
    private func color_from_model()
    {
        /*if node != nil
        {
            let node_color = node?.geometry?.firstMaterial?.diffuse.contents as? UIColor
            
            figure_color = node_color?.to_hex()
        }*/
    }
    
    /// Applies color to part node by components.
    public func color_to_model()
    {
        /*if node != nil
        {
            /*var viewed_nodes = node?.childNodes ?? []
            let color = UIColor(hex: figure_color ?? "#453CCC")
            
            while !viewed_nodes.isEmpty
            {
                let current_node = viewed_nodes.removeFirst()
                
                if let geometry = current_node.geometry
                {
                    geometry.firstMaterial?.diffuse.contents = color
                    // break
                }
                else
                {
                    viewed_nodes.append(contentsOf: current_node.childNodes)
                }
            }*/
            node?.geometry?.firstMaterial?.diffuse.contents = UIColor(hex: figure_color ?? "#453CCC")
        }*/
    }
    
    // MARK: - Visual Functions
    #if canImport(RealityKit)
    override public var entity_tag: EntityModelIdentifier
    {
        return EntityModelIdentifier(type: .part, name: name)
    }
    #endif
    
    /// Old
    // MARK: Part in workspace handling
    /// Resets model postion.
    public func model_position_reset()
    {
        /*node?.position = SCNVector3(0, 0, 0)
        node?.rotation.x = 0
        node?.rotation.y = 0
        node?.rotation.z = 0*/
    }
    /// Old
    
    // MARK: - UI functions
    /// Part model color.
    public var color: Color
    {
        get
        {
            return Color(hex: figure_color ?? "#453CCC")
        }
        set
        {
            figure_color = UIColor(newValue).to_hex()
            
            // Update color by components
            color_to_model()
        }
    }
    
    /// Returns info for part card view.
    /*public override var card_info: (title: String, subtitle: String, color: Color, image: UIImage, SCNNode: SCNNode) // Get info for robot card view
    {
        return("\(self.name)", "Subtitle", self.color, UIImage(), self.node ?? SCNNode())
    }*/
    
    // MARK: - Work with file system
    public convenience init(file: PartFileData)
    {
        self.init(file: file.object) //self.init()
        
        self.physics_type = file.physics_type
        self.figure_color = file.figure_color
        
        color_import()
    }
    
    public func file_data() -> PartFileData
    {
        return PartFileData(
            object: WorkspaceObjectFileData(
                name: name,
                
                module_name: module_name,
                is_internal_module: is_internal_module,
                
                location: [position.x, position.y, position.z],
                rotation: [position.r, position.p, position.w],
                is_placed: is_placed,
                
                update_interval: update_interval,
                scope_type: scope_type
            ),
            
            physics_type: physics_type,
            figure_color: figure_color
        )
    }
    
    public convenience init(file_from_object object: Part)
    {
        let file: PartFileData = object.file_data()
        self.init(file: file)
    }
}

public enum PhysicsType: String, Codable, Equatable, CaseIterable
{
    case ph_static = "Static"
    case ph_dynamic = "Dynamic"
    case ph_kinematic = "Kinematic"
    case ph_none = "None"
    
    public var mode: PhysicsBodyMode?
    {
        switch self
        {
        case .ph_static: .static
        case .ph_dynamic: .dynamic
        case .ph_kinematic: .kinematic
        default: .none
        }
    }
}

// MARK: - File Data
public struct PartFileData: Codable
{
    public var object: WorkspaceObjectFileData
    
    public var physics_type: PhysicsType
    public var figure_color: String?
    
    // MARK: - Init
    public init(
        object: WorkspaceObjectFileData,
        
        physics_type: PhysicsType,
        figure_color: String?
    )
    {
        self.object = object
        
        self.physics_type = physics_type
        self.figure_color = figure_color
    }
}

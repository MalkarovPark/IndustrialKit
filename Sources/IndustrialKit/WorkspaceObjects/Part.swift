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
        update_model_color()
        apply_physics(to: entity)
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
    
    // MARK: - Physics
    /**
     Physics body data of part.
     
     > This variable is codable.
     */
    @Published public var physics_body_data: PhysicsBodyComponentFileData = PhysicsBodyComponentFileData()
    
    /*public var physical_body: PhysicsBodyComponent?
    {
        get
        {
            if let physics_body_data = physics_body_data
            {
                return physics_body_data.component
            }
            else
            {
                return nil
            }
        }
        set
        {
            if let new_value = newValue
            {
                
            }
            else
            {
                physics_body_data = nil
            }
        }
    }*/
    
    /// The state of physics calculation for part node.
    public var physics_enabled = false
    {
        didSet
        {
            /*if physics_enabled
            {
                node?.physicsBody = physics // Return original physics
            }
            else
            {
                node?.physicsBody = nil // Remove physic body
            }*/
        }
    }
    
    func apply_physics(to entity: Entity)
    {
        entity.visit
        { child in
            //child.components.remove(CollisionComponent.self)
            child.components.remove(PhysicsBodyComponent.self)
            child.components.remove(PhysicsMotionComponent.self)
        }
        
        var models: [ModelEntity] = []
        
        entity.visit
        { child in
            guard let model = child as? ModelEntity else { return }
            
            models.append(model)
        }
        
        guard !models.isEmpty else { return }
        
        var shapes: [ShapeResource] = []
        
        for model in models
        {
            let bounds = model.visualBounds(relativeTo: entity)
            let size = bounds.extents
            
            if size.x < 0.0001 || size.y < 0.0001 || size.z < 0.0001 { continue }
            
            let shape = ShapeResource.generateBox(size: size)
                .offsetBy(
                    rotation: simd_quatf(angle: 0, axis: SIMD3(0, 1, 0)),
                    translation: bounds.center
                )
            
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
        
        if var motion = entity.components[PhysicsMotionComponent.self]
        {
            motion.linearVelocity = [0.0001, 0, 0]
            entity.components.set(motion)
        }
    }
    
    // MARK: - Color
    public var is_custom_color: Bool = false
    {
        didSet
        {
            update_model_color()
        }
    }
    
    private var color_code: String = "#05A89D" // Color hex for part without scene figure
    
    /// Part model color.
    public var color: Color
    {
        get
        {
            return Color(hex: color_code)
        }
        set
        {
            color_code = UIColor(newValue).to_hex() ?? "#05A89D"
            
            update_model_color()
        }
    }
    
    private var saved_basecolor_textures: [ObjectIdentifier: [MaterialParameters.Texture?]] = [:]
    
    private func update_model_color()
    {
        guard let model_entity = model_entity else { return }
        
        if is_custom_color
        {
            apply_color(UIColor(hex: color_code) ?? .systemIndigo, to: model_entity)
        }
        else
        {
            remove_color(from: model_entity)
        }
        
        func apply_color(_ color: UIColor, to root: Entity)
        {
            root.visit
            { entity in
                
                guard let model = entity as? ModelEntity else { return }
                guard var materials = model.model?.materials else { return }
                
                let id = ObjectIdentifier(model)
                
                if saved_basecolor_textures[id] == nil
                {
                    saved_basecolor_textures[id] = []
                }
                
                var stored: [MaterialParameters.Texture?] = []
                
                for i in materials.indices
                {
                    guard var pbr = materials[i] as? PhysicallyBasedMaterial
                    else
                    {
                        stored.append(nil)
                        continue
                    }
                    
                    stored.append(pbr.baseColor.texture)
                    
                    pbr.baseColor.texture = nil
                    
                    pbr.baseColor.tint = color
                    
                    materials[i] = pbr
                }
                
                saved_basecolor_textures[id] = stored
                model.model?.materials = materials
            }
        }
        
        func remove_color(from root: Entity)
        {
            root.visit
            { entity in
                guard let model = entity as? ModelEntity else { return }
                guard var materials = model.model?.materials else { return }
                
                let id = ObjectIdentifier(model)
                guard let stored = saved_basecolor_textures[id] else { return }
                
                for i in materials.indices
                {
                    guard var pbr = materials[i] as? PhysicallyBasedMaterial
                    else { continue }
                    
                    pbr.baseColor.texture = stored[i]
                    pbr.baseColor.tint = .white
                    
                    materials[i] = pbr
                }
                
                model.model?.materials = materials
            }
        }
    }
    
    // MARK: - Visual Functions
    #if canImport(RealityKit)
    override public var entity_tag: EntityModelIdentifier
    {
        return EntityModelIdentifier(type: .part, name: name)
    }
    #endif
    
    // MARK: - Work with file system
    public convenience init(file: PartFileData)
    {
        self.init(file: file.object) //self.init()
        
        self.physics_enabled = file.physics_enabled
        self.physics_body_data = file.physics_body_data
        
        self.is_custom_color = file.is_custom_color
        self.color_code = file.color_code
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
            
            physics_enabled: physics_enabled,
            physics_body_data: physics_body_data,
            
            is_custom_color: is_custom_color,
            color_code: color_code
        )
    }
    
    public convenience init(file_from_object object: Part)
    {
        let file: PartFileData = object.file_data()
        self.init(file: file)
    }
}

// MARK: - File Data
public struct PartFileData: Codable
{
    public var object: WorkspaceObjectFileData
    
    public var physics_enabled: Bool = true
    public var physics_body_data: PhysicsBodyComponentFileData = PhysicsBodyComponentFileData()
    
    public var is_custom_color: Bool = false
    public var color_code: String
    
    // MARK: Init
    public init(
        object: WorkspaceObjectFileData,
        
        physics_enabled: Bool,
        physics_body_data: PhysicsBodyComponentFileData,
        
        is_custom_color: Bool,
        color_code: String
    )
    {
        self.object = object
        
        self.physics_enabled = physics_enabled
        self.physics_body_data = physics_body_data
        
        self.is_custom_color = is_custom_color
        self.color_code = color_code
    }
}

public class PhysicsBodyComponentFileData: Codable
{
    @Published public var mode: PhysicsBodyModeFileData
    
    @Published public var mass: Float
    
    @Published public var static_friction: Float
    @Published public var dynamic_friction: Float
    @Published public var restitution: Float
    
    @Published public var affected_by_gravity: Bool = true
    
    @Published public var lock_location: (x: Bool, y: Bool, z: Bool) // [x, y, z]
    @Published public var lock_rotation: (r: Bool, p: Bool, w: Bool) // [r, p, w]
    
    @Published public var ccd: Bool = false
    
    // MARK: Init
    public init(
        mode: PhysicsBodyModeFileData = ._static,
        
        mass: Float = 1,
        
        static_friction: Float = 0.5,
        dynamic_friction: Float = 0.5,
        restitution: Float = 0.0,
        
        affected_by_gravity: Bool = true,
        
        lock_location: (x: Bool, y: Bool, z: Bool) = (false, false, false),
        lock_rotation: (r: Bool, p: Bool, w: Bool) = (false, false, false),
        
        ccd: Bool = false
    )
    {
        self.mode = mode
        
        self.mass = mass
        
        self.static_friction = static_friction
        self.dynamic_friction = dynamic_friction
        self.restitution = restitution
        
        self.affected_by_gravity = affected_by_gravity
        
        self.lock_location = lock_location
        self.lock_rotation = lock_rotation
        
        self.ccd = ccd
    }
    
    // MARK: Body
    @MainActor public var component: PhysicsBodyComponent
    {
        var body = PhysicsBodyComponent(
            massProperties: .init(mass: mass),
            material: PhysicsMaterialResource.generate(
                staticFriction: static_friction,
                dynamicFriction: dynamic_friction,
                restitution: restitution
            ),
            mode: mode.mode
        )
        
        body.isAffectedByGravity = affected_by_gravity
        
        body.isTranslationLocked = (
            x: lock_location.x,
            y: lock_location.z,
            z: lock_location.y
        )
        
        body.isRotationLocked = (
            x: lock_rotation.r,
            y: lock_rotation.w,
            z: lock_rotation.p
        )
        
        body.isContinuousCollisionDetectionEnabled = ccd
        
        return body
    }
    
    // MARK: File handling
    private enum CodingKeys: String, CodingKey
    {
        case mode
        
        case mass
        
        case static_friction
        case dynamic_friction
        case restitution
        
        case affected_by_gravity
        
        case lock_location
        case lock_rotation
        
        case ccd
    }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        mode = try container.decode(PhysicsBodyModeFileData.self, forKey: .mode)
        
        mass = try container.decode(Float.self, forKey: .mass)
        
        static_friction = try container.decode(Float.self, forKey: .static_friction)
        dynamic_friction = try container.decode(Float.self, forKey: .dynamic_friction)
        restitution = try container.decode(Float.self, forKey: .restitution)
        
        affected_by_gravity = try container.decode(Bool.self, forKey: .affected_by_gravity)
        
        let locationArray = try container.decode([Bool].self, forKey: .lock_location)
        if locationArray.count == 3
        {
            lock_location = (locationArray[0], locationArray[1], locationArray[2])
        }
        else
        {
            lock_location = (false, false, false)
        }
        
        let rotationArray = try container.decode([Bool].self, forKey: .lock_rotation)
        if rotationArray.count == 3
        {
            lock_rotation = (rotationArray[0], rotationArray[1], rotationArray[2])
        }
        else
        {
            lock_rotation = (false, false, false)
        }
        
        ccd = try container.decode(Bool.self, forKey: .ccd)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(mode, forKey: .mode)
        
        try container.encode(mass, forKey: .mass)
        
        try container.encode(static_friction, forKey: .static_friction)
        try container.encode(dynamic_friction, forKey: .dynamic_friction)
        try container.encode(restitution, forKey: .restitution)
        
        try container.encode(affected_by_gravity, forKey: .affected_by_gravity)
        
        try container.encode(
            [lock_location.x, lock_location.y, lock_location.z],
            forKey: .lock_location
        )
        
        try container.encode(
            [lock_rotation.r, lock_rotation.p, lock_rotation.w],
            forKey: .lock_rotation
        )
        
        try container.encode(ccd, forKey: .ccd)
    }
}

public enum PhysicsBodyModeFileData: String, Codable, Equatable, CaseIterable
{
    case _dynamic = "Static"
    case _kinematic = "Kinematic"
    case _static = "Dynamic"
    
    public var mode: PhysicsBodyMode
    {
        switch self
        {
        case ._dynamic: .dynamic
        case ._kinematic: .kinematic
        case ._static: .static
        }
    }
}

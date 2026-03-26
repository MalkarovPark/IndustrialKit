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
    
    public override init(
        name: String,
        entity_name: String
    )
    {
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Inits part by name and part module.
    public init(
        name: String,
        module: PartModule,
        
        is_internal: Bool = true
    )
    {
        super.init(name: name)
        
        is_internal_module = is_internal
        import_module(module)
    }
    
    public override init(
        name: String,
        module_name: String,
        
        is_internal: Bool
    )
    {
        super.init(name: name, module_name: module_name, is_internal: is_internal)
    }
    
    override open func extend_entity_preparation(_ entity: Entity)
    {
        update_model_color()
        update_model_physics()
    }
    
    // MARK: - Module handling
    /**
     Sets modular components to object instance.
     - Parameters:
        - module: A part module.
     
     Set the following components:
     - Scene Node
     */
    public func import_module(_ module: PartModule)
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
                import_entity(entity.clone(recursive: true))
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
    
    public override func import_module(_ name: String, is_internal: Bool = true)
    {
        let modules = is_internal ? Part.internal_modules : Part.external_modules
        
        guard let index = modules.firstIndex(where: { $0.name == name })
        else
        {
            return
        }
        
        import_module(modules[index])
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
    public static func import_external_modules(by names: [String])
    {
        Part.external_modules.removeAll()
        
        for name in names
        {
            Part.external_modules.append(PartModule(external_name: name))
        }
    }
    
    /// Performs loading to all entities from internal modules.
    public static func load_all_internal_modules_entities(_ completion: @escaping () -> Void = {})
    {
        Task
        {
            for module in Part.internal_modules
            {
                await module.perform_load_entity_async()
            }
            completion()
        }
    }
    
    /// Performs loading to all entities from external modules.
    public static func load_all_external_modules_entities(_ completion: @escaping () -> Void = {})
    {
        Task
        {
            for module in Part.external_modules
            {
                await module.perform_load_entity_async()
            }
            completion()
        }
    }
    
    // MARK: - Physics
    /**
     Physics body data of part.
     
     > This variable is codable.
     */
    @Published public var physics_body_data: PhysicsBodyComponentFileData = PhysicsBodyComponentFileData()
    
    /// The state of physics calculation for part node.
    public var physics_enabled = false
    {
        didSet
        {
            update_model_physics()
        }
    }
    
    public func update_model_physics()
    {
        if physics_enabled
        {
            entity.apply_physics(by: physics_body_data.component)
        }
        else
        {
            entity.visit
            { child in
                child.components.remove(PhysicsBodyComponent.self)
                child.components.remove(PhysicsMotionComponent.self)
            }
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
                
                position: [
                    position.x, position.y, position.z,
                    position.r, position.p, position.w
                ],
                
                is_placed: is_placed
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

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

/// A passive object within a robotic production environment.
///
/// A part represents a non-controllable component of a robotic system.
/// It does not perform actions independently but serves as an object
/// of interaction for active components such as robots and tools.
///
/// Parts may represent:
/// - Production equipment elements (for example, tables, drives, safety enclosures)
/// - Raw materials entering the production process
/// - Workpieces being processed or assembled into final products
///
/// During system operation, parts are manipulated, transported, or
/// transformed by robots and tools.
///
/// Use ``Part`` instances to model the physical environment and material
/// flow within a robotic workspace.
///
open class Part: ProductionObject
{
    // MARK: - Initializers
    /// Creates a part instance with default parameters.
    public override init()
    {
        super.init()
    }
    
    /// Creates a part with a specified name.
    ///
    /// - Parameter name: A human-readable identifier of the part.
    public override init(name: String)
    {
        super.init(name: name)
    }
    
    /// Creates a part with a name and associated entity resource.
    ///
    /// - Parameters:
    ///   - name: A human-readable identifier.
    ///   - entity_name: A name of the associated scene entity.
    public override init(
        name: String,
        entity_name: String
    )
    {
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Creates a part instance using a module configuration.
    ///
    /// - Parameters:
    ///   - name: A part identifier.
    ///   - module: A part module defining structure and geometry.
    ///   - is_internal: A flag indicating whether the module is internal.
    ///
    /// The module entity is loaded asynchronously and applied when available.
    /// If `name` is not specified, the module name is used as the object name.
    public init(
        name: String = String(),
        module: PartModule,
        
        is_internal: Bool = true
    )
    {
        super.init(name: name.isEmpty ? module.name : name)
        
        is_internal_module = is_internal
        import_module(module)
    }
    
    /// Creates a part instance using a module name.
    ///
    /// - Parameters:
    ///   - name: A part identifier.
    ///   - module_name: A module identifier.
    ///   - is_internal: A flag indicating internal or external module source.
    ///
    /// The module entity is loaded asynchronously and applied when available.
    /// If `name` is not specified, the module name is used as the object name.
    public override init(
        name: String = String(),
        module_name: String,
        
        is_internal: Bool
    )
    {
        super.init(name: name.isEmpty ? module_name : name, module_name: module_name, is_internal: is_internal)
    }
    
    // MARK: - Entity Preparation
    /// Extends entity preparation by applying visual and physical configuration.
    ///
    /// - Parameter entity: A root entity representing the part.
    ///
    /// This method updates model color and physics state after the entity
    /// is loaded or modified.
    override open func extend_entity_preparation(_ entity: Entity)
    {
        update_model_color()
        update_model_physics()
    }
    
    // MARK: - Module Handling
    /// Imports a part module and applies its entity representation.
    ///
    /// The method asynchronously waits for the module entity to become available,
    /// then clones and imports it into the part instance.
    ///
    /// - Parameter module: A part module describing geometry and structure.
    ///
    /// Performing of entity import occurs on the main actor.
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
    
    /// A collection of registered external part modules.
    ///
    /// External modules are loaded dynamically from external sources.
    nonisolated(unsafe) public static var internal_modules = [PartModule]()
    
    /// Imports a module by name from registered modules.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - is_internal: A flag indicating module source.
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
    
    /// Registers external part modules by their names.
    ///
    /// Existing external modules are replaced.
    ///
    /// - Parameter names: A list of module identifiers.
    override open var has_avaliable_module: Bool
    {
        return is_internal_module ? Part.internal_modules.contains(where: { $0.name == module_name }) : Part.external_modules.contains(where: { $0.name == module_name })
    }
    
    /// Performs loading of all internal module entities asynchronously.
    ///
    /// - Parameter completion: A callback invoked after performing completes.
    public static func import_external_modules(by names: [String])
    {
        Part.external_modules.removeAll()
        
        for name in names
        {
            Part.external_modules.append(PartModule(external_name: name))
        }
    }
    
    /// Performs loading of all external module entities asynchronously.
    ///
    /// - Parameter completion: A callback invoked after performing completes.
    public static func load_internal_module_entities(_ completion: @escaping () -> Void = {})
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
    
    /// Performs loading of all external module entities asynchronously.
    ///
    /// - Parameter completion: A callback invoked after performing completes.
    public static func load_external_module_entities(_ completion: @escaping () -> Void = {})
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
    /// Physical body configuration of the part.
    ///
    /// This value defines collision shape, mass, and other physics properties
    /// applied to the part entity.
    ///
    /// > This property is codable.
    @Published public var physics_body_data: PhysicsBodyComponentFileData = PhysicsBodyComponentFileData()
    
    /// A Boolean value that indicates whether physics simulation is enabled.
    ///
    /// When enabled, physics components are applied to the entity hierarchy.
    /// When disabled, all physics components are removed.
    public var physics_enabled = false
    {
        didSet
        {
            update_model_physics()
        }
    }
    
    /// Updates physics components of the part entity.
    ///
    /// Applies or removes physics simulation depending on the current
    /// ``physics_enabled`` state.
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
    /// A Boolean value that indicates whether a custom color is applied.
    ///
    /// When enabled, the part model uses the specified ``color`` value.
    /// When disabled, original material textures are restored.
    public var is_custom_color: Bool = false
    {
        didSet
        {
            update_model_color()
        }
    }
    
    private var color_code: String = "#05A89D" // Color hex for part without scene figure
    
    /// The color of the part model.
    ///
    /// Setting this value updates the visual appearance of the entity.
    /// The color is stored internally as a hexadecimal string representation.
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
    
    /// Updates the visual appearance of the part model.
    ///
    /// Applies or removes color tint while preserving original material textures.
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
    
    // MARK: - Reality Functions
    #if canImport(RealityKit)
    /// An identifier used for tagging the entity within the scene.
    ///
    /// The identifier encodes the object type and its name.
    override public var entity_tag: ObjectEntityIdentifier
    {
        return ObjectEntityIdentifier(type: .part, name: name)
    }
    #endif
    
    // MARK: - File Hanlding
    /// Creates a part instance from serialized file data.
    ///
    /// - Parameter file: A data structure containing part configuration.
    public convenience init(file: PartFileData)
    {
        self.init(file: file.object) //self.init()
        
        self.physics_enabled = file.physics_enabled
        self.physics_body_data = file.physics_body_data
        
        self.is_custom_color = file.is_custom_color
        self.color_code = file.color_code
    }
    
    /// Generates a serializable representation of the part.
    ///
    /// - Returns: A ``PartFileData`` instance containing current state.
    public func file_data() -> PartFileData
    {
        return PartFileData(
            object: ProductionObjectFileData(
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
    
    /// Creates a part instance by copying data from another part.
    ///
    /// - Parameter object: A source part instance.
    public convenience init(file_from_object object: Part)
    {
        let file: PartFileData = object.file_data()
        self.init(file: file)
    }
}

// MARK: - File Hanlding
/// A serializable representation of a part configuration.
///
/// This structure stores all necessary data to reconstruct a part,
/// including its workspace configuration, physics parameters,
/// and visual customization.
///
public struct PartFileData: Codable
{
    public var object: ProductionObjectFileData
    
    public var physics_enabled: Bool = true
    public var physics_body_data: PhysicsBodyComponentFileData = PhysicsBodyComponentFileData()
    
    public var is_custom_color: Bool = false
    public var color_code: String
    
    // MARK: Init
    public init(
        object: ProductionObjectFileData,
        
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

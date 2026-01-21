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
public class Part: WorkspaceObject
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
        //self.node = (SCNScene(named: scene_name) ?? SCNScene()).rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
    }
    
    /// Inits part by name and scene.
    /*public init(name: String, scene: SCNScene)
    {
        super.init(name: name)
        self.node = scene.rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
    }*/
    
    /// Inits part by name and part module.
    public init(name: String, module: PartModule)
    {
        super.init(name: name)
        module_import(module)
    }
    
    public override init(name: String, module_name: String, is_internal: Bool)
    {
        super.init(name: name, module_name: module_name, is_internal: is_internal)
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
        
        // node = module.node.clone()
        //node = module.node.deep_clone()
        color_from_model()
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
    public override var scene_node_name: String { "part" }
    
    /*public func node_by_description()
    {
        node = SCNNode()
        
        // Convert Float array to GFloat array
        var lengths = [CGFloat]()
        for length in self.lengths ?? []
        {
            lengths.append(CGFloat(length))
        }
        
        // Set geometry
        var geometry: SCNGeometry?
        switch figure
        {
        case "plane":
            if lengths.count == 2
            {
                geometry = SCNPlane(width: lengths[0], height: lengths[1])
            }
            else
            {
                geometry = SCNPlane(width: 40, height: 40)
            }
        case "box":
            if lengths.count >= 3 && lengths.count <= 4
            {
                geometry = SCNBox(width: lengths[0], height: lengths[1], length: lengths[2], chamferRadius: lengths.count == 3 ? 0 : lengths[3]) // If lengths 4 – set chamer radius by element 3
            }
            else
            {
                geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
            }
        case "sphere":
            if lengths.count == 1
            {
                geometry = SCNSphere(radius: lengths[0])
            }
            else
            {
                geometry = SCNSphere(radius: 20)
            }
        case "pyramid":
            if lengths.count == 3
            {
                geometry = SCNPyramid(width: lengths[0], height: lengths[1], length: lengths[2])
            }
            else
            {
                geometry = SCNPyramid(width: 40, height: 20, length: 40)
            }
        case "cylinder":
            if lengths.count == 2
            {
                geometry = SCNCylinder(radius: lengths[0], height: lengths[1])
            }
            else
            {
                geometry = SCNCylinder(radius: 20, height: 40)
            }
        case "cone":
            if lengths.count == 3
            {
                geometry = SCNCone(topRadius: lengths[0], bottomRadius: lengths[1], height: lengths[2])
            }
            else
            {
                geometry = SCNCone(topRadius: 10, bottomRadius: 20, height: 40)
            }
        case "tube":
            if lengths.count == 3
            {
                geometry = SCNTube(innerRadius: lengths[0], outerRadius: lengths[1], height: lengths[2])
            }
            else
            {
                geometry = SCNTube(innerRadius: 10, outerRadius: 20, height: 40)
            }
        case "capsule":
            if lengths.count == 2
            {
                geometry = SCNCapsule(capRadius: lengths[0], height: lengths[1])
            }
            else
            {
                geometry = SCNCapsule(capRadius: 20, height: 40)
            }
        case "torus":
            if lengths.count == 2
            {
                geometry = SCNTorus(ringRadius: lengths[0], pipeRadius: lengths[1])
            }
            else
            {
                geometry = SCNTorus(ringRadius: 40, pipeRadius: 20)
            }
        default:
            geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
        }
        node?.geometry = geometry
        
        // Set color by components
        color_to_model()
        
        // Set shading type
        switch material_name
        {
        case "blinn":
            node?.geometry?.firstMaterial?.lightingModel = .blinn
        case "constant":
            node?.geometry?.firstMaterial?.lightingModel = .constant
        case "lambert":
            node?.geometry?.firstMaterial?.lightingModel = .lambert
        case "phong":
            node?.geometry?.firstMaterial?.lightingModel = .phong
        case "physically based":
            node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        case "shadow only":
            node?.geometry?.firstMaterial?.lightingModel = .shadowOnly
        default:
            node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        }
        
        node?.name = "part"
    }*/
    
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
    /*enum CodingKeys: String, CodingKey
    {
        case physics_type
        case figure_color
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        try super.init(from: decoder)
        
        self.physics_type = try container.decode(PhysicsType.self, forKey: .physics_type)
        self.figure_color = try container.decodeIfPresent(String.self, forKey: .figure_color)
        
        color_import()
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(physics_type, forKey: .physics_type)
        try container.encode(figure_color, forKey: .figure_color)
        
        try super.encode(to: encoder)
    }*/
    
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

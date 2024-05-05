//
//  Part.swift
//  IndustrialKit
//
//  Created by Artem on 28.08.2022.
//

import Foundation
import SceneKit
import SwiftUI

/**
 A part in production complex class.
 
 Forms environment, and represent objects with which executing devices interact directly.
 */
public class Part: WorkspaceObject, Codable
{
    private var figure: String? //Part figure name
    private var lengths: [Float]? //lengths for part without scene figure
    private var figure_color: [Int]? //Color for part without scene figure
    private var material_name: String? //Material for part without scene figure
    
    ///Physics body for part model node by physics type.
    public var physics: SCNPhysicsBody?
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
            //return .kinematic()
        default:
            return .none
        }
    }
    
    /**
     Physics type of part.
     
     > This variable is codable.
     */
    public var physics_type: PhysicsType = PhysicsType.ph_none //Physic body type
    
    ///The state of physics calculation for part node.
    public var enable_physics = false
    {
        didSet
        {
            if enable_physics
            {
                node?.physicsBody = physics //Return original physics
            }
            else
            {
                node?.physicsBody = nil //Remove physic body
            }
        }
    }
    
    //MARK: - Part init functions
    public override init()
    {
        super.init()
    }
    
    public override init(name: String)
    {
        super.init(name: name)
    }
    
    ///Inits part by dictionary and use models folder.
    public init(name: String, dictionary: [String: Any])
    {
        super.init()
        init_by_dictionary(name: name, dictionary: dictionary)
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it.
        {
            self.scene_address = dictionary["Scene"] as? String ?? ""
            get_node_from_scene()
            color_from_model()
        }
        else
        {
            node_by_description()
        }
    }
    
    ///Inits tool by model dictionary.
    private func init_by_dictionary(name: String, dictionary: [String: Any])
    {
        self.name = name
        
        //Get values form dictionary
        if dictionary.keys.contains("Figure")
        {
            self.figure = dictionary["Figure"] as? String ?? ""
        }
        
        if dictionary.keys.contains("Color")
        {
            var figure_color = [Int]()
            let elements = dictionary["Color"] as! NSArray
            
            for element in elements //Add elements from NSArray to floats array
            {
                figure_color.append((element as? Int) ?? 0)
            }
            
            self.figure_color = figure_color
        }
        
        if dictionary.keys.contains("Material")
        {
            self.material_name = dictionary["Material"] as? String ?? ""
        }
        
        if dictionary.keys.contains("Lengths")
        {
            var lengths = [Float]()
            let elements = dictionary["Lengths"] as! NSArray
            
            for element in elements //Add elements from NSArray to floats array
            {
                lengths.append((element as? Float) ?? 0)
            }
            
            self.lengths = lengths
        }
        
        if dictionary.keys.contains("Physics")
        {
            switch dictionary["Physics"] as? String ?? ""
            {
            case "static":
                physics_type = .ph_static
            case "dynamic":
                physics_type = .ph_dynamic
            case "kinematic":
                physics_type = .ph_kinematic
            default:
                physics_type = .ph_none
            }
        }
    }
    
    ///Inits part by name and scene name.
    public init(name: String, scene_name: String)
    {
        super.init(name: name)
        self.node = (SCNScene(named: scene_name) ?? SCNScene()).rootNode.childNode(withName: self.scene_node_name, recursively: false)!
    }
    
    private func color_from_model()
    {
        if node != nil
        {
            #if os(macOS)
            let node_color = node?.geometry?.firstMaterial?.diffuse.contents as? NSColor
            
            let components = node_color?.cgColor.components
            figure_color = [Int((components?[0]) ?? (123 / 255) * 255), Int((components?[1]) ?? (123 / 255) * 255), Int((components?[2]) ?? (129 / 255) * 255)]
            #else
            let node_color = node?.geometry?.firstMaterial?.diffuse.contents as? UIColor
            
            if let color = node_color
            {
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                
                color.getRed(&red, green: &green, blue: &blue, alpha: nil)
                figure_color = [Int(red * 255), Int(green * 255), Int(blue * 255)]
            }
            else
            {
                figure_color = [123, 123, 129]
            }
            #endif
        }
    }
    
    ///Applies color to part node by components.
    public func color_to_model()
    {
        if node != nil
        {
            #if os(macOS)
            node?.geometry?.firstMaterial?.diffuse.contents = NSColor(red: CGFloat(figure_color?[0] ?? 0) / 255, green: CGFloat(figure_color?[1] ?? 0) / 255, blue: CGFloat(figure_color?[2] ?? 0) / 255, alpha: 1)
            #else
            node?.geometry?.firstMaterial?.diffuse.contents = UIColor(red: CGFloat(figure_color?[0] ?? 0) / 255, green: CGFloat(figure_color?[1] ?? 0) / 255, blue: CGFloat(figure_color?[2] ?? 0) / 255, alpha: 1)
            #endif
        }
    }
    
    //MARK: - Visual build functions
    public override var scene_node_name: String { "part" }
    
    public override var scene_internal_folder_address: String { Part.scene_folder }
    
    ///A scene folder address.
    public static var scene_folder = String()
    
    public override func node_by_description()
    {
        node = SCNNode()
        
        //Convert Float array to GFloat array
        var lengths = [CGFloat]()
        for length in self.lengths ?? []
        {
            lengths.append(CGFloat(length))
        }
        
        //Set geometry
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
                geometry = SCNBox(width: lengths[0], height: lengths[1], length: lengths[2], chamferRadius: lengths.count == 3 ? 0 : lengths[3]) //If lengths 4 – set chamer radius by element 3
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
        
        //Set color by components
        color_to_model()
        
        //Set shading type
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
    }
    
    //MARK: Part in workspace handling
    ///Resets model postion.
    public func model_position_reset()
    {
        node?.position = SCNVector3(0, 0, 0)
        node?.rotation.x = 0
        node?.rotation.y = 0
        node?.rotation.z = 0
    }
    
    //MARK: - UI functions
    ///Part model color.
    public var color: Color
    {
        get
        {
            return Color(red: Double(figure_color?[0] ?? 0) / 255, green: Double(figure_color?[1] ?? 0) / 255, blue: Double(figure_color?[2] ?? 0) / 255)
        }
        set
        {
            let viewed_color_components = UIColor(newValue).cgColor.components
            
            for i in 0..<(figure_color?.count ?? 3)
            {
                self.figure_color?[i] = Int((viewed_color_components?[i] ?? 0) * 255)
            }
            
            //Update color by components
            color_to_model()
        }
    }
    
    ///Returns info for part card view.
    public override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name)", "Subtitle", self.color, UIImage())
    }
    
    //MARK: - Work with file system
    private enum CodingKeys: String, CodingKey
    {
        case name
        
        case scene_address
        
        case figure
        case lengths
        
        case figure_color
        case material_name
        case physics_type
        
        case is_placed
        case location
        case rotation
    }
    
    public required init(from decoder: any Decoder) throws
    {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        
        self.figure = try container.decodeIfPresent(String.self, forKey: .figure)
        self.lengths = try container.decodeIfPresent([Float].self, forKey: .lengths)
        
        self.figure_color = try container.decodeIfPresent([Int].self, forKey: .figure_color)
        self.material_name = try container.decodeIfPresent(String.self, forKey: .material_name)
        self.physics_type = try container.decode(PhysicsType.self, forKey: .physics_type)
        
        self.is_placed = try container.decode(Bool.self, forKey: .is_placed)
        self.location = try container.decode([Float].self, forKey: .location)
        self.rotation = try container.decode([Float].self, forKey: .rotation)
        
        self.scene_address = try container.decode(String.self, forKey: .scene_address)
        
        //get_node_from_scene()
        //color_to_model()
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(figure, forKey: .figure)
        try container.encode(lengths, forKey: .lengths)
        
        try container.encode(figure_color, forKey: .figure_color)
        try container.encode(material_name, forKey: .material_name)
        try container.encode(physics_type, forKey: .physics_type)
        
        try container.encode(is_placed, forKey: .is_placed)
        try container.encode(location, forKey: .location)
        try container.encode(rotation, forKey: .rotation)
        
        try container.encode(scene_address, forKey: .scene_address)
    }
}

public enum PhysicsType: String, Codable, Equatable, CaseIterable
{
    case ph_static = "Static"
    case ph_dynamic = "Dynamic"
    case ph_kinematic = "Kinematic"
    case ph_none = "None"
}

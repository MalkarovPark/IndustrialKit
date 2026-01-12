//
//  PositionProgram.swift
//  IndustrialKit
//
//  Created by Artem on 01.06.2022.
//

import Foundation

//import SceneKit
import RealityKit
import SwiftUI

/**
 A type of named set of target positions performed by an industrial robot.
 
 Contains an array of positions and a custom name used for identification. Builds a visual model of the points with trajectory and provides actions for the robot model.
 */
public class PositionsProgram: Identifiable, Codable, Equatable
{
    public let id: UUID = UUID()
    
    public static func == (lhs: PositionsProgram, rhs: PositionsProgram) -> Bool
    {
        return lhs.name == rhs.name // Identity condition by names
    }
    
    /// A positions program name.
    public var name: String
    
    /// An array of positions points.
    public var points = [PositionPoint]()
    
    // MARK: - Positions program init functions
    /// Creates a new positions program.
    public init()
    {
        self.name = "None"
    }
    
    /**
     Creates a new positions program.
     - Parameters:
        - name: A new program name.
     */
    public init(name: String?)
    {
        self.name = name ?? "None"
    }
    
    // MARK: - Point manage functions
    /**
     Add the new point to positions program.
     - Parameters:
        - code: An added code.
     */
    public func add_point(_ point: PositionPoint)
    {
        points.append(point)
    }
    
    /**
     Creates a new positions program.
     - Parameters:
        - index: Updated position pint index.
        - code: New position point.
     */
    public func update_point(number: Int, _ point: PositionPoint)
    {
        if points.indices.contains(number) // Checking for the presence of a point with a given number to update
        {
            points[number] = point
        }
    }
    
    /**
     Checks for the presence of a point with a given index to delete.
     - Parameters:
        - index: An index of deleted point.
     */
    public func delete_point(number: Int)
    {
        if points.indices.contains(number)
        {
            points.remove(at: number)
        }
    }
    
    /// Returns the positions points count.
    public var points_count: Int
    {
        return points.count
    }
    
    /// Resets the performing state of all position points to the `.none` state.
    public func reset_points_states()
    {
        for point in points
        {
            point.performing_state = .none
        }
    }
    
    // MARK: - Visual functions
    #if canImport(RealityKit)
    @MainActor public func entity(_ point_index: Int? = nil) -> Entity
    {
        // MARK: - Color definitions
        let target_point_color = UIColor.systemPurple
        let selected_point_color = UIColor.systemIndigo
        let cylinder_color = UIColor.white.withAlphaComponent(0.75)
        
        let positions_group = Entity()
        
        if points.count > 0
        {
            var point_location = SIMD3<Float>()
            
            if points.count > 1
            {
                var is_first = true
                var pivot_points: [SIMD3<Float>] = [SIMD3<Float>(), SIMD3<Float>()]
                var index = 0
                
                for point in points
                {
                    let visual_point = ModelEntity(mesh: .generateSphere(radius: Float(0.003)), materials: [SimpleMaterial(color: target_point_color, isMetallic: false)])
                    
                    node_by_data(node: visual_point, point: point, location: &point_location)
                    
                    if let selected_index = point_index, selected_index == index
                    {
                        visual_point.model?.materials = [SimpleMaterial(color: selected_point_color, roughness: 1.0, isMetallic: false)]
                    }
                    else
                    {
                        visual_point.model?.materials = [SimpleMaterial(color: target_point_color, roughness: 1.0, isMetallic: false)]
                    }
                    
                    if is_first
                    {
                        pivot_points[0] = point_location
                        is_first = false
                    }
                    else
                    {
                        pivot_points[1] = point_location + SIMD3<Float>(.random(in: Float(-0.000001)..<Float(0.000001)), .random(in: Float(-0.000001)..<Float(0.000001)), .random(in: Float(-0.000001)..<Float(0.000001)))
                        
                        positions_group.addChild(build_ptp_line(from: pivot_points[0], to: pivot_points[1]))
                        pivot_points[0] = pivot_points[1]
                    }
                    
                    positions_group.addChild(visual_point)
                    index += 1
                }
            }
            else
            {
                let visual_point = ModelEntity(mesh: .generateSphere(radius: Float(0.002)), materials: [SimpleMaterial(color: target_point_color, isMetallic: false)])
                
                let point = points.first ?? PositionPoint()
                node_by_data(node: visual_point, point: point, location: &point_location)
                
                if point_index == 0
                {
                    visual_point.model?.materials = [SimpleMaterial(color: selected_point_color, isMetallic: false)]
                }
                else
                {
                    visual_point.model?.materials = [SimpleMaterial(color: target_point_color, isMetallic: false)]
                }
                
                positions_group.addChild(visual_point)
            }
        }
        
        return positions_group
        
        // Functions
        func build_ptp_line(from: SIMD3<Float>, to: SIMD3<Float>) -> Entity
        {
            let vector = to - from
            let height = length(vector)
            
            let cylinder_mesh = MeshResource.generateCylinder(height: height, radius: Float(0.001))
            let line_entity = ModelEntity(mesh: cylinder_mesh, materials: [SimpleMaterial(color: cylinder_color, roughness: 1.0, isMetallic: false)])
            
            line_entity.position = from + vector / 2
            
            let up_axis = SIMD3<Float>(0, 1, 0)
            let rotation_quat = simd_quaternion(up_axis, normalize(vector))
            line_entity.orientation = rotation_quat
            
            return line_entity
        }
        
        func node_by_data(node: ModelEntity, point: PositionPoint, location: inout SIMD3<Float>)
        {
            location = SIMD3<Float>(point.y / 1000, point.z / 1000, point.x / 1000)
            node.position = location
            
            let cones_entity = build_cones() // pointer without rotation
            
            // Apply rotations ONLY to pointer_entity
            let r_rot = simd_quatf(angle: Float(point.r.to_rad), axis: [0, 0, 1])
            let p_rot = simd_quatf(angle: Float(point.p.to_rad), axis: [1, 0, 0])
            let w_rot = simd_quatf(angle: Float(point.w.to_rad), axis: [0, 1, 0])
            
            cones_entity.orientation = w_rot * p_rot * r_rot
            
            node.addChild(cones_entity)
            
            // The node itself remains without rotation or has identity rotation
            node.orientation = simd_quatf() // optional, explicit identity rotation
        }
        
        func build_cones() -> Entity
        {
            let colors: [UIColor] = [
                UIColor.systemIndigo/*.withAlphaComponent(0.75)*/,
                UIColor.systemPink/*.withAlphaComponent(0.75)*/,
                UIColor.systemTeal/*.withAlphaComponent(0.75)*/
            ]
            let rotations: [SIMD3<Float>] = [[.pi/2,0,0],[0,0,-.pi/2],[0,0,0]]
            let positions: [SIMD3<Float>] = [[0,0,Float(0.008)],[Float(0.008),0,0],[0,Float(0.008),0]]
            
            let parent = Entity()
            
            for i in 0..<3
            {
                let cone = ModelEntity(mesh: .generateCone(height: 0.004, radius: 0.002), materials: [SimpleMaterial(color: colors[i], roughness: 1.0, isMetallic: false)])
                
                cone.position = positions[i]
                cone.eulerAngles = rotations[i]
                
                parent.addChild(cone)
            }
            
            return parent
        }
    }
    
    // Define colors for path and points of program
    #if os(macOS)
    private let target_point_color = NSColor.systemPurple
    private let target_point_cone_colors = [NSColor.systemIndigo, NSColor.systemPink, NSColor.systemTeal]
    private let selected_point_color = NSColor.systemIndigo
    private let target_point_cone_pos = [[0.0, 0.0, 8], [8, 0.0, 0.0], [0.0, 8, 0.0]]
    private let target_point_cone_rot = [[90.0 * .pi / 180, 0.0, 0.0], [0.0, 0.0, -90 * .pi / 180], [0.0, 0.0, 0.0]]
    private let cylinder_color = NSColor.white
    #else
    private let target_point_color = UIColor.systemPurple
    private let target_point_cone_colors = [UIColor.systemIndigo, UIColor.systemPink, UIColor.systemTeal]
    private let selected_point_color = UIColor.systemIndigo
    private let target_point_cone_pos: [[Float]] = [[0.0, 0.0, 8], [8, 0.0, 0.0], [0.0, 8, 0.0]]
    private let target_point_cone_rot: [[Float]] = [[90.0 * .pi / 180, 0.0, 0.0], [0.0, 0.0, -90 * .pi / 180], [0.0, 0.0, 0.0]]
    private let cylinder_color = UIColor.white
    #endif
    #endif
    
    // MARK: - Work with file system
    private enum CodingKeys: String, CodingKey
    {
        case name
        case points
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.points = try container.decode([PositionPoint].self, forKey: .points)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(points, forKey: .points)
    }
}

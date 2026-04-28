//
//  PositionProgram.swift
//  IndustrialKit
//
//  Created by Artem on 01.06.2022.
//

import Foundation
import RealityKit
import SwiftUI

/// A named sequence of spatial target points executed by a robot.
///
/// `PositionProgram` defines an ordered set of ``PositionPoint`` instances
/// representing robot motion targets in 3D space.
///
/// Each point describes a full pose of the robot end-effector, including
/// position, orientation, motion type, and speed parameters.
///
/// The program supports:
/// - Sequential motion definition
/// - Performing state management
/// - Visual representation of trajectory and points
/// - Serialization for storage and transfer
///
/// The program can be visualized as a trajectory consisting of connected
/// segments between points, enabling intuitive inspection and debugging.
///
/// Equality between programs is determined by their ``name``.
///
public class PositionProgram: Identifiable, Codable, Equatable, ObservableObject
{
    public let id: UUID = UUID()
    
    public static func == (lhs: PositionProgram, rhs: PositionProgram) -> Bool
    {
        return lhs.name == rhs.name // Identity condition by names
    }
    
    /// A human-readable name of the position program.
    ///
    /// The name is used as the primary identity condition when comparing programs.
    public var name: String
    
    /// An array of positions points.
    @Published public var points = [PositionPoint]()
    
    // MARK: - Initializer
    /// Creates a new position program.
    ///
    /// - Parameters:
    ///   - name: A human-readable program name. Defaults to `"None"`.
    ///   - points: An ordered list of position points describing target poses and motion parameters.
    public init(
        name: String = "None",
        points: [PositionPoint] = [PositionPoint]()
    )
    {
        self.name = name
        self.points = points
    }
    
    // MARK: - Point manage functions
    /// Appends a new position point to the program.
    ///
    /// - Parameter point: A position point to add.
    public func add_point(_ point: PositionPoint)
    {
        points.append(point)
    }
    
    /// Updates a position point at the specified index.
    ///
    /// - Parameters:
    ///   - index: The index of the point to update.
    ///   - point: A new position point.
    public func update_point(at index: Int, _ point: PositionPoint)
    {
        if points.indices.contains(index) // Checking for the presence of a point with a given number to update
        {
            points[index] = point
        }
    }
    
    /// Removes a position point at the specified index, if it exists.
    ///
    /// - Parameter index: The index of the point to remove.
    public func delete_point(at index: Int)
    {
        if points.indices.contains(index)
        {
            points.remove(at: index)
        }
    }
    
    /// The number of points contained in the program.
    public var points_count: Int
    {
        return points.count
    }
    
    /// Resets the performing state of all position points to `.none`.
    ///
    /// This method is typically used before starting program performing.
    public func reset_points_states()
    {
        for point in points
        {
            point.performing_state = .none
        }
    }
    
    // MARK: - Reality Functions
    #if canImport(RealityKit)
    /// Builds a visual representation of the position program.
    ///
    /// The method generates a 3D entity containing:
    /// - Spherical markers for each point
    /// - Directional cones representing orientation
    /// - Cylindrical segments forming a trajectory path
    ///
    /// - Parameter point_index: An optional index of the selected point.
    /// - Returns: A root entity containing the full trajectory visualization.
    @MainActor public func entity(_ point_index: Int? = nil) -> Entity
    {
        // MARK: - Color definitions
        let point_color = UIColor.systemPurple
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
                    let visual_point = ModelEntity(mesh: .generateSphere(radius: Float(0.0025)))
                    
                    node_by_data(node: visual_point, point: point, location: &point_location)
                    
                    if let selected_index = point_index, selected_index == index
                    {
                        visual_point.model?.materials = [SimpleMaterial(color: selected_point_color, roughness: 1.0, isMetallic: false)]
                    }
                    else
                    {
                        visual_point.model?.materials = [SimpleMaterial(color: point_color, roughness: 1.0, isMetallic: false)]
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
                let visual_point = ModelEntity(mesh: .generateSphere(radius: Float(0.0025)))
                
                let point = points.first ?? PositionPoint()
                node_by_data(node: visual_point, point: point, location: &point_location)
                
                if point_index == 0
                {
                    visual_point.model?.materials = [SimpleMaterial(color: selected_point_color, roughness: 1.0, isMetallic: false)]
                }
                else
                {
                    visual_point.model?.materials = [SimpleMaterial(color: point_color, roughness: 1.0, isMetallic: false)]
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
            
            let cones_entity = build_cones() // Pointer without rotation
            
            // Apply rotations only to pointer_entity
            let r_rot = simd_quatf(angle: Float(point.r.to_rad), axis: [0, 0, 1])
            let p_rot = simd_quatf(angle: Float(point.p.to_rad), axis: [1, 0, 0])
            let w_rot = simd_quatf(angle: Float(point.w.to_rad), axis: [0, 1, 0])
            
            cones_entity.orientation = w_rot * p_rot * r_rot
            
            node.addChild(cones_entity)
            
            node.orientation = simd_quatf() // Optional, explicit identity rotation
        }
        
        func build_cones() -> Entity
        {
            let colors: [UIColor] = [
                UIColor.systemIndigo/*.withAlphaComponent(0.75)*/,
                UIColor.systemPink/*.withAlphaComponent(0.75)*/,
                UIColor.systemTeal/*.withAlphaComponent(0.75)*/
            ]
            let rotations: [SIMD3<Float>] = [[.pi/2, 0, 0], [0, 0, -.pi / 2], [0, 0, 0]]
            let positions: [SIMD3<Float>] = [[0, 0, Float(0.008)], [Float(0.008), 0, 0], [0, Float(0.008), 0]]
            
            let parent = Entity()
            
            for i in 0..<3
            {
                let cone = ModelEntity(mesh: .generateCone(height: 0.004, radius: 0.002), materials: [SimpleMaterial(color: colors[i], roughness: 1.0, isMetallic: false)])
                
                cone.position = positions[i]
                cone.euler_angles = rotations[i]
                
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
    
    // MARK: - File Hanlding
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

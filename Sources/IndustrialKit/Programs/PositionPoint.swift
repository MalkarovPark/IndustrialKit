//
//  PositionPoint.swift
//  IndustrialKit
//
//  Created by Artem on 01.06.2022.
//

import Foundation

/// A spatial target point describing a robot end-effector pose.
///
/// `PositionPoint` defines a complete motion target in a Cartesian coordinate
/// system, including position, orientation, and movement parameters.
///
/// The point contains:
/// - Linear coordinates (`x`, `y`, `z`) in workspace space
/// - Orientation angles (`r`, `p`, `w`) representing roll, pitch, and yaw
/// - Motion characteristics such as move type and speed
///
/// Instances of this type are used within ``PositionProgram`` to form
/// sequential robot trajectories.
///
/// The class also maintains a performing state used for visualization
/// and execution tracking in UI.
///
/// Equality and hashing are based on the unique identifier ``id``.
///
public class PositionPoint: Identifiable, Codable, Hashable, ObservableObject, @unchecked Sendable
{
    public let id: UUID = UUID()
    
    public static func == (lhs: PositionPoint, rhs: PositionPoint) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    // A point location component.
    /// The position along the X axis.
    ///
    /// Defines the horizontal displacement in the workspace coordinate system.
    @Published public var x: Float
    
    /// The position along the Z axis.
    ///
    /// Defines the vertical displacement in the workspace coordinate system.
    @Published public var y: Float
    
    /// The position along the Z axis.
    ///
    /// Defines the vertical displacement in the workspace coordinate system.
    @Published public var z: Float
    
    // A point rotation component.
    /// The rotation around the X axis (roll).
    @Published public var r: Float
    
    /// The rotation around the P axis (pitch).
    @Published public var p: Float
    
    /// The rotation around the Y axis (yaw).
    @Published public var w: Float
    
    /// The movement type used to reach this point.
    ///
    /// Determines interpolation and motion behavior.
    @Published public var move_type: MoveType
    
    /// The movement speed when approaching this point.
    ///
    /// - Note: The value is specified in millimeters per second (mm/s).
    @Published public var move_speed: Float
    
    // MARK: - Initializer
    /// Creates a position point with spatial and motion parameters.
    ///
    /// - Parameters:
    ///   - x: Position along the X axis.
    ///   - y: Position along the Y axis.
    ///   - z: Position along the Z axis.
    ///   - r: Roll angle.
    ///   - p: Pitch angle.
    ///   - w: Yaw angle.
    ///   - move_speed: Movement speed in mm/s.
    ///   - move_type: Movement type used to reach the point.
    public init(x: Float = 0, y: Float = 0, z: Float = 0, r: Float = 0, p: Float = 0, w: Float = 0, move_speed: Float = 100, move_type: MoveType = .linear)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.p = p
        self.w = w
        
        self.move_speed = move_speed
        self.move_type = move_type
    }
    
    // MARK: - UI
    /// The current performing state of the point.
    ///
    /// This value is used for UI visualization and runtime tracking
    /// during program performing.
    @Published public var performing_state: PerformingState = .none
    
    // MARK: - File Hanlding
    // For performing_state exclusion
    enum CodingKeys: String, CodingKey
    {
        case x, y, z, r, p, w, move_type, move_speed
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        x = try container.decode(Float.self, forKey: .x)
        y = try container.decode(Float.self, forKey: .y)
        z = try container.decode(Float.self, forKey: .z)
        
        r = try container.decode(Float.self, forKey: .r)
        p = try container.decode(Float.self, forKey: .p)
        w = try container.decode(Float.self, forKey: .w)
        
        move_type = try container.decode(MoveType.self, forKey: .move_type)
        move_speed = try container.decode(Float.self, forKey: .move_speed)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
        
        try container.encode(r, forKey: .r)
        try container.encode(p, forKey: .p)
        try container.encode(w, forKey: .w)
        
        try container.encode(move_type, forKey: .move_type)
        try container.encode(move_speed, forKey: .move_speed)
    }
}

/// Linear motion between points.
///
/// The robot follows a continuous path with interpolation.
///
public enum MoveType: String, Codable, Equatable, CaseIterable
{
    /// Linear motion between points.
    ///
    /// The robot follows a continuous path with interpolation.
    case linear = "Linear"
    
    /// Precise positioning at the target point.
    ///
    /// The robot prioritizes accuracy and stops exactly at the point.
    case fine = "Fine"
    
    init(register_value: Int)
    {
        switch register_value
        {
        case 0:
            self = .linear
        case 1:
            self = .fine
        default:
            self = .linear
        }
    }
    
    /*/// Register value.
    public var register_value: Int
    {
        switch self
        {
        case .linear:
            return 0
        case .fine:
            return 1
        }
    }*/
}

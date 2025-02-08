//
//  PositionPoint.swift
//  IndustrialKit
//
//  Created by Artem on 01.06.2022.
//

import Foundation
import SceneKit

/**
 A type of value that describes the target position.
 
 The position consists of the location of the manipulator in a rectangular coordinate system and the rotation angles in it.
 */
public class PositionPoint: Identifiable, Codable, Hashable
{
    public static func == (lhs: PositionPoint, rhs: PositionPoint) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    /// A point location component.
    public var x, y, z: Float
    
    /// A point rotation component.
    public var r, p, w: Float
    
    /// Type of moving to point.
    public var move_type: MoveType
    
    /// Moving to point speed.
    public var move_speed: Float
    
    // MARK: - Init functions
    /**
     Creates a point with location and rotation values and move type.
     - Parameters:
        - x: A location by *x* axis.
        - y: A location by *y* axis.
        - z: A location by *z* axis.
        - r: A roll value.
        - p: A pitch value.
        - w: An yaw value.
        - move_type: A movement to point type.
        - move_speed: A movement to point speed.
     */
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
}

///Movement to point type.
public enum MoveType: String, Codable, Equatable, CaseIterable
{
    case linear = "Linear"
    case fine = "Fine"
}

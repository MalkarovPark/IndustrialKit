//
//  PositionPoint.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 01.06.2022.
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
    
    ///A point location component.
    public var x, y, z: Float
    
    ///A point rotation component.
    public var r, p, w: Float
    
    ///Type of moving to point.
    public var move_type: MoveType
    
    ///Moving to point speed.
    public var move_speed: Float
    
    //MARK: - Init functions
    ///Creates a point with zero position values, a speed of 10 mm/sec, and a linear movement type.
    public init()
    {
        self.x = 0
        self.y = 0
        self.z = 0
        
        self.r = 0
        self.p = 0
        self.w = 0
        
        self.move_type = .linear
        self.move_speed = 10
    }
    
    /**
     Creates a point with only location values.
     - Parameters:
        - x: Location by *x* axis.
        - y: Location by *y* axis.
        - z: Location by *z* axis.
     */
    public init(x: Float, y: Float, z: Float)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = 0
        self.p = 0
        self.w = 0
        
        self.move_type = .linear
        self.move_speed = 10
    }
    
    /**
     Creates a point with location and rotation values.
     - Parameters:
        - x: A location by *x* axis.
        - y: A location by *y* axis.
        - z: A location by *z* axis.
        - r: A roll value.
        - p: A pitch value.
        - w: An yaw value.
     */
    public init(x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.p = p
        self.w = w
        
        self.move_type = .linear
        self.move_speed = 10
    }
    
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
     */
    public init(x: Float, y: Float, z: Float, r: Float, p: Float, w: Float, move_type: MoveType)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.p = p
        self.w = w
        
        self.move_type = move_type
        self.move_speed = 10
    }
    
    /**
     Creates a point with location and rotation values and move speed.
     - Parameters:
        - x: A location by *x* axis.
        - y: A location by *y* axis.
        - z: A location by *z* axis.
        - r: A roll value.
        - p: A pitch value.
        - w: An yaw value.
        - move_speed: A movement to point speed.
     */
    public init(x: Float, y: Float, z: Float, r: Float, p: Float, w: Float, move_speed: Float)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.p = p
        self.w = w
        
        self.move_type = .linear
        self.move_speed = move_speed
    }
    
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
    public init(x: Float, y: Float, z: Float, r: Float, p: Float, w: Float, move_type: MoveType, move_speed: Float)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.p = p
        self.w = w
        
        self.move_type = move_type
        self.move_speed = move_speed
    }
    
    //MARK: Movement functions
    public func moving(time: Float) -> (position: SCNAction, rotation: SCNAction)
    {
        let moving_position = SCNVector3(y, z, x) //Convert location to scnvector
        let moving_rotation = [p.to_rad, w.to_rad, 0] //Get rotation from from position point
        
        let action_position = SCNAction.group([SCNAction.move(to: moving_position, duration: TimeInterval(time)), SCNAction.rotateTo(x: CGFloat(moving_rotation[0]), y: CGFloat(moving_rotation[1]), z: CGFloat(moving_rotation[2]), duration: TimeInterval(time))])
        let action_rotation = SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(r.to_rad), duration: TimeInterval(time))
        
        return (action_position, action_rotation)
    }
}

///Movement to point type.
public enum MoveType: String, Codable, Equatable, CaseIterable
{
    case linear = "Linear"
    case fine = "Fine"
}

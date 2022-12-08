//
//  PositionPoint.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.06.2022.
//

import Foundation

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
    
    ///Point location components.
    public var x, y, z: Float
    
    ///Point rotation components.
    public var r, p, w: Float
    
    ///Type of moving to point.
    public var move_type: MoveType
    
    ///Moving to point speed.
    public var move_speed: Float
    
    //MARK: - Init functions
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
}

public enum MoveType: String, Codable, Equatable, CaseIterable
{
    case linear = "Linear"
    case fine = "Fine"
}

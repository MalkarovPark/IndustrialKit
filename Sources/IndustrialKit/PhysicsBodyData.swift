//
//  PhysicsBodyData.swift
//  IndustrialKit
//
//  Created by Artem on 26.03.2026.
//

import Foundation
import RealityKit

public class PhysicsBodyComponentFileData: Codable
{
    @Published public var mode: PhysicsBodyModeFileData
    
    @Published public var mass: Float
    
    @Published public var static_friction: Float
    @Published public var dynamic_friction: Float
    @Published public var restitution: Float
    
    @Published public var affected_by_gravity: Bool = true
    
    @Published public var lock_location: (x: Bool, y: Bool, z: Bool) // [x, y, z]
    @Published public var lock_rotation: (r: Bool, p: Bool, w: Bool) // [r, p, w]
    
    @Published public var ccd: Bool = false
    
    // MARK: Init
    public init(
        mode: PhysicsBodyModeFileData = ._static,
        
        mass: Float = 1,
        
        static_friction: Float = 0.5,
        dynamic_friction: Float = 0.5,
        restitution: Float = 0.0,
        
        affected_by_gravity: Bool = true,
        
        lock_location: (x: Bool, y: Bool, z: Bool) = (false, false, false),
        lock_rotation: (r: Bool, p: Bool, w: Bool) = (false, false, false),
        
        ccd: Bool = false
    )
    {
        self.mode = mode
        
        self.mass = mass
        
        self.static_friction = static_friction
        self.dynamic_friction = dynamic_friction
        self.restitution = restitution
        
        self.affected_by_gravity = affected_by_gravity
        
        self.lock_location = lock_location
        self.lock_rotation = lock_rotation
        
        self.ccd = ccd
    }
    
    // MARK: Body
    @MainActor public var component: PhysicsBodyComponent
    {
        var body = PhysicsBodyComponent(
            massProperties: .init(mass: mass),
            material: PhysicsMaterialResource.generate(
                staticFriction: static_friction,
                dynamicFriction: dynamic_friction,
                restitution: restitution
            ),
            mode: mode.mode
        )
        
        body.isAffectedByGravity = affected_by_gravity
        
        body.isTranslationLocked = (
            x: lock_location.x,
            y: lock_location.z,
            z: lock_location.y
        )
        
        body.isRotationLocked = (
            x: lock_rotation.r,
            y: lock_rotation.w,
            z: lock_rotation.p
        )
        
        body.isContinuousCollisionDetectionEnabled = ccd
        
        return body
    }
    
    // MARK: File handling
    private enum CodingKeys: String, CodingKey
    {
        case mode
        
        case mass
        
        case static_friction
        case dynamic_friction
        case restitution
        
        case affected_by_gravity
        
        case lock_location
        case lock_rotation
        
        case ccd
    }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        mode = try container.decode(PhysicsBodyModeFileData.self, forKey: .mode)
        
        mass = try container.decode(Float.self, forKey: .mass)
        
        static_friction = try container.decode(Float.self, forKey: .static_friction)
        dynamic_friction = try container.decode(Float.self, forKey: .dynamic_friction)
        restitution = try container.decode(Float.self, forKey: .restitution)
        
        affected_by_gravity = try container.decode(Bool.self, forKey: .affected_by_gravity)
        
        let locationArray = try container.decode([Bool].self, forKey: .lock_location)
        if locationArray.count == 3
        {
            lock_location = (locationArray[0], locationArray[1], locationArray[2])
        }
        else
        {
            lock_location = (false, false, false)
        }
        
        let rotationArray = try container.decode([Bool].self, forKey: .lock_rotation)
        if rotationArray.count == 3
        {
            lock_rotation = (rotationArray[0], rotationArray[1], rotationArray[2])
        }
        else
        {
            lock_rotation = (false, false, false)
        }
        
        ccd = try container.decode(Bool.self, forKey: .ccd)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(mode, forKey: .mode)
        
        try container.encode(mass, forKey: .mass)
        
        try container.encode(static_friction, forKey: .static_friction)
        try container.encode(dynamic_friction, forKey: .dynamic_friction)
        try container.encode(restitution, forKey: .restitution)
        
        try container.encode(affected_by_gravity, forKey: .affected_by_gravity)
        
        try container.encode(
            [lock_location.x, lock_location.y, lock_location.z],
            forKey: .lock_location
        )
        
        try container.encode(
            [lock_rotation.r, lock_rotation.p, lock_rotation.w],
            forKey: .lock_rotation
        )
        
        try container.encode(ccd, forKey: .ccd)
    }
}

public enum PhysicsBodyModeFileData: String, Codable, Equatable, CaseIterable
{
    case _static = "Static"
    case _dynamic = "Dynamic"
    case _kinematic = "Kinematic"
    
    public var mode: PhysicsBodyMode
    {
        switch self
        {
        case ._static: .static
        case ._dynamic: .dynamic
        case ._kinematic: .kinematic
        }
    }
}

//
//  ToolModelController.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import RealityKit

///Provides control over visual model for robot.
open class ToolModelController: ModelController, @unchecked Sendable
{
    /// Cancel perform flag.
    public var canceled = false
    
    private var performing_task = Task<Void, Error> {}
    
    /**
     Performs tool model action by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool visual model.
        - completion: A completion function that is calls when the performing completes.
     */
    public func perform(code: Int, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
    {
        canceled = false
        
        performing_task = Task
        {
            do
            {
                try self.perform(code: code)
                if !canceled
                {
                    completion(.success(()))
                }
            }
            catch
            {
                completion(.failure(error))
            }
            
            canceled = false
        }
    }
    
    /**
     Performs tool model action by operation code value.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool visual model.
     */
    public func perform(code: Int) throws
    {
        let entity_animations = try entity_animations(code: code)
        
        let animation_time = process_animation(by: entity_animations) // Perform and get animation time
        
        usleep(UInt32(animation_time * 1_000_000))
    }
    
    /**
     Processes a list of entity animations and plays them on the corresponding entities.
     
     - Parameters:
        - entity_animations: An array of `EntityAnimationData`, each containing the target entity name,
     transform parameters (position, rotation, scale), duration, delay, speed, and repeat count.
     
     - Returns: The total time (`TimeInterval`) needed to complete all animations, including
     duration, speed, delay, and repeat count.
     
     Animations are applied immediately if the target entity exists. Entities not found in
     `entities` are skipped.
     */
    public func process_animation(by entity_animations: [EntityAnimationData]) -> TimeInterval
    {
        var animation_time: TimeInterval = 0
        
        for entity_animation in entity_animations
        {
            process_animation(by: entity_animation)
        }
        
        return animation_time
        
        func process_animation(by data: EntityAnimationData)
        {
            let transform = Transform(
                scale: SIMD3<Float>(x: data.scale.y, y: data.scale.z, z: data.scale.x),
                rotation:
                    simd_quatf(angle: data.position.w.to_rad, axis: [0, 1, 0]) *
                    simd_quatf(angle: data.position.p.to_rad, axis: [1, 0, 0]) *
                    simd_quatf(angle: data.position.r.to_rad, axis: [0, 0, 1]),
                translation:
                    SIMD3<Float>(
                        data.position.y / 1000,
                        data.position.z / 1000,
                        data.position.x / 1000
                    )
                )
            
            let animation_view = AnimationView(
                source: FromToByAnimation(
                    to: transform,
                    duration: data.duration,
                    bindTarget: .transform
                ),
                delay: data.delay,
                speed: data.speed
            )
            
            do
            {
                let resource = try AnimationResource.generate(with: animation_view)
                if let entity = entities[data.entity_name]
                {
                    switch data.repeat_count
                    {
                    case 1:
                        entity.playAnimation(resource)
                    case 0:
                        break
                    case nil:
                        entity.playAnimation(resource.repeat(duration: .infinity))
                    default:
                        entity.playAnimation(resource.repeat(count: data.repeat_count ?? 1))
                    }
                    
                    let current_animation_time = (data.duration * Double(data.speed)) * Double(data.repeat_count ?? 1) + data.delay
                    if current_animation_time > animation_time
                    {
                        animation_time = current_animation_time
                    }
                    
                    //animation_time += (data.duration * Double(data.speed)) * Double(data.repeat_count ?? 1) + data.delay
                }
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
    }
    
    open func entity_animations(code: Int) throws -> [EntityAnimationData]
    {
        return []
    }
    
    public func reset_entities()
    {
        for (_, entity) in entities // Remove all node actions
        {
            entity.stopAllAnimations()
        }
    }
}

// MARK: - External Model Controller
open class ExternalToolModelController: ToolModelController, @unchecked Sendable
{
    /// Clone model controller instance.
    open override func clone() -> Self
    {
        let copy = type(of: self).init()
        
        copy.external_entity_names = external_entity_names
        copy.code = code
        
        return copy
    }
    
    // MARK: Init functions
    public init(
        entity_names: [String],
        
        code: String
    )
    {
        self.external_entity_names = entity_names
        
        self.js_environment.js_code = code
    }
    
    required public init()
    {
        //self.module_name = ""
        //self.package_url = URL(fileURLWithPath: "")
    }
    
    // MARK: Parameters import
    override open var entity_names: [String]
    {
        return external_entity_names
    }
    
    public var external_entity_names = [String]()
    
    // MARK: JS Code Handling
    private var js_environment = JSEnvironment()
    
    public func reset_js_context()
    {
        js_environment.reset_context()
    }
    
    public var code: String
    {
        get { js_environment.js_code }
        set { js_environment.js_code = newValue }
    }
    
    // MARK: Modeling
    override open func entity_animations(code: Int) -> [EntityAnimationData]
    {
        do
        {
            let json_string = try js_environment.call_js_func(
                name: "entity_animations",
                args: [code]
            )
            
            guard let json_data = json_string.data(using: .utf8) else { return [] }
            
            let animations = try JSONDecoder().decode([EntityAnimationData].self, from: json_data)
            return animations
        }
        catch
        {
            print(error.localizedDescription)
            return []
        }
    }
    
    // MARK: Statistics
    open override var current_device_state: DeviceState?
    {
        do
        {
            let json_string = try js_environment.call_js_func(
                name: "current_device_state"
            )
            
            guard let json_data = json_string.data(using: .utf8)
            else
            {
                print("Failed to convert JS output to Data: \(json_string)")
                return nil
            }
            
            let state = try JSONDecoder().decode(DeviceState.self, from: json_data)
            return state
        }
        catch
        {
            print("JS current_device_state error: \(error.localizedDescription)")
            return nil
        }
    }

    open override var initial_device_state: DeviceState?
    {
        do
        {
            let json_string = try js_environment.call_js_func(
                name: "initial_device_state"
            )
            
            guard let json_data = json_string.data(using: .utf8)
            else
            {
                print("Failed to convert JS output to Data: \(json_string)")
                return nil
            }
            
            let state = try JSONDecoder().decode(DeviceState.self, from: json_data)
            return state
        }
        catch
        {
            print("JS initial_device_state error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Animation Storage
/**
 A storage for entity animation.
 */
public struct EntityAnimationData: Codable
{
    public var entity_name: String
    
    public var position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (0, 0, 0, 0, 0, 0)
    
    public var scale: (x: Float, y: Float, z: Float) = (1, 1, 1)
    
    public var duration: Double = 1
    public var timing_function: TimingFunction = .linear
    
    public var delay: Double = 0
    public var speed: Float = 1
    
    public var repeat_count: Int? = 1 //nil – infinity
    
    public init(
        entity_name: String,
        position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (0, 0, 0, 0, 0, 0),
        scale: (x: Float, y: Float, z: Float) = (1, 1, 1),
        duration: Double = 1,
        timing_function: TimingFunction = .linear,
        delay: Double = 0,
        speed: Float = 1,
        repeat_count: Int? = 1
    )
    {
        self.entity_name = entity_name
        self.position = position
        self.scale = scale
        self.duration = duration
        self.timing_function = timing_function
        self.delay = delay
        self.speed = speed
        self.repeat_count = repeat_count
    }
    
    // MARK: Work with file system
    private enum CodingKeys: String, CodingKey
    {
        case entity_name
        
        case location     // [x, y, z]
        case rotation     // [r, p, w]
        
        case scale        // [x, y, z]
        
        case duration
        //case timing_function
        case delay
        case speed
        
        case repeat_count
    }
    
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        entity_name = try container.decode(String.self, forKey: .entity_name)
        
        let location = try container.decodeIfPresent([Float].self, forKey: .location) ?? [0, 0, 0]
        let rotation = try container.decodeIfPresent([Float].self, forKey: .rotation) ?? [0, 0, 0]
        let scaleArr = try container.decodeIfPresent([Float].self, forKey: .scale) ?? [1, 1, 1]
        
        guard location.count == 3, rotation.count == 3, scaleArr.count == 3
        else
        {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Location, rotation and scale must contain exactly 3 elements"
                )
            )
        }
        
        position = (
            x: location[0],
            y: location[1],
            z: location[2],
            r: rotation[0],
            p: rotation[1],
            w: rotation[2]
        )
        
        scale = (
            x: scaleArr[0],
            y: scaleArr[1],
            z: scaleArr[2]
        )
        
        duration = try container.decodeIfPresent(Double.self, forKey: .duration) ?? 1
        //timing_function = try container.decodeIfPresent(TimingFunction.self, forKey: .timing_function) ?? .linear
        
        delay = try container.decodeIfPresent(Double.self, forKey: .delay) ?? 0
        speed = try container.decodeIfPresent(Float.self, forKey: .speed) ?? 1
        
        repeat_count = try container.decodeIfPresent(Int.self, forKey: .repeat_count) ?? 1
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(entity_name, forKey: .entity_name)
        
        try container.encode(
            [position.x, position.y, position.z],
            forKey: .location
        )
        
        try container.encode(
            [position.r, position.p, position.w],
            forKey: .rotation
        )
        
        try container.encode(
            [scale.x, scale.y, scale.z],
            forKey: .scale
        )
        
        try container.encode(duration, forKey: .duration)
        //try container.encode(timing_function, forKey: .timing_function)
        
        if delay != 0
        {
            try container.encode(delay, forKey: .delay)
        }
        
        if speed != 1
        {
            try container.encode(speed, forKey: .speed)
        }
        /*try container.encode(delay, forKey: .delay)
        try container.encode(speed, forKey: .speed)*/
        
        try container.encode(repeat_count, forKey: .repeat_count)
    }
}

public enum TimingFunction: Codable
{
    case linear, easeIn, easeOut, easeInOut
}

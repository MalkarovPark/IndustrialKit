//
//  ToolModelController.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import RealityKit

/// A controller that manages the visual model of a tool.
///
/// `ToolModelController` extends ``ModelController`` to provide
/// animation-based behavior driven by operation codes.
///
/// The controller translates operation codes into sequences of entity
/// animations, enabling visualization of discrete tool actions such as
/// gripping, welding, or actuation.
///
/// Subclasses define animation logic by overriding
/// ``entity_animations(code:)``.
///
open class ToolModelController: ModelController, @unchecked Sendable
{
    // MARK: - Performing
    /// Performs a tool action using an operation code.
    ///
    /// The method resolves animation data, applies animations to the model,
    /// and waits for completion based on calculated animation duration.
    ///
    /// - Parameter code: An operation code defining the tool action.
    /// - Throws: An error if animation generation fails.
    public func perform(code: Int) throws
    {
        let entity_animations = try entity_animations(code: code)
        
        let animation_time = process_animation(by: entity_animations) // Perform and get animation time
        
        usleep(UInt32(animation_time * 1_000_000))
    }
    
    /// Indicates whether the current performing operation is canceled.
    public var canceled = false
    
    /// Performs a tool action with a completion handler.
    ///
    /// - Parameters:
    ///   - code: An operation code defining the tool action.
    ///   - completion: A closure called when performing completes.
    private var performing_task = Task<Void, Error> {}
    
    // MARK: - Animation Processing
    /// Processes and applies entity animations to the visual model.
    ///
    /// The method iterates through animation data, generates animation resources,
    /// and applies them to corresponding entities.
    ///
    /// The total execution time is calculated based on animation duration,
    /// speed, delay, and repeat count.
    ///
    /// - Parameter entity_animations: A list of animation data.
    /// - Returns: Total time required to complete all animations.
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
    
    /// Generates animation data for a given operation code.
    ///
    /// Subclasses override this method to define mapping between
    /// operation codes and animation sequences.
    ///
    /// - Parameter code: An operation code.
    /// - Returns: A list of animation data.
    /// - Throws: An error if generation fails.
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
                //print(error.localizedDescription)
            }
        }
    }
    
    /// Generates animation data for a given operation code.
    ///
    /// Subclasses override this method to define mapping between
    /// operation codes and animation sequences.
    ///
    /// - Parameter code: An operation code.
    /// - Returns: A list of animation data.
    /// - Throws: An error if generation fails.
    open func entity_animations(code: Int) throws -> [EntityAnimationData]
    {
        return []
    }
    
    /// Stops all animations for connected entities.
    ///
    /// This method resets the visual model to a non-animated state.
    public func reset_entities()
    {
        for (_, entity) in entities // Remove all node actions
        {
            entity.stopAllAnimations()
        }
    }
}

// MARK: - External Model Controller
/// A tool model controller driven by external JavaScript logic.
///
/// `ExternalToolModelController` extends ``ToolModelController`` by
/// delegating animation generation and state computation to a
/// JavaScript environment.
///
/// This enables dynamic definition of tool behavior and animation
/// sequences without recompilation.
/// 
open class ExternalToolModelController: ToolModelController, @unchecked Sendable
{
    // MARK: Init functions
    /// Creates a default external tool model controller.
    required public init() {}
    
    /// Creates an external tool model controller.
    ///
    /// - Parameters:
    ///   - entity_names: Names of entities used in the model.
    ///   - code: JavaScript code defining animation behavior.
    public init(
        entity_names: [String],
        
        code: String
    )
    {
        self.external_entity_names = entity_names
        
        self.js_environment.js_code = code
    }
    
    open override func copy() -> Self
    {
        let copy = type(of: self).init()
        
        copy.external_entity_names = external_entity_names
        copy.code = code
        
        return copy
    }
    
    // MARK: JavaScript Handling
    /// Resets the JavaScript execution context.
    private var js_environment = JSEnvironment()
    
    /// JavaScript code defining tool behavior.
    ///
    /// Updating this value rebuilds the scripting environment.
    public func reset_js_context()
    {
        js_environment.reset_context()
    }
    
    /// Generates animation data using JavaScript.
    ///
    /// The method calls a JS function `entity_animations`,
    /// decodes the returned JSON, and converts it into animation data.
    ///
    /// - Parameter code: An operation code.
    /// - Returns: A list of animation data.
    public var code: String
    {
        get { js_environment.js_code }
        set { js_environment.js_code = newValue }
    }
    
    // MARK: Modeling
    public var external_entity_names = [String]()
    
    override open var entity_names: [String]
    {
        return external_entity_names
    }
    
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
            //print(error.localizedDescription)
            return []
        }
    }
    
    // MARK: Device Output
    /// Current device output generated by JavaScript.
    ///
    /// The method calls a JS function `current_device_output`
    /// and decodes the result into ``DeviceOutputData``.
    open override var current_device_output: DeviceOutputData?
    {
        do
        {
            let json_string = try js_environment.call_js_func(
                name: "current_device_output"
            )
            
            guard let json_data = json_string.data(using: .utf8)
            else
            {
                //print("Failed to convert JS output to Data: \(json_string)")
                return nil
            }
            
            let state = try JSONDecoder().decode(DeviceOutputData.self, from: json_data)
            return state
        }
        catch
        {
            //print("JS current_device_output error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Initial device output generated by JavaScript.
    ///
    /// The method calls a JS function `initial_device_output`
    /// and decodes the result into ``DeviceOutputData``.
    open override var initial_device_output: DeviceOutputData?
    {
        do
        {
            let json_string = try js_environment.call_js_func(
                name: "initial_device_output"
            )
            
            guard let json_data = json_string.data(using: .utf8)
            else
            {
                //print("Failed to convert JS output to Data: \(json_string)")
                return nil
            }
            
            let state = try JSONDecoder().decode(DeviceOutputData.self, from: json_data)
            return state
        }
        catch
        {
            //print("JS initial_device_output error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Entity Animation Data
/// A structure describing animation parameters for an entity.
///
/// `EntityAnimationData` defines transformation and timing properties
/// used to animate a specific entity within the visual model.
///
/// It includes:
/// - Target entity name
/// - Position and rotation (pose)
/// - Scale
/// - Timing parameters (duration, delay, speed)
/// - Repeat behavior
///
public struct EntityAnimationData: Codable
{
    /// An optional name of the target entity.
    ///
    /// Identifies the entity in the model to which the transformation
    /// or animation will be applied.
    ///
    /// The name is used to match data with a corresponding entity in
    /// the controller’s ``ModelController/entities`` dictionary.
    ///
    public var entity_name: String
    
    /// Position and rotation of the entity.
    ///
    /// Contains translation (*x, y, z*) and orientation (*r, p, w*)
    /// components used to build the target transform.
    public var position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (0, 0, 0, 0, 0, 0)
    
    /// Scale of the entity.
    ///
    /// Defines scaling factors along each axis (*x, y, z*).
    public var scale: (x: Float, y: Float, z: Float) = (1, 1, 1)
    
    /// Animation duration in seconds.
    public var duration: Double = 1
    
    /// Timing function describing animation interpolation.
    public var timing_function: TimingFunction = .linear
    
    /// Delay before animation starts in seconds.
    public var delay: Double = 0
    
    /// Playback speed multiplier.
    ///
    /// Values greater than 1 accelerate animation,
    /// while values less than 1 slow it down.
    public var speed: Float = 1
    
    /// Number of animation repetitions.
    ///
    /// - `nil`: Infinite repetition
    /// - `0`: No animation
    /// - `1`: Single execution (default)
    public var repeat_count: Int?// = 1 //nil – infinity
    
    /// Creates animation data for an entity.
    ///
    /// - Parameters:
    ///   - entity_name: A target entity name.
    ///   - position: Position and rotation components.
    ///   - scale: Scale components.
    ///   - duration: Animation duration.
    ///   - timing_function: Timing function of animation.
    ///   - delay: Delay before animation starts.
    ///   - speed: Playback speed.
    ///   - repeat_count: Number of repetitions (`nil` for infinite).
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
    
    // MARK: File Data
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
        
        repeat_count = try container.decodeIfPresent(Int.self, forKey: .repeat_count) ?? nil
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

/// A type defining animation timing functions.
///
/// `TimingFunction` specifies how animation progress evolves over time.
///
public enum TimingFunction: Codable
{
    /// A linear timing function.
    case linear
    
    /// An accelerating timing function.
    case ease_in
    
    /// A decelerating timing function.
    case ease_out
    
    /// A combined acceleration and deceleration timing function.
    case ease_in_out
}

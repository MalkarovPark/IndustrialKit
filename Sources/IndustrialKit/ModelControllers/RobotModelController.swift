//
//  RobotModelController.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import RealityKit

/// A controller that manages the visual and kinematic model of a robot.
///
/// `RobotModelController` extends ``ModelController`` to provide
/// robot-specific functionality, including kinematic updates,
/// pointer handling, and motion simulation.
///
/// The controller translates target positions into transformations
/// of individual model entities, enabling visualization of robot motion
/// within a workspace.
///
/// Subclasses implement inverse kinematics or custom transformation logic
/// by overriding ``entity_positions(pointer_position:origin_position:)``.
///
open class RobotModelController: ModelController, @unchecked Sendable
{
    // MARK: - Robot Model
    /// Updates the robot model based on pointer and origin positions.
    ///
    /// The method transforms the target pointer position into the workspace
    /// coordinate system, computes entity transformations, and applies them
    /// to the visual model.
    ///
    /// - Parameters:
    ///   - pointer_position: Target position and orientation (*x, y, z, r, p, w*).
    ///   - origin_position: Workspace origin position and orientation.
    /// - Throws: An error if kinematic computation fails.
    public func update_robot_model(
        pointer_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        ),
        origin_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        )
    ) throws
    {
        do
        {
            let entity_positions = try entity_positions(
                pointer_position:
                    origin_transform(
                        pointer_position: pointer_position,
                        origin_position: origin_position
                    ),
                origin_position: origin_position
            )
            
            apply_entity_positions(by: entity_positions)
        }
        catch
        {
            throw error
        }
    }
    
    /// Applies computed entity transformations to the visual model.
    ///
    /// The method iterates over provided transformation data and updates
    /// corresponding entities asynchronously on the main actor.
    ///
    /// Entities that are not present in the controller are ignored.
    ///
    /// - Parameter entity_positions: A list of entity transformation data.
    public func apply_entity_positions(by entity_positions: [EntityPositionData])
    {
        Task
        { @MainActor in
            for entity_position in entity_positions
            {
                apply_entity_position(by: entity_position)
            }
        }
        
        @MainActor func apply_entity_position(by data: EntityPositionData)
        {
            guard let entity = entities[data.name ?? String()] else { return }
            
            entity.transform = Transform(
                scale: entity.transform.scale,
                rotation:
                    simd_quatf(angle: data.position.r.to_rad, axis: SIMD3(1,0,0)) *
                simd_quatf(angle: data.position.p.to_rad, axis: SIMD3(0,0,1)) *
                simd_quatf(angle: data.position.w.to_rad, axis: SIMD3(0,1,0)),
                translation: SIMD3(
                    data.position.x,
                    data.position.z,
                    data.position.y
                )
            )
        }
    }
    
    /// Computes entity transformations for the robot model.
    ///
    /// Subclasses override this method to implement kinematic models,
    /// converting pointer and origin positions into per-entity transforms.
    ///
    /// - Parameters:
    ///   - pointer_position: Target position and orientation.
    ///   - origin_position: Workspace origin position.
    /// - Returns: A list of entity transformation data.
    /// - Throws: An error if computation fails.
    open func entity_positions(
        pointer_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        ),
        origin_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        )
    ) throws -> [EntityPositionData]
    {
        return []
    }
    
    // MARK: - Pointer
    /// Current robot pointer position.
    ///
    /// Represents the target pose of the robot end-effector,
    /// including translation (*x, y, z*) and orientation (*r, p, w*).
    public var pointer_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// Updates the pointer entity transform in the scene.
    ///
    /// The update is performed asynchronously on the main actor.
    public func update_pointer_position()
    {
        Task
        { @MainActor in
            pointer_entity?.update_position(pointer_position)
        }
        //pointer_entity?.update_position(pointer_position)
    }
    
    /// A visual entity representing the robot pointer.
    public var pointer_entity: Entity?
    
    // MARK: - Operational Space
    /// The origin position of the robot workspace.
    ///
    /// Defines the base coordinate system for all robot transformations,
    /// including translation and orientation.
    public var origin_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// The dimensions of the robot working space.
    ///
    /// Defines the size of the operational volume along each axis.
    public var space_scale: (
        x: Float, y: Float, z: Float
    ) = (x: 200, y: 200, z: 200)
    
    // MARK: - Entities
    /// Connects model entities and assigns a pointer entity.
    ///
    /// - Parameters:
    ///   - entity: Root entity of the robot model.
    ///   - pointer_entity: Entity representing the pointer.
    public func connect_entities(_ entity: Entity, pointer_entity: Entity)
    {
        connect_entities(of: entity)
        self.pointer_entity = pointer_entity
    }
    
    /// Disconnects all model entities and resets the pointer entity.
    public override func disconnect_entities()
    {
        entities.removeAll()
        pointer_entity = Entity()
    }
    
    /// Updates the robot model using the current pointer position.
    ///
    /// This method recomputes entity transforms and applies them
    /// to the visual model.
    ///
    /// - Throws: An error if update fails.
    public func update_model() throws
    {
        //update_pointer_position()//pointer_position) // Target pointer pointer
        
        do
        {
            try update_robot_model(pointer_position: pointer_position, origin_position: origin_position) // Robot part positions
        }
        catch
        {
            throw error
        }
    }
    
    /// Performs robot movement toward a target point.
    ///
    /// The movement is executed incrementally, interpolating both
    /// position and orientation over a number of steps.
    ///
    /// - Parameter point: A target position point.
    /// - Throws: An error if movement fails.
    open func move_to(point: PositionPoint) throws
    {
        let parts_count: Int = 1000 // Trajectory steps calculation
        
        let current_position = pointer_position
        
        let delta_x: Float = point.x - current_position.x
        let delta_y: Float = point.y - current_position.y
        let delta_z: Float = point.z - current_position.z
        
        let delta_r: Float = point.r - current_position.r
        let delta_p: Float = point.p - current_position.p
        let delta_w: Float = point.w - current_position.w
        
        let distance_xyz: Double = sqrt(
            pow(Double(delta_x), 2) +
            pow(Double(delta_y), 2) +
            pow(Double(delta_z), 2)
        )
        
        let distance_rpw: Double = sqrt(
            pow(Double(delta_r), 2) +
            pow(Double(delta_p), 2) +
            pow(Double(delta_w), 2)
        )
        
        let total_distance: Double = max(distance_xyz, distance_rpw)
        
        let move_speed: Double = Double(point.move_speed)
        guard move_speed > 0, parts_count > 0 else
        {
            return
        }
        
        let total_time: Double = total_distance / move_speed
        let part_time: Double = total_time / Double(parts_count)
        
        let step_x: Float = delta_x / Float(parts_count)
        let step_y: Float = delta_y / Float(parts_count)
        let step_z: Float = delta_z / Float(parts_count)
        
        let step_r: Float = delta_r / Float(parts_count)
        let step_p: Float = delta_p / Float(parts_count)
        let step_w: Float = delta_w / Float(parts_count)
        
        for _ in 0..<parts_count // Incremental movement
        {
            var new_position = pointer_position
            
            new_position.x += step_x
            new_position.y += step_y
            new_position.z += step_z
            
            new_position.r += step_r
            new_position.p += step_p
            new_position.w += step_w
            
            pointer_position = new_position
            
            update_pointer_position()
            do { try update_model() } catch { throw error }
            
            usleep(UInt32(part_time * 1_000_000))
            
            if canceled { break }
        }
        
        if !canceled // Final step to point
        {
            pointer_position = (
                x: point.x, y: point.y, z: point.z,
                r: point.r, p: point.p, w: point.w
            )
            
            update_pointer_position()
            do { try update_model() } catch { throw error }
        }
    }
    
    /// Indicates whether the current movement operation is canceled.
    public var canceled = false
    
    private var moving_task = Task<Void, Error> {}
    
    /// Performs robot movement with a completion handler.
    ///
    /// - Parameters:
    ///   - point: A target position point.
    ///   - completion: A closure called when performing completes.
    public func move_to(
        point: PositionPoint,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    )
    {
        canceled = false
        
        moving_task = Task
        {
            do
            {
                try self.move_to(point: point)
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
}

//MARK: - External Controller
/// A robot model controller driven by external scripting logic.
///
/// `ExternalRobotModelController` extends ``RobotModelController`` by
/// delegating kinematic computation and state generation to a JavaScript
/// environment.
///
/// This enables dynamic definition of robot behavior without recompilation,
/// supporting flexible integration of external algorithms.
open class ExternalRobotModelController: RobotModelController, @unchecked Sendable
{
    /// Creates a default external robot model controller.
    required public init() {}
    
    // MARK: Initializers
    /// Creates an external robot model controller.
    ///
    /// - Parameters:
    ///   - entity_names: Names of entities used in the model.
    ///   - code: JavaScript code defining kinematics and output logic.
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
    private var js_environment = JSEnvironment()
    
    /// Resets the JavaScript execution context.
    public func reset_js_context()
    {
        js_environment.reset_context()
    }
    
    /// JavaScript code defining controller behavior.
    ///
    /// Updating this value rebuilds the scripting environment.
    public var code: String
    {
        get { js_environment.js_code }
        set { js_environment.js_code = newValue }
    }
    
    // MARK: Modeling
    /// Names of entities used for model connection.
    ///
    /// Returns externally defined entity names.
    override open var entity_names: [String]
    {
        return external_entity_names
    }
    
    /// A list of entity names provided by the external configuration.
    public var external_entity_names = [String]()
    
    /// Computes entity transformations using JavaScript.
    ///
    /// The method calls a JS function `entity_positions`,
    /// decodes the returned JSON, and converts it into
    /// entity transformation data.
    ///
    /// - Parameters:
    ///   - pointer_position: Target position and orientation.
    ///   - origin_position: Workspace origin.
    /// - Returns: A list of entity transformation data.
    /// - Throws: An error if script execution fails.
    override open func entity_positions(
        pointer_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        ),
        origin_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        )
    ) throws -> [EntityPositionData]
    {
        // Wrap 12 numbers in a single array for JS
        let args: [Any] = [[
            pointer_position.x, pointer_position.y, pointer_position.z,
            pointer_position.r, pointer_position.p, pointer_position.w,
            origin_position.x, origin_position.y, origin_position.z,
            origin_position.r, origin_position.p, origin_position.w
        ]]
        
        // Call JS function
        let result_string = try js_environment.call_js_func(name: "entity_positions", args: args)
        
        // Decode JSON returned from JS
        guard let data = result_string.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([EntityPositionData].self, from: data)
        else { return [] }
        
        // Map decoded objects to tuple array
        return decoded
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

// MARK: - Entity Position Data
/// A structure describing transformation data for an entity.
///
/// `EntityPositionData` defines a named entity and its target pose,
/// including translation and rotation components.
///
/// This structure is used as an intermediate representation between
/// kinematic computation and visual model updates.
public struct EntityPositionData: Codable, Sendable
{
    /// An optional name of the target entity.
    ///
    /// The name is used to match transformation data with a corresponding
    /// entity in the controller's ``ModelController/entities`` dictionary.
    ///
    /// If `nil`, the transformation may be ignored or handled by custom logic.
    let name: String?
    
    let x, y, z, r, p, w: Float
    
    /// A pose representation containing position and orientation.
    public struct Pose
    {
        let x, y, z, r, p, w: Float
    }
    
    /// A computed pose derived from stored transformation values.
    var position: Pose
    {
        Pose(x: x, y: y, z: z, r: r, p: p, w: w)
    }
    
    /// Creates an entity position data instance.
    ///
    /// - Parameters:
    ///   - name: An optional entity name.
    ///   - position: A tuple containing position and rotation components.
    public init(
        name: String? = nil,
        position: (
            x: Float,
            y: Float,
            z: Float,
            
            r: Float,
            p: Float,
            w: Float
        ) = (0,0,0,0,0,0)
    )
    {
        self.name = name
        
        self.x = position.x
        self.y = position.y
        self.z = position.z
        
        self.r = position.r
        self.p = position.p
        self.w = position.w
    }
    
    enum CodingKeys: String, CodingKey
    {
        case name
        case position
    }
    
    enum PositionKeys: String, CodingKey
    {
        case x, y, z, r, p, w
    }
    
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        let pos = try container.nestedContainer(keyedBy: PositionKeys.self, forKey: .position)
        x = try pos.decode(Float.self, forKey: .x)
        y = try pos.decode(Float.self, forKey: .y)
        z = try pos.decode(Float.self, forKey: .z)
        r = try pos.decode(Float.self, forKey: .r)
        p = try pos.decode(Float.self, forKey: .p)
        w = try pos.decode(Float.self, forKey: .w)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        var pos = container.nestedContainer(keyedBy: PositionKeys.self, forKey: .position)
        try pos.encode(x, forKey: .x)
        try pos.encode(y, forKey: .y)
        try pos.encode(z, forKey: .z)
        try pos.encode(r, forKey: .r)
        try pos.encode(p, forKey: .p)
        try pos.encode(w, forKey: .w)
    }
}

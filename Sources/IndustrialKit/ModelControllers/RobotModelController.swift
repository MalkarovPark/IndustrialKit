//
//  RobotModelController.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import RealityKit

///Provides control over visual model for robot.
open class RobotModelController: ModelController, @unchecked Sendable
{
    /**
     Updates entities positions of robot model by target position and origin parameters.
     
     - Parameters:
        - pointer_location: The target position location components – *x*, *y*, *z*.
        - pointer_rotation: The target position rotation components – *r*, *p*, *w*.
        - origin_location: The workcell origin location components – *x*, *y*, *z*.
        - origin_rotation: The workcell origin rotation components – *r*, *p*, *w*.
     
     > Pre-transforms the position in space depending on the rotation of the tool coordinate system.
     */
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
    
    /**
     Applies a list of entity positions to the corresponding entities in the scene.
     
     - Parameters:
        - entity_positions: An array of `EntityPositionData`, each containing the name, position, and rotation of an entity to apply.
     
     Updates are applied asynchronously on the main actor. Entities with names not present
     in `entities` are skipped.
     */
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
    
    /**
     Updates entities positions of robot model by target position and origin parameters.
     
     - Parameters:
        - pointer_location: The target position location components – *x*, *y*, *z*.
        - pointer_rotation: The target position rotation components – *r*, *p*, *w*.
        - origin_location: The workcell origin location components – *x*, *y*, *z*.
        - origin_rotation: The workcell origin rotation components – *r*, *p*, *w*.
     */
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
    
    // MARK: Pointer
    /**
     A robot pointer position.
     
     Tuple with three coordinates – *x*, *y*, *z* and three angles – *r*, *p*, *w*.
     */
    public var pointer_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /**
     Updates the pointer’s position and orientation in the scene.
     
     - Parameters:
     - pos_x: The X coordinate of the pointer's position.
     - pos_y: The Y coordinate of the pointer's position.
     - pos_z: The Z coordinate of the pointer's position.
     - rot_x: Rotation about the X-axis, in radians.
     - rot_y: Rotation about the Y-axis, in radians.
     - rot_z: Rotation about the Z-axis, in radians.
     */
    public func update_pointer_position(
        /*_ position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        )*/
    )
    {
        Task
        { @MainActor in
            pointer_entity?.update_position(pointer_position)
        }
        //pointer_entity?.update_position(pointer_position)//position)
    }
    
    /// Robot teach pointer.
    public var pointer_entity: Entity?
    
    /// Node for internal element.
    public var pointer_entity_internal: Entity?
    
    // MARK: Operational Space
    /**
     A robot cell origin position.
     
     Tuple with coordinates – *x*, *y*, *z* and angles – *r*, *p*, *w*.
     */
    public var origin_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// A robot cell box scale.
    public var space_scale: (
        x: Float, y: Float, z: Float
    ) = (x: 200, y: 200, z: 200)
    
    // MARK: Device
    /**
     Gets parts entities links from model root node and pass to array.
     
     - Parameters:
        - entity: A root entity of workspace object model.
        - pointer: A node of pointer for robot.
     */
    public func connect_entities(_ entity: Entity, pointer_entity: Entity)
    {
        connect_entities(of: entity)
        self.pointer_entity = pointer_entity
    }
    
    public override func disconnect_entities()
    {
        entities.removeAll()
        pointer_entity = Entity()
    }
    
    /// Update pointer position and robot entity positions by target point.
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
    
    /**
     Performs robot model movement by target position.
     
     - Parameters:
        - point: The target position performed by the robot visual model.
     */
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
    
    /// Cancel perform flag.
    public var canceled = false
    
    private var moving_task = Task<Void, Error> {}
    
    /**
     Performs robot model movement by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the robot visual model.
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
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
open class ExternalRobotModelController: RobotModelController, @unchecked Sendable
{
    /// Clone model controller instance.
    open override func copy() -> Self
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
        return decoded//.map { ($0.name, ($0.position.x, $0.position.y, $0.position.z, $0.position.r, $0.position.p, $0.position.w)) }
    }
    
    // MARK: Statistics
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
                print("Failed to convert JS output to Data: \(json_string)")
                return nil
            }
            
            let state = try JSONDecoder().decode(DeviceOutputData.self, from: json_data)
            return state
        }
        catch
        {
            print("JS current_device_output error: \(error.localizedDescription)")
            return nil
        }
    }

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
                print("Failed to convert JS output to Data: \(json_string)")
                return nil
            }
            
            let state = try JSONDecoder().decode(DeviceOutputData.self, from: json_data)
            return state
        }
        catch
        {
            print("JS initial_device_output error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Animation Storage
public struct EntityPositionData: Codable, Sendable
{
    let name: String?
    let x, y, z, r, p, w: Float
    
    public struct Pose
    {
        let x, y, z, r, p, w: Float
    }
    
    var position: Pose
    {
        Pose(x: x, y: y, z: z, r: r, p: p, w: w)
    }
    
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

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
    public func update_entities(pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float),
                             origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)) throws
    {
        do
        {
            try update_entities_positions(pointer_position: origin_transform(pointer_position: pointer_position,
                                                                          origin_position: origin_position),
                                       origin_position: origin_position)
        }
        catch
        {
            throw error
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
    open func update_entities_positions(pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float),
                                     origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)) throws
    {
        
    }
    
    // MARK: Pointer
    /**
     A robot pointer position.
     
     Tuple with three coordinates – *x*, *y*, *z* and three angles – *r*, *p*, *w*.
     */
    public var pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
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
    public func update_pointer_position(_ position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float))
    {
        // Apply origin shift
        var position = position
        position.x += origin_shift.x
        position.y += origin_shift.y
        position.z += origin_shift.z
        
        pointer_entity?.update_position(position)
    }
    
    public var origin_shift: (x: Float, y: Float, z: Float) = (x: 0, y: 0, z: 0)
    
    /// Robot teach pointer.
    public var pointer_entity: Entity?
    
    /// Node for internal element.
    public var pointer_entity_internal: Entity?
    
    // MARK: Alt pointer
    /**
     A robot alt pointer location.
     
     Tuple with three coordinates – *x*, *y*, *z* and three angles – *r*, *p*, *w*.
     */
    public var alt_pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            update_alt_pointer()
        }
    }
    
    /// Updates alt pointer position by target point.
    private func update_alt_pointer()
    {
        update_alt_pointer_position(alt_pointer_position)
    }
    
    /**
     Updates the alt pointer’s position and orientation in the scene.
     
     - Parameters:
     - pos_x: The X coordinate of the pointer's position.
     - pos_y: The Y coordinate of the pointer's position.
     - pos_z: The Z coordinate of the pointer's position.
     - rot_x: Rotation about the X-axis, in radians.
     - rot_y: Rotation about the Y-axis, in radians.
     - rot_z: Rotation about the Z-axis, in radians.
     */
    private func update_alt_pointer_position(_ position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float))
    {
        alt_pointer_entity?.update_position(position)
    }
    
    /// Robot alt teach pointer.
    public var alt_pointer_entity: Entity?
    
    /// Toggles view for alt pointer.
    public func toggle_alt_pointer(_ hidden: Bool)
    {
        alt_pointer_entity?.isEnabled = !hidden
        
        if hidden
        {
            // to demo
            pointer_position = alt_pointer_position
            do
            {
                try update_model()
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        else
        {
            // to real
            alt_pointer_position = pointer_position
        }
    }
    
    // MARK: Workcell
    /**
     A robot cell origin position.
     
     Tuple with coordinates – *x*, *y*, *z* and angles – *r*, *p*, *w*.
     */
    public var origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// A robot cell box scale.
    public var space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    
    // MARK: Device
    /// Update robot manipulator parts positions by target point.
    public func update_model() throws
    {
        update_pointer_position(pointer_position)
        
        do
        {
            try update_entities_by_pointer_position()
        }
        catch
        {
            throw error
        }
    }
    
    /// Updates robot entities by current pointer and origin parameters.
    public func update_entities_by_pointer_position() throws
    {
        do
        {
            try update_entities(pointer_position: pointer_position, origin_position: origin_position)
        }
        catch
        {
            throw error
        }
    }
    
    /**
     Gets parts entities links from model root node and pass to array.
     
     - Parameters:
        - node: A root node of workspace object model.
        - pointer: A node of pointer for robot.
     */
    public func connect_entities(_ entity: Entity, pointer_entity: Entity)
    {
        connect_entities(of: entity)
        self.pointer_entity = pointer_entity
        
        /*connect_entities(of: node)
        
        pointer_node = pointer
        pointer_node_internal = pointer_internal
        
        alt_pointer_node?.removeFromParentNode()
        
        alt_pointer_node = pointer.deep_clone()
        alt_pointer_node?.opacity = 0.25
        alt_pointer_node?.isHidden = true
        
        if let parent_node = pointer.parent, let alt_pointer_node = alt_pointer_node
        {
            parent_node.addChildNode(alt_pointer_node)
        }*/
    }
    
    public override func disconnect_entities()
    {
        entities.removeAll()
        pointer_entity = Entity()
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
    
    /**
     Performs robot model movement by target position.
     
     - Parameters:
        - point: The target position performed by the robot visual model.
     */
    public func move_to(point: PositionPoint) throws
    {
        let parts_count: Int = 1000
        
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
        
        for _ in 0..<parts_count
        {
            var new_position = pointer_position
            
            new_position.x += step_x
            new_position.y += step_y
            new_position.z += step_z
            
            new_position.r += step_r
            new_position.p += step_p
            new_position.w += step_w
            
            pointer_position = new_position
            do
            {
                try update_model()
            }
            catch
            {
                throw error
            }
            
            usleep(UInt32(part_time * 1_000_000))
            
            if canceled
            {
                break
            }
        }
        
        if !canceled
        {
            pointer_position = (x: point.x, y: point.y, z: point.z,
                                r: point.r, p: point.p, w: point.w)
            do
            {
                try update_model()
            }
            catch
            {
                throw error
            }
        }
    }
    
    open override func reset_entities()
    {
        
    }
    
    /**
     Applies position updates to scene entities based on a list of string commands.
     
     Each string in `lines` must be in the format `"nodeName position"`, where:
     - `nodeName` is the identifier of the node to update.
     - `position` is a string describing the new position (e.g., coordinates).
     
     The updates are applied asynchronously on the main thread.
     
     - Parameter lines: An array of strings, each containing a node name and its target position separated by a space.
     */
    public func apply_entities_positions(by lines: [String])
    {
        #if os(macOS)
        let updates: [(String, String)] = lines.compactMap
        {
            let components = $0.split(separator: " ", maxSplits: 1).map { String($0) }
            return components.count == 2 ? (components[0], components[1]) : nil
        }
        
        /*DispatchQueue.main.async
        {
            for (node_name, action_string) in updates
            {
                set_position(for: self.entities[safe: node_name, default: Entity()], from: action_string)
            }
            
            self.is_entities_updating = false
        }*/
        #endif
    }
    
    #if os(macOS)
    internal var is_entities_updating = false
    #endif
}

//MARK: - External Controller
public class ExternalRobotModelController: RobotModelController, @unchecked Sendable
{
    // MARK: Init functions
    /// An external module name.
    public var module_name: String
    
    /// For access to code.
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL, entities_names: [String])
    {
        self.module_name = module_name
        self.package_url = package_url
        
        self.external_entities_names = entities_names
    }
    
    required init()
    {
        self.module_name = ""
        self.package_url = URL(fileURLWithPath: "")
    }
    
    // MARK: Parameters import
    override open var entities_names: [String]
    {
        return external_entities_names
    }
    
    public var external_entities_names = [String]()
    
    // MARK: Modeling
    override open func update_entities_positions(pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float),
                                              origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float))
    {
        #if os(macOS)
        guard !is_entities_updating else { return }
        is_entities_updating = true
        
        DispatchQueue.global(qos: .utility).async
        {
            let pointer_position: [String] =
            [
                "\(pointer_position.x)", "\(pointer_position.y)", "\(pointer_position.z)",
                "\(pointer_position.r)", "\(pointer_position.p)", "\(pointer_position.w)"
            ]

            let origin_position: [String] =
            [
                "\(origin_position.x)",  "\(origin_position.y)",  "\(origin_position.z)",
                "\(origin_position.r)",  "\(origin_position.p)",  "\(origin_position.w)"
            ]

            send_via_unix_socket(at:   "/tmp/\(self.module_name)_robot_controller_socket", with: ["update_entities_positions"] + (pointer_position + origin_position).map { "\($0)" })
            { output in
                self.apply_entities_positions(by: output.split(separator: "\n").map { String($0) })
            }
        }
        #endif
    }
    
    open override func reset_entities()
    {
        #if os(macOS)
        send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_controller_socket", with: ["reset_entities"])
        { output in
            self.apply_entities_positions(by: output.split(separator: "\n").map { String($0) })
        }
        #endif
    }
    
    // MARK: Statistics
    open override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_controller_socket", with: ["updated_charts_data"])
        else
        {
            return nil
        }
        
        if let charts: [WorkspaceObjectChart] = string_to_codable(from: output)
        {
            return charts
        }
        #endif
        
        return nil
    }
    
    open override func updated_states_data() -> [StateItem]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_controller_socket", with: ["updated_states_data"])
        else
        {
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            return states
        }
        #endif
        
        return nil
    }
    
    open override func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_controller_socket", with: ["initial_charts_data"])
        else
        {
            return nil
        }
        
        if let charts: [WorkspaceObjectChart] = string_to_codable(from: output)
        {
            return charts
        }
        #endif
        
        return nil
    }
    
    open override func initial_states_data() -> [StateItem]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_controller_socket", with: ["initial_states_data"])
        else
        {
            return nil
        }
        
        if let states: [StateItem] = string_to_codable(from: output)
        {
            return states
        }
        #endif
        
        return nil
    }
}

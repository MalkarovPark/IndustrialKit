//
//  RobotModelController.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import SceneKit

///Provides control over visual model for robot.
open class RobotModelController: ModelController
{
    /**
     Updates nodes positions of robot model by target position and origin parameters.
     
     - Parameters:
        - pointer_location: The target position location components – *x*, *y*, *z*.
        - pointer_rotation: The target position rotation components – *r*, *p*, *w*.
        - origin_location: The workcell origin location components – *x*, *y*, *z*.
        - origin_rotation: The workcell origin rotation components – *r*, *p*, *w*.
     
     > Pre-transforms the position in space depending on the rotation of the tool coordinate system.
     */
    public func update_nodes(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float])
    {
        update_nodes_positions(pointer_location: origin_transform(pointer_location: pointer_location, origin_rotation: origin_rotation), pointer_rotation: pointer_rotation, origin_location: origin_location, origin_rotation: origin_rotation)
    }
    
    /**
     Updates nodes positions of robot model by target position and origin parameters.
     
     - Parameters:
        - pointer_location: The target position location components – *x*, *y*, *z*.
        - pointer_rotation: The target position rotation components – *r*, *p*, *w*.
        - origin_location: The workcell origin location components – *x*, *y*, *z*.
        - origin_rotation: The workcell origin rotation components – *r*, *p*, *w*.
     */
    open func update_nodes_positions(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float])
    {
        
    }
    
    /// An update pointer node by position data flag.
    //private var update_pointer_node_position = true
    
    /**
     A robot pointer location.
     
     Array with three coordinates – [*x*, *y*, *z*].
     */
    public var pointer_location: [Float] = [0.0, 0.0, 0.0]
    {
        didSet
        {
            update_model()
        }
    }
    
    /**
     A robot pointer rotation.
     
     Array with three angles – [*r*, *p*, *w*].
     */
    public var pointer_rotation: [Float] = [0.0, 0.0, 0.0]
    {
        didSet
        {
            update_model()
        }
    }
    
    /**
     A robot cell origin location.
     
     Array with three coordinates – [*x*, *y*, *z*].
     */
    public var origin_location = [Float](repeating: 0, count: 3)
    
    /**
     A robot cell origin rotation.
     
     Array with three angles – [*r*, *p*, *w*].
     */
    public var origin_rotation = [Float](repeating: 0, count: 3)
    
    /// A robot cell box scale.
    public var space_scale = [Float](repeating: 200, count: 3)
    
    /// Update robot manipulator parts positions by target point.
    private func update_model()
    {
        update_pointer_position(to: converted_pointer_position)
        
        update_nodes(pointer_location: pointer_location, pointer_rotation: pointer_rotation, origin_location: origin_location, origin_rotation: origin_rotation)
    }
    
    /// Robot current pointer position data for nodes.
    private var converted_pointer_position: (location: SCNVector3, rot_x: Float, rot_y: Float, rot_z: Float)
    {
        return(SCNVector3(pointer_location[1], pointer_location[2], pointer_location[0]), pointer_rotation[0].to_rad, pointer_rotation[1].to_rad, pointer_rotation[2].to_rad)
    }
    
    /**
     Updates the pointer’s position and orientation in the 3D scene.
     
     - Parameter pointer_position: A tuple containing the new transform for the pointer:
     - location: The target position of the pointer as an `SCNVector3`.
     - rot_x: Rotation about the X-axis, in radians.
     - rot_y: Rotation about the Y-axis, in radians.
     - rot_z: Rotation about the Z-axis, in radians.
     */
    public func update_pointer_position(to pointer_position: (location: SCNVector3, rot_x: Float, rot_y: Float, rot_z: Float))
    {
        pointer_node?.position = pointer_position.location // Set robot pointer node location
        
        // Set robot pointer node rotation
        #if os(macOS)
        pointer_node?.eulerAngles.x = CGFloat(pointer_position.rot_y)
        pointer_node?.eulerAngles.y = CGFloat(pointer_position.rot_z)
        pointer_node_internal?.eulerAngles.z = CGFloat(pointer_position.rot_x)
        #else
        pointer_node?.eulerAngles.x = pointer_position.rot_y
        pointer_node?.eulerAngles.y = pointer_position.rot_z
        pointer_node_internal?.eulerAngles.z = pointer_position.rot_x
        #endif
    }
    
    /// Robot teach pointer.
    public var pointer_node: SCNNode?
    
    /// Node for internal element.
    public var pointer_node_internal: SCNNode?
    
    /**
     Gets parts nodes links from model root node and pass to array.
     
     - Parameters:
        - node: A root node of workspace object model.
        - pointer: A node of pointer for robot.
        - pointer_internal: A internal node of pointer for robot.
     */
    public func nodes_connect(_ node: SCNNode, pointer: SCNNode, pointer_internal: SCNNode)
    {
        connect_nodes(of: node)
        pointer_node = pointer
        pointer_node_internal = pointer_internal
    }
    
    public override func disconnect_nodes()
    {
        nodes.removeAll()
        pointer_node = SCNNode()
    }
    
    /// Cancel perform flag.
    public var canceled = false
    
    private var moving_task = Task {}
    
    /**
     Performs robot model movement by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the robot visual model.
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping () -> Void)
    {
        canceled = false
        moving_task = Task
        {
            self.move_to(point: point)
            
            if !canceled
            {
                completion()
            }
            canceled = false
        }
    }
    
    /**
     Performs robot model movement by target position.
     
     - Parameters:
        - point: The target position performed by the robot visual model.
     */
    public func move_to(point: PositionPoint)
    {
        let parts_count: Int = 1000
        
        let current_location = pointer_location
        let current_rotation = pointer_rotation
        
        let delta_x: Float = point.x - current_location[0]
        let delta_y: Float = point.y - current_location[1]
        let delta_z: Float = point.z - current_location[2]
        
        let delta_r: Float = point.r - current_rotation[0]
        let delta_p: Float = point.p - current_rotation[1]
        let delta_w: Float = point.w - current_rotation[2]
        
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
            pointer_location[0] += step_x
            pointer_location[1] += step_y
            pointer_location[2] += step_z
            
            pointer_rotation[0] += step_r
            pointer_rotation[1] += step_p
            pointer_rotation[2] += step_w
            
            usleep(UInt32(part_time * 1_000_000))
            
            if canceled
            {
                break
            }
        }
        
        if !canceled
        {
            pointer_location = [point.x, point.y, point.z]
            pointer_rotation = [point.r, point.p, point.w]
        }
    }
    
    private func remove_movement_actions()
    {
        pointer_node?.removeAllActions()
        pointer_node_internal?.removeAllActions()
    }
    
    open override func reset_nodes()
    {
        canceled = true
        remove_movement_actions()
    }
}

//MARK: - External Controller
public class ExternalRobotModelController: RobotModelController
{
    // MARK: Init functions
    /// An external module name.
    public var module_name: String
    
    /// For access to code.
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL, nodes_names: [String])
    {
        self.module_name = module_name
        self.package_url = package_url
        
        self.external_nodes_names = nodes_names
    }
    
    required init()
    {
        self.module_name = ""
        self.package_url = URL(fileURLWithPath: "")
    }
    
    // MARK: Parameters import
    override open var nodes_names: [String]
    {
        return external_nodes_names
    }
    
    public var external_nodes_names = [String]()
    
    // MARK: Modeling
    private var is_nodes_updating = false
    
    override open func update_nodes_positions(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float])
    {
        #if os(macOS)
        guard !is_nodes_updating else { return }
        is_nodes_updating = true
        
        DispatchQueue.global(qos: .utility).async
        {
            send_via_unix_socket(at: "/tmp/\(self.module_name)_robot_controller_socket",
                                 with: ["update_nodes_positions"] + (pointer_location + pointer_rotation + origin_location + origin_rotation).map { "\($0)" })
            { output in
                let lines = output.split(separator: "\n").map { String($0) }
                
                let updates: [(String, String)] = lines.compactMap
                {
                    let components = $0.split(separator: " ", maxSplits: 1).map { String($0) }
                    return components.count == 2 ? (components[0], components[1]) : nil
                }
                
                DispatchQueue.main.async
                {
                    for (node_name, action_string) in updates
                    {
                        set_position(for: self.nodes[safe: node_name, default: SCNNode()], from: action_string)
                    }
                    
                    self.is_nodes_updating = false
                }
            }
        }
        #endif
    }
    
    open override func reset_nodes()
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_controller_socket", with: ["reset_nodes"])
        else
        {
            return
        }
        
        // Split the output into lines
        let lines = output.split(separator: "\n").map { String($0) }

        for line in lines
        {
            // Split the line by space to separate node name and action string
            let components = line.split(separator: " ", maxSplits: 1).map { String($0) }
            
            // Ensure there are two components: the node name and the action string
            guard components.count == 2
            else
            {
                continue
            }
            
            set_position(for: nodes[safe: components[0], default: SCNNode()], from: components[1])
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

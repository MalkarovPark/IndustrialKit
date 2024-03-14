//
//  ModelController.swift
//  IndustrialKit
//
//  Created by Artem on 11.11.2022.
//

import Foundation
import SceneKit

/**
 Provides control over visual model for workspace object.
 
 In a workspace class of controllable object, such as a robot, this controller provides control functionality for the linked node in instance of the workspace object.
 Controller can add SCNaction or update position, angles for any nodes nested in object visual model root node.
 > Model controller does not build the visual model, but can change it according to instance's lengths.
 */
open class ModelController
{
    ///Model nodes from connected root node.
    public var nodes = [SCNNode]()
    
    public init()
    {
        
    }
    
    /**
     Gets parts nodes links from model root node and pass to array.
     
     - Parameters:
        - node: A root node of workspace object model.
     */
    open func nodes_connect(_ node: SCNNode)
    {
        
    }
    
    ///Removes all nodes in object model from controller.
    public func nodes_disconnect()
    {
        nodes.removeAll()
    }
    
    ///Resets nodes position of connected visual model.
    open func reset_model()
    {
        
    }
    
    ///A get statistics flag.
    public var get_statistics = false
    {
        didSet
        {
            if !get_statistics
            {
                clear_charts_data()
            }
        }
    }
    
    ///Returns chart data.
    open func charts_data() -> [WorkspaceObjectChart]?
    {
        return [WorkspaceObjectChart]()
    }
    
    ///Retruns perfroming state info.
    open func state_data() -> [StateItem]?
    {
        return [StateItem]()
    }
    
    ///Clears model chart data.
    open func clear_charts_data()
    {
        
    }
    
    ///Clears model state data.
    open func clear_state_data()
    {
        
    }
}

//MARK: - Model controller implementations
///Provides control over visual model for robot.
open class RobotModelController: ModelController
{
    ///Model nodes lengths.
    public var lengths = [Float]()
    
    /**
     Required count of lengths to transform the connected model.
     
     Сan be overridden depending on the number of lengths used in the transformation.
     */
    open var description_lengths_count: Int { 0 }
    
    ///Sets new values for connected nodes geometries.
    open func update_nodes_lengths()
    {
        
    }
    
    ///Updates connected model nodes scales by instance lengths.
    public final func nodes_transform()
    {
        guard lengths.count == description_lengths_count //Return if current lengths count is not equal required one
        else
        {
            return
        }
        
        update_nodes_lengths()
    }
    
    /**
     Updates robot model nodes by target position.
     
     - Parameters:
        - pointer_location: The target position location components – *x*, *y*, *z*.
        - pointer_rotation: The target position rotation components – *r*, *p*, *w*.
        - origin_location: The workcell origin location components – *x*, *y*, *z*.
        - origin_rotation: The workcell origin rotation components – *r*, *p*, *w*.
     */
    public final func nodes_update(pointer_location: [Float], pointer_roation: [Float], origin_location: [Float], origin_rotation: [Float])
    {
        nodes_update(values: inverse_kinematic_calculate(pointer_location: origin_transform(pointer_location: pointer_location, origin_rotation: origin_rotation), pointer_rotation: pointer_roation, origin_location: origin_location, origin_rotation: origin_rotation))
    }
    
    /**
     Calculates robot model nodes positions by target position.
     
     - Parameters:
        - pointer_location: The target position location components – *x*, *y*, *z*.
        - pointer_rotation: The target position rotation components – *r*, *p*, *w*.
        - origin_location: The workcell origin location components – *x*, *y*, *z*.
        - origin_rotation: The workcell origin rotation components – *r*, *p*, *w*.
     
     - Returns: An array of float values describing the positions of nodes of the robot model.
     */
    open func inverse_kinematic_calculate(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float]) -> [Float]
    {
        return [Float]()
    }
    
    /**
     Updates robot nodes by positional values.
     
     - Parameters:
        - values: A robot nodes positional values.
     */
    open func nodes_update(values: [Float])
    {
        
    }
    
    /**
     A robot pointer location.
     
     Array with three coordinates – [*x*, *y*, *z*].
     */
    public var pointer_location: [Float] = [0.0, 0.0, 0.0]
    {
        didSet
        {
            update_location()
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
            update_rotation()
        }
    }
    
    ///Sets robot pointer node location.
    private func update_location()
    {
        pointer_node?.position = get_pointer_position().location
        
        update_robot()
    }
    
    ///Sets robot pointer node rotation.
    private func update_rotation()
    {
        #if os(macOS)
        pointer_node?.eulerAngles.x = CGFloat(get_pointer_position().rot_y)
        pointer_node?.eulerAngles.y = CGFloat(get_pointer_position().rot_z)
        pointer_node_internal?.eulerAngles.z = CGFloat(get_pointer_position().rot_x)
        #else
        pointer_node?.eulerAngles.x = get_pointer_position().rot_y
        pointer_node?.eulerAngles.y = get_pointer_position().rot_z
        pointer_node_internal?.eulerAngles.z = get_pointer_position().rot_x
        #endif
        
        update_robot()
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
    
    ///A robot cell box scale.
    public var space_scale = [Float](repeating: 200, count: 3)
    
    ///Update robot manipulator parts positions by target point.
    public func update_robot()
    {
        if lengths.count == description_lengths_count
        {
            nodes_update(pointer_location: pointer_location, pointer_roation: pointer_rotation, origin_location: origin_location, origin_rotation: origin_rotation)
        }
    }
    
    ///Returns robot pointer position for nodes.
    private func get_pointer_position() -> (location: SCNVector3, rot_x: Float, rot_y: Float, rot_z: Float)
    {
        return(SCNVector3(pointer_location[1], pointer_location[2], pointer_location[0]), pointer_rotation[0].to_rad, pointer_rotation[1].to_rad, pointer_rotation[2].to_rad)
    }
    
    ///Robot teach pointer.
    public var pointer_node: SCNNode?
    
    ///Node for internal element.
    public var pointer_node_internal: SCNNode?
    
    /**
     Updates robot model by current pointer position.
     
     > Can be used within class, but for normal synchronization in SceneKit it is placed in the public protection level.
     */
    public func update_model() //Call from internal – nodes_move_to function
    {
        pointer_location = [Float(pointer_node?.position.z ?? 0), Float(pointer_node?.position.x ?? 0), Float(pointer_node?.position.y ?? 0)]
        pointer_rotation = [Float(pointer_node_internal?.eulerAngles.z ?? 0).to_deg, Float(pointer_node?.eulerAngles.x ?? 0).to_deg, Float(pointer_node?.eulerAngles.y ?? 0).to_deg]
    }
    
    /**
     Gets parts nodes links from model root node and pass to array.
     
     - Parameters:
        - node: A root node of workspace object model.
        - pointer: A node of pointer for robot.
        - pointer_internal: A internal node of pointer for robot.
     */
    public func nodes_connect(_ node: SCNNode, pointer: SCNNode, pointer_internal: SCNNode)
    {
        nodes_connect(node)
        pointer_node = pointer
        pointer_node_internal = pointer_internal
    }
    
    public override func nodes_disconnect()
    {
        nodes.removeAll()
        pointer_node = SCNNode()
    }
    
    //private var moving_task = Task {}
    
    ///Cancel perform flag.
    private var cancel_task = false
    
    ///Moving finished flag.
    private var moving_finished = false
    
    ///Rotation finished flag.
    private var rotation_finished = false
    
    /**
     Updates connected model nodes scales by lengths.
     
     - Parameters:
        - lengths: The new model nodes lengths.
     */
    public func transform_by_lengths(_ lengths: [Float])
    {
        if lengths.count > 0
        {
            self.lengths = lengths
            nodes_transform()
        }
    }
    
    /**
     Performs robot model action by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the robot visual model.
        - completion: A completion function that is calls when the performing completes.
     */
    public func nodes_move_to(point: PositionPoint, completion: @escaping () -> Void)
    {
        self.moving_finished = false
        self.rotation_finished = false
        self.cancel_task = false
        
        let location_action = SCNAction.move(to: SCNVector3(point.y, point.z, point.x), duration: TimeInterval(location_time))
        
        let rotation_action_r = SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(point.r.to_rad), duration: TimeInterval(rotation_time.r))
        let rotation_action_pw = SCNAction.rotateTo(x: CGFloat(point.p.to_rad), y: CGFloat(point.w.to_rad), z: 0, duration: TimeInterval(rotation_time.p + rotation_time.w))
        
        pointer_node?.runAction(SCNAction.group([location_action, rotation_action_pw]))
        {
            self.moving_finished = true
            check_completion()
        }
        
        pointer_node_internal?.runAction(rotation_action_r)
        {
            self.rotation_finished = true
            check_completion()
        }
        
        func check_completion()
        {
            if (self.moving_finished && self.rotation_finished) || self.cancel_task
            {
                if self.cancel_task
                {
                    self.remove_movement_actions()
                    //self.cancel_task = false
                }
                else
                {
                    completion()
                }
            }
        }
    }
    
    /**
     Updates robot model movement time by end points distance.
     
     - Parameters:
        - point1: The first target point.
        - completion: The second target point.
     */
    public func update_movement_time(point1: PositionPoint, point2: PositionPoint)
    {
        //Calculate time between target point and current location
        let v = point1.move_speed
        let s = distance_between_points(point1: point1, point2: point2)
        
        if v != 0
        {
            location_time = s / v
        }
        else
        {
            location_time = 0
        }
        
        //Calculate time between target point and current rotation
        let rotation_r = abs(point1.r - point2.r)
        let rotation_p = abs(point1.p - point2.p)
        let rotation_w = abs(point1.w - point2.w)
        
        if v != 0
        {
            rotation_time.r = rotation_r / v
            rotation_time.p = rotation_p / v
            rotation_time.w = rotation_w / v
        }
        else
        {
            rotation_time.r = 0
            rotation_time.p = 0
            rotation_time.w = 0
        }
        
        func distance_between_points(point1: PositionPoint, point2: PositionPoint) -> Float
        {
            let x_dist = point1.x - point2.x
            let y_dist = point1.y - point2.y
            let z_dist = point1.z - point2.z
            
            return sqrt(Float(x_dist * x_dist + y_dist * y_dist + z_dist * z_dist))
        }
    }
    
    private var location_time: Float = 0
    private var rotation_time: (r: Float, p: Float, w: Float) = (0, 0, 0)
    
    private func remove_movement_actions()
    {
        pointer_node?.removeAllActions()
        pointer_node_internal?.removeAllActions()
    }
    
    open override func reset_model()
    {
        cancel_task = true
        remove_movement_actions()
    }
}

///Provides control over visual model for robot.
open class ToolModelController: ModelController
{
    /**
     Performs tool model action by operation code value.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool visual model.
     */
    open func nodes_perform(code: Int)
    {
        
    }
    
    /**
     Performs tool model action by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool visual model.
        - completion: A completion function that is calls when the performing completes.
     */
    open func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        nodes_perform(code: code)
        completion()
    }
    
    ///Stops connected model actions performation.
    public final func remove_all_model_actions()
    {
        for node in nodes //Remove all node actions
        {
            node.removeAllActions()
        }
        
        reset_model()
    }
    
    ///Inforamation code updated by model controller.
    public var info_output: [Float]?
}

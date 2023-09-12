//
//  ModelController.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 11.11.2022.
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
    
    ///Model nodes lengths.
    public var lengths = [Float]()
    
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
    public final func nodes_disconnect()
    {
        nodes.removeAll()
    }
    
    ///Resets nodes position of connected visual model.
    open func reset_model()
    {
        
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
    
    /**
     Required count of lengths to transform the connected model.
     
     Сan be overridden depending on the number of lengths used in the transformation.
     */
    open var description_lengths_count: Int { 0 }
    
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
    
    ///Sets new values for connected nodes geometries.
    open func update_nodes_lengths()
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
    open func state() -> [StateItem]?
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
    
    /**
     A robot pointer rotation.
     
     Array with three angles – [*r*, *p*, *w*].
     */
    public var pointer_rotation: [Float] = [0.0, 0.0, 0.0]
    
    ///Robot teach pointer.
    public var pointer_node: SCNNode?
    
    ///Node for internal element.
    public var pointer_node_internal: SCNNode?
    
    public func current_pointer_position_select()
    {
        pointer_location = [Float(pointer_node?.position.z ?? 0), Float(pointer_node?.position.x ?? 0), Float(pointer_node?.position.y ?? 0)]
        pointer_rotation = [Float(pointer_node_internal?.eulerAngles.z ?? 0).to_deg, Float(pointer_node?.eulerAngles.x ?? 0).to_deg, Float(pointer_node?.eulerAngles.y ?? 0).to_deg]
    }
    
    private var moving_task = Task {}
    
    private var cancel_task = false
    
    ///Moving finished flag.
    private var moving_finished = false
    
    ///Rotation finished flag.
    private var rotation_finished = false
    
    private func nodes_move_to(position: PositionPoint, move_time: Float?, rotate_time: Float?, completion: @escaping () -> Void)
    {
        self.moving_finished = false
        self.rotation_finished = false
        self.cancel_task = false
        
        pointer_node?.runAction(position.moving(time: move_time ?? 1).position)
        {
            self.moving_finished = true
            check_completion()
        }
        
        pointer_node_internal?.runAction(position.moving(time: rotate_time ?? 1).rotation)
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
     Performs node action by operation code.
     
     - Parameters:
        - code: The information code of the operation performed by the tool visual model.
     */
    open func nodes_perform(code: Int)
    {
        
    }
    
    /**
     Performs node action by operation code with completion handler.
     
     - Parameters:
        - code: The information code of the operation performed by the tool visual model.
        - completion: A completion block that is calls when the action completes.
     */
    open func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        nodes_perform(code: code)
        completion()
    }
    
    ///Inforamation code updated by model controller.
    public var info_code: Int?
}

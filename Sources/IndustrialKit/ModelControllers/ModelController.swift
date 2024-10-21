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
    
    ///A sequence of nodes names nested within the main node used for model connection.
    public var nodes_names = [String]()
    
    /**
     Gets parts nodes links from model root node and pass to array.
     
     - Parameters:
        - node: A root node of workspace object model.
     */
    open func connect_nodes(of node: SCNNode)
    {
        nodes.removeAll()
        
        for node_name in nodes_names
        {
            if let node = node.childNode(withName: node_name, recursively: true)
            {
                nodes.append(node)
            }
        }
    }
    
    ///Removes all nodes in object model from controller.
    public func disconnect_nodes()
    {
        nodes.removeAll()
    }
    
    ///Resets nodes position of connected visual model.
    open func reset_nodes()
    {
        
    }
    
    //MARK: Statistics handling
    ///A get statistics flag.
    public var get_statistics = false
    {
        didSet
        {
            if !get_statistics
            {
                reset_charts_data()
            }
        }
    }
    
    ///Charts data.
    @Published public var charts_data: [WorkspaceObjectChart]?
    
    ///States data.
    @Published public var states_data: [StateItem]?
    
    ///Performs statistics data update.
    public func update_statistics_data()
    {
        charts_data = updated_charts_data()
        states_data = updated_states_data()
    }
    
    ///Updates charts data.
    open func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        return [WorkspaceObjectChart]()
    }
    
    ///Updates states.
    open func updated_states_data() -> [StateItem]?
    {
        return [StateItem]()
    }
    
    ///Resets charts data to inital state.
    open func reset_charts_data()
    {
        
    }
    
    ///Resets states data to inital state.
    open func reset_states_data()
    {
        
    }
}

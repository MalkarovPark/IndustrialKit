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
 Controller can add SCNAction or update position, angles for any nodes nested in object visual model root node.
 > Model controller does not build the visual model, but can change it according to instance's lengths.
 */
open class ModelController: NSCopying
{
    // MARK: - Initialization
    public init() { }
    
    // MARK: - Scene handling
    /// Dictionary of nodes from the connected root node. Keys are node names.
    public var nodes = [String: SCNNode]()
    
    /// A sequence of node names nested within the main node, used for model connection.
    /// This should be overridden in subclasses to return actual node names.
    open var nodes_names: [String]
    {
        return [String]()
    }
    
    /**
     Connects nodes by finding them in the specified root node and storing them in the `nodes` dictionary.
     
     - Parameters:
        - node: The root node of the workspace object model.
     */
    open func connect_nodes(of node: SCNNode)
    {
        // Clear any existing nodes in the dictionary.
        nodes.removeAll()
        
        // Loop through the node names and find corresponding nodes in the hierarchy.
        for node_name in nodes_names
        {
            if let found_node = node.childNode(withName: node_name, recursively: true)
            {
                // Add the found node to the dictionary.
                nodes[node_name] = found_node
            }
        }
    }
    
    /// Removes all nodes from the `nodes` dictionary, disconnecting them from the controller.
    public func disconnect_nodes()
    {
        nodes.removeAll()
    }
    
    /// Resets the positions of connected nodes in the visual model. Override to provide specific functionality.
    open func reset_nodes() { }
    
    // MARK: - Statistics handling
    /// Flag indicating whether statistics are being collected.
    public var get_statistics = false
    {
        didSet
        {
            // If statistics collection is turned off, reset charts data.
            if !get_statistics
            {
                reset_charts_data()
            }
        }
    }
    
    /// Charts data for the object. Published to allow observation.
    @Published public var charts_data: [WorkspaceObjectChart]?
    
    /// States data for the object. Published to allow observation.
    @Published public var states_data: [StateItem]?
    
    /**
     Updates charts data for the object. Override to provide specific updates.
     
     - Returns: An updated array of `WorkspaceObjectChart`.
     */
    open func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        return [WorkspaceObjectChart]()
    }
    
    /**
     Updates states data of object.
     
     - Returns: An updated array of `StateItem`.
     */
    open func updated_states_data() -> [StateItem]?
    {
        return [StateItem]()
    }
    
    /// Updates statistics data.
    public func update_statistics_data()
    {
        charts_data = updated_charts_data()
        states_data = updated_states_data()
    }
    
    /**
     Provides the initial charts data for the object. Override to customize the initial state.
     
     - Returns: An array of `WorkspaceObjectChart` representing initial charts data.
     */
    open func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        return [WorkspaceObjectChart]()
    }
    
    /**
     Provides the initial states data for the object. Override to customize the initial state.
     
     - Returns: An array of `StateItem` representing initial states data.
     */
    open func initial_states_data() -> [StateItem]?
    {
        return [StateItem]()
    }
    
    /// Resets the charts data to its initial state.
    public func reset_charts_data()
    {
        charts_data = initial_charts_data()
    }
    
    /// Resets the states data to its initial state.
    public func reset_states_data()
    {
        states_data = initial_states_data()
    }
    
    // MARK: - NSCopying Protocol
    /**
     Creates a deep copy of the current instance. Conforms to the `NSCopying` protocol.
     
     - Parameter zone: The zone in which to allocate the copy. Default is `nil`.
     - Returns: A new `ModelController` instance that is a copy of the current instance.
     */
    public func copy(with zone: NSZone? = nil) -> Any
    {
        let copy = ModelController()
        
        // Copy the nodes dictionary (note: SCNNode is a reference type, so this is not a deep copy).
        copy.nodes = self.nodes
        
        // Copy the statistics flag.
        copy.get_statistics = self.get_statistics
        
        // Copy charts and states data. This is shallow copying; ensure deep copying if needed.
        copy.charts_data = self.charts_data
        copy.states_data = self.states_data
        
        return copy
    }
}

//
//  ModelController.swift
//  IndustrialKit
//
//  Created by Artem on 11.11.2022.
//

import Foundation
import RealityKit

/**
 Provides control over visual model for workspace object.
 
 In a workspace class of controllable object, such as a robot, this controller provides control functionality for the linked node in instance of the workspace object.
 Controller can add SCNaction or update position, angles for any nodes nested in object visual model root node.
 > Model controller does not build the visual model, but can change it according to instance's lengths.
 */
open class ModelController: NSCopying
{
    required public init()
    {
        
    }
    
    /// Copy model controller instance.
    open func copy(with zone: NSZone? = nil) -> Any
    {
        return type(of: self).init() as! Self
    }
    
    // MARK: - Scene handling
    /// Model nodes from connected root node.
    public var entities = [String: Entity]()

    /// A sequence of node names nested within the main node used for model connection.
    open var entities_names: [String]
    {
        return [String]()
    }

    /**
     Gets part nodes links from the model root node and adds them to the dictionary.
     
     - Parameters:
        - node: The root node of the workspace object model.
     */
    open func connect_entities(of entity: Entity)
    {
        entities.removeAll()
        
        for entity_name in entities_names
        {
            if let found_entity = entity.childEntity(withName: entity_name, recursively: true)
            {
                entities[entity_name] = found_entity
            }
        }
    }
    
    /// Removes all nodes in object model from controller.
    public func disconnect_entities()
    {
        entities.removeAll()
    }
    
    /// Resets nodes position of connected visual model.
    open func reset_entities()
    {
        
    }
    
    // MARK: - Statistics handling
    /// A get statistics flag.
    public var get_statistics = false
    
    /// Charts data.
    @Published public var charts_data: [WorkspaceObjectChart]?
    
    /// States data.
    @Published public var states_data: [StateItem]?
    
    /// Updates charts data.
    open func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        return [WorkspaceObjectChart]()
    }
    
    /// Updates states.
    open func updated_states_data() -> [StateItem]?
    {
        return [StateItem]()
    }
    
    /// Performs statistics data update.
    public func update_statistics_data()
    {
        charts_data = updated_charts_data()
        states_data = updated_states_data()
    }
    
    /// Initial charts data.
    open func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        return [WorkspaceObjectChart]()
    }
    
    /// Initial states data.
    open func initial_states_data() -> [StateItem]?
    {
        return [StateItem]()
    }
    
    /// Resets charts data to inital state.
    public func reset_charts_data()
    {
        charts_data = initial_charts_data()
    }
    
    /// Resets states data to inital state.
    public func reset_states_data()
    {
        states_data = initial_states_data()
    }
}

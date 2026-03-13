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
open class ModelController
{
    required public init()
    {
        
    }
    
    /// Clone model controller instance.
    open func clone() -> Self
    {
        return type(of: self).init()
    }
    
    // MARK: - Scene handling
    /// Model nodes from connected root node.
    public var entities = [String: Entity]()

    /// A sequence of node names nested within the main node used for model connection.
    open var entity_names: [String]
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
        
        for entity_name in entity_names
        {
            if let found_entity = entity.childEntity(withName: entity_name, recursively: true)
            {
                entities[entity_name] = found_entity
            }
        }
    }
    
    /// Removes all nodes in object model from controller.
    open func disconnect_entities()
    {
        entities.removeAll()
    }
    
    /// Initial entities transform visual model.
    open var inital_entities_transform: [EntityAnimationData]
    {
        return []
    }
    
    // MARK: - Device state data
    /// Updates device state data.
    open var current_device_state: DeviceState?
    {
        // Prepare controller output
        return DeviceState()
    }
    
    /// Initial charts data.
    open var initial_device_state: DeviceState?
    {
        // Reset contoller output
        return nil //DeviceState()
    }
}

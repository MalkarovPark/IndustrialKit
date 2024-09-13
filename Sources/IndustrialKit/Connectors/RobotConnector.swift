//
//  RobotConnector.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation

/**
 This subtype provides control for industrial robot.
 
 Contains special function for movement to point performation.
 */
open class RobotConnector: WorkspaceObjectConnector
{
    private var moving_task = Task {}
    
    /**
     Performs movement on real robot by target position.
     
     - Parameters:
        - point: The target position performed by the real robot.
     */
    open func move_to(point: PositionPoint)
    {
        
    }
    
    /**
     Performs movement on real robot by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the real robot.
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
                //canceled = true
                completion()
            }
            canceled = false
        }
    }
    
    ///A robot model controller.
    public var model_controller: RobotModelController?
    
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
}

//MARK: - External Connector
public class ExternalRobotConnector: RobotConnector
{
    public init(_ module_name: String)
    {
        
    }
}

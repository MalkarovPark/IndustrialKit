//
//  Connector.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 08.10.2022.
//

import Foundation

//MARK: - Workspace object connector
public class WorkspaceObjectConnector
{
    public init()
    {
        
    }
    
    //Connection functions
    public func connect() //Connect to robot controller function
    {
        
    }
    
    public func disconnect() //Disconnect robot function
    {
        
    }
    
    public var connected: Bool = false
    
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
    
    public var update_model = false
}

//MARK: - Robot connector
public class RobotConnector: WorkspaceObjectConnector
{
    //Perform functions
    public func move_to(point: PositionPoint)
    {
        
    }
    
    public func move_to(point: PositionPoint, completion: @escaping () -> Void)
    {
        move_to(point: point)
        completion()
    }
    
    //Visual model handling
    public var model_controller: RobotModelController?
}

//MARK: - Tool connector
public class ToolConnector: WorkspaceObjectConnector
{
    //Perform functions
    func perform(code: Int) //Perform function for tool operation code
    {
        
    }
    
    func perform(code: Int, completion: @escaping () -> Void)
    {
        perform(code: code)
        completion()
    }
    
    //Visual model handling
    public var model_controller: ToolModelController?
}

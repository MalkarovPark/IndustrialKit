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
    private(set) var connected: Bool = false
    private(set) var connection_updating: Bool = false
    
    private var connection_task = Task {}
    
    private var disconnection_task = Task {}
    
    ///Connects instance to real workspace object.
    public func connect()
    {
        disconnection_task.cancel()
        
        if !connected
        {
            connection_updating = true
            
            connection_task = Task
            {
                connected = await connection_process()
            }
            
            connection_updating = false
        }
    }
    
    ///Disconnects real workspace object from instance.
    public func disconnect()
    {
        connection_task.cancel()
        
        if connected
        {
            connection_updating = true
            //connected = await disconnection_process()
            
            disconnection_task = Task
            {
                await disconnection_process()
            }
            
            connected = false
            connection_updating = false
        }
    }
    
    open func connection_process() async -> Bool
    {
        return true
    }
    
    open func disconnection_process() async // -> Bool
    {
        //return false
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
    
    public var update_model = false
}

//MARK: - Robot connector
public class RobotConnector: WorkspaceObjectConnector
{
    //Perform functions
    open func move_to(point: PositionPoint)
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
    open func perform(code: Int) //Perform function for tool operation code
    {
        
    }
    
    public func perform(code: Int, completion: @escaping () -> Void)
    {
        perform(code: code)
        completion()
    }
    
    //Visual model handling
    public var model_controller: ToolModelController?
}

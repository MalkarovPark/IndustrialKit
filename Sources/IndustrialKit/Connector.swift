//
//  Connector.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 08.10.2022.
//

import Foundation

//MARK: - Workspace object connector
/**
 A type provides connection and control for real workspace objects.
 
 Contains connect, disconnect functions and connection parameters array.
 
 Control functions are specialized for subtypes by workspace objects.
 */
open class WorkspaceObjectConnector
{
    public init()
    {
        
    }
    
    ///A connection state.
    public var connected: Bool = false
    
    ///A connection in updating process state.
    public var connection_updating: Bool = false
    
    ///An array of connection parameters.
    public var parameters = [ConnectionParameter]()
    
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
/**
 This subtype provides control for industrial robot.
 
 Contains special function for movement to point performation.
 */
open class RobotConnector: WorkspaceObjectConnector
{
    ///Performs movement to point.
    open func move_to(point: PositionPoint)
    {
        
    }
    
    ///Performs movement to point with compleition handler.
    public func move_to(point: PositionPoint, completion: @escaping () -> Void)
    {
        move_to(point: point)
        completion()
    }
    
    ///A robot model controller.
    public var model_controller: RobotModelController?
}

//MARK: - Tool connector
/**
 This subtype provides control for industrial tool.
 
 Contains special function for operation code performation.
 */
open class ToolConnector: WorkspaceObjectConnector
{
    ///Performs operation code.
    open func perform(code: Int)
    {
        
    }
    
    ///Performs operation code with compleition handler.
    public func perform(code: Int, completion: @escaping () -> Void)
    {
        perform(code: code)
        completion()
    }
    
    ///A tool model controller.
    public var model_controller: ToolModelController?
}

//MARK: - Connector parameter
public struct ConnectionParameter: Identifiable
{
    public var id = UUID()
    public var name: String
    public var value: Any
    
    public init(name: String, value: Any)
    {
        self.name = name
        self.value = value
    }
}

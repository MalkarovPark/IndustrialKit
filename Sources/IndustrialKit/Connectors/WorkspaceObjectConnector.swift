//
//  WorkspaceObjectConnector.swift
//  IndustrialKit
//
//  Created by Artem on 08.10.2022.
//

import Foundation
import SwiftUI
import SceneKit

//MARK: - Workspace object connector
/**
 A type provides connection and control for real workspace objects.
 
 Contains connect, disconnect functions and connection parameters array.
 
 Control functions are specialized for subtypes by workspace objects.
 */
open class WorkspaceObjectConnector: ObservableObject
{
    //MARK: - Init functions
    public init()
    {
        current_parameters = parameters
    }
    
    //MARK: - Connection parameters handling
    public func import_connection_parameters_values(_ list: [String]?)
    {
        if list != nil && current_parameters.count > 0
        {
            if list?.count == current_parameters.count
            {
                for i in 0 ..< current_parameters.count
                {
                    switch current_parameters[i].value
                    {
                    case is String:
                        current_parameters[i].value = list?[i] ?? ""
                    case is Int:
                        current_parameters[i].value = Int(list![i]) ?? 0
                    case is Float:
                        current_parameters[i].value = Float(list![i]) ?? 0
                    case is Bool:
                        current_parameters[i].value = list![i] == "true"
                    default:
                        break
                    }
                }
            }
        }
    }
    
    public var connection_parameters_values: [String]?
    {
        if current_parameters.count > 0
        {
            var parameters_list = [String]()
            
            for parameter in current_parameters
            {
                switch parameter.value
                {
                case let value as String:
                    parameters_list.append(value)
                case let value as Int:
                    parameters_list.append(String(value))
                case let value as Float:
                    parameters_list.append(String(value))
                case let value as Bool:
                    parameters_list.append(String(value))
                default:
                    break
                }
            }
            
            return parameters_list
        }
        else
        {
            return nil
        }
    }
    
    //MARK: - Connection handling
    ///A connection state.
    @Published public var connected: Bool = false
    
    ///A connection in updating process state.
    @Published public var connection_updating: Bool = false
    
    ///An array of default connection parameters.
    open var parameters: [ConnectionParameter]
    {
        return [ConnectionParameter]()
    }
    
    ///An array of connection parameters.
    @Published public var current_parameters = [ConnectionParameter]()
    
    /**
     A pause flag of performation.
     
     Used to pass to the performation function (*move to point* or *perform code*) information about the stop.
     */
    public var canceled = true
    
    private var connection_task = Task {}
    private var disconnection_task = Task {}
    
    ///Connects instance to real workspace object.
    public func connect()
    {
        disconnection_task.cancel()
        connection_failure = false
        
        if !connected
        {
            connection_updating = true
            
            /*DispatchQueue.global(qos: .background).async
            {
                self.connected = self.connection_process()
                self.connection_updating = false
                
                self.connection_failure = !self.connected
            }*/
            
            connection_task = Task
            {
                connected = await connection_process()
                connection_updating = false
                
                connection_failure = !connected
            }
        }
    }
    
    ///Disconnects real workspace object from instance.
    public func disconnect()
    {
        connection_task.cancel()
        
        if connected
        {
            connection_updating = true
            
            disconnection_task = Task
            {
                await disconnection_process()
            }
            
            connected = false
            connection_updating = false
            
            connection_failure = false
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
    
    ///A get output flag.
    @Published public var get_output = false
    
    private var connector_output_data = String()
    
    ///A connection output data.
    public var output: String
    {
        get
        {
            if !get_output
            {
                connector_output_data = String()
            }
            
            return connector_output_data
        }
        set
        {
            connector_output_data = newValue
        }
    }
    
    ///Clears connectiopn output data.
    public func clear_output()
    {
        output = String()
        self.objectWillChange.send()
    }
    
    ///Reset device perfoming.
    open func reset_device()
    {
        
    }
    
    //MARK: - Statistics handling
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
    
    ///Performs statistics data update.
    public func update_statistics_data()
    {
        charts_data = updated_charts_data()
        states_data = updated_states_data()
    }
    
    ///Initial charts data.
    open func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        return [WorkspaceObjectChart]()
    }
    
    ///Initial states data.
    open func initial_states_data() -> [StateItem]?
    {
        return [StateItem]()
    }
    
    ///Resets charts data to inital state.
    public func reset_charts_data()
    {
        charts_data = initial_charts_data()
    }
    
    ///Resets states data to inital state.
    public func reset_states_data()
    {
        states_data = initial_states_data()
    }
    
    //MARK: - Model handling
    ///A flag of update model avalibility.
    @Published public var update_model = false
    
    ///Synchronizes model with real device state.
    open func sync_model()
    {
        
    }
    
    //MARK: - UI functions
    ///A failure result of connection.
    @Published public var connection_failure = false
    
    ///Data for connection button.
    /// - Returns: Button label and light color – *label*, *color*.
    public var connection_button: (label: String, color: Color)
    {
        var label = String()
        var color = Color.gray
        
        if !connection_updating
        {
            if !connected
            {
                label = "Connect"
                
                if !connection_failure
                {
                    color = .gray
                }
                else
                {
                    color = .red
                }
            }
            else
            {
                label = "Disconnect"
                color = .green
            }
        }
        else
        {
            label = "Connecting"
            color = .yellow
        }
        
        return (label, color)
    }
}

//MARK: - Connector parameter
public struct ConnectionParameter: Identifiable, Equatable, Codable
{
    public static func == (lhs: ConnectionParameter, rhs: ConnectionParameter) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public var id = UUID()
    public var name: String
    public var value: Any
    
    public init(name: String, value: Any)
    {
        self.name = name
        self.value = value
    }
    
    //MARK: - Codable handling
    private enum CodingKeys: String, CodingKey
    {
        case id
        case name
        case value_type
        case value_string
        case value_int
        case value_float
        case value_bool
    }
    
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        let value_type = try container.decode(String.self, forKey: .value_type)
        switch value_type
        {
        case "String":
            value = try container.decode(String.self, forKey: .value_int)
        case "Int":
            value = try container.decode(Int.self, forKey: .value_int)
        case "Float":
            value = try container.decode(Float.self, forKey: .value_float)
        case "Bool":
            value = try container.decode(Bool.self, forKey: .value_bool)
        default:
            throw DecodingError.dataCorruptedError(forKey: .value_type, in: container, debugDescription: "Unknown type")
        }
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        switch value
        {
        case let value as String:
            try container.encode("String", forKey: .value_type)
            try container.encode(value, forKey: .value_int)
        case let value as Int:
            try container.encode("Int", forKey: .value_type)
            try container.encode(value, forKey: .value_int)
        case let value as Double:
            try container.encode("Float", forKey: .value_type)
            try container.encode(value, forKey: .value_float)
        case let value as Bool:
            try container.encode("Bool", forKey: .value_type)
            try container.encode(value, forKey: .value_bool)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

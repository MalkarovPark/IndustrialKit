//
//  ProductionObjectConnector.swift
//  IndustrialKit
//
//  Created by Artem on 08.10.2022.
//

import Foundation
import SwiftUI

//MARK: - Workspace object connector
/**
 A type provides connection and control for real workspace objects.
 
 Contains connect, disconnect functions and connection parameters array.
 
 Control functions are specialized for subtypes by workspace objects.
 */
open class ProductionObjectConnector: ObservableObject, @unchecked Sendable
{
    // MARK: - Init functions
    required public init()
    {
        parameters = default_parameters
    }
    
    deinit
    {
        disconnect()
    }
    
    /// Clone connector instance.
    open func copy() -> Self
    {
        //return type(of: self).init()
        
        let copy = type(of: self).init()
        
        copy.parameters = parameters
        
        return copy
    }
    
    /*/// Copy model controller instance.
    open func copy(with zone: NSZone? = nil) -> Any
    {
        return type(of: self).init() as! Self
    }*/
    
    // MARK: - Connection parameters handling
    /**
     Imports and assigns values to connection parameters from a string list.
     
     - Parameters:
        - list: An optional array of string values.
     
     The number of elements must match the number of parameters. Each string is converted to the corresponding parameter type (String, Int, Float, or Bool) before assignment.
     */
    public func import_connection_parameters_values(_ list: [String]?)
    {
        guard let list, list.count == parameters.count else { return }
        
        var new_parameters: [ConnectionParameter] = []
        
        for i in 0 ..< parameters.count
        {
            let original = parameters[i]
            let new_parameter = original.copy()
            
            switch original.value
            {
            case is String:
                new_parameter.value = list[i]
            case is Int:
                new_parameter.value = Int(list[i]) ?? 0
            case is Float:
                new_parameter.value = Float(list[i]) ?? 0
            case is Bool:
                new_parameter.value = list[i] == "true"
            default:
                break
            }
            
            new_parameters.append(new_parameter)
        }
        
        parameters = new_parameters
    }
    
    public var connection_parameters_values: [String]?
    {
        if parameters.count > 0
        {
            var parameters_list = [String]()
            
            for parameter in parameters
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
    
    // MARK: - Connection handling
    /// A connection state.
    @Published public var connected: Bool = false
    
    /// A connection in updating process state.
    @Published public var connection_updating: Bool = false
    
    /// An array of default connection parameters.
    open var default_parameters: [ConnectionParameter]
    {
        return [ConnectionParameter]()
    }
    
    /// An array of connection parameters.
    @Published public var parameters = [ConnectionParameter]()
    
    /**
     A pause flag of performation.
     
     Used to pass to the performation function (*move to point* or *perform code*) information about the stop.
     */
    public var canceled = true
    
    private var connection_task = Task {}
    private var disconnection_task = Task {}
    
    @Published public var connection_error: Error?
    @Published public var connection_output_string: String?
    
    /// Connects instance to real workspace object.
    public func connect()
    {
        disconnection_task.cancel()
        
        Task
        { @MainActor in
            connection_failure = false
        }
        
        guard !connected else { return }
        
        Task
        { @MainActor in
            connection_updating = true
        }
        
        connection_task.cancel()
        connection_task = Task
        {
            let success = await connection_process()
            
            await MainActor.run
            {
                connected = success
                connection_updating = false
                connection_failure = !success
            }
            
            if success
            {
                await MainActor.run
                {
                    start_device_sync()
                }
            }
            else
            {
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                await MainActor.run
                {
                    connection_failure = false
                }
            }
        }
    }
    
    /// Disconnects real workspace object from instance.
    public func disconnect()
    {
        stop_device_sync()
        
        connection_task.cancel()
        
        if connected
        {
            connection_updating = true
            
            /*disconnection_task = Task
            {
                await disconnection_process()
            }*/
            
            disconnection_process()
            
            connected = false
            connection_updating = false
            
            connection_failure = false
        }
    }
    
    open func connection_process() async -> Bool
    {
        return true
    }
    
    open func disconnection_process()
    {
        
    }
    
    /// Reset device perfoming.
    open func reset_device()
    {
        
    }
    
    // MARK: - Device state data
    @Published public var performing_state: PerformingState = .none
    @Published public var output_string: String?
    
    @Published public var current_device_output: DeviceOutputData?
    
    /*/// Updates device state data.
    open var current_device_output: DeviceState?
    {
        // Prepare controller output
        return DeviceState()
    }*/
    
    /// Initial charts data.
    open var initial_device_output: DeviceOutputData?
    {
        // Reset contoller output
        return nil
    }
    
    // MARK: - Model handling
    /// Indicates whether the device–model synchronization loop is currently running.
    public var is_device_syncing = false
    
    /// Enables or disables synchronization between the real device and the virtual model.
    //public var model_sync_enabled = true //false
    
    /// Asynchronous task responsible for executing the device–model synchronization loop.
    public var device_sync_task: Task<Void, Never>?
    
    /// Time interval between synchronization cycles (in seconds).
    public var device_sync_interval: Double = 0.01
    
    /**
     Starts the device–model synchronization loop.
     
     If synchronization is enabled (`model_sync_enabled == true`), this function launches an asynchronous task
     that periodically invokes `sync_with_device()` on the main thread. The loop continues to run while
     `is_device_syncing` remains `true`.
     
     The delay between iterations is defined by `device_sync_interval`. The synchronization process can be
     terminated by calling `stop_device_sync()`.
     */
    public func start_device_sync()
    {
        is_device_syncing = true
        
        device_sync_task = Task
        {
            while is_device_syncing
            {
                try? await Task.sleep(nanoseconds: UInt64(device_sync_interval * 1_000_000_000))
                await MainActor.run
                {
                    //guard model_sync_enabled else { return } //??
                    self.sync_with_device()
                }
                
                if device_sync_task == nil
                {
                    return
                }
            }
        }
    }
    
    /**
     Stops the device–model synchronization loop.
     
     This function terminates the synchronization process by setting `is_device_syncing` to `false`,
     cancelling the active synchronization task, and clearing `device_sync_task`.
     */
    public func stop_device_sync()
    {
        is_device_syncing = false
        device_sync_task?.cancel()
        device_sync_task = nil
    }
    
    /**
     Performs a single synchronization step between the real device and the virtual model.
     
     This method is invoked periodically by `start_device_sync()` and is executed on the main thread.
     Subclasses should override this method to transfer the current state of the real device to the
     controller of the virtual model.
     
     > Since this method is executed frequently, its implementation should remain lightweight and fast to prevent delays in the synchronization loop.
     */
    open func sync_with_device()
    {
        
    }
    
    /// Resets the internal state of the virtual device model.
    /*open func reset_device_model()
    {
        
    }*/
    
    // MARK: - UI functions
    /// A failure result of connection.
    @Published public var connection_failure = false
    
    /// Data for connection button.
    ///  - Returns: Button label and light color – *label*, *color*.
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
public class ConnectionParameter: Identifiable, Equatable, Codable, ObservableObject
{
    public static func == (lhs: ConnectionParameter, rhs: ConnectionParameter) -> Bool
    {
        lhs.name == rhs.name //lhs.id == rhs.id
    }
    
    public var id = UUID()
    public var name: String
    public var value: Any
    
    public init(name: String, value: Any)
    {
        self.name = name
        self.value = value
    }
    
    public func copy() -> ConnectionParameter
    {
        return ConnectionParameter(name: self.name, value: self.value)
    }
    
    // MARK: - Codable handling
    private enum CodingKeys: String, CodingKey
    {
        case name
        case value_type
        case value_string
        case value_int
        case value_float
        case value_bool
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        let value_type = try container.decode(String.self, forKey: .value_type)
        switch value_type
        {
        case "String":
            value = try container.decode(String.self, forKey: .value_string)
        case "Int":
            value = try container.decode(Int.self, forKey: .value_int)
        case "Float":
            value = try container.decode(Float.self, forKey: .value_float)
        case "Bool":
            value = try container.decode(Bool.self, forKey: .value_bool)
        default:
            throw DecodingError.dataCorruptedError(forKey: .value_type, in: container, debugDescription: "Unknown Type")
        }
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        switch value
        {
        case let value as String:
            try container.encode("String", forKey: .value_type)
            try container.encode(value, forKey: .value_string)
        case let value as Int:
            try container.encode("Int", forKey: .value_type)
            try container.encode(value, forKey: .value_int)
        case let value as Float:
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

public protocol ExternalConnector: ProductionObjectConnector, ObservableObject, Identifiable
{
    var program_component_enabled: Bool { get set }
    
    func start_program_component()
    func stop_program_component()
    
    var program_component_status: ProgramComponentStatus { get set }
    
    var program_component_url: URL { get }
    var socket_name: String { get }
}

public enum ProgramComponentStatus: String, Codable, Equatable, CaseIterable
{
    case not_running = "Not Running"
    case starting = "Starting"
    case running = "Running"
    
    public var color: Color
    {
        switch self
        {
        case .not_running:
            .red
        case .starting:
            .yellow
        case .running:
            .green
        }
    }
}

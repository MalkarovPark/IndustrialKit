//
//  ProductionObjectConnector.swift
//  IndustrialKit
//
//  Created by Artem on 08.10.2022.
//

import Foundation
import SwiftUI

//MARK: - Production Object Connector
/// A connector that provides communication with a real workspace object.
///
/// `ProductionObjectConnector` defines a unified interface for connecting,
/// controlling, and synchronizing a physical device with its virtual model.
///
/// The connector manages:
/// - Connection lifecycle (connect / disconnect)
/// - Parameter configuration
/// - Device state synchronization
/// - Performing control and cancellation
///
/// Subclasses implement device-specific logic by overriding connection,
/// disconnection, and synchronization methods.
/// 
open class ProductionObjectConnector: ObservableObject, @unchecked Sendable
{
    // MARK: - Initializers
    /// Creates a connector instance with default parameters.
    required public init()
    {
        parameters = default_parameters
    }
    
    /// Releases resources and disconnects the device if needed.
    deinit
    {
        disconnect()
    }
    
    /// Creates a copy of the connector.
    ///
    /// The copy preserves connection parameters but does not inherit
    /// the active connection state.
    ///
    /// - Returns: A new connector instance.
    open func copy() -> Self
    {
        //return type(of: self).init()
        
        let copy = type(of: self).init()
        
        copy.parameters = parameters
        
        return copy
    }
    
    // MARK: - Connection Parameters
    /// Imports connection parameter values from a string list.
    ///
    /// Values are converted to the corresponding parameter types
    /// (`String`, `Int`, `Float`, `Bool`) and assigned to parameters.
    ///
    /// - Parameter list: A list of string values matching parameter count.
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
    
    /// A list of connection parameter values represented as strings.
    ///
    /// Used for serialization or UI binding.
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
    
    /// Default connection parameters.
    ///
    /// Subclasses override this property to define required parameters.
    open var default_parameters: [ConnectionParameter]
    {
        return [ConnectionParameter]()
    }
    
    /// Current connection parameters.
    @Published public var parameters = [ConnectionParameter]()
    
    // MARK: - Connection Handling
    // MARK: Connection State
    /// Indicates whether the device is currently connected.
    @Published public var connected: Bool = false
    
    /// Indicates whether a connection or disconnection process is in progress.
    @Published public var connection_updating: Bool = false
    
    /// Indicates whether performing operations are canceled.
    ///
    /// This flag is used to interrupt long-running device actions.
    public var canceled = true
    
    private var connection_task = Task {}
    private var disconnection_task = Task {}
    
    /// An error describing the last connection issue.
    @Published public var connection_error: Error?
    
    /// A textual output describing connection status or logs.
    @Published public var connection_output_string: String?
    
    /// Initiates connection to the real device.
    ///
    /// This method starts an asynchronous connection process and updates
    /// connection state properties accordingly.
    ///
    /// On success, device synchronization is started automatically.
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
    
    /// Disconnects the device.
    ///
    /// Stops synchronization, cancels active tasks, and resets connection state.
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
    
    /// Performs the connection process.
    ///
    /// Subclasses override this method to implement device-specific logic.
    ///
    /// - Returns: `true` if connection succeeded.
    open func connection_process() async -> Bool
    {
        return true
    }
    
    /// Performs the connection process.
    ///
    /// Subclasses override this method to implement device-specific logic.
    ///
    /// - Returns: `true` if connection succeeded.
    open func disconnection_process() {}
    
    /// Resets the device performing state.
    ///
    /// Subclasses override this method to stop active operations on the device.
    open func reset_device() {}
    
    // MARK: - Device State
    /// Current performing state of the device.
    @Published public var performing_state: PerformingState = .none
    
    /// A textual representation of device output.
    @Published public var output_string: String?
    
    /// Current device output data.
    ///
    /// Contains structured state information such as charts and items.
    @Published public var current_device_output: DeviceOutputData?
    
    /*/// Updates device state data.
    open var current_device_output: DeviceState?
    {
        // Prepare controller output
        return DeviceState()
    }*/
    
    /// Initial device output data.
    ///
    /// Used to reset or initialize the device state.
    open var initial_device_output: DeviceOutputData?
    {
        // Reset contoller output
        return nil
    }
    
    // MARK: - Device Sync
    /// Indicates whether device synchronization is active.
    public var is_device_syncing = false
    
    /// Enables or disables synchronization between the real device and the virtual model.
    //public var model_sync_enabled = true //false
    
    /// A task responsible for periodic device synchronization.
    public var device_sync_task: Task<Void, Never>?
    
    /// Time interval between synchronization updates in seconds.
    public var device_sync_interval: Double = 0.01
    
    /// Starts the device–model synchronization loop.
    ///
    /// Periodically invokes ``sync_with_device()`` while synchronization is active.
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
    
    /// Stops the device–model synchronization loop.
    public func stop_device_sync()
    {
        is_device_syncing = false
        device_sync_task?.cancel()
        device_sync_task = nil
    }
    
    /// Synchronizes the virtual model with the real device.
    ///
    /// Subclasses override this method to transfer device state
    /// into the virtual representation.
    ///
    /// - Important:
    /// This method should remain lightweight to avoid blocking the update loop.
    open func sync_with_device()
    {
        
    }
    
    /// Resets the internal state of the virtual device model.
    /*open func reset_device_model()
    {
        
    }*/
    
    // MARK: - UI
    /// Indicates whether the last connection attempt failed.
    @Published public var connection_failure = false
    
    /// Data for connection button representation.
    ///
    /// Returns a label and color reflecting current connection state.
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

//MARK: - Connector Parameter
/// A parameter describing a connection setting.
///
/// `ConnectionParameter` stores a named value used to configure
/// connection to a real device.
public class ConnectionParameter: Identifiable, Equatable, Codable, ObservableObject
{
    public static func == (lhs: ConnectionParameter, rhs: ConnectionParameter) -> Bool
    {
        lhs.name == rhs.name //lhs.id == rhs.id
    }
    
    public var id = UUID()
    
    /// Parameter name.
    public var name: String
    
    /// Parameter value.
    ///
    /// Supports `String`, `Int`, `Float`, and `Bool` types.
    public var value: Any
    
    /// Creates a connection parameter.
    ///
    /// - Parameters:
    ///   - name: Parameter name.
    ///   - value: Parameter value.
    public init(name: String, value: Any)
    {
        self.name = name
        self.value = value
    }
    
    public func copy() -> ConnectionParameter
    {
        return ConnectionParameter(name: self.name, value: self.value)
    }
    
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

// MARK: - External Connector
/// A protocol describing connectors with external program components.
///
/// `ExternalConnector` extends ``ProductionObjectConnector`` by adding
/// support for external processes such as runtime controllers or services.
public protocol ExternalConnector: ProductionObjectConnector, ObservableObject, Identifiable
{
    /// Indicates whether the program component is enabled.
    var program_component_enabled: Bool { get set }
    
    /// Starts the external program component.
    func start_program_component()
    
    /// Stops the external program component.
    func stop_program_component()
    
    /// Current status of the program component.
    var program_component_status: ProgramComponentStatus { get set }
    
    /// URL of the program component executable or resource.
    var program_component_url: URL { get }
    
    /// Name of the communication socket.
    var socket_name: String { get }
}

// MARK: - Program Component Status
/// A status representing the lifecycle of an external program component.
public enum ProgramComponentStatus: String, Codable, Equatable, CaseIterable
{
    /// The component is not running.
    case not_running = "Not Running"
    
    /// The component is starting.
    case starting = "Starting"
    
    /// The component is running.
    case running = "Running"
    
    /// A color representing the current status.
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

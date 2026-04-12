//
//  RobotConnector.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation

/// A connector that provides control over an industrial robot.
///
/// `RobotConnector` extends ``ProductionObjectConnector`` and adds
/// high-level motion control, including synchronous and asynchronous
/// movement execution.
///
/// It bridges:
/// - High-level movement commands (`move`)
/// - Real device execution (`start_process`)
/// - Live synchronization with robot state
/// - Model visualization updates via ``RobotModelController``
open class RobotConnector: ProductionObjectConnector, @unchecked Sendable
{
    // MARK: - Parameters
    /// The current end-effector position of the robot.
    ///
    /// Represents full spatial pose consisting of:
    /// - Linear coordinates (*x*, *y*, *z*)
    /// - Orientation angles (*r*, *p*, *w*)
    ///
    /// Updated automatically during device synchronization.
    public var pointer_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// The origin pose of the robot workspace.
    ///
    /// Defines the base coordinate system of the robot cell in both position
    /// and orientation space.
    public var origin_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// The scaling factor of the robot workspace.
    ///
    /// Defines the physical dimensions of the simulated or real working area.
    public var space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    
    // MARK: - Device Handling
    /// Performs a synchronous movement of the robot to a target position.
    ///
    /// The method blocks execution until the device completes the movement.
    /// Internally it:
    /// 1. Starts the movement process
    /// 2. Waits for the device to enter performing state
    /// 3. Waits for completion
    /// 4. Evaluates result state and throws an error if needed
    ///
    /// - Parameter point: Target position in workspace coordinates.
    /// - Throws: An error if the device reports a failure state.
    public func move(to point: PositionPoint) throws
    {
        start_process(point: point)
        
        while performing_state != .processing {} //Wait for performing state
        while performing_state == .processing {} //Wait for completion
        
        switch performing_state
        {
        case .error:
            throw NSError(domain: output_string ?? "Performing Error", code: 0, userInfo: nil)
        default:
            break
        }
    }
    
    /// Starts a movement process on the robot without blocking execution.
    ///
    /// This method triggers device-side execution and returns immediately.
    /// Use ``move(to:)`` for synchronous execution control.
    ///
    /// - Parameter point: Target position in workspace coordinates.
    open func start_process(point: PositionPoint) {}
    
    private var moving_task = Task {}
    
    /// Performs an asynchronous movement to a target position with completion handler.
    ///
    /// This method wraps synchronous execution in an asynchronous task.
    ///
    /// - Parameters:
    ///   - point: Target position in workspace coordinates.
    ///   - completion: Completion handler returning success or failure result.
    public func move(
        to point: PositionPoint,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    )
    {
        if !connected
        {
            completion(.failure(NSError(domain: "Not Connected to Robot", code: 0, userInfo: nil)))
            return
        }
        
        canceled = false
        
        moving_task = Task
        {
            do
            {
                try self.move(to: point)
                if !canceled
                {
                    completion(.success(()))
                }
            }
            catch
            {
                completion(.failure(error))
            }
            
            canceled = false
        }
    }
    
    // MARK: - Robot Sync
    /// A model controller responsible for visual representation of the robot.
    ///
    /// Synchronizes virtual robot state with device state.
    public var model_controller: RobotModelController?
    
    /// Synchronizes the robot state with the connected device.
    ///
    /// Updates:
    /// - Performing state
    /// - Output messages and data
    /// - Pointer position
    /// - Entity transformations via model controller
    ///
    /// This method ensures consistency between physical device state and
    /// virtual simulation model.
    override open func sync_with_device()
    {
        guard let current_device_state = current_device_state else { return }
        
        // Update current performing state
        performing_state = current_device_state.performing_state
        output_string = current_device_state.output_string
        
        // Update current position
        if let current_pointer_position = current_device_state.pointer_position
        {
            pointer_position = (
                x: current_pointer_position.x,
                y: current_pointer_position.y,
                z: current_pointer_position.z,
                r: current_pointer_position.r,
                p: current_pointer_position.p,
                w: current_pointer_position.w
            )
        }
        
        // Update current output data
        if let output_data = current_device_state.output_data
        {
            current_device_output = output_data
        }
        
        // Apply model data
        if let model_controller = model_controller,
           performing_state == .processing
        {
            if let entity_positions = current_device_state.entity_positions
            {
                model_controller.apply_entity_positions(by: entity_positions)
            }
            
            if current_device_state.pointer_position != nil
            {
                model_controller.pointer_position = pointer_position
                model_controller.update_pointer_position()
            }
        }
    }
    
    /// The current state of the robot device.
    ///
    /// Subclasses must override this property to provide actual device state.
    ///
    /// Returns `nil` by default when no device is connected.
    open var current_device_state: RobotState?
    {
        return nil
    }
}

/// A snapshot of the robot's runtime state.
///
/// Contains:
/// - Execution state
/// - Output data
/// - Pointer position
/// - Entity transformations
public struct RobotState: Codable
{
    /// Current execution state of the robot.
    public var performing_state: PerformingState = .none
    
    /// Robot output message.
    public var output_string: String?
    
    /// Structured output data from the robot.
    public var output_data: DeviceOutputData?
    
    /// Current TCP position of the robot.
    public var pointer_position: EntityPositionData?
    
    /// Positions of entities in robot workspace.
    public var entity_positions: [EntityPositionData]?
    
    public init(
        performing_state: PerformingState = .none,
        
        output_data: DeviceOutputData? = nil,
        output_string: String? = nil,
        
        pointer_position: EntityPositionData? = nil,
        entity_positions: [EntityPositionData]? = nil
    )
    {
        self.performing_state = performing_state
        
        self.output_data = output_data
        self.output_string = output_string
        
        self.pointer_position = pointer_position
        self.entity_positions = entity_positions
    }
}

//MARK: - External Connector
/// A robot connector that communicates with an external runtime module.
///
/// `ExternalRobotConnector` extends ``RobotConnector`` by delegating all
/// device control and state processing to an external executable module.
///
/// The connector manages:
/// - External process lifecycle (start/stop program component)
/// - Unix socket communication
/// - Connection negotiation with external runtime
/// - Remote execution of movement commands
///
/// This class is used when robot logic is implemented outside the main system.
public class ExternalRobotConnector: RobotConnector, ExternalConnector, @unchecked Sendable
{
    // MARK: Initializators
    /// Creates an empty external robot connector instance.
    ///
    /// This initializer is required for dynamic instantiation and copying.
    /// The connector is created without configuration and must be set up
    /// before establishing a connection.
    required init()
    {
        self.module_name = ""
        self.package_url = URL(fileURLWithPath: "")
    }
    
    /// Creates an external robot connector with module configuration.
    ///
    /// - Parameters:
    ///   - module_name: The name of the external module controlling the robot.
    ///   - package_url: The location of the external module package.
    ///   - parameters: A list of connection parameters for the robot.
    ///
    /// This initializer configures the connector to communicate with an
    /// external runtime responsible for robot control and motion execution.
    public init(
        _ module_name: String,
        package_url: URL,
        
        parameters: [ConnectionParameter]
    )
    {
        self.module_name = module_name
        self.package_url = package_url
        
        self.external_parameters = parameters
    }
    
    open override func copy() -> Self
    {
        let copy = type(of: self).init()
        
        copy.module_name = module_name
        copy.package_url = package_url
        
        copy.external_parameters = external_parameters
        copy.parameters = parameters
        
        return copy
    }
    
    /*deinit
    {
        stop_program_component()
    }*/
    
    // MARK: External Module
    /// The name of the external module controlling the robot.
    public var module_name: String
    
    /// The filesystem URL of the external package providing robot logic.
    public var package_url: URL
    
    // MARK: External Program Component
    public var program_component_enabled: Bool = false
    {
        didSet
        {
            program_component_enabled ?
            start_program_component() :
            stop_program_component()
        }
    }
    
    public func start_program_component()
    {
        #if os(macOS)
        Task
        {
            program_component_status = .starting
            
            if await !is_socket_active(at: socket_name)
            {
                perform_terminal_app_sync(
                    at: program_component_url,
                    with: [
                        socket_name,
                        " > /dev/null 2>&1 &"
                    ]
                )
            }
            
            let timeout_seconds: UInt64 = 2
            let check_interval: UInt64 = 100_000_000
            var attempts: UInt64 = 0
            let max_attempts = timeout_seconds * 10
            
            while await !is_socket_active(at: socket_name)
            {
                if attempts >= max_attempts
                {
                    program_component_status = .not_running
                    return
                }
                try? await Task.sleep(nanoseconds: check_interval)
                attempts += 1
            }
            
            program_component_status = .running
        }
        #endif
    }
    
    public func stop_program_component()
    {
        #if os(macOS)
        send_via_unix_socket(at: socket_name, command: "stop")
        program_component_status = .not_running
        #endif
    }
    
    @Published public var program_component_status: ProgramComponentStatus = .not_running
    
    public var program_component_url: URL
    {
        return package_url.appendingPathComponent("Connector")
    }
    
    public var socket_name: String
    {
        return "/tmp/\(module_name)\(Int(bitPattern: id))_robot_connector_socket"
    }
    
    // MARK: Connection Handling
    override open var default_parameters: [ConnectionParameter]
    {
        return external_parameters
    }
    
    /// A list of external connection parameters used for runtime configuration.
    ///
    /// This array defines parameters received from or passed to an external system.
    public var external_parameters = [ConnectionParameter]()
    
    override open func perform_connection() async -> Bool
    {
        #if os(macOS)
        // Perform connection
        let arguments = ["connect"] + (connection_parameters_values?.map { "\($0)" } ?? [])
        
        guard let terminal_output: String = send_via_unix_socket(at: socket_name, with: arguments)
        else
        {
            connection_error = NSError(domain: "Couldn't perform external code", code: 0, userInfo: nil)
            return false
        }
        
        // Get output
        if let range = terminal_output.range(of: "\"([^\"]*)\"", options: .regularExpression)
        {
            connection_output_string = String(terminal_output[range]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        
        // Get connection result
        if let start = terminal_output.range(of: "<done:")?.upperBound,
           let end = terminal_output[start...].firstIndex(of: ">")
        {
            connection_output_string = terminal_output[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            return true
        }
        if let start = terminal_output.range(of: "<failed:")?.upperBound,
           let end = terminal_output[start...].firstIndex(of: ">")
        {
            connection_error = NSError(domain: terminal_output[start..<end].trimmingCharacters(in: .whitespacesAndNewlines), code: 0, userInfo: nil)
            return false
        }
        if terminal_output.contains("<done>")
        {
            connection_output_string = "Connected"
            return true
        }
        if terminal_output.contains("<failed>")
        {
            connection_error = NSError(domain: "Connection failed", code: 0, userInfo: nil)
            return false
        }
        
        connection_error = NSError(domain: "External module connector unavailable", code: 0, userInfo: nil)
        return false
        #else
        return false
        #endif
    }
    
    override open func perform_disconnection()// async
    {
        #if os(macOS)
        guard let terminal_output: String = send_via_unix_socket(at: socket_name, with: ["disconnect"])
        else
        {
            connection_failure = true
            return
        }
        #endif
    }
    
    // MARK: Device Handling
    override open func start_process(point: PositionPoint)
    {
        #if os(macOS)
        let origin_position = [
            "\(origin_position.x)",  "\(origin_position.y)",  "\(origin_position.z)",
            "\(origin_position.r)",  "\(origin_position.p)",  "\(origin_position.w)"
        ]
        let command = ["move_to"] + [point.json_string()] + origin_position
        
        guard let terminal_output: String = send_via_unix_socket(at: socket_name, with: command)
        else
        {
            connection_error = NSError(domain: "Couldn't move to position", code: 0, userInfo: nil)
            connection_failure = true
            connected = false
            return
        }
        #endif
    }
    
    open override var current_device_state: RobotState?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: socket_name, with: ["current_device_state"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let device_state: RobotState = string_to_codable(from: output)
        {
            return device_state
        }
        #endif
        
        connected = false
        return nil
    }
}

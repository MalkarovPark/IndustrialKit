//
//  RobotConnector.swift
//  IndustrialKit
//
//  Created by Artem on 13.09.2024.
//

import Foundation
import SceneKit

/**
 This subtype provides control for industrial robot.
 
 Contains special function for movement to point performation.
 */
open class RobotConnector: WorkspaceObjectConnector, @unchecked Sendable
{
    // MARK: - Parameters
    /**
     A robot pointer position.
     
     Tuple with three coordinates – *x*, *y*, *z* and three angles – *r*, *p*, *w*.
     */
    public var pointer_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /**
     A robot cell origin position.
     
     Tuple with coordinates – *x*, *y*, *z* and angles – *r*, *p*, *w*.
     */
    public var origin_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// A robot cell box scale.
    public var space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    
    // MARK: - Device Handling
    /**
     Performs movement on real robot by target position.
     
     - Parameters:
        - point: The target position performed by the real robot.
     */
    public func move_to(point: PositionPoint) throws
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
    
    /**
     Starts movement process of the real robot to the specified position.
     
     This method initiates the execution but does not block until completion.
     Use higher-level methods (e.g., `move_to(point:)`) to perform synchronous execution.
     
     - Parameters:
        - point: The target position to which the real robot should move.
     */
    open func start_process(point: PositionPoint)
    {
        
    }
    
    private var moving_task = Task {}
    
    /**
     Performs movement on real robot by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the real robot.
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
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
                try self.move_to(point: point)
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
    
    // MARK: - Sync Handling
    /// A robot model controller.
    public var model_controller: RobotModelController?
    
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
    
    open var current_device_state: RobotState?
    {
        return nil
    }
}

public struct RobotState: Codable
{
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
    
    public var performing_state: PerformingState = .none
    
    public var output_string: String?
    public var output_data: DeviceOutputData?
    
    public var pointer_position: EntityPositionData?
    public var entity_positions: [EntityPositionData]?
}

//MARK: - External Connector
public class ExternalRobotConnector: RobotConnector, ExternalConnector, @unchecked Sendable
{
    /// Clone connector instance.
    open override func clone() -> Self
    {
        let copy = type(of: self).init()
        
        copy.module_name = module_name
        copy.package_url = package_url
        
        return copy
    }
    
    // MARK: Init functions
    /// An external module name
    public var module_name: String
    
    /// For access to code
    public var package_url: URL
    
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
    
    required init()
    {
        self.module_name = ""
        self.package_url = URL(fileURLWithPath: "")
    }
    
    /*deinit
    {
        stop_program_component()
    }*/
    
    // MARK: Program component handling
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
    }
    
    public func stop_program_component()
    {
        send_via_unix_socket(at: socket_name, command: "stop")
        program_component_status = .not_running
    }
    
    @Published public var program_component_status: ProgramComponentStatus = .not_running
    
    public var program_component_url: URL
    {
        return package_url.appendingPathComponent("Code/Connector")
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
    
    public var external_parameters = [ConnectionParameter]()
    
    override open func connection_process() async -> Bool
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
    
    override open func disconnection_process()// async
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

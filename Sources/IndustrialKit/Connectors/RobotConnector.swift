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
        
        while performing_state == .processing { }
        
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
        - update_model: Update model by connector.
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
    {
        if !connected
        {
            completion(
                .failure(NSError(domain: "Not Connected to Robot", code: 0, userInfo: nil))
            )
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
    
    // MARK: - Model Handling
    /// A robot model controller.
    public var model_controller: RobotModelController?
    
    override open func sync_with_device()
    {
        guard let current_robot_state = current_robot_state else { return }
        
        // Update current performing state
        performing_state = current_robot_state.performing_state
        output_string = current_robot_state.output_string
        
        // Update current position
        if let current_pointer_position = current_robot_state.pointer_position
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
        
        // Apply model data
        if let model_controller = model_controller
        {
            if let entity_positions = current_robot_state.entity_positions
            {
                model_controller.apply_entity_positions(by: entity_positions)
            }
            
            if current_robot_state.pointer_position != nil
            {
                model_controller.pointer_position = pointer_position
                model_controller.update_pointer_position()
            }
        }
    }
    
    open var current_robot_state: RobotState?
    {
        return nil
    }
    
    /*override open func reset_device_model()
    {
        if let model_controller = model_controller,
           let entity_positions = initial_entity_positions
        {
            model_controller.apply_entity_positions(by: entity_positions)
        }
    }
    
    open var initial_entity_positions: [EntityPositionData]?
    {
        return nil//[]
    }*/
}

public struct RobotState: Codable
{
    public var performing_state: PerformingState = .none
    public var pointer_position: EntityPositionData?
    public var entity_positions: [EntityPositionData]?
    
    public var output_string: String?
}

//MARK: - External Connector
public class ExternalRobotConnector: RobotConnector, @unchecked Sendable
{
    // MARK: Init functions
    /// An external module name
    public var module_name: String
    
    /// For access to code
    public var package_url: URL
    
    public init(_ module_name: String, package_url: URL, parameters: [ConnectionParameter])
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
    
    // MARK: Parameters import
    override open var default_parameters: [ConnectionParameter]
    {
        return external_parameters
    }
    
    public var external_parameters = [ConnectionParameter]()
    
    // MARK: Connection
    override open func connection_process() async -> Bool
    {
        #if os(macOS)
        // Perform connection
        let arguments = ["connect"] + (connection_parameters_values?.map { "\($0)" } ?? [])

        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: arguments) else
        {
            connection_error = NSError(domain: "Couldn't perform external code", code: 0, userInfo: nil)
            return false
        }
        
        // Get output
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
        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["disconnect"])
        else
        {
            
            connection_failure = true
            return
        }
        #endif
    }
    
    // MARK: Performing
    private var state: PerformingState
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(
            at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket",
            with: ["performing_state"])
        else
        {
            return .completed //.error
        }
        
        return PerformingState(rawValue: output) ?? .completed //.error
        #else
        return PerformingState(rawValue: output) ?? .completed //.error
        #endif
    }
    
    override open func start_process(point: PositionPoint)
    {
        #if os(macOS)
        // Perform to point moving
        let origin_position = ["\(origin_position.x)",  "\(origin_position.y)",  "\(origin_position.z)",
                               "\(origin_position.r)",  "\(origin_position.p)",  "\(origin_position.w)"]
        let command = ["move_to"] + [point.json_string()] + origin_position
        
        guard let terminal_output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: command)
        else
        {
            connection_error = NSError(domain: "Couldn't move to position", code: 0, userInfo: nil)
            connection_failure = true
            connected = false
            return
        }
        
        // Process output
        while state == .processing && !canceled
        {
            sync_with_device()
        }
        #endif
    }
    
    open override func reset_device()
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["reset_device"])
        else
        {
            connection_failure = true
            connected = false
            return
        }
        #endif
    }
    
    // MARK: State Data
    open override var current_device_state: DeviceState?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["current_device_state"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let device_state: DeviceState = string_to_codable(from: output)
        {
            return device_state
        }
        #endif
        
        connected = false
        return nil
    }
    
    open override var initial_device_state: DeviceState?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["initial_device_state"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let device_state: DeviceState = string_to_codable(from: output)
        {
            return device_state
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }
    
    // MARK: Model Sync
    /*open override var current_entity_positions: [EntityPositionData]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["current_entity_positions"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let entity_animations: [EntityPositionData] = string_to_codable(from: output)
        {
            return entity_animations
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }
    
    open override var initial_entity_positions: [EntityPositionData]?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["initial_entity_positions"])
        else
        {
            connection_failure = true
            connected = false
            return nil
        }
        
        if let entity_animations: [EntityPositionData] = string_to_codable(from: output)
        {
            return entity_animations
        }
        #endif
        
        connection_failure = true
        connected = false
        return nil
    }
    
    open override func sync_model()
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket", with: ["sync_model"])
        else
        {
            connection_failure = true
            connected = false
            return
        }
        
        // Split the output into lines
        let lines = output.split(separator: "\n").map { String($0) }
        
        for line in lines
        {
            // Split the line by space to separate node name and action string
            let components = line.split(separator: " ", maxSplits: 1).map { String($0) }
            
            // Ensure there are two components: the node name and the action string
            guard components.count == 2
            else
            {
                continue
            }
            
            set_position(for: model_controller?.nodes[safe: components[0], default: SCNNode()] ?? SCNNode(), from: components[1])
        }
        #endif
    }*/
    
    /*private var external_pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)?
    {
        #if os(macOS)
        guard let output: String = send_via_unix_socket(
            at: "/tmp/\(module_name.code_correct_format)_robot_connector_socket",
            with: ["sync_pointer"])
        else
        {
            return nil
        }
        
        let components = output.split(separator: " ").compactMap { Float($0) }
        return components.count == 6 ? (components[0], components[1], components[2],
                                        components[3], components[4], components[5]) : nil
        #else
        return nil
        #endif
    }
    
    open override func sync_device_model()
    {
        if let position = external_pointer_position // Update pointer node position by connector
        {
            model_controller?.update_pointer_position((x: position.x, y: position.y, z: position.z, r: position.r, p: position.p, w: position.w))
            
            if let nodes_positions = external_nodes_positions // Update nodes positions by connector (real device)
            {
                //model_controller?.apply_entities_positions(by: nodes_positions)
            }
            else // Update nodes positions by model controller (simulated device)
            {
                do
                {
                    try model_controller?.update_robot_model(pointer_position: position, origin_position: origin_position)
                }
                catch
                {
                    print(error.localizedDescription)
                }
            }
        }
    }*/
}

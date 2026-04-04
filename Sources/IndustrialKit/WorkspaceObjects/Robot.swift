//
//  Robot.swift
//  IndustrialKit
//
//  Created by Artem on 05.12.2021.
//

import Foundation
import SwiftUI
#if canImport(RealityKit)
import RealityKit
#endif

/// A programmable robotic manipulator capable of performing spatial operations.
///
/// A robot is an automatically controlled, reprogrammable, and versatile
/// manipulator that operates within a workspace and may have different
/// kinematic structures and degrees of freedom.
///
/// The robot operates in spatial coordinates and performs sequential
/// positioning of its end-effector at target locations.
///
/// Robot behavior is defined using positional programs (``PositionsProgram``),
/// each representing an ordered sequence of target points (``PositionPoint``).
///
/// Each position point specifies:
/// - Linear displacement relative to the robot coordinate system (x, y, z)
/// - Orientation in space (r, p, w)
/// - Motion type (for example, linear or fine)
/// - Movement speed in millimeters per second
///
/// Use the ``move_to(_:)`` method to initiate performing of a movement
/// toward a target position defined by a ``PositionPoint``.
///
/// This abstraction enables deterministic motion planning and performing
/// of robotic tasks such as manipulation, assembly, and automated processing.
/// 
open class Robot: WorkspaceObject, DeviceTwin, StateOutputCapable
{
    // MARK: - Initializers
    /// Creates a robot instance with default parameters.
    public override init()
    {
        super.init()
    }
    
    /// Creates a robot instance with a specified name.
    ///
    /// - Parameter name: A human-readable identifier of the robot.
    public override init(name: String)
    {
        super.init(name: name)
    }
    
    /// Creates a robot instance with a name and associated entity resource.
    ///
    /// - Parameters:
    ///   - name: A human-readable identifier.
    ///   - entity_name: A name of the associated scene entity.
    public override init(
        name: String,
        entity_name: String
    )
    {
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Creates a fully configured robot instance.
    ///
    /// - Parameters:
    ///   - name: A human-readable identifier.
    ///   - entity_name: A name of the associated scene entity.
    ///   - end_entity_name: A name of the end-effector entity.
    ///   - model_controller: A controller responsible for virtual model performing.
    ///   - connector: A connector responsible for real-device communication.
    public init(
        name: String,
        entity_name: String,
        
        end_entity_name: String = String(),
        
        model_controller: RobotModelController = RobotModelController(),
        connector: RobotConnector = RobotConnector()
    )
    {
        super.init(name: name, entity_name: entity_name)
        
        self.end_entity_name = end_entity_name
        
        self.model_controller = model_controller
        self.connector = connector
    }
    
    /// Creates a robot instance from an existing entity.
    ///
    /// - Parameters:
    ///   - name: A robot identifier.
    ///   - entity: A 3D entity representing the robot model.
    ///   - end_entity_name: A name of the end-effector entity.
    ///   - model_controller: A model controller instance.
    ///   - connector: A device connector instance.
    public convenience init(
        name: String,
        entity: Entity,
        
        end_entity_name: String = String(),
        
        model_controller: RobotModelController = RobotModelController(),
        connector: RobotConnector = RobotConnector()
    )
    {
        self.init(name: name, entity: entity)
        
        self.end_entity_name = end_entity_name
        
        self.model_controller = model_controller
        self.connector = connector
    }
    
    /// Creates a robot instance from a module configuration.
    ///
    /// - Parameters:
    ///   - name: A robot identifier.
    ///   - module: A robot module defining structure and behavior.
    ///   - is_internal: A flag indicating whether the module is internal.
    public init(
        name: String,
        module: RobotModule,
        
        is_internal: Bool = true
    )
    {
        super.init(name: name)
        
        is_internal_module = is_internal
        import_module(module)
    }
    
    /// Creates a robot instance using a module name.
    ///
    /// - Parameters:
    ///   - name: A robot identifier.
    ///   - module_name: A module identifier.
    ///   - is_internal: A flag indicating whether the module is internal.
    public override init(
        name: String,
        module_name: String,
        
        is_internal: Bool
    )
    {
        super.init(name: name, module_name: module_name, is_internal: is_internal)
    }
    
    /// Creates a robot instance using a module name.
    ///
    /// - Parameters:
    ///   - name: A robot identifier.
    ///   - module_name: A module identifier.
    ///   - is_internal: A flag indicating whether the module is internal.
    private func set_default_cell_parameters()
    {
        self.origin_position = Robot.default_origin_position
        self.space_scale = Robot.default_space_scale
    }
    
    // MARK: - Entity Preparation
    /// Extends entity preparation by assembling robot components.
    ///
    /// This method attaches auxiliary entities such as working area,
    /// position pointer, and position program visualization, and connects
    /// the kinematic structure using the model controller.
    ///
    /// - Parameter entity: A root entity representing the robot.
    override open func extend_entity_preparation(_ entity: Entity)
    {
        // Place robot accesories
        working_area_entity = build_working_area_entity(scale: space_scale)
        working_area_entity.isEnabled = false
        
        origin_entity.addChild(working_area_entity)
        
        position_pointer_entity = build_position_pointer_entity()
        position_pointer_entity.isEnabled = false
        
        origin_entity.addChild(position_pointer_entity)
        
        position_program_entity.isEnabled = false
        
        origin_entity.addChild(position_program_entity)
        
        entity.addChild(origin_entity)
        
        // Connect robot parts
        model_controller.disconnect_entities()
        model_controller.connect_entities(entity, pointer_entity: position_pointer_entity)
        
        // Connect end point
        if let end_entity = entity.child_entity(withName: end_entity_name, recursively: true) { end_point_entity = end_entity }
        
        // Apply physics
        entity.apply_physics(
            by: PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .kinematic
            )
        )
        
        update_model()
    }
    
    // MARK: - Module Handling
    /// Imports a robot module and configures the instance.
    ///
    /// The method asynchronously loads the module entity and applies
    /// controller, connector, and spatial configuration parameters.
    ///
    /// - Parameter module: A robot module describing structure and behavior.
    public func import_module(_ module: RobotModule)
    {
        module_name = module.name
        
        Task
        {
            while module.entity == nil
            {
                try await Task.sleep(nanoseconds: 30_000_000)
            }
            
            guard let entity = module.entity else { return }
            
            await MainActor.run
            {
                import_entity(entity.clone(recursive: true))
            }
        }
        /*if let module_entity = module.entity
        {
            perform_load_entity(module_entity.clone(recursive: true))
        }*/
        
        model_controller = module.model_controller.copy()
        connector = module.connector.copy()
        
        origin_shift = module.origin_shift
        origin_position = module.default_origin_position
        
        end_entity_name = module.end_entity_name
    }
    
    /// A Boolean value indicating whether a compatible module is available.
    override open var has_avaliable_module: Bool
    {
        return is_internal_module ? Robot.internal_modules.contains(where: { $0.name == module_name }) : Robot.external_modules.contains(where: { $0.name == module_name })
    }
    
    /// A collection of registered internal robot modules.
    nonisolated(unsafe) public static var internal_modules = [RobotModule]()
    
    /// A collection of registered external robot modules.
    nonisolated(unsafe) public static var external_modules = [RobotModule]()
    
    /// Imports a module by name from the registered module pool.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - is_internal: A flag indicating module source.
    public override func import_module(_ name: String, is_internal: Bool = true)
    {
        let modules = is_internal ? Robot.internal_modules : Robot.external_modules
        
        guard let index = modules.firstIndex(where: { $0.name == name })
        else
        {
            return
        }
        
        import_module(modules[index])
    }
    
    /// Registers external modules by their names.
    ///
    /// Existing external modules are replaced.
    ///
    /// - Parameter names: A list of module identifiers.
    public static func import_external_modules(by names: [String])
    {
        Robot.external_modules.removeAll()
        
        for name in names
        {
            Robot.external_modules.append(RobotModule(external_name: name))
        }
    }
    
    /// Performs loading of all internal module entities.
    ///
    /// - Parameter completion: A closure invoked after performing completes.
    public static func load_all_internal_modules_entities(_ completion: @escaping () -> Void = {})
    {
        Task
        {
            for module in Robot.internal_modules
            {
                await module.perform_load_entity_async()
            }
            
            completion()
        }
    }
    
    /// Performs loading of all external module entities.
    ///
    /// - Parameter completion: A closure invoked after performing completes.
    public static func load_all_external_modules_entities(_ completion: @escaping () -> Void = {})
    {
        Task
        {
            for module in Robot.external_modules
            {
                await module.perform_load_entity_async()
            }
            
            completion()
        }
    }
    
    // MARK: - Digital Twin
    /// Defines the operating mode of the robot.
    ///
    /// - simulation: Performs using a virtual model.
    /// - real: Performs on a physical device.
    ///
    /// Changing the mode affects connection and synchronization behavior.
    @Published public var device_mode: DeviceMode = .simulation
    {
        didSet
        {
            if device_mode == .simulation && connector.connected
            {
                reset_moving()
                disconnect_device()
            }
            else if device_mode == .real && is_twin_sync
            {
                connector.model_controller = model_controller
            }
            
            //model_controller.toggle_alt_pointer(device_mode == .simulation)
        }
    }
    
    /// A Boolean value indicating whether digital twin synchronization is enabled.
    ///
    /// When enabled, the model controller state is mirrored to the connector.
    @Published public var is_twin_sync = false
    {
        didSet
        {
            if is_twin_sync
            {
                connector.model_controller = model_controller
            }
            else
            {
                //connector.model_controller?.reset_entities()
                connector.model_controller = nil
            }
        }
    }
    
    /// A controller responsible for robot model performing and kinematics.
    ///
    /// Updating this value reconnects the model entity automatically.
    public var model_controller = RobotModelController()
    {
        didSet // Entities reconnection if model contoller changed
        {
            if let model_entity = model_entity
            {
                model_controller.connect_entities(model_entity, pointer_entity: position_pointer_entity)
                //model_controller.connect_entities(of: model_entity)
            }
        }
    }
    public typealias ModelControllerType = RobotModelController
    
    /// A connector responsible for communication with a real robot device.
    public var connector: RobotConnector = RobotConnector()
    public typealias ConnectorType = RobotConnector
    
    /// Establishes a connection to a real robot device.
    ///
    /// The method performs only when the device mode is set to `.real`.
    public func connect_device()
    {
        guard device_mode == .real else { return }
        
        connector.connect()
    }
    
    /// Disconnects from the real robot device.
    public func disconnect_device()
    {
        connector.model_controller = nil
        connector.disconnect()
    }
    
    private func sync_model_controller_parameters()
    {
        model_controller.origin_position = origin_position
        model_controller.space_scale = space_scale
    }
    
    private func sync_connector_parameters()
    {
        connector.origin_position = origin_position
        connector.space_scale = space_scale
    }
    
    // MARK: - Program Handling
    /// A collection of robot position programs.
    @Published public var programs = [PositionProgram]()
    
    /// The index of the currently selected program.
    ///
    /// Changing this value resets performing state.
    public var selected_program_index = -1
    {
        willSet
        {
            // Stop robot moving before program change
            performed = false
            target_point_index = 0
        }
    }
    
    /// Adds a new position program to the robot.
    ///
    /// - Parameter program: A program to add.
    public func add_program(_ program: PositionProgram)
    {
        program.name = unique_name(for: program.name, in: program_names)
        programs.append(program)
    }
    
    /// Updates a position program by index.
    ///
    /// - Parameters:
    ///   - index: The index of the program.
    ///   - program: A new program value.
    public func update_program(index: Int, _ program: PositionProgram) // Update program by index
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to update
        {
            programs[index] = program
        }
    }
    
    /// Updates a position program by name.
    ///
    /// - Parameters:
    ///   - name: A program identifier.
    ///   - program: A new program value.
    public func update_program(name: String, _ program: PositionProgram)
    {
        update_program(index: index_by_name(name: name), program)
    }
    
    /// Deletes a position program by index.
    ///
    /// - Parameter index: The index of the program to delete.
    public func delete_program(index: Int)
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to delete
        {
            //selected_program.visual_clear()
            programs.remove(at: index)
        }
    }
    
    /// Deletes a position program by name.
    ///
    /// - Parameter name: A program identifier.
    public func delete_program(name: String)
    {
        delete_program(index: index_by_name(name: name))
    }
    
    /// Selects a program by index.
    ///
    /// - Parameter index: A program index.
    public func select_program(index: Int)
    {
        selected_program_index = index
    }
    
    /// Selects a program by name.
    ///
    /// - Parameter name: A program identifier.
    public func select_program(name: String)
    {
        select_program(index: index_by_name(name: name))
    }
    
    /// The currently selected program.
    public func deselect_program()
    {
        reset_moving()
        if selected_program_index > -1 { position_program_entity.isEnabled = false }
        
        selected_program_index = -1
    }
    
    /// A list of all program names.
    public var selected_program: PositionProgram?
    {
        get // Return positions program by selected index
        {
            return programs[safe: selected_program_index]
        }
        set
        {
            programs[safe: selected_program_index] = newValue
        }
    }
    
    /// Returns index by program name.
    private func index_by_name(name: String) -> Int
    {
        return programs.firstIndex(of: PositionProgram(name: name)) ?? -1
    }
    
    /// The total number of programs.
    public var program_names: [String]
    {
        var prog_names = [String]()
        if programs.count > 0
        {
            for program in programs
            {
                prog_names.append(program.name)
            }
        }
        return prog_names
    }
    
    /// The total number of programs.
    public var programs_count: Int
    {
        return programs.count
    }
    
    // MARK: - Moving
    /// Indicates whether the robot is currently performing motion.
    @Published public var performed = false
    
    /// The index of the current target point.
    public var target_point_index = 0
    
    /// The currently selected position point.
    public var selected_position_point: PositionPoint
    {
        get
        {
            return selected_program?.points[safe: target_point_index] ?? PositionPoint()
        }
        set
        {
            selected_program?.points[safe: target_point_index] = newValue
        }
    }
    
    /// The current pointer position of the robot.
    ///
    /// Contains translation (x, y, z) and rotation (r, p, w).
    public var pointer_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            position_point_shift(&pointer_position)
            
            self.objectWillChange.send()
            
            update_model()
            
            func position_point_shift(_ point: inout (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float))
            {
                if point.x > Float(space_scale.x) { point.x = Float(space_scale.x) }
                else if point.x < 0 { point.x = 0 }
                
                if point.y > Float(space_scale.y) { point.y = Float(space_scale.y) }
                else if point.y < 0 { point.y = 0 }
                
                if point.z > Float(space_scale.z) { point.z = Float(space_scale.z) }
                else if point.z < 0 { point.z = 0 }
            }
        }
    }
    
    /// A robot default pointer position.
    private var default_pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)?
    
    /// Stores the current pointer position as the default position.
    ///
    /// This position can later be restored using ``reset_pointer_to_default()``.
    public func set_default_pointer_position()
    {
        default_pointer_position = pointer_position
    }
    
    /// Clears the stored default pointer position.
    ///
    /// After calling this method, ``has_default_position`` returns `false`.
    public func clear_default_pointer_position()
    {
        default_pointer_position = nil
    }
    
    /// Restores the pointer position to the previously stored default value.
    ///
    /// The method performs no action if a default position is not set.
    public func reset_pointer_to_default()
    {
        guard let position = default_pointer_position else { return }
        
        pointer_position = position
    }
    
    /// A Boolean value indicating whether a default pointer position is available.
    public var has_default_position: Bool
    {
        return default_pointer_position != nil
    }
    
    // MARK: Performing
    /// Moves the robot to a specified position.
    ///
    /// - Parameters:
    ///   - point: A target position.
    ///   - completion: A closure invoked after performing completes.
    public func move_to(
        point: PositionPoint,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void = { _ in }
    )
    {
        if update_scope_type == .operational { start_output_updating() } // Device State
        
        performed = true
        
        if device_mode == .simulation
        {
            // Move to target on virtual robot
            pointer_position_to_robot()
            
            model_controller.move_to(point: point)
            { result in
                Task
                { @MainActor in
                    if self.update_scope_type == .operational { self.stop_output_updating() } // Device State
                    
                    self.performed = false
                    
                    switch result
                    {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
        else
        {
            // Move to target on real robot
            pointer_position_to_robot()
            
            connector.move_to(point: point)
            { result in
                Task
                { @MainActor in
                    if self.update_scope_type == .operational { self.stop_output_updating() } // Device State
                    
                    self.performed = false
                    
                    switch result
                    {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Stops current robot motion.
    public func stop()
    {
        if state_update_enabled && update_scope_type == .operational { stop_output_updating() } // Device State
        
        if device_mode == .simulation
        {
            // Remove actions for virtual robot
            model_controller.canceled = true
            //model_controller.reset_entities()
        }
        else
        {
            // Remove actions for real robot
            connector.canceled = true
            connector.reset_device()
        }
    }
    
    /// Toggles start and pause of program performing.
    public func start_pause_moving()
    {
        guard let selected_program = self.selected_program, selected_program.points_count > 0
        else
        {
            finish_handler()
            return
        }
        
        // Robot moving handling
        if !performed
        {
            reset_error()
            
            if device_mode == .real // Pass workcell parameters to model controller
            {
                sync_connector_parameters()
            }
            
            // Move to next point if moving was stop
            performed = false //???
            
            program_performed = true // Control Buttons (UI)
            performing_state = .processing // State light (UI)
            
            move_to_next_point()
        }
        else
        {
            // Remove all action if moving was perform
            pointer_position_to_robot()
            performed = false
            
            //program_performed = false // Control Buttons (UI)
            
            pause_handler()
        }
        
        func pause_handler()
        {
            selected_position_point.performing_state = .current //selected_program.points[target_point_index].performing_state = .current
            
            program_performed = false // Control Buttons (UI)
            performing_state = .current // State light (UI)
            
            if device_mode == .simulation
            {
                model_controller.canceled = true
                //model_controller.reset_entities()
            }
            else
            {
                // Remove actions for real robot
                connector.canceled = true
                connector.reset_device()
            }
        }
    }
    
    /// Moves the robot to the next point in the program sequence.
    public func move_to_next_point()
    {
        selected_position_point.performing_state = .processing
        
        move_to(point: selected_position_point)
        { result in
            Task
            { @MainActor in
                switch result
                {
                case .success:
                    self.selected_position_point.performing_state = .completed
                    self.select_next_point()
                case .failure(let error):
                    self.process_error(error)
                    self.error_handler(error)
                }
            }
        }
    }
    
    /// Resets robot performing state and program progress.
    public func process_error(_ error: Error)
    {
        performed = false // Pause performing
        
        last_error = error
        
        selected_position_point.performing_state = .error
        performing_state = .error // State light (UI)
        
        //model_controller.reset_entities()
        
        if device_mode == .simulation
        {
            //model_controller.reset_entities()
        }
        else
        {
            // Remove actions for real robot
            connector.canceled = true
            connector.reset_device()
        }
        
        program_performed = false // Control Buttons (UI)
    }
    
    /// Selects the next target point and continues program performing.
    private func select_next_point()
    {
        guard let selected_program = self.selected_program
        else
        {
            finish_handler()
            return
        }
        
        if target_point_index < selected_program.points_count - 1
        {
            // Select and move to next point
            target_point_index += 1
            move_to_next_point()
        }
        else
        {
            // Reset target point index if all points passed
            target_point_index = 0
            performed = false
            
            performing_state = .completed // State light (UI)
            program_performed = false // Control Buttons (UI)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
            {
                self.performing_state = .none // State light (UI)
                self.selected_program?.reset_points_states()
            }
            
            pointer_position_to_robot()
            
            finish_handler()
        }
    }
    
    /// A closure invoked when program performing finishes successfully.
    ///
    /// Use this handler to trigger post-processing logic such as UI updates
    /// or workflow continuation.
    public var finish_handler: (() -> Void) = {}
    
    /// Resets the finish handler to an empty closure.
    public func clear_finish_handler()
    {
        finish_handler = {}
    }
    
    /// A closure invoked when an error occurs during program performing.
    ///
    /// - Parameter error: The error describing the failure.
    public var error_handler: ((Error) -> Void) = { _ in }
    
    /// Resets the error handler to a default empty implementation.
    public func clear_error_handler()
    {
        error_handler = { _ in }
    }
    
    /// Resets robot performing state and program progress.
    public func reset_moving()
    {
        guard let selected_program = self.selected_program else { return }
        
        program_performed = false // Control Buttons (UI)
        performing_state = .none // State light (UI)
        
        if performed
        {
            stop()
            
            pointer_position_to_robot()
            performed = false
            
            reset_device_output()
        }
        
        target_point_index = 0
        selected_program.reset_points_states()
        
        reset_error()
    }
    
    /// Pass pointer position from model controller or connector to robot.
    internal func pointer_position_to_robot()
    {
        if device_mode == .simulation
        {
            pointer_position = model_controller.pointer_position
        }
        else
        {
            pointer_position = connector.pointer_position
        }
    }
    
    // MARK: - Device S
    /// The current device output data.
    @Published public var device_output: DeviceOutputData?
    
    /// Indicates whether output updating is active.
    public var is_output_updating = false
    
    /// Enables or disables device state updating.
    public var state_update_enabled = false
    {
        didSet
        {
            if state_update_enabled
            {
                if update_scope_type == .continious
                {
                    start_output_updating()
                }
            }
            else
            {
                stop_output_updating()
            }
        }
    }
    
    /// A task responsible for updating device output.
    public var output_update_task: Task<Void, Never>?
    
    /// The interval between updates in seconds.
    public var state_update_interval: Double = 0.01
    
    /// Defines the update scope behavior.
    public var update_scope_type: ScopeType = ScopeType.operational
    {
        didSet
        {
            stop_output_updating()
            
            if update_scope_type == .continious
            {
                start_output_updating()
            }
        }
    }
    
    /// Stops device output updating loop.
    public func start_output_updating()
    {
        guard state_update_enabled else { return }
        
        is_output_updating = true
        
        output_update_task = Task
        {
            while is_output_updating
            {
                try? await Task.sleep(nanoseconds: UInt64(state_update_interval * 1_000_000_000))
                await MainActor.run
                {
                    self.update_device_output()
                }
                
                if output_update_task == nil
                {
                    return
                }
            }
        }
    }
    
    /// Stops device output updating loop.
    public func stop_output_updating()
    {
        is_output_updating = false
        output_update_task?.cancel()
        output_update_task = nil
    }
    
    /// Updates device output data.
    private func update_device_output()
    {
        if is_output_updating && (performed || update_scope_type == .continious)
        {
            if device_mode == .simulation || (connector.connected && is_twin_sync)
            {
                update_statistics_data()
            }
        }
    }
    
    /// Updates device output data.
    public func update_statistics_data()
    {
        if device_output == nil
        {
            device_output = DeviceOutputData()
        }
        
        if device_mode == .simulation // Get statistic from model controller
        {
            device_output = model_controller.current_device_output
        }
        else // Get statistic from real device
        {
            device_output = connector.current_device_output
        }
    }
    
    /// Resets device output data to initial state.
    public func reset_device_output()
    {
        device_output = nil
        
        if device_mode == .simulation // Get statistic from model controller
        {
            device_output = model_controller.initial_device_output
        }
        else // Get statistic from real device
        {
            device_output = connector.current_device_output
        }
    }
    
    // MARK: - Visal
    #if canImport(RealityKit)
    /// A unique identifier for the robot entity in a 3D scene.
    ///
    /// This value is used to distinguish robot entities from other
    /// workspace objects during scene interaction and processing.
    override public var entity_tag: ObjectEntityIdentifier
    {
        return ObjectEntityIdentifier(type: .robot, name: name)
    }
    
    // MARK: Origin Entity
    /// The root entity representing the robot coordinate system origin.
    ///
    /// This entity acts as a spatial anchor for all robot-related visualization
    /// objects, including the working area, program paths, and pointer markers.
    ///
    /// All transformations applied to the robot workspace are relative to this entity.
    private var origin_entity = Entity()
    
    /// Updates the robot origin position by applying the current origin shift.
    ///
    /// The method:
    /// - Applies `origin_shift` to the base origin position
    /// - Synchronizes updated parameters with the model controller
    /// - Updates the underlying scene entity transform
    ///
    /// This ensures consistency between logical workspace coordinates and
    /// visual representation.
    ///
    /// - Important: Must be called on the main thread due to scene updates.
    @MainActor public func update_origin_position()
    {
        var origin_position = origin_position
        
        origin_position.x += origin_shift.x
        origin_position.y += origin_shift.y
        origin_position.z += origin_shift.z
        
        sync_model_controller_parameters()
        
        origin_entity.update_position(origin_position)
    }
    
    // MARK: Working Area Entity
    /// A visual representation of the robot working volume.
    ///
    /// This entity defines the 3D bounding box of the robot workspace
    /// and is used for visualization and spatial constraints.
    private var working_area_entity = Entity()
    
    /// Toggles visibility of the working area visualization.
    ///
    /// When disabled, the workspace bounding box is hidden from the scene.
    @MainActor public func toggle_working_area_visibility()
    {
        working_area_entity.isEnabled.toggle()
    }
    
    /// Makes the working area visible in the scene.
    @MainActor public func show_working_area()
    {
        working_area_entity.isEnabled = true
    }
    
    /// Hides the working area visualization from the scene.
    @MainActor public func hide_working_area()
    {
        working_area_entity.isEnabled = false
    }
    
    /// Rebuilds the working area visualization using the current workspace scale.
    ///
    /// This method:
    /// - Recreates the 3D bounding box geometry
    /// - Preserves current visibility state
    /// - Reattaches the entity to the origin node
    ///
    /// It is typically called when `space_scale` changes.
    @MainActor public func update_working_area_scale()
    {
        let is_enabled = working_area_entity.isEnabled
        
        working_area_entity.removeFromParent()
        working_area_entity = build_working_area_entity(scale: space_scale)
        working_area_entity.isEnabled = is_enabled
        
        origin_entity.addChild(working_area_entity)
    }
    
    /// Constructs a 3D working area box entity.
    ///
    /// The box is built from semi-transparent planes representing
    /// the six faces of the workspace volume:
    /// - XY planes (red)
    /// - XZ planes (blue)
    /// - YZ planes (green)
    ///
    /// - Parameter scale: The workspace dimensions in millimeters.
    /// - Returns: A fully constructed scene entity representing the workspace volume.
    @MainActor func build_working_area_entity(scale: (x: Float, y: Float, z: Float)) -> Entity
    {
        let box = Entity()
        
        let scale = (x: scale.x / 1000, y: scale.y / 1000, z: scale.z / 1000)
        
        // Transparent materials for each pair of walls (50% opacity)
        let red = UIColor.systemRed.withAlphaComponent(0.5)
        let green = UIColor.systemGreen.withAlphaComponent(0.5)
        let blue = UIColor.systemBlue.withAlphaComponent(0.5)
        
        // Half sizes for positioning
        let hx = scale.x / 2
        let hy = scale.y / 2
        let hz = scale.z / 2
        
        // Nested function to create a single wall
        func make_wall(width: Float, height: Float, color: UIColor, pos: SIMD3<Float>, rot: simd_quatf) -> Entity
        {
            let mesh = MeshResource.generatePlane(width: width, depth: height)
            let wall = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, roughness: 1.0, isMetallic: false)])
            wall.position = pos
            wall.orientation = rot
            return wall
        }
        
        // XY wall (red)
        let pos_x = SIMD3<Float>(hy, 0, hx)
        let rot_pos_x = simd_quatf(angle: .pi/2, axis: [0, 1, 0])
        box.addChild(make_wall(width: scale.x, height: scale.y, color: red, pos: pos_x, rot: rot_pos_x))
        
        // XY wall 2 (red)
        let neg_x = SIMD3<Float>(hy, scale.z, hx)
        let rot_neg_x = simd_mul(simd_quatf(angle: .pi/2, axis: [0, 1, 0]), simd_quatf(angle: .pi, axis: [1,0,0]))
        box.addChild(make_wall(width: scale.x, height: scale.y, color: red, pos: neg_x, rot: rot_neg_x))
        
        // XZ wall (blue)
        let pos_z = SIMD3<Float>(0, hz, hx)
        let rot_pos_z = simd_mul(simd_quatf(angle: .pi/2, axis: [1, 0, 0]), simd_quatf(angle: -.pi/2, axis: [0,0,1]))
        box.addChild(make_wall(width: scale.x, height: scale.z, color: blue, pos: pos_z, rot: rot_pos_z))
        
        // XZ wall 2 (blue)
        let neg_z = SIMD3<Float>(scale.y, hz, hx)
        let rot_neg_z = simd_mul(simd_quatf(angle: .pi/2, axis: [1, 0, 0]), simd_quatf(angle: .pi/2, axis: [0,0,1]))
        box.addChild(make_wall(width: scale.x, height: scale.z, color: blue, pos: neg_z, rot: rot_neg_z))
        
        // YZ wall (green)
        let pos_y = SIMD3<Float>(hy, hz, 0)
        let rot_pos_y = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
        box.addChild(make_wall(width: scale.y, height: scale.z, color: green, pos: pos_y, rot: rot_pos_y))
        
        // YZ wall 2 (green)
        let neg_y = SIMD3<Float>(hy, hz, scale.x)
        let rot_neg_y = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
        box.addChild(make_wall(width: scale.y, height: scale.z, color: green, pos: neg_y, rot: rot_neg_y))
        
        return box
    }
    
    // MARK: Position Pointer Entity
    /// A visual marker representing the robot end-effector pointer orientation.
    ///
    /// The pointer consists of three orthogonal indicators representing
    /// X, Y, and Z axes directions in 3D space.
    private var position_pointer_entity = Entity()
    
    /// Toggles visibility of the position pointer visualization.
    @MainActor public func toggle_position_pointer_visibility()
    {
        position_pointer_entity.isEnabled.toggle()
    }
    
    /// Shows the position pointer in the scene.
    @MainActor public func show_position_pointer()
    {
        position_pointer_entity.isEnabled = true
    }
    
    /// Hides the position pointer from the scene.
    @MainActor public func hide_position_pointer()
    {
        position_pointer_entity.isEnabled = false
    }
    
    /// Builds the 3-axis position pointer visualization.
    ///
    /// The pointer is composed of three directional cones representing
    /// the local orientation axes of the robot end-effector.
    ///
    /// - Returns: A composite entity representing the pointer model.
    @MainActor func build_position_pointer_entity() -> Entity
    {
        let colors: [UIColor] = [
            UIColor.systemIndigo/*.withAlphaComponent(0.75)*/,
            UIColor.systemPink/*.withAlphaComponent(0.75)*/,
            UIColor.systemTeal/*.withAlphaComponent(0.75)*/
        ]
        let rotations: [SIMD3<Float>] = [[.pi/2,0,0],[0,0,-.pi/2],[0,0,0]]
        let positions: [SIMD3<Float>] = [[0,0,Float(0.00425)],[Float(0.00425),0,0],[0,Float(0.00425),0]]
        
        let parent = Entity()
        
        for i in 0..<3
        {
            //let point = ModelEntity(mesh: .generateSphere(radius: Float(0.005)), materials: [SimpleMaterial(color: .white.withAlphaComponent(0.5), roughness: 1.0, isMetallic: false)])
            
            let cone = ModelEntity(mesh: .generateCylinder(height: Float(0.0125), radius: Float(0.002)), materials: [SimpleMaterial(color: colors[i], roughness: 1.0, isMetallic: false)])
            
            cone.position = positions[i]
            cone.euler_angles = rotations[i]
            
            //parent.addChild(point)
            parent.addChild(cone)
        }
        
        return parent
    }
    
    // MARK: Position Program Entity
    /// A visual representation of the currently active position program.
    ///
    /// This entity contains all trajectory points and motion paths
    /// currently assigned to the robot.
    private var position_program_entity = Entity()
    
    /// Toggles visibility of the position program visualization.
    @MainActor public func toggle_position_program_visibility()
    {
        position_program_entity.isEnabled.toggle()
    }
    
    /// Shows the position program in the scene.
    @MainActor public func show_position_program()
    {
        position_program_entity.isEnabled = true
    }
    
    /// Hides the position program visualization.
    @MainActor public func hide_position_program()
    {
        position_program_entity.isEnabled = false
    }
    
    /// Rebuilds the program visualization from a position program model.
    ///
    /// The method:
    /// - Removes previous program visualization
    /// - Generates new trajectory geometry
    /// - Optionally highlights an edited point
    /// - Restores previous visibility state
    ///
    /// - Parameters:
    ///   - program: The position program to visualize.
    ///   - point_index: Optional index of a point being edited.
    @MainActor public func update_program_entity(
        by program: PositionProgram,
        point_index: Int? = nil
    )
    {
        let is_enabled = position_program_entity.isEnabled
        
        position_program_entity.removeFromParent()
        
        position_program_entity = program.entity(point_index)
        position_program_entity.isEnabled = is_enabled
        
        origin_entity.children.forEach {
            if $0 !== position_program_entity {
                $0.removeFromParent()
            }
        }
        
        origin_entity.addChild(position_program_entity)
        
        /*let is_enabled = position_program_entity.isEnabled
        
        position_program_entity.removeFromParent()
        position_program_entity = program.entity(point_index)
        position_program_entity.isEnabled = is_enabled
        
        origin_entity.addChild(position_program_entity)*/
    }
    
    // MARK: End Point Entity
    /// A visual marker representing the final or target endpoint in a program.
    ///
    /// This entity is used to highlight the last position in a sequence
    /// or a selected target point in the workspace visualization.
    public var end_point_entity = Entity()
    
    /// A scene identifier for the robot end-effector entity.
    ///
    /// This value is used to bind the logical robot model to a visual 3D entity
    /// in the scene graph.
    public var end_entity_name = String()
    #endif
    
    /// Updates the robot model state and synchronizes it with the current pointer position.
    ///
    /// In simulation mode:
    /// - Updates pointer position in the model controller
    /// - Performs full kinematic model update
    ///
    /// In real device mode:
    /// - Updates pointer position only
    /// - Delegates execution to external connector system
    ///
    /// This method is skipped when the robot is in performing state.
    public func update_model()
    {
        if !performed
        {
            model_controller.pointer_position = pointer_position
            
            if device_mode == .simulation
            {
                model_controller.update_pointer_position()
                
                do
                {
                    try model_controller.update_model()
                }
                catch
                {
                    //print(error.localizedDescription)
                }
            }
            else
            {
                model_controller.update_pointer_position()//pointer_position)
            }
        }
    }
    
    // MARK: Cell box handling
    /// The default origin position of the robot workspace.
    ///
    /// Defines the initial translation (x, y, z) and rotation (r, p, w)
    /// of the robot coordinate system.
    public static var default_origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// The default scale of the robot workspace.
    ///
    /// Defines the maximum working area dimensions along each axis.
    public static var default_space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    
    /// The origin position of the robot cell.
    public var origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            update_model()
            
            #if canImport(RealityKit)
            update_origin_position()
            #endif
        }
    }
    
    /// The scale of the robot workspace.
    public var space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    {
        didSet
        {
            position_points_shift()
            
            #if canImport(RealityKit)
            update_working_area_scale()
            #endif
        }
    }
    
    /// A positional shift applied to the origin.
    public var origin_shift: (x: Float, y: Float, z: Float) = (x: 0, y: 0, z: 0)
    {
        didSet
        {
            #if canImport(RealityKit)
            update_origin_position()
            #endif
        }
    }
    
    /// Adjusts a position point to fit within workspace bounds.
    ///
    /// - Parameter point: A position point to adjust.
    public func point_shift(_ point: inout PositionPoint)
    {
        if point.x > Float(space_scale.x)
        {
            point.x = Float(space_scale.x)
        }
        else if point.x < 0
        {
            point.x = 0
        }
        
        if point.y > Float(space_scale.y)
        {
            point.y = Float(space_scale.y)
        }
        else if point.y < 0
        {
            point.y = 0
        }
        
        if point.z > Float(space_scale.z)
        {
            point.z = Float(space_scale.z)
        }
        else if point.z < 0
        {
            point.z = 0
        }
    }
    
    private func position_points_shift() // Shifts all positions
    {
        if programs_count > 0
        {
            for program in programs
            {
                if program.points_count > 0
                {
                    for i in 0..<program.points.count
                    {
                        point_shift(&program.points[i])
                    }
                    
                    //program.visual_build()
                }
            }
        }
    }
    
    // MARK: - Performing State
    /// The last error occurred during performing.
    public var last_error: Error?
    
    /// Resets the last performing error.
    public func reset_error()
    {
        last_error = nil
        //performing_state = .processing
    }
    
    /// The current performing state indicator.
    @Published public var performing_state: PerformingState = .none
    
    /// Indicates whether a program is currently being performed.
    @Published public var program_performed = false
    
    // MARK: - File Data
    /// Creates a robot instance from file data.
    ///
    /// - Parameter file: Serialized robot data.
    public convenience init(file: RobotFileData)
    {
        self.init(file: file.object) //self.init()
        
        self.programs = file.programs
        
        self.origin_position = (
            file.origin_location[safe: 0] ?? 0,
            file.origin_location[safe: 1] ?? 0,
            file.origin_location[safe: 2] ?? 0,
            file.origin_rotation[safe: 0] ?? 0,
            file.origin_rotation[safe: 1] ?? 0,
            file.origin_rotation[safe: 2] ?? 0
        )
        
        self.space_scale = (
            file.space_scale[safe: 0] ?? 1,
            file.space_scale[safe: 1] ?? 1,
            file.space_scale[safe: 2] ?? 1
        )
        
        if let pl = file.default_pointer_location,
           let pr = file.default_pointer_rotation
        {
            self.default_pointer_position = (
                pl[safe: 0] ?? 0,
                pl[safe: 1] ?? 0,
                pl[safe: 2] ?? 0,
                pr[safe: 0] ?? 0,
                pr[safe: 1] ?? 0,
                pr[safe: 2] ?? 0
            )
        }
        
        self.state_update_enabled = file.state_update_enabled
        self.state_update_interval = file.state_update_interval
        self.update_scope_type = file.update_scope_type
        self.device_output = file.device_output
        
        self.device_mode = file.device_mode
        self.is_twin_sync = file.is_twin_sync
        self.connector.import_connection_parameters_values(file.connection_parameters)
        
        if self.is_twin_sync
        {
            self.connector.model_controller = self.model_controller
        }
        
        self.reset_pointer_to_default()
    }
    
    /// Generates file data representation of the robot.
    public func file_data() -> RobotFileData
    {
        return RobotFileData(
            object: WorkspaceObjectFileData(
                name: name,
                
                module_name: module_name,
                is_internal_module: is_internal_module,
                
                position: [
                    position.x, position.y, position.z,
                    position.r, position.p, position.w
                ],
                
                is_placed: is_placed
            ),
            
            programs: programs,
            
            origin_location: [origin_position.x, origin_position.y, origin_position.z],
            origin_rotation: [origin_position.r, origin_position.p, origin_position.w],
            space_scale: [space_scale.x, space_scale.y, space_scale.z],
            default_pointer_location: default_pointer_position.map {
                [$0.x, $0.y, $0.z]
            },
            default_pointer_rotation: default_pointer_position.map {
                [$0.r, $0.p, $0.w]
            },
            
            state_update_enabled: state_update_enabled,
            state_update_interval: state_update_interval,
            update_scope_type: update_scope_type,
            device_output: device_output,
            
            device_mode: device_mode,
            
            connection_parameters: connector.connection_parameters_values,
            is_twin_sync: is_twin_sync
        )
    }
    
    /// Creates a robot instance by copying file data from another object.
    ///
    /// - Parameter object: A source robot.
    public convenience init(file_from_object object: Robot)
    {
        let file: RobotFileData = object.file_data()
        self.init(file: file)
    }
}

// MARK: - File Data
/// A serializable representation of a robot state.
///
/// `RobotFileData` stores configuration, programs, spatial parameters,
/// and device state required to reconstruct a robot instance.
public struct RobotFileData: Codable
{
    public var object: WorkspaceObjectFileData
    
    public var programs: [PositionProgram]
    
    public var origin_location: [Float]
    public var origin_rotation: [Float]
    public var space_scale: [Float]
    
    public var default_pointer_location: [Float]?
    public var default_pointer_rotation: [Float]?
    
    public var state_update_enabled: Bool
    public var state_update_interval: Double
    public var update_scope_type: ScopeType
    public var device_output: DeviceOutputData?
    
    public var device_mode: DeviceMode
    public var connection_parameters: [String]?
    public var is_twin_sync: Bool
    
    // MARK: - Init
    public init(
        object: WorkspaceObjectFileData,
        
        programs: [PositionProgram],
        
        origin_location: [Float],
        origin_rotation: [Float],
        space_scale: [Float],
        
        default_pointer_location: [Float]?,
        default_pointer_rotation: [Float]?,
        
        state_update_enabled: Bool,
        state_update_interval: Double,
        update_scope_type: ScopeType,
        device_output: DeviceOutputData?,
        
        device_mode: DeviceMode,
        connection_parameters: [String]?,
        is_twin_sync: Bool
    )
    {
        self.object = object
        
        self.origin_location = origin_location
        self.origin_rotation = origin_rotation
        self.space_scale = space_scale
        
        self.default_pointer_location = default_pointer_location
        self.default_pointer_rotation = default_pointer_rotation
        
        self.device_mode = device_mode
        self.connection_parameters = connection_parameters
        self.is_twin_sync = is_twin_sync
        
        self.state_update_enabled = state_update_enabled
        self.state_update_interval = state_update_interval
        self.update_scope_type = update_scope_type
        self.device_output = device_output
        
        self.programs = programs
    }
}

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

/**
 An industrial robot class.
 
 Permorms reposition operation by target points order in selected positions program.
 */
open class Robot: WorkspaceObject, DeviceTwin, StateOutputCapable
{
    // MARK: - Init functions
    /// Inits robot with default parameters.
    public override init()
    {
        super.init()
    }
    
    /// Inits robot by name.
    public override init(name: String)
    {
        super.init(name: name)
    }
    
    /// Inits robot by name and entity name.
    public override init(
        name: String,
        entity_name: String
    )
    {
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Inits robot by name, entity name, controller and connector.
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
    
    /// Inits robot by name and part module.
    public init(
        name: String,
        module: RobotModule,
        is_internal: Bool = true
    )
    {
        super.init(name: name)
        
        is_internal_module = is_internal
        module_import(module)
    }
    
    public override init(
        name: String,
        module_name: String,
        is_internal: Bool
    )
    {
        super.init(name: name, module_name: module_name, is_internal: is_internal)
    }
    
    private func set_default_cell_parameters()
    {
        self.origin_position = Robot.default_origin_position
        self.space_scale = Robot.default_space_scale
    }
    
    override open func extend_entity_preparation(_ entity: Entity)
    {
        // Place robot accesories
        working_area_entity = build_working_area_entity(scale: space_scale)
        working_area_entity.isEnabled = false
        
        origin_entity.addChild(working_area_entity)
        
        position_pointer_entity = build_position_pointer_entity()
        position_pointer_entity.isEnabled = false
        
        origin_entity.addChild(position_pointer_entity)
        
        //position_program_entity = build_position_program_entity()
        position_program_entity.isEnabled = false
        
        origin_entity.addChild(position_program_entity)
        
        entity.addChild(origin_entity)
        
        // Connect robot parts
        model_controller.disconnect_entities()
        model_controller.connect_entities(entity, pointer_entity: position_pointer_entity)
        
        // Connect end point
        if let end_entity = entity.childEntity(withName: end_entity_name, recursively: true) { end_point_entity = end_entity }
        
        // Apply physics
        entity.apply_physics(
            by: PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .kinematic
            )
        )
        
        update_position()
    }
    
    // MARK: - Module handling
    /**
     Sets modular components to object instance.
     - Parameters:
        - module: A robot module.
     
     Set the following components:
     - Robot Model Entity
     - Robot Model Controller
     - Robot Connector
     */
    public func module_import(_ module: RobotModule)
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
        
        if !(module.model_controller is ExternalRobotModelController)
        {
            model_controller = module.model_controller.copy() as! RobotModelController
        }
        else
        {
            model_controller = module.model_controller
        }
        
        if !(module.connector is ExternalRobotConnector)
        {
            connector = module.connector.copy() as! RobotConnector
        }
        else
        {
            connector = module.connector
        }
        
        model_controller = module.model_controller.copy() as! RobotModelController
        connector = module.connector.copy() as! RobotConnector
        
        origin_shift = module.origin_shift
        origin_position = module.default_origin_position
        
        end_entity_name = module.end_entity_name
    }
    
    override open var has_avaliable_module: Bool
    {
        return is_internal_module ? Robot.internal_modules.contains(where: { $0.name == module_name }) : Robot.external_modules.contains(where: { $0.name == module_name })
    }
    
    /// Imported internal robot modules.
    nonisolated(unsafe) public static var internal_modules = [RobotModule]()
    
    /// Imported external robot modules.
    nonisolated(unsafe) public static var external_modules = [RobotModule]()
    
    public override func module_import_by_name(_ name: String, is_internal: Bool = true)
    {
        let modules = is_internal ? Robot.internal_modules : Robot.external_modules
        
        guard let index = modules.firstIndex(where: { $0.name == name })
        else
        {
            return
        }
        
        module_import(modules[index])
    }
    
    /// Performs loading to all entities from internal modules.
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
    
    /// Performs loading to all entities from external modules.
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
    
    /**
     Imports external modules by names.
     - Parameters:
        - name: A list of external modules names.
     */
    public static func external_modules_import(by names: [String])
    {
        /*#if os(macOS)
        external_modules_servers_stop()
        #endif*/
        
        Robot.external_modules.removeAll()
        
        for name in names
        {
            Robot.external_modules.append(RobotModule(external_name: name))
        }
        
        /*#if os(macOS)
        external_modules_servers_start()
        #endif*/
    }
    
    #if os(macOS)
    /// Start all program components in module.
    public static func external_modules_servers_start()
    {
        Task
        {
            for module in external_modules
            {
                await module.start_program_components()
            }
        }
    }
    
    /// Stop all program components in module.
    public static func external_modules_servers_stop()
    {
        for module in external_modules
        {
            module.stop_program_components()
        }
    }
    #endif
    
    // MARK: - Digital Twin
    /**
     Device state of robot.
     
     If did set *Simulation* – class instance try to connects a real tool by connector.
     If did set *Real* – class instance disconnects from a real tool.
     */
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
    
    /// Updates tool visual model by model controller in connector.
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
    
    /// A robot visual model controller.
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
    
    /// A tool connector.
    public var connector: RobotConnector = RobotConnector()
    public typealias ConnectorType = RobotConnector
    
    /// Connects to real robot.
    public func connect_device()
    {
        guard device_mode == .real else { return }
        
        connector.connect()
    }
    
    /// Disconnects from real robot.
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
    
    // MARK: - Program manage functions
    /// An array of robot positions programs.
    @Published public var programs = [PositionProgram]()
    
    /// A selected positions program index.
    public var selected_program_index = -1
    {
        willSet
        {
            // Stop robot moving before program change
            performed = false
            target_point_index = 0
        }
    }
    
    /**
     Adds new positions program to robot.
     - Parameters:
        - program: A new robot positions program.
     */
    public func add_program(_ program: PositionProgram)
    {
        program.name = mismatched_name(name: program.name, names: programs_names)
        programs.append(program)
    }
    
    /**
     Updates positions program in robot by index.
     - Parameters:
        - index: Updated program index.
        - program: A new robot positions program.
     */
    public func update_program(index: Int, _ program: PositionProgram) // Update program by index
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to update
        {
            programs[index] = program
        }
    }
    
    /**
     Updates positions program by name.
     - Parameters:
        - name: Updated program name.
        - program: A new robot positions program.
     */
    public func update_program(name: String, _ program: PositionProgram)
    {
        update_program(index: index_by_name(name: name), program)
    }
    
    /**
     Deletes positions program in robot by index.
     - Parameters:
        - index: Deleted program index.
     */
    public func delete_program(index: Int)
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to delete
        {
            //selected_program.visual_clear()
            programs.remove(at: index)
        }
    }
    
    /**
     Deletes positions program in robot by name.
     - Parameters:
        - name: Deleted program name.
     */
    public func delete_program(name: String)
    {
        delete_program(index: index_by_name(name: name))
    }
    
    /**
     Selects positions program in robot by index.
     - Parameters:
        - index: Selected program index.
     */
    public func select_program(index: Int)
    {
        selected_program_index = index
    }
    
    /**
     Selects positions program in robot by name.
     - Parameters:
        - name: Selected program name.
     */
    public func select_program(name: String)
    {
        select_program(index: index_by_name(name: name))
    }
    
    /// Deselects positions program in robot.
    public func deselect_program()
    {
        reset_moving()
        if selected_program_index > -1 { position_program_entity.isEnabled = false }
        
        selected_program_index = -1
    }
    
    /// A selected positions program.
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
    
    /// All positions programs names in robot.
    public var programs_names: [String]
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
    
    /// A positions programs coount in robot.
    public var programs_count: Int
    {
        return programs.count
    }
    
    // MARK: - Moving functions
    /// A moving state of robot.
    @Published public var performed = false
    
    /// An Index of target point in points array.
    public var target_point_index = 0
    
    /// A target position in position points array.
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
    
    /**
     A robot pointer position.
     
     Tuple with three coordinates – *x*, *y*, *z* and three angles – *r*, *p*, *w*.
     */
    public var pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            position_point_shift(&pointer_position)
            
            self.objectWillChange.send()
            
            update_position()
            
            func position_point_shift(_ point: inout (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float))
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
        }
    }
    
    /// A robot default pointer position.
    private var default_pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)?
    
    /// Sets default robot pointer position by current pointer position.
    public func set_default_pointer_position()
    {
        default_pointer_position = pointer_position
    }
    
    /// Clears default robot pointer position.
    public func clear_default_pointer_position()
    {
        default_pointer_position = nil
    }
    
    /// Resets robot pointer to default position.
    public func reset_pointer_to_default()
    {
        guard let position = default_pointer_position else { return }
        
        pointer_position = position
    }
    
    /// Returns information about default pointer position avalibility of robot.
    public var has_default_position: Bool
    {
        return default_pointer_position != nil
    }
    
    // MARK: Performation cycle
    /**
     Performs movement on robot by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the robot.
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping @Sendable (Result<Void, Error>) -> Void = { _ in })
    {
        if update_scope_type == .operational { start_update_state() } // Device State
        
        performed = true
        
        if device_mode == .simulation
        {
            // Move to target on virtual robot
            pointer_position_to_robot()
            
            model_controller.move_to(point: point)
            { result in
                Task
                { @MainActor in
                    if self.update_scope_type == .operational { self.stop_update_state() } // Device State
                    
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
                    if self.update_scope_type == .operational { self.stop_update_state() } // Device State
                    
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
    
    /// Stops robot movement.
    public func stop()
    {
        if state_update_enabled && update_scope_type == .operational { stop_update_state() } // Device State
        
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
    
    /// A robot moving performation toggle.
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
    
    /// Performs robot to selected point movement and select next.
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
                    if self.device_mode == .simulation
                    {
                        self.selected_position_point.performing_state = .completed
                    }
                    else if self.connector.connected
                    {
                        self.selected_position_point.performing_state = self.connector.performing_state.output
                    }
                    
                    self.select_next_point()
                case .failure(let error):
                    self.process_error(error)
                    self.error_handler(error)
                }
            }
        }
    }
    
    /**
     Processes an error that occurred during the operation performing.
     - Parameters:
        - error: A robot moving error.
     */
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
    }
    
    /// Set the new target point index.
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
    
    /// Finish handler for to point moving.
    public var finish_handler: (() -> Void) = {}
    
    /// Clears finish handler.
    public func clear_finish_handler()
    {
        finish_handler = {}
    }
    
    /// Error handler for operation program performation.
    public var error_handler: ((Error) -> Void) = { _ in }
    
    /// Clears error handler.
    public func clear_error_handler()
    {
        error_handler = { _ in }
    }
    
    /// Resets robot moving.
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
            
            reset_device_state()
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
            if let controller = connector.model_controller
            {
                pointer_position = controller.pointer_position
            }
        }
    }
    
    // MARK: - Device state data handling
    /// A device state data.
    @Published public var device_state: DeviceState?
    
    /// Flag indicating whether the update loop is active.
    public var is_state_updating = false
    
    /// Device state updating enable.
    public var state_update_enabled = false
    {
        didSet
        {
            if state_update_enabled
            {
                if update_scope_type == .continious
                {
                    start_update_state()
                }
            }
            else
            {
                stop_update_state()
            }
        }
    }
    
    /// The task responsible for executing the update loop.
    public var state_update_task: Task<Void, Never>?
    
    /// The interval between updates in nanoseconds.
    public var state_update_interval: Double = 0.01
    
    /// Defines the update timing scope.
    public var update_scope_type: ScopeType = ScopeType.operational
    {
        didSet
        {
            stop_update_state()
            
            if update_scope_type == .continious
            {
                start_update_state()
            }
        }
    }
    
    /**
     Starts the update loop.
     
     This function sets the `updated` flag to `true` and initiates a new task that repeatedly calls the `update()` function on the main thread.  The loop runs as long as the `updated` flag remains `true`.  A sleep duration of approximately 1 millisecond is introduced between each update cycle. The task can be cancelled by calling `disable_update()`.
     */
    public func start_update_state()
    {
        guard state_update_enabled else { return }
        
        is_state_updating = true
        
        state_update_task = Task
        {
            while is_state_updating
            {
                try? await Task.sleep(nanoseconds: UInt64(state_update_interval * 1_000_000_000))
                await MainActor.run
                {
                    self.update_device_state()
                }
                
                if state_update_task == nil
                {
                    return
                }
            }
        }
    }
    
    /**
     Stops the update loop.
     
     This function sets the `updated` flag to `false`, cancels the `update_task`, and sets it to `nil`.  This effectively terminates the update loop initiated by `perform_update()`.
     */
    public func stop_update_state()
    {
        is_state_updating = false
        state_update_task?.cancel()
        state_update_task = nil
    }
    
    /**
     Called repeatedly within the update loop to perform updates.
     
     This function is called on the main thread by the `perform_update()` function as long as the `updated` flag is `true`. Subclasses should override this method to implement their specific update logic.
     
     > This function is called frequently, so it's crucial to keep its performing time as short as possible to avoid performance issues.
     */
    private func update_device_state()
    {
        if is_state_updating && (performed || update_scope_type == .continious)
        {
            if device_mode == .simulation || (connector.connected && is_twin_sync)
            {
                update_statistics_data()
            }
        }
    }
    
    /// Updates statisitcs data by model controller (if demo is *true*) or connector (if demo is *false*).
    public func update_statistics_data()
    {
        if device_state == nil
        {
            device_state = DeviceState()
        }
        
        if device_mode == .simulation // Get statistic from model controller
        {
            device_state = model_controller.current_device_state
        }
        else // Get statistic from real device
        {
            device_state = connector.current_device_state
        }
    }
    
    /// Clears device state data.
    public func reset_device_state()
    {
        device_state = nil
        
        if device_mode == .simulation // Get statistic from model controller
        {
            device_state = model_controller.initial_device_state
        }
        else // Get statistic from real device
        {
            device_state = connector.initial_device_state
        }
    }
    
    // MARK: - Visual Functions
    #if canImport(RealityKit)
    override public var entity_tag: EntityModelIdentifier
    {
        return EntityModelIdentifier(type: .robot, name: name)
    }
    
    // MARK: Origin Entity
    private var origin_entity = Entity()
    
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
    private var working_area_entity = Entity()
    
    @MainActor public func toggle_working_area_visibility()
    {
        working_area_entity.isEnabled.toggle()
    }
    
    @MainActor public func show_working_area()
    {
        working_area_entity.isEnabled = true
    }
    
    @MainActor public func hide_working_area()
    {
        working_area_entity.isEnabled = false
    }
    
    @MainActor public func update_working_area_scale()
    {
        let is_enabled = working_area_entity.isEnabled
        
        working_area_entity.removeFromParent()
        working_area_entity = build_working_area_entity(scale: space_scale)
        working_area_entity.isEnabled = is_enabled
        
        origin_entity.addChild(working_area_entity)
    }
    
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
    private var position_pointer_entity = Entity()
    
    @MainActor public func toggle_position_pointer_visibility()
    {
        position_pointer_entity.isEnabled.toggle()
    }
    
    @MainActor public func show_position_pointer()
    {
        position_pointer_entity.isEnabled = true
    }
    
    @MainActor public func hide_position_pointer()
    {
        position_pointer_entity.isEnabled = false
    }
    
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
            cone.eulerAngles = rotations[i]
            
            //parent.addChild(point)
            parent.addChild(cone)
        }
        
        return parent
    }
    
    //MARK: Position Program Entity
    private var position_program_entity = Entity()
    
    @MainActor public func toggle_position_program_visibility()
    {
        position_program_entity.isEnabled.toggle()
    }
    
    @MainActor public func show_position_program()
    {
        position_program_entity.isEnabled = true
    }
    
    @MainActor public func hide_position_program()
    {
        position_program_entity.isEnabled = false
    }
    
    @MainActor public func update_position_program_entity(by program: PositionProgram, edited_point: Int? = nil)
    {
        let is_enabled = position_program_entity.isEnabled
        
        position_program_entity.removeFromParent()
        position_program_entity = program.entity(edited_point)
        position_program_entity.isEnabled = is_enabled
        
        origin_entity.addChild(position_program_entity)
    }
    
    // MARK: End Point Entity
    /*private*/ var end_point_entity = Entity()
    
    public var end_entity_name = String()
    #endif
    
    /// Sets robot pointer node position.
    public func update_position()
    {
        if !performed
        {
            if device_mode == .simulation
            {
                model_controller.pointer_position = pointer_position
                
                do
                {
                    try model_controller.update_model()
                }
                catch
                {
                    print(error.localizedDescription)
                }
            }
            else
            {
                model_controller.alt_pointer_position = pointer_position
            }
        }
    }
    
    // MARK: Cell box handling
    /// A default location of robot cell origin.
    public static var default_origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// A default scale of robot cell box.
    public static var default_space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    
    /**
     A robot cell origin position.
     
     Tuple with coordinates – *x*, *y*, *z* and angles – *r*, *p*, *w*.
     */
    public var origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            update_position()
            
            #if canImport(RealityKit)
            update_origin_position()
            #endif
        }
    }
    
    /// A robot cell box scale.
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
    
    /// A robot cell box default shift.
    public var origin_shift: (x: Float, y: Float, z: Float) = (x: 0, y: 0, z: 0)
    {
        didSet
        {
            #if canImport(RealityKit)
            update_origin_position()
            #endif
        }
    }
    
    /**
     Shifts positions when reducing the robot workcell area.
     
     - Parameters:
        - point: The position to which the shifting is applied.
     */
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
    /// Last performing error.
    public var last_error: Error?
    
    /// Resets last hanled error.
    public func reset_error()
    {
        last_error = nil
        //performing_state = .processing
    }
    
    /// Performing state light.
    @Published public var performing_state: PerformingState = .none
    
    /// A program performing state of robot.
    @Published public var program_performed = false
    
    // MARK: - Work with file system
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
        self.device_state = file.device_state
        
        self.device_mode = file.device_mode
        self.is_twin_sync = file.is_twin_sync
        self.connector.import_connection_parameters_values(file.connection_parameters)
        
        if self.is_twin_sync
        {
            self.connector.model_controller = self.model_controller
        }
        
        self.reset_pointer_to_default()
    }
    
    public func file_data() -> RobotFileData
    {
        return RobotFileData(
            object: WorkspaceObjectFileData(
                name: name,
                
                module_name: module_name,
                is_internal_module: is_internal_module,
                
                location: [position.x, position.y, position.z],
                rotation: [position.r, position.p, position.w],
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
            device_state: device_state,
            
            device_mode: device_mode,
            
            connection_parameters: connector.connection_parameters_values,
            is_twin_sync: is_twin_sync
        )
    }

    public convenience init(file_from_object object: Robot)
    {
        let file: RobotFileData = object.file_data()
        self.init(file: file)
    }
}

// MARK: - File Data
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
    public var device_state: DeviceState?
    
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
        device_state: DeviceState?,
        
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
        self.device_state = device_state
        
        self.programs = programs
    }
}

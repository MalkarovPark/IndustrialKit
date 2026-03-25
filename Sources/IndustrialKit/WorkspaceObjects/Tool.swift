//
//  Tool.swift
//  IndustrialKit
//
//  Created by Artem on 01.06.2022.
//

import Foundation

//import SwiftUI
#if canImport(RealityKit)
import RealityKit
#endif

/**
 An industrial tool class.
 
 Permorms operation by codes order in selected operations program.
 */
open class Tool: WorkspaceObject, DeviceTwin, StateOutputCapable
{
    // MARK: - Init functions
    public override init()
    {
        current_operation = OperationCode(0)
        
        super.init()
    }
    
    /// Inits tool by name.
    public override init(name: String)
    {
        current_operation = OperationCode(0)
        
        super.init(name: name)
    }
    
    public override init(name: String, entity_name: String)
    {
        current_operation = OperationCode(0)
        
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Inits tool by name, entity name, controller and connector.
    public init(
        name: String,
        entity_name: String,
        
        model_controller: ToolModelController = ToolModelController(),
        connector: ToolConnector = ToolConnector(),
        
        codes: [OperationCodeInfo] = [OperationCodeInfo]()
    )
    {
        current_operation = OperationCode(0)
        
        super.init(name: name, entity_name: entity_name)
        
        self.model_controller = model_controller
        self.connector = connector
        
        self.codes = codes
        
        current_operation = OperationCode(codes.first?.value ?? 0)
    }
    
    /// Inits part by name and tool module.
    public init(
        name: String,
        module: ToolModule,
        
        is_internal: Bool = true
    )
    {
        current_operation = OperationCode(0)
        
        super.init(name: name)
        
        is_internal_module = is_internal
        import_module(module)
    }
    
    public override init(
        name: String,
        module_name: String,
        
        is_internal: Bool
    )
    {
        current_operation = OperationCode(0)
        
        super.init(name: name, module_name: module_name, is_internal: is_internal)
    }
    
    override open func extend_entity_preparation(_ entity: Entity)
    {
        // Connect tool parts
        model_controller.disconnect_entities()
        model_controller.connect_entities(of: entity)
        
        // Apply physics
        update_model_physics()
        /*entity.apply_physics(
            by: PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .kinematic
            )
        )*/
    }
    
    // MARK: - Module handling
    /**
     Sets modular components to object instance.
     - Parameters:
        - module: A tool module.
     
     Set the following components:
     - Scene Node
     - Tool Model Controller
     - Tool Connector
     - Codes
     */
    public func import_module(_ module: ToolModule)
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
        
        /*if !(module.connector is ExternalToolConnector)
        {
            connector = module.connector.copy() as! ToolConnector
        }
        else
        {
            connector = module.connector
        }*/
        
        codes = module.codes
        
        current_operation = OperationCode(codes.first?.value ?? 0)
    }
    
    override open var has_avaliable_module: Bool
    {
        return is_internal_module ? Tool.internal_modules.contains(where: { $0.name == module_name }) : Tool.external_modules.contains(where: { $0.name == module_name })
    }
    
    /// Imported internal tool modules.
    nonisolated(unsafe) public static var internal_modules = [ToolModule]()
    
    /// Imported external tool modules.
    nonisolated(unsafe) public static var external_modules = [ToolModule]()
    
    public override func import_module(_ name: String, is_internal: Bool = true)
    {
        let modules = is_internal ? Tool.internal_modules : Tool.external_modules
        
        guard let index = modules.firstIndex(where: { $0.name == name })
        else
        {
            return
        }
        
        import_module(modules[index])
    }
    
    /**
     Imports external modules by names.
     - Parameters:
        - name: A list of external modules names.
     */
    public static func import_external_modules(by names: [String])
    {
        Tool.external_modules.removeAll()
        
        for name in names
        {
            Tool.external_modules.append(ToolModule(external_name: name))
        }
    }
    
    /// Performs loading to all entities from internal modules.
    public static func load_all_internal_modules_entities(_ completion: @escaping () -> Void = {})
    {
        Task
        {
            for module in Tool.internal_modules
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
            for module in Tool.external_modules
            {
                await module.perform_load_entity_async()
            }
            
            completion()
        }
    }
    
    // MARK: - Digital Twin
    /**
     Device state of tool.
     
     If did set *Simulation* – class instance try to connects a real tool by connector.
     If did set *Real* – class instance disconnects from a real tool.
     */
    @Published public var device_mode: DeviceMode = .simulation
    {
        didSet
        {
            if device_mode == .simulation && connector.connected
            {
                reset_performing()
                disconnect_device()
            }
            else if device_mode == .real && is_twin_sync
            {
                connector.model_controller = model_controller
            }
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
    
    /// A tool visual model controller.
    public var model_controller = ToolModelController()
    {
        didSet // Entities reconnection if model contoller changed
        {
            if let model_entity = model_entity
            {
                model_controller.connect_entities(of: model_entity)
            }
        }
    }
    public typealias ModelControllerType = ToolModelController
    
    /// A tool connector.
    public var connector: ToolConnector = ToolConnector()
    public typealias ConnectorType = ToolConnector
    
    /// Connects to real tool.
    public func connect_device()
    {
        guard device_mode == .real else { return }
        
        connector.connect()
    }
    
    /// Disconnects from real tool.
    public func disconnect_device()
    {
        connector.disconnect()
    }
    
    // MARK: - Program manage functions
    /// An array of tool operations programs.
    @Published public var programs = [OperationProgram]()
    
    /// A selected operations program index.
    public var selected_program_index = -1
    {
        willSet
        {
            // Stop tool performing before program change
            performed = false
            selected_code_index = 0
        }
    }
    
    /**
     Adds new operations program to tool.
     - Parameters:
        - program: A new tool operations program.
     */
    public func add_program(_ program: OperationProgram)
    {
        program.name = unique_name(for: program.name, in: programs_names)
        programs.append(program)
    }
    
    /**
     Updates operations program in tool by index.
     - Parameters:
        - index: Updated program index.
        - program: A new tool operations program.
     */
    public func update_program(index: Int, _ program: OperationProgram) // Update program by index
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to update
        {
            programs[index] = program
        }
    }
    
    /**
     Updates operations program by name.
     - Parameters:
        - name: Updated program name.
        - program: A new tool operations program.
     */
    public func update_program(name: String, _ program: OperationProgram) // Update program by name
    {
        update_program(index: index_by_name(name: name), program)
    }
    
    /**
     Deletes operations program in tool by index.
     - Parameters:
        - index: Deleted program index.
     */
    public func delete_program(index: Int) // Delete program by index
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to delete
        {
            programs.remove(at: index)
        }
    }
    
    /**
     Deletes operations program in tool by name.
     - Parameters:
        - name: Deleted program name.
     */
    public func delete_program(name: String) // Delete program by name
    {
        delete_program(index: index_by_name(name: name))
    }
    
    /**
     Selects operations program in tool by index.
     - Parameters:
        - index: Selected program index.
     */
    public func select_program(index: Int) // Delete program by index
    {
        selected_program_index = index
    }
    
    /// Deselects operations program in robot.
    public func deselect_program()
    {
        reset_performing()
        self.objectWillChange.send()
        
        selected_program_index = -1
    }
    
    /**
     Selects operations program in tool by name.
     - Parameters:
        - name: Selected program name.
     */
    public func select_program(name: String) // Select program by name
    {
        select_program(index: index_by_name(name: name))
    }
    
    /// A selected operations program.
    public var selected_program: OperationProgram?
    {
        get // Return operations program by selected index
        {
            return programs[safe: selected_program_index]
        }
        set
        {
            programs[safe: selected_program_index] = newValue
        }
    }
    
    /// Returns index by program name.
    private func index_by_name(name: String) -> Int // Get index of program by name
    {
        return programs.firstIndex(of: OperationProgram(name: name)) ?? -1
    }
    
    /// All operations programs names in tool.
    public var programs_names: [String] // Get all names of programs in tool
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
    
    /// A operations programs coount in tool.
    public var programs_count: Int
    {
        return programs.count
    }
    
    // MARK: Single operation handling
    /// An array of avaliable operation codes values for tool.
    @Published public var codes = [OperationCodeInfo]()
    
    /// Single pendant operation.
    @Published public var current_operation: OperationCode
    
    private var is_single_performed = false
    
    private var previous_performing_state: PerformingState = .none
    
    public func start_pause_single_operation()
    {
        if !is_single_performed
        {
            single_operation_perform()
        }
        else
        {
            single_operation_reset()
        }
    }
    
    public func single_operation_perform()
    {
        if !is_single_performed
        {
            is_single_performed = true
            
            previous_performing_state = performing_state != .completed ? performing_state : .none
            performing_state = .processing
            
            perform(code: current_operation.value)
            { result in
                Task
                { @MainActor in
                    switch result
                    {
                    case .success:
                        self.performing_state = .completed
                    case .failure(let error):
                        self.performing_state = .error
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                    {
                        self.performing_state = self.previous_performing_state //.none
                    }
                    
                    self.is_single_performed = false
                }
            }
        }
    }
    
    public func single_operation_reset()
    {
        if is_single_performed
        {
            is_single_performed = false
            stop()
            performing_state = previous_performing_state //.none
        }
    }
    
    // MARK: - Performing functions
    /// A moving state of tool.
    public var performed = false
    
    /// An Index of target code in operation codes array.
    public var selected_code_index = 0
    
    /// A target code in operation codes array.
    public var selected_operation_code: OperationCode
    {
        get
        {
            return selected_program?.codes[safe: selected_code_index] ?? OperationCode(0)
        }
        set
        {
            selected_program?.codes[safe: selected_code_index] = newValue
        }
    }
    
    // MARK: Performation cycle
    /**
     Performs tool by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool.
        - completion: A completion function that is calls when the performing completes.
     */
    public func perform(
        code: Int,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void = { _ in }
    )
    {
        if update_scope_type == .operational { start_output_updating() } // Device State
        
        performed = true
        
        if device_mode == .simulation
        {
            // Perform operation on virtual tool
            model_controller.perform(code: code)
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
            // Perform operation on real tool
            connector.perform(code: code)
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
    
    /// Stops tool movement.
    public func stop()
    {
        if state_update_enabled && update_scope_type == .operational { stop_output_updating() } // Device State
        
        if device_mode == .simulation
        {
            // Remove actions for virtural tool
            model_controller.canceled = true
            model_controller.reset_entities()
        }
        else
        {
            // Remove actions for real tool
            connector.canceled = true
            connector.reset_device()
        }
    }
    
    /// A tool performation toggle.
    public func start_pause_performing()
    {
        single_operation_reset()
        
        guard let selected_program = self.selected_program, selected_program.codes_count > 0
        else
        {
            finish_handler()
            return
        }
        
        // Tool performing handling
        if !performed
        {
            reset_error()
            
            /*if !demo // Pass workcell parameters to model controller
            {
                sync_connector_parameters()
            }*/
            
            // Perform next code if performing was stop
            performed = false //???
            
            program_performed = true // Control Buttons (UI)
            performing_state = .processing // State light (UI)
            
            perform_next_code()
        }
        else
        {
            // Remove all action if moving was perform
            performed = false
            
            pause_handler()
        }
        
        func pause_handler()
        {
            selected_operation_code.performing_state = .current //selected_program.codes[selected_code_index].performing_state = .current
            
            program_performed = false // Control Buttons (UI)
            performing_state = .current // State light (UI)
            
            stop()
        }
    }
    
    /// Selects a code and performs the corresponding operation.
    public func perform_next_code()
    {
        selected_operation_code.performing_state = .processing
        
        perform(code: selected_operation_code.value)
        { result in
            Task
            { @MainActor in
                switch result
                {
                case .success:
                    self.selected_operation_code.performing_state = .completed
                    self.select_next_code()
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
        - error: A tool performing error.
     */
    public func process_error(_ error: Error)
    {
        performed = false // Pause performing
        
        last_error = error
        
        selected_operation_code.performing_state = .error
        performing_state = .error // State light (UI)
        
        model_controller.reset_entities()
        
        if device_mode == .simulation
        {
            //model_controller.reset_entities()
        }
        else
        {
            // Remove actions for real tool
            connector.canceled = true
            connector.reset_device()
        }
        
        program_performed = false // Control Buttons (UI)
    }
    
    /// Set the new target operation code index.
    private func select_next_code()
    {
        guard let selected_program = self.selected_program
        else
        {
            finish_handler()
            return
        }
        
        if selected_code_index < selected_program.codes_count - 1
        {
            // Select and perform next code
            selected_code_index += 1
            perform_next_code()
        }
        else
        {
            // Reset target point index if all points passed
            selected_code_index = 0
            performed = false
            
            performing_state = .completed // State light (UI)
            program_performed = false // Control Buttons (UI)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
            {
                self.performing_state = .none // State light (UI)
                self.selected_program?.reset_codes_states()
            }
            
            finish_handler()
        }
    }
    
    /// Finish handler for operation program performation.
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
    
    /// Resets tool operation performation.
    public func reset_performing()
    {
        guard let selected_program = self.selected_program else { return }
        
        program_performed = false // Control Buttons (UI)
        performing_state = .none // State light (UI)
        
        if performed
        {
            if !is_single_performed { stop() } // If reset from program
            
            performed = false
            
            //clear_chart_data()
        }
        
        selected_code_index = 0
        selected_program.reset_codes_states()
        
        reset_error()
    }
    
    // MARK: - Reality Functions
    #if canImport(RealityKit)
    override public var entity_tag: EntityModelIdentifier
    {
        return EntityModelIdentifier(type: .tool, name: name)
    }
    #endif
    
    /// A name of the robot that the tool is attached to.
    public var attached_to: String?
    
    override public func on_remove()
    {
        attached_to = nil
    }
    
    // MARK: - Device state data handling
    /// A device state data.
    @Published public var device_output: DeviceOutputData?
    
    /// Flag indicating whether the update loop is active.
    public var is_output_updating = false
    
    /// Device state updating enable.
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
    
    /// The task responsible for executing the update loop.
    public var output_update_task: Task<Void, Never>?
    
    /// The interval between updates in nanoseconds.
    public var state_update_interval: Double = 0.01
    
    /// Defines the update timing scope.
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
    
    /**
     Starts the update loop.
     
     This function sets the `updated` flag to `true` and initiates a new task that repeatedly calls the `update()` function on the main thread.  The loop runs as long as the `updated` flag remains `true`.  A sleep duration of approximately 1 millisecond is introduced between each update cycle. The task can be cancelled by calling `disable_update()`.
     */
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
    
    /**
     Stops the update loop.
     
     This function sets the `updated` flag to `false`, cancels the `update_task`, and sets it to `nil`.  This effectively terminates the update loop initiated by `perform_update()`.
     */
    public func stop_output_updating()
    {
        is_output_updating = false
        output_update_task?.cancel()
        output_update_task = nil
    }
    
    /**
     Called repeatedly within the update loop to perform updates.
     
     This function is called on the main thread by the `perform_update()` function as long as the `updated` flag is `true`. Subclasses should override this method to implement their specific update logic.
     
     > This function is called frequently, so it's crucial to keep its performing time as short as possible to avoid performance issues.
     */
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
    
    /// Updates statisitcs data by model controller (if demo is *true*) or connector (if demo is *false*).
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
    
    /// Clears device state data.
    public func reset_device_output()
    {
        device_output = nil
        
        if device_mode == .simulation  // Get statistic from model controller
        {
            device_output = model_controller.initial_device_output
        }
        else // Get statistic from real device
        {
            device_output = connector.initial_device_output
        }
    }
    
    // MARK: - Physics
    /**
     Physics body data of part.
     
     > This variable is codable.
     */
    @Published public var physics_body_data: PhysicsBodyComponentFileData = PhysicsBodyComponentFileData(mode: ._kinematic)
    
    /// The state of physics calculation for part node.
    public var physics_enabled = false
    {
        didSet
        {
            update_model_physics()
        }
    }
    
    public func update_model_physics()
    {
        if physics_enabled
        {
            entity.apply_physics(by: physics_body_data.component)
        }
        else
        {
            entity.visit
            { child in
                child.components.remove(PhysicsBodyComponent.self)
                child.components.remove(PhysicsMotionComponent.self)
            }
        }
    }
    
    // MARK: - UI functions
    /// Apply corresponded label and SF Symbol to operation code.
    public func code_info(_ value: Int) -> OperationCodeInfo
    {
        let index = codes.firstIndex(where: { $0.value == value }) ?? -1
        if codes.indices.contains(index)
        {
            return self.codes[index]
        }
        else
        {
            return OperationCodeInfo()
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
    public convenience init(file: ToolFileData)
    {
        self.init(file: file.object) //self.init()
        
        self.programs = file.programs
        
        self.codes = file.codes
        
        self.attached_to = file.attached_to
        
        self.state_update_enabled = file.state_update_enabled
        self.state_update_interval = file.state_update_interval
        self.update_scope_type = file.update_scope_type
        self.device_output = file.device_output
        
        self.device_mode = file.device_mode
        self.is_twin_sync = file.is_twin_sync
        self.connector.import_connection_parameters_values(file.connection_parameters)
        
        self.physics_enabled = file.physics_enabled
        self.physics_body_data = file.physics_body_data
        
        if self.is_twin_sync
        {
            self.connector.model_controller = self.model_controller
        }
    }
    
    public func file_data() -> ToolFileData
    {
        return ToolFileData(
            object: WorkspaceObjectFileData(
                name: name,
                
                module_name: module_name,
                is_internal_module: is_internal_module,
                
                location: [position.x, position.y, position.z],
                rotation: [position.r, position.p, position.w],
                is_placed: is_placed
            ),
            
            programs: programs,
            
            codes: codes,
            
            attached_to: attached_to,
            
            state_update_enabled: state_update_enabled,
            state_update_interval: state_update_interval,
            update_scope_type: update_scope_type,
            device_output: device_output,
            
            device_mode: device_mode,
            connection_parameters: connector.connection_parameters_values,
            is_twin_sync: is_twin_sync,
            
            physics_enabled: physics_enabled,
            physics_body_data: physics_body_data
        )
    }
    
    public convenience init(file_from_object object: Tool)
    {
        let file: ToolFileData = object.file_data()
        self.init(file: file)
    }
}

// MARK: - File Data
public struct ToolFileData: Codable
{
    public var object: WorkspaceObjectFileData
    
    public var programs: [OperationProgram]
    
    public var codes: [OperationCodeInfo]
    
    public var attached_to: String?
    
    public var state_update_enabled: Bool
    public var state_update_interval: Double
    public var update_scope_type: ScopeType
    public var device_output: DeviceOutputData?
    
    public var device_mode: DeviceMode
    public var connection_parameters: [String]?
    public var is_twin_sync: Bool
    
    public var physics_enabled: Bool = true
    public var physics_body_data: PhysicsBodyComponentFileData = PhysicsBodyComponentFileData()
    
    // MARK: Init
    public init(
        object: WorkspaceObjectFileData,
        
        programs: [OperationProgram],
        
        codes: [OperationCodeInfo],
        
        attached_to: String?,
        
        state_update_enabled: Bool,
        state_update_interval: Double,
        update_scope_type: ScopeType,
        device_output: DeviceOutputData?,
        
        device_mode: DeviceMode,
        connection_parameters: [String]?,
        is_twin_sync: Bool,
        
        physics_enabled: Bool,
        physics_body_data: PhysicsBodyComponentFileData
    )
    {
        self.object = object
        
        self.programs = programs
        
        self.codes = codes
        
        self.attached_to = attached_to
        
        self.state_update_enabled = state_update_enabled
        self.state_update_interval = state_update_interval
        self.update_scope_type = update_scope_type
        self.device_output = device_output
        
        self.device_mode = device_mode
        self.connection_parameters = connection_parameters
        self.is_twin_sync = is_twin_sync
        
        self.physics_enabled = physics_enabled
        self.physics_body_data = physics_body_data
    }
}

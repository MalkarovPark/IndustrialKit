//
//  Tool.swift
//  IndustrialKit
//
//  Created by Artem on 01.06.2022.
//

import Foundation
#if canImport(RealityKit)
import RealityKit
#endif

/// A robotic device that performs specialized operations within a workspace.
///
/// A tool represents a class of robotic devices that do not implement
/// the full functionality of a robot.
///
/// A tool can operate either as:
/// - An independent device
/// - An end-effector mounted on a robot via a mechanical interface
///
/// Tool behavior is defined using operation codes (``OperationCode``),
/// where each code corresponds to a specific operation or a set of parameters.
///
/// A sequence of operation codes forms an operational program
/// (``OperationProgram``), which defines the performing logic of the tool.
///
/// The available operation codes are described by ``OperationCodeInfo``
/// instances, which provide metadata and semantic meaning of each operation.
///
/// Use the ``perform(_:)`` method to initiate performing of an operation
/// associated with a given ``OperationCode``.
///
open class Tool: WorkspaceObject, DeviceTwin, StateOutputCapable
{
    // MARK: - Initializers
    /// Creates a tool instance with default parameters.
    public override init()
    {
        current_operation = OperationCode(0)
        
        super.init()
    }
    
    /// Creates a tool with a specified name.
    ///
    /// - Parameter name: A human-readable identifier of the tool.
    public override init(name: String)
    {
        current_operation = OperationCode(0)
        
        super.init(name: name)
    }
    
    /// Creates a tool with a name and associated entity resource.
    ///
    /// - Parameters:
    ///   - name: A human-readable identifier.
    ///   - entity_name: A name of the associated scene entity.
    public override init(
        name: String,
        entity_name: String
    )
    {
        current_operation = OperationCode(0)
        
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Creates a fully configured tool instance.
    ///
    /// - Parameters:
    ///   - name: A human-readable identifier.
    ///   - entity_name: A name of the associated scene entity.
    ///   - model_controller: A controller responsible for model performing.
    ///   - connector: A connector responsible for device communication.
    ///   - codes: A list of supported operation codes.
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
    
    /// Creates a tool instance from a module configuration.
    ///
    /// - Parameters:
    ///   - name: A tool identifier.
    ///   - module: A tool module defining structure and behavior.
    ///   - is_internal: A flag indicating whether the module is internal.
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
    
    /// Creates a tool instance using a module name.
    ///
    /// - Parameters:
    ///   - name: A tool identifier.
    ///   - module_name: A module identifier.
    ///   - is_internal: A flag indicating internal or external module source.
    public override init(
        name: String,
        module_name: String,
        
        is_internal: Bool
    )
    {
        current_operation = OperationCode(0)
        
        super.init(name: name, module_name: module_name, is_internal: is_internal)
    }
    
    // MARK: - Entity Preparation
    /// Extends entity preparation by connecting model components and applying physics.
    ///
    /// - Parameter entity: A root entity representing the tool.
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
    
    // MARK: - Module Handling
    /// Imports a tool module and configures the tool instance.
    ///
    /// The method assigns model controller, connector, and operation codes
    /// from the module. Entity loading is performed asynchronously.
    ///
    /// - Parameter module: A tool module describing structure and behavior.
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
        
        codes = module.codes
        
        current_operation = OperationCode(codes.first?.value ?? 0)
    }
    
    /// Indicates whether a compatible module is available for the tool.
    override open var has_avaliable_module: Bool
    {
        return is_internal_module ? Tool.internal_modules.contains(where: { $0.name == module_name }) : Tool.external_modules.contains(where: { $0.name == module_name })
    }
    
    /// A collection of registered internal tool modules.
    nonisolated(unsafe) public static var internal_modules = [ToolModule]()
    
    /// A collection of registered external tool modules.
    nonisolated(unsafe) public static var external_modules = [ToolModule]()
    
    /// Imports a module by name from registered modules.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - is_internal: A flag indicating module source.
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
    
    /// Registers external tool modules by their names.
    ///
    /// Existing external modules are replaced.
    ///
    /// - Parameter names: A list of module identifiers.
    public static func import_external_modules(by names: [String])
    {
        Tool.external_modules.removeAll()
        
        for name in names
        {
            Tool.external_modules.append(ToolModule(external_name: name))
        }
    }
    
    /// Performs loading of all internal module entities.
    ///
    /// - Parameter completion: A callback invoked after performing completes.
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
    
    /// Performs loading of all external module entities.
    ///
    /// - Parameter completion: A callback invoked after performing completes.
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
    /// Defines the operating mode of the tool.
    ///
    /// - simulation: Performs using a virtual model.
    /// - real: Performs on a physical device.
    ///
    /// Switching modes affects connection and performing behavior.
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
    
    /// Enables synchronization between the digital twin and the real device.
    ///
    /// When enabled, the model controller is linked to the connector.
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
    
    /// A controller responsible for tool model performing.
    ///
    /// Updating this value reconnects entities automatically.
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
    
    /// A communication interface for controlling a real tool device.
    public var connector: ToolConnector = ToolConnector()
    public typealias ConnectorType = ToolConnector
    
    /// Establishes connection to the real tool.
    ///
    /// The connection is performed only in `.real` mode.
    public func connect_device()
    {
        guard device_mode == .real else { return }
        
        connector.connect()
    }
    
    /// Disconnects from the real tool device.
    public func disconnect_device()
    {
        connector.disconnect()
    }
    
    // MARK: - Program Handling
    /// A collection of operation programs available for performing.
    @Published public var programs = [OperationProgram]()
    
    /// Index of the selected program.
    public var selected_program_index = -1
    {
        willSet
        {
            // Stop tool performing before program change
            performed = false
            selected_code_index = 0
        }
    }
    
    /// Adds a new operation program.
    ///
    /// - Parameter program: A program to add.
    public func add_program(_ program: OperationProgram)
    {
        program.name = unique_name(for: program.name, in: programs_names)
        programs.append(program)
    }
    
    /// Updates a program at the specified index.
    ///
    /// - Parameters:
    ///   - index: Program index.
    ///   - program: A new program instance.
    public func update_program(
        index: Int,
        _ program: OperationProgram
    )
    {
        if programs.indices.contains(index)
        {
            programs[index] = program
        }
    }
    
    /// Updates a program by name.
    ///
    /// - Parameters:
    ///   - name: Program identifier.
    ///   - program: A new program instance.
    public func update_program(
        name: String,
        _ program: OperationProgram
    )
    {
        update_program(index: index_by_name(name: name), program)
    }
    
    /// Deletes a program at the specified index.
    ///
    /// - Parameter index: Program index.
    public func delete_program(index: Int)
    {
        if programs.indices.contains(index)
        {
            programs.remove(at: index)
        }
    }
    
    /// Deletes a program by name.
    ///
    /// - Parameter name: Program identifier.
    public func delete_program(name: String)
    {
        delete_program(index: index_by_name(name: name))
    }
    
    /// Selects a program by index.
    ///
    /// - Parameter index: Program index.
    public func select_program(index: Int)
    {
        selected_program_index = index
    }
    
    /// Selects a program by name.
    ///
    /// - Parameter name: Program identifier.
    public func select_program(name: String)
    {
        select_program(index: index_by_name(name: name))
    }
    
    /// Deselects the current program and resets performing state.
    public func deselect_program()
    {
        reset_performing()
        self.objectWillChange.send()
        
        selected_program_index = -1
    }
    
    /// The currently selected program.
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
    
    /// All operations program names in tool.
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
    
    /// A operation programs coount in tool.
    public var programs_count: Int
    {
        return programs.count
    }
    
    // MARK: - Single Operation
    /// A collection of available operation codes.
    @Published public var codes = [OperationCodeInfo]()
    
    /// The current operation code.
    @Published public var current_operation: OperationCode
    
    private var is_single_performed = false
    
    private var previous_performing_state: PerformingState = .none
    
    /// Toggles performing of a single operation.
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
    
    /// Performs a single operation.
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
    
    /// Stops a single operation.
    public func single_operation_reset()
    {
        if is_single_performed
        {
            is_single_performed = false
            stop()
            performing_state = previous_performing_state //.none
        }
    }
    
    // MARK: - Performing
    /// Indicates whether the tool is currently performing.
    public var performed = false
    
    /// Index of the selected operation code.
    public var selected_code_index = 0
    
    /// The currently selected operation code.
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
    
    /// Performs an operation by code value.
    ///
    /// - Parameters:
    ///   - code: Operation code value.
    ///   - completion: A callback invoked after performing completes.
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
    
    /// Stops tool performing.
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
    
    /// Performs the next operation in the program.
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
    
    /// Processes an error that occurred during performing.
    ///
    /// - Parameter error: An error describing the failure.
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
    
    /// Processes an error that occurred during performing.
    ///
    /// - Parameter error: An error describing the failure.
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
    
    /// Selects the next operation code and continues program performing.
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
    
    /// A closure invoked when program performing finishes successfully.
    ///
    /// Use this handler to trigger post-performing actions such as UI updates
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
    
    /// Resets tool performing state and program progress.
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
    
    // MARK: - Attachment
    /// The name of the robot the tool is attached to.
    public var attached_to: String?
    
    /// Called when the tool is removed from the workspace.
    override public func on_remove()
    {
        attached_to = nil
    }
    
    /// Local position of the tool relative to its attachment.
    ///
    /// Includes translation (*x*, *y*, *z*) and rotation (*r*, *p*, *w*).
    @Published public var local_position: (
        x: Float, y: Float, z: Float,
        r: Float, p: Float, w: Float
    ) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            if attached_to != nil
            {
                entity.update_position(local_position)
            }
        }
    }
    
    // MARK: - Reality Functions
    #if canImport(RealityKit)
    override public var entity_tag: ObjectEntityIdentifier
    {
        return ObjectEntityIdentifier(type: .tool, name: name)
    }
    
    public func set_local_position()
    {
        entity.update_position(local_position)
    }
    
    public func set_global_position()
    {
        entity.update_position(position)
    }
    #endif
    
    // MARK: - Device State
    /// Current device output data.
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
    
    /// Task responsible for updating device state.
    public var output_update_task: Task<Void, Never>?
    
    /// Interval between state updates.
    public var state_update_interval: Double = 0.01
    
    /// Defines update scope type.
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
    
    /// Stops device state updating loop.
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
    
    /// Stops device state updating loop.
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
    
    /// Updates statistics data from model or connector.
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
    
    /// Resets device output data.
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
    /// Physics body configuration of the tool.
    @Published public var physics_body_data: PhysicsBodyComponentFileData = PhysicsBodyComponentFileData(mode: ._kinematic)
    
    /// Indicates whether physics simulation is enabled.
    public var physics_enabled = true
    {
        didSet
        {
            update_model_physics()
        }
    }
    
    /// Updates physics state of the model.
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
    
    // MARK: - UI
    /// Returns metadata for an operation code.
    ///
    /// - Parameter value: Operation code value.
    /// - Returns: Associated operation code info.
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
    /// Last error that occurred during performing.
    public var last_error: Error?
    
    /// Current performing state.
    public func reset_error()
    {
        last_error = nil
        //performing_state = .processing
    }
    
    /// Current performing state.
    @Published public var performing_state: PerformingState = .none
    
    /// Indicates whether a program is being performed.
    @Published public var program_performed = false
    
    // MARK: - File Data
    /// Creates a tool from file data.
    ///
    /// - Parameter file: A serialized tool representation.
    public convenience init(file: ToolFileData)
    {
        self.init(file: file.object)
        
        self.programs = file.programs
        
        self.codes = file.codes
        
        self.attached_to = file.attached_to
        
        self.local_position = (
            file.local_position[safe: 0] ?? 0,
            file.local_position[safe: 1] ?? 0,
            file.local_position[safe: 2] ?? 0,
            file.local_position[safe: 3] ?? 0,
            file.local_position[safe: 4] ?? 0,
            file.local_position[safe: 5] ?? 0
        )
        
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
    
    /// Returns a serializable representation of the tool.
    public func file_data() -> ToolFileData
    {
        return ToolFileData(
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
            
            codes: codes,
            
            attached_to: attached_to,
            local_position: [
                local_position.x, local_position.y, local_position.z,
                local_position.r, local_position.p, local_position.w
            ],
            
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
    
    /// Creates a tool by copying another instance.
    public convenience init(file_from_object object: Tool)
    {
        let file: ToolFileData = object.file_data()
        self.init(file: file)
    }
}

// MARK: - Tool File Data
/// A serializable representation of a tool.
///
/// This structure contains all data required to restore tool state,
/// including programs, configuration, device parameters, and physics.
/// 
public struct ToolFileData: Codable
{
    public var object: WorkspaceObjectFileData
    
    public var programs: [OperationProgram]
    
    public var codes: [OperationCodeInfo]
    
    public var attached_to: String?
    public var local_position: [Float] // [x, y, z, r, p, w]
    
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
        local_position: [Float],
        
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
        self.local_position = local_position
        
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

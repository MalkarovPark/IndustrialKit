//
//  Tool.swift
//  IndustrialKit
//
//  Created by Artem on 01.06.2022.
//

import Foundation

import SwiftUI
#if canImport(RealityKit)
import RealityKit
#endif

/**
 An industrial tool class.
 
 Permorms operation by codes order in selected operations program.
 */
open class Tool: WorkspaceObject
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
    public init(name: String, entity_name: String, model_controller: ToolModelController = ToolModelController(), connector: ToolConnector = ToolConnector(), codes: [OperationCodeInfo] = [OperationCodeInfo]())
    {
        current_operation = OperationCode(0)
        
        super.init(name: name, entity_name: entity_name)
        
        self.model_controller = model_controller
        self.connector = connector
        
        apply_statistics_flags()
        
        self.codes = codes
        
        current_operation = OperationCode(codes.first?.value ?? 0)
    }
    
    /// Inits part by name and tool module.
    public init(name: String, module: ToolModule, is_internal: Bool = true)
    {
        current_operation = OperationCode(0)
        
        super.init(name: name)
        
        is_internal_module = is_internal
        module_import(module)
    }
    
    public override init(name: String, module_name: String, is_internal: Bool)
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
        /*entity.apply_physics(
            by: PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .kinematic
            )
        )*/
    }
    
    //MARK: Model Controller and Connector
    /// A tool visual model controller.
    public var model_controller = ToolModelController()
    {
        didSet // Entities reconnection if model contoller changed
        {
            if let entity = model_entity
            {
                model_controller.connect_entities(of: entity)
            }
        }
    }
    
    /**
     Updates tool visual model by model controller in connector.
     
     Called on the SCNScene *rendrer* function.
     */
    public var update_model_by_connector = false
    {
        didSet
        {
            if update_model_by_connector
            {
                connector.model_controller = model_controller
            }
            else
            {
                connector.model_controller?.reset_entities()
                connector.model_controller = nil
            }
        }
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
    public func module_import(_ module: ToolModule)
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
        
        if !(module.model_controller is ExternalToolModelController)
        {
            model_controller = module.model_controller.copy() as! ToolModelController
        }
        else
        {
            model_controller = module.model_controller
        }
        
        if !(module.connector is ExternalToolConnector)
        {
            connector = module.connector.copy() as! ToolConnector
        }
        else
        {
            connector = module.connector
        }
        
        model_controller = module.model_controller.copy() as! ToolModelController
        connector = module.connector.copy() as! ToolConnector
        
        apply_statistics_flags()
        
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
    
    public override func module_import_by_name(_ name: String, is_internal: Bool = true)
    {
        let modules = is_internal ? Tool.internal_modules : Tool.external_modules
        
        guard let index = modules.firstIndex(where: { $0.name == name })
        else
        {
            return
        }
        
        module_import(modules[index])
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
        
        Tool.external_modules.removeAll()
        
        for name in names
        {
            Tool.external_modules.append(ToolModule(external_name: name))
        }
        
        /*#if os(macOS)
        external_modules_servers_start()
        #endif*/
    }
    
    /// Performs loading to all entities from internal modules.
    public static func load_all_internal_modules_entities()
    {
        for module in Tool.internal_modules
        {
            module.perform_load_entity()
        }
    }
    
    /// Performs loading to all entities from external modules.
    public static func load_all_external_modules_entities()
    {
        for module in Tool.external_modules
        {
            module.perform_load_entity()
        }
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
        /*for module in external_modules
        {
            module.start_program_components()
        }*/
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
    
    private func apply_statistics_flags()
    {
        model_controller.get_statistics = get_statistics
        connector.get_statistics = get_statistics
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
        program.name = mismatched_name(name: program.name, names: programs_names)
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
    
    // MARK: - Info codes functions
    /// An array of avaliable operation codes values for tool.
    @Published public var codes = [OperationCodeInfo]()
    
    /// An information output code.
    public var info_output: [Float]?
    {
        if demo
        {
            return model_controller.info_output
        }
        else
        {
            if connector.connected
            {
                return connector.info_output
            }
            else
            {
                return nil
            }
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
    
    /**
     Demo state of tool.
     
     If did set *true* – class instance try to connects a real tool by connector.
     If did set *false* – class instance disconnects from a real tool.
     */
    public var demo = true
    {
        didSet
        {
            if demo && connector.connected
            {
                reset_performing()
                disconnect()
            }
            else if !demo && update_model_by_connector
            {
                connector.model_controller = model_controller
            }
        }
    }
    
    // MARK: Update functions
    /// Updates tool statistics and sync model by real device state.
    public override func update()
    {
        if get_statistics && (performed || scope_type == .constant)
        {
            if demo || (connector.connected && update_model_by_connector)
            {
                update_statistics_data()
            }
        }
    }
    
    // MARK: Performation cycle
    /**
     Performs tool by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool.
        - completion: A completion function that is calls when the performing completes.
     */
    public func perform(code: Int, completion: @escaping @Sendable (Result<Void, Error>) -> Void = { _ in })
    {
        performed = true
        
        if demo
        {
            // Perform operation on virtual tool
            model_controller.perform(code: code)
            { result in
                Task
                { @MainActor in
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
        if demo
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
            //pointer_position_to_robot()
            performed = false
            
            //program_performed = false // Control Buttons (UI)
            
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
                    if self.demo
                    {
                        self.selected_operation_code.performing_state = .completed
                    }
                    else if self.connector.connected
                    {
                        self.selected_operation_code.performing_state = self.connector.performing_state.output
                    }
                    
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
        
        if demo
        {
            //model_controller.reset_entities()
        }
        else
        {
            // Remove actions for real tool
            connector.canceled = true
            connector.reset_device()
        }
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
            
            update()
            //pointer_position_to_robot()
            
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
            
            clear_chart_data()
        }
        
        selected_code_index = 0
        selected_program.reset_codes_states()
        
        reset_error()
    }
    
    // MARK: - Connection functions
    /// A tool connector.
    public var connector = ToolConnector()
    
    /// Disconnects from real tool.
    private func disconnect()
    {
        // connector.update_model = false
        connector.model_controller = nil
        connector.disconnect()
    }
    
    // MARK: - Visual Functions
    #if canImport(RealityKit)
    override public var entity_tag: EntityModelIdentifier
    {
        return EntityModelIdentifier(type: .tool, name: name)
    }
    #endif
    
    /*/// A flag determines if tool is attached to the robot manipulator.
    public var is_attached = false*/
    
    /// A name of the robot that the tool is attached to.
    public var attached_to: String?
    
    override public func on_remove()
    {
        attached_to = nil
    }
    
    // MARK: - Chart functions
    /// A tool charts data.
    @Published public var charts_data: [WorkspaceObjectChart]?
    
    /// A tool state data.
    @Published public var states_data: [StateItem]?
    
    /// A statistics getting toggle.
    public var get_statistics = false
    {
        didSet
        {
            if demo
            {
                model_controller.get_statistics = get_statistics
            }
            else
            {
                connector.get_statistics = get_statistics
            }
        }
    }
    
    /// Index of chart element.
    private var chart_element_index = 0
    
    /// Update statisitcs data by model controller (if demo is *true*) or connector (if demo is *false*).
    public func update_statistics_data()
    {
        if charts_data == nil
        {
            charts_data = [WorkspaceObjectChart]()
        }
        
        if self.demo // Get statistic from model controller
        {
            self.model_controller.update_statistics_data()
            self.states_data = model_controller.states_data
            self.charts_data = model_controller.charts_data
        }
        else // Get statistic from real tool
        {
            self.connector.update_statistics_data()
            self.states_data = connector.states_data
            self.charts_data = connector.charts_data
        }
    }
    
    /// Clears tool chart data.
    public func clear_chart_data()
    {
        charts_data = nil
        
        if demo
        {
            model_controller.reset_charts_data()
        }
        else
        {
            connector.reset_charts_data()
        }
        
        /*if get_statistics
        {
            if demo
            {
                model_controller.reset_charts_data()
            }
            else
            {
                connector.reset_charts_data()
            }
        }*/
    }
    
    /// Clears tool state data.
    public func clear_states_data()
    {
        states_data = nil
        
        if demo
        {
            model_controller.reset_states_data()
        }
        else
        {
            connector.reset_states_data()
        }
        
        /*if get_statistics
        {
            if demo
            {
                model_controller.reset_states_data()
            }
            else
            {
                connector.reset_states_data()
            }
        }*/
    }
    
    // MARK: - UI functions
    /**
     Returns info for tool card view.
     
     Output avaliable codes count. If their number is zero, the instrument is listed as *static*.
     */
    /*public override var card_info: (title: String, subtitle: String, color: Color, image: UIImage, node: SCNNode) // Get info for robot card view
    {
        return("\(self.name)", "\(self.module_name)", .teal, UIImage(), SCNNode())
        //return("\(self.name)", self.codes.count > 0 ? "\(self.codes.count) code tool" : "Static tool", .teal, UIImage(), node: SCNNode()) // Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255)
    }*/
    
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
    
    /// Connects tool charts to UI.
    public func charts_binding() -> Binding<[WorkspaceObjectChart]?>
    {
        Binding<[WorkspaceObjectChart]?>(
            get:
            {
                if self.demo
                {
                    self.model_controller.charts_data
                }
                else
                {
                    self.connector.charts_data
                }
            },
            set:
            { value in
                self.charts_data = value
            }
        )
    }
    
    /// Connects tool charts to UI.
    public func states_binding() -> Binding<[StateItem]?>
    {
        Binding<[StateItem]?>(
            get:
            {
                if self.demo
                {
                    self.model_controller.states_data
                }
                else
                {
                    self.connector.states_data
                }
            },
            set:
            { value in
                self.states_data = value
            }
        )
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
        
        self.codes = file.codes
        
        //self.is_attached = file.is_attached
        self.attached_to = file.attached_to
        
        self.demo = file.demo
        self.update_model_by_connector = file.update_model_by_connector
        
        self.get_statistics = file.get_statistics
        self.charts_data = file.charts_data
        self.states_data = file.states_data
        
        self.programs = file.programs
        
        self.connector.import_connection_parameters_values(file.connection_parameters)
        
        if self.update_model_by_connector
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
                is_placed: is_placed,
                
                update_interval: update_interval,
                scope_type: scope_type
            ),
            
            codes: codes,
            
            //is_attached: is_attached,
            attached_to: attached_to,
            
            demo: demo,
            connection_parameters: connector.connection_parameters_values,
            update_model_by_connector: update_model_by_connector,
            
            get_statistics: get_statistics,
            charts_data: charts_data,
            states_data: states_data,
            
            programs: programs
        )
    }
    
    public convenience init(file_from_object object: Tool)
    {
        let file: ToolFileData = object.file_data()
        self.init(file: file)
    }
}

/**
 Provides information about the operation code.
 
 An array of them determines the opcode values ​​available for a given device.
 */
public struct OperationCodeInfo: Equatable, Codable, Hashable
{
    /// Operation code value.
    public var value: Int
    
    /// Operation code name.
    public var name: String
    
    /// Operation code symbol.
    public var symbol: String
    
    /// Operation code info.
    public var info: String
    
    public init(value: Int = 0, name: String = "", symbol: String = "", info: String = "")
    {
        self.value = value
        self.name = name
        self.symbol = symbol
        self.info = info
    }
    
    public var image: Image
    {
        return Image(systemName: symbol)
    }
}

// MARK: - File Data
public struct ToolFileData: Codable
{
    public var object: WorkspaceObjectFileData
    
    public var codes: [OperationCodeInfo]
    
    //public var is_attached: Bool
    public var attached_to: String?
    
    public var demo: Bool
    public var connection_parameters: [String]?
    public var update_model_by_connector: Bool
    
    public var get_statistics: Bool
    public var charts_data: [WorkspaceObjectChart]?
    public var states_data: [StateItem]?
    
    public var programs: [OperationProgram]
    
    // MARK: Init
    public init(
        object: WorkspaceObjectFileData,
        
        codes: [OperationCodeInfo],
        
        //is_attached: Bool,
        attached_to: String?,
        
        demo: Bool,
        connection_parameters: [String]?,
        update_model_by_connector: Bool,
        
        get_statistics: Bool,
        charts_data: [WorkspaceObjectChart]?,
        states_data: [StateItem]?,
        
        programs: [OperationProgram]
    )
    {
        self.object = object
        
        self.codes = codes
        
        //self.is_attached = is_attached
        self.attached_to = attached_to
        
        self.demo = demo
        self.connection_parameters = connection_parameters
        self.update_model_by_connector = update_model_by_connector
        
        self.get_statistics = get_statistics
        self.charts_data = charts_data
        self.states_data = states_data
        
        self.programs = programs
    }
}

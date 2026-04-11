//
//  Workspace.swift
//  IndustrialKit
//
//  Created by Artem on 05.12.2021.
//

import Foundation

#if canImport(RealityKit)
import RealityKit
#endif
import SwiftUI

/**
 A basis of industrial technological complex including production equipment.
 
 Performs management of the production complex.
 
 Also can build a visual model of the production system with editing functions.
 */
@MainActor public class Workspace: ObservableObject, @unchecked Sendable
{
    // MARK: - Init functions
    /// Initializes an empty workspace instance.
    ///
    /// Creates default runtime state including:
    /// - A default `RobotPerformerElement` as current element
    /// - A register memory block with default size
    /// - Empty collections of robots, tools, and parts
    public init()
    {
        current_element = RobotPerformerElement()//MarkLogicElement(name: "")
        
        registers = [Float](repeating: 0, count: Workspace.default_registers_count)
    }
    
    // MARK: - Production Objects
    /// Collection of robots currently registered in the workspace.
    ///
    /// Each robot represents a programmable production unit capable of executing
    /// motion and operation programs.
    @Published public var robots = [Robot]()
    
    /// Collection of tools currently registered in the workspace.
    ///
    /// Tools represent executable end-effectors or functional devices used
    /// within production programs.
    @Published public var tools = [Tool]()
    
    /// Collection of parts currently registered in the workspace.
    ///
    /// Parts represent passive production objects manipulated by robots or tools.
    @Published public var parts = [Part]()
    
    /// Returns index of a production object by name within a given collection.
    ///
    /// - Parameters:
    ///   - name: Target object name.
    ///   - objects: Collection of production objects to search.
    ///
    /// - Returns: Index of object if found, otherwise `-1`.
    private func object_index(of name: String, in objects: [ProductionObject]) -> Int
    {
        return objects.firstIndex(where: { $0.name == name }) ?? -1
    }
    
    /// Currently selected production object in the workspace.
    ///
    /// Can be a robot, tool, or part. Selection affects camera focus,
    /// program context, and interaction state.
    @Published public var selected_object: ProductionObject?
    
    /// Selects a production object and updates workspace interaction state.
    ///
    /// This method:
    /// - Clears previous selection
    /// - Disables pointer interaction temporarily
    /// - Selects the appropriate object type handler
    /// - Focuses camera on the selected entity (macOS/iOS)
    /// - Enables interaction pointer if applicable
    ///
    /// - Parameter object: Object to be selected (Robot, Tool, or Part)
    public func select_object(_ object: ProductionObject)
    {
        deselect_object() // Test
        pointer_entity.isEnabled = false
        
        deselect_program()
        
        switch object
        {
        case is Robot:
            select_robot(named: object.name)
            pointer_entity.isEnabled = true
        case is Tool:
            select_tool(named: object.name)
            pointer_entity.isEnabled = true
        case is Part:
            select_part(named: object.name)
            pointer_entity.isEnabled = true
        default:
            break
        }
        
        #if os(macOS) || os(iOS)
        // Camera pivot reposition
        if let selected_object = selected_object
        {
            focus(on: selected_object.entity)
        }
        #endif
        
        self.objectWillChange.send() // UI only
    }
    
    /// Deselects currently active production object.
    ///
    /// Performs cleanup depending on object type:
    /// - Robot: stops program and disables visual aids
    /// - Tool: stops program execution
    /// - Part: no additional cleanup
    ///
    /// Also clears program selection state if no object is active.
    public func deselect_object()
    {
        switch selected_object
        {
        case let robot as Robot:
            robot.deselect_program() // Deselect program
            
            // Disable accessories
            robot.toggle_position_pointer_visibility()
            robot.toggle_working_area_visibility()
        case let tool as Tool:
            tool.deselect_program() // Deselect program
        case let part as Part:
            break
        default:
            deselect_program()
        }
        
        selected_object = nil
    }
    
    /// Removes a production object from the workspace and scene.
    ///
    /// This method:
    /// - Removes the entity from the scene graph
    /// - Clears camera focus
    /// - Deletes object from its corresponding collection
    ///
    /// - Parameter object: Object to be removed
    public func delete_object(_ object: ProductionObject)
    {
        #if os(macOS) || os(iOS)
        focus(on: nil)
        #endif
        
        object.entity.removeFromParent() //Change to separate removes for objects?
        
        switch selected_object
        {
        case is Robot:
            robots.removeAll(where: { $0.name == object.name })
        case is Tool:
            tools.removeAll(where: { $0.name == object.name })
        case is Part:
            parts.removeAll(where: { $0.name == object.name })
        default:
            break
        }
    }
    
    // MARK: - Program Management
    /// Collection of production programs available in workspace.
    ///
    /// Programs define ordered sequences of `ProductionProgramElement`
    /// executed by robots or tools.
    @Published public var programs = [ProductionProgram]()
    
    /// Index of currently selected production program.
    ///
    /// Changing this value resets execution state and selected element index.
    public var selected_program_index = -1
    {
        willSet
        {
            // Stop workspace performing before program change
            performed = false
            selected_element_index = 0
        }
    }
    
    /// Adds a new production program to the workspace.
    ///
    /// Automatically ensures unique program name before insertion.
    ///
    /// - Parameter program: Program to be added
    public func add_program(_ program: ProductionProgram)
    {
        program.name = unique_name(for: program.name, in: program_names)
        programs.append(program)
    }
    
    /// Updates an existing program at a given index.
    ///
    /// - Parameters:
    ///   - index: Program index in collection
    ///   - program: New program instance
    public func update_program(at index: Int, with program: ProductionProgram) // Update program by index
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to update
        {
            programs[index] = program
        }
    }
    
    /// Updates an existing program by name lookup.
    ///
    /// - Parameters:
    ///   - name: Program name
    ///   - program: Replacement program instance
    public func update_program(named name: String, with program: ProductionProgram) // Update program by name
    {
        update_program(at: index_by_name(name: name), with: program)
    }
    
    /// Deletes a program by index.
    ///
    /// - Parameter index: Index of program to remove
    public func delete_program(at index: Int) // Delete program by index
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to delete
        {
            programs.remove(at: index)
        }
    }
    
    /// Deletes a program by name.
    ///
    /// - Parameter name: Program identifier
    public func delete_program(named name: String) // Delete program by name
    {
        delete_program(at: index_by_name(name: name))
    }
    
    /// Selects a program by index and validates its elements.
    ///
    /// Performs integrity check of all program elements after selection.
    ///
    /// - Parameter index: Program index
    public func select_program(at index: Int)
    {
        selected_program_index = index
        
        if let selected_program = selected_program // Elements check on program selection
        {
            elements_check(program: selected_program)
        }
    }
    
    /// Deselects current program and resets execution state.
    ///
    /// Stops all performing processes and resets execution index.
    public func deselect_program()
    {
        reset_performing()
        self.objectWillChange.send()
        
        selected_program_index = -1
    }
    
    /// Selects a program by its name.
    ///
    /// - Parameter name: Program identifier
    public func select_program(named name: String) // Select program by name
    {
        select_program(at: index_by_name(name: name))
    }
    
    /// Currently active production program.
    ///
    /// Provides safe access to program at `selected_program_index`.
    public var selected_program: ProductionProgram?
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
    
    /// Returns program index by name.
    ///
    /// - Parameter name: Program name
    /// - Returns: Index or `-1` if not found
    private func index_by_name(name: String) -> Int // Get index of program by name
    {
        return programs.firstIndex(of: ProductionProgram(name: name)) ?? -1
    }
    
    /// List of all program names in workspace.
    ///
    /// Used for UI display and validation of program references.
    public var program_names: [String] // Get all names of programs in tool
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
    
    /// Number of programs in workspace.
    public var programs_count: Int
    {
        return programs.count
    }
    
    // MARK: Single Element Processing
    /// Currently active program element for single-step execution.
    ///
    /// Used when executing or debugging a single operation outside full program cycle.
    @Published public var current_element: ProductionProgramElement
    
    private var is_single_performed = false
    
    private var previous_performing_state: PerformingState = .none
    
    /// Starts or pauses single element execution.
    ///
    /// Toggles between execution and reset states.
    public func start_pause_single_element()
    {
        if !is_single_performed
        {
            perform_single_element()
        }
        else
        {
            single_operation_reset()
        }
    }
    
    /// Executes a single program element asynchronously.
    ///
    /// Updates performing state and handles completion callback.
    public func perform_single_element()
    {
        if !is_single_performed
        {
            is_single_performed = true
            
            previous_performing_state = performing_state != .completed ? performing_state : .none
            performing_state = .processing
            
            if let selected_program = selected_program
            {
                selected_program.set_mark_index(for: current_element)
            }
            
            if let element = current_element as? ChangerModifierElement
            {
                changer_element_check(element)
            }
            
            perform(element: current_element)
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
    
    /// Resets single element execution state.
    ///
    /// Restores previous performing state if execution was interrupted.
    public func single_operation_reset()
    {
        if is_single_performed
        {
            is_single_performed = false
            performing_state = previous_performing_state
        }
    }
    
    // MARK: Element Validation
    /// Validates all elements of a production program.
    ///
    /// Ensures consistency between:
    /// - Selected robots/tools existence
    /// - Available program names
    /// - Mark references for logic elements
    /// - Module availability for changer elements
    ///
    /// Automatically repairs invalid references where possible.
    ///
    /// - Parameter program: Program to validate
    public func elements_check(program: ProductionProgram)
    {
        for element in program.elements
        {
            switch element
            {
            case let element as RobotPerformerElement:
                robot_element_check(element)
            case let element as ToolPerformerElement:
                tool_element_check(element)
            case let element as ObserverModifierElement:
                observer_element_check(element)
            case let element as ChangerModifierElement:
                changer_element_check(element)
            case let element as JumpLogicElement:
                jump_element_check(element)
            case let element as ComparatorLogicElement:
                comparator_element_check(element)
            default:
                break
            }
        }
        
        func robot_element_check(_ element: RobotPerformerElement) // Check element by selected robot exists
        {
            var checked_object = robot(named: element.object_name)
            
            if checked_object.is_placed
            {
                program_check()
            }
            else
            {
                objects_check()
            }
            
            func objects_check()
            {
                if placed_robot_names.count > 0
                {
                    element.object_name = placed_robot_names.first ?? ""
                    checked_object = robot(named: element.object_name)
                    program_check()
                }
                else
                {
                    element.object_name = ""
                    element.program_name = ""
                }
            }
            
            func program_check()
            {
                if checked_object.programs_count > 0
                {
                    if !checked_object.program_names.contains(element.program_name)
                    {
                        element.program_name = checked_object.program_names.first ?? ""
                    }
                }
                else
                {
                    element.program_name = ""
                }
            }
        }
        
        func tool_element_check(_ element: ToolPerformerElement)
        {
            var checked_object = tool(named: element.object_name)
            
            if checked_object.is_placed
            {
                program_check()
            }
            else
            {
                objects_check()
            }
            
            func objects_check()
            {
                if placed_tool_names.count > 0
                {
                    element.object_name = placed_tool_names.first ?? ""
                    checked_object = tool(named: element.object_name)
                    program_check()
                }
                else
                {
                    element.object_name = ""
                    element.program_name = ""
                }
            }
            
            func program_check()
            {
                if checked_object.programs_count > 0
                {
                    if !checked_object.program_names.contains(element.program_name)
                    {
                        element.program_name = checked_object.program_names.first ?? ""
                    }
                }
                else
                {
                    element.program_name = ""
                }
            }
        }
        
        func observer_element_check(_ element: ObserverModifierElement)
        {
            switch element.object_type
            {
            case .robot:
                if self.placed_robot_names.count > 0
                {
                    element.object_name = self.placed_robot_names.first!
                }
                else
                {
                    element.object_name = ""
                }
            case .tool:
                if self.placed_tool_names.count > 0
                {
                    element.object_name = self.placed_tool_names.first!
                }
                else
                {
                    element.object_name = ""
                }
            }
        }
        
        /*func changer_element_check(_ element: ChangerModifierElement)
        {
            if element.module_name.isEmpty
            {
                element.module_import_by_name(element.module_name, is_internal: !element.module_name.hasPrefix("."))
                
                if !Changer.internal_modules_list.contains(element.module_name)
                {
                    if Changer.internal_modules_list.count > 0
                    {
                        element.module_name = Changer.internal_modules_list.first!
                    }
                    else
                    {
                        element.module_name = "None"
                    }
                }
                else if !Changer.external_modules_list.contains(element.module_name)
                {
                    if Changer.external_modules_list.count > 0
                    {
                        element.module_name = Changer.external_modules_list.first!
                    }
                    else
                    {
                        element.module_name = "None"
                    }
                }
            }
        }*/
        
        func jump_element_check(_ element: JumpLogicElement)
        {
            mark_check(name: &element.target_mark_name)
        }
        
        func comparator_element_check(_ element: ComparatorLogicElement) // Check element by selected mark exists
        {
            mark_check(name: &element.target_mark_name)
        }
        
        func mark_check(name: inout String)
        {
            if program.mark_names.count > 0
            {
                var mark_founded = false
                
                for mark_name in program.mark_names
                {
                    if mark_name == name
                    {
                        mark_founded = true
                        break
                    }
                }
                
                if !mark_founded // && name == ""
                {
                    name = program.mark_names[0]
                }
            }
            else
            {
                name = ""
            }
        }
    }
    
    /// Validates and corrects module-based changer elements.
    ///
    /// Ensures module references are valid and available in registry.
    /// Falls back to default module if necessary.
    ///
    /// - Parameter element: Changer element to validate
    private func changer_element_check(_ element: ChangerModifierElement)
    {
        if element.module_name.isEmpty
        {
            if !Changer.internal_modules_list.contains(element.module_name)
            {
                if Changer.internal_modules_list.count > 0
                {
                    element.module_name = Changer.internal_modules_list.first!
                }
                else
                {
                    element.module_name = "None"
                }
            }
            else if !Changer.external_modules_list.contains(element.module_name)
            {
                if Changer.external_modules_list.count > 0
                {
                    element.module_name = Changer.external_modules_list.first!
                }
                else
                {
                    element.module_name = "None"
                }
            }
        }
        
        element.import_module(element.module_name, is_internal: !element.module_name.hasPrefix("."))
    }
    
    // MARK: - Performing State
    /// Indicates whether program execution is running in cyclic mode.
    @Published public var cycled = false
    
    /// Indicates whether workspace is currently performing any operation.
    @Published public var performed = false
    
    /// Index of currently executing program element.
    private var selected_element_index = 0
    
    /// Currently active program element (safe access).
    ///
    /// Returns fallback element if index is invalid.
    public var selected_program_element: ProductionProgramElement //A selected workspace program element.
    {
        get
        {
            return selected_program?.elements[safe: selected_element_index] ?? ProductionProgramElement()
        }
        set
        {
            selected_program?.elements[safe: selected_program_index] = newValue
        }
    }
    
    /// Cancel perform flag.
    //public var canceled = false
    
    private var performing_task = Task<Void, Error> {}
    
    // MARK: Performing
    /// Executes a single production program element.
    ///
    /// Dispatches execution based on runtime type:
    /// - Robot/Tool performers
    /// - Modifiers (math, move, write, observe)
    /// - Logic operations (jump, compare, mark)
    /// - Memory operations (changer, cleaner)
    ///
    /// - Parameters:
    ///   - element: Element to execute
    ///   - completion: Completion callback with success or failure result
    public func perform(element: ProductionProgramElement, completion: @escaping @Sendable (Result<Void, Error>) -> Void = { _ in })
    {
        performed = true
        
        //canceled = false
        
        switch element
        {
        // Performers
        case let performer_element as RobotPerformerElement:
            perform_robot(
                by: performer_element,
                completion:
                    { result in
                        DispatchQueue.main.async
                        {
                            self.performed = false
                            completion(result)
                        }
                    },
                error_handler:
                    { error in
                        DispatchQueue.main.async { self.error_handler(error) }
                    }
            )
        case let performer_element as ToolPerformerElement:
            perform_tool(
                by: performer_element,
                completion:
                    { result in
                        DispatchQueue.main.async
                        {
                            self.performed = false
                            completion(result)
                        }
                    },
                error_handler:
                    { error in
                        DispatchQueue.main.async { self.error_handler(error) }
                    }
            )
            
        // Modifiers
        case let mover_element as MoverModifierElement:
            move(by: mover_element)
            self.performed = false
            completion(.success(()))
        case let write_element as WriterModifierElement:
            write(by: write_element)
            self.performed = false
            completion(.success(()))
        case let math_element as MathModifierElement:
            math(by: math_element)
            self.performed = false
            completion(.success(()))
        case let changer_element as ChangerModifierElement:
            let registers_count = registers.count
            do
            {
                try changer_element.change(&registers)
                check_registers(registers_count)
                
                self.performed = false
                completion(.success(()))
            }
            catch
            {
                check_registers(registers_count)
                error_handler(error)
            }
        case let observer_element as ObserverModifierElement:
            observe(
                by: observer_element,
                completion:
                    { result in
                        DispatchQueue.main.async
                        {
                            self.performed = false
                            completion(result)
                        }
                    },
                error_handler:
                    { error in
                        DispatchQueue.main.async { self.error_handler(error) }
                    }
            )
        case is CleanerModifierElement:
            clear_registers()
            performed = false
            completion(.success(()))
            
        // Logic
        case let jump_element as JumpLogicElement:
            jump(by: jump_element)
            performed = false
            completion(.success(()))
        case let comparator_element as ComparatorLogicElement:
            compare(by: comparator_element)
            performed = false
            completion(.success(()))
        case is MarkLogicElement:
            performed = false
            completion(.success(()))
        default:
            performed = false
            completion(.success(()))
        }
        
        func check_registers(_ reference_count: Int)
        {
            if registers.count != reference_count
            {
                registers = updated_registers(registers, reference_count)
            }
        }
    }
    
    /// Starts or pauses full program execution cycle.
    ///
    /// If program is not running → starts execution from first element.
    /// If running → pauses current execution step.
    ///
    /// Handles:
    /// - Program preparation
    /// - Error reset
    /// - State transitions
    /// - Sequential execution pipeline
    public func start_pause_performing() //Selects program element and performs by workspace.
    {
        single_operation_reset()
        
        guard let selected_program = self.selected_program, selected_program.elements_count > 0
        else
        {
            finish_handler()
            return
        }
        
        prepare_program(selected_program)
        
        // Tool performing handling
        if !performed
        {
            reset_error()
            
            // Perform next element if performing was stop
            performed = false //???
            
            program_performed = true // Control Buttons (UI)
            performing_state = .processing // State light (UI)
            
            perform_next_element()
        }
        else
        {
            // Remove all action if moving was perform
            performed = false
            
            pause_handler()
        }
        
        func pause_handler()
        {
            //disable_constant_objects_update()
            
            selected_program_element.performing_state = .current
            
            program_performed = false // Control Buttons (UI)
            performing_state = .current // State light (UI)
            
            switch selected_program_element
            {
            case let performer_element as RobotPerformerElement:
                pause_handler(performer_element)
            case let performer_element as ToolPerformerElement:
                pause_handler(performer_element)
            default:
                break
            }
        }
        
        func pause_handler(_ element: RobotPerformerElement)
        {
            let robot = robot(named: element.object_name)
            
            if element.is_single_perfrom
            {
                robot.stop()
            }
            else
            {
                robot.start_pause_moving()
            }
            
            robot.clear_finish_handler()
            robot.clear_error_handler()
            
            robot.stop_output_updating()
        }
        
        func pause_handler(_ element: ToolPerformerElement)
        {
            let tool = tool(named: element.object_name)
            
            if element.is_single_perfrom
            {
                tool.stop()
            }
            else
            {
                tool.start_pause_performing()
            }
            
            tool.clear_finish_handler()
            tool.clear_error_handler()
        }
    }
    
    /// Executes next program element in sequence.
    ///
    /// Updates state and advances execution pointer.
    public func perform_next_element()
    {
        selected_program_element.performing_state = .processing
        
        perform(element: selected_program_element)
        { result in
            Task
            { @MainActor in
                switch result
                {
                case .success:
                    self.selected_program_element.performing_state = .completed
                    
                    self.select_next_element()
                case .failure(let error):
                    self.process_error(error)
                    self.error_handler(error)
                }
            }
        }
    }
    
    /// Processes execution error during program runtime.
    ///
    /// Updates workspace state and UI indicators.
    ///
    /// - Parameter error: Execution error
    public func process_error(_ error: Error)
    {
        performed = false // Pause performing
        
        last_error = error
        
        selected_program_element.performing_state = .error
        performing_state = .error // State light (UI)
        
        program_performed = false // Control Buttons (UI)
    }
    
    /// Advances execution pointer to next program element.
    ///
    /// Handles:
    /// - Normal progression
    /// - Loop cycling mode
    /// - Program completion state
    private func select_next_element()
    {
        guard let selected_program = self.selected_program
        else
        {
            finish_handler()
            return
        }
        
        if selected_element_index < selected_program.elements_count - 1
        {
            // Select and perform next code
            selected_element_index += 1
            perform_next_element()
        }
        else
        {
            selected_element_index = 0
            
            if cycled
            {
                self.selected_program?.reset_elements_states()
                
                perform_next_element()
            }
            else
            {
                // Reset target point index if all points passed
                selected_element_index = 0
                performed = false
                
                performing_state = .completed // State light (UI)
                program_performed = false // Control Buttons (UI)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                {
                    self.performing_state = .none // State light (UI)
                    self.selected_program?.reset_elements_states()
                }
                
                //update()
                
                finish_handler()
            }
        }
    }
    
    /// Callback invoked when program execution finishes.
    public var finish_handler: (() -> Void) = {}
    
    /// Clears finish handler callback.
    public func clear_finish_handler()
    {
        finish_handler = {}
    }
    
    /// Handles execution error state internally.
    ///
    /// Updates UI and execution state without stopping pipeline logic directly.
    ///
    /// - Parameter error: Execution error
    private func error_handler(_ error: Error)
    {
        performed = false // Pause performing
        
        //disable_constant_objects_update()
        
        selected_program_element.performing_state = .error
        performing_state = .error // State light
        last_error = error
    }
    
    //public var error_handler: ((Error) -> Void) = { _ in }
    
    /// Clears error handler.
    /*public func clear_error_handler()
    {
        error_handler = { _ in }
    }*/
    
    /// Resets full workspace execution state.
    ///
    /// Clears:
    /// - Program progress
    /// - Execution flags
    /// - Selected element index
    /// - Robot/tool runtime states
    public func reset_performing()
    {
        //disable_constant_objects_update()
        
        switch selected_program_element
        {
        case let performer_element as RobotPerformerElement:
            reset_handler(performer_element)
        case let performer_element as ToolPerformerElement:
            reset_handler(performer_element)
        default:
            break
        }
        
        guard let selected_program = self.selected_program else { return }
        
        program_performed = false // Control Buttons (UI)
        performing_state = .none // State light (UI)
        
        performed = false
        
        selected_element_index = 0
        selected_program.reset_elements_states()
        
        reset_error()
        
        func reset_handler(_ element: RobotPerformerElement)
        {
            let robot = robot(named: element.object_name)
            
            if element.is_single_perfrom
            {
                robot.stop()
            }
            else
            {
                robot.reset_moving()
                robot.deselect_program()
            }
            
            robot.clear_finish_handler()
            robot.clear_error_handler()
            
            robot.stop_output_updating()
        }
        
        func reset_handler(_ element: ToolPerformerElement)
        {
            let tool = tool(named: element.object_name)
            
            if element.is_single_perfrom
            {
                tool.stop()
            }
            else
            {
                tool.reset_performing()
                tool.deselect_program()
            }
            
            tool.clear_finish_handler()
            tool.clear_error_handler()
        }
    }
    
    // MARK: Registers
    /// Default number of workspace registers used for computation and memory flow.
    nonisolated(unsafe) public static var default_registers_count = 256
    
    /// Register memory buffer used for program execution.
    ///
    /// Stores intermediate computation values.
    @Published public var registers: [Float]
    
    /// Number of active registers in workspace memory.
    public var registers_count: Int
    {
        get { registers.count }
        set
        {
            registers = updated_registers(registers, newValue > 1 ? newValue : 1)
        }
    }
    
    /// Resizes register memory while preserving existing values where possible.
    ///
    /// - Parameters:
    ///   - registers: Current register array
    ///   - new_count: Desired register count
    /// - Returns: Updated register buffer
    private func updated_registers(_ registers: [Float], _ new_count: Int) -> [Float]
    {
        if registers.count > 0
        {
            var updated_registers = [Float](repeating: 0, count: new_count)
            
            for (index, value) in registers.enumerated()
            {
                if index < updated_registers.count
                {
                    updated_registers[safe: index] = Float(value)
                }
                else
                {
                    break
                }
            }
            
            return updated_registers
        }
        else
        {
            return registers
        }
    }
    
    /// Clears all register values.
    public func clear_registers()
    {
        registers = [Float](repeating: 0, count: registers.count)
    }
    
    /// Clears value at specific register index.
    ///
    /// - Parameter index: Register index
    public func clear_register(_ index: Int)
    {
        if index < registers.count && index >= 0
        {
            registers[safe: index] = 0
        }
    }
    
    /// Updates value of specific register.
    ///
    /// - Parameters:
    ///   - index: Register index
    ///   - new_value: New float value
    public func update_register(_ index: Int, new_value: Float)
    {
        if index < registers.count && index >= 0
        {
            registers[safe: index] = new_value
        }
    }
    
    // MARK: - Performing State
    /// Last runtime error produced during program execution.
    ///
    /// Stores the most recent error from robot/tool/program execution pipeline.
    /// Used for diagnostics and UI feedback.
    public var last_error: Error?
    
    /// Resets current execution error state.
    ///
    /// Clears `last_error` without affecting execution flow.
    /// Useful when restarting program or clearing UI error indicators.
    public func reset_error()
    {
        last_error = nil
        //performing_state = .processing
    }
    
    /// Lightweight global performing state of workspace.
    ///
    /// Represents aggregated execution state across robots, tools, and programs.
    @Published public var performing_state: PerformingState = .none
    
    /// Indicates whether a production program is currently executing.
    ///
    /// Used for UI binding and runtime control of execution lifecycle.
    @Published public var program_performed = false
    
    /*/// Last performing error
    public var last_error: Error?
    {
        switch selected_object_type
        {
        case .robot:
            return selected_robot.last_error
        case .tool:
            return selected_tool.last_error
        default:
            return nil
        }
    }
    
    /// Performing state light.
    public var performing_state: PerformingState
    {
        switch selected_object_type
        {
        case .robot:
            return selected_robot.performing_state
        case .tool:
            return selected_tool.performing_state
        default:
            return .none
        }
    }*/
    
    // MARK: - Element Processing
    /// Executes a robot-related program element.
    ///
    /// Supports:
    /// - Single motion execution (point-to-point move)
    /// - Full program execution via robot internal program system
    ///
    /// Handles register-based parameter extraction, motion execution,
    /// and asynchronous completion/error propagation.
    ///
    /// - Parameters:
    ///   - element: Robot execution descriptor
    ///   - completion: Success callback
    ///   - error_handler: Error callback
    private func perform_robot(by element: RobotPerformerElement, completion: @escaping @Sendable (Result<Void, Error>) -> Void, error_handler: @escaping @Sendable (Error) -> Void)
    {
        let robot = robot(named: element.object_name)
        
        if element.is_single_perfrom
        {
            // Single movement perform
            robot.performed = true
            
            var target_point = PositionPoint(
                x: registers[safe_float: element.x_index],
                y: registers[safe_float: element.y_index],
                z: registers[safe_float: element.z_index],
                r: registers[safe_float: element.r_index],
                p: registers[safe_float: element.p_index],
                w: registers[safe_float: element.w_index],
                move_speed: registers[safe_float: element.speed_index],
                move_type: MoveType(register_value: Int(registers[safe_float: element.type_index]))
            )
            robot.point_shift(&target_point)
            
            robot.move(to: target_point)
            { result in
                Task
                { @MainActor in
                    robot.performed = false
                    switch result
                    {
                    case .success:
                        robot.pointer_position_to_robot()
                        completion(.success(()))
                    case .failure(let error):
                        robot.process_error(error)
                        error_handler(error)
                    }
                }
            }
        }
        else
        {
            // Robot program perform
            if !element.is_program_by_index
            {
                robot.select_program(named: element.program_name)
            }
            else
            {
                robot.select_program(at: Int(registers[safe: element.program_index] ?? 0))
            }
            
            robot.finish_handler = {
                robot.clear_finish_handler()
                robot.clear_error_handler()
                
                robot.deselect_program()
                
                robot.stop_output_updating()
                
                completion(.success(()))
            }
            robot.error_handler = { error in
                robot.clear_finish_handler()
                robot.clear_error_handler()
                
                robot.stop_output_updating()
                
                error_handler(error)
            }
            
            robot.start_pause_moving()
        }
    }
    
    /// Executes a tool-related program element.
    ///
    /// Supports:
    /// - Single operation execution (opcode-based action)
    /// - Full tool program execution
    ///
    /// Uses register-based parameter resolution and async completion handling.
    ///
    /// - Parameters:
    ///   - element: Tool execution descriptor
    ///   - completion: Success callback
    ///   - error_handler: Error callback
    private func perform_tool(by element: ToolPerformerElement, completion: @escaping @Sendable (Result<Void, Error>) -> Void, error_handler: @escaping @Sendable (Error) -> Void)
    {
        let tool = tool(named: element.object_name)
        
        if element.is_single_perfrom
        {
            // Single operation perform
            tool.perform(code: Int(registers[safe: element.opcode_index] ?? 0))
            { result in
                Task
                { @MainActor in
                    tool.performed = false
                    switch result
                    {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        tool.process_error(error)
                        error_handler(error)
                    }
                }
            }
        }
        else
        {
            // Tool program perform
            if !element.is_program_by_index
            {
                tool.select_program(named: element.program_name)
            }
            else
            {
                tool.select_program(at: Int(registers[safe: element.program_index] ?? 0))
            }
            
            tool.finish_handler = {
                tool.clear_finish_handler()
                tool.clear_error_handler()
                
                completion(.success(()))
            }
            tool.error_handler = { error in
                tool.clear_finish_handler()
                tool.clear_error_handler()
                
                tool.deselect_program()
                
                error_handler(error)
            }
            
            tool.start_pause_performing()
        }
    }
    
    /// Moves values between registers using link definitions.
    ///
    /// Supports optional clearing of source register depending on move mode.
    ///
    /// - Parameter element: Move operation descriptor
    private func move(by element: MoverModifierElement)
    {
        for link in element.links
        {
            registers[safe: link.to] = registers[safe: link.from]
            if element.move_type == .move
            {
                registers[safe: link.from] = 0
            }
        }
    }
    
    /// Writes constant or computed values into registers.
    ///
    /// Overwrites target register values defined by input mapping.
    ///
    /// - Parameter element: Write operation descriptor
    private func write(by element: WriterModifierElement)
    {
        for input in element.inputs
        {
            registers[safe: input.to] = input.value
        }
    }
    
    /// Evaluates mathematical expression and stores result in register.
    ///
    /// Expression is parsed into tokens, converted to Reverse Polish Notation,
    /// and evaluated using stack-based execution.
    ///
    /// Supports:
    /// - arithmetic operators (+, -, *, /, ^)
    /// - registers
    /// - constants
    /// - functions
    ///
    /// - Parameter element: Math expression descriptor
    private func math(by element: MathModifierElement)
    {
        let tokens = tokenize(element.expression)
        let rpn = to_rpn(tokens)
        let result = eval_rpn(rpn)
        
        registers[safe: element.to_index] = result
        
        func eval_rpn(_ rpn: [MathToken]) -> Float
        {
            var stack: [Float] = []
            
            for token in rpn
            {
                switch token
                {
                case .number(let n):
                    stack.append(n)
                    
                case .constant(let c):
                    stack.append(c)
                    
                case .register(let i):
                    stack.append(registers[safe: i] ?? 0)
                    
                case .function(let name):
                    guard let value = stack.popLast(),
                          let f = math_functions[name]
                    else { return 0 }
                    stack.append(f(value))
                    
                case .op(let op):
                    guard stack.count >= 2 else { return 0 }
                    let b = stack.removeLast()
                    let a = stack.removeLast()
                    
                    switch op
                    {
                    case "+": stack.append(a + b)
                    case "-": stack.append(a - b)
                    case "*": stack.append(a * b)
                    case "/": stack.append(b == 0 ? 0 : a / b)
                    case "^": stack.append(pow(a, b))
                    default: break
                    }
                    
                default: break
                }
            }
            
            return stack.last ?? 0
        }
    }
    
    /// Reads structured output from robot or tool and maps it into registers.
    ///
    /// Extracts hierarchical state items and flattens them into linear register space.
    ///
    /// Supports type inference:
    /// - Float values
    /// - Boolean values
    /// - Fallback string encoding
    ///
    /// - Parameters:
    ///   - element: Observation descriptor
    ///   - completion: Success callback
    ///   - error_handler: Error callback
    private func observe(by element: ObserverModifierElement, completion: @escaping @Sendable (Result<Void, Error>) -> Void, error_handler: @escaping @Sendable (Error) -> Void)
    {
        var info_output = [String]()
        
        switch element.object_type
        {
        case .robot:
            if let device_output = robot(named: element.object_name).device_output
            {
                info_output = items_to_array(from: device_output.items)
            }
            else
            {
                error_handler(NSError(domain: "No output items", code: 0, userInfo: nil))
            }
        case .tool:
            if let device_output = tool(named: element.object_name).device_output
            {
                info_output = items_to_array(from: device_output.items)
            }
            else
            {
                error_handler(NSError(domain: "No output items", code: 0, userInfo: nil))
            }
        }
        
        if element.outputs.count > 0
        {
            for output in element.outputs
            {
                guard output.from < info_output.count,
                      output.to >= 0,
                      output.to < registers.count else { continue }
                
                let raw = info_output[output.from]
                
                if let value = Float(raw)
                {
                    registers[output.to] = value
                }
                else if let value = Bool(raw)
                {
                    registers[output.to] = value ? 1 : 0
                }
                else
                {
                    registers[output.to] = raw.isEmpty ? 0 : 1
                }
            }
        }
        
        completion(.success(()))
        
        func items_to_array(from items: [StateItem]) -> [String]
        {
            var info_output = [String]()
            
            func traverse(_ item: StateItem)
            {
                info_output.append(item.name)
                
                if let value = item.value
                {
                    info_output.append(value)
                }
                
                if let children = item.children
                {
                    for child in children
                    {
                        traverse(child)
                    }
                }
            }
            
            for item in items
            {
                traverse(item)
            }
            
            return info_output
        }
    }
    
    /// Jumps unconditionally to target program element index.
    ///
    /// Used for control-flow redirection in program execution.
    ///
    /// - Parameter element: Jump descriptor
    private func jump(by element: JumpLogicElement)
    {
        selected_element_index = element.target_element_index
        
        reset_elements_states_to_current() // UI only
    }
    
    /// Conditional jump based on register comparison result.
    ///
    /// If comparison evaluates to true, execution pointer is redirected.
    ///
    /// - Parameter element: Comparator descriptor
    private func compare(by element: ComparatorLogicElement)
    {
        if element.compare_type.compare(registers[safe_float: element.value_index], registers[safe_float: element.value2_index])
        {
            selected_element_index = element.target_element_index
            
            reset_elements_states_to_current() // UI only
        }
    }
    
    /// Resets UI execution state from current element index onward.
    ///
    /// Marks all following elements as non-executing.
    /// Used for visual synchronization only (no logic impact).
    private func reset_elements_states_to_current()
    {
        guard let program = selected_program else { return }
        
        for i in selected_element_index ..< program.elements_count
        {
            program.elements[safe: i]?.performing_state = .none
        }
    }
    
    /// Prepares program for execution by resolving internal element indices.
    ///
    /// Builds execution metadata required for runtime traversal.
    private func prepare_program(_ program: ProductionProgram)
    {
        program.defining_elements_indexes()
    }
    
    // MARK: - UI
    #if canImport(RealityKit)
    /// Root RealityKit entity representing entire workspace scene graph.
    ///
    /// Contains robots, tools, parts, grid, pointer, and camera anchors.
    private var workspace_entity = Entity()
    
    /// Anchor entity used for physics and world alignment in RealityKit scene.
    private var workspace_anchor = AnchorEntity(world: .zero)
    
    #if os(macOS) || os(iOS)
    private var scene_content: RealityViewCameraContent?
    #else
    private var scene_content: RealityViewContent?
    #endif
    
    #if os(macOS) || os(iOS)
    /// Injects workspace into RealityKit scene content.
    ///
    /// Responsible for:
    /// - Scene initialization
    /// - Camera setup (macOS/iOS)
    /// - Grid generation
    /// - Pointer system activation
    /// - Module entity loading
    /// - Object placement
    ///
    /// - Parameters:
    ///   - content: RealityKit scene container
    ///   - completion: Completion callback
    public func place_entity(
        in content: RealityViewCameraContent,
        completion: @escaping () -> () = {}
    )
    {
        scene_content = content
        scene_content?.add(workspace_entity)
        
        scene_content?.add(workspace_anchor) // Physics
        
        // Place (connect) camera
        if workspace_camera == nil
        {
            // Camera setup
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 60
            camera.position = [0, 1, 0]
            camera.rotate_x(by: -.pi / 6)
            
            workspace_entity.addChild(camera)
            workspace_camera = camera
            workspace_entity.addChild(workspace_camera_target)
            
            // Target entity setup
            let wall = ModelEntity(mesh: MeshResource.generatePlane(width: 0.5, depth: 0.5))
            wall.orientation = simd_quatf(angle: .pi/2, axis: [0, 1, 0])
            workspace_camera_target.addChild(wall)
            target_tile = wall
            wall.isEnabled = false
            
            workspace_camera_target.addChild(wall)
            scene_content?.cameraTarget = workspace_camera_target
            
            capture_initial_camera_target_offset()
            
            // Dynamic camera
            _ = content.subscribe(to: SceneEvents.Update.self)
            { [weak self] _ in
                guard let self else { return }
                
                if self.is_focusing
                {
                    self.scene_content?.cameraTarget = self.workspace_camera_target
                }
                else
                {
                    self.move_camera_target()
                }
            }
            
            // Prebuild grid
            let cx = Int(round(camera.position.x / cell_size))
            let cz = Int(round(camera.position.z / cell_size))
            
            create_grid_async(center_x: cx, center_z: cz)
        }
        
        // Place grid
        _ = content.subscribe(to: SceneEvents.Update.self)
        { [weak self] _ in
            guard let self, let camera = self.workspace_camera else { return }
            self.update_grid(camera_position: camera.position)
        }
        
        // Place pointer
        workspace_entity.addChild(pointer_entity)
        pointer_entity.isEnabled = false
        let bounding_box = make_wire_bounding_box()
        bounding_box.addChild(make_object_pointer_entity())
        pointer_entity.addChild(bounding_box)
        _ = content.subscribe(to: SceneEvents.Update.self)
        { [weak self] _ in
            guard let self else { return }
            
            if self.selected_object != nil { self.update_pointer_entity() } // Dynamic pointer update
        }
        
        load_all_module_entities
        {
            self.place_physical_floor() // Place floor
            self.place_objects() // Place objects
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
            {
                self.focus(on: nil) // Focus on a whole workspace
            }
            
            completion()
        }
    }
    #else
    public func place_entity(
        in content: RealityViewContent,
        completion: @escaping () -> () = {}
    )
    {
        scene_content = content
        scene_content?.add(workspace_entity)
        
        scene_content?.add(workspace_anchor) // Physics
        
        // Place grid
        let cx = Int(round(0 / cell_size))
        let cz = Int(round(0 / cell_size))
        
        create_grid_async(center_x: cx, center_z: cz)
        
        /*_ = content.subscribe(to: SceneEvents.Update.self)
        { [weak self] _ in
            guard let self, let camera = self.workspace_camera else { return }
            self.update_grid(camera_position: camera.position)
        }*/
        
        // Place pointer
        workspace_entity.addChild(pointer_entity)
        pointer_entity.isEnabled = false
        let bounding_box = make_wire_bounding_box()
        bounding_box.addChild(make_object_pointer_entity())
        pointer_entity.addChild(bounding_box)
        _ = content.subscribe(to: SceneEvents.Update.self)
        { [weak self] _ in
            guard let self else { return }
            
            if self.selected_object != nil { self.update_pointer_entity() } // Dynamic pointer update
        }
        
        load_all_module_entities
        {
            self.place_physical_floor() // Place floor
            self.place_objects() // Place objects
            
            #if os(macOS) || os(iOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
            {
                self.focus(on: nil) // Focus on a whole workspace
            }
            #endif
            
            completion()
        }
    }
    #endif
    
    #if os(macOS) || os(iOS)
    /// Removes workspace from RealityKit scene.
    ///
    /// Cleans up entity hierarchy and grid state.
    ///
    /// - Parameter content: Scene container
    public func remove_entity(from content: RealityViewCameraContent)
    {
        content.remove(workspace_entity)
        grid_lines.removeAll()
    }
    #else
    public func remove_entity(from content: RealityViewContent)
    {
        content.remove(workspace_entity)
        grid_lines.removeAll()
    }
    #endif
    
    // MARK: Entities from modules
    /// Loads all internal and external module entities for robots, tools, and parts.
    ///
    /// Ensures that all visual representations are available before scene assembly.
    private func load_all_module_entities(_ completion: @escaping () -> Void = {})
    {
        load_all_internal_module_entities
        {
            load_all_external_module_entities
            {
                completion()
            }
        }
        
        func load_all_internal_module_entities(_ completion: @escaping () -> Void = {})
        {
            Robot.load_all_internal_module_entities
            {
                Tool.load_all_internal_module_entities
                {
                    Part.load_all_internal_module_entities
                    {
                        //print("Internal loaded")
                        completion()
                    }
                }
            }
        }
        
        func load_all_external_module_entities(_ completion: @escaping () -> Void = {})
        {
            Robot.load_all_external_module_entities
            {
                Tool.load_all_external_module_entities
                {
                    Part.load_all_external_module_entities
                    {
                        //print("External loaded")
                        completion()
                    }
                }
            }
        }
    }
    
    #if os(macOS) || os(iOS)
    // MARK: Camera
    /// Perspective camera used for workspace visualization.
    private var workspace_camera: PerspectiveCamera?
    
    /// Camera target entity used as pivot for smooth movement and focus control.
    private var workspace_camera_target = Entity()
    
    /// Current offset between camera and target pivot point.
    private var camera_target_offset: SIMD3<Float> = .zero
    
    /// Indicates whether camera target offset has been initialized.
    private var camera_target_initialized = false
    
    /// Base distance reference for camera scaling computations.
    private var base_camera_distance: Float?
    
    /// Indicates whether camera is currently in focus animation mode.
    private var is_focusing = false
    
    /// Default tile size computed from bounding box of placed objects.
    ///
    /// Used for grid scaling and visual framing.
    private var target_tile_default_size: Float // = 0.5
    {
        let placed = (robots + tools + parts).filter { $0.is_placed }
        
        guard !placed.isEmpty else { return 0.5 }
        
        var min_x = placed[0].position.x
        var max_x = min_x
        var min_y = placed[0].position.y
        var max_y = min_y
        var min_z = placed[0].position.z
        var max_z = min_z
        
        for obj in placed
        {
            let p = obj.position
            
            if p.x < min_x { min_x = p.x }
            if p.x > max_x { max_x = p.x }
            
            if p.y < min_y { min_y = p.y }
            if p.y > max_y { max_y = p.y }
            
            if p.z < min_z { min_z = p.z }
            if p.z > max_z { max_z = p.z }
        }
        
        let dx = (max_x - min_x) * 0.001
        let dy = (max_y - min_y) * 0.001
        let dz = (max_z - min_z) * 0.001
        
        let diagonal = sqrt(dx*dx + dy*dy + dz*dz)
        
        return max(diagonal * 1.2, 0.5)
    }
    
    /// Weak reference to grid tile entity used for scaling during camera focus.
    private weak var target_tile: ModelEntity?
    
    /// Moves camera focus to specified entity or workspace center.
    ///
    /// Animates:
    /// - Camera pivot movement
    /// - Grid tile scaling
    /// - Smooth easing transitions
    ///
    /// - Parameter entity: Target entity to focus on (nil = full workspace)
    public func focus(on entity: Entity?)
    {
        //scene_content?.cameraTarget = entity?
        
        if is_focusing { return }
        is_focusing = true
        
        var center: SIMD3<Float> = .zero
        var tile_size = SIMD2<Float>(repeating: target_tile_default_size)
        
        // Center
        if let entity
        {
            let bounds = entity.visualBounds(relativeTo: nil)
            center = bounds.center
            
            let width = max(bounds.extents.x, 0.05)
            let depth = max(bounds.extents.z, 0.05)
            
            let margin: Float = 1.25
            tile_size = max(SIMD2<Float>(width * margin, depth * margin), 0.25)//0.5)
        }
        
        let animation_duration: Float = 0.4
        
        // Pivot movement
        var transform = workspace_camera_target.transform
        transform.translation = center
        
        workspace_camera_target.move(
            to: transform,
            relativeTo: nil,
            duration: TimeInterval(animation_duration),
            timingFunction: .easeInOut
        )
        
        // Animate tile scale smoothly
        if let tile = target_tile
        {
            let base_width: Float = 0.5
            let base_depth: Float = 0.5
            
            let start_scale = tile.scale
            let target_scale = SIMD3<Float>(tile_size.x / base_width, tile.scale.y, tile_size.y / base_depth)
            
            let steps = 400 //160 //40
            let dt = animation_duration / Float(steps)
            
            for i in 1...steps
            {
                let t = Float(i) / Float(steps)
                let k = t * t * (3 - 2 * t) // Smoothstep easing
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(dt * Float(i))) { [weak tile] in
                    guard let tile else { return }
                    tile.scale = simd_mix(start_scale, target_scale, SIMD3<Float>(repeating: k))
                }
            }
        }
        
        // Delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(animation_duration))
        { [weak self] in
            self?.is_focusing = false
        }
    }
    
    /// Captures initial offset between camera and target pivot.
    ///
    /// Used for maintaining stable relative camera movement.
    private func capture_initial_camera_target_offset()
    {
        guard let camera = workspace_camera else { return }

        let camera_pos = camera.position(relativeTo: nil)
        let target_pos = workspace_camera_target.position(relativeTo: nil)

        camera_target_offset = target_pos - camera_pos
        camera_target_initialized = true
    }
    
    /// Continuously updates camera target position based on camera direction.
    ///
    /// Computes ray-plane intersection to maintain grounded pivot movement.
    /// Also updates grid scaling based on camera distance.
    func move_camera_target()
    {
        guard let camera = workspace_camera else { return }
        
        let camera_pos = camera.position(relativeTo: nil)
        let m = camera.transformMatrix(relativeTo: nil)
        
        var forward = SIMD3<Float>(-m.columns.2.x, -m.columns.2.y, -m.columns.2.z)
        forward = normalize(forward)
        
        if abs(forward.y) < 0.0001 { return }
        
        let t = -camera_pos.y / forward.y
        
        if t <= 0 { return }
        
        let intersection = camera_pos + forward * t
        
        workspace_camera_target.setPosition(intersection, relativeTo: nil)
        
        update_target_tile_scale(camera_pos, intersection)
        
        func update_target_tile_scale(_ camera_position: SIMD3<Float>, _ target_position: SIMD3<Float>) // Performs smooth animated scaling of grid tile during focus transitions.
        {
            guard let tile = target_tile else { return }
            
            let distance = simd_distance(camera_position, target_position)
            
            if base_camera_distance == nil
            {
                base_camera_distance = distance
                tile.scale = .one
                return
            }
            
            guard let base = base_camera_distance else { return }
            
            let relative_scale = distance / base
            let clamped = min(max(relative_scale, 0.15), 40.0)
            
            tile.scale = SIMD3<Float>(repeating: clamped)
        }
    }
    #endif
    
    // MARK: Grid
    private var grid_visible = true
    private var grid_lines: [String: ModelEntity] = [:]
    
    private let cell_size: Float = 0.1 // 100 mm
    private let render_radius: Int = 200
    
    private let minor_width: Float = 0.002 //0.001
    private let major_width: Float = 0.0025
    
    private let major_step = 10
    
    private let minor_line_mesh_x = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.002)
    private let major_line_mesh_x = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.0025)
    private let axis_line_mesh_x  = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.00375)
    
    private let minor_line_mesh_z = MeshResource.generatePlane(width: 0.002, depth: Float(200*2) * 0.1)
    private let major_line_mesh_z = MeshResource.generatePlane(width: 0.0025, depth: Float(200*2) * 0.1)
    private let axis_line_mesh_z  = MeshResource.generatePlane(width: 0.00375, depth: Float(200*2) * 0.1)
    
    private enum Axis { case x, z }
    
    /*public var is_grid_visible: Bool { grid_visible } // UI Only
    
    public func toggle_grid_visiblity()
    {
        grid_visible.toggle()
        grid_lines.values.forEach { $0.isEnabled = grid_visible }
        
        self.objectWillChange.send() // UI Only
    }*/
    
    /// Public toggle for grid visibility.
    ///
    /// Automatically enables/disables all grid line entities
    /// and triggers UI update.
    public var shows_grid: Bool
    {
        get
        {
            grid_visible
        }
        set
        {
            grid_visible = newValue
            grid_lines.values.forEach { $0.isEnabled = newValue }
            
            self.objectWillChange.send() // UI Only
        }
    }
    
    /// Updates grid based on camera position.
    ///
    /// Dynamically spawns and removes grid lines around the camera.
    /// Ensures stable visual density independent of world scale.
    ///
    /// - Parameter camera_position: Current camera world position.
    private func update_grid(camera_position: SIMD3<Float>)
    {
        if !grid_visible { return }
        
        let cx = Int(round(camera_position.x / cell_size))
        let cz = Int(round(camera_position.z / cell_size))
        
        for i in -render_radius...render_radius
        {
            add_line(index: cx + i, axis: .x)
            add_line(index: cz + i, axis: .z)
        }
        
        cleanup_lines(center_x: cx, center_z: cz)
    }
    
    /// Asynchronously builds grid around a center position.
    ///
    /// Uses batched updates to avoid blocking main thread.
    /// Suitable for initial scene setup or teleport-like camera moves.
    ///
    /// - Parameters:
    ///   - center_x: Grid X center index
    ///   - center_z: Grid Z center index
    private func create_grid_async(center_x: Int, center_z: Int)
    {
        Task.detached(priority: .userInitiated)
        { [weak self] in
            guard let self else { return }
            
            let indices = (-self.render_radius...self.render_radius).map { $0 }
            
            for batch_start in stride(from: 0, to: indices.count, by: 20)
            {
                let batch_end = min(batch_start + 20, indices.count)
                
                await MainActor.run
                {
                    for i in batch_start..<batch_end
                    {
                        let idx = indices[i]
                        self.add_line(index: center_x + idx, axis: .x)
                        self.add_line(index: center_z + idx, axis: .z)
                    }
                }
                
                try? await Task.sleep(nanoseconds: 1_000_000_0)
            }
        }
    }
    
    /// Adds a single grid line at given index and axis.
    ///
    /// Performs:
    /// - Major/minor classification
    /// - Material assignment
    /// - Positioning in world space
    /// - Entity caching
    private func add_line(index: Int, axis: Axis)
    {
        let key = "\(axis)_\(index)"
        if grid_lines[key] != nil { return }
        
        let is_major = index % major_step == 0
        let is_axis  = index == 0
        
        let color = is_axis
        ? UIColor.gray.withAlphaComponent(0.5)
        : is_major
        ? UIColor.gray.withAlphaComponent(0.4)
        : UIColor.gray.withAlphaComponent(0.3)
        
        let mesh: MeshResource
        switch axis
        {
        case .x:
            mesh = is_axis ? axis_line_mesh_x : is_major ? major_line_mesh_x : minor_line_mesh_x
        case .z:
            mesh = is_axis ? axis_line_mesh_z : is_major ? major_line_mesh_z : minor_line_mesh_z
        }
        
        var material = SimpleMaterial(color: color, roughness: 1, isMetallic: false) //UnlitMaterial(color: color)
        material.faceCulling = .none
        
        let line = ModelEntity(mesh: mesh, materials: [material])
        line.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        
        switch axis
        {
        case .x:
            line.position = [0, Float(-0.001), Float(index) * cell_size]
        case .z:
            line.position = [Float(index) * cell_size, Float(-0.002), 0]
        }
        
        workspace_entity.addChild(line)
        grid_lines[key] = line
    }
    
    /// Removes grid lines that are outside render radius.
    ///
    /// Prevents memory growth and keeps scene graph lightweight.
    ///
    /// - Parameters:
    ///   - center_x: Current grid center X
    ///   - center_z: Current grid center Z
    private func cleanup_lines(center_x: Int, center_z: Int)
    {
        for (key, line) in grid_lines
        {
            if key.hasPrefix("x_"),
               let idx = Int(key.dropFirst(2)),
               abs(idx - center_x) > render_radius
            {
                line.removeFromParent()
                grid_lines.removeValue(forKey: key)
            }
            
            if key.hasPrefix("z_"),
               let idx = Int(key.dropFirst(2)),
               abs(idx - center_z) > render_radius
            {
                line.removeFromParent()
                grid_lines.removeValue(forKey: key)
            }
        }
    }
    #endif
    
    // MARK: Production Objects Placement
    /// Attaches a production object entity to workspace anchor.
    ///
    /// Ensures correct positioning in world coordinate system.
    ///
    /// - Parameter object: Production object to place
    public func place_object_entity(object: ProductionObject)
    {
        object.entity.update_position(object.position)
        workspace_anchor.addChild(object.entity)
    }
    
    /// Removes a production object entity from workspace.
    ///
    /// Detaches visual representation from scene graph.
    public func remove_object_entity(object: ProductionObject)
    {
        object.entity.removeFromParent()
    }
    
    /// Places all workspace objects into the scene.
    ///
    /// Includes:
    /// - Robots
    /// - Tools (with attachments resolved)
    /// - Parts
    ///
    /// Also updates internal transforms and tool bindings.
    private func place_objects()
    {
        for robot in robots
        {
            place_object_entity(object: robot)
            robot.update_origin_position()
            robot.update_model()
        }
        
        for tool in tools
        {
            place_object_entity(object: tool)
        }
        update_tool_attachments()
        
        for part in self.parts
        {
            place_object_entity(object: part)
        }
    }
    
    /// Creates static physical floor for workspace.
    ///
    /// Adds collision + physics body to prevent object falling.
    ///
    /// Used only in simulation mode.
    private func place_physical_floor()
    {
        let size: Float = 2000
        let thickness: Float = 20
        
        let floor = Entity()
        
        let shape = ShapeResource.generateBox(size: [size, thickness, size])
        
        floor.components.set(
            CollisionComponent(
                shapes: [shape],
                mode: .default
            )
        )
        
        floor.components.set(
            PhysicsBodyComponent(
                shapes: [shape],
                mass: 0,
                mode: .static
            )
        )
        
        floor.position = [0, -thickness / 2, 0]
        
        //workspace_entity.addChild(floor)
        workspace_anchor.addChild(floor)
    }
    
    // MARK: Pointer Handling
    /// Handles tap gesture interaction with workspace entities.
    ///
    /// Traverses entity hierarchy to resolve object identifiers.
    /// Supports:
    /// - Robot selection
    /// - Tool selection
    /// - Part selection
    /// - Nested tool-in-robot detection
    public func process_tap(value: EntityTargetValue<TapGesture.Value>)
    {
        var entity: Entity? = value.entity
        
        while let current = entity
        {
            //print(current.name)
            
            if let object_identifier = current.components[ObjectEntityIdentifier.self]
            {
                //print("📍 Name: \(object_identifier.name), Type: \(object_identifier.type, default: "No")")
                
                if object_identifier.type == .robot
                {
                    if let tool_entity = find_tool(in: current)
                    {
                        if let tool_id = tool_entity.components[ObjectEntityIdentifier.self]
                        {
                            if !already_selecting_same_object(tool_id)
                            {
                                select_object(by: tool_id)
                            }
                            else
                            {
                                process_empty_tap()
                            }
                            
                            return
                        }
                    }
                }
                
                if !already_selecting_same_object(object_identifier)
                {
                    select_object(by: object_identifier)
                }
                else
                {
                    process_empty_tap()
                }
                
                return
            }
            
            entity = current.parent
        }
        
        process_empty_tap()
        
        func find_tool(in root: Entity) -> Entity?
        {
            (root.components[ObjectEntityIdentifier.self]?.type == .tool) ? root :
            root.children.lazy.compactMap { find_tool(in: $0) }.first
        }
        
        func already_selecting_same_object(_ object_identifier: ObjectEntityIdentifier) -> Bool
        {
            guard let identifier_type = object_identifier.type, let selected = selected_object else
            {
                return false
            }
            
            switch (selected, identifier_type)
            {
            case (let robot as Robot, .robot):
                return robot.name == object_identifier.name
            case (let tool as Tool, .tool):
                return tool.name == object_identifier.name
            case (let part as Part, .part):
                return part.name == object_identifier.name
            default:
                return false
            }
        }
    }
    
    /// Clears current selection and resets interaction state.
    ///
    /// Removes pointer visualization and resets camera focus.
    public func process_empty_tap()
    {
        deselect_object()
        pointer_entity.removeFromParent()
        
        #if os(macOS) || os(iOS)
        // Camera pivot reposition
        focus(on: nil)
        #endif
        
        self.objectWillChange.send() // UI only
    }
    
    /// Visual pointer entity used for selection highlighting.
    ///
    /// Dynamically attached to selected object.
    private var pointer_entity = Entity()
    
    /// Visual pointer entity used for selection highlighting.
    ///
    /// Dynamically attached to selected object.
    private func select_object(by entity_identifier: ObjectEntityIdentifier)
    {
        deselect_object() // Test
        pointer_entity.isEnabled = false
        
        deselect_program()
        
        switch entity_identifier.type
        {
        case .robot:
            select_robot(named: entity_identifier.name)
            pointer_entity.isEnabled = true
        case .tool:
            select_tool(named: entity_identifier.name)
            pointer_entity.isEnabled = true
        case .part:
            select_part(named: entity_identifier.name)
            pointer_entity.isEnabled = true
        case .none:
            break
        }
        
        #if os(macOS) || os(iOS)
        // Camera pivot reposition
        if let selected_object = selected_object
        {
            focus(on: selected_object.entity)
        }
        #endif
        
        self.objectWillChange.send() // UI only
    }
    
    // MARK: Pointer Entity
    /// Group of entities used to render 3D selection bounding visualization.
    ///
    /// Includes:
    /// - Axis cones (X/Y/Z)
    /// - Wireframe edges for bounding box faces
    public var pointer_entity_group: (
        cones: (
            x: Entity, y: Entity, z: Entity
        ),
        faces: (
            xz0: Entity, xz1: Entity, xz2: Entity, xz3: Entity,
            xy0: Entity, xy1: Entity, xy2: Entity, xy3: Entity,
            
            yz0: (a: Entity, b: Entity),
            yz1: (a: Entity, b: Entity),
            yz2: (a: Entity, b: Entity),
            yz3: (a: Entity, b: Entity)
        )
    ) = (
        cones: (
            x: Entity(), y: Entity(), z: Entity()
        ),
        faces: (
            xz0: Entity(), xz1: Entity(), xz2: Entity(), xz3: Entity(),
            xy0: Entity(), xy1: Entity(), xy2: Entity(), xy3: Entity(),
            
            yz0: (a: Entity(), b: Entity()),
            yz1: (a: Entity(), b: Entity()),
            yz2: (a: Entity(), b: Entity()),
            yz3: (a: Entity(), b: Entity())
        )
    )
    
    /// Updates pointer position to match selected object bounds.
    ///
    /// Aligns cones and bounding box with visual bounds of model entity.
    ///
    /// - Parameter model_entity: Selected object model
    public func update_pointer_entity()
    {
        if let selected_object = selected_object, let model_entity = selected_object.model_entity
        {
            selected_object.entity.addChild(pointer_entity)
            update_object_pointer_entity(by: model_entity.visualBounds(relativeTo: model_entity).extents)
            update_wire_bounding_box(by: model_entity.visualBounds(relativeTo: model_entity).extents)
            pointer_entity.position = model_entity.visualBounds(relativeTo: model_entity).center
        }
    }
    
    /// Creates axis cones used for 3D orientation visualization.
    ///
    /// Each cone represents one axis direction (X, Y, Z).
    private func make_object_pointer_entity() -> Entity
    {
        let hx: Float = 0
        let hy: Float = 0
        let hz: Float = 0
        
        let cone_height: Float = 0.010
        let cone_radius: Float = 0.008
        
        let colors: [UIColor] = [
            UIColor.systemIndigo,
            UIColor.systemPink,
            UIColor.systemTeal
        ]
        
        let rotations: [SIMD3<Float>] = [[.pi/2, 0, 0], [0, 0,-.pi/2], [0, 0, 0]]
        let positions: [SIMD3<Float>] = [[0, 0, hz], [hx, 0, 0], [0, hy, 0]]
        
        let cylinder_shift: Float = 0.0025
        
        let parent = Entity()
        
        var cones = [Entity]()
        
        for i in 0..<3
        {
            // Cone
            let cone = ModelEntity(mesh: .generateCone(height: cone_height, radius: cone_radius), materials: [SimpleMaterial(color: colors[i], roughness: 1.0, isMetallic: false)])
            cone.components.set(
                CollisionComponent(
                    shapes: [.generateConvex(from: cone.model!.mesh)]
                )
            )
            
            cone.position = positions[i]
            cone.euler_angles = rotations[i]
            
            // Cylinder
            let cylinder = ModelEntity(mesh: .generateCylinder(height: cylinder_shift, radius: cone_radius), materials: [SimpleMaterial(color: .white, roughness: 1.0, isMetallic: false)])
            cylinder.components.set(
                CollisionComponent(
                    shapes: [.generateConvex(from: cone.model!.mesh)]
                )
            )
            cylinder.position = [0, Float(hy) - (cylinder_shift / 2 + cone_height / 2), 0]
            
            cone.addChild(cylinder)
            
            // All
            cones.append(cone)
            parent.addChild(cone)
        }
        
        pointer_entity_group.cones = (x: cones[0], y: cones[1], z: cones[2])
        
        return parent
    }
    
    /// Updates size and offset of axis cones based on object bounds.
    ///
    /// Keeps pointer visually aligned with object geometry.
    ///
    /// - Parameters:
    ///   - size: Bounding box extents
    ///   - shift: Padding offset
    private func update_object_pointer_entity(by size: SIMD3<Float>, shift: Float = 0.04)
    {
        let hx = size.x / 2 + shift
        let hy = size.y / 2 + shift
        let hz = size.z / 2 + shift
        
        let positions: [SIMD3<Float>] = [[0, 0, hz], [hx, 0, 0], [0, hy, 0]]
        
        let cones = [pointer_entity_group.cones.x, pointer_entity_group.cones.y, pointer_entity_group.cones.z]
        
        for i in 0..<3
        {
            cones[i].position = positions[i]
        }
    }
    
    /// Builds wireframe bounding box visualization for selected object.
    ///
    /// Creates edge-aligned line segments forming a 3D box.
    public func make_wire_bounding_box(line_width: Float = 0.001) -> Entity
    {
        let parent = Entity()
        
        var material = SimpleMaterial(
            color: .gray.withAlphaComponent(0.5), //color.withAlphaComponent(0.5),
            roughness: 1.0,
            isMetallic: false
        )
        material.faceCulling = .none
        
        // XZ
        pointer_entity_group.faces.xz0.addChild(
            line(
                position: [line_width / 2,  line_width / 2, 0],
                rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            )
        )
        pointer_entity_group.faces.xz0.addChild(
            line(
                position: [0,  line_width / 2, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            )
        )
        parent.addChild(pointer_entity_group.faces.xz0)
        
        pointer_entity_group.faces.xz1.addChild(
            line(
                position: [-line_width / 2,  line_width / 2, 0],
                rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            )
        )
        pointer_entity_group.faces.xz1.addChild(
            line(
                position: [0,  line_width / 2, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            )
        )
        parent.addChild(pointer_entity_group.faces.xz1)
        
        pointer_entity_group.faces.xz2.addChild(
            line(
                position: [-line_width / 2,  line_width / 2, 0],
                rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            )
        )
        pointer_entity_group.faces.xz2.addChild(
            line(
                position: [0,  line_width / 2, line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            )
        )
        parent.addChild(pointer_entity_group.faces.xz2)
        
        pointer_entity_group.faces.xz3.addChild(
            line(
                position: [line_width / 2,  line_width / 2, 0],
                rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            )
        )
        pointer_entity_group.faces.xz3.addChild(
            line(
                position: [0,  line_width / 2, line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            )
        )
        parent.addChild(pointer_entity_group.faces.xz3)
        
        // XY
        pointer_entity_group.faces.xy0.addChild(
            line(
                position: [line_width / 2,  line_width / 2, 0],
                rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            )
        )
        pointer_entity_group.faces.xy0.addChild(
            line(
                position: [line_width / 2,  0, line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            )
        )
        parent.addChild(pointer_entity_group.faces.xy0)
        
        pointer_entity_group.faces.xy1.addChild(
            line(
                position: [line_width / 2,  line_width / 2, 0],
                rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            )
        )
        pointer_entity_group.faces.xy1.addChild(
            line(
                position: [line_width / 2,  0, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            )
        )
        parent.addChild(pointer_entity_group.faces.xy1)
        
        pointer_entity_group.faces.xy2.addChild(
            line(
                position: [line_width / 2,  -line_width / 2, 0],
                rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            )
        )
        pointer_entity_group.faces.xy2.addChild(
            line(
                position: [line_width / 2,  0, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            )
        )
        parent.addChild(pointer_entity_group.faces.xy2)
        
        pointer_entity_group.faces.xy3.addChild(
            line(
                position: [line_width / 2,  -line_width / 2, 0],
                rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            )
        )
        pointer_entity_group.faces.xy3.addChild(
            line(
                position: [line_width / 2,  0, line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            )
        )
        parent.addChild(pointer_entity_group.faces.xy3)
        
        // YZ
        pointer_entity_group.faces.yz0.a.addChild(
            line(
                position: [line_width / 2,  0, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 0])
            )
        )
        parent.addChild(pointer_entity_group.faces.yz0.a)
        pointer_entity_group.faces.yz0.b.addChild(
            line(
                position: [0,  line_width / 2, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            )
        )
        parent.addChild(pointer_entity_group.faces.yz0.b)
        
        pointer_entity_group.faces.yz1.a.addChild(
            line(
                position: [-line_width / 2,  0, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 0])
            )
        )
        parent.addChild(pointer_entity_group.faces.yz1.a)
        pointer_entity_group.faces.yz1.b.addChild(
            line(
                position: [0,  line_width / 2, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            )
        )
        parent.addChild(pointer_entity_group.faces.yz1.b)
        
        pointer_entity_group.faces.yz2.a.addChild(
            line(
                position: [-line_width / 2,  0, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 0])
            )
        )
        parent.addChild(pointer_entity_group.faces.yz2.a)
        pointer_entity_group.faces.yz2.b.addChild(
            line(
                position: [0,  -line_width / 2, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            )
        )
        parent.addChild(pointer_entity_group.faces.yz2.b)
        
        pointer_entity_group.faces.yz3.a.addChild(
            line(
                position: [line_width / 2,  0, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 0])
            )
        )
        parent.addChild(pointer_entity_group.faces.yz3.a)
        pointer_entity_group.faces.yz3.b.addChild(
            line(
                position: [0,  -line_width / 2, -line_width / 2],
                rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            )
        )
        parent.addChild(pointer_entity_group.faces.yz3.b)
        
        return parent
        
        func line(position: SIMD3<Float>, rotation: simd_quatf) -> ModelEntity
        {
            let mesh = MeshResource.generatePlane(width: line_width, depth: line_width)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.position = position
            entity.orientation = rotation
            return entity
        }
    }
    
    /// Updates wireframe bounding box to match object size.
    ///
    /// Dynamically scales and repositions edges.
    ///
    /// - Parameters:
    ///   - size: Object bounding box size
    ///   - color: Line color
    ///   - line_width: Thickness of wireframe
    private func update_wire_bounding_box(by size: SIMD3<Float>, color: UIColor = .gray, line_width: Float = 0.001)
    {
        let hx = size.x / 2
        let hy = size.y / 2
        let hz = size.z / 2
        
        let size_multiplier: Float = 1 / line_width
        
        // XZ Lines
        pointer_entity_group.faces.xz0.scale.y = size.y * size_multiplier
        pointer_entity_group.faces.xz0.position = [-hx, -hy, hz]
        
        pointer_entity_group.faces.xz1.scale.y = size.y * size_multiplier
        pointer_entity_group.faces.xz1.position = [hx, -hy, hz]
        
        pointer_entity_group.faces.xz2.scale.y = size.y * size_multiplier
        pointer_entity_group.faces.xz2.position = [hx, -hy, -hz]
        
        pointer_entity_group.faces.xz3.scale.y = size.y * size_multiplier
        pointer_entity_group.faces.xz3.position = [-hx, -hy, -hz]
        
        // XY Lines
        var gapped_size = size_multiplier * (size.x - line_width * 2)
        
        pointer_entity_group.faces.xy0.scale.x = gapped_size
        pointer_entity_group.faces.xy0.position = [-hx + line_width, -hy, -hz]
        
        pointer_entity_group.faces.xy1.scale.x = gapped_size
        pointer_entity_group.faces.xy1.position = [-hx + line_width, -hy, hz]
        
        pointer_entity_group.faces.xy2.scale.x = gapped_size
        pointer_entity_group.faces.xy2.position = [-hx + line_width, hy, hz]
        
        pointer_entity_group.faces.xy3.scale.x = gapped_size
        pointer_entity_group.faces.xy3.position = [-hx + line_width, hy, -hz]
        
        // YZ Lines
        gapped_size = size_multiplier * (size.z - line_width * 2)
        
        pointer_entity_group.faces.yz0.a.scale.z = size.z * size_multiplier
        pointer_entity_group.faces.yz0.a.position = [-hx, -hy, hz]
        pointer_entity_group.faces.yz0.b.scale.z = gapped_size
        pointer_entity_group.faces.yz0.b.position = [-hx, -hy, hz - line_width]
        
        pointer_entity_group.faces.yz1.a.scale.z = size.z * size_multiplier
        pointer_entity_group.faces.yz1.a.position = [hx, -hy, hz]
        pointer_entity_group.faces.yz1.b.scale.z = gapped_size
        pointer_entity_group.faces.yz1.b.position = [hx, -hy, hz - line_width]
        
        pointer_entity_group.faces.yz2.a.scale.z = size.z * size_multiplier
        pointer_entity_group.faces.yz2.a.position = [hx, hy, hz]
        pointer_entity_group.faces.yz2.b.scale.z = gapped_size
        pointer_entity_group.faces.yz2.b.position = [hx, hy, hz - line_width]
        
        pointer_entity_group.faces.yz3.a.scale.z = size.z * size_multiplier
        pointer_entity_group.faces.yz3.a.position = [-hx, hy, hz]
        pointer_entity_group.faces.yz3.b.scale.z = gapped_size
        pointer_entity_group.faces.yz3.b.position = [-hx, hy, hz - line_width]
    }
    
    // MARK: - Placements
    /// Computes collision-free placement for a new object.
    ///
    /// Uses AABB intersection checks and radial candidate search
    /// to avoid overlaps with existing robots/tools/parts.
    ///
    /// - Parameter object: Object to place
    private func comfort_placement(for object: ProductionObject)
    {
        let object_rect = rect(of: object)

        // Occupied rectangles
        var occupied: [(center: SIMD2<Float>, half: SIMD2<Float>)] = []
        
        for group in [robots as [ProductionObject], tools, parts]
        {
            for item in group
            {
                guard item !== object, item.model_entity != nil else { continue }
                
                if let tool = item as? Tool, tool.attached_to != nil { continue }
                
                occupied.append(rect(of: item))
            }
        }
        
        // Convert RealityKit bounds to workspace units
        func rect(of item: ProductionObject) -> (center: SIMD2<Float>, half: SIMD2<Float>)
        {
            let entity = item.model_entity ?? Entity()
            let b = entity.visualBounds(relativeTo: entity)
            
            let center = SIMD2<Float>(item.position.x, item.position.y)
            let half = SIMD2<Float>(b.extents.x, b.extents.y) * 500
            
            return (center, half)
        }
        
        @inline(__always)
        func grid(_ p: SIMD2<Float>) -> SIMD2<Float>
        {
            SIMD2<Float>(round(p.x), round(p.y))
        }
        
        @inline(__always)
        func dist2(_ p: SIMD2<Float>) -> Float
        {
            p.x * p.x + p.y * p.y
        }
        
        // AABB intersection
        func intersects(_ p: SIMD2<Float>) -> Bool
        {
            let min_a = p - object_rect.half
            let max_a = p + object_rect.half
            
            for r in occupied
            {
                let min_b = r.center - r.half
                let max_b = r.center + r.half
                
                if !(max_a.x < min_b.x ||
                     min_a.x > max_b.x ||
                     max_a.y < min_b.y ||
                     min_a.y > max_b.y)
                {
                    return true
                }
            }
            return false
        }
        
        // Start at origin
        var placement: SIMD2<Float> = .zero
        
        if intersects(placement)
        {
            let gap: Float = 10 // 10 mm gap
            var best: SIMD2<Float>? = nil
            var best_d2: Float = .greatestFiniteMagnitude
            
            for r in occupied
            {
                let dx = r.half.x + object_rect.half.x + gap
                let dy = r.half.y + object_rect.half.y + gap
                
                let candidates =
                [
                    r.center + SIMD2<Float>( dx,  0),
                    r.center + SIMD2<Float>(-dx,  0),
                    r.center + SIMD2<Float>( 0,  dy),
                    r.center + SIMD2<Float>( 0, -dy)
                ]
                
                for p in candidates
                {
                    let g = grid(p)
                    if intersects(g) { continue }
                    
                    let d2 = dist2(g)
                    if d2 < best_d2
                    {
                        best_d2 = d2
                        best = g
                    }
                }
            }
            
            placement = best ?? .zero
        }
        
        placement = grid(placement)
        
        object.position.x = placement.x
        object.position.y = placement.y
    }
    
    // MARK: - Robots handling functions
    // MARK: Robots manage functions
    /// Adds a robot to the workspace.
    ///
    /// The robot is inserted into the workspace model and registered in the scene.
    /// Its name is normalized to ensure uniqueness before insertion.
    ///
    /// - Parameter robot: The robot instance to add.
    public func add_robot(_ robot: Robot)
    {
        robot.name = unique_name(for: robot.name, in: robot_names)
        robot.is_placed = true
        robots.append(robot)
        
        comfort_placement(for: robot)
        place_object_entity(object: robot)
    }
    
    /// Removes a robot from the workspace by index.
    ///
    /// The robot is removed from internal storage and detached from the scene graph.
    /// Any dependent program state is updated after removal.
    ///
    /// - Parameter index: Index of the robot in the workspace.
    public func delete_robot(at index: Int)
    {
        if robots.indices.contains(index)
        {
            robots[index].entity.removeFromParent()
            
            robots.remove(at: index)
            
            if let selected_program = selected_program { elements_check(program: selected_program) }
        }
    }
    
    /// Removes a robot from the workspace by name.
    ///
    /// The robot is resolved by name and removed using its index.
    ///
    /// - Parameter name: Name of the robot to remove.
    public func delete_robot(name: String)
    {
        delete_robot(at: object_index(of: name, in: robots))
    }
    
    /// Creates a duplicate of a robot by index.
    ///
    /// The new robot is inserted as a separate instance with a unique name.
    /// It is initially marked as not placed in the workspace.
    ///
    /// - Parameter index: Index of the robot to duplicate.
    public func duplicate_robot(at index: Int)
    {
        if robots.indices.contains(index)
        {
            let new_name = unique_name(for: robots[index].name, in: robot_names)
            let new_index = robots.count
            
            robots.append(Robot())
            
            //robots[new_index] = clone_codable(robots[index]) ?? Robot() // Robot(robot_struct: robots[index].file_info)
            robots[new_index].name = new_name
            robots[new_index].is_placed = false
        }
    }
    
    /// Creates a duplicate of a robot by name.
    ///
    /// The robot is resolved by name and duplicated using index-based lookup.
    ///
    /// - Parameter name: Name of the robot to duplicate.
    public func duplicate_robot(name: String)
    {
        duplicate_robot(at: object_index(of: name, in: robots))
    }
    
    // MARK: Robot selection functions
    /// Selects a robot by name.
    ///
    /// The selected robot becomes the active object in the workspace.
    /// Auxiliary visualization components are enabled for the robot.
    ///
    /// - Parameter name: Name of the robot to select.
    public func select_robot(named name: String)
    {
        selected_object = robots[object_index(of: name, in: robots)]
        
        // Enable accessories
        let robot = selected_object as? Robot
        robot?.toggle_position_pointer_visibility()
        robot?.toggle_working_area_visibility()
    }
    
    // MARK: Robots naming
    /// Returns a robot by name.
    ///
    /// If no robot is found, an empty `Robot` instance is returned.
    ///
    /// - Parameter name: Name of the robot.
    /// - Returns: The robot instance if found, otherwise an empty `Robot`.
    public func robot(named name: String) -> Robot
    {
        let index = object_index(of: name, in: robots)
        if robots.indices.contains(index)
        {
            return self.robots[index]
        }
        else
        {
            return Robot()
        }
        
        // return self.robots[robot_index_by_name(name)]
    }
    
    /// List of robot names in workspace.
    public var robot_names: [String] { robots.map { $0.name } }
    
    /// Names of robots currently placed in workspace.
    public var placed_robot_names: [String] { robots.compactMap { $0.is_placed ? $0.name : nil } }
    
    /// Names of robots supporting tool attachment.
    public var attachment_supporting_robot_names: [String] { robots.compactMap { $0.is_placed && !$0.end_entity_name.isEmpty ? $0.name : nil } }
    
    /// Stops all external connector programs attached to robots.
    ///
    /// All active external integrations associated with robots are terminated.
    public func stop_robot_external_connectors()
    {
        robots.compactMap { $0.connector as? any ExternalConnector }
            .forEach { $0.stop_program_component() }
    }
    
    // MARK: - Tools handling functions
    // MARK: Tools manage funcions
    /// Adds a tool to the workspace.
    ///
    /// The tool is inserted into the workspace model and registered in the scene.
    /// Its name is normalized to ensure uniqueness before insertion.
    ///
    /// - Parameter tool: The tool instance to add.
    public func add_tool(_ tool: Tool)
    {
        tool.name = unique_name(for: tool.name, in: tool_names)
        tool.is_placed = true
        tools.append(tool)
        
        comfort_placement(for: tool)
        place_object_entity(object: tool)
    }
    
    /// Removes a tool from the workspace by index.
    ///
    /// The tool is detached from the scene graph and removed from storage.
    /// Dependent program state is updated after removal.
    ///
    /// - Parameter index: Index of the tool in the workspace.
    public func delete_tool(index: Int)
    {
        if tools.indices.contains(index)
        {
            tools[index].entity.removeFromParent()
            
            tools.remove(at: index)
            
            if let selected_program = selected_program { elements_check(program: selected_program) }
        }
    }
    
    /// Removes a tool from the workspace by name.
    ///
    /// The tool is resolved by name and removed using its index.
    ///
    /// - Parameter name: Name of the tool to remove.
    public func delete_tool(name: String)
    {
        delete_tool(index: object_index(of: name, in: tools))
    }
    
    /// Creates a duplicate of a tool by index.
    ///
    /// The new tool is inserted as a separate instance with a unique name.
    /// It is initially marked as not placed.
    ///
    /// - Parameter index: Index of the tool to duplicate.
    public func duplicate_tool(index: Int)
    {
        if tools.indices.contains(index)
        {
            let new_name = unique_name(for: tools[index].name, in: tool_names)
            let new_index = tools.count
            
            tools.append(Tool())
            
            //tools[new_index] = clone_codable(tools[index]) ?? Tool() // Tool(tool_struct: tools[index].file_info)
            tools[new_index].name = new_name
            tools[new_index].is_placed = false
        }
    }
    
    /// Creates a duplicate of a tool by name.
    ///
    /// The tool is resolved by name and duplicated using index-based lookup.
    ///
    /// - Parameter name: Name of the tool to duplicate.
    public func duplicate_tool(name: String)
    {
        duplicate_tool(index: object_index(of: name, in: tools))
    }

    // MARK: Tools selection functions
    /// Selects a tool by name.
    ///
    /// The selected tool becomes the active object in the workspace.
    ///
    /// - Parameter name: Name of the tool to select.
    public func select_tool(named name: String) // Select tool by name
    {
        selected_object = tools[object_index(of: name, in: tools)]
    }
    
    /// Returns a tool by name.
    ///
    /// If no tool is found, an empty `Tool` instance is returned.
    ///
    /// - Parameter name: Name of the tool.
    /// - Returns: The tool instance if found, otherwise an empty `Tool`.
    public func tool(named name: String) -> Tool
    {
        let index = object_index(of: name, in: tools)
        if tools.indices.contains(index)
        {
            return self.tools[index]
        }
        else
        {
            return Tool()
        }
    }
    
    /// List of tool names in workspace.
    public var tool_names: [String] { tools.map { $0.name } }
    
    /// Names of tools currently placed in workspace.
    public var placed_tool_names: [String] { tools.compactMap { $0.is_placed ? $0.name : nil } }
    
    // MARK: Tool attachment functions
    /// Updates tool attachment hierarchy.
    ///
    /// Tools are attached either to a robot end effector or to the workspace root,
    /// depending on their attachment state.
    public func update_tool_attachments()
    {
        if !(tools.count > 0) { return }
        
        for tool in tools
        {
            if let attached_to = tool.attached_to
            {
                let end_point_entity = robot(named: attached_to).end_point_entity
                
                end_point_entity.addChild(tool.entity)
                tool.set_local_position()
            }
            else
            {
                workspace_entity.addChild(tool.entity)
                tool.set_global_position()
            }
        }
    }
    
    /// Stops all external connector programs attached to tools.
    ///
    /// All active external integrations associated with tools are terminated.
    public func stop_tool_external_connectors()
    {
        tools.compactMap { $0.connector as? any ExternalConnector }
            .forEach { $0.stop_program_component() }
    }
    
    // MARK: - Parts handling functions
    // MARK: Parts manage funcions
    /// Adds a part to the workspace.
    ///
    /// The part is inserted into the workspace model and registered in the scene.
    /// Its name is normalized to ensure uniqueness before insertion, and the part
    /// becomes available for interaction within the workspace.
    ///
    /// - Parameter part: The part instance to add.
    public func add_part(_ part: Part)
    {
        part.name = unique_name(for: part.name, in: part_names)
        part.is_placed = true
        parts.append(part)
        
        comfort_placement(for: part)
        place_object_entity(object: part)
    }
    
    /// Removes a part from the workspace by index.
    ///
    /// The part is detached from the scene graph and removed from internal storage.
    ///
    /// - Parameter index: Index of the part in the workspace.
    public func delete_part(index: Int)
    {
        if parts.indices.contains(index)
        {
            parts[index].entity.removeFromParent()
            
            parts.remove(at: index)
        }
    }
    
    /// Removes a part from the workspace by name.
    ///
    /// The part is resolved by its name and removed using its index.
    ///
    /// - Parameter name: Name of the part to remove.
    public func delete_part(name: String)
    {
        delete_part(index: object_index(of: name, in: parts))
    }
    
    /// Creates a duplicate of a part by index.
    ///
    /// The new part is inserted as a separate instance with a unique name.
    /// It is initially marked as not placed in the workspace.
    ///
    /// - Parameter index: Index of the part to duplicate.
    public func duplicate_part(index: Int)
    {
        if parts.indices.contains(index)
        {
            let new_name = unique_name(for: parts[index].name, in: part_names)
            let new_index = parts.count

            parts.append(Part())

            //parts[new_index] = clone_codable(parts[index]) ?? Part() // Part(part_struct: parts[index].file_info)
            parts[new_index].name = new_name
            parts[new_index].is_placed = false
        }
    }
    
    /// Creates a duplicate of a part by name.
    ///
    /// The part is resolved by name and duplicated using index-based lookup.
    ///
    /// - Parameter name: Name of the part to duplicate.
    public func duplicate_part(name: String)
    {
        duplicate_part(index: object_index(of: name, in: parts))
    }
    
    // MARK: Parts selection functions
    /// Selects a part by name.
    ///
    /// The selected part becomes the active object in the workspace.
    ///
    /// - Parameter name: Name of the part to select.
    public func select_part(named name: String)
    {
        selected_object = parts[object_index(of: name, in: parts)]
    }
    
    /// Returns a part by name.
    ///
    /// If no part is found, a new empty `Part` instance is returned.
    ///
    /// - Parameter name: Name of the part.
    /// - Returns: The part instance if found, otherwise an empty `Part`.
    public func part(named name: String) -> Part
    {
        let index = object_index(of: name, in: parts)
        if parts.indices.contains(index)
        {
            return self.parts[index]
        }
        else
        {
            return Part()
        }
    }
    
    /// List of part names in workspace.
    public var part_names: [String] { parts.map { $0.name } }
    
    /// Names of parts currently placed in workspace.
    public var placed_part_names: [String] { parts.compactMap { $0.is_placed ? $0.name : nil } }
    
    // MARK: - File Hanlding
    /// Returns a serializable representation of the tool.
    public func file_data() ->
    (
        robots: [RobotFileData],
        tools: [ToolFileData],
        parts: [PartFileData],
        
        programs: [ProductionProgram],
        registers: [Float]
    )
    {
        // Robots
        let robots_file_info: [RobotFileData] = robots.map
        {
            $0.file_data()
        }
        
        // Tools
        let tools_file_info: [ToolFileData] = tools.map
        {
            $0.file_data()
        }
        
        // Parts
        let parts_file_info: [PartFileData] = parts.map
        {
            $0.file_data()
        }
        
        return (
            robots: robots_file_info,
            tools: tools_file_info,
            parts: parts_file_info,
            
            programs: programs,
            registers: registers
        )
    }
    
    /// Creates a workspace from file data.
    ///
    /// - Parameter file: A serialized workspace representation.
    public func file_view(preset: WorkspacePreset)
    {
        // Robots
        robots.removeAll()
        
        for robot_file in preset.robots
        {
            let robot = Robot(file: robot_file)
            robots.append(robot)
        }
        
        // Tools
        tools.removeAll()
        
        for tool_file in preset.tools
        {
            let tool = Tool(file: tool_file)
            tools.append(tool)
        }
        
        // Parts
        parts.removeAll()
        
        for part_file in preset.parts
        {
            let part = Part(file: part_file)
            parts.append(part)
        }
        
        // Workspace production programs
        programs.removeAll()
        
        for program in preset.programs
        {
            programs.append(program)
        }
        
        // Registers
        registers = preset.registers ?? [Float](repeating: 0, count: Workspace.default_registers_count)
    }
}

//MARK: - Workspace File Data

/// Type of production object in workspace.
///
/// Used for runtime identification and selection logic.
public enum ProductionObjectType: String, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
    case part = "Part"
}

/// Serializable workspace snapshot used for saving/loading.
///
/// Contains all production objects and execution state.
public struct WorkspacePreset: Codable
{
    public var robots = [RobotFileData]()
    public var tools = [ToolFileData]()
    public var parts = [PartFileData]()
    
    public var programs = [ProductionProgram]()
    public var registers: [Float]?
    
    public init()
    {
        robots = [RobotFileData]()
        tools = [ToolFileData]()
        parts = [PartFileData]()
        
        programs = [ProductionProgram]()
    }
    
    public init(
        robots: [RobotFileData],
        tools: [ToolFileData],
        parts: [PartFileData],
        
        programs: [ProductionProgram]
    )
    {
        self.robots = robots
        self.tools = tools
        self.parts = parts
        
        self.programs = programs
    }
}

// MARK: - Math Element Functions
private enum MathToken // Tokens
{
    case number(Float)
    case register(Int)
    case function(String)
    case constant(Float)
    case op(Character)
    case lparen
    case rparen
}

private func precedence(_ op: Character) -> Int // Operations priority
{
    switch op
    {
    case "+", "-": return 1
    case "*", "/": return 2
    case "^": return 3
    default: return 0
    }
}

@MainActor private let math_functions: [String: (Float) -> Float] =
[
    "sin": { sin($0) },
    "cos": { cos($0) },
    "sqrt": { sqrt($0) }
]

private let math_constants: [String: Float] =
[
    "pi": Float.pi
]

private func is_right_associative(_ op: Character) -> Bool
{
    return op == "^"
}

private func tokenize(_ expr: String) -> [MathToken] // String to tokens
{
    var tokens: [MathToken] = []
    var i = expr.startIndex
    
    func next() { i = expr.index(after: i) }
    
    while i < expr.endIndex
    {
        let c = expr[i]
        
        if c.isWhitespace { next(); continue }
        
        // Numbers
        if c.isNumber || c == "."
        {
            var number = ""
            while i < expr.endIndex && (expr[i].isNumber || expr[i] == ".")
            {
                number.append(expr[i])
                next()
            }
            tokens.append(.number(Float(number) ?? 0))
            continue
        }
        
        // Registers — [n]
        if c == "["
        {
            next()
            var index = ""
            while i < expr.endIndex && expr[i] != "]"
            {
                index.append(expr[i])
                next()
            }
            next()
            tokens.append(.register(Int(index) ?? 0))
            continue
        }
        
        // Functions and constants
        if c.isLetter
        {
            var name = ""
            while i < expr.endIndex && (expr[i].isLetter)
            {
                name.append(expr[i])
                next()
            }
            
            if let const = math_constants[name]
            {
                tokens.append(.constant(const))
            }
            else
            {
                tokens.append(.function(name))
            }
            continue
        }
        
        if c == "(" { tokens.append(.lparen); next(); continue }
        if c == ")" { tokens.append(.rparen); next(); continue }
        
        if "+-*/^".contains(c)
        {
            tokens.append(.op(c))
            next()
            continue
        }
        
        next()
    }
    
    return tokens
}

private func to_rpn(_ tokens: [MathToken]) -> [MathToken] // Shunting-Yard to RPN
{
    var output: [MathToken] = []
    var stack: [MathToken] = []
    
    for token in tokens
    {
        switch token
        {
        case .number, .register, .constant:
            output.append(token)
            
        case .function:
            stack.append(token)
            
        case .op(let op1):
            while let last = stack.last
            {
                switch last
                {
                case .op(let op2):
                    if (precedence(op2) > precedence(op1)) ||
                       (precedence(op2) == precedence(op1) && !is_right_associative(op1))
                    {
                        output.append(stack.removeLast())
                        continue
                    }
                case .function:
                    output.append(stack.removeLast())
                    continue
                default: break
                }
                break
            }
            stack.append(token)
            
        case .lparen:
            stack.append(token)
            
        case .rparen:
            while let last = stack.last
            {
                if case .lparen = last
                {
                    break
                }
                output.append(stack.removeLast())
            }

            if !stack.isEmpty // Remove "("
            {
                stack.removeLast()
            }

            if let last = stack.last // Push out before the bracket function
            {
                if case .function = last
                {
                    output.append(stack.removeLast())
                }
            }
        }
    }
    
    while let last = stack.last
    {
        output.append(last)
        stack.removeLast()
    }
    
    return output
}

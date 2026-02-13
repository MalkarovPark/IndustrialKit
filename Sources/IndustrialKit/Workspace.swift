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
@MainActor
public class Workspace: ObservableObject, @unchecked Sendable
{
    // MARK: - Init functions
    public init()
    {
        current_element = RobotPerformerElement()//MarkLogicElement(name: "")
        
        registers = [Float](repeating: 0, count: Workspace.default_registers_count)
    }
    
    // MARK: - Workspace objects data
    @Published public var robots = [Robot]()
    @Published public var tools = [Tool]()
    @Published public var parts = [Part]()
    
    // MARK: - Selection handling functions
    /**
     Returns index number of workspace object by name.
     
     - Parameters:
        - name: A name of object for index find.
        - objects: An array of objects where the index searches.
     */
    private func index_by_name(_ name: String, objects: [WorkspaceObject]) -> Int
    {
        return objects.firstIndex(where: { $0.name == name }) ?? -1
    }
    
    /// Selected workspace object.
    @Published public var selected_object: WorkspaceObject?
    
    /// Deselects selected object.
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
            deselect_program()//break
        }
        
        selected_object = nil
    }
    
    public func delete_object(_ object: WorkspaceObject)
    {
        object.entity.removeFromParent()
        
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
    
    // MARK: - Update functions
    ///  Flag indicating whether the update loop is active.
    private var updated = false
    
    ///  The task responsible for executing the update loop.
    private var update_task: Task<Void, Never>?
    
    /// The interval between updates in nanoseconds.
    nonisolated(unsafe) public static var update_interval: Double = 0.01
    
    /**
     Starts the update loop.
     
     This function sets the `updated` flag to `true` and initiates a new task that repeatedly calls the `update()` function on the main thread.  The loop runs as long as the `updated` flag remains `true`.  A sleep duration of approximately 1 millisecond is introduced between each update cycle. The task can be cancelled by calling `disable_update()`.
     */
    public func perform_update()
    {
        updated = true
        
        update_task = Task
        {
            while updated
            {
                try? await Task.sleep(nanoseconds: UInt64(Workspace.update_interval * 1_000_000_000))
                await MainActor.run
                {
                    self.update()
                }
                
                if(update_task == nil)
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
    public func disable_update()
    {
        updated = false
        update_task?.cancel()
        update_task = nil
    }
    
    /**
     Called repeatedly within the update loop to perform updates.
     
     This function is called on the main thread by the `perform_update()` function as long as the `updated` flag is `true`. Subclasses should override this method to implement their specific update logic.
     
     > This function is called frequently, so it's crucial to keep its execution time as short as possible to avoid performance issues.
     */
    public func update()
    {
        /*switch selected_object_type
        {
        case .robot:
            selected_robot.update()
        case .tool:
            selected_tool.update()
        case .part:
            break
        case .none:
            break
        }*/
    }
    
    // MARK: - Program manage functions
    /// An array of tool operations programs.
    @Published public var programs = [ProductionProgram]()
    
    /// A selected operations program index.
    public var selected_program_index = -1
    {
        willSet
        {
            // Stop workspace performing before program change
            performed = false
            selected_element_index = 0
        }
    }
    
    /**
     Adds new operations program to tool.
     - Parameters:
        - program: A new tool operations program.
     */
    public func add_program(_ program: ProductionProgram)
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
    public func update_program(index: Int, _ program: ProductionProgram) // Update program by index
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
    public func update_program(name: String, _ program: ProductionProgram) // Update program by name
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
    
    /// Returns index by program name.
    private func index_by_name(name: String) -> Int // Get index of program by name
    {
        return programs.firstIndex(of: ProductionProgram(name: name)) ?? -1
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
    
    // MARK: Single element handling
    /// Single program element.
    @Published public var current_element: WorkspaceProgramElement
    
    private var is_single_performed = false
    
    private var previous_performing_state: PerformingState = .none
    
    public func start_pause_single_element()
    {
        if !is_single_performed
        {
            single_element_perform()
        }
        else
        {
            single_operation_reset()
        }
    }
    
    public func single_element_perform()
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
    
    public func single_operation_reset()
    {
        if is_single_performed
        {
            is_single_performed = false
            //stop()
            performing_state = previous_performing_state //.none
        }
    }
    
    // MARK: Workspace progem elements checking functions
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
            var checked_object = robot_by_name(element.object_name)
            
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
                if placed_robots_names.count > 0
                {
                    element.object_name = placed_robots_names.first ?? ""
                    checked_object = robot_by_name(element.object_name)
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
                    if !checked_object.programs_names.contains(element.program_name)
                    {
                        element.program_name = checked_object.programs_names.first ?? ""
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
            var checked_object = tool_by_name(element.object_name)
            
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
                if placed_tools_names.count > 0
                {
                    element.object_name = placed_tools_names.first ?? ""
                    checked_object = tool_by_name(element.object_name)
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
                    if !checked_object.programs_names.contains(element.program_name)
                    {
                        element.program_name = checked_object.programs_names.first ?? ""
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
                if self.placed_robots_names.count > 0
                {
                    element.object_name = self.placed_robots_names.first!
                }
                else
                {
                    element.object_name = ""
                }
            case .tool:
                if self.placed_tools_names.count > 0
                {
                    element.object_name = self.placed_tools_names.first!
                }
                else
                {
                    element.object_name = ""
                }
            }
        }
        
        func changer_element_check(_ element: ChangerModifierElement)
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
        }
        
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
    
    // MARK: - Performing functions
    /// Program performing cycle state.
    @Published public var cycled = false
    
    /// Workspace performing state.
    @Published public var performed = false
    
    /// An Index of target element in control program array.
    private var selected_element_index = 0
    
    /// A target code in operation codes array.
    public var selected_program_element: WorkspaceProgramElement //A selected workspace program element.
    {
        get
        {
            return selected_program?.elements[safe: selected_element_index] ?? WorkspaceProgramElement()
        }
        set
        {
            selected_program?.elements[safe: selected_program_index] = newValue
        }
    }
    
    /// Cancel perform flag.
    //public var canceled = false
    
    private var performing_task = Task<Void, Error> {}
    
    // MARK: Performation cycle
    /**
     Performs program element on workspace with completion handler.
     
     - Parameters:
        - element: The program element performed by the workspace.
        - completion: A completion function that is calls when the performing completes.
     */
    public func perform(element: WorkspaceProgramElement, completion: @escaping @Sendable (Result<Void, Error>) -> Void = { _ in })
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
                update_registers_count(reference_count)
            }
        }
    }
    
    /// A workspace performation toggle.
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
            disable_constant_objects_update()
            
            selected_program_element.performing_state = .current //selected_program.elements[selected_element_index].performing_state = .current
            
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
            let robot = robot_by_name(element.object_name)
            
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
            
            robot.disable_update()
        }
        
        func pause_handler(_ element: ToolPerformerElement)
        {
            let tool = tool_by_name(element.object_name)
            
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
            
            tool.disable_update()
        }
    }
    
    /// Selects and performs program element by workspace.
    public func perform_next_element()
    {
        selected_program_element.performing_state = .processing
        
        //performed = true
        
        perform(element: selected_program_element)
        { result in
            Task
            { @MainActor in
                switch result
                {
                case .success:
                    self.selected_program_element.performing_state = .completed
                    //self.selected_operation_code.performing_state = self.connector.performing_state.output
                    
                    self.select_next_element()
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
        
        selected_program_element.performing_state = .error
        performing_state = .error // State light (UI)
        
        //model_controller.reset_entities()
        
        /*if demo
        {
            //model_controller.reset_entities()
        }
        else
        {
            // Remove actions for real tool
            connector.canceled = true
            connector.reset_device()
        }*/
    }
    
    /// Set the new target program element index.
    private func select_next_element()
    {
        guard let selected_program = self.selected_program
        else
        {
            finish_handler()
            return
        }
        
        //if !performed { return }
        
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
                
                //deselect_object()
                
                performing_state = .completed // State light (UI)
                program_performed = false // Control Buttons (UI)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                {
                    self.performing_state = .none // State light (UI)
                    self.selected_program?.reset_elements_states()
                }
                
                update()
                //pointer_position_to_robot()
                
                finish_handler()
            }
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
    private func error_handler(_ error: Error)
    {
        performed = false // Pause performing
        
        disable_constant_objects_update()
        
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
    
    /// Resets workspace performing.
    public func reset_performing()
    {
        disable_constant_objects_update()
        
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
            let robot = robot_by_name(element.object_name)
            
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
            
            robot.disable_update()
        }
        
        func reset_handler(_ element: ToolPerformerElement)
        {
            let tool = tool_by_name(element.object_name)
            
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
            
            tool.disable_update()
        }
    }
    
    // MARK: Update statistics handling
    private func perform_constant_objects_update()
    {
        for robot in robots
        {
            if robot.scope_type == .constant
            {
                robot.perform_update()
            }
        }
        
        for tool in tools
        {
            if tool.scope_type == .constant
            {
                tool.perform_update()
            }
        }
    }
    
    private func disable_constant_objects_update()
    {
        for robot in robots
        {
            if robot.scope_type == .constant
            {
                robot.disable_update()
            }
        }
        
        for tool in tools
        {
            if tool.scope_type == .constant
            {
                tool.disable_update()
            }
        }
    }
    
    // MARK: Registers handling
    /// A default count of data registers for workspace.
    nonisolated(unsafe) public static var default_registers_count = 256
    
    /// An array of data registers of workspace.
    @Published public var registers: [Float]// = [Float](repeating: 0, count: Workspace.default_registers_count)
    
    private func input_registers(_ registers: [Float])
    {
        for (index, value) in registers.enumerated()
        {
            if index < self.registers.count
            {
                self.registers[safe: index] = Float(value)
            }
            else
            {
                break
            }
        }
    }
    
    /**
     Updates count of data registers.
     
     - Parameters:
        - new_count: A new count of registers.
     */
    public func update_registers_count(_ new_count: Int)
    {
        let old_registers = registers
        registers = [Float](repeating: 0, count: new_count)
        
        input_registers(old_registers)
    }
    
    /// Clears all data registers.
    public func clear_registers()
    {
        registers = [Float](repeating: 0, count: registers.count)
    }
    
    /**
     Clears selected register data.
     
     - Parameters:
        - index: An index of register to be cleared.
     */
    public func clear_register(_ index: Int)
    {
        if index < registers.count && index >= 0
        {
            registers[safe: index] = 0
        }
    }
    
    /**
     Updates selected register data.
     
     - Parameters:
        - index: An index of register to be updated.
        - new_value: A new data register value.
     */
    public func update_register(_ index: Int, new_value: Float)
    {
        if index < registers.count && index >= 0
        {
            registers[safe: index] = new_value
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
    
    // MARK: - Element processing
    /**
     Perform robot by element data.
     - Parameters:
        - element: A robot performer element.
     */
    private func perform_robot(by element: RobotPerformerElement, completion: @escaping @Sendable (Result<Void, Error>) -> Void, error_handler: @escaping @Sendable (Error) -> Void)
    {
        let robot = robot_by_name(element.object_name)
        
        if element.is_single_perfrom
        {
            // Single robot perform
            robot.performed = true
            
            var target_point = PositionPoint(x: registers[safe_float: element.x_index],
                                             y: registers[safe_float: element.y_index],
                                             z: registers[safe_float: element.z_index],
                                             r: registers[safe_float: element.r_index],
                                             p: registers[safe_float: element.p_index],
                                             w: registers[safe_float: element.w_index],
                                             move_speed: registers[safe_float: element.speed_index],
                                             move_type: MoveType(register_value: Int(registers[safe_float: element.type_index])))
            robot.point_shift(&target_point)
            
            robot.move_to(point: target_point)
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
            // Program robot perform
            if !element.is_program_by_index
            {
                robot.select_program(name: element.program_name)
            }
            else
            {
                robot.select_program(index: Int(registers[safe: element.program_index] ?? 0))
            }
            
            robot.finish_handler = {
                robot.clear_finish_handler()
                robot.clear_finish_handler()
                
                robot.disable_update()
                
                completion(.success(()))
            }
            robot.error_handler = { error in
                robot.clear_finish_handler()
                robot.clear_finish_handler()
                
                robot.disable_update()
                
                error_handler(error)
            }
            
            robot.start_pause_moving()
        }
    }
    
    /**
     Perform tool by element data.
     - Parameters:
        - element: A tool performer element.
     */
    private func perform_tool(by element: ToolPerformerElement, completion: @escaping @Sendable (Result<Void, Error>) -> Void, error_handler: @escaping @Sendable (Error) -> Void)
    {
        let tool = tool_by_name(element.object_name)
        
        if element.is_single_perfrom
        {
            // Single tool perform
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
            if !element.is_program_by_index
            {
                tool.select_program(name: element.program_name)
            }
            else
            {
                tool.select_program(index: Int(registers[safe: element.program_index] ?? 0))
            }
            
            tool.finish_handler = {
                tool.clear_finish_handler()
                tool.clear_error_handler()
                
                tool.disable_update()
                
                completion(.success(()))
            }
            tool.error_handler = { error in
                tool.clear_finish_handler()
                tool.clear_error_handler()
                
                tool.disable_update()
                
                error_handler(error)
            }
            
            tool.start_pause_performing()
        }
    }
    
    /**
     Move value between registers.
     - Parameters:
        - element: A mover modifier element.
     */
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
    
    /**
     Write value from element to regiser.
     - Parameters:
        - element: A write modifier element.
     */
    private func write(by element: WriterModifierElement)
    {
        for input in element.inputs
        {
            registers[safe: input.to] = input.value
        }
    }
    
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
    
    /**
     Pushes info from tool to register.
     - Parameters:
        - element: An observable modifier element.
     */
    private func observe(by element: ObserverModifierElement, completion: @escaping @Sendable (Result<Void, Error>) -> Void, error_handler: @escaping @Sendable (Error) -> Void)
    {
        var info_output = [Float]()
        
        switch element.object_type
        {
        case .robot:
            robot_by_name(element.object_name).pointer_position_to_robot()
            
            let pointer_position = robot_by_name(element.object_name).pointer_position
            
            info_output.append(pointer_position.x)
            info_output.append(pointer_position.y)
            info_output.append(pointer_position.z)
            
            info_output.append(pointer_position.r)
            info_output.append(pointer_position.p)
            info_output.append(pointer_position.w)
        case .tool:
            if let output = tool_by_name(element.object_name).info_output
            {
                info_output = output
            }
            else
            {
                error_handler(NSError(domain: "No output", code: 0, userInfo: nil))
            }
        }
        
        if element.outputs.count > 0
        {
            for i in 0..<element.outputs.count
            {
                if element.outputs[i].to <= 255 && element.outputs[i].to >= 0 && (element.outputs[i].from < info_output.count)
                {
                    registers[safe: element.outputs[i].to] = info_output[element.outputs[i].from]
                }
            }
        }
        
        completion(.success(()))
    }
    
    /**
     Jumps to program element by index.
     - Parameters:
        - index: An element index to jump.
     */
    private func jump(by element: JumpLogicElement)
    {
        selected_element_index = element.target_element_index
        
        reset_elements_states_to_current() // UI only
    }
    
    /**
     Jumps to program element by index if compare condition is met.
     - Parameters:
        - index: An element index to jump.
     */
    private func compare(by element: ComparatorLogicElement)
    {
        if element.compare_type.compare(registers[safe_float: element.value_index], registers[safe_float: element.value2_index])
        {
            selected_element_index = element.target_element_index
            
            reset_elements_states_to_current() // UI only
        }
    }
    
    private func reset_elements_states_to_current()
    {
        guard let program = selected_program else { return }
        
        for i in selected_element_index ..< program.elements_count
        {
            program.elements[safe: i]?.performing_state = .none
        }
        
        /*let end = max(0, min(selected_element_index, program.elements_count))
        if end == 0 { return }
        
        for i in 0..<end
        {
            program.elements[safe: i]?.performing_state = .none
        }*/
    }
    
    /// Prepare workspace program to perform.
    private func prepare_program(_ program: ProductionProgram)
    {
        program.defining_elements_indexes()
    }
    
    // MARK: - Visual Functions
    #if canImport(RealityKit)
    private var workspace_entity = Entity()
    private var camera_entity: PerspectiveCamera?
    
    public func place_entity(to content: RealityViewCameraContent)
    {
        content.add(workspace_entity)
        
        // Place (connect) camera
        if camera_entity == nil
        {
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 60
            camera.position = [0, 1, 0]
            camera.rotate_x(by: -.pi / 6)
            
            workspace_entity.addChild(camera)
            camera_entity = camera
            
            let cx = Int(round(camera.position.x / cell_size))
            let cz = Int(round(camera.position.z / cell_size))
            create_grid_async(center_x: cx, center_z: cz)
        }
        
        // Place grid
        _ = content.subscribe(to: SceneEvents.Update.self)
        { [weak self] _ in
            guard let self, let camera = self.camera_entity else { return }
            self.update_grid(camera_position: camera.position)
        }
        
        /*// Place (connect) camera
        if camera_entity == nil
        {
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 60
            camera.position = [0, 1, 0]
            camera.rotate_x(by: -.pi / 6)
            
            workspace_entity.addChild(camera)
            camera_entity = camera
        }
        
        // Place grid
        _ = content.subscribe(to: SceneEvents.Update.self)
        { [weak self] _ in
            guard let self, let camera = self.camera_entity else { return }
            
            self.update_grid(camera_position: camera.position)
        }*/
        
        // Dynamic pointer update
        _ = content.subscribe(to: SceneEvents.Update.self)
        { [weak self] _ in
            guard let self else { return }
            
            if self.selected_object != nil { self.update_pointer_entity() }
        }
        
        // Place objects
        place_objects() //(to: workspace_entity)
        update_tool_attachments()
        
        // Perform tool attachments update
        /*_ = content.subscribe(to: SceneEvents.Update.self)
        { [weak self] _ in
            guard let self else { return }
            
            self.update_tool_attachments()
        }*/
    }
    
    public func remove_entity(from content: RealityViewCameraContent)
    {
        content.remove(workspace_entity)
        grid_lines.removeAll()
    }
    
    // MARK: Grid
    private var grid_visible = true
    private var grid_lines: [String: ModelEntity] = [:]

    private let cell_size: Float = 0.1 // 100 mm
    private let render_radius: Int = 200

    private let minor_width: Float = 0.002 //0.001
    private let major_width: Float = 0.0025

    private let major_step = 10

    private let minor_line_mesh = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.002)
    private let major_line_mesh = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.0025)
    private let axis_line_mesh  = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.00375)

    public var is_grid_visible: Bool { grid_visible } // UI Only

    public func toggle_grid_visiblity()
    {
        grid_visible.toggle()
        grid_lines.values.forEach { $0.isEnabled = grid_visible }
        
        self.objectWillChange.send() // UI Only
    }

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

    private enum Axis { case x, z }

    private func create_grid_async(center_x: Int, center_z: Int)
    {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            
            let indices = (-self.render_radius...self.render_radius).map { $0 }
            
            for batchStart in stride(from: 0, to: indices.count, by: 20)
            {
                let batchEnd = min(batchStart + 20, indices.count)
                
                await MainActor.run {
                    for i in batchStart..<batchEnd
                    {
                        let idx = indices[i]
                        self.add_line(index: center_x + idx, axis: .x)
                        self.add_line(index: center_z + idx, axis: .z)
                    }
                }
                
                try? await Task.sleep(nanoseconds: 1_000_000_0) // 1ms пауза между батчами
            }
        }
    }

    private func add_line(index: Int, axis: Axis)
    {
        let key = "\(axis)_\(index)"
        if grid_lines[key] != nil { return }
        
        let is_major = index % major_step == 0
        let is_axis  = index == 0
        
        let width = is_axis ? major_width * 1.5
        : is_major ? major_width
        : minor_width
        
        let color = is_axis
        ? UIColor.gray.withAlphaComponent(0.5)
        : is_major
        ? UIColor.gray.withAlphaComponent(0.4)
        : UIColor.gray.withAlphaComponent(0.3)
        
        let length = Float(render_radius * 2) * cell_size
        
        let mesh: MeshResource
        switch axis
        {
        case .x:
            mesh = is_axis ? axis_line_mesh : is_major ? major_line_mesh : minor_line_mesh
        case .z:
            mesh = is_axis ? axis_line_mesh : is_major ? major_line_mesh : minor_line_mesh
        }
        
        var material = SimpleMaterial(color: color, roughness: 1, isMetallic: false)
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
    
    /*private var grid_visible = true
    private var grid_lines: [String: ModelEntity] = [:]
    
    private let cell_size: Float = 0.1 // 100 mm
    private let render_radius: Int = 200
    
    private let minor_width: Float = 0.002 //0.001
    private let major_width: Float = 0.0025
    
    private let major_step = 10
    
    public var is_grid_visible: Bool { grid_visible } // UI Only
    
    public func toggle_grid_visiblity()
    {
        grid_visible.toggle()
        grid_lines.values.forEach { $0.isEnabled = grid_visible }
        
        self.objectWillChange.send() // UI Only
    }
    
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
    
    private enum Axis { case x, z }
    
    private func add_line(index: Int, axis: Axis)
    {
        let key = "\(axis)_\(index)"
        if grid_lines[key] != nil { return }
        
        let is_major = index % major_step == 0
        let is_axis  = index == 0
        
        let width = is_axis ? major_width * 1.5
        : is_major ? major_width
        : minor_width
        
        let color = is_axis
        ? UIColor.gray.withAlphaComponent(0.5)
        : is_major
        ? UIColor.gray.withAlphaComponent(0.4)
        : UIColor.gray.withAlphaComponent(0.3)
        
        let length = Float(render_radius * 2) * cell_size
        
        let mesh: MeshResource
        switch axis
        {
        case .x:
            mesh = MeshResource.generatePlane(width: length, depth: width)
        case .z:
            mesh = MeshResource.generatePlane(width: width, depth: length)
        }
        
        var material = SimpleMaterial(color: color, roughness: 1, isMetallic: false)
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
    }*/
    #endif
    
    // MARK: Workspace Objects Placement
    public func place_object_entity(object: WorkspaceObject)
    {
        workspace_entity.addChild(object.entity)
        object.entity.update_position(object.position)
    }
    
    public func remove_object_entity(object: WorkspaceObject)
    {
        object.entity.removeFromParent()
    }
    
    private func place_objects()//(to entity: Entity)
    {
        for robot in robots
        {
            place_object_entity(object: robot)
            robot.update_origin_position()
        }
        
        for tool in tools
        {
            place_object_entity(object: tool)
        }
        
        for part in parts
        {
            place_object_entity(object: part)
        }
    }
    
    // MARK: Pointer Handling
    public func process_tap(value: EntityTargetValue<TapGesture.Value>)
    {
        print("Tapped on entity: \(value.entity.name)")
        
        let tapped_entity = value.entity
        
        if let object_identifier = tapped_entity.components[EntityModelIdentifier.self]
        {
            print("📍 Name: \(object_identifier.name), Type: \(object_identifier.type, default: "No")")
            
            if !already_selecting_same_object(object_identifier)
            {
                select_object_by_entity_identifier(object_identifier)
            }
            else
            {
                process_empty_tap()
            }
        }
        else
        {
            process_empty_tap()
        }
        
        func already_selecting_same_object(_ object_identifier: EntityModelIdentifier) -> Bool
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
    
    public func process_empty_tap()
    {
        deselect_object()
        pointer_entity.removeFromParent()
        
        self.objectWillChange.send()
    }
    
    private func select_object_by_entity_identifier(_ entity_identifier: EntityModelIdentifier)
    {
        deselect_object() // Test
        
        deselect_program()
        
        switch entity_identifier.type
        {
        case .robot:
            select_robot(name: entity_identifier.name)
            //set_pointer_entity(to: selected_object?.model_entity ?? Entity())
        case .tool:
            select_tool(name: entity_identifier.name)
            //set_pointer_entity(to: selected_object?.model_entity ?? Entity())
        case .part:
            select_part(name: entity_identifier.name)
            //set_pointer_entity(to: selected_object?.model_entity ?? Entity())
        case .none:
            break
        }
        
        self.objectWillChange.send()
    }
    
    // MARK: Pointer Entity
    private var pointer_entity = Entity()
    
    public func set_pointer_entity(to entity: Entity)
    {
        pointer_entity.removeFromParent()
        
        let bounds = entity.visualBounds(relativeTo: entity)
        
        //pointer_entity = make_object_pointer(bounds: bounds)
        //pointer_entity.addChild(make_wire_bounding_box(bounds: bounds, color: .gray))
        
        // For center reposition
        pointer_entity = make_wire_bounding_box(bounds: bounds, color: .gray)
        pointer_entity.addChild(make_object_pointer(bounds: bounds))
        
        entity.addChild(pointer_entity)
    }
    
    public func disable_pointer_entity()
    {
        pointer_entity.removeFromParent()
    }
    
    public func toggle_pointer_visibility()
    {
        pointer_entity.isEnabled.toggle()
    }
    
    public func update_pointer_entity()
    {
        if let selected_object = selected_object, let model_entity = selected_object.model_entity
        {
            set_pointer_entity(to: model_entity)
        }
    }
    
    private func make_object_pointer(bounds: BoundingBox) -> Entity
    {
        let size = bounds.extents
        
        let shift: Float = 0.04
        
        let cone_height: Float = 0.016
        let cone_radius: Float = 0.008
        
        let hx = size.x / 2 + shift
        let hy = size.y / 2 + shift
        let hz = size.z / 2 + shift
        
        let colors: [UIColor] = [
            UIColor.systemIndigo,
            UIColor.systemPink,
            UIColor.systemTeal
        ]
        let rotations: [SIMD3<Float>] = [[.pi/2, 0, 0], [0, 0,-.pi/2], [0, 0, 0]]
        let positions: [SIMD3<Float>] = [[0, 0, hz], [hx, 0, 0], [0, hy, 0]]
        
        let cylinder_shift: Float = 0.003
        let positions2: [SIMD3<Float>] = [[0, 0, Float(hz) - (cylinder_shift / 2 + cone_height / 2)], [Float(hx) - (cylinder_shift / 2 + cone_height / 2), 0, 0], [0, Float(hy) - (cylinder_shift / 2 + cone_height / 2), 0]]
        
        let parent = Entity()
        
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
            cone.eulerAngles = rotations[i]
            
            parent.addChild(cone)
            
            // Cylinder
            let cylinder = ModelEntity(mesh: .generateCylinder(height: cylinder_shift, radius: cone_radius), materials: [SimpleMaterial(color: .white, roughness: 1.0, isMetallic: false)])
            cylinder.components.set(
                CollisionComponent(
                    shapes: [.generateConvex(from: cone.model!.mesh)]
                )
            )
            cylinder.position = positions2[i]
            cylinder.eulerAngles = rotations[i]
            
            parent.addChild(cylinder)
        }
        
        return parent
    }

    private func make_wire_bounding_box(bounds: BoundingBox, color: UIColor, line_width: Float = 0.001) -> Entity
    {
        let root = Entity()

        let size = bounds.extents
        let center = bounds.center

        let hx = size.x / 2
        let hy = size.y / 2
        let hz = size.z / 2

        var material = SimpleMaterial(
            color: color.withAlphaComponent(0.5),
            roughness: 1.0,
            isMetallic: false
        )
        material.faceCulling = .none

        func line(length: Float, position: SIMD3<Float>, rotation: simd_quatf) -> ModelEntity
        {
            let mesh = MeshResource.generatePlane(width: length, depth: line_width)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.position = position
            entity.orientation = rotation
            return entity
        }
        
        func line(width: Float, depth: Float, position: SIMD3<Float>, rotation: simd_quatf) -> ModelEntity
        {
            let mesh = MeshResource.generatePlane(width: width, depth: depth)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.position = position
            entity.orientation = rotation
            return entity
        }

        // XY Planes
        for z in [-hz, hz]
        {
            root.addChild(
                line(
                    width: size.x - line_width * 2,
                    depth: line_width,
                    position: [0,  hy - line_width / 2, z],
                    rotation: simd_quatf(angle: .pi / 2, axis: [1,0,0])
                )
            )
            
            root.addChild(
                line(
                    width: size.x - line_width * 2,
                    depth: line_width,
                    position: [0,  -hy + line_width / 2, z],
                    rotation: simd_quatf(angle: .pi / 2, axis: [1,0,0])
                )
            )
            
            root.addChild(
                line(
                    width: line_width,
                    depth: size.y,
                    position: [-hx + line_width / 2, 0, z],
                    rotation: simd_quatf(angle: .pi / 2, axis: [1,0,0])
                )
            )
            
            root.addChild(
                line(
                    width: line_width,
                    depth: size.y,
                    position: [hx - line_width / 2, 0, z],
                    rotation: simd_quatf(angle: .pi / 2, axis: [1,0,0])
                )
            )
        }

        // YZ Planes
        for x in [-hx, hx]
        {
            root.addChild(
                line(
                    width: line_width,
                    depth: size.z - line_width * 2,
                    position: [x, hy - line_width / 2, 0],
                    rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                )
            )
            
            root.addChild(
                line(
                    width: line_width,
                    depth: size.z - line_width * 2,
                    position: [x, -hy + line_width / 2, 0],
                    rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                )
            )
            
            root.addChild(
                line(
                    width: size.y,
                    depth: line_width,
                    position: [x, 0, -hz + line_width / 2],
                    rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                )
            )
            
            root.addChild(
                line(
                    width: size.y,
                    depth: line_width,
                    position: [x, 0,  hz - line_width / 2],
                    rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                )
            )
        }

        // XZ Planes
        for y in [-hy, hy]
        {
            root.addChild(
                line(
                    width: size.z - line_width * 2,
                    depth: line_width,
                    position: [-hx + line_width / 2, y, 0],
                    rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
                )
            )
            
            root.addChild(
                line(
                    width: size.z - line_width * 2,
                    depth: line_width,
                    position: [hx - line_width / 2, y, 0],
                    rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
                )
            )
            
            root.addChild(
                line(
                    width: line_width,
                    depth: size.x,
                    position: [0, y, -hz + line_width / 2],
                    rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
                )
            )
            
            root.addChild(
                line(
                    width: line_width,
                    depth: size.x,
                    position: [0, y, hz - line_width / 2],
                    rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
                )
            )
        }
        
        root.position = center
        
        return root
    }
    
    private func comfort_placement(for object: WorkspaceObject)
    {
        // Convert RealityKit bounds to workspace units
        func rect(of item: WorkspaceObject) -> (center: SIMD2<Float>, half: SIMD2<Float>)
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
            p.x*p.x + p.y*p.y
        }
        
        let object_rect = rect(of: object)
        
        // Occupied rectangles
        var occupied: [(center: SIMD2<Float>, half: SIMD2<Float>)] = []
        
        for group in [robots as [WorkspaceObject], tools, parts]
        {
            for item in group where item !== object && item.model_entity != nil
            {
                occupied.append(rect(of: item))
            }
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
    /// Adds robot in the workspace.
    public func add_robot(_ robot: Robot)
    {
        robot.name = mismatched_name(name: robot.name, names: robots_names)
        robot.is_placed = true
        robots.append(robot)
        
        comfort_placement(for: robot)
        place_object_entity(object: robot)
    }
    
    /**
     Deletes robot from workspace.
     
     - Parameters:
        - index: An index of robot to be deleted.
     */
    public func delete_robot(index: Int)
    {
        if robots.indices.contains(index)
        {
            robots.remove(at: index)
            
            if let selected_program = selected_program { elements_check(program: selected_program) }
        }
    }
    
    /**
     Deletes robot from workspace.
     
     - Parameters:
        - name: A name of robot to be deleted.
     */
    public func delete_robot(name: String)
    {
        delete_robot(index: index_by_name(name, objects: robots))
    }
    
    /**
     Duplicates robot in the workspace.
     
     - Parameters:
        - index: An index of robot to be duplicated.
     */
    public func duplicate_robot(index: Int)
    {
        if robots.indices.contains(index)
        {
            let new_name = mismatched_name(name: robots[index].name, names: robots_names)
            let new_index = robots.count
            
            robots.append(Robot())
            
            //robots[new_index] = clone_codable(robots[index]) ?? Robot() // Robot(robot_struct: robots[index].file_info)
            robots[new_index].name = new_name
            robots[new_index].is_placed = false
        }
    }
    
    /**
     Duplicates robot in the workspace.
     
     - Parameters:
        - name: A name of robot to be duplicated.
     */
    public func duplicate_robot(name: String)
    {
        duplicate_robot(index: index_by_name(name, objects: robots))
    }
    
    // MARK: Robot selection functions
    /**
     Selects robot by name.
     
     - Parameters:
        - name: A name of robot to be selected.
     */
    public func select_robot(name: String)
    {
        selected_object = robots[index_by_name(name, objects: robots)]
        
        // Enable accessories
        let robot = selected_object as? Robot
        robot?.toggle_position_pointer_visibility()
        robot?.toggle_working_area_visibility()
    }
    
    // MARK: Robots naming
    /**
     Returns robot by name.
     
     - Parameters:
        - name: A name of tobot for index find.
     */
    public func robot_by_name(_ name: String) -> Robot
    {
        let index = index_by_name(name, objects: robots)
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
    
    /// Names of all robots in the workspace.
    public var robots_names: [String]
    {
        var robots_names = [String]()
        if robots.count > 0
        {
            for robot in robots
            {
                robots_names.append(robot.name)
            }
        }
        return robots_names
    }
    
    /// Names of robots avaliable to place in the workspace.
    public var avaliable_robots_names: [String]
    {
        var names = [String]()
        for robot in robots
        {
            if !robot.is_placed
            {
                names.append(robot.name)
            }
        }
        return names
    }
    
    /// Names of robots placed in the workspace.
    public var placed_robots_names: [String] { robots.compactMap { $0.is_placed ? $0.name : nil } }
    
    // MARK: - Tools handling functions
    // MARK: Tools manage funcions
    /// Adds tool in the workspace.
    public func add_tool(_ tool: Tool)
    {
        tool.name = mismatched_name(name: tool.name, names: tools_names)
        tool.is_placed = true
        tools.append(tool)
        
        comfort_placement(for: tool)
        place_object_entity(object: tool)
    }
    
    /**
     Deletes tool from workspace.
     
     - Parameters:
        - index: An index of tool to be deleted.
     */
    public func delete_tool(index: Int)
    {
        if tools.indices.contains(index)
        {
            tools.remove(at: index)
            
            if let selected_program = selected_program { elements_check(program: selected_program) }
        }
    }
    
    /**
     Deletes tool from workspace.
     
     - Parameters:
        - name: A name of tool to be deleted.
     */
    public func delete_tool(name: String)
    {
        delete_tool(index: index_by_name(name, objects: tools))
    }
    
    /**
     Duplicates tool in the workspace.
     
     - Parameters:
        - index: An index of tool to be duplicated.
     */
    public func duplicate_tool(index: Int)
    {
        if tools.indices.contains(index)
        {
            let new_name = mismatched_name(name: tools[index].name, names: tools_names)
            let new_index = tools.count
            
            tools.append(Tool())
            
            //tools[new_index] = clone_codable(tools[index]) ?? Tool() // Tool(tool_struct: tools[index].file_info)
            tools[new_index].name = new_name
            tools[new_index].is_placed = false
        }
    }
    
    /**
     Duplicates tool in the workspace.
     
     - Parameters:
        - name: A name of tool to be duplicated.
     */
    public func duplicate_tool(name: String)
    {
        duplicate_tool(index: index_by_name(name, objects: tools))
    }

    // MARK: Tools selection functions
    /**
     Selects tool by name.
     
     - Parameters:
        - name: A name of tool to be selected.
     */
    public func select_tool(name: String) // Select tool by name
    {
        selected_object = tools[index_by_name(name, objects: tools)]
    }
    
    /**
     Returns tool by name.
     
     - Parameters:
        - name: A name of tobot for index find.
     */
    public func tool_by_name(_ name: String) -> Tool
    {
        let index = index_by_name(name, objects: tools)
        if tools.indices.contains(index)
        {
            return self.tools[index]
        }
        else
        {
            return Tool()
        }
        
        // return self.tools[tool_index_by_name(name)]
    }
    
    /// Names of all tools in the workspace.
    public var tools_names: [String] // Get names of all tools in the workspace
    {
        var names = [String]()
        if tools.count > 0
        {
            for tool in tools
            {
                names.append(tool.name)
            }
        }
        return names
    }
    
    /// Names of tools avaliable to place in the workspace.
    public var avaliable_tools_names: [String]
    {
        var names = [String]()
        for tool in tools
        {
            if !tool.is_placed
            {
                names.append(tool.name)
            }
        }
        return names
    }
    
    /// Names of tools placed in the workspace.
    public var placed_tools_names: [String] { tools.compactMap { $0.is_placed ? $0.name : nil } }
    
    // MARK: Tool attachment functions
    public func update_tool_attachments()
    {
        if !(tools.count > 0) { return }
        
        for tool in tools
        {
            if let attached_to = tool.attached_to
            {
                let end_point_entity = robot_by_name(attached_to).end_point_entity
                
                end_point_entity.addChild(tool.entity)
            }
            else
            {
                workspace_entity.addChild(tool.entity)
            }
        }
        
        /*for tool in tools
        {
            if let attached_to = tool.attached_to
            {
                let end_point_entity = robot_by_name(attached_to).end_point_entity
                tool.entity.position = end_point_entity.position(relativeTo: nil) // World position of robot end point
            }
            else
            {
                tool.entity.position = workspace_entity.position(relativeTo: nil) // World position of workspace origin
            }
        }*/
        
        /*func sum_rotations(_ entity: Entity, _ entity2: Entity)
        {
            entity.eulerAngles.x += entity2.eulerAngles.x
            entity.eulerAngles.y += entity2.eulerAngles.y
            entity.eulerAngles.z += entity2.eulerAngles.z
        }
        
        func sum_angles(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float>
        {
            @inline(__always)
            func normalize(_ angle: Float) -> Float
            {
                var x = fmodf(angle + Float.pi, 2 * Float.pi)
                if x < 0 { x += 2 * Float.pi }
                return x - Float.pi
            }

            let s = a + b
            return SIMD3<Float>(
                normalize(s.x),
                normalize(s.y),
                normalize(s.z)
            )
        }*/
    }
    
    /// Attaches tool to robot by reparenting it under robot's tool node.
    public func attach_tool_to(robot_name: String)
    {
        //update_pointer()
        
        /*if let edited_node = edited_object_node,
           let robot_tool_node = robot_by_name(robot_name).tool_node
        {
            attach(node: edited_node, to: robot_tool_node)
            selected_tool.attached_to = robot_name
        }*/
    }

    /// Moves the node to be child of the end_point_node, preserving its world transform.
    /*private func attach(node: SCNNode, to new_parent: SCNNode)
    {
        let local_transform = node.transform
        
        new_parent.addChildNode(node)
        
        node.transform = local_transform
    }*/
    
    /*/// Removes the node from its parent and re-adds to scene root, preserving world transform.
    public func remove_attachment()
    {
        guard let node = edited_object_node, let scene_root_node = tools_node else { return }
        
        let local_transform = node.transform
        scene_root_node.addChildNode(node)
        node.transform = local_transform
        
        node.simdTransform = node.simdTransform
        
        selected_tool.attached_to = nil
    }*/

    /**
     Detaches the given node from its current parent and re-adds it to the specified root node,
     preserving its local transform and ensuring correct visual update.
     
     - Parameters:
        - node: The node to be detached and moved.
        - root_node: The node that will become the new parent (typically the scene root).
     */
    /*public func remove_attachment(from node: SCNNode, to root_node: SCNNode)
    {
        let local_transform = node.transform
        root_node.addChildNode(node)
        node.transform = local_transform
        
        node.simdTransform = node.simdTransform
    }*/
    
    /**
     Detaches the specified tool from its current parent node and restores it to the scene root,
     preserving its local transform and resetting its attachment state.
     
     - Parameters:
        - tool: The tool to be detached and reinserted into the scene root.
        - node_only: If `true`, only the tool's node is detached without modifying its attachment state.
     */
    public func remove_attachment(tool: Tool, node_only: Bool = false)
    {
        if tool.attached_to != nil
        {
            /*guard let tool_node = tool.node, let scene_root_node = tools_node else { return }
            
            remove_attachment(from: tool_node, to: scene_root_node)
            
            if !node_only
            {
                tool.attached_to = nil
            }*/
        }
    }
    
    /// Detaches the currently edited node and restores it to the tools root node.
    public func remove_edited_node_attachment()
    {
        //guard let edited_object_node = edited_object_node, let tools_node = tools_node else { return }
        //remove_attachment(from: edited_object_node, to: tools_node)
    }
    
    /**
     Detaches all tool nodes from their current parents and re-adds them to the scene root.
     Optionally preserves the tools' attachment state.
     
     - Parameters:
        -  nodes_only: If `true`, only the nodes are moved without resetting the attachment information.
     */
    public func remove_all_tools_attachments(nodes_only: Bool = false)
    {
        for tool in tools
        {
            remove_attachment(tool: tool, node_only: nodes_only)
        }
    }
    
    // MARK: - Parts handling functions
    // MARK: Parts manage funcions
    /// Adds part in the workspace.
    public func add_part(_ part: Part)
    {
        part.name = mismatched_name(name: part.name, names: parts_names)
        part.is_placed = true
        parts.append(part)
        
        comfort_placement(for: part)
        place_object_entity(object: part)
    }
    
    /**
     Deletes part from workspace.
     
     - Parameters:
        - index: An index of part to be deleted.
     */
    public func delete_part(index: Int)
    {
        if parts.indices.contains(index)
        {
            parts.remove(at: index)
        }
    }
    
    /**
     Deletes part from workspace.
     
     - Parameters:
        - name: A name of part to be deleted.
     */
    public func delete_part(name: String)
    {
        delete_part(index: index_by_name(name, objects: parts))
    }
    
    /**
     Duplicates part in the workspace.
     
     - Parameters:
        - index: An index of part to be duplicated.
     */
    public func duplicate_part(index: Int)
    {
        if parts.indices.contains(index)
        {
            let new_name = mismatched_name(name: parts[index].name, names: parts_names)
            let new_index = parts.count

            parts.append(Part())

            //parts[new_index] = clone_codable(parts[index]) ?? Part() // Part(part_struct: parts[index].file_info)
            parts[new_index].name = new_name
            parts[new_index].is_placed = false
        }
    }
    
    /**
     Duplicates part in the workspace.
     
     - Parameters:
        - name: A name of part to be duplicated.
     */
    public func duplicate_part(name: String)
    {
        duplicate_part(index: index_by_name(name, objects: parts))
    }
    
    // MARK: Parts selection functions
    /**
     Selects part by name.
     
     - Parameters:
        - name: A name of part to be selected.
     */
    public func select_part(name: String)
    {
        selected_object = parts[index_by_name(name, objects: parts)]
    }
    
    /**
     Returns part by name.
     
     - Parameters:
        - name: A name of tobot for index find.
     */
    public func part_by_name(_ name: String) -> Part
    {
        let index = index_by_name(name, objects: parts)
        if parts.indices.contains(index)
        {
            return self.parts[index]
        }
        else
        {
            return Part()
        }
    }
    
    /// Names of all parts in the workspace.
    public var parts_names: [String]
    {
        var parts_names = [String]()
        if parts.count > 0
        {
            for part in parts
            {
                parts_names.append(part.name)
            }
        }
        return parts_names
    }
    
    /// Names of parts avaliable to place in the workspace.
    public var avaliable_parts_names: [String]
    {
        var names = [String]()
        for part in parts
        {
            if !part.is_placed
            {
                names.append(part.name)
            }
        }
        return names
    }
    
    /// Names of parts placed in the workspace.
    public var placed_parts_names: [String] { parts.compactMap { $0.is_placed ? $0.name : nil } }
    
    // MARK: - Work with file system
    /**
     Returns arrays of document structures by workspace objects type.
     
     - Returns: Codable structures for robots, tools, parts and elements ordered as control program.
     */
    public func file_data()
    -> (
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
        
        // Workspace production programs
        /*let programs_file_info: [ProductionProgram] = programs.map
        {
            $0.file_data()
        }*/
        
        return (
            robots: robots_file_info,
            tools: tools_file_info,
            parts: parts_file_info,
            
            programs: programs,
            registers: registers
        )
    }
    
    /**
     Imports file data to workspace from preset structure.
     
     - Parameters:
        - preset: Imported workspace preset.
     */
    public func file_view(preset: WorkspacePreset)
    {
        // MARK: - Robots
        robots.removeAll()
        
        for robot_file in preset.robots
        {
            let robot = Robot(file: robot_file)
            robots.append(robot)
        }
        
        // MARK: - Tools
        tools.removeAll()
        
        for tool_file in preset.tools
        {
            let tool = Tool(file: tool_file)
            tools.append(tool)
        }
        
        // MARK: - Parts
        parts.removeAll()
        
        for part_file in preset.parts
        {
            let part = Part(file: part_file)
            parts.append(part)
        }
        
        // MARK: - Workspace production programs
        programs.removeAll()
        
        for program in preset.programs
        {
            programs.append(program)
        }
        
        // MARK: - Registers
        registers = preset.registers ?? [Float](repeating: 0, count: Workspace.default_registers_count)
    }
}

public enum WorkspaceObjectType: String, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
    case part = "Part"
}

//MARK: - Structures for workspace preset document handling
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

// MARK: - Math element functions
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


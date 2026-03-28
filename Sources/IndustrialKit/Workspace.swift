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
    public init()
    {
        current_element = RobotPerformerElement()//MarkLogicElement(name: "")
        
        registers = [Float](repeating: 0, count: Workspace.default_registers_count)
    }
    
    // MARK: Workspace objects data
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
    
    /**
     Selects a workspace object by type (Robot, Tool, or Part), updates the current selection, and focuses the camera on it.
     
     - Parameters:
        - object: An object to select.
     */
    public func select_object(_ object: WorkspaceObject)
    {
        deselect_object() // Test
        pointer_entity.isEnabled = false
        
        deselect_program()
        
        switch object
        {
        case is Robot:
            select_robot(name: object.name)
            pointer_entity.isEnabled = true
        case is Tool:
            select_tool(name: object.name)
            pointer_entity.isEnabled = true
        case is Part:
            select_part(name: object.name)
            pointer_entity.isEnabled = true
        default:
            break
        }
        
        // Camera pivot reposition
        if let selected_object = selected_object
        {
            focus(on: selected_object.entity)
        }
        
        self.objectWillChange.send() // UI only
    }
    
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
            deselect_program()
        }
        
        selected_object = nil
    }
    
    public func delete_object(_ object: WorkspaceObject)
    {
        focus(on: nil)
        
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
        program.name = unique_name(for: program.name, in: programs_names)
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
    public func select_program(index: Int)
    {
        selected_program_index = index
        
        if let selected_program = selected_program // Elements check on program selection
        {
            elements_check(program: selected_program)
        }
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
    
    public func single_operation_reset()
    {
        if is_single_performed
        {
            is_single_performed = false
            performing_state = previous_performing_state
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
                if placed_robot_names.count > 0
                {
                    element.object_name = placed_robot_names.first ?? ""
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
                if placed_tool_names.count > 0
                {
                    element.object_name = placed_tool_names.first ?? ""
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
                registers = updated_registers(registers, reference_count)
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
            
            robot.stop_output_updating()
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
        }
    }
    
    /// Selects and performs program element by workspace.
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
        
        program_performed = false // Control Buttons (UI)
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
    
    /// Resets workspace performing.
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
            
            robot.stop_output_updating()
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
        }
    }
    
    // MARK: Registers handling
    /// A default count of data registers for workspace.
    nonisolated(unsafe) public static var default_registers_count = 256
    
    /// An array of data registers of workspace.
    @Published public var registers: [Float]
    
    /// Registers count control.
    public var registers_count: Int
    {
        get { registers.count }
        set
        {
            registers = updated_registers(registers, newValue > 1 ? newValue : 1)
        }
    }
    
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
            // Robot program perform
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
                tool.select_program(name: element.program_name)
            }
            else
            {
                tool.select_program(index: Int(registers[safe: element.program_index] ?? 0))
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
        var info_output = [String]()
        
        switch element.object_type
        {
        case .robot:
            if let device_output = robot_by_name(element.object_name).device_output
            {
                info_output = items_to_array(from: device_output.items)
            }
            else
            {
                error_handler(NSError(domain: "No output items", code: 0, userInfo: nil))
            }
        case .tool:
            if let device_output = tool_by_name(element.object_name).device_output
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
    }
    
    /// Prepare workspace program to perform.
    private func prepare_program(_ program: ProductionProgram)
    {
        program.defining_elements_indexes()
    }
    
    // MARK: - Visual Functions
    #if canImport(RealityKit)
    private var workspace_entity = Entity()
    private var scene_content: RealityViewCameraContent?
    
    public func place_entity(to content: RealityViewCameraContent, completion: @escaping () -> () = {})
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
        
        load_all_modules_entities
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
    
    // MARK: Entities from modules
    private func load_all_modules_entities(_ completion: @escaping () -> Void = {})
    {
        load_all_internal_modules_entities
        {
            load_all_external_modules_entities
            {
                completion()
            }
        }
        
        func load_all_internal_modules_entities(_ completion: @escaping () -> Void = {})
        {
            Robot.load_all_internal_modules_entities
            {
                Tool.load_all_internal_modules_entities
                {
                    Part.load_all_internal_modules_entities
                    {
                        print("Internal loaded")
                        completion()
                    }
                }
            }
        }
        
        func load_all_external_modules_entities(_ completion: @escaping () -> Void = {})
        {
            Robot.load_all_external_modules_entities
            {
                Tool.load_all_external_modules_entities
                {
                    Part.load_all_external_modules_entities
                    {
                        print("External loaded")
                        completion()
                    }
                }
            }
        }
    }
    
    // MARK: Camera
    private var workspace_anchor = AnchorEntity(world: .zero)
    
    private var workspace_camera: PerspectiveCamera?
    private var workspace_camera_target = Entity()
    
    private var camera_target_offset: SIMD3<Float> = .zero
    private var camera_target_initialized = false
    
    private var base_camera_distance: Float?
    private var is_focusing = false
    
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
    
    private weak var target_tile: ModelEntity?
    
    /// Focus camera to pivot
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
    
    private func capture_initial_camera_target_offset()
    {
        guard let camera = workspace_camera else { return }

        let camera_pos = camera.position(relativeTo: nil)
        let target_pos = workspace_camera_target.position(relativeTo: nil)

        camera_target_offset = target_pos - camera_pos
        camera_target_initialized = true
    }
    
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
        
        func update_target_tile_scale(_ camera_position: SIMD3<Float>, _ target_position: SIMD3<Float>)
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
    
    private let minor_line_mesh_x = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.002)
    private let major_line_mesh_x = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.0025)
    private let axis_line_mesh_x  = MeshResource.generatePlane(width: Float(200*2) * 0.1, depth: 0.00375)
    
    private let minor_line_mesh_z = MeshResource.generatePlane(width: 0.002, depth: Float(200*2) * 0.1)
    private let major_line_mesh_z = MeshResource.generatePlane(width: 0.0025, depth: Float(200*2) * 0.1)
    private let axis_line_mesh_z  = MeshResource.generatePlane(width: 0.00375, depth: Float(200*2) * 0.1)
    
    /*public var is_grid_visible: Bool { grid_visible } // UI Only
    
    public func toggle_grid_visiblity()
    {
        grid_visible.toggle()
        grid_lines.values.forEach { $0.isEnabled = grid_visible }
        
        self.objectWillChange.send() // UI Only
    }*/
    
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
    #endif
    
    // MARK: Workspace Objects Placement
    public func place_object_entity(object: WorkspaceObject)
    {
        object.entity.update_position(object.position)
        workspace_anchor.addChild(object.entity)
    }
    
    public func remove_object_entity(object: WorkspaceObject)
    {
        object.entity.removeFromParent()
    }
    
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
    public func process_tap(value: EntityTargetValue<TapGesture.Value>)
    {
        var entity: Entity? = value.entity
        
        while let current = entity
        {
            print(current.name)
            if let object_identifier = current.components[ObjectEntityIdentifier.self]
            {
                print("📍 Name: \(object_identifier.name), Type: \(object_identifier.type, default: "No")")
                
                if object_identifier.type == .robot
                {
                    if let tool_entity = find_tool(in: current)
                    {
                        if let tool_id = tool_entity.components[ObjectEntityIdentifier.self]
                        {
                            if !already_selecting_same_object(tool_id)
                            {
                                select_object_by_entity_identifier(tool_id)
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
                    select_object_by_entity_identifier(object_identifier)
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
    
    public func process_empty_tap()
    {
        deselect_object()
        pointer_entity.removeFromParent()
        
        // Camera pivot reposition
        focus(on: nil)
        
        self.objectWillChange.send() // UI only
    }
    
    private var pointer_entity = Entity()
    
    private func select_object_by_entity_identifier(_ entity_identifier: ObjectEntityIdentifier)
    {
        deselect_object() // Test
        pointer_entity.isEnabled = false
        
        deselect_program()
        
        switch entity_identifier.type
        {
        case .robot:
            select_robot(name: entity_identifier.name)
            pointer_entity.isEnabled = true
        case .tool:
            select_tool(name: entity_identifier.name)
            pointer_entity.isEnabled = true
        case .part:
            select_part(name: entity_identifier.name)
            pointer_entity.isEnabled = true
        case .none:
            break
        }
        
        // Camera pivot reposition
        if let selected_object = selected_object
        {
            focus(on: selected_object.entity)
        }
        
        self.objectWillChange.send() // UI only
    }
    
    // MARK: Pointer Entity
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
            cone.eulerAngles = rotations[i]
            
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
    private func comfort_placement(for object: WorkspaceObject)
    {
        let object_rect = rect(of: object)

        // Occupied rectangles
        var occupied: [(center: SIMD2<Float>, half: SIMD2<Float>)] = []
        
        for group in [robots as [WorkspaceObject], tools, parts]
        {
            for item in group
            {
                guard item !== object, item.model_entity != nil else { continue }
                
                if let tool = item as? Tool, tool.attached_to != nil { continue }
                
                occupied.append(rect(of: item))
            }
        }
        
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
    /// Adds robot in the workspace.
    public func add_robot(_ robot: Robot)
    {
        robot.name = unique_name(for: robot.name, in: robot_names)
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
            robots[index].entity.removeFromParent()
            
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
            let new_name = unique_name(for: robots[index].name, in: robot_names)
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
    public var robot_names: [String] { robots.map { $0.name } }
    
    /// Names of robots placed in the workspace.
    public var placed_robot_names: [String] { robots.compactMap { $0.is_placed ? $0.name : nil } }
    
    /// Names of placed robots that support attachments.
    public var attachment_supporting_robot_names: [String] { robots.compactMap { $0.is_placed && !$0.end_entity_name.isEmpty ? $0.name : nil } }
    
    /// Stops any external connector programs running on the robots.
    public func stop_robot_external_connectors()
    {
        robots.compactMap { $0.connector as? any ExternalConnector }
            .forEach { $0.stop_program_component() }
    }
    
    // MARK: - Tools handling functions
    // MARK: Tools manage funcions
    /// Adds tool in the workspace.
    public func add_tool(_ tool: Tool)
    {
        tool.name = unique_name(for: tool.name, in: tool_names)
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
            tools[index].entity.removeFromParent()
            
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
            let new_name = unique_name(for: tools[index].name, in: tool_names)
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
    public var tool_names: [String] { tools.map { $0.name } }
    
    /// Names of tools placed in the workspace.
    public var placed_tool_names: [String] { tools.compactMap { $0.is_placed ? $0.name : nil } }
    
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
                tool.set_local_position()
            }
            else
            {
                workspace_entity.addChild(tool.entity)
                tool.set_global_position()
            }
        }
    }
    
    /// Stops any external connector programs running on the tools.
    public func stop_tool_external_connectors()
    {
        tools.compactMap { $0.connector as? any ExternalConnector }
            .forEach { $0.stop_program_component() }
    }
    
    // MARK: - Parts handling functions
    // MARK: Parts manage funcions
    /// Adds part in the workspace.
    public func add_part(_ part: Part)
    {
        part.name = unique_name(for: part.name, in: part_names)
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
            parts[index].entity.removeFromParent()
            
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
            let new_name = unique_name(for: parts[index].name, in: part_names)
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
    public var part_names: [String] { parts.map { $0.name } }
    
    /// Names of parts placed in the workspace.
    public var placed_part_names: [String] { parts.compactMap { $0.is_placed ? $0.name : nil } }
    
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
        
        // MARK: Registers
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

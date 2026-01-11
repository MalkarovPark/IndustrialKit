//
//  Robot.swift
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
 An industrial robot class.
 
 Permorms reposition operation by target points order in selected positions program.
 */
public class Robot: WorkspaceObject
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
    public override init(name: String, entity_name: String)
    {
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Inits robot by name, entity name, controller and connector .
    public init(name: String, entity_name: String, model_controller: RobotModelController = RobotModelController(), connector: RobotConnector = RobotConnector())
    {
        super.init(name: name, entity_name: entity_name)
        
        self.model_controller = model_controller
        self.connector = connector
        
        apply_statistics_flags()
    }
    
    /// Inits robot by name and part module.
    public init(name: String, module: RobotModule)
    {
        super.init(name: name)
        module_import(module)
    }
    
    public override init(name: String, module_name: String, is_internal: Bool)
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
        update_position()
    }
    
    // MARK: - Module handling
    /**
     Sets modular components to object instance.
     - Parameters:
        - module: A robot module.
     
     Set the following components:
     - Scene Node
     - Robot Model Controller
     - Robot Connector
     */
    public func module_import(_ module: RobotModule)
    {
        module_name = module.name
        
        //node = module.node.clone()
        
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
        
        // model_controller = module.model_controller.copy() as! RobotModelController
        // connector = module.connector.copy() as! RobotConnector
        
        apply_statistics_flags()
        
        origin_shift = module.origin_shift
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
    
    private func apply_statistics_flags()
    {
        model_controller.get_statistics = get_statistics
        connector.get_statistics = get_statistics
    }
    
    // MARK: - Program manage functions
    /// An array of robot positions programs.
    @Published public var programs = [PositionsProgram]()
    
    /// A selected positions program index.
    public var selected_program_index = 0
    {
        willSet
        {
            // Stop robot moving before program change
            performed = false
            target_point_index = 0
        }
        didSet
        {
            if selected_program_index != -1
            {
                update_points_model()
            }
        }
    }
    
    /**
     Adds new positions program to robot.
     - Parameters:
        - program: A new robot positions program.
     */
    public func add_program(_ program: PositionsProgram)
    {
        program.name = mismatched_name(name: program.name, names: programs_names)
        programs.append(program)
        /*if selected_program_index != -1
        {
            selected_program.visual_clear()
        }*/
    }
    
    /**
     Updates positions program in robot by index.
     - Parameters:
        - index: Updated program index.
        - program: A new robot positions program.
     */
    public func update_program(index: Int, _ program: PositionsProgram) // Update program by index
    {
        if programs.indices.contains(index) // Checking for the presence of a position program with a given number to update
        {
            programs[index] = program
            //selected_program.visual_clear()
        }
    }
    
    /**
     Updates positions program by name.
     - Parameters:
        - name: Updated program name.
        - program: A new robot positions program.
     */
    public func update_program(name: String, _ program: PositionsProgram)
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
    
    /// A selected positions program.
    public var selected_program: PositionsProgram
    {
        get // Return positions program by selected index
        {
            if programs.count > 0 && selected_program_index < programs.count
            {
                if selected_program_index < programs_count
                {
                    return programs[selected_program_index]
                }
                else
                {
                    return programs[selected_program_index - 1]
                }
                // return programs[selected_program_index]
            }
            else
            {
                return PositionsProgram()
            }
        }
        set
        {
            programs[selected_program_index] = newValue
        }
    }
    
    /// Returns index by program name.
    private func index_by_name(name: String) -> Int
    {
        return programs.firstIndex(of: PositionsProgram(name: name)) ?? -1
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
    nonisolated(unsafe) public var performed = false
    
    /// An Index of target point in points array.
    public var target_point_index = 0
    
    /// A target position in position points array.
    public var selected_position_point: PositionPoint
    {
        get
        {
            return selected_program.points[safe: target_point_index] ?? PositionPoint()
        }
        set
        {
            selected_program.points[safe: target_point_index] = newValue
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
            update_position()
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
        
        update()
    }
    
    /// Returns information about default pointer position avalibility of robot.
    public var has_default_position: Bool
    {
        return default_pointer_position != nil
    }
    
    /**
     Demo state of robot.
     
     If did set *true* – class instance try to connects a real robot by connector.
     If did set *false* – class instance disconnects from a real robot.
     */
    public var demo = true
    {
        didSet
        {
            if demo && connector.connected
            {
                reset_moving()
                disconnect()
            }
            else if !demo && update_model_by_connector
            {
                connector.model_controller = model_controller
            }
            
            model_controller.toggle_alt_pointer(demo)
        }
    }
    
    /// Returns robot pointer position for nodes.
    /*private func get_pointer_position() -> (location: SCNVector3, rot_x: Float, rot_y: Float, rot_z: Float)
    {
        return(SCNVector3(pointer_position.y, pointer_position.z, pointer_position.x), pointer_position.r.to_rad, pointer_position.p.to_rad, pointer_position.w.to_rad)
    }*/
    
    // MARK: Update functions
    /// Updates robot statistics and model by current pointer position.
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
     Performs movement on robot by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the robot.
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping @Sendable (Result<Void, Error>) -> Void = { _ in })
    {
        // pointer_position_to_robot()
        performed = true
        
        if demo
        {
            pointer_position_to_robot()
            model_controller.move_to(point: point)
            { result in
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
        else
        {
            pointer_position_to_robot()
            connector.move_to(point: point)
            { result in
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
    
    /// A robot moving performation toggle.
    public func start_pause_moving()
    {
        guard selected_program.points_count > 0
        else
        {
            finish_handler()
            return
        }
        
        // Robot moving handling
        if !performed
        {
            reset_error()
            paused = false // State light
            
            if !demo // Pass workcell parameters to model controller
            {
                sync_connector_parameters()
            }
            
            // Move to next point if moving was stop
            performed = false //???
            move_to_next_point()
        }
        else
        {
            // Remove all action if moving was perform
            pointer_position_to_robot()
            performed = false
            pause_handler()
        }
        
        func pause_handler()
        {
            selected_program.points[target_point_index].performing_state = .current
            
            paused = true // State light
            
            if demo
            {
                model_controller.canceled = true
                model_controller.reset_entities()
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
                    if self.demo
                    {
                        self.selected_position_point.performing_state = .completed
                    }
                    else if self.connector.connected
                    {
                        self.selected_position_point.performing_state = self.connector.performing_state.output
                    }
                    
                    self.select_new_point()
                case .failure(let error):
                    self.process_error(error)
                    self.error_handler(error)
                }
            }
        }
        /*move_to(point: selected_position_point) //(point: programs[selected_program_index].points[target_point_index])
        { result in
            switch result
            {
            case .success:
                if self.demo
                {
                    self.selected_position_point.performing_state = .completed
                }
                else if self.connector.connected
                {
                    self.selected_position_point.performing_state = self.connector.performing_state.output
                }
                
                self.select_new_point()
            case .failure(let error):
                self.process_error(error)
                self.error_handler(error)
            }
        }*/
    }
    
    /**
     Processes an error that occurred during the operation performing.
     - Parameters:
        - error: A robot moving error.
     */
    /*@Sendable*/ func process_error(_ error: Error)
    {
        performed = false // Pause performing
        
        last_error = error
        
        selected_position_point.performing_state = .error
        
        if demo
        {
            //model_controller.remove_all_model_actions()
            model_controller.reset_entities()
        }
        else
        {
            // Remove actions for real tool
            connector.canceled = true
            connector.reset_device()
        }
    }
    
    /// Set the new target point index.
    private func select_new_point()
    {
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
            
            finished = true // State light
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
            {
                self.finished = false // State light
                
                self.selected_program.reset_points_states()
            }
            
            update()
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
        if performed
        {
            if demo
            {
                model_controller.canceled = true
                model_controller.reset_entities()
            }
            else
            {
                connector.canceled = true
                connector.reset_device()
            }
            
            pointer_position_to_robot()
            performed = false
            
            clear_chart_data()
        }
        
        target_point_index = 0
        selected_program.reset_points_states()
        
        reset_error()
    }
    
    /// Pass pointer position from model controller or connector to robot.
    internal func pointer_position_to_robot()
    {
        if demo
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
    
    // MARK: - Connection functions
    /// A robot connector.
    public var connector = RobotConnector()
    
    private func sync_connector_parameters()
    {
        connector.origin_position = origin_position
        connector.space_scale = space_scale
    }
    
    /// Disconnects from real robot.
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
        return EntityModelIdentifier(type: .robot, name: name)
    }
    
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
        let rot_pos_x = simd_quatf(angle: .pi/2, axis: [0,1,0])
        box.addChild(make_wall(width: scale.x, height: scale.y, color: red, pos: pos_x, rot: rot_pos_x))
        
        // XY wall 2 (red)
        let neg_x = SIMD3<Float>(hy, scale.z, hx)
        let rot_neg_x = simd_mul(simd_quatf(angle: .pi/2, axis: [0,1,0]), simd_quatf(angle: .pi, axis: [1,0,0]))
        box.addChild(make_wall(width: scale.x, height: scale.y, color: red, pos: neg_x, rot: rot_neg_x))
        
        // XZ wall (blue)
        let pos_z = SIMD3<Float>(0, hz, hx)
        let rot_pos_z = simd_mul(simd_quatf(angle: .pi/2, axis: [1,0,0]), simd_quatf(angle: -.pi/2, axis: [0,0,1]))
        box.addChild(make_wall(width: scale.x, height: scale.z, color: blue, pos: pos_z, rot: rot_pos_z))
        
        // XZ wall 2 (blue)
        let neg_z = SIMD3<Float>(scale.y, hz, hx)
        let rot_neg_z = simd_mul(simd_quatf(angle: .pi/2, axis: [1,0,0]), simd_quatf(angle: .pi/2, axis: [0,0,1]))
        box.addChild(make_wall(width: scale.x, height: scale.z, color: blue, pos: neg_z, rot: rot_neg_z))
        
        // YZ wall (green)
        let pos_y = SIMD3<Float>(hy, hz, 0)
        let rot_pos_y = simd_quatf(angle: .pi/2, axis: [1,0,0])
        box.addChild(make_wall(width: scale.y, height: scale.z, color: green, pos: pos_y, rot: rot_pos_y))
        
        // YZ wall 2 (green)
        let neg_y = SIMD3<Float>(hy, hz, scale.x)
        let rot_neg_y = simd_quatf(angle: -.pi/2, axis: [1,0,0])
        box.addChild(make_wall(width: scale.y, height: scale.z, color: green, pos: neg_y, rot: rot_neg_y))
        
        return box
    }
    
    // MARK: Position Pointer Entity
    private var position_pointer_entity = Entity()
    
    @MainActor public func toggle_position_pointer_visibility()
    {
        position_pointer_entity.isEnabled.toggle()
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
    
    @MainActor public func update_position_program_entity(by program: PositionsProgram, edited_point: Int? = nil)
    {
        let is_enabled = position_program_entity.isEnabled
        
        position_program_entity.removeFromParent()
        position_program_entity = program.entity(edited_point)
        position_program_entity.isEnabled = is_enabled
        
        origin_entity.addChild(position_program_entity)
    }
    
    #endif
    
    /// A robot visual model controller.
    public var model_controller = RobotModelController()
    {
        didSet // Entities reconnection if model contoller changed
        {
            if let entity = entity
            {
                model_controller.connect_entities(of: entity)
            }
        }
    }
    
    private func sync_model_controller_parameters()
    {
        model_controller.origin_position = origin_position
        model_controller.space_scale = space_scale
    }
    
    /**
     Updates robot visual model by model controller in connector.
     
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
    
    /// Sets robot pointer node position.
    private func update_position()
    {
        if !performed
        {
            if demo
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
    
    /// Old
    
    /// An option of view current position program model.
    nonisolated(unsafe) public static var view_current_program_model = true
    
    private func update_points_model() // Update selected positions program model for robot
    {
        /*if Robot.view_current_program_model
        {
            points_node?.remove_all_child_nodes()
            selected_program.visual_build()
            points_node?.addChildNode(selected_program.positions_group)
        }*/
    }
    
    /// Old
    
    // MARK: - Chart functions
    /// A robot charts data.
    @Published public var charts_data: [WorkspaceObjectChart]?
    
    /// A robot state data.
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
    
    /// Updates statisitcs data by model controller (if demo is *true*) or connector (if demo is *false*).
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
    
    /// Clears robot chart data.
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
    }
    
    /// Clears robot state data.
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
     Returns info for robot card view.
     
     Color sets by the manufacturer name.
     */
    /*public override var card_info: (title: String, subtitle: String, color: Color, image: UIImage, SCNNode: SCNNode) // Get info for robot card view
    {
        return("\(self.name)", "\(self.module_name)", .green, UIImage(), SCNNode())
    }*/
    
    /// Connects robot charts to UI.
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
    
    /// Connects robot charts to UI.
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
    }
    
    /// Performing state light.
    public var performing_state: PerformingState
    {
        if !performed
        {
            if last_error == nil
            {
                if finished
                {
                    return PerformingState.completed
                }
                else if paused
                {
                    return PerformingState.current
                }
                else
                {
                    return PerformingState.none
                }
            }
            else
            {
                return PerformingState.error
            }
        }
        else
        {
            return PerformingState.processing
        }
    }
    
    /// A finished state of tool.
    private var finished = false
    
    /// A paused state of tool.
    private var paused = false
    
    // MARK: - Work with file system
    enum CodingKeys: String, CodingKey
    {
        case origin_location
        case origin_rotation
        case space_scale
        
        case default_pointer_location
        case default_pointer_rotation
        
        case demo
        case connection_parameters
        case update_model_by_connector
        
        case get_statistics
        case charts_data
        case states_data
        
        case programs
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let location = try container.decode([Float].self, forKey: .origin_location)
        let rotation = try container.decode([Float].self, forKey: .origin_rotation)
        self.origin_position = (location[0], location[1], location[2], rotation[0], rotation[1], rotation[2])
        let space_scale = try container.decode([Float].self, forKey: .space_scale)
        self.space_scale = (space_scale[0], space_scale[1], space_scale[2])
        
        if let pointer_location = try container.decodeIfPresent([Float].self, forKey: .default_pointer_location), let pointer_rotation = try container.decodeIfPresent([Float].self, forKey: .default_pointer_rotation)
        {
            self.default_pointer_position = (pointer_location[0], pointer_location[1], pointer_location[2], pointer_rotation[0], pointer_rotation[1], pointer_rotation[2])
        }
        
        self.demo = try container.decode(Bool.self, forKey: .demo)
        self.update_model_by_connector = try container.decode(Bool.self, forKey: .update_model_by_connector)
        
        self.get_statistics = try container.decode(Bool.self, forKey: .get_statistics)
        self.charts_data = try container.decodeIfPresent([WorkspaceObjectChart].self, forKey: .charts_data)
        self.states_data = try container.decodeIfPresent([StateItem].self, forKey: .states_data)
        
        self.programs = try container.decode([PositionsProgram].self, forKey: .programs)
        
        try super.init(from: decoder)
        
        self.connector.import_connection_parameters_values(try container.decodeIfPresent([String].self, forKey: .connection_parameters))
        if self.update_model_by_connector
        {
            self.connector.model_controller = self.model_controller
        }
        
        self.reset_pointer_to_default()
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode([origin_position.x, origin_position.y, origin_position.z], forKey: .origin_location)
        try container.encode([origin_position.r, origin_position.p, origin_position.w], forKey: .origin_rotation)
        try container.encode([space_scale.x, space_scale.y, space_scale.z], forKey: .space_scale)

        if let pointer = default_pointer_position
        {
            try container.encode([pointer.x, pointer.y, pointer.z], forKey: .default_pointer_location)
            try container.encode([pointer.r, pointer.p, pointer.w], forKey: .default_pointer_rotation)
        }
        
        try container.encode(demo, forKey: .demo)
        try container.encode(connector.connection_parameters_values, forKey: .connection_parameters)
        try container.encode(update_model_by_connector, forKey: .update_model_by_connector)
        
        try container.encode(get_statistics, forKey: .get_statistics)
        try container.encode(charts_data, forKey: .charts_data)
        try container.encode(states_data, forKey: .states_data)
        
        try container.encode(programs, forKey: .programs)
        
        try super.encode(to: encoder)
    }
}

//
//  Robot.swift
//  IndustrialKit
//
//  Created by Artem on 05.12.2021.
//

import Foundation

//import SceneKit
import RealityKit
import SwiftUI

/**
 An industrial robot class.
 
 Permorms reposition operation by target points order in selected positions program.
 */
public class Robot: WorkspaceObject, @unchecked Sendable
{
    // MARK: - Init functions
    /// Inits robot with default parameters.
    public override init()
    {
        working_area_entity = Entity()
        
        super.init()
        set_default_cell_parameters()
    }
    
    /// Inits robot by name.
    public override init(name: String)
    {
        working_area_entity = Entity()
        
        super.init(name: name)
        set_default_cell_parameters()
    }
    
    public override init(name: String, entity_name: String)
    {
        working_area_entity = Entity()
        
        super.init(name: name, entity_name: entity_name)
    }
    
    /// Inits robot by name, controller, connector and SceneKit scene.
    /*public init(name: String, model_controller: RobotModelController, connector: RobotConnector, scene: SCNScene)
    {
        super.init(name: name)
        
        self.node = scene.rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
        
        self.model_controller = model_controller
        self.connector = connector
        
        apply_statistics_flags()
        set_default_cell_parameters()
    }*/
    
    /// Inits robot by name, controller, connector and SceneKit scene name.
    public init(name: String, model_controller: RobotModelController, connector: RobotConnector, scene_name: String)
    {
        working_area_entity = Entity()
        
        super.init(name: name)
        
        //self.node = (SCNScene(named: scene_name) ?? SCNScene()).rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
        
        self.model_controller = model_controller
        self.connector = connector
        
        apply_statistics_flags()
        set_default_cell_parameters()
    }
    
    /// Inits robot by name and part module.
    public init(name: String, module: RobotModule)
    {
        working_area_entity = Entity()
        
        super.init(name: name)
        module_import(module)
        
        set_default_cell_parameters()
    }
    
    public override init(name: String, module_name: String, is_internal: Bool)
    {
        working_area_entity = Entity()
        
        super.init(name: name, module_name: module_name, is_internal: is_internal)
        
        set_default_cell_parameters()
    }
    
    private func set_default_cell_parameters()
    {
        self.origin_position = Robot.default_origin_position
        self.space_scale = Robot.default_space_scale
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
        if selected_program_index != -1
        {
            selected_program.visual_clear()
        }
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
            selected_program.visual_clear()
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
            selected_program.visual_clear()
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
    /// A drawing path flag.
    public var draw_path = false
    
    /// A moving state of robot.
    public var performed = false
    
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
                model_controller.reset_nodes()
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
        
        move_to(point: selected_position_point) //(point: programs[selected_program_index].points[target_point_index])
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
        }
    }
    
    /**
     Processes an error that occurred during the operation performing.
     - Parameters:
        - error: A robot moving error.
     */
    @Sendable func process_error(_ error: Error)
    {
        performed = false // Pause performing
        
        last_error = error
        
        selected_position_point.performing_state = .error
        
        if demo
        {
            //model_controller.remove_all_model_actions()
            model_controller.reset_nodes()
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
                model_controller.reset_nodes()
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
    override public var entity_tag: Component
    {
        return EntityModelIdentifier(type: .robot, name: name)
    }
    
    override open func extend_entity_preparation(_ entity: Entity)
    {
        // Place robot accesories
        working_area_entity = build_working_area_entity(scale: space_scale)
        working_area_entity.update_position(origin_position)
        working_area_entity.isEnabled = false
        entity.addChild(working_area_entity)
    }
    
    private var working_area_entity: Entity //private var working_area_entity = Entity()
    
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
        
        entity?.addChild(working_area_entity)
    }
    
    @MainActor public func update_working_area_position()
    {
        working_area_entity.update_position(origin_position)
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
    #endif
    
    /// Old
    public override var scene_node_name: String { "robot" }
    
    /// A robot visual model controller.
    public var model_controller = RobotModelController()
    
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
                connector.model_controller?.reset_nodes()
                connector.model_controller = nil
            }
        }
    }
    
    // Robot workcell unit nodes references
    /*/// Robot unit node with manipulator node.
    public var unit_node: SCNNode?
    
    /// Box bordered cell workspace.
    public var box_node: SCNNode?
    
    /// Camera.
    public var camera_node: SCNNode?
    
    /// Robot teach pointer.
    public var pointer_node: SCNNode?
    
    /// Node for internal element.
    public var pointer_node_internal: SCNNode?
    
    /// Teach points.
    public var points_node: SCNNode?
    
    /// Current robot.
    public var robot_node: SCNNode?
    
    /// Robot space.
    public var space_node:SCNNode?
    
    /// Node for tool attachment.
    public var tool_node: SCNNode?*/
    
    /**
     Connects to robot model in scene.
     - Parameters:
        - scene: A current scene.
        - name: A robot name.
        - connect_camera: Place camera to robot's camera node.
     
     > The scene should contain nodes named: box, space, pointer, internal, points.
     */
    /*public func workcell_connect(scene: SCNScene, name: String, connect_camera: Bool)
    {
        // Find nodes from scene by names or add them
        if let node = scene.rootNode.childNode(withName: name, recursively: true)
        {
            self.unit_node = node
        }
        else
        {
            self.unit_node = SCNNode()
            self.unit_node?.name = name
            scene.rootNode.addChildNode(self.unit_node!)
        }

        if let node = self.unit_node?.childNode(withName: "space", recursively: true)
        {
            self.space_node = node
        }
        else
        {
            self.space_node = SCNNode()
            self.space_node?.name = "space"
            self.unit_node?.addChildNode(self.space_node!)
        }
        
        if let node = self.space_node?.childNode(withName: "box", recursively: true)
        {
            self.box_node = node
        }
        else
        {
            self.box_node = SCNNode()
            self.box_node?.name = "box"
            self.space_node?.addChildNode(self.box_node!)
        }

        if let node = self.space_node?.childNode(withName: "pointer", recursively: true)
        {
            self.pointer_node = node
        }
        else
        {
            self.pointer_node = SCNNode()
            self.pointer_node?.name = "pointer"
            self.space_node?.addChildNode(self.pointer_node!)
        }

        if let node = self.pointer_node?.childNode(withName: "internal", recursively: true)
        {
            self.pointer_node_internal = node
        }
        else
        {
            self.pointer_node_internal = SCNNode()
            self.pointer_node_internal?.name = "internal"
            self.pointer_node?.addChildNode(self.pointer_node_internal!)
        }

        if let node = self.space_node?.childNode(withName: "points", recursively: true)
        {
            self.points_node = node
        }
        else
        {
            self.points_node = SCNNode()
            self.points_node?.name = "points"
            self.space_node?.addChildNode(self.points_node!)
        }

        // Connect robot parts
        self.tool_node = node?.childNode(withName: "tool", recursively: true)
        self.unit_node?.addChildNode(node ?? SCNNode())
        model_controller.disconnect_nodes()
        model_controller.nodes_connect(node ?? SCNNode(), pointer: self.pointer_node ?? SCNNode(), pointer_internal: self.pointer_node_internal ?? SCNNode())
        
        // Connect robot camera
        if connect_camera
        {
            if let node = scene.rootNode.childNode(withName: "camera", recursively: true)
            {
                self.camera_node = node
            }
            else
            {
                self.camera_node = SCNNode()
                self.camera_node?.name = "camera"
                scene.rootNode.addChildNode(self.camera_node!)
            }
        }
        
        // Place and scale cell box
        robot_location_place()
        update_space_scale() // Set space scale by connected robot parameters
        
        update_position()
        
        update_points_model()
    }*/
    
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
    nonisolated(unsafe) public static var default_origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    /// A default scale of robot cell box.
    nonisolated(unsafe) public static var default_space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    
    /**
     A robot cell origin position.
     
     Tuple with coordinates – *x*, *y*, *z* and angles – *r*, *p*, *w*.
     */
    public var origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    {
        didSet
        {
            robot_location_place()
            update_position()
        }
    }
    
    /// A robot cell box scale.
    public var space_scale: (x: Float, y: Float, z: Float) = (x: 200, y: 200, z: 200)
    {
        didSet
        {
            update_space_scale()
        }
    }
    
    /// A robot cell box default shift.
    public var origin_shift: (x: Float, y: Float, z: Float) = (x: 0, y: 0, z: 0)
    {
        didSet
        {
            robot_location_place()
        }
    }
    
    /// A modified node reference.
    //private var modified_node = SCNNode()
    
    /// A saved SCNMateral for edited node.
    //private var saved_material = SCNMaterial()
    
    /// Places cell workspace relative to manipulator.
    public func robot_location_place()
    {
        /*sync_model_controller_parameters()
        
        // MARK: Place workcell box
        #if os(macOS)
        space_node?.position.x = CGFloat(origin_position.y + origin_shift.y)
        space_node?.position.y = CGFloat(origin_position.z + origin_shift.z)
        space_node?.position.z = CGFloat(origin_position.x + origin_shift.x)
        
        space_node?.eulerAngles.x = CGFloat(origin_position.p.to_rad)
        space_node?.eulerAngles.y = CGFloat(origin_position.w.to_rad)
        space_node?.eulerAngles.z = CGFloat(origin_position.r.to_rad)
        #else
        space_node?.position.x = Float(origin_position.y) + origin_shift.y
        space_node?.position.y = Float(origin_position.z) + origin_shift.z
        space_node?.position.z = Float(origin_position.x) + origin_shift.x
        
        space_node?.eulerAngles.x = origin_position.p.to_rad
        space_node?.eulerAngles.y = origin_position.w.to_rad
        space_node?.eulerAngles.z = origin_position.r.to_rad
        #endif
        
        // MARK: Place camera
        #if os(macOS)
        camera_node?.position.x += CGFloat(origin_position.y)
        camera_node?.position.y += CGFloat(origin_position.z)
        camera_node?.position.z += CGFloat(origin_position.x)
        #else
        camera_node?.position.x += Float(origin_position.y)
        camera_node?.position.y += Float(origin_position.z)
        camera_node?.position.z += Float(origin_position.x)
        #endif*/
    }
    
    /// Updates cell box model scale.
    public func update_space_scale()
    {
        /*guard box_node?.childNodes.count ?? 0 > 0
        else
        {
            return
        }
        
        // XY planes
        modified_node = box_node?.childNode(withName: "w0", recursively: true) ?? SCNNode()
        saved_material = (modified_node.geometry?.firstMaterial) ?? SCNMaterial()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale.y), height: CGFloat(space_scale.x))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = -CGFloat(space_scale.z) / 2
        #else
        modified_node.position.y = -space_scale.z / 2
        #endif
        modified_node = box_node?.childNode(withName: "w1", recursively: true) ?? SCNNode()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale.y), height: CGFloat(space_scale.x))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = CGFloat(space_scale.z) / 2
        #else
        modified_node.position.y = space_scale.z / 2
        #endif
        
        // YZ plane
        modified_node = box_node?.childNode(withName: "w2", recursively: true) ?? SCNNode()
        saved_material = (modified_node.geometry?.firstMaterial) ?? SCNMaterial()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale.y), height: CGFloat(space_scale.z))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = -CGFloat(space_scale.x) / 2
        #else
        modified_node.position.z = -space_scale.x / 2
        #endif
        modified_node = box_node?.childNode(withName: "w3", recursively: true) ?? SCNNode()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale.y), height: CGFloat(space_scale.z))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = CGFloat(space_scale.x) / 2
        #else
        modified_node.position.z = space_scale.x / 2
        #endif
        
        // XZ plane
        modified_node = box_node?.childNode(withName: "w4", recursively: true) ?? SCNNode()
        saved_material = (modified_node.geometry?.firstMaterial) ?? SCNMaterial()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale.x), height: CGFloat(space_scale.z))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = -CGFloat(space_scale.y) / 2
        #else
        modified_node.position.x = -space_scale.y / 2
        #endif
        modified_node = box_node?.childNode(withName: "w5", recursively: true) ?? SCNNode()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale.x), height: CGFloat(space_scale.z))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = CGFloat(space_scale.y) / 2
        #else
        modified_node.position.x = space_scale.y / 2
        #endif
        
        #if os(macOS)
        box_node?.position = SCNVector3(x: CGFloat(space_scale.y) / 2, y: CGFloat(space_scale.z) / 2, z: CGFloat(space_scale.x) / 2)
        #else
        box_node?.position = SCNVector3(x: space_scale.y / 2, y: space_scale.z / 2, z: space_scale.x / 2)
        #endif
        
        model_controller.space_scale = space_scale
        position_points_shift()*/
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
                    
                    program.visual_build()
                }
            }
        }
    }
    
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
        
        working_area_entity = Entity()
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

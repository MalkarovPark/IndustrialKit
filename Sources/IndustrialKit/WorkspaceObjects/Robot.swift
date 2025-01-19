//
//  Robot.swift
//  IndustrialKit
//
//  Created by Artem on 05.12.2021.
//

import Foundation
import SceneKit
import SwiftUI

/**
 An industrial robot class.
 
 Permorms reposition operation by target points order in selected positions program.
 */
public class Robot: WorkspaceObject
{
    //MARK: - Init functions
    ///Inits robot with default parameters.
    public override init()
    {
        super.init()
        set_default_cell_parameters()
    }
    
    ///Inits robot by name.
    public override init(name: String)
    {
        super.init(name: name)
        set_default_cell_parameters()
    }
    
    ///Inits robot by name, controller, connector and SceneKit scene.
    public init(name: String, model_controller: RobotModelController, connector: RobotConnector, scene: SCNScene)
    {
        super.init(name: name)
        
        self.node = scene.rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
        
        self.model_controller = model_controller
        self.connector = connector
        
        apply_statistics_flags()
        set_default_cell_parameters()
    }
    
    ///Inits robot by name, controller, connector and SceneKit scene name.
    public init(name: String, model_controller: RobotModelController, connector: RobotConnector, scene_name: String)
    {
        super.init(name: name)
        
        self.node = (SCNScene(named: scene_name) ?? SCNScene()).rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
        
        self.model_controller = model_controller
        self.connector = connector
        
        apply_statistics_flags()
        set_default_cell_parameters()
    }
    
    ///Inits part by name and part module.
    public init(name: String, module: RobotModule)
    {
        super.init(name: name)
        module_import(module)
        
        set_default_cell_parameters()
    }
    
    public override init(name: String, module_name: String, is_internal: Bool)
    {
        super.init(name: name, module_name: module_name, is_internal: is_internal)
        
        set_default_cell_parameters()
    }
    
    private func set_default_cell_parameters()
    {
        self.origin_location = [Robot.default_origin_location[0], Robot.default_origin_location[1], Robot.default_origin_location[2]]
        self.space_scale = [Robot.default_space_scale[0], Robot.default_space_scale[1], Robot.default_space_scale[2]]
    }
    
    //MARK: - Module handling
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
        
        node = module.node.clone()
        
        model_controller = module.model_controller
        connector = module.connector
        
        apply_statistics_flags()
    }
    
    ///Imported internal robot modules.
    public static var internal_modules = [RobotModule]()
    
    ///Imported external robot modules.
    public static var external_modules = [RobotModule]()
    
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
    
    private func apply_statistics_flags()
    {
        model_controller.get_statistics = get_statistics
        connector.get_statistics = get_statistics
    }
    
    //MARK: - Program manage functions
    ///An array of robot positions programs.
    @Published public var programs = [PositionsProgram]()
    
    ///A selected positions program index.
    public var selected_program_index = 0
    {
        willSet
        {
            //Stop robot moving before program change
            performed = false
            moving_completed = false
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
    public func update_program(index: Int, _ program: PositionsProgram) //Update program by index
    {
        if programs.indices.contains(index) //Checking for the presence of a position program with a given number to update
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
        if programs.indices.contains(index) //Checking for the presence of a position program with a given number to delete
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
    
    ///A selected positions program.
    public var selected_program: PositionsProgram
    {
        get //Return positions program by selected index
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
                //return programs[selected_program_index]
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
    
    ///Returns index by program name.
    private func index_by_name(name: String) -> Int
    {
        return programs.firstIndex(of: PositionsProgram(name: name)) ?? -1
    }
    
    ///All positions programs names in robot.
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
    
    ///A positions programs coount in robot.
    public var programs_count: Int
    {
        return programs.count
    }
    
    //MARK: - Moving functions
    ///A drawing path flag.
    public var draw_path = false
    
    ///A moving state of robot.
    public var performed = false
    
    /**
     A path moving completion state.
     
     This flag set if the robot has passed all positions.
     
     > Used for indication in GUI.
     */
    public var moving_completed = false
    
    ///An Index of target point in points array.
    public var target_point_index = 0
    
    ///A default location of robot cell origin.
    public static var default_origin_location = [Float](repeating: 0, count: 3)
    
    ///A default scale of robot cell box.
    public static var default_space_scale = [Float](repeating: 200, count: 3)
    
    /**
     A robot pointer location.
     
     Array with three coordinates – [*x*, *y*, *z*].
     */
    public var pointer_location: [Float] = [0.0, 0.0, 0.0]
    {
        didSet
        {
            update_location()
        }
    }
    
    /**
     A robot pointer rotation.
     
     Array with three angles – [*r*, *p*, *w*].
     */
    public var pointer_rotation: [Float] = [0.0, 0.0, 0.0]
    {
        didSet
        {
            update_rotation()
        }
    }
    
    ///A robot default pointer location.
    private var default_pointer_location: [Float]?
    
    ///A robot default pointer rotatioin.
    private var default_pointer_rotation: [Float]?
    
    ///Sets default robot pointer position by current pointer position.
    public func set_default_pointer_position()
    {
        default_pointer_location = pointer_location
        default_pointer_rotation = pointer_rotation
    }
    
    ///Clears default robot pointer position.
    public func clear_default_pointer_position()
    {
        default_pointer_location = nil
        default_pointer_rotation = nil
    }
    
    ///Resets robot pointer to default position.
    public func reset_pointer_to_default()
    {
        guard let location = default_pointer_location, let rotation = default_pointer_rotation
        else
        {
            return
        }
        
        pointer_location = location
        pointer_rotation = rotation
        
        update()
    }
    
    ///Returns information about default pointer position avalibility of robot.
    public var has_default_position: Bool
    {
        if default_pointer_location != nil && default_pointer_rotation != nil
        {
            return true
        }
        else
        {
            return false
        }
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
        }
    }
    
    ///Returns robot pointer position for nodes.
    private func get_pointer_position() -> (location: SCNVector3, rot_x: Float, rot_y: Float, rot_z: Float)
    {
        return(SCNVector3(pointer_location[1], pointer_location[2], pointer_location[0]), pointer_rotation[0].to_rad, pointer_rotation[1].to_rad, pointer_rotation[2].to_rad)
    }
    
    ///A flag that prevents concurrent execution of the update function.
    private var updated = true
    
    /**
     Updates robot statistics and model by current pointer position.
     
     > Has the public protection level for provide external synchronization. A common practice is to it put in a *render* func of **SceneKit** Scene.
     */
    public func update()
    {
        if updated
        {
            updated = false
            
            update_statistics_data()
            
            //Modeling
            if demo
            {
                model_controller.update_by_pointer()
            }
            else if update_model_by_connector
            {
                connector.sync_model()
            }
            
            updated = true
        }
    }
    
    //MARK: Performation cycle
    /**
     Performs movement on robot by target position with completion handler.
     
     - Parameters:
        - point: The target position performed by the robot.
        - completion: A completion function that is calls when the performing completes.
     */
    public func move_to(point: PositionPoint, completion: @escaping () -> Void)
    {
        //pointer_position_to_robot()
        performed = true
        
        if demo
        {
            //Move to point for virtual robot
            pointer_position_to_robot()
            model_controller.update_movement_time(point1: point,
                                                  point2: PositionPoint(x: pointer_location[0],
                                                                        y: pointer_location[1],
                                                                        z: pointer_location[2],
                                                                        r: pointer_rotation[0],
                                                                        p: pointer_rotation[1],
                                                                        w: pointer_rotation[2]))
            model_controller.nodes_move_to(point: point)
            {
                completion()
                //self.performed = false
            }
        }
        else
        {
            if connector.connected
            {
                //Move to point for real robot
                connector.move_to(point: point)
                {
                    completion()
                    self.performed = false
                }
            }
            else
            {
                completion()
                self.performed = false
            }
        }
    }
    
    ///A robot moving performation toggle.
    public func start_pause_moving()
    {
        guard selected_program.points_count > 0
        else
        {
            finish_handler()
            return
        }
        
        //Handling robot moving
        if !performed
        {
            if !demo //Pass workcell parameters to model controller
            {
                sync_connector_parameters()
            }
            
            //Move to next point if moving was stop
            //performed = true
            move_to_next_point()
        }
        else
        {
            //Remove all action if moving was perform
            pointer_position_to_robot()
            performed = false
            pause_handler()
        }
        
        func pause_handler()
        {
            if demo
            {
                model_controller.reset_nodes()
            }
            else
            {
                //Remove actions for real robot
                connector.canceled = true
                connector.reset_device()
            }
        }
    }
    
    ///Performs robot to selected point movement and select next.
    public func move_to_next_point()
    {
        move_to(point: programs[selected_program_index].points[target_point_index])
        {
            self.select_new_point()
        }
    }
    
    ///Set the new target point index.
    private func select_new_point()
    {
        if target_point_index < selected_program.points_count - 1
        {
            //Select and move to next point
            target_point_index += 1
            move_to_next_point()
        }
        else
        {
            //Reset target point index if all points passed
            target_point_index = 0
            performed = false
            moving_completed = true
            
            update()
            pointer_position_to_robot()
            
            finish_handler()
        }
    }
    
    ///Finish handler for to point moving.
    public var finish_handler: (() -> Void) = {}
    
    ///Clears finish handler.
    public func clear_finish_handler()
    {
        finish_handler = {}
    }
    
    ///Resets robot moving.
    public func reset_moving()
    {
        if performed
        {
            if demo
            {
                model_controller.reset_nodes()
            }
            else
            {
                connector.canceled = true
                connector.reset_device()
            }
            
            pointer_position_to_robot()
            performed = false
            target_point_index = 0
            
            clear_chart_data()
        }
    }
    
    ///Pass pointer position from model controller or connector to robot.
    internal func pointer_position_to_robot()
    {
        if demo
        {
            pointer_location = model_controller.pointer_location
            pointer_rotation = model_controller.pointer_rotation
        }
        else
        {
            pointer_location = connector.pointer_location
            pointer_rotation = connector.pointer_rotation
        }
    }
    
    //MARK: - Connection functions
    ///A robot connector.
    public var connector = RobotConnector()
    
    private func sync_connector_parameters()
    {
        connector.origin_location = origin_location
        connector.origin_rotation = origin_rotation
        
        connector.space_scale = space_scale
    }
    
    ///Disconnects from real robot.
    private func disconnect()
    {
        //connector.update_model = false
        connector.model_controller = nil
        connector.disconnect()
    }
    
    //MARK: - Visual build functions
    public override var scene_node_name: String { "robot" }
    
    ///A robot visual model controller.
    public var model_controller = RobotModelController()
    
    private func sync_model_controller_parameters()
    {
        model_controller.origin_location = origin_location
        model_controller.origin_rotation = origin_rotation
        
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
    
    //Robot workcell unit nodes references
    ///Robot unit node with manipulator node.
    public var unit_node: SCNNode?
    
    ///Box bordered cell workspace.
    public var box_node: SCNNode?
    
    ///Camera.
    public var camera_node: SCNNode?
    
    ///Robot teach pointer.
    public var pointer_node: SCNNode?
    
    ///Node for internal element.
    public var pointer_node_internal: SCNNode?
    
    ///Teach points.
    public var points_node: SCNNode?
    
    ///Current robot.
    public var robot_node: SCNNode?
    
    ///Robot space.
    public var space_node:SCNNode?
    
    ///Node for tool attachment.
    public var tool_node: SCNNode?
    
    /**
     Connects to robot model in scene.
     - Parameters:
        - scene: A current scene.
        - name: A robot name.
        - connect_camera: Place camera to robot's camera node.
     
     > The scene should contain nodes named: box, space, pointer, internal, points.
     */
    public func workcell_connect(scene: SCNScene, name: String, connect_camera: Bool)
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
        
        //Place and scale cell box
        robot_location_place()
        update_space_scale() //Set space scale by connected robot parameters
        
        //Pass workcell parameters to model controller
        //model_controller.origin_location = origin_location
        //model_controller.origin_rotation = origin_rotation
        model_controller.space_scale = space_scale
        
        update_location()
        update_rotation()
        
        update_points_model()
        //model_controller.update_robot() //Updates robot model by target position. Update robot parts position on robot connection.
        
        //Pass model controller to connector
        /*if update_model_by_connector
        {
            connector.model_controller = model_controller
        }*/
    }
    
    ///Sets robot pointer node location.
    private func update_location()
    {
        if !performed
        {
            model_controller.pointer_location = pointer_location
        }
    }
    
    ///Sets robot pointer node rotation.
    private func update_rotation()
    {
        if !performed
        {
            model_controller.pointer_rotation = pointer_rotation
        }
    }
    
    //MARK: Cell box handling
    /**
     A robot cell origin location.
     
     Array with three coordinates – [*x*, *y*, *z*].
     */
    public var origin_location = [Float](repeating: 0, count: 3)
    {
        didSet
        {
            robot_location_place()
            update_location()
        }
    }
    
    /**
     A robot cell origin rotation.
     
     Array with three angles – [*r*, *p*, *w*].
     */
    public var origin_rotation = [Float](repeating: 0, count: 3)
    {
        didSet
        {
            robot_location_place()
            update_rotation()
        }
    }
    
    ///A robot cell box scale.
    public var space_scale = [Float](repeating: 200, count: 3)
    
    ///A modified node reference.
    private var modified_node = SCNNode()
    
    ///A saved SCNMateral for edited node.
    private var saved_material = SCNMaterial()
    
    ///Places cell workspace relative to manipulator.
    public func robot_location_place()
    {
        sync_model_controller_parameters()
        
        let vertical_length = model_controller.nodes["base"]?.position.y
        
        //MARK: Place workcell box
        #if os(macOS)
        space_node?.position.x = CGFloat(origin_location[1])
        space_node?.position.y = CGFloat(origin_location[2]) + (vertical_length ?? 0) //Add vertical base length
        space_node?.position.z = CGFloat(origin_location[0])
        
        space_node?.eulerAngles.x = CGFloat(origin_rotation[1].to_rad)
        space_node?.eulerAngles.y = CGFloat(origin_rotation[2].to_rad)
        space_node?.eulerAngles.z = CGFloat(origin_rotation[0].to_rad)
        #else
        space_node?.position.x = Float(origin_location[1])
        space_node?.position.y = Float(origin_location[2] + (vertical_length ?? 0))
        space_node?.position.z = Float(origin_location[0])
        
        space_node?.eulerAngles.x = origin_rotation[1].to_rad
        space_node?.eulerAngles.y = origin_rotation[2].to_rad
        space_node?.eulerAngles.z = origin_rotation[0].to_rad
        #endif
        
        //MARK: Place camera
        #if os(macOS)
        camera_node?.position.x += CGFloat(origin_location[1])
        camera_node?.position.y += CGFloat(origin_location[2]) + (vertical_length ?? 0)
        camera_node?.position.z += CGFloat(origin_location[0])
        #else
        camera_node?.position.x += Float(origin_location[1])
        camera_node?.position.y += Float(origin_location[2] + (vertical_length ?? 0))
        camera_node?.position.z += Float(origin_location[0])
        #endif
    }
    
    ///Updates cell box model scale.
    public func update_space_scale()
    {
        guard box_node?.childNodes.count ?? 0 > 0
        else
        {
            return
        }
        
        //XY planes
        modified_node = box_node?.childNode(withName: "w0", recursively: true) ?? SCNNode()
        saved_material = (modified_node.geometry?.firstMaterial) ?? SCNMaterial()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]), height: CGFloat(space_scale[0]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = -CGFloat(space_scale[2]) / 2
        #else
        modified_node.position.y = -space_scale[2] / 2
        #endif
        modified_node = box_node?.childNode(withName: "w1", recursively: true) ?? SCNNode()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]), height: CGFloat(space_scale[0]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = CGFloat(space_scale[2]) / 2
        #else
        modified_node.position.y = space_scale[2] / 2
        #endif
        
        //YZ plane
        modified_node = box_node?.childNode(withName: "w2", recursively: true) ?? SCNNode()
        saved_material = (modified_node.geometry?.firstMaterial) ?? SCNMaterial()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]), height: CGFloat(space_scale[2]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = -CGFloat(space_scale[0]) / 2
        #else
        modified_node.position.z = -space_scale[0] / 2
        #endif
        modified_node = box_node?.childNode(withName: "w3", recursively: true) ?? SCNNode()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]), height: CGFloat(space_scale[2]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = CGFloat(space_scale[0]) / 2
        #else
        modified_node.position.z = space_scale[0] / 2
        #endif
        
        //XZ plane
        modified_node = box_node?.childNode(withName: "w4", recursively: true) ?? SCNNode()
        saved_material = (modified_node.geometry?.firstMaterial) ?? SCNMaterial()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[0]), height: CGFloat(space_scale[2]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = -CGFloat(space_scale[1]) / 2
        #else
        modified_node.position.x = -space_scale[1] / 2
        #endif
        modified_node = box_node?.childNode(withName: "w5", recursively: true) ?? SCNNode()
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[0]), height: CGFloat(space_scale[2]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = CGFloat(space_scale[1]) / 2
        #else
        modified_node.position.x = space_scale[1] / 2
        #endif
        
        #if os(macOS)
        box_node?.position = SCNVector3(x: CGFloat(space_scale[1]) / 2, y: CGFloat(space_scale[2]) / 2, z: CGFloat(space_scale[0]) / 2)
        #else
        box_node?.position = SCNVector3(x: space_scale[1] / 2, y: space_scale[2] / 2, z: space_scale[0] / 2)
        #endif
        
        position_points_shift()
    }
    
    /**
     Shifts positions when reducing the robot workcell area.
     
     - Parameters:
        - point: The position to which the shifting is applied.
     */
    public func point_shift(_ point: inout PositionPoint)
    {
        if point.x > Float(space_scale[0])
        {
            point.x = Float(space_scale[0])
        }
        else if point.x < 0
        {
            point.x = 0
        }
        
        if point.y > Float(space_scale[1])
        {
            point.y = Float(space_scale[1])
        }
        else if point.y < 0
        {
            point.y = 0
        }
        
        if point.z > Float(space_scale[2])
        {
            point.z = Float(space_scale[2])
        }
        else if point.z < 0
        {
            point.z = 0
        }
    }
    
    private func position_points_shift() //Shifts all positions
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
    
    ///An option of view current position program model.
    public static var view_current_program_model = true
    
    private func update_points_model() //Update selected positions program model for robot
    {
        if Robot.view_current_program_model
        {
            points_node?.remove_all_child_nodes()
            selected_program.visual_build()
            points_node?.addChildNode(selected_program.positions_group)
        }
    }
    
    //MARK: - Chart functions
    ///A robot charts data.
    @Published public var charts_data: [WorkspaceObjectChart]?
    
    ///A robot state data.
    @Published public var states_data: [StateItem]?
    
    ///A statistics getting toggle.
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
    
    ///Index of chart element.
    private var chart_element_index = 0
    
    ///Updates statisitcs data by model controller (if demo is *true*) or connector (if demo is *false*).
    public func update_statistics_data()
    {
        if charts_data == nil
        {
            charts_data = [WorkspaceObjectChart]()
        }
        
        if get_statistics && performed //Get data if robot is moving and statistic collection enabled
        {
            if demo //Get statistic from model controller
            {
                model_controller.update_statistics_data()
                states_data = model_controller.states_data
                charts_data = model_controller.charts_data
            }
            else //Get statistic from real robot
            {
                connector.update_statistics_data()
                states_data = connector.states_data
                charts_data = connector.charts_data
            }
        }
    }
    
    ///Clears robot chart data.
    public func clear_chart_data()
    {
        charts_data = nil
        
        if get_statistics
        {
            if demo
            {
                model_controller.reset_charts_data()
            }
            else
            {
                connector.reset_charts_data()
            }
        }
    }
    
    ///Clears robot state data.
    public func clear_states_data()
    {
        states_data = nil
        
        if get_statistics
        {
            if demo
            {
                model_controller.reset_states_data()
            }
            else
            {
                connector.reset_states_data()
            }
        }
    }
    
    //MARK: - UI functions
    /**
     Returns info for robot card view.
     
     Color sets by the manufacturer name.
     */
    public override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name)", "Model – \(self.module_name)", .green, self.image)
    }
    
    /**
     Returns point color for inspector view.
     
     Colors mean:
     - gray – if point not selected.
     - yellow – if target point not reached.
     - green – if target point reached.
     */
    public func inspector_point_color(point: PositionPoint) -> Color
    {
        var color = Color.gray //Gray point color if the robot is not reching the point
        let point_number = self.selected_program.points.firstIndex(of: point) //Number of selected point
        
        if performed
        {
            if point_number == target_point_index //Yellow color, if the robot is in the process of moving to the point
            {
                color = .yellow
            }
            else
            {
                if point_number ?? 0 < target_point_index //Green color, if the robot has reached this point
                {
                    color = .green
                }
            }
        }
        else
        {
            if moving_completed //Green color, if the robot has passed all points
            {
                color = .green
            }
        }
        
        return color
    }
    
    ///Connects robot charts to UI.
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
    
    ///Connects robot charts to UI.
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
    
    //MARK: - Work with file system
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
        
        self.origin_location = try container.decode([Float].self, forKey: .origin_location)
        self.origin_rotation = try container.decode([Float].self, forKey: .origin_rotation)
        self.space_scale = try container.decode([Float].self, forKey: .space_scale)
        
        self.default_pointer_location = try container.decodeIfPresent([Float].self, forKey: .default_pointer_location)
        self.default_pointer_rotation = try container.decodeIfPresent([Float].self, forKey: .default_pointer_rotation)
        
        self.demo = try container.decode(Bool.self, forKey: .demo)
        self.update_model_by_connector = try container.decode(Bool.self, forKey: .update_model_by_connector)
        
        self.get_statistics = try container.decode(Bool.self, forKey: .get_statistics)
        self.charts_data = try container.decodeIfPresent([WorkspaceObjectChart].self, forKey: .charts_data)
        self.states_data = try container.decodeIfPresent([StateItem].self, forKey: .states_data)
        
        self.programs = try container.decode([PositionsProgram].self, forKey: .programs)
        
        try super.init(from: decoder)
        
        self.connector.import_connection_parameters_values(try container.decodeIfPresent([String].self, forKey: .connection_parameters))
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(origin_location, forKey: .origin_location)
        try container.encode(origin_rotation, forKey: .origin_rotation)
        try container.encode(space_scale, forKey: .space_scale)
        
        try container.encode(default_pointer_location, forKey: .default_pointer_location)
        try container.encode(default_pointer_rotation, forKey: .default_pointer_rotation)
        
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

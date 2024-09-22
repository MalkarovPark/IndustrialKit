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
    }
    
    ///Inits robot by name.
    public override init(name: String)
    {
        super.init(name: name)
    }
    
    ///Inits robot by name, controller, connector and SceneKit scene name.
    public init(name: String, scene_name: String, model_controller: RobotModelController, connector: RobotConnector)
    {
        super.init(name: name)
        
        self.node = (SCNScene(named: scene_name) ?? SCNScene()).rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
        
        self.model_controller = model_controller
        self.connector = connector
        
        apply_statistics_flags()
    }
    
    ///Inits robot by name, controller, connector and SceneKit scene.
    public init(name: String, scene: SCNScene, model_controller: RobotModelController, connector: RobotConnector)
    {
        super.init(name: name)
        
        self.node = scene.rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
        
        self.model_controller = model_controller
        self.connector = connector
        
        apply_statistics_flags()
    }
    
    ///Inits part by name and part module.
    public init(name: String, module: RobotModule)
    {
        super.init(name: name)
        module_import(module)
    }
    
    public override init(name: String, module_name: String)
    {
        super.init(name: name, module_name: module_name)
    }
    
    //
    //
    
    ///Inits robot by codable robot structure.
    public init(robot_struct: RobotStruct)
    {
        super.init()
        robot_init(name: robot_struct.name,
                   module_name: robot_struct.module,
                   scene: robot_struct.scene,
                   is_placed: robot_struct.is_placed,
                   location: robot_struct.location,
                   rotation: robot_struct.rotation,
                   demo: robot_struct.demo,
                   update_model_by_connector: robot_struct.update_model_by_connector,
                   get_statistics: robot_struct.get_statistics,
                   charts_data: robot_struct.charts_data,
                   state: robot_struct.state, image_data: robot_struct.image_data,
                   origin_location: robot_struct.origin_location,
                   origin_rotation: robot_struct.origin_rotation,
                   space_scale: robot_struct.space_scale)
        
        read_default_position(robot_struct.default_pointer_position)
        
        read_programs(robot_struct: robot_struct)
        
        import_module_by_name(module_name)
        read_connection_parameters(connector: connector, robot_struct.connection_parameters)
        model_controller.charts_data = charts_data
    }
    
    public required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    ///Common init function.
    private func robot_init(name: String, module_name: String, scene: String, is_placed: Bool, location: [Float], rotation: [Float], demo: Bool, update_model_by_connector: Bool, get_statistics: Bool, charts_data: [WorkspaceObjectChart]?, state: [StateItem]?, image_data: Data, origin_location: [Float], origin_rotation: [Float], space_scale: [Float])
    {
        //Robot model names
        self.name = name
        
        //Robot position in workspace
        self.is_placed = is_placed
        self.location = location
        self.rotation = rotation
        
        //Demo info
        self.demo = demo
        self.update_model_by_connector = update_model_by_connector
        
        //Statistic value
        self.get_statistics = get_statistics
        self.charts_data = charts_data
        self.states_data = state
        
        self.image_data = image_data
        self.origin_location = origin_location
        self.origin_rotation = origin_rotation
        self.space_scale = space_scale
        
        //Robot controller and connector modules
        self.module_name = module_name
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
        node = module.node
        
        model_controller = module.model_controller
        connector = module.connector
        
        apply_statistics_flags()
    }
    
    ///Imported robot modules.
    public static var modules = [RobotModule]()
    
    override public func import_module_by_name(_ name: String)
    {
        guard let index = Robot.modules.firstIndex(where: { $0.name == name })
        else
        {
            return
        }
        
        module_import(Robot.modules[index])
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
    
    /**
     A robot default pointer position.
     
     Array with three angles – [*x*, *y*, *z*, *r*, *p*, *w*].
     */
    private var default_pointer_position: [Float]?
    
    ///Sets default robot pointer position by current pointer position.
    public func set_default_pointer_position()
    {
        default_pointer_position = [
        pointer_location[0],
        pointer_location[1],
        pointer_location[2],
        pointer_rotation[0],
        pointer_rotation[1],
        pointer_rotation[2]
        ]
    }
    
    ///Clears default robot pointer position.
    public func clear_default_pointer_position()
    {
        default_pointer_position = nil
    }
    
    ///Resets robot pointer to default position.
    public func reset_pointer_to_default()
    {
        guard let viewed_data = default_pointer_position
        else
        {
            return
        }
        
        pointer_location = [viewed_data[0], viewed_data[1], viewed_data[2]]
        pointer_rotation = [viewed_data[3], viewed_data[4], viewed_data[5]]
        
        update_model()
    }
    
    ///Returns information about default pointer position avalibility of robot.
    public var has_default_position: Bool
    {
        if default_pointer_position != nil
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
    
    /**
     Updates robot model by current pointer position.
     
     > Placed in the public protection level for normal synchronization in SceneKit.
     */
    public func update_model()
    {
        update_statistics_data()
        model_controller.update_by_pointer()
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
                }
            }
            else
            {
                completion()
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
                connector.origin_location = origin_location
                connector.origin_rotation = origin_rotation
                connector.space_scale = space_scale
            }
            
            //Move to next point if moving was stop
            performed = true
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
                connector.pause()
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
            
            update_model()
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
                connector.pause()
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
    
    ///Disconnects from real robot.
    private func disconnect()
    {
        //connector.update_model = false
        connector.model_controller = nil
        connector.disconnect()
    }
    
    //MARK: - Visual build functions
    public override var scene_node_name: String { "robot" }
    
    public override var scene_internal_folder_address: String { Robot.scene_folder }
    
    ///An internal scene folder address.
    public static var scene_folder = String()
    
    ///A robot visual model controller.
    public var model_controller = RobotModelController()
    
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
    
    public override func node_by_description()
    {
        node = SCNNode()
        
        if module_name != ""
        {
            //Get default models by modules names
            guard let new_scene = SCNScene(named: scene_internal_folder_address + (scene_internal_folder_address != "" ? "/" : "") + module_name + ".scn")
            else
            {
                node_by_description()
                return
            }
            
            node = new_scene.rootNode.childNode(withName: scene_node_name, recursively: false)!
            //node = SCNScene(named: scene_internal_folder_address + "/" + module_name + ".scn")!.rootNode.childNode(withName: scene_node_name, recursively: false)!
        }
        else
        {
            no_model_node()
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
    
    ///An array of robot parts lengths.
    private var lengths = [Float]()
    
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
        model_controller.transform_by_lengths(lengths)

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
        model_controller.origin_location = origin_location
        model_controller.origin_rotation = origin_rotation
        
        let vertical_length = model_controller.lengths.last
        
        //MARK: Place workcell box
        #if os(macOS)
        space_node?.position.x = CGFloat(origin_location[1])
        space_node?.position.y = CGFloat(origin_location[2] + (vertical_length ?? 0)) //Add vertical base length
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
        camera_node?.position.y += CGFloat(origin_location[2] + (vertical_length ?? 0))
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
    ///Converts robot data to codable robot struct.
    public var file_info: RobotStruct
    {
        return RobotStruct(name: name,
                           manufacturer: "Manufacturer",
                           model: "Model",
                           module: self.module_name,
                           scene: self.scene_address,
                           lengths: self.scene_address == "" ? self.lengths : [Float](),
                           is_placed: self.is_placed,
                           location: self.location,
                           rotation: self.rotation,
                           default_pointer_position: self.default_pointer_position,
                           demo: self.demo,
                           connection_parameters: get_connection_parameters(connector: self.connector),
                           update_model_by_connector: self.update_model_by_connector,
                           get_statistics: self.get_statistics,
                           charts_data: self.charts_data,
                           state: self.states_data,
                           image_data: self.image_data ?? Data(),
                           programs: self.programs,
                           origin_location: self.origin_location,
                           origin_rotation: self.origin_rotation,
                           space_scale: self.space_scale)
    }
    
    ///Gets default pointer position from array.
    private func read_default_position(_ data: [Float]?)
    {
        if data?.count == 6
        {
            default_pointer_position = data
            
            guard let viewed_data = data
            else
            {
                return
            }
            
            pointer_location = [viewed_data[0], viewed_data[1], viewed_data[2]]
            pointer_rotation = [viewed_data[3], viewed_data[4], viewed_data[5]]
        }
    }
    
    ///Convert array of codable positions programs structs to robot programs.
    private func read_programs(robot_struct: RobotStruct)
    {
        if robot_struct.programs.count > 0
        {
            for postions_program in robot_struct.programs
            {
                programs.append(postions_program)
            }
        }
    }
}

//MARK: - Robot structure for workspace preset document handling
///A codable robot struct.
public struct RobotStruct: Codable
{
    public var name: String
    public var manufacturer: String
    public var model: String
    
    public var module: String
    public var scene: String
    public var lengths: [Float]
    
    public var is_placed: Bool
    public var location: [Float]
    public var rotation: [Float]
    
    public var default_pointer_position: [Float]?
    
    public var demo: Bool
    public var connection_parameters: [String]?
    public var update_model_by_connector: Bool
    
    public var get_statistics: Bool
    public var charts_data: [WorkspaceObjectChart]?
    public var state: [StateItem]?
    
    public var image_data: Data
    public var programs: [PositionsProgram]
    
    public var origin_location: [Float]
    public var origin_rotation: [Float]
    public var space_scale: [Float]
}

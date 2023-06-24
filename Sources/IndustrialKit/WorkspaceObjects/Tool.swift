//
//  Tool.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 01.06.2022.
//

import Foundation
import SceneKit
import SwiftUI

/**
 An industrial tool class.
 
 Permorms operation by codes order in selected operations program.
 */
public class Tool: WorkspaceObject
{
    //MARK: - Init functions
    public override init()
    {
        super.init()
    }
    
    ///Inits tool by name.
    public override init(name: String)
    {
        super.init(name: name)
    }
    
    ///Inits tool by model dictionary.
    public init(name: String, dictionary: [String: Any])
    {
        super.init()
        
        if dictionary.keys.contains("Codes") //Import tool opcodes values from dictionary
        {
            let dict = dictionary["Codes"] as! [String : Int]
            
            self.codes = dict.map { $0.value }
            self.codes_names = dict.map { $0.key }
        }
        
        if dictionary.keys.contains("Module") //Select model visual controller an connector
        {
            self.module_name = dictionary["Module"] as? String ?? ""
            
            Tool.select_modules(module_name, &model_controller, &connector)
            
            if update_model_by_connector
            {
                connector.model_controller = model_controller
            }
            
            apply_statistics_flags()
        }
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it
        {
            self.scene_address = dictionary["Scene"] as? String ?? ""
            get_node_from_scene()
        }
        else
        {
            node_by_description()
        }
        
        if dictionary.keys.contains("Lengths") //Checking for the availability of lengths data property
        {
            let elements = dictionary["Lengths"] as! NSArray
            
            for element in elements //Add elements from NSArray to floats array
            {
                lengths.append((element as? Float) ?? 0)
            }
        }
    }
    
    ///Inits tool by codable tool structure.
    public init(tool_struct: ToolStruct)
    {
        super.init(name: tool_struct.name!)
        
        self.is_placed = tool_struct.is_placed
        self.location = tool_struct.location
        self.rotation = tool_struct.rotation
        
        self.is_attached = tool_struct.is_attached
        self.attached_to = tool_struct.attached_to
        
        self.demo = tool_struct.demo
        self.update_model_by_connector = tool_struct.update_model_by_connector
        
        self.get_statistics = tool_struct.get_statistics
        self.charts_data = tool_struct.charts_data
        self.state_data = tool_struct.state
        
        self.codes = tool_struct.codes
        self.codes_names = tool_struct.names
        
        self.scene_address = tool_struct.scene ?? ""
        self.programs = tool_struct.programs
        self.image_data = tool_struct.image_data
        
        if scene_address != ""
        {
            get_node_from_scene()
        }
        else
        {
            node_by_description()
        }
        
        self.module_name = tool_struct.module ?? ""
        if module_name != ""
        {
            Tool.select_modules(module_name, &model_controller, &connector)
            
            if update_model_by_connector
            {
                connector.model_controller = model_controller
            }
            
            apply_statistics_flags()
        }
        
        read_connection_parameters(connector: self.connector, tool_struct.connection_parameters)
    }
    
    /**
     Model connector and contoller selection function for tool.
    
     Code example.
     
            switch name
            {
            case "Connector Name":
                model_controller = ToolController()
                connector = ToolConnector()
            case "Connector Name 2":
                model_controller = ToolController2()
                connector = ToolConnector2()
            default:
                break
            }
     */
    public static var select_modules: ((_ name: String, _ model_controller: inout ToolModelController, _ connector: inout ToolConnector) -> Void) = { name,controller,connector in }
    
    private func apply_statistics_flags()
    {
        model_controller.get_statistics = get_statistics
        connector.get_statistics = get_statistics
    }
    
    //MARK: - Program manage functions
    ///An array of tool operations programs.
    @Published private var programs = [OperationsProgram]()
    
    ///A selected operations program index.
    public var selected_program_index = 0
    {
        willSet
        {
            //Stop tool performing before program change
            reset_performing()
        }
    }
    
    /**
     Adds new operations program to tool.
     - Parameters:
        - program: A new tool operations program.
     */
    public func add_program(_ program: OperationsProgram)
    {
        program.name = mismatched_name(name: program.name!, names: programs_names)
        programs.append(program)
    }
    
    /**
     Updates operations program in tool by index.
     - Parameters:
        - index: Updated program index.
        - program: A new tool operations program.
     */
    public func update_program(index: Int, _ program: OperationsProgram) //Update program by index
    {
        if programs.indices.contains(index) //Checking for the presence of a position program with a given number to update
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
    public func update_program(name: String, _ program: OperationsProgram) //Update program by name
    {
        update_program(index: index_by_name(name: name), program)
    }
    
    /**
     Deletes operations program in tool by index.
     - Parameters:
        - index: Deleted program index.
     */
    public func delete_program(index: Int) //Delete program by index
    {
        if programs.indices.contains(index) //Checking for the presence of a position program with a given number to delete
        {
            programs.remove(at: index)
        }
    }
    
    /**
     Deletes operations program in tool by name.
     - Parameters:
        - name: Deleted program name.
     */
    public func delete_program(name: String) //Delete program by name
    {
        delete_program(index: index_by_name(name: name))
    }
    
    /**
     Selects operations program in tool by index.
     - Parameters:
        - index: Selected program index.
     */
    public func select_program(index: Int) //Delete program by index
    {
        selected_program_index = index
    }
    
    /**
     Selects operations program in tool by name.
     - Parameters:
        - name: Selected program name.
     */
    public func select_program(name: String) //Select program by name
    {
        select_program(index: index_by_name(name: name))
    }
    
    ///A selected operations program.
    public var selected_program: OperationsProgram
    {
        get //Return positions program by selected index
        {
            if programs.count > 0
            {
                return programs[selected_program_index]
            }
            else
            {
                return OperationsProgram()
            }
        }
        set
        {
            programs[selected_program_index] = newValue
        }
    }
    
    ///Returns index by program name.
    private func index_by_name(name: String) -> Int //Get index of program by name
    {
        return programs.firstIndex(of: OperationsProgram(name: name)) ?? -1
    }
    
    ///All operations programs names in tool.
    public var programs_names: [String] //Get all names of programs in tool
    {
        var prog_names = [String]()
        if programs.count > 0
        {
            for program in programs
            {
                prog_names.append(program.name ?? "None")
            }
        }
        return prog_names
    }
    
    ///A operations programs coount in tool.
    public var programs_count: Int
    {
        return programs.count
    }
    
    //MARK: - Codes functions
    ///An array of avaliable operation codes values for tool.
    public var codes = [Int]()
    
    ///An avaliable codes count.
    public var codes_count: Int
    {
        return codes.count
    }
    
    ///An information output code.
    public var info_code: Int?
    {
        if demo
        {
            return model_controller.info_code
        }
        else
        {
            return connector.info_code
        }
    }
    
    //MARK: - Performing functions
    ///A name of tool module to describe model controller and connector.
    private var module_name = ""
    
    ///A moving state of tool.
    public var performed = false
    
    /**
     An operations completion state.
     
     This flag set if the tool has passed all operations.
     
     > Used for indication in GUI.
     */
    public var performing_completed = false
    
    ///An Index of target code in operation codes array.
    public var selected_code_index = 0
    
    /**
     An operation code changed flag.
     
     This flag perform update if performed code changed. Used for GUI.
     */
    public var code_changed = false
    
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
        }
    }
    
    open func perform_operation(_ code: Int) //Single operation perform
    {
        
    }
    
    //MARK: Performation cycle
    ///Selects codes and performs tool operation.
    public func start_pause_performing()
    {
        if !performed
        {
            //Move to next point if moving was stop
            performed = true
            perform_next_code()
            
            code_changed = true
        }
        else
        {
            //Pause moving if tool perform
            performed = false
            pause_handler()
        }
        
        func pause_handler()
        {
            if demo == true
            {
                model_controller.reset_model()
            }
            else
            {
                //Remove actions for real tool
                connector.pause()
            }
        }
    }
    
    ///Selects a code and performs the corresponding operation.
    public func perform_next_code()
    {
        update_statistics = true
        
        if demo
        {
            //Move to point for virtual tool
            model_controller.nodes_perform(code: selected_program.codes[selected_code_index].value)
            {
                self.select_new_code()
            }
        }
        else
        {
            //Move to point for real tool
            if connector.connected
            {
                connector.perform(code: selected_program.codes[selected_code_index].value)
                {
                    self.select_new_code()
                }
            }
            else
            {
                //Skip operation if real tool is not connected
                select_new_code()
            }
        }
    }
    
    ///Finish handler for operation code performation.
    public var finish_handler: (() -> Void) = {}
    
    ///Clears finish handler.
    public func clear_finish_handler()
    {
        finish_handler = {}
    }
    
    ///Set the new target operation code index.
    private func select_new_code()
    {
        /*DispatchQueue.main.async
        {
            self.update_statistics_data()
        }*/
        
        update_statistics = false
        
        if performed
        {
            selected_code_index += 1
        }
        else
        {
            return
        }
        
        code_changed = true
        
        if selected_code_index < selected_program.codes_count
        {
            //Select and move to next point
            perform_next_code()
        }
        else
        {
            //Reset target point index if all points passed
            selected_code_index = 0
            update_statistics_data()
            performed = false
            performing_completed = true
            
            finish_handler()
        }
    }
    
    ///Resets tool operation performation.
    public func reset_performing()
    {
        performed = false
        performing_completed = false
        selected_code_index = 0
        
        clear_chart_data()
    }
    
    //MARK: - Connection functions
    ///A tool connector.
    public var connector = ToolConnector()
    
    ///Disconnects from real tool.
    private func disconnect()
    {
        //connector.update_model = false
        connector.model_controller = nil
        connector.disconnect()
    }
    
    //MARK: - Visual build functions
    public override var scene_node_name: String { "tool" }
    
    public override var scene_internal_folder_address: String { Tool.scene_folder }
    
    ///An internal scene folder address.
    public static var scene_folder = String()
    
    ///A tool visual model controller.
    private var model_controller = ToolModelController()
    
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
                connector.model_controller?.reset_model()
                connector.model_controller = nil
            }
        }
    }
    
    ///An array of connected tool parts.
    //private var tool_parts = [SCNNode]()
    
    ///An array of tool parts lengths.
    private var lengths = [Float]()
    
    /**
     Connects to robot model in scene.
     - Parameters:
        - scene: A current scene.
        - name: A robot name.
        - connect_camera: Place camera to robot's camera node.
     */
    public func workcell_connect(scene: SCNScene, name: String) //Connect tool parts from scene
    {
        //let unit_node = scene.rootNode.childNode(withName: name, recursively: true)
        var unit_node = SCNNode()
        var stopped = false
        scene.rootNode.enumerateChildNodes
        { (_node, stop) in
            if _node.name == name && _node.categoryBitMask == Workspace.tool_bit_mask && !stopped
            {
                unit_node = _node
                stopped = true
                print((_node.name ?? "") + " is tool")
            }
        }
        
        model_controller.nodes_disconnect()
        model_controller.nodes_connect(unit_node)// ?? SCNNode())
        
        if lengths.count > 0
        {
            model_controller.lengths = lengths
            model_controller.nodes_transform()
        }
        
        model_controller.info_code = self.info_code
        
        //Pass model controller to connector
        /*if update_model_by_connector
        {
            connector.model_controller = model_controller
        }*/
    }
    
    ///Disconnect tool model parts from workcell.
    public func workcell_disconnect()
    {
        model_controller.remove_all_model_actions()
        model_controller.nodes_disconnect()
        model_controller.info_code = nil
        
        //connector.model_controller = nil
    }
    
    ///A flag determines if tool is attached to the robot manipulator.
    public var is_attached = false
    
    ///A name of the robot that the tool is attached to.
    public var attached_to: String?
    
    override public func on_remove()
    {
        attached_to = nil
    }
    
    //MARK: - Chart functions
    ///A tool charts data.
    public var charts_data: [WorkspaceObjectChart]?
    
    ///A tool state data.
    public var state_data: [StateItem]?
    
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
    
    private var get_statistics_task = Task {}
    
    private var update_statistics = false
    {
        didSet
        {
            if update_statistics
            {
                perform_statistics()
            }
        }
    }
    
    private func perform_statistics()
    {
        get_statistics_task = Task
        {
            while update_statistics
            {
                update_statistics_data()
            }
        }
    }
    
    ///Index of chart element.
    private var chart_element_index = 0
    
    ///Update statisitcs data by model controller (if demo is *true*) or connector (if demo is *false*).
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
                state_data = model_controller.state()
                charts_data = model_controller.charts_data()
            }
            else //Get statistic from real robot
            {
                state_data = connector.state()
                charts_data = connector.charts_data()
            }
        }
    }
    
    ///Clears tool chart data.
    public func clear_chart_data()
    {
        if get_statistics
        {
            if demo
            {
                model_controller.clear_charts_data()
            }
            else
            {
                connector.clear_charts_data()
            }
            
            charts_data = nil
        }
    }
    
    ///Clears tool state data.
    public func clear_state_data()
    {
        state_data = nil
        
        if get_statistics
        {
            if demo
            {
                model_controller.clear_state_data()
            }
            else
            {
                connector.clear_state_data()
            }
        }
    }
    
    //MARK: - UI functions
    #if os(macOS)
    /**
     Returns info for tool card view.
     
     Output avaliable codes count. If their number is zero, the instrument is listed as *static*.
     */
    public override var card_info: (title: String, subtitle: String, color: Color, image: NSImage) //Get info for robot card view
    {
        return("\(self.name ?? "Tool")", self.codes.count > 0 ? "\(self.codes.count) code tool" : "Static tool", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    #else
    /**
     Returns info for tool card view.
     
     Output avaliable codes count. If their number is zero, the instrument is listed as *static*.
     */
    public override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name ?? "Tool")", self.codes.count > 0 ? "\(self.codes.count) code tool" : "Static tool", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    #endif
    
    /**
     Returns point color for inspector view.
     
     Colors mean:
     - gray – if operation not selected.
     - yellow – if target operation not passed.
     - green – if target operation passed.
     */
    public func inspector_code_color(code: OperationCode) -> Color
    {
        var color = Color.gray //Gray point color if the robot is not reching the code
        let code_index = self.selected_program.codes.firstIndex(of: code) //Number of selected code
        
        if performed
        {
            if code_index == selected_code_index //Yellow color, if the tool is in the process of moving to the code
            {
                color = .yellow
            }
            else
            {
                if code_index ?? 0 < selected_code_index //Green color, if the tool has reached this code
                {
                    color = .green
                }
            }
        }
        else
        {
            if performing_completed //Green color, if the robot has passed all codes
            {
                color = .green
            }
        }
        
        return color
    }
    
    ///Apply corresponded label and SF Symbol to operation code.
    public func code_info(_ code: Int) -> (label: String, image: Image)
    {
        var image = Image("")
        
        if codes_count > 0
        {
            let info_names = codes_names[codes.firstIndex(of: code) ?? 0].components(separatedBy: "#")
            
            if info_names.count == 2
            {
                image = Image(systemName: info_names[1])
            }
            else
            {
                if info_names.count == 3
                {
                    image = Image(info_names[1])
                }
            }
            
            if info_names.count > 0
            {
                return (info_names[0], image)
            }
            else
            {
                return ("Unnamed", image)
            }
        }
        else
        {
            return ("Unnamed", image)
        }
    }
    
    private var codes_names = [String]()
    
    //MARK: - Work with file system
    ///Converts tool data to codable tool struct.
    public var file_info: ToolStruct
    {
        return ToolStruct(name: self.name,
                          codes: self.codes,
                          names: self.codes_names,
                          scene: self.scene_address,
                          lengths: self.lengths,
                          is_placed: self.is_placed,
                          location: self.location,
                          rotation: self.rotation,
                          is_attached: self.is_attached,
                          attached_to: self.attached_to,
                          demo: self.demo,
                          connection_parameters: get_connection_parameters(connector: self.connector),
                          update_model_by_connector: self.update_model_by_connector,
                          get_statistics: self.get_statistics,
                          charts_data: self.charts_data,
                          state: self.state_data,
                          programs: self.programs,
                          image_data: self.image_data,
                          module: self.module_name)
    }
}

//MARK: - Tool structure for workspace preset document handling
///A codable tool struct.
public struct ToolStruct: Codable
{
    public var name: String?
    public var codes: [Int]
    public var names: [String]
    
    public var scene: String?
    public var lengths: [Float]
    
    public var is_placed: Bool
    public var location: [Float]
    public var rotation: [Float]
    
    public var is_attached: Bool
    public var attached_to: String?
    
    public var demo: Bool
    public var connection_parameters: [String]?
    public var update_model_by_connector: Bool
    
    public var get_statistics: Bool
    public var charts_data: [WorkspaceObjectChart]?
    public var state: [StateItem]?
    
    public var programs: [OperationsProgram]
    public var image_data: Data
    
    public var module: String?
}

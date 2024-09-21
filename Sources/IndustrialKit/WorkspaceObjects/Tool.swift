//
//  Tool.swift
//  IndustrialKit
//
//  Created by Artem on 01.06.2022.
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
    
    ///Inits tool by name, controller, connector and scene name.
    public init(name: String, scene_name: String, model_controller: ToolModelController, connector: ToolConnector, codes: [OperationCodeInfo] = [OperationCodeInfo]())
    {
        super.init(name: name)
        
        self.node = (SCNScene(named: scene_name) ?? SCNScene()).rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone() //!
        
        self.model_controller = model_controller
        self.connector = connector
        
        self.codes = codes
    }
    
    ///Inits tool by name, controller, connector and scene.
    public init(name: String, scene: SCNScene, model_controller: ToolModelController, connector: ToolConnector, codes: [OperationCodeInfo] = [OperationCodeInfo]())
    {
        super.init(name: name)
        
        self.node = scene.rootNode.childNode(withName: self.scene_node_name, recursively: false)?.clone()
        
        self.model_controller = model_controller
        self.connector = connector
        
        self.codes = codes
    }
    
    ///Inits part by name and part module.
    public init(name: String, module: ToolModule)
    {
        super.init(name: name)
        module_import(module)
    }
    
    //MARK: - Module handling
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
        
        node = module.node
        
        model_controller = module.model_controller
        connector = module.connector
        
        codes = module.codes
    }
    
    ///Imported tool modules.
    public static var modules = [ToolModule]()
    
    override public func import_module_by_name(_ name: String)
    {
        guard let index = Tool.modules.firstIndex(where: { $0.name == name })
        else
        {
            return
        }
        
        module_import(Tool.modules[index])
    }
    
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
            if programs.count > 0 && selected_program_index < programs.count
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
    public var codes = [OperationCodeInfo]()
    
    ///An information output code.
    public var info_output: [Float]?
    {
        if demo
        {
            return model_controller.info_output
        }
        else
        {
            return connector.info_output
        }
    }
    
    //MARK: - Performing functions
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
    
    //MARK: Performation cycle
    /**
     Performs tool by operation code value with completion handler.
     
     - Parameters:
        - code: The operation code value of the operation performed by the tool.
        - completion: A completion function that is calls when the performing completes.
     */
    public func perform(code: Int, completion: @escaping () -> Void)
    {
        if demo
        {
            //Move to point for virtual tool
            model_controller.nodes_perform(code: code)
            {
                completion()
            }
        }
        else
        {
            //Move to point for real tool
            if connector.connected
            {
                connector.perform(code: code)
                {
                    completion()
                }
            }
            else
            {
                //Skip operation if real tool is not connected
                completion()
            }
        }
    }
    
    ///Selects codes and performs tool operation.
    public func start_pause_performing()
    {
        guard selected_program.codes_count > 0
        else
        {
            finish_handler()
            return
        }
        
        //Handling tool performing
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
            if demo
            {
                model_controller.reset_nodes()
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
        //update_statistics = true
        
        perform(code: selected_program.codes[selected_code_index].value)
        {
            self.select_new_code()
        }
    }
    
    ///Set the new target operation code index.
    private func select_new_code()
    {
        //update_statistics = false
        
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
            //update_statistics_data()
            performed = false
            performing_completed = true
            
            finish_handler()
        }
    }
    
    ///Finish handler for operation code performation.
    public var finish_handler: (() -> Void) = {}
    
    ///Clears finish handler.
    public func clear_finish_handler()
    {
        finish_handler = {}
    }
    
    ///Resets tool operation performation.
    public func reset_performing()
    {
        if performed
        {
            performed = false
            performing_completed = false
            selected_code_index = 0
            
            clear_chart_data()
        }
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
                connector.model_controller?.reset_nodes()
                connector.model_controller = nil
            }
        }
    }
    
    ///An array of connected tool parts.
    //private var tool_parts = [SCNNode]()
    
    ///An array of tool parts lengths.
    //private var lengths = [Float]()
    
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
            }
        }
        
        model_controller.disconnect_nodes()
        model_controller.connect_nodes(unit_node)// ?? SCNNode())
        
        /*if lengths.count > 0
        {
            model_controller.lengths = lengths
            model_controller.nodes_transform()
        }*/
        
        model_controller.info_output = self.info_output
        
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
        model_controller.disconnect_nodes()
        model_controller.info_output = nil
        
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
    public var states_data: [StateItem]?
    
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
    
    /*private var update_statistics = false
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
    }*/
    
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
            get_statistics_task = Task
            {
                if demo //Get statistic from model controller
                {
                    model_controller.update_statistics_data()
                    states_data = model_controller.states_data
                    charts_data = model_controller.charts_data
                }
                else //Get statistic from real tool
                {
                    connector.update_statistics_data()
                    states_data = connector.states_data
                    charts_data = connector.charts_data
                }
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
                model_controller.reset_charts_data()
            }
            else
            {
                connector.reset_charts_data()
            }
            
            charts_data = nil
        }
    }
    
    ///Clears tool state data.
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
     Returns info for tool card view.
     
     Output avaliable codes count. If their number is zero, the instrument is listed as *static*.
     */
    public override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name)", self.codes.count > 0 ? "\(self.codes.count) code tool" : "Static tool", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    
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
    
    ///Connects tool charts to UI.
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
    
    ///Connects tool charts to UI.
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
        case codes
        
        case is_attached
        case attached_to
        
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
        
        self.codes = try container.decode([OperationCodeInfo].self, forKey: .codes)
        
        self.is_attached = try container.decode(Bool.self, forKey: .is_attached)
        self.attached_to = try container.decodeIfPresent(String.self, forKey: .attached_to)
        
        self.demo = try container.decode(Bool.self, forKey: .demo)
        self.update_model_by_connector = try container.decode(Bool.self, forKey: .update_model_by_connector)
        
        self.get_statistics = try container.decode(Bool.self, forKey: .get_statistics)
        self.charts_data = try container.decodeIfPresent([WorkspaceObjectChart].self, forKey: .charts_data)
        self.states_data = try container.decodeIfPresent([StateItem].self, forKey: .states_data)
        
        self.programs = try container.decode([OperationsProgram].self, forKey: .programs)
        
        try super.init(from: decoder)
        
        read_connection_parameters(connector: self.connector, try container.decode([String].self, forKey: .connection_parameters))
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(codes, forKey: .codes)
        
        try container.encode(is_attached, forKey: .is_attached)
        try container.encode(attached_to, forKey: .attached_to)
        
        try container.encode(demo, forKey: .demo)
        try container.encode(get_connection_parameters(connector: self.connector), forKey: .connection_parameters)
        try container.encode(update_model_by_connector, forKey: .update_model_by_connector)
        
        try container.encode(get_statistics, forKey: .get_statistics)
        try container.encode(charts_data, forKey: .charts_data)
        try container.encode(states_data, forKey: .states_data)
        
        try container.encode(programs, forKey: .programs)
        
        try super.encode(to: encoder)
    }
}

/**
 Provides information about the operation code.
 
 An array of them determines the opcode values ​​available for a given device.
 */
public struct OperationCodeInfo: Equatable, Codable, Hashable
{
    ///Operation code value.
    public var value: Int
    
    ///Operation code name.
    public var name: String
    
    ///Operation code symbol.
    public var symbol: String
    
    ///Operation code info.
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

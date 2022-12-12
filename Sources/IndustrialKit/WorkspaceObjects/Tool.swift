//
//  Tool.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.06.2022.
//

import Foundation
import SceneKit
import SwiftUI

public class Tool: WorkspaceObject
{
    //MARK: - Init functions
    public override init()
    {
        super.init()
    }
    
    public override init(name: String)
    {
        super.init(name: name)
    }
    
    public init(name: String, dictionary: [String: Any]) //Init by dictionary
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
            select_modules(module_name)
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
    
    public init(tool_struct: ToolStruct) //Init by tool structure
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
            Tool.select_modules(module_name)
            apply_statistics_flags()
        }
    }
    
    /**
     Function description.
    
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
    public static var select_modules: ((_ name: String) -> Void) = {name in }
    
    private func apply_statistics_flags()
    {
        model_controller.get_statistics = get_statistics
        connector.get_statistics = get_statistics
    }
    
    //MARK: - Program manage functions
    @Published private var programs = [OperationsProgram]()
    
    public var selected_program_index = 0
    {
        willSet
        {
            //Stop tool performing before program change
            reset_performing()
        }
    }
    
    public func add_program(_ program: OperationsProgram)
    {
        program.name = mismatched_name(name: program.name!, names: programs_names)
        programs.append(program)
    }
    
    public func update_program(index: Int, _ program: OperationsProgram) //Update program by index
    {
        if programs.indices.contains(index) //Checking for the presence of a position program with a given number to update
        {
            programs[index] = program
        }
    }
    
    public func update_program(name: String, _ program: OperationsProgram) //Update program by name
    {
        update_program(index: index_by_name(name: name), program)
    }
    
    public func delete_program(index: Int) //Delete program by index
    {
        if programs.indices.contains(index) //Checking for the presence of a position program with a given number to delete
        {
            programs.remove(at: index)
        }
    }
    
    public func delete_program(name: String) //Delete program by name
    {
        delete_program(index: index_by_name(name: name))
    }
    
    public func select_program(index: Int) //Delete program by index
    {
        selected_program_index = index
    }
    
    public func select_program(name: String) //Select program by name
    {
        select_program(index: index_by_name(name: name))
    }
    
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
    
    private func index_by_name(name: String) -> Int //Get index of program by name
    {
        return programs.firstIndex(of: OperationsProgram(name: name)) ?? -1
    }
    
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
    
    public var programs_count: Int //Get count of programs in tool
    {
        return programs.count
    }
    
    //MARK: - Control functions
    public var codes = [Int]()
    
    public var performed = false //Performing state of tool
    
    public var codes_count: Int
    {
        return codes.count
    }
    
    public var info_code = 0 //Information code
    
    //MARK: - Performing functions
    private var module_name = ""
    
    public var performing_completed = false //This flag set if the robot has passed all positions. Used for indication in GUI
    public var selected_code_index = 0 //Index of target point in points array
    public var code_changed = false //This flag perform update if performed code changed
    
    public var demo = true
    {
        didSet
        {
            reset_performing()
            
            if demo
            {
                connect()
            }
            else
            {
                disconnect()
            }
        }
    }
    
    open func perform_operation(_ code: Int) //Single operation perform
    {
        
    }
    
    //MARK: Performation cycle
    public func start_pause_performing() //Handling robot moving
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
            }
        }
    }
    
    public func perform_next_code()
    {
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
            connector.perform(code: selected_program.codes[selected_code_index].value)
            {
                self.select_new_code()
            }
        }
    }
    
    public var finish_handler: (() -> Void) = {}
    public func clear_finish_handler()
    {
        finish_handler = {}
    }
    
    private func select_new_code() //Set new target point index
    {
        update_statistics_data()
        
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
            performed = false
            performing_completed = true
            
            finish_handler()
        }
    }
    
    public func reset_performing() //Reset tool performing
    {
        performed = false
        performing_completed = false
        selected_code_index = 0
        
        clear_chart_data()
    }
    
    //MARK: - Connection functions
    private var connector = ToolConnector()
    
    private func connect()
    {
        connector.update_model = update_model_by_connector
        connector.model_controller = model_controller
        connector.connect()
    }
    
    private func disconnect()
    {
        connector.update_model = false
        connector.model_controller = nil
        connector.disconnect()
    }
    
    //MARK: - Visual build functions
    public override var scene_node_name: String { "tool" }
    
    private var model_controller = ToolModelController()
    
    public var update_model_by_connector = false //Update model by model controller
    
    private var tool_parts = [SCNNode]()
    private var lengths = [Float]()
    
    public override func node_by_description()
    {
        node = SCNNode()
        node?.geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
        
        #if os(macOS)
        node?.geometry?.firstMaterial?.diffuse.contents = NSColor.gray
        #else
        node?.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        #endif
        
        node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        node?.name = "Tool"
    }
    
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
    }
    
    public func workcell_disconnect() //Disconnect tool model parts
    {
        model_controller.remove_all_model_actions()
        model_controller.nodes_disconnect()
        model_controller.info_code = nil
    }
    
    public var is_attached = false
    public var attached_to: String?
    
    //MARK: - Chart functions
    public var charts_data: [WorkspaceObjectChart]?
    public var state_data: [StateItem]?
    
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
    
    private var chart_element_index = 0
    
    func update_statistics_data()
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
        }
    }
    
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
    public override var card_info: (title: String, subtitle: String, color: Color, image: NSImage) //Get info for robot card view
    {
        return("\(self.name ?? "Tool")", self.codes.count > 0 ? "\(self.codes.count) code tool" : "Static tool", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    #else
    public override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name ?? "Tool")", self.codes.count > 0 ? "\(self.codes.count) code tool" : "Static tool", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    #endif
    
    public func inspector_code_color(code: OperationCode) -> Color //Get point color for inspector view
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
    public var file_info: ToolStruct
    {
        return ToolStruct(name: self.name, codes: self.codes, names: self.codes_names, scene: self.scene_address, lengths: self.lengths, is_placed: self.is_placed, location: self.location, rotation: self.rotation, is_attached: self.is_attached, attached_to: self.attached_to, demo: self.demo, update_model_by_connector: self.update_model_by_connector, get_statistics: self.get_statistics, charts_data: self.charts_data, state: self.state_data, programs: self.programs, image_data: self.image_data, module: self.module_name)
    }
}

//MARK: - Tool structure for workspace preset document handling
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
    public var update_model_by_connector: Bool
    
    public var get_statistics: Bool
    public var charts_data: [WorkspaceObjectChart]?
    public var state: [StateItem]?
    
    public var programs: [OperationsProgram]
    public var image_data: Data
    
    public var module: String?
}

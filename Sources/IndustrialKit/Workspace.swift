//
//  Workspace.swift
//  IndustrialKit
//
//  Created by Artem on 05.12.2021.
//

import Foundation
import SceneKit
import SwiftUI

/**
 A basis of industrial technological complex including production equipment.
 
 Performs management of the production complex.
 
 Also can build a visual model of the production system with editing functions.
 */
public class Workspace: ObservableObject
{
    //MARK: - Init functions
    public init()
    {
        registers = [Float](repeating: 0, count: Workspace.default_registers_count)
    }
    
    //MARK: - Workspace objects data
    @Published public var robots = [Robot]()
    @Published public var tools = [Tool]()
    @Published public var parts = [Part]()
    
    @Published public var elements = [WorkspaceProgramElement]()
    {
        didSet
        {
            //Reset performing if elements array was changed
            if elements.count > 0
            {
                performed = false //Enable workspace program edit
                selected_element_index = 0 //Select first program element
            }
        }
    }
    
    //MARK: - Workspace visual handling functions
    ///A SceneKit scene for complex visual model of workspace.
    public var scene = SCNScene()
    
    ///A selected workspace object type value in industrial complex.
    public var selected_object_type: WorkspaceObjectType?
    {
        if selected_robot_index > -1 && selected_part_index == -1 && selected_tool_index == -1
        {
            return .robot
        }
        
        if selected_tool_index > -1 && selected_robot_index == -1 && selected_part_index == -1
        {
            return .tool
        }
        
        if selected_part_index > -1 && selected_robot_index == -1 && selected_tool_index == -1
        {
            return .part
        }
        
        return nil
    }
    
    ///Selected workspace object.
    public var selected_object: WorkspaceObject?
    {
        get
        {
            switch selected_object_type
            {
            case .robot:
                return selected_robot
            case .tool:
                return selected_tool
            case .part:
                return selected_part
            default:
                return nil
            }
        }
        set
        {
            switch selected_object_type
            {
            case .robot:
                selected_robot = newValue as! Robot
            case .tool:
                selected_tool = newValue as! Tool
            case .part:
                selected_part = newValue as! Part
            default:
                break
            }
        }
    }
    
    ///Sets new pointer position by selected workspace object.
    public func update_pointer()
    {
        update_object_pointer_position(by_node: edited_object_node ?? SCNNode())
    }
    
    ///Updates opject selection pointer position.
    private func update_object_pointer_position(by_node: SCNNode)
    {
        //Remove old and add new constraint
        object_pointer_node?.constraints?.removeAll()
        object_pointer_node?.constraints?.append(SCNReplicatorConstraint(target: by_node))
        
        //Refresh pointer node position
        object_pointer_node?.position.x += 1
        object_pointer_node?.position.x -= 1
        //object_pointer_node?.rotation.x += 1
        //object_pointer_node?.rotation.x -= 1
        
        object_pointer_node?.isHidden = false //Unhide pointer node
    }
    
    ///A link to edited object node.
    public var edited_object_node: SCNNode?
    
    ///A workcell scene adress.
    public static var workcell_scene_address = String()
    
    ///Gets new object node model for previewing position.
    public func view_object_node(type: WorkspaceObjectType, name: String)
    {
        //Reset dismissed object by type
        switch selected_object_type
        {
        case .robot:
            selected_robot.location = [0, 0, 0]
            selected_robot.rotation = [0, 0, 0]
        case .tool:
            selected_tool.location = [0, 0, 0]
            selected_tool.rotation = [0, 0, 0]
        case .part:
            selected_part.location = [0, 0, 0]
            selected_part.rotation = [0, 0, 0]
        default:
            break
        }
        
        edited_object_node?.removeFromParentNode() //Remove old node
        edited_object_node = SCNNode() //Remove old reference
        
        switch type
        {
        case .robot:
            //Deselect other
            deselect_part()
            deselect_tool()
            
            //Get new node
            select_robot(name: name) //Select robot in workspace
            workcells_node?.addChildNode(SCNScene(named: Workspace.workcell_scene_address)!.rootNode.childNode(withName: "unit", recursively: false)!) //Get workcell from Workcell.scn and add it to Workspace.scn
            
            edited_object_node = workcells_node?.childNode(withName: "unit", recursively: false) ?? SCNNode() //Connect to unit node in workspace scene
            
            edited_object_node?.name = name
            selected_robot.workcell_connect(scene: scene, name: name, connect_camera: false)
            selected_robot.update_model()
        case .tool:
            //Deselect other
            deselect_robot()
            deselect_part()
            
            //Get new node
            select_tool(name: name)
            
            edited_object_node = selected_tool.node?.clone()
            edited_object_node?.name = name
            
            tools_node?.addChildNode(edited_object_node ?? SCNNode())
            selected_tool.workcell_connect(scene: scene, name: name)
        case .part:
            //Deselect other
            deselect_robot()
            deselect_tool()
            
            //Get new node
            select_part(name: name)
            selected_part.model_position_reset()
            
            edited_object_node = selected_part.node?.clone()
            edited_object_node?.name = name
            
            parts_node?.addChildNode(edited_object_node ?? SCNNode())
        }
        
        //Unhide pointer and move to object position
        object_pointer_node?.isHidden = false
        update_pointer()
    }
    
    ///Updates model position of selected object in workspace scene by its positional values.
    public func update_object_position()
    {
        //Get position by selected object type
        var location = [Float](repeating: 0, count: 3)
        var rotation = [Float](repeating: 0, count: 3)
        
        switch selected_object_type
        {
        case .robot:
            location = selected_robot.location
            rotation = selected_robot.rotation
        case .tool:
            location = selected_tool.location
            rotation = selected_tool.rotation
        case.part:
            location = selected_part.location
            rotation = selected_part.rotation
        default:
            break
        }
        
        //Apply position to node
        #if os(macOS)
        edited_object_node?.worldPosition = SCNVector3(x: CGFloat(location[1]), y: CGFloat(location[2]), z: CGFloat(location[0]))
        
        edited_object_node?.eulerAngles.x = CGFloat(rotation[1].to_rad)
        edited_object_node?.eulerAngles.y = CGFloat(rotation[2].to_rad)
        edited_object_node?.eulerAngles.z = CGFloat(rotation[0].to_rad)
        #else
        edited_object_node?.worldPosition = SCNVector3(x: location[1], y: location[2], z: location[0])
        
        edited_object_node?.eulerAngles.x = rotation[1].to_rad
        edited_object_node?.eulerAngles.y = rotation[2].to_rad
        edited_object_node?.eulerAngles.z = rotation[0].to_rad
        #endif
    }
    
    ///Places object in workspace.
    public func place_viewed_object()
    {
        switch selected_object_type
        {
        case .robot:
            selected_robot.is_placed = true
            apply_bit_mask(node: edited_object_node ?? SCNNode(), Workspace.robot_bit_mask) //Apply category bit mask
            
            deselect_robot()
        case .tool:
            selected_tool.is_placed = true
            apply_bit_mask(node: edited_object_node ?? SCNNode(), Workspace.tool_bit_mask) //Apply category bit mask
            
            deselect_tool()
        case.part:
            selected_part.is_placed = true
            
            apply_bit_mask(node: edited_object_node ?? SCNNode(), Workspace.part_bit_mask) //Apply category bit mask
            edited_object_node?.physicsBody = selected_part.physics //Apply physics
            
            deselect_part()
        default:
            break
        }
        
        //Disconnecting from edited node
        edited_object_node = SCNNode() //Remove old reference
        edited_object_node?.removeFromParentNode() //Remove old node
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
        {
            self.in_visual_edit_mode = false
        }
    }
    
    ///Removes selected object model from workspace scene.
    public func dismiss_object()
    {
        object_pointer_node?.isHidden = true
        
        edited_object_node?.removeFromParentNode() //Remove edited object node
        edited_object_node = SCNNode() //Remove scnnode link
        
        deselect_object()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
        {
            self.in_visual_edit_mode = false
        }
    }
    
    public var selected_object_unavaliable: Bool?
    {
        var unavaliable = true
        switch selected_object_type
        {
        case .robot:
            if avaliable_robots_names.count == 0
            {
                unavaliable = true
            }
            else
            {
                unavaliable = false
            }
        case .tool:
            if avaliable_tools_names.count == 0
            {
                unavaliable = true
            }
            else
            {
                unavaliable = false
            }
        case.part:
            if avaliable_parts_names.count == 0
            {
                unavaliable = true
            }
            else
            {
                unavaliable = false
            }
        default:
            unavaliable = true
        }
        
        return unavaliable
    }
    
    ///Process object node selection in workspace scene.
    public func select_object_in_scene(result: SCNHitTestResult)
    {
        //print(result.localCoordinates)
        //print("🍮 tapped – \(result.node.name!), category \(result.node.categoryBitMask)")
        var object_node: SCNNode?
        
        switch result.node.categoryBitMask //Switch object node bit mask
        {
        case Workspace.robot_bit_mask:
            object_node = main_object_node(result_node: result.node, object_bit_mask: Workspace.robot_bit_mask)
            select_object_for_edit(node: object_node!, type: .robot)
        case Workspace.tool_bit_mask:
            object_node = main_object_node(result_node: result.node, object_bit_mask: Workspace.tool_bit_mask)
            select_object_for_edit(node: object_node!, type: .tool)
        case Workspace.part_bit_mask:
            object_node = main_object_node(result_node: result.node, object_bit_mask: Workspace.part_bit_mask)
            select_object_for_edit(node: object_node!, type: .part)
        default:
            deselect_object_for_edit()
        }
        update_view()
        
        func main_object_node(result_node: SCNNode, object_bit_mask: Int) -> SCNNode //Find top level node of selectable object
        {
            var current_node = result_node
            var saved_node = SCNNode()
            
            while current_node.categoryBitMask == object_bit_mask
            {
                saved_node = current_node
                current_node = current_node.parent!
            }
            
            return saved_node
        }
    }
    
    private var previous_selected_type: WorkspaceObjectType = .robot //Current selected object type for new selection
    
    private func select_object_for_edit(node: SCNNode, type: WorkspaceObjectType) //Create editable node with name
    {
        //Connect to old part node
        var old_part_node = SCNNode()
        if selected_object_type == .part
        {
            old_part_node = edited_object_node!
        }
        edited_object_node = node //Connect to tapped node
        
        if any_object_selected
        {
            switch type //Switch new selected objec type
            {
            case .robot:
                if type == previous_selected_type
                {
                    if node.name ?? "" == selected_robot.name
                    {
                        //Deselect already selected robot
                        deselect_robot()
                        object_pointer_node?.isHidden = true
                    }
                    else
                    {
                        //Change selected to new robot
                        select_robot(name: node.name!)
                        update_pointer()
                    }
                }
                else
                {
                    deselect_all()
                    select_new()
                }
            case .tool:
                if type == previous_selected_type
                {
                    if node.name ?? "" == selected_tool.name
                    {
                        //Deselect already selected tool
                        deselect_tool()
                        object_pointer_node?.isHidden = true
                    }
                    else
                    {
                        //Change selected to new tool
                        select_tool(name: node.name!)
                        update_pointer()
                    }
                }
                else
                {
                    deselect_all()
                    select_new()
                }
            case .part:
                if type == previous_selected_type
                {
                    if node.name ?? "" == selected_part.name
                    {
                        //Deselect already selected part
                        deselect_part()
                        edited_object_node?.physicsBody = selected_part.physics
                        object_pointer_node?.isHidden = true
                    }
                    else
                    {
                        old_part_node.physicsBody = selected_part.physics //Enable physics for deselctable node
                        
                        //Change selected to new part
                        select_part(name: node.name!)
                        update_pointer()
                        
                        edited_object_node?.physicsBody = .none //Disable physics physics for selected node
                    }
                }
                else
                {
                    edited_object_node?.physicsBody = selected_part.physics
                    deselect_all()
                    select_new()
                }
            }
            
            previous_selected_type = type
        }
        else
        {
            select_new() //If nothing object selected – select new
        }
        
        func select_new() //Select new object by type
        {
            switch type
            {
            case .robot:
                select_robot(name: node.name!)
            case .tool:
                select_tool(name: node.name!)
            case .part:
                select_part(name: node.name!)
                edited_object_node?.physicsBody = .none
                
                //Get part node position after physics calculation
                #if os(macOS)
                selected_part.location = [Float((edited_object_node?.presentation.worldPosition.z)!), Float((edited_object_node?.presentation.worldPosition.x)!), Float((edited_object_node?.presentation.worldPosition.y)!)]
                selected_part.rotation = [Float((edited_object_node?.presentation.eulerAngles.z)!).to_deg, Float((edited_object_node?.presentation.eulerAngles.x)!).to_deg, Float((edited_object_node?.presentation.eulerAngles.y)!).to_deg]
                #else
                selected_part.location = [(edited_object_node?.presentation.worldPosition.z)!, (edited_object_node?.presentation.worldPosition.x)!, (edited_object_node?.presentation.worldPosition.y)!]
                selected_part.rotation = [(edited_object_node?.presentation.eulerAngles.z.to_deg)!, (edited_object_node?.presentation.eulerAngles.x.to_deg)!, (edited_object_node?.presentation.eulerAngles.y.to_deg)!]
                #endif
            }
            
            //Unhide pointer and move to object position
            object_pointer_node?.isHidden = false
            update_pointer()
        }
        
        func deselect_all()
        {
            deselect_robot()
            deselect_tool()
            deselect_part()
        }
    }
    
    ///Deselects edited object node.
    public func deselect_object_for_edit()
    {
        if any_object_selected
        {
            update_view()
            object_pointer_node?.isHidden = true
            
            switch selected_object_type
            {
            case .robot:
                deselect_robot()
            case .tool:
                deselect_tool()
            case .part:
                if selected_part.is_placed
                {
                    edited_object_node?.physicsBody = selected_part.physics
                }
                deselect_part()
            default:
                break
            }
            
            //Disconnect from edited node
            edited_object_node = SCNNode() //Remove old reference
            //edited_object_node?.removeFromParentNode() //Remove old node
        }
    }
    
    ///Unplaces selected object from workspace.
    public func unplace_selected_object()
    {
        if any_object_selected
        {
            //Toggle selection state and deselect by object type
            switch selected_object_type
            {
            case .robot:
                selected_robot.is_placed = false
                deselect_robot()
                elements_check()
            case .tool:
                selected_tool.is_placed = false
                remove_attachment()
                deselect_tool()
                elements_check()
            case .part:
                selected_part.is_placed = false
                deselect_part()
            default:
                break
            }
        }
        
        //Disconnect from edited node
        edited_object_node?.removeFromParentNode() //Remove old node
        edited_object_node = SCNNode() //Remove old reference
        
        object_pointer_node?.isHidden = true
    }
    
    ///Deselects selected object.
    public func deselect_object()
    {
        switch selected_object_type
        {
        case .robot:
            deselect_robot()
        case .tool:
            deselect_tool()
        case .part:
            deselect_part()
        default:
            break
        }
    }
    
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
    
    //MARK: - Robots handling functions
    //MARK: Robots manage functions
    ///Adds robot in workspace.
    public func add_robot(_ robot: Robot)
    {
        robot.name = mismatched_name(name: robot.name, names: robots_names)
        robots.append(robot)
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
            elements_check()
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
     Duplicates robot in workspace.
     
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
            
            robots[new_index] = clone_codable(robots[index]) ?? Robot() //Robot(robot_struct: robots[index].file_info)
            robots[new_index].name = new_name
            robots[new_index].is_placed = false
        }
    }
    
    /**
     Duplicates robot in workspace.
     
     - Parameters:
        - name: A name of robot to be duplicated.
     */
    public func duplicate_robot(name: String)
    {
        duplicate_robot(index: index_by_name(name, objects: robots))
    }
    
    //MARK: Robot selection functions
    private var selected_robot_index = -1
    
    /**
     Selects robot by index.
     
     - Parameters:
        - index: An index of robot to be selected.
     */
    public func select_robot(index: Int)
    {
        selected_robot_index = index
    }
    
    /**
     Selects robot by name.
     
     - Parameters:
        - name: A name of robot to be selected.
     */
    public func select_robot(name: String)
    {
        select_robot(index: index_by_name(name, objects: robots))
    }
    
    ///Deselects selected robot.
    public func deselect_robot()
    {
        selected_robot_index = -1
    }
    
    ///Selected robot.
    public var selected_robot: Robot
    {
        get
        {
            if selected_robot_index > -1 && selected_robot_index < robots.count
            {
                return robots[selected_robot_index]
            }
            else
            {
                return Robot()
            }
        }
        set
        {
            if selected_robot_index > -1
            {
                robots[selected_robot_index] = newValue
            }
        }
    }
    
    //MARK: Robots naming
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
        
        //return self.robots[robot_index_by_name(name)]
    }
    
    ///Names of all robots in workspace.
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
    
    ///Names of robots avaliable to place in workspace.
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
    
    ///Names of robots placed in workspace.
    public var placed_robots_names: [String] //Array of robots names added to workspace
    {
        var names = [String]()
        for robot in robots
        {
            if robot.is_placed
            {
                names.append(robot.name)
            }
        }
        return names
    }
    
    ///Names of robots avaliable to tool attachment.
    public var attachable_robots_names: [String]
    {
        var names = placed_robots_names
        
        if names.count > 0
        {
            //Find attached robots names by tools
            var attached_robots_names = [String]()
            for tool in tools
            {
                if tool.is_attached
                {
                    attached_robots_names.append(tool.attached_to ?? "")
                }
            }
            
            names = names.filter{ !attached_robots_names.contains($0) } //Substract attached robots names from all placed robots
        }
        
        return names
    }
    
    //MARK: - Tools handling functions
    //MARK: Tools manage funcions
    ///Adds tool in workspace.
    public func add_tool(_ tool: Tool)
    {
        tool.name = mismatched_name(name: tool.name, names: tools_names)
        tools.append(tool)
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
            elements_check()
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
     Duplicates tool in workspace.
     
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
            
            tools[new_index] = clone_codable(tools[index]) ?? Tool() //Tool(tool_struct: tools[index].file_info)
            tools[new_index].name = new_name
            tools[new_index].is_placed = false
        }
    }
    
    /**
     Duplicates tool in workspace.
     
     - Parameters:
        - name: A name of tool to be duplicated.
     */
    public func duplicate_tool(name: String)
    {
        duplicate_tool(index: index_by_name(name, objects: tools))
    }

    //MARK: Tools selection functions
    private var selected_tool_index = -1
    
    ///Selected tool.
    public var selected_tool: Tool
    {
        get
        {
            if selected_tool_index > -1 && selected_tool_index < tools.count
            {
                return tools[selected_tool_index]
            }
            else
            {
                return Tool(name: "None")
            }
        }
        set
        {
            if selected_tool_index > -1
            {
                tools[selected_tool_index] = newValue
            }
        }
    }
    
    /**
     Selects tool by index.
     
     - Parameters:
        - index: An index of tool to be selected.
     */
    public func select_tool(index: Int) //Select tool by number
    {
        selected_tool_index = index
    }
    
    /**
     Selects tool by name.
     
     - Parameters:
        - name: A name of tool to be selected.
     */
    public func select_tool(name: String) //Select tool by name
    {
        select_tool(index: index_by_name(name, objects: tools))
    }
    
    ///Deselects selected tool.
    public func deselect_tool()
    {
        selected_tool_index = -1
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
        
        //return self.tools[tool_index_by_name(name)]
    }
    
    ///Names of all tools in workspace.
    public var tools_names: [String] //Get names of all tools in workspace
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
    
    ///Names of tools avaliable to place in workspace.
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
    
    ///Names of tools placed in workspace.
    public var placed_tools_names: [String] //Array of robots names added to workspace
    {
        var names = [String]()
        for tool in tools
        {
            if tool.is_placed
            {
                names.append(tool.name)
            }
        }
        return names
    }
    
    //MARK: Tool attachment functions
    /**
     Attaches tool to robot.
     
     - Parameters:
        - robot_name: A name of the robot that the tool is attached to.
     */
    public func attach_tool_to(robot_name: String)
    {
        update_pointer()
        
        edited_object_node?.constraints = [SCNConstraint]()
        edited_object_node?.constraints?.append(SCNReplicatorConstraint(target: robot_by_name(robot_name).tool_node))
    }
    
    ///Removes attachment for edited tool and reset it position in workspace.
    public func remove_attachment()
    {
        edited_object_node?.remove_all_constraints()
        selected_tool.attached_to = nil
    }
    
    //MARK: - Parts handling functions
    //MARK: Parts manage funcions
    ///Adds part in workspace.
    public func add_part(_ part: Part)
    {
        part.name = mismatched_name(name: part.name, names: parts_names)
        parts.append(part)
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
     Duplicates part in workspace.
     
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

            parts[new_index] = clone_codable(parts[index]) ?? Part() //Part(part_struct: parts[index].file_info)
            parts[new_index].name = new_name
            parts[new_index].is_placed = false
        }
    }
    
    /**
     Duplicates part in workspace.
     
     - Parameters:
        - name: A name of part to be duplicated.
     */
    public func duplicate_part(name: String)
    {
        duplicate_part(index: index_by_name(name, objects: parts))
    }
    
    //MARK: Parts selection functions
    private var selected_part_index = -1
    
    ///Selected part.
    public var selected_part: Part //Return part by selected index
    {
        get
        {
            if selected_part_index > -1 && selected_part_index < parts.count
            {
                return parts[selected_part_index]
            }
            else
            {
                return Part(name: "None")
            }
        }
        set
        {
            if selected_part_index > -1
            {
                parts[selected_part_index] = newValue
            }
        }
    }
    
    /**
     Selects part by index.
     
     - Parameters:
        - index: An index of part to be selected.
     */
    public func select_part(index: Int)
    {
        selected_part_index = index
    }
    
    /**
     Selects part by name.
     
     - Parameters:
        - name: A name of part to be selected.
     */
    public func select_part(name: String)
    {
        select_part(index: index_by_name(name, objects: parts))
    }
    
    ///Deselects selected part.
    public func deselect_part()
    {
        selected_part_index = -1
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
        
        //return self.parts[part_index_by_name(name)]
    }
    
    ///Names of all parts in workspace.
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
    
    ///Names of parts avaliable to place in workspace.
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
    
    ///Names of parts placed in workspace.
    public var placed_parts_names: [String] //Array of robots names added to workspace
    {
        var names = [String]()
        for part in parts
        {
            if part.is_placed
            {
                names.append(part.name)
            }
        }
        return names
    }
    
    //MARK: - Control program functions
    //MARK: Workspace program elements handling
    ///All marks in workspace program.
    public var marks_names: [String]
    {
        var marks_names = [String]()
        for program_element in self.elements
        {
            if program_element is MarkLogicElement
            {
                marks_names.append((program_element as! MarkLogicElement).name)
            }
        }
        
        return marks_names
    }
    
    ///Deletes program element by number.
    public func delete_element(index: Int)
    {
        if elements.indices.contains(index)
        {
            elements.remove(at: index)
        }
    }
    
    //MARK: Workspace progem elements checking functions
    public func elements_check()
    {
        for element in elements
        {
            switch element
            {
            case is RobotPerformerElement:
                robot_element_check(element as! RobotPerformerElement)
            case is ToolPerformerElement:
                tool_element_check(element as! ToolPerformerElement)
            case is ObserverModifierElement:
                observer_element_check(element as! ObserverModifierElement)
            case is ChangerModifierElement:
                changer_element_check(element as! ChangerModifierElement)
            case is JumpLogicElement:
                jump_element_check(element as! JumpLogicElement)
            case is ComparatorLogicElement:
                comparator_element_check(element as! ComparatorLogicElement)
            default:
                break
            }
        }
        
        func robot_element_check(_ element: RobotPerformerElement) //Check element by selected robot exists
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
            if !Workspace.changer_modules.contains(element.module_name)
            {
                if Workspace.changer_modules.count > 0
                {
                    element.module_name = Workspace.changer_modules.first!
                }
                else
                {
                    element.module_name = "None"
                }
            }
        }
        
        func jump_element_check(_ element: JumpLogicElement)
        {
            mark_check(name: &element.target_mark_name)
        }
        
        func comparator_element_check(_ element: ComparatorLogicElement) //Check element by selected mark exists
        {
            mark_check(name: &element.target_mark_name)
        }
        
        func mark_check(name: inout String)
        {
            if marks_names.count > 0
            {
                var mark_founded = false
                
                for mark_name in self.marks_names
                {
                    if mark_name == name
                    {
                        mark_founded = true
                        break
                    }
                }
                
                if !mark_founded //&& name == ""
                {
                    name = marks_names[0]
                }
            }
            else
            {
                name = ""
            }
        }
    }
    
    //MARK: Performation functions
    ///Program performating cycle state.
    @Published public var cycled = false
    
    ///Workspace performing state.
    public var performed = false
    
    ///An Index of target element in control program array.
    private var selected_element_index = 0
    
    /**
     An program element changed flag.
     
     This flag perform update if performed element changed. Used for GUI.
     */
    public var element_changed = false
    
    ///Selects program element and performs by workcell.
    public func start_pause_performing()
    {
        guard elements.count > 0
        else
        {
            return
        }
        
        if !(object_pointer_node?.isHidden ?? false)
        {
            deselect_object_for_edit()
        }
        
        prepare_program()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) //Delayed view update
        {
            self.update_view()
        }
        
        if !performed
        {
            //Move to next point if moving was stop
            performed = true
            
            perform_next_element()
            element_changed = true
        }
        else
        {
            //Remove all action if moving was perform
            performed = false
            
            //Stop perfomed objects
            pause_performing()
        }
    }
    
    ///A selected workspace program element.
    private var selected_program_element: WorkspaceProgramElement
    {
        return elements[selected_element_index]
    }
    
    ///Selects and performs program element by workspace.
    private func perform_next_element()
    {
        let element = selected_program_element
        
        switch element
        {
        case let performer_element as RobotPerformerElement:
            perform_robot_by(element: performer_element)
        case let performer_element as ToolPerformerElement:
            perform_tool_by(element: performer_element)
        case let mover_element as MoverModifierElement:
            move_by(element: mover_element)
            select_new_element()
        case let write_element as WriterModifierElement:
            write_by(element: write_element)
            select_new_element()
        case let math_element as MathModifierElement:
            math_by(element: math_element)
            select_new_element()
        case let changer_element as ChangerModifierElement:
            let registers_count = registers.count
            changer_element.change(&registers)
            check_registers(registers_count)
            select_new_element()
        case let observer_element as ObserverModifierElement:
            observe_by(element: observer_element)
            select_new_element()
        case is CleanerModifierElement:
            clear_registers()
            select_new_element()
        case let jump_element as JumpLogicElement:
            jump_by(element: jump_element)
            select_new_element()
        case let comparator_element as ComparatorLogicElement:
            compare_by(element: comparator_element)
            select_new_element()
        case is MarkLogicElement:
            select_new_element()
        default:
            select_new_element()
        }
        
        func check_registers(_ reference_count: Int)
        {
            if registers.count != reference_count
            {
                update_registers_count(reference_count)
            }
        }
    }
    
    ///Set the new target program element index.
    private func select_new_element()
    {
        if performed
        {
            selected_element_index += 1
        }
        else
        {
            return
        }
        
        element_changed = true
        
        if selected_element_index < elements.count
        {
            //Select and move to next point
            perform_next_element()
        }
        else
        {
            selected_element_index = 0
            
            if cycled
            {
                perform_next_element()
            }
            else
            {
                performed = false
                
                deselect_robot()
                deselect_tool()
                //update_view()
            }
        }
    }
    
    ///Pauses program element performing.
    public func pause_performing()
    {
        let element = selected_program_element
        
        switch element
        {
        case is RobotPerformerElement:
            pause_robot()
        case is ToolPerformerElement:
            pause_tool()
        default:
            break
        }
        
        func pause_robot()
        {
            selected_robot.start_pause_moving()
            deselect_robot()
        }
        
        func pause_tool()
        {
            selected_tool.start_pause_performing()
            deselect_tool()
        }
    }
    
    ///A default count of data registers in workspace.
    public static var default_registers_count = 256
    
    ///An array of pushed info data.
    public var registers: [Float]// = [Float](repeating: 0, count: Workspace.default_registers_count)
    
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
    
    ///Clears all data registers.
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
    
    //MARK: - Elements processing
    /**
     Perform robot by element data.
     - Parameters:
        - element: A robot performer element.
     */
    private func perform_robot_by(element: RobotPerformerElement)
    {
        select_robot(name: element.object_name)
        deselect_tool()
        
        if !element.is_single_perfrom
        {
            if selected_robot_index != -1
            {
                if !element.is_program_by_index
                {
                    selected_robot.select_program(name: element.program_name)
                }
                else
                {
                    selected_robot.select_program(index: Int(registers[safe: element.program_index]))
                }
                
                selected_robot.finish_handler = self.select_new_element
                selected_robot.start_pause_moving()
            }
            else
            {
                select_new_element()
            }
        }
        else
        {
            //Single robot perform
            var target_point = PositionPoint(x: registers[safe: element.x_index],
                                             y: registers[safe: element.y_index],
                                             z: registers[safe: element.z_index],
                                             r: registers[safe: element.r_index],
                                             p: registers[safe: element.p_index],
                                             w: registers[safe: element.w_index],
                                             move_speed: registers[safe: element.speed_index])
            selected_robot.point_shift(&target_point)
            
            selected_robot.move_to(point: target_point)
            {
                self.selected_robot.pointer_position_to_robot()
                self.select_new_element()
            }
        }
    }
    
    /**
     Perform tool by element data.
     - Parameters:
        - element: A tool performer element.
     */
    private func perform_tool_by(element: ToolPerformerElement)
    {
        select_tool(name: element.object_name)
        deselect_robot()
        
        if !element.is_single_perfrom
        {
            if selected_tool_index != -1
            {
                if !element.is_program_by_index
                {
                    selected_tool.select_program(name: element.program_name)
                }
                else
                {
                    selected_tool.select_program(index: Int(registers[safe: element.program_index]))
                }
                
                selected_tool.finish_handler = self.select_new_element
                selected_tool.start_pause_performing()
            }
            else
            {
                select_new_element()
            }
        }
        else
        {
            //Single tool perform
            selected_tool.perform(code: Int(registers[safe: element.opcode_index]))
            {
                self.select_new_element()
            }
        }
    }
    
    /**
     Move value between registers.
     - Parameters:
        - element: A mover modifier element.
     */
    private func move_by(element: MoverModifierElement)
    {
        registers[safe: element.to_index] = registers[safe: element.from_index]
        if element.move_type == .move
        {
            registers[safe: element.from_index] = 0
        }
    }
    
    /**
     Write value from element to regiser.
     - Parameters:
        - element: A write modifier element.
     */
    private func write_by(element: WriterModifierElement)
    {
        registers[safe: element.to_index] = element.value
    }
    
    private func math_by(element: MathModifierElement)
    {
        element.operation.operation(&registers[safe: element.value_index], registers[safe: element.value2_index])
    }
    
    /**
     Pushes info from tool to register.
     - Parameters:
        - element: An observable modifier element.
     */
    private func observe_by(element: ObserverModifierElement)
    {
        var info_output = [Float]()
        
        switch element.object_type
        {
        case .robot:
            robot_by_name(element.object_name).pointer_position_to_robot()
            
            var pointer_position = robot_by_name(element.object_name).pointer_location
            for i in 0 ..< 3
            {
                info_output.append(pointer_position[i])
            }
            
            pointer_position = robot_by_name(element.object_name).pointer_rotation
            for i in 0 ..< 3
            {
                info_output.append(pointer_position[i])
            }
        case .tool:
            info_output = tool_by_name(element.object_name).info_output ?? [Float]()
        }
        
        if element.from_indices.count > 0
        {
            for i in 0..<element.from_indices.count
            {
                if element.to_indices[i] <= 255 && element.to_indices[i] >= 0 && (element.from_indices[i] < info_output.count)
                {
                    registers[safe: element.to_indices[i]] = info_output[element.from_indices[i]]
                }
            }
        }
    }
    
    ///A changer modules names array.
    public static var changer_modules = [String]()
    
    /**
     Jumps to program element by index.
     - Parameters:
        - index: An element index to jump.
     */
    private func jump_by(element: JumpLogicElement)
    {
        selected_element_index = element.target_element_index
    }
    
    /**
     Jumps to program element by index if compare condition is met.
     - Parameters:
        - index: An element index to jump.
     */
    private func compare_by(element: ComparatorLogicElement)
    {
        if element.compare_type.compare(registers[safe: element.value_index], registers[safe: element.value2_index])
        {
            selected_element_index = element.target_element_index
        }
    }
    
    ///Resets workspace performing.
    public func reset_performing()
    {
        if performed
        {
            pause_performing()
            
            switch selected_object_type
            {
            case .robot:
                selected_robot.reset_moving()
            case .tool:
                selected_tool.reset_performing()
            default:
                break
            }
            
            performed = false //Enable workspace program edit
            selected_element_index = 0 //Select first program element
        }
    }
    
    ///Prepare workspace program to perform.
    private func prepare_program()
    {
        defining_elements_indexes()
    }
    
    ///Define program element indexes.
    private func defining_elements_indexes()
    {
        //Find mark elements indexes
        var marks_associations = [(String, Int)]()
        var element = WorkspaceProgramElement()
        for i in 0..<elements.count
        {
            element = elements[i]
            if element is MarkLogicElement
            {
                marks_associations.append(((element as! MarkLogicElement).name, i))
            }
        }
        
        //Set target element indexes of marks to jump elements.
        var target_mark_name = String()
        
        for element in elements
        {
            if element is JumpLogicElement
            {
                target_mark_name = (element as! JumpLogicElement).target_mark_name
            }
            if element is ComparatorLogicElement
            {
                target_mark_name = (element as! ComparatorLogicElement).target_mark_name
            }
            
            if target_mark_name != ""
            {
                for marks_association in marks_associations
                {
                    if marks_association.0 == target_mark_name
                    {
                        if element is JumpLogicElement
                        {
                            (element as! JumpLogicElement).target_element_index = marks_association.1
                        }
                        if element is ComparatorLogicElement
                        {
                            (element as! ComparatorLogicElement).target_element_index = marks_association.1
                        }
                        break
                    }
                }
            }
        }
    }
    
    //MARK: - Work with file system
    /**
     Returns arrays of document structures by workspace objects type.
     
     - Returns: Codable structures for robots, tools, parts and elements ordered as control program.
     */
    public func file_data() -> (robots: [Robot], tools: [Tool], parts: [Part], elements: [WorkspaceProgramElementStruct], registers: [Float])
    {
        //Get robots info for save to file
        var robots_file_info = [Robot]()
        for robot in robots
        {
            robots_file_info.append(robot)
        }
        
        //Get tools info for save to file
        var tools_file_info = [Tool]()
        for tool in tools
        {
            tools_file_info.append(tool)
        }
        
        //Get parts info for save to file
        var parts_file_info = [Part]()
        for part in parts
        {
            parts_file_info.append(part)
        }
        
        //Get workspace program elements info for save to file
        var elements_file_info = [WorkspaceProgramElementStruct]()
        for element in elements
        {
            elements_file_info.append(element.file_info)
        }
        
        return(robots_file_info, tools_file_info, parts_file_info, elements_file_info, registers)
    }
    
    ///File bookmark for robots models.
    public static var robots_bookmark: Data?
    
    ///File bookmark for tools models.
    public static var tools_bookmark: Data?
    
    ///File bookmark for parts models.
    public static var parts_bookmark: Data?
    
    /**
     Imports file data to workspace from preset structure.
     
     - Parameters:
        - preset: Imported workspace preset.
     */
    public func file_view(preset: WorkspacePreset)
    {
        //Update robots data from file
        robots.removeAll()
        Robot.folder_bookmark = Workspace.robots_bookmark
        
        for robot in preset.robots
        {
            robots.append(robot)
        }
        
        //Update tools data from file
        tools.removeAll()
        Tool.folder_bookmark = Workspace.tools_bookmark
        
        for tool in preset.tools
        {
            tools.append(tool)
        }
        
        //Update parts data from file
        parts.removeAll()
        Part.folder_bookmark = Workspace.parts_bookmark
        
        for part in preset.parts
        {
            //part.get_node_from_scene()
            //part.color_to_model()
            
            parts.append(part)
        }
        
        //Update workspace program elements data from file
        elements.removeAll()
        for element in preset.elements
        {
            elements.append(element_from_struct(element))
        }
        
        registers = preset.registers ?? [Float](repeating: 0, count: Workspace.default_registers_count)
    }
    
    //MARK: - UI Functions
    ///Determines whether the object can be selected if it is open for editing.
    public var in_visual_edit_mode = false
    
    ///Force updates SwiftUI view.
    public func update_view()
    {
        self.objectWillChange.send()
    }
    
    ///Selection workspace object state.
    public var any_object_selected: Bool
    {
        if selected_robot_index == -1 && selected_part_index == -1 && selected_tool_index == -1
        {
            return false
        }
        else
        {
            return true
        }
    }
    
    ///Determines whether a given program element is currently selected for performing.
    public func is_current_element(element: WorkspaceProgramElement) -> Bool
    {
        var flag = false
        let element_index = self.elements.firstIndex(of: element) //Index of selected code
        
        if performed
        {
            if element_index == selected_element_index
            {
                flag = true
            }
        }
        
        return flag
    }
    
    //MARK: - Visual functions
    ///Scene camera node.
    public var camera_node: SCNNode?
    
    ///Robots workcells node.
    public var workcells_node: SCNNode?
    
    ///Tools node.
    public var tools_node: SCNNode?
    
    ///Parts node.
    public var parts_node: SCNNode?
    
    ///Viusal object pointer node.
    public var object_pointer_node: SCNNode?
    
    ///Robot node category bit mask.
    public static var robot_bit_mask = 2
    
    ///Tool node category bit mask.
    public static var tool_bit_mask = 4
    
    ///Part node category bit mask.
    public static var part_bit_mask = 6
    
    ///Connects and places objects to workspace scene.
    public func connect_scene(_ scene: SCNScene)
    {
        deselect_robot()
        deselect_tool()
        deselect_part()
        
        camera_node = scene.rootNode.childNode(withName: "camera", recursively: true)
        
        workcells_node = scene.rootNode.childNode(withName: "workcells", recursively: true)
        tools_node = scene.rootNode.childNode(withName: "tools", recursively: false)
        parts_node = scene.rootNode.childNode(withName: "parts", recursively: false)
        
        object_pointer_node = scene.rootNode.childNode(withName: "object_pointer", recursively: false)
        object_pointer_node?.constraints = [SCNConstraint]()
        
        place_objects(scene: scene)
    }
    
    private func place_objects(scene: SCNScene)
    {
        //Nodes for placement operations
        var unit_node: SCNNode?
        var tool_node: SCNNode?
        var part_node: SCNNode?
        
        //Place robots
        if self.avaliable_robots_names.count < self.robots.count //If there are placed robots in workspace
        {
            var connect_camera = true
            for robot in robots
            {
                if robot.is_placed
                {
                    workcells_node?.addChildNode(SCNScene(named: Workspace.workcell_scene_address)!.rootNode.childNode(withName: "unit", recursively: false)!)
                    unit_node = workcells_node?.childNode(withName: "unit", recursively: false) ?? SCNNode() //Connect to unit node in workspace scene
                    
                    unit_node?.name = robot.name //Select robot cell node
                    robot.workcell_connect(scene: scene, name: robot.name, connect_camera: connect_camera) //Connect to robot model, place manipulator
                    robot.update_model() //Update robot by current position
                    
                    apply_bit_mask(node: robot.unit_node ?? SCNNode(), Workspace.robot_bit_mask)
                    
                    connect_camera = false //Disable camera connect for next robots in array
                    
                    //Set robot cell node position
                    #if os(macOS)
                    unit_node?.worldPosition = SCNVector3(x: CGFloat(robot.location[1]), y: CGFloat(robot.location[2]), z: CGFloat(robot.location[0]))
                    
                    unit_node?.eulerAngles.x = CGFloat(robot.rotation[1].to_rad)
                    unit_node?.eulerAngles.y = CGFloat(robot.rotation[2].to_rad)
                    unit_node?.eulerAngles.z = CGFloat(robot.rotation[0].to_rad)
                    #else
                    unit_node?.worldPosition = SCNVector3(x: robot.location[1], y: robot.location[2], z: robot.location[0])

                    unit_node?.eulerAngles.x = robot.rotation[1].to_rad
                    unit_node?.eulerAngles.y = robot.rotation[2].to_rad
                    unit_node?.eulerAngles.z = robot.rotation[0].to_rad
                    #endif
                }
            }
        }
        
        //Place tools
        if self.avaliable_tools_names.count < self.tools.count //If there are placed tools in workspace
        {
            for tool in tools
            {
                if tool.is_placed
                {
                    tool_node = tool.node
                    apply_bit_mask(node: tool_node ?? SCNNode(), Workspace.tool_bit_mask)
                    tool_node?.name = tool.name
                    tools_node?.addChildNode(tool_node ?? SCNNode())
                    tool.workcell_connect(scene: scene, name: tool.name) //Connect to robot model, place manipulator
                    
                    if !tool.is_attached
                    {
                        //Set tool node position
                        #if os(macOS)
                        tool_node?.position = SCNVector3(x: CGFloat(tool.location[1]), y: CGFloat(tool.location[2]), z: CGFloat(tool.location[0]))
                        
                        tool_node?.eulerAngles.x = CGFloat(tool.rotation[1].to_rad)
                        tool_node?.eulerAngles.y = CGFloat(tool.rotation[2].to_rad)
                        tool_node?.eulerAngles.z = CGFloat(tool.rotation[0].to_rad)
                        #else
                        tool_node?.position = SCNVector3(x: Float(tool.location[1]), y: Float(tool.location[2]), z: Float(tool.location[0]))
                        
                        tool_node?.eulerAngles.x = tool.rotation[1].to_rad
                        tool_node?.eulerAngles.y = tool.rotation[2].to_rad
                        tool_node?.eulerAngles.z = tool.rotation[0].to_rad
                        #endif
                    }
                    else
                    {
                        tool_node?.constraints = [SCNConstraint]()
                        //clear_constranints(node: tool_node ?? SCNNode())
                        tool_node?.constraints?.append(SCNReplicatorConstraint(target: robot_by_name(tool.attached_to ?? "").tool_node))
                        //tool_node?.position.x += 1
                        //tool_node?.position.x -= 1
                    }
                }
            }
        }
        
        //Place parts
        if self.avaliable_parts_names.count < self.parts.count //If there are placed parts in workspace
        {
            for part in parts
            {
                if part.is_placed
                {
                    part_node = part.node
                    part.enable_physics = true
                    apply_bit_mask(node: part_node ?? SCNNode(), Workspace.part_bit_mask)
                    part_node?.name = part.name
                    parts_node?.addChildNode(part_node ?? SCNNode())
                    
                    //Set part node position
                    #if os(macOS)
                    part_node?.position = SCNVector3(x: CGFloat(part.location[1]), y: CGFloat(part.location[2]), z: CGFloat(part.location[0]))
                    
                    part_node?.eulerAngles.x = CGFloat(part.rotation[1].to_rad)
                    part_node?.eulerAngles.y = CGFloat(part.rotation[2].to_rad)
                    part_node?.eulerAngles.z = CGFloat(part.rotation[0].to_rad)
                    #else
                    part_node?.position = SCNVector3(x: Float(part.location[1]), y: Float(part.location[2]), z: Float(part.location[0]))
                    
                    part_node?.eulerAngles.x = part.rotation[1].to_rad
                    part_node?.eulerAngles.y = part.rotation[2].to_rad
                    part_node?.eulerAngles.z = part.rotation[0].to_rad
                    #endif
                }
            }
        }
    }
}

public enum WorkspaceObjectType: String, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
    case part = "Part"
}

public enum PositionComponents: String, Equatable, CaseIterable
{
    case location = "Location"
    case rotation = "Rotation"
}

public enum LocationComponents: Equatable, CaseIterable
{
    case x
    case y
    case z
    
    public var info: (text: String, index: Int)
    {
        switch self
        {
        case .x:
            return("X: ", 0)
        case .y:
            return("Y: ", 1)
        case .z:
            return("Z: ", 2)
        }
    }
}

public enum RotationComponents: Equatable, CaseIterable
{
    case r
    case p
    case w
    
    public var info: (text: String, index: Int)
    {
        switch self
        {
        case .r:
            return("R: ", 0)
        case .p:
            return("P: ", 1)
        case .w:
            return("W: ", 2)
        }
    }
}

//MARK: - Structures for workspace preset document handling
public struct WorkspacePreset: Codable
{
    public var robots = [Robot]()
    public var elements = [WorkspaceProgramElementStruct]()
    public var tools = [Tool]()
    public var parts = [Part]()
    
    public var registers: [Float]?
    
    public init()
    {
        robots = [Robot]()
        elements = [WorkspaceProgramElementStruct]()
        tools = [Tool]()
        parts = [Part]()
    }
    
    public init(robots: [Robot], elements: [WorkspaceProgramElementStruct], tools: [Tool], parts: [Part])
    {
        self.robots = robots
        self.elements = elements
        self.tools = tools
        self.parts = parts
    }
    
    /*public init(robots: [RobotStruct], elements: [WorkspaceProgramElementStruct], tools: [ToolStruct], parts: [PartStruct], registers: [Int])
    {
        self.robots = robots
        self.elements = elements
        self.tools = tools
        self.parts = parts
        
        for (index, value) in registers.enumerated()
        {
            /*if index < self.registers.count
            {
                self.registers[safe: index] = value
            }*/
            
            self.registers[safe: index] = value
        }
    }*/
}

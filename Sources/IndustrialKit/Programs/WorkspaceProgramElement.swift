//
//  WorkspaceProgramElement.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 01.04.2022.
//

import Foundation

/**
 A type of workspace program element that is performed to manage means of production.
 
 The element contains some action performed by the production system.
 */
public class WorkspaceProgramElement: Codable, Hashable, Identifiable
{
    public static func == (lhs: WorkspaceProgramElement, rhs: WorkspaceProgramElement) -> Bool
    {
        return lhs.id.uuidString + lhs.element_data.element_type.rawValue == rhs.id.uuidString + rhs.element_data.element_type.rawValue //Identity condition by id plus element type
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id.uuidString + element_data.element_type.rawValue)
    }
    
    public var id = UUID()
    
    ///An element program data.
    public var element_data = WorkspaceProgramElementStruct(element_type: ProgramElementType.perofrmer, performer_type: PerformerType.robot, modifier_type: ModifierType.observer, logic_type: LogicType.jump)
    
    //MARK: - Element init functions
    /**
     Creates a new program element.
     - Parameters:
        - element_type: The program element type.
        - performer_type: The performer element type.
        - modifier_type: The modifier element type.
        - logic_type: The logic element type.
     */
    public init(element_type: ProgramElementType, performer_type: PerformerType, modifier_type: ModifierType, logic_type: LogicType)
    {
        self.element_data = WorkspaceProgramElementStruct(element_type: element_type, performer_type: performer_type, modifier_type: modifier_type, logic_type: logic_type)
    }
    
    /**
     Creates a new performer program element.
     - Parameters:
        - element_type: The program element type.
        - performer_type: The performer element type.
     */
    public init(element_type: ProgramElementType, performer_type: PerformerType)
    {
        self.element_data.element_type = element_type
        self.element_data.performer_type = performer_type
    }
    
    /**
     Creates a new modifier program element.
     - Parameters:
        - element_type: The program element type.
        - modifier_type: The modifier element type.
     */
    public init(element_type: ProgramElementType, modifier_type: ModifierType)
    {
        self.element_data.element_type = element_type
        self.element_data.modifier_type = modifier_type
    }
    
    /**
     Creates a new logic program element.
     - Parameters:
        - element_type: The program element type.
        - logic_type: The logic element type.
     */
    public init(element_type: ProgramElementType, logic_type: LogicType)
    {
        self.element_data.logic_type = logic_type
        self.element_data.logic_type = logic_type
    }
    
    /**
     Creates a new program element by structure.
     - Parameters:
        - element_struct: A program element structure.
     */
    public init(element_struct: WorkspaceProgramElementStruct)
    {
        self.element_data = element_struct
    }
    
    //MARK: - Visual data output
    ///A subtype string for a specific type.
    public var subtype: String
    {
        var subtype = String()
        
        switch element_data.element_type
        {
        case .perofrmer:
            subtype = "\(self.element_data.performer_type.rawValue)"
        case .modifier:
            subtype = "\(self.element_data.modifier_type.rawValue)"
        case .logic:
            subtype = "\(self.element_data.logic_type.rawValue)"
        }
        
        return subtype
    }
    
    ///A string for the text in program element card.
    public var info: String
    {
        var info = String()
        
        switch element_data.element_type
        {
        case .perofrmer:
            switch element_data.performer_type
            {
            case .robot:
                if element_data.robot_name != ""
                {
                    info = "\(element_data.robot_name) – \(element_data.program_name)"
                }
                else
                {
                    info = "No robot selected"
                }
            case .tool:
                if element_data.tool_name != ""
                {
                    info = "\(element_data.tool_name) – \(element_data.program_name)"
                }
                else
                {
                    info = "No tool selected"
                }
            }
        case .modifier:
            switch element_data.modifier_type
            {
            case .observer:
                info = "Output from \(element_data.object_name)"
            case .mover:
                if element_data.is_push
                {
                    info = "Push previous to \(element_data.register_index)"
                }
                else
                {
                    info = "Pop from \(element_data.register_index) to next"
                }
            case .changer:
                info = "Module – \(element_data.module_name)"
            }
        case .logic:
            switch element_data.logic_type
            {
            case .jump:
                if element_data.target_mark_name != ""
                {
                    info = "To mark – \(element_data.target_mark_name)"
                }
                else
                {
                    info = "No mark selected"
                }
            case .mark:
                if element_data.mark_name != ""
                {
                    info = element_data.mark_name
                }
                else
                {
                    info = "Unnamed"
                }
            case .equal:
                info = "Compare previous with \(element_data.compared_value)"
            case .unequal:
                info = "Compare previous with \(element_data.compared_value)"
            }
        }
        
        return info
    }
    
    ///An index of the target mark element for the jump element.
    public var target_element_index = 0
}

//MARK: - Models of program element data
///Structure for workspace program element data.
public struct WorkspaceProgramElementStruct: Codable, Hashable
{
    ///A program element type.
    public var element_type: ProgramElementType = .perofrmer
    
    //MARK: For Performer
    ///A performer element type.
    public var performer_type: PerformerType = .robot
    
    ///A name of performed robot.
    public var robot_name = String()
    
    ///A name of performed tool.
    public var tool_name = String()
    
    ///A name of program to perform.
    public var program_name = String()
    
    //MARK: For Modififcator
    ///A modificator name.
    public var modifier_type: ModifierType = .observer
    
    ///An observable workspace object name.
    public var object_name = String()
    
    ///A changer module name.
    public var module_name = String()
    
    ///A push/pop selector for changer.
    public var is_push = true
    
    ///A register index for hold info data.
    public var register_index = 0

    //MARK: For logic
    ///A logic element type.
    public var logic_type: LogicType = .jump
    
    ///A target mark name.
    public var mark_name = String()
    
    ///A target mark name.
    public var target_mark_name = String()
    
    ///A value to compare for element.
    public var compared_value: Float = 0
    
    //MARK: Init function
    ///Creates a new program element with default values.
    public init()
    {
        element_type = .perofrmer
        
        performer_type = .robot
        
        robot_name = String()
        tool_name = String()
        
        program_name = String()
        
        modifier_type = .observer
        target_mark_name = String()
        
        logic_type = .jump
        mark_name = String()
    }
    
    /**
     Creates a new program element structure.
     - Parameters:
        - element_type: The program element type.
        - performer_type: The performer program element type.
        - modifier_type: The modifier program element type.
        - logic_type: The logic program element type.
     */
    public init(element_type: ProgramElementType, performer_type: PerformerType, modifier_type: ModifierType, logic_type: LogicType)
    {
        self.element_type = element_type
        self.performer_type = performer_type
        self.modifier_type = modifier_type
        self.logic_type = logic_type
    }
}

//MARK: - Type enums
///A program element type enum.
public enum ProgramElementType: String, Codable, Equatable, CaseIterable
{
    case perofrmer = "Performer"
    case modifier = "Modifier"
    case logic = "Logic"
}

///A performer program element type enum.
public enum PerformerType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
}

///A modifier program element type enum.
public enum ModifierType: String, Codable, Equatable, CaseIterable
{
    case observer = "Observer"
    case mover = "Mover"
    case changer = "Changer"
}

///A logic program element type enum.
public enum LogicType: String, Codable, Equatable, CaseIterable
{
    case jump = "Jump"
    case mark = "Mark"
    case equal = "Equal"
    case unequal = "Unequal"
}

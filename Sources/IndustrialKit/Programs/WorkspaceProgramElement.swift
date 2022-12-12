//
//  WorkspaceProgramElement.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.04.2022.
//

import Foundation

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
    public var element_data = WorkspaceProgramElementStruct(element_type: ProgramElementType.perofrmer, performer_type: PerformerType.robot, modificator_type: ModificatorType.observer, logic_type: LogicType.jump)
    
    //MARK: - Element init functions
    public init(element_type: ProgramElementType, performer_type: PerformerType, modificator_type: ModificatorType, logic_type: LogicType)
    {
        self.element_data = WorkspaceProgramElementStruct(element_type: element_type, performer_type: performer_type, modificator_type: modificator_type, logic_type: logic_type)
    }
    
    public init(element_type: ProgramElementType, performer_type: PerformerType)
    {
        self.element_data.element_type = element_type
        self.element_data.performer_type = performer_type
    }
    
    public init(element_type: ProgramElementType, modificator_type: ModificatorType)
    {
        self.element_data.element_type = element_type
        self.element_data.modificator_type = modificator_type
    }
    
    public init(element_type: ProgramElementType, logic_type: LogicType)
    {
        self.element_data.logic_type = logic_type
        self.element_data.logic_type = logic_type
    }
    
    public init(element_struct: WorkspaceProgramElementStruct) //Init by element struct
    {
        self.element_data = element_struct
    }
    
    //MARK: - Visual data output
    public var subtype: String //Subtype string for a specific type
    {
        var subtype = String()
        
        switch element_data.element_type
        {
        case .perofrmer:
            subtype = "\(self.element_data.performer_type.rawValue)"
        case .modificator:
            subtype = "\(self.element_data.modificator_type.rawValue)"
        case .logic:
            subtype = "\(self.element_data.logic_type.rawValue)"
        }
        
        return subtype
    }
    
    public var info: String //String for the text in program element card
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
                    info = "Name – \(element_data.robot_name)"
                }
                else
                {
                    info = "No robot selected"
                }
            case .tool:
                if element_data.tool_name != ""
                {
                    info = "Name – \(element_data.tool_name)"
                }
                else
                {
                    info = "No tool selected"
                }
            }
        case .modificator:
            switch element_data.modificator_type
            {
            case .observer:
                info = "None"
            case .changer:
                info = "None"
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
                info = "None"
            case .unequal:
                info = "None"
            }
        }
        
        return info
    }
    
    public var target_element_index = 0 //The index of the target mark element for the jump element.
}

//MARK: - Models of program element data
public struct WorkspaceProgramElementStruct: Codable, Hashable
{
    public var element_type: ProgramElementType = .perofrmer
    
    //MARK: For Performer
    public var performer_type: PerformerType = .robot
    
    public var robot_name = String()
    public var tool_name = String()
    
    public var program_name = String()
    
    //MARK: For Modififcator
    public var modificator_type: ModificatorType = .observer
    
    public var target_mark_name = String()

    //MARK: For logic
    public var logic_type: LogicType = .jump
    
    public var mark_name = String()
    
    //MARK: Init function
    public init()
    {
        element_type = .perofrmer
        
        performer_type = .robot
        
        robot_name = String()
        tool_name = String()
        
        program_name = String()
        
        modificator_type = .observer
        target_mark_name = String()
        
        logic_type = .jump
        mark_name = String()
    }
    
    public init(element_type: ProgramElementType, performer_type: PerformerType, modificator_type: ModificatorType, logic_type: LogicType)
    {
        self.element_type = element_type
        self.performer_type = performer_type
        self.modificator_type = modificator_type
        self.logic_type = logic_type
    }
}

//MARK: - Type enums
public enum ProgramElementType: String, Codable, Equatable, CaseIterable
{
    case perofrmer = "Performer"
    case modificator = "Modificator"
    case logic = "Logic"
}

public enum PerformerType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
}

public enum ModificatorType: String, Codable, Equatable, CaseIterable
{
    case observer = "Observer"
    case changer = "Changer"
}

public enum LogicType: String, Codable, Equatable, CaseIterable
{
    case jump = "Jump"
    case mark = "Mark"
    case equal = "Equal"
    case unequal = "Unequal"
}

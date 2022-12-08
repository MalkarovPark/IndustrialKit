//
//  WorkspaceProgramElement.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.04.2022.
//

import Foundation

class WorkspaceProgramElement: Codable, Hashable, Identifiable
{
    static func == (lhs: WorkspaceProgramElement, rhs: WorkspaceProgramElement) -> Bool
    {
        return lhs.id.uuidString + lhs.element_data.element_type.rawValue == rhs.id.uuidString + rhs.element_data.element_type.rawValue //Identity condition by id plus element type
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(id.uuidString + element_data.element_type.rawValue)
    }
    
    var id = UUID()
    var element_data = workspace_program_element_struct(element_type: .perofrmer, performer_type: .robot, modificator_type: .observer, logic_type: .jump)
    
    //MARK: - Element init functions
    init(element_type: ProgramElementType, performer_type: PerformerType, modificator_type: ModificatorType, logic_type: LogicType)
    {
        self.element_data = workspace_program_element_struct(element_type: element_type, performer_type: performer_type, modificator_type: modificator_type, logic_type: logic_type)
    }
    
    init(element_type: ProgramElementType, performer_type: PerformerType)
    {
        self.element_data.element_type = element_type
        self.element_data.performer_type = performer_type
    }
    
    init(element_type: ProgramElementType, modificator_type: ModificatorType)
    {
        self.element_data.element_type = element_type
        self.element_data.modificator_type = modificator_type
    }
    
    init(element_type: ProgramElementType, logic_type: LogicType)
    {
        self.element_data.logic_type = logic_type
        self.element_data.logic_type = logic_type
    }
    
    init(element_struct: workspace_program_element_struct) //Init by element struct
    {
        self.element_data = element_struct
    }
    
    //MARK: - Visual data output
    var subtype: String //Subtype string for a specific type
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
    
    var info: String //String for the text in program element card
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
struct workspace_program_element_struct: Codable, Hashable
{
    var element_type: ProgramElementType = .perofrmer
    
    //MARK: For Performer
    var performer_type: PerformerType = .robot
    
    var robot_name = String()
    var tool_name = String()
    
    var program_name = String()
    
    //MARK: For Modififcator
    var modificator_type: ModificatorType = .observer
    
    var target_mark_name = String()

    //MARK: For logic
    var logic_type: LogicType = .jump
    
    var mark_name = String()
}

//MARK: - Type enums
enum ProgramElementType: String, Codable, Equatable, CaseIterable
{
    case perofrmer = "Performer"
    case modificator = "Modificator"
    case logic = "Logic"
}

enum PerformerType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
}

enum ModificatorType: String, Codable, Equatable, CaseIterable
{
    case observer = "Observer"
    case changer = "Changer"
}

enum LogicType: String, Codable, Equatable, CaseIterable
{
    case jump = "Jump"
    case mark = "Mark"
    case equal = "Equal"
    case unequal = "Unequal"
}

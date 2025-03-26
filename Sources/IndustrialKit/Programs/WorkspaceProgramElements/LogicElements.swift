//
//  LogicElements.swift
//  IndustrialKit
//
//  Created by Artem on 12.10.2024.
//

import Foundation
import SwiftUI

///Controls the order of performing of program elements through conditional and unconditional transitions to given labels.
public class LogicElement: WorkspaceProgramElement
{
    public override var title: String
    {
        return "Logic"
    }
    
    public override var color: Color
    {
        return .gray
    }
}

///Jumps to the specified mark.
public class JumpLogicElement: LogicElement
{
    /// A name of the target mark.
    public var target_mark_name = ""
    
    /// An index of the target mark element.
    public var target_element_index = 0
    
    public override var info: String
    {
        if target_mark_name != ""
        {
            return "Jump to \(target_mark_name)"
        }
        else
        {
            return "No marks to jump"
        }
    }
    
    public override var symbol_name: String
    {
        return "arrowshape.zigzag.forward"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return ""
    }
    
    // File handling
    // Data [target]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .jump_logic
    }
    
    public override var data_count: Int
    {
        return 1
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        target_mark_name = element_struct.data[0]
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .jump_logic, data: [target_mark_name])
    }
}

///Jumps to the specified mark when the conditions are met.
public class ComparatorLogicElement: LogicElement
{
    /// A type of compare.
    public var compare_type: CompareType = .equal
    
    /// An index of register with compared value.
    public var value_index = 0
    
    /// An index of register with compared value.
    public var value2_index = 0
    
    /// A name of the target mark.
    public var target_mark_name = ""
    
    /// An index of the target mark element.
    public var target_element_index = 0
    
    public override var info: String
    {
        if target_mark_name != ""
        {
            return "Jump to \(target_mark_name) if value of \(value_index) \(compare_type.rawValue) value of \(value2_index)"
        }
        else
        {
            return "No marks to jump"
        }
    }
    
    public override var symbol_name: String
    {
        return "alt"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return ""
    }
    
    // File handling
    // Data [compare, value, value2, target]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .comparator_logic
    }
    
    public override var data_count: Int
    {
        return 4
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        compare_type = compare_from_string(element_struct.data[0])
        
        value_index = Int(element_struct.data[1]) ?? 0
        value2_index = Int(element_struct.data[2]) ?? 0
        
        target_mark_name = element_struct.data[3]
        
        func compare_from_string(_ string: String) -> CompareType
        {
            switch string
            {
            case "=":
                return .equal
            case "≠":
                return .unequal
            case ">":
                return .greater
            case "⩾":
                return .greater_equal
            case "<":
                return .less
            case "⩽":
                return .less_equal
            default:
                return .equal
            }
        }
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .comparator_logic, data: [compare_type.rawValue, String(value_index), String(value2_index), target_mark_name])
    }
}

///A logic program element compare type enum.
public enum CompareType: String, Codable, Equatable, CaseIterable
{
    case equal = "="
    case unequal = "≠"
    case greater = ">"
    case greater_equal = "⩾"
    case less = "<"
    case less_equal = "⩽"
    
    func compare(_ value1: Float, _ value2: Float) -> Bool
    {
        switch self
        {
        case .equal:
            return value1 == value2
        case .unequal:
            return value1 != value2
        case .greater:
            return value1 > value2
        case .greater_equal:
            return value1 >= value2
        case .less:
            return value1 < value2
        case .less_equal:
            return value1 <= value2
        }
    }
}

///A logic mark to jump.
public class MarkLogicElement: LogicElement
{
    /// A target mark name.
    public var name = "None"
    
    public override var title: String
    {
        return "Mark"
    }
    
    public override var info: String
    {
        return name
    }
    
    public override var symbol_name: String
    {
        return "record.circle"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return ""
    }
    
    // File handling
    // Data [name]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .mark_logic
    }
    
    public override var data_count: Int
    {
        return 1
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        name = element_struct.data[0]
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .mark_logic, data: [name])
    }
}

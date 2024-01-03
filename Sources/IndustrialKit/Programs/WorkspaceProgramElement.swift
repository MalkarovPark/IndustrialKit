//
//  WorkspaceProgramElement.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 01.04.2022.
//

import Foundation
import SwiftUI

/**
 A type of workspace program element that is performed to manage means of production.
 
 The element contains some action performed by the production system.
 */
public class WorkspaceProgramElement: Hashable, Identifiable
{
    public static func == (lhs: WorkspaceProgramElement, rhs: WorkspaceProgramElement) -> Bool
    {
        return lhs.id == rhs.id //Identity condition by id plus element type
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var id = UUID()
    
    public init()
    {
        
    }
    
    ///Inits workspace program element by appropriate codable structure.
    public init(element_struct: WorkspaceProgramElementStruct)
    {
        if element_struct.identifier == identifier && element_struct.data.count == data_count
        {
            data_from_struct(element_struct)
        }
    }
    
    ///Inits workspace program element by appropriate identifier
    public init(element_identifier: WorkspaceProgramElementIdentifier)
    {
        data_from_struct(WorkspaceProgramElementStruct(identifier: element_identifier, data: [String]()))
    }
    
    ///Element type identifier
    public var identifier: WorkspaceProgramElementIdentifier?
    {
        return nil
    }
    
    ///Element data components count for type
    public var data_count: Int
    {
        return 0
    }
    
    /**
     Inits program element by struct.
     - Parameters:
        - struct: Appropriate codable struct.
     */
    public func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        
    }
    
    ///A string for the title in program element card.
    open var title: String
    {
        return "Title"
    }
    
    ///A string for the text in program element card.
    open var info: String
    {
        return "Info"
    }
    
    ///An image name for program element card.
    open var image_name: String
    {
        return "app"
    }
    
    ///An image for program element card.
    public var image: Image
    {
        return Image(systemName: image_name)
    }
    
    ///A color for the program element card.
    open var color: Color
    {
        return Color(.gray)
    }
    
    //MARK: - Work with file system
    ///Converts tool data to codable tool struct.
    public var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct()
    }
}

//MARK: - Performer program elements
public class PerformerElement: WorkspaceProgramElement
{
    ///A name of workspace object.
    public var object_name = ""
    
    ///Determines if workspace object is perform a single action.
    public var is_single_perfrom = false
    
    ///Determines if workspace object is perform a program by index from registers.
    public var is_program_by_index = false
    
    ///A name of program to perfrom.
    public var program_name = ""
    
    ///An index of register with index of program to perform.
    public var program_index = 0
    
    public override var info: String
    {
        if object_name != ""
        {
            if !is_single_perfrom
            {
                if !is_program_by_index
                {
                    if program_name != ""
                    {
                        return "\(object_name) – \(program_name)"
                    }
                    else
                    {
                        return "No programs to perform"
                    }
                }
                else
                {
                    return "Program index from \(program_index)"
                }
            }
            else
            {
                return "Perform from registers"
            }
        }
        else
        {
            return "No objects placed"
        }
    }
    
    public override var color: Color
    {
        return .green
    }
}

///Performs program or position on selected robot.
public class RobotPerformerElement: PerformerElement
{
    ///Index of *x* location component.
    public var x_index = 0
    ///Index of *y* location component.
    public var y_index = 0
    ///Index of *z* location component.
    public var z_index = 0
    
    ///Index of *r* rotation component.
    public var r_index = 0
    ///Index of *p* rotation component.
    public var p_index = 0
    ///Index of *w* rotation component.
    public var w_index = 0
    
    ///Index of movement speed.
    public var speed_index = 0
    
    public override var title: String
    {
        return "Robot"
    }
    
    public override var image_name: String
    {
        return "r.square"
    }
    
    //File handling
    //Data [robot name, program name, program index, is single, is by index, x, y, z, r, p, w, speed]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .robot_performer
    }
    
    public override var data_count: Int
    {
        return 12
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        object_name = element_struct.data[0]
        
        program_name = element_struct.data[1]
        program_index = Int(element_struct.data[2]) ?? 0
        is_single_perfrom = Bool(element_struct.data[3]) ?? false
        is_program_by_index = Bool(element_struct.data[4]) ?? false
        
        x_index = Int(element_struct.data[5]) ?? 0
        y_index = Int(element_struct.data[6]) ?? 0
        z_index = Int(element_struct.data[7]) ?? 0
        
        r_index = Int(element_struct.data[8]) ?? 0
        p_index = Int(element_struct.data[9]) ?? 0
        w_index = Int(element_struct.data[10]) ?? 0
        
        speed_index = Int(element_struct.data[11]) ?? 0
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        var info = [String]()
        
        info.append(object_name)
        
        info.append(program_name)
        info.append(String(program_index))
        info.append(String(is_single_perfrom))
        info.append(String(is_program_by_index))
        
        info.append(String(x_index))
        info.append(String(y_index))
        info.append(String(z_index))
        
        info.append(String(r_index))
        info.append(String(p_index))
        info.append(String(w_index))
        
        info.append(String(speed_index))
        
        return WorkspaceProgramElementStruct(identifier: .robot_performer, data: info)
    }
}

///Performs program or position on selected tool.
public class ToolPerformerElement: PerformerElement
{
    ///Index of operation code location component.
    public var opcode_index = 0
    
    public override var title: String
    {
        return "Tool"
    }
    
    public override var image_name: String
    {
        return "hammer"
    }
    
    //File handling
    //Data [tool name, program name, program index, is single, is by index, opcode]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .tool_performer
    }
    
    public override var data_count: Int
    {
        return 6
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        object_name = element_struct.data[0]
        
        program_name = element_struct.data[1]
        program_index = Int(element_struct.data[2]) ?? 0
        is_single_perfrom = Bool(element_struct.data[3]) ?? false
        is_program_by_index = Bool(element_struct.data[4]) ?? false
        
        opcode_index = Int(element_struct.data[5]) ?? 0
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        var info = [String]()
        
        info.append(object_name)
        
        info.append(program_name)
        info.append(String(program_index))
        info.append(String(is_single_perfrom))
        info.append(String(is_program_by_index))
        
        info.append(String(opcode_index))
        
        return WorkspaceProgramElementStruct(identifier: .tool_performer, data: info)
    }
}

//MARK: - Modifier elements
public class ModifierElement: WorkspaceProgramElement
{
    public override var title: String
    {
        return "Modifier"
    }
    
    public override var color: Color
    {
        return .pink
    }
}

///Moves data between registers.
public class MoverModifierElement: ModifierElement
{
    ///A type of copy
    public var move_type: ModifierCopyType = .duplicate
    
    ///An index of value to copy.
    public var from_index = 0
    
    ///An index of target register.
    public var to_index = 0
    
    public override var info: String
    {
        return "\(move_type.rawValue) from \(from_index) to \(to_index)"
    }
    
    public override var image_name: String
    {
        switch move_type
        {
        case .duplicate:
            return "plus.square.on.square"
        case .move:
            return "square.on.square.dashed"
        }
    }
    
    //File handling
    //Data [type, from, to]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .mover_modifier
    }
    
    public override var data_count: Int
    {
        return 3
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        move_type = type_from_string(element_struct.data[0])
        from_index = Int(element_struct.data[1]) ?? 0
        to_index = Int(element_struct.data[2]) ?? 0
        
        func type_from_string(_ string: String) -> ModifierCopyType
        {
            switch string
            {
            case "Duplicate":
                return .duplicate
            case "Move":
                return .move
            default:
                return .duplicate
            }
        }
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .mover_modifier, data: [move_type.rawValue, String(from_index), String(to_index)])
    }
}

///Writes data to selected register.
public class WriterModifierElement: ModifierElement
{
    ///A writable value.
    public var value: Float = 0
    
    ///An index of register to write.
    public var to_index = 0
    
    public override var info: String
    {
        return "Write \(value) to \(to_index)"
    }
    
    public override var image_name: String
    {
        return "square.and.pencil"
    }
    
    //File handling
    //Data [value, to]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .writer_modifier
    }
    
    public override var data_count: Int
    {
        return 2
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        value = Float(element_struct.data[0]) ?? 0
        to_index = Int(element_struct.data[1]) ?? 0
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .writer_modifier, data: [String(value), String(to_index)])
    }
}

public class MathModifierElement: ModifierElement
{
    ///A type of compare.
    public var operation: MathType = .add
    
    ///An index of register with compared value.
    public var value_index = 0
    
    ///An index of register with compared value.
    public var value2_index = 0
    
    public override var info: String
    {
        return "Value of \(value_index) \(operation.rawValue) value of \(value2_index)"
    }
    
    public override var image_name: String
    {
        return "function"
    }
    
    //File handling
    //Data [operation, value, value2]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .math_modifier
    }
    
    public override var data_count: Int
    {
        return 3
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        operation = operation_from_string(element_struct.data[0])
        
        value_index = Int(element_struct.data[1]) ?? 0
        value2_index = Int(element_struct.data[2]) ?? 0
        
        func operation_from_string(_ string: String) -> MathType
        {
            switch string
            {
            case "+":
                return .add
            case "-":
                return .substract
            case "·":
                return .multiply
            case "÷":
                return .divide
            case "^":
                return .power
            default:
                return .add
            }
        }
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .math_modifier, data: [operation.rawValue, String(value_index), String(value2_index)])
    }
}

///A math program element operation type enum.
public enum MathType: String, Codable, Equatable, CaseIterable
{
    case add = "+"
    case substract = "-"
    case multiply = "·"
    case divide = "÷"
    case power = "^"
    
    func operation(_ value1: inout Float, _ value2: Float)
    {
        switch self
        {
        case .add:
            value1 += value2
        case .substract:
            value1 -= value2
        case .multiply:
            value1 *= value2
        case .divide:
            value1 /= (value2 != 0 ? value2 : 1)
        case .power:
            value1 = pow(value1, value2)
        }
    }
}

///Changes registers by changer module.
public class ChangerModifierElement: ModifierElement
{
    ///A name of modifier module.
    public var module_name = ""
    
    public override var info: String
    {
        return "Module – \(module_name)"
    }
    
    public override var image_name: String
    {
        return "wand.and.rays"
    }
    
    //File handling
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .changer_modifier
    }
    
    public override var data_count: Int
    {
        return 1
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        module_name = element_struct.data[0]
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .changer_modifier, data: [module_name])
    }
}

///Pushes info code from tool to registers.
public class ObserverModifierElement: ModifierElement
{
    ///A name of object to observe output.
    public var object_name = ""
    
    ///An index of target register.
    public var from_indices = [Int]()
    public var to_indices = [Int]()
    
    public override var info: String
    {
        if from_indices.count > 0
        {
            return "Observe form \(object_name) of \(from_indices.map { String($0) }.joined(separator: ", ")) to \(to_indices.map { String($0) }.joined(separator: ", "))"
        }
        else
        {
            return "No items to observe"
        }
    }
    
    public override var image_name: String
    {
        return "loupe"
    }
    
    //File handling
    //Data [name, from indices, to indices]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .observer_modifier
    }
    
    public override var data_count: Int
    {
        return 3
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        object_name = element_struct.data[0]
        from_indices = string_to_indices(element_struct.data[1])
        to_indices = string_to_indices(element_struct.data[2])
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .observer_modifier, data: [object_name, indices_to_string(from_indices), indices_to_string(to_indices)])
    }
    
    private func string_to_indices(_ string: String) -> [Int]
    {
        return string.components(separatedBy: "|").compactMap { Int($0) }
    }
    
    private func indices_to_string(_ indices: [Int]) -> String
    {
        return indices.map { String($0) }.joined(separator: "|")
    }
}

///Cleares data in all registers.
public class CleanerModifierElement: ModifierElement
{
    public override var info: String
    {
        return "Clear all registers"
    }
    
    public override var image_name: String
    {
        return "clear"
    }
    
    //File handling
    //Data |nothing|
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .cleaner_modifier
    }
    
    public override var data_count: Int
    {
        return 0
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        //Nothing...
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .cleaner_modifier, data: [String]())
    }
}

//MARK: - Logic elements
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
    ///A name of the target mark.
    public var target_mark_name = ""
    
    ///An index of the target mark element.
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
    
    public override var image_name: String
    {
        return "arrowshape.zigzag.forward"
    }
    
    //File handling
    //Data [target]
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
    ///A type of compare.
    public var compare_type: CompareType = .equal
    
    ///An index of register with compared value.
    public var value_index = 0
    
    ///An index of register with compared value.
    public var value2_index = 0
    
    ///A name of the target mark.
    public var target_mark_name = ""
    
    ///An index of the target mark element.
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
    
    public override var image_name: String
    {
        return "alt"
    }
    
    //File handling
    //Data [compare, value, value2, target]
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
    ///A target mark name.
    public var name = "None"
    
    public override var title: String
    {
        return "Mark"
    }
    
    public override var info: String
    {
        return name
    }
    
    public override var image_name: String
    {
        return "record.circle"
    }
    
    //File handling
    //Data [name]
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

//MARK: - Tool structure for workspace preset document handling
///A codable tool struct.
public struct WorkspaceProgramElementStruct: Codable
{
    public var identifier: WorkspaceProgramElementIdentifier?
    
    public var data: [String]
    
    public init()
    {
        data = [String]()
    }
    
    public init(identifier: WorkspaceProgramElementIdentifier, data: [String])
    {
        self.identifier = identifier
        self.data = data
    }
}

public enum ModifierCopyType: String, Codable, Equatable, CaseIterable
{
    case duplicate = "Duplicate"
    case move = "Move"
}

///A workspace program element type enum.
public enum WorkspaceProgramElementIdentifier: Codable, Equatable, CaseIterable
{
    //Performer
    case robot_performer
    case tool_performer
    
    //Modifier
    case mover_modifier
    case writer_modifier
    case math_modifier
    case changer_modifier
    case observer_modifier
    case cleaner_modifier
    
    //Logic
    case jump_logic
    case comparator_logic
    case mark_logic
}

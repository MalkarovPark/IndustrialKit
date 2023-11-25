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
public class WorkspaceProgramElement: Codable, Hashable, Identifiable
{
    public static func == (lhs: WorkspaceProgramElement, rhs: WorkspaceProgramElement) -> Bool
    {
        return lhs.id == rhs.id //Identity condition by id plus element type
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public init()
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
}

//MARK: - Performer program elements
public class PerformerElement: WorkspaceProgramElement
{
    ///A name of workspace object.
    public var object_name = ""
    
    ///Determines if workspace object is perform a single action.
    public var is_single_perfrom = true
    
    ///A name of program to perfrom.
    public var program_name = ""
    
    ///An index of register with index of program to perform.
    public var program_index_from = 0
    
    ///Determines if workspace object is perform a program by index from registers.
    public var is_program_by_index = false
    
    public override var info: String
    {
        if !is_single_perfrom
        {
            if !is_program_by_index
            {
                return "\(object_name) – \(program_name)"
            }
            else
            {
                return "Program index from \(program_index_from)"
            }
        }
        else
        {
            return "Perform from registers"
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
    
    public override var title: String
    {
        return "Robot"
    }
    
    public override var image_name: String
    {
        return "r.square"
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
    ///An index of value to move.
    public var from_index = 0
    
    ///An index of target register.
    public var to_index = 0
    
    public override var info: String
    {
        return "Move from \(from_index) to \(to_index)"
    }
    
    public override var image_name: String
    {
        return "square.on.square.dashed"
    }
}

///Copies data from register to target register.
public class CopyModifierElement: ModifierElement
{
    ///An index of value to copy.
    public var from_index = 0
    
    ///An index of target register.
    public var to_index = 0
    
    public override var info: String
    {
        return "Copy from \(from_index) to \(to_index)"
    }
    
    public override var image_name: String
    {
        return "plus.square.on.square"
    }
}

///Writes data to selected register.
public class WriteModifierElement: ModifierElement
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
}

///Cleares data in all registers.
public class ClearModifierElement: ModifierElement
{
    public override var info: String
    {
        return "Clear all registers"
    }
    
    public override var image_name: String
    {
        return "clear"
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
}

///Pushes info code from tool to registers.
public class ObserverModifierElement: ModifierElement
{
    ///A name of object to observe output.
    public var object_name = ""
    
    ///An index of target register.
    public var to_index = 0
    
    public override var info: String
    {
        return "Observe form \(object_name) to \(to_index)"
    }
    
    public override var image_name: String
    {
        return "loupe"
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

///Jumps to the specified mark when the conditions are met
public class ComparatorLogicElement: LogicElement
{
    ///An index of register with compared value.
    public var value_index = 0
    
    ///An index of register with compared value.
    public var second_value_index = 0
    
    ///A type of compare.
    public var compare_type: CompareType = .equal
    
    ///A name of the target mark.
    public var target_mark_name = ""
    
    ///An index of the target mark element.
    public var target_element_index = 0
    
    public override var info: String
    {
        return "Jump to \(target_mark_name) if value of \(value_index) \(compare_type.rawValue) value of \(second_value_index)"
    }
    
    public override var image_name: String
    {
        return "arrowshape.bounce.forward"
    }
}

///A logic mark to jump.
public class MarkLogicElement: LogicElement
{
    ///A target mark name.
    public var name = "None"
    
    public override var info: String
    {
        return name
    }
    
    public override var image_name: String
    {
        return "record.circle"
    }
}

///A logic program element type enum.
public enum CompareType: String, Codable, Equatable, CaseIterable
{
    case equal = "="
    case unequal = "≠"
    case greater = ">"
    case greater_equal = "⩾"
    case less = "<"
    case less_equal = "⩽"
}

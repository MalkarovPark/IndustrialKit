//
//  PerformerElements.swift
//  IndustrialKit
//
//  Created by Artem on 12.10.2024.
//

import Foundation
import SwiftUI

///Initiates operations on controllable devices such as robots or tools.
public class PerformerElement: WorkspaceProgramElement
{
    /// A name of workspace object.
    public var object_name = ""
    
    /// Determines if workspace object is perform a single action.
    public var is_single_perfrom = false
    
    /// Determines if workspace object is perform a program by index from registers.
    public var is_program_by_index = false
    
    /// A name of program to perfrom.
    public var program_name = ""
    
    /// An index of register with index of program to perform.
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
    /// Index of *x* location component.
    public var x_index = 0
    /// Index of *y* location component.
    public var y_index = 0
    /// Index of *z* location component.
    public var z_index = 0
    
    /// Index of *r* rotation component.
    public var r_index = 0
    /// Index of *p* rotation component.
    public var p_index = 0
    /// Index of *w* rotation component.
    public var w_index = 0
    
    /// Index of movement speed.
    public var speed_index = 0
    
    /// Index of movement type.
    public var type_index = 0
    
    public override var title: String
    {
        return "Robot"
    }
    
    public override var symbol_name: String
    {
        return "r.square"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        if !is_single_perfrom
        {
            if !is_program_by_index
            {
                return "p: r.(\(object_name)).(\(program_name))"
            }
            else
            {
                return "p: r.(\(object_name)).index.[\(program_index)]"
            }
        }
        else
        {
            return "p: r.(\(object_name)).single.[\(x_index), \(y_index), \(z_index), \(r_index), \(p_index), \(w_index), \(speed_index), \(type_index)]"
        }
    }
    
    // File handling
    // Data [<#robot name#>, <#program name#>, <#program index#>, <#is single#>, <#is by index#>, <#x#>, <#y#>, <#z#>, <#r#>, <#p#>, <#w#>, <#speed#>, <#type#>]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .robot_performer
    }
    
    public override var data_count: Int
    {
        return 13
    }
    
    public override func data_from_array(_ data: [String])
    {
        object_name = data[0]
        
        program_name = data[1]
        program_index = Int(data[2]) ?? 0
        is_single_perfrom = Bool(data[3]) ?? false
        is_program_by_index = Bool(data[4]) ?? false
        
        x_index = Int(data[5]) ?? 0
        y_index = Int(data[6]) ?? 0
        z_index = Int(data[7]) ?? 0
        
        r_index = Int(data[8]) ?? 0
        p_index = Int(data[9]) ?? 0
        w_index = Int(data[10]) ?? 0
        
        speed_index = Int(data[11]) ?? 0
        type_index = Int(data[12]) ?? 0
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
        info.append(String(type_index))
        
        return WorkspaceProgramElementStruct(identifier: .robot_performer, data: info)
    }
}

///Performs program or position on selected tool.
public class ToolPerformerElement: PerformerElement
{
    /// Index of operation code location component.
    public var opcode_index = 0
    
    public override var title: String
    {
        return "Tool"
    }
    
    public override var symbol_name: String
    {
        return "hammer"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        if !is_single_perfrom
        {
            if !is_program_by_index
            {
                return "p: t.(\(object_name)).(\(program_name))"
            }
            else
            {
                return "p: t.(\(object_name)).index.[\(program_index)]"
            }
        }
        else
        {
            return "p: t.(\(object_name)).single.[\(opcode_index)]"
        }
    }
    
    // File handling
    // Data [<#tool name#>, <#program name#>, <#program index#>, <#is single#>, <#is by index#>, <#opcode#>]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .tool_performer
    }
    
    public override var data_count: Int
    {
        return 6
    }
    
    public override func data_from_array(_ data: [String])
    {
        object_name = data[0]
        
        program_name = data[1]
        program_index = Int(data[2]) ?? 0
        is_single_perfrom = Bool(data[3]) ?? false
        is_program_by_index = Bool(data[4]) ?? false
        
        opcode_index = Int(data[5]) ?? 0
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

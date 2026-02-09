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
    public init(
        object_name: String = "",
        is_single_perfrom: Bool = false,
        is_program_by_index: Bool = false,
        program_name: String = "",
        program_index: Int = 0
    )
    {
        self.object_name = object_name
        self.is_single_perfrom = is_single_perfrom
        self.is_program_by_index = is_program_by_index
        self.program_name = program_name
        self.program_index = program_index
        
        super.init()
    }
    
    /// A name of workspace object.
    @Published public var object_name = ""
    
    /// Determines if workspace object is perform a single action.
    @Published public var is_single_perfrom = false
    
    /// Determines if workspace object is perform a program by index from registers.
    @Published public var is_program_by_index = false
    
    /// A name of program to perfrom.
    @Published public var program_name = ""
    
    /// An index of register with index of program to perform.
    @Published public var program_index = 0
    
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
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case object_name, is_single_perfrom, is_program_by_index, program_name, program_index
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object_name = try container.decodeIfPresent(String.self, forKey: .object_name) ?? ""
        self.is_single_perfrom = try container.decodeIfPresent(Bool.self, forKey: .is_single_perfrom) ?? false
        self.is_program_by_index = try container.decodeIfPresent(Bool.self, forKey: .is_program_by_index) ?? false
        self.program_name = try container.decodeIfPresent(String.self, forKey: .program_name) ?? ""
        self.program_index = try container.decodeIfPresent(Int.self, forKey: .program_index) ?? 0
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(object_name, forKey: .object_name)
        try container.encode(is_single_perfrom, forKey: .is_single_perfrom)
        try container.encode(is_program_by_index, forKey: .is_program_by_index)
        try container.encode(program_name, forKey: .program_name)
        try container.encode(program_index, forKey: .program_index)
        
        try super.encode(to: encoder)
    }
}

///Performs program or position on selected robot.
public class RobotPerformerElement: PerformerElement
{
    public init(
        object_name: String = "",
        is_single_perfrom: Bool = false,
        is_program_by_index: Bool = false,
        program_name: String = "",
        program_index: Int = 0,
        
        x_index: Int = 0, y_index: Int = 0, z_index: Int = 0,
        r_index: Int = 0, p_index: Int = 0, w_index: Int = 0,
        speed_index: Int = 0, type_index: Int = 0
    )
    {
        super.init()
        
        self.object_name = object_name
        self.is_single_perfrom = is_single_perfrom
        self.is_program_by_index = is_program_by_index
        self.program_name = program_name
        self.program_index = program_index
        
        self.x_index = x_index
        self.y_index = y_index
        self.z_index = z_index
        self.r_index = r_index
        self.p_index = p_index
        self.w_index = w_index
        self.speed_index = speed_index
        self.type_index = type_index
    }
    
    /// Index of *x* location component.
    @Published public var x_index = 0
    /// Index of *y* location component.
    @Published public var y_index = 0
    /// Index of *z* location component.
    @Published public var z_index = 0
    
    /// Index of *r* rotation component.
    @Published public var r_index = 0
    /// Index of *p* rotation component.
    @Published public var p_index = 0
    /// Index of *w* rotation component.
    @Published public var w_index = 0
    
    /// Index of movement speed.
    @Published public var speed_index = 0
    
    /// Index of movement type.
    @Published public var type_index = 0
    
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
    private enum CodingKeys: String, CodingKey
    {
        case x_index, y_index, z_index, r_index, p_index, w_index, speed_index, type_index
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.x_index = try container.decodeIfPresent(Int.self, forKey: .x_index) ?? 0
        self.y_index = try container.decodeIfPresent(Int.self, forKey: .y_index) ?? 0
        self.z_index = try container.decodeIfPresent(Int.self, forKey: .z_index) ?? 0
        self.r_index = try container.decodeIfPresent(Int.self, forKey: .r_index) ?? 0
        self.p_index = try container.decodeIfPresent(Int.self, forKey: .p_index) ?? 0
        self.w_index = try container.decodeIfPresent(Int.self, forKey: .w_index) ?? 0
        
        self.speed_index = try container.decodeIfPresent(Int.self, forKey: .speed_index) ?? 0
        self.type_index = try container.decodeIfPresent(Int.self, forKey: .type_index) ?? 0
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(x_index, forKey: .x_index)
        try container.encode(y_index, forKey: .y_index)
        try container.encode(z_index, forKey: .z_index)
        try container.encode(r_index, forKey: .r_index)
        try container.encode(p_index, forKey: .p_index)
        try container.encode(w_index, forKey: .w_index)
        try container.encode(speed_index, forKey: .speed_index)
        try container.encode(type_index, forKey: .type_index)
        
        try super.encode(to: encoder)
    }
}

///Performs program or position on selected tool.
public class ToolPerformerElement: PerformerElement
{
    public init(
        object_name: String = "",
        is_single_perfrom: Bool = false,
        is_program_by_index: Bool = false,
        program_name: String = "",
        program_index: Int = 0,
        
        opcode_index: Int = 0
    )
    {
        super.init()
        
        self.object_name = object_name
        self.is_single_perfrom = is_single_perfrom
        self.is_program_by_index = is_program_by_index
        self.program_name = program_name
        self.program_index = program_index
        
        self.opcode_index = opcode_index
    }
    
    /// Index of operation code location component.
    @Published public var opcode_index = 0
    
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
    private enum CodingKeys: String, CodingKey
    {
        case opcode_index
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.opcode_index = try container.decodeIfPresent(Int.self, forKey: .opcode_index) ?? 0
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(opcode_index, forKey: .opcode_index)
        
        try super.encode(to: encoder)
    }
}

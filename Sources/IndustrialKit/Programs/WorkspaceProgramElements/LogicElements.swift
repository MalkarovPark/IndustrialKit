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
    public init(
        target_mark_name: String = "",
        target_element_index: Int = 0
    )
    {
        self.target_mark_name = target_mark_name
        self.target_element_index = target_element_index
        
        super.init()
    }
    
    /// A name of the target mark.
    @Published public var target_mark_name = ""
    
    /// An index of the target mark element.
    @Published public var target_element_index = 0
    
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
        return "l: jump.(\(target_mark_name)"
    }
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case target_mark_name, target_element_index
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.target_mark_name = try container.decodeIfPresent(String.self, forKey: .target_mark_name) ?? ""
        self.target_element_index = try container.decodeIfPresent(Int.self, forKey: .target_element_index) ?? 0
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(target_mark_name, forKey: .target_mark_name)
        try container.encode(target_element_index, forKey: .target_element_index)
        
        try super.encode(to: encoder)
    }
}

///Jumps to the specified mark when the conditions are met.
public class ComparatorLogicElement: LogicElement
{
    public init(
        compare_type: CompareType = .equal,
        value_index: Int = 0,
        value2_index: Int = 0,
        target_mark_name: String = "",
        target_element_index: Int = 0
    )
    {
        self.compare_type = compare_type
        self.value_index = value_index
        self.value2_index = value2_index
        self.target_mark_name = target_mark_name
        self.target_element_index = target_element_index
        
        super.init()
    }
    
    /// A type of compare.
    @Published public var compare_type: CompareType = .equal
    
    /// An index of register with compared value.
    @Published public var value_index = 0
    
    /// An index of register with compared value.
    @Published public var value2_index = 0
    
    /// A name of the target mark.
    @Published public var target_mark_name = ""
    
    /// An index of the target mark element.
    @Published public var target_element_index = 0
    
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
        return "l: if [\(value_index)] \(compare_type.code_string) [\(value2_index)] jump.(\(target_mark_name))"
    }
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case compare_type, value_index, value2_index, target_mark_name, target_element_index
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.compare_type = try container.decodeIfPresent(CompareType.self, forKey: .compare_type) ?? .equal
        self.value_index = try container.decodeIfPresent(Int.self, forKey: .value_index) ?? 0
        self.value2_index = try container.decodeIfPresent(Int.self, forKey: .value2_index) ?? 0
        self.target_mark_name = try container.decodeIfPresent(String.self, forKey: .target_mark_name) ?? ""
        self.target_element_index = try container.decodeIfPresent(Int.self, forKey: .target_element_index) ?? 0
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(compare_type, forKey: .compare_type)
        try container.encode(value_index, forKey: .value_index)
        try container.encode(value2_index, forKey: .value2_index)
        try container.encode(target_mark_name, forKey: .target_mark_name)
        try container.encode(target_element_index, forKey: .target_element_index)
        
        try super.encode(to: encoder)
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
    
    var code_string: String
    {
        switch self
        {
        case .equal:
            return "="
        case .unequal:
            return "!="
        case .greater:
            return ">"
        case .greater_equal:
            return ">="
        case .less:
            return "<"
        case .less_equal:
            return "<="
        }
    }
}

///A logic mark to jump.
public class MarkLogicElement: LogicElement
{
    public init(name: String = "")
    {
        self.name = name
        
        super.init()
    }
    
    /// A target mark name.
    @Published public var name = "None"
    
    public override var title: String
    {
        return "Mark"
    }
    
    public override var info: String
    {
        return !name.isEmpty ? name : "Mark without name"
    }
    
    public override var symbol_name: String
    {
        return "record.circle"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return "l: mark.(\(name))"
    }
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case name
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "None"
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try super.encode(to: encoder)
    }
}

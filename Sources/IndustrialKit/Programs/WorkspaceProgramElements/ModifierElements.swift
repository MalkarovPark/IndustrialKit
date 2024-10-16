//
//  ModifierElements.swift
//  IndustrialKit
//
//  Created by Artem on 12.10.2024.
//

import Foundation
import SwiftUI

///Manipulates data in memory, which is an array of registers containing floating point numbers.
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
    /*{
        didSet
        {
            import_module_by_name(module_name)
        }
    }*/
    
    ///A module access type identifier – external or internal.
    public var is_internal_module: Bool
    {
        return !module_name.hasPrefix(".") //Intrnal module has not dot "." in name
    }
    
    public override var info: String
    {
        return "Module – \(is_internal_module ? module_name : String(module_name.dropFirst()))"
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
        
        import_module_by_name(module_name, is_internal: is_internal_module)
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .changer_modifier, data: [module_name])
    }
    
    public var change: ((_ registers: inout [Float]) -> Void) = { registers in }
    
    //MARK: - Module handling
    /**
     Sets modular components to object instance.
     - Parameters:
        - module: A part module.
     
     Set the following components:
     - Registers change function
     */
    public func module_import(_ module: ChangerModule)
    {
        change = module.change
    }
    
    ///Imported internal part modules.
    public static var internal_modules = [ChangerModule]()
    
    ///Imported external part modules.
    public static var external_modules = [ChangerModule]()
    
    ///A changer internal modules names array.
    public static var internal_modules_list = [String]()
    
    ///A changer external modules names array.
    public static var external_modules_list = [String]()
    
    public func import_module_by_name(_ name: String, is_internal: Bool = true)
    {
        let modules = is_internal ? Changer.internal_modules : Changer.external_modules
        
        guard let index = modules.firstIndex(where: { is_internal ? $0.name == name : $0.name.dropFirst() == name }) //If external – drop "." before name
        else
        {
            change = { registers in }
            return
        }
        
        module_import(modules[index])
    }
}

typealias Changer = ChangerModifierElement

///Pushes info code from tool to registers.
public class ObserverModifierElement: ModifierElement
{
    ///A type of observed object
    public var object_type: ObserverObjectType = .robot
    
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
    //Data [type, name, from indices, to indices]
    public override var identifier: WorkspaceProgramElementIdentifier?
    {
        return .observer_modifier
    }
    
    public override var data_count: Int
    {
        return 4
    }
    
    public override func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        object_type = type_from_string(element_struct.data[0])
        object_name = element_struct.data[1]
        from_indices = string_to_indices(element_struct.data[2])
        to_indices = string_to_indices(element_struct.data[3])
        
        func type_from_string(_ string: String) -> ObserverObjectType
        {
            switch string
            {
            case "Robot":
                return .robot
            case "Tool":
                return .tool
            default:
                return .robot
            }
        }
    }
    
    public override var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct(identifier: .observer_modifier, data: [object_type.rawValue, object_name, indices_to_string(from_indices), indices_to_string(to_indices)])
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

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
    public init(
        move_type: ModifierMoveType = .copy,
        links: [MoverLink] = []
    )
    {
        self.move_type = move_type
        self.links = links
        
        super.init()
    }
    
    /// A type of copy
    @Published public var move_type: ModifierMoveType = .copy
    
    /// Inputs bindings
    @Published public var links = [MoverLink]()
    
    public override var info: String
    {
        if links.count > 0
        {
            return "\(move_type.rawValue) from \(links.map { String($0.from) }.joined(separator: ", ")) to \(links.map { String($0.to) }.joined(separator: ", "))"
        }
        else
        {
            return "No registers to write"
        }
    }
    
    public override var symbol_name: String
    {
        switch move_type
        {
        case .copy:
            return "plus.square.on.square"
        case .move:
            return "square.on.square.dashed"
        }
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return "m: [\(links.map { String($0.from) }.joined(separator: ", "))] \(move_type.code_string) [\(links.map { String($0.to) }.joined(separator: ", "))]"
    }
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case move_type, links
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.move_type = try container.decodeIfPresent(ModifierMoveType.self, forKey: .move_type) ?? .copy
        self.links = try container.decodeIfPresent([MoverLink].self, forKey: .links) ?? []
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(move_type, forKey: .move_type)
        try container.encode(links, forKey: .links)
        
        try super.encode(to: encoder)
    }
}

public class MoverLink: ObservableObject, Codable, Identifiable
{
    @Published public var from: Int
    @Published public var to: Int
    
    public var id = UUID()
    
    public init(from: Int, to: Int)
    {
        self.from = from
        self.to = to
    }
    
    // Codable
    private enum CodingKeys: String, CodingKey
    {
        case from, to
    }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.from = try container.decode(Int.self, forKey: .from)
        self.to = try container.decode(Int.self, forKey: .to)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
    }
}

///Writes data to selected register.
public class WriterModifierElement: ModifierElement
{
    public init(
        inputs: [WriterInput] = []
    )
    {
        self.inputs = inputs
        
        super.init()
    }
    
    /// Inputs bindings
    @Published public var inputs = [WriterInput]()
    
    public override var info: String
    {
        if inputs.count > 0
        {
            return "Write \(inputs.map { String($0.value) }.joined(separator: ", ")) to \(inputs.map { String($0.to) }.joined(separator: ", "))"
        }
        else
        {
            return "No registers to write"
        }
    }
    
    public override var symbol_name: String
    {
        return "square.and.pencil"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return "m: <\(inputs.map { String($0.value) }.joined(separator: ", "))> write [\(inputs.map { String($0.to) }.joined(separator: ", "))]"
    }
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case inputs
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.inputs = try container.decodeIfPresent([WriterInput].self, forKey: .inputs) ?? []
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(inputs, forKey: .inputs)
        
        try super.encode(to: encoder)
    }
}

public class WriterInput: ObservableObject, Codable, Identifiable
{
    @Published public var value: Float
    @Published public var to: Int
    
    public var id = UUID()
    
    public init(value: Float, to: Int)
    {
        self.value = value
        self.to = to
    }
    
    // Codable
    private enum CodingKeys: String, CodingKey
    {
        case value, to
    }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decode(Float.self, forKey: .value)
        self.to = try container.decode(Int.self, forKey: .to)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(to, forKey: .to)
    }
}

public class MathModifierElement: ModifierElement
{
    public init(
        expression: String = "",
        to_index: Int = 0
    )
    {
        self.expression = expression
        self.to_index = to_index
        
        super.init()
    }
    
    /// A type of compare.
    @Published public var expression: String = ""
    
    /// An index of register to write.
    @Published public var to_index = 0
    
    public override var info: String
    {
        return "Value of \(expression) to \(to_index)"
    }
    
    public override var symbol_name: String
    {
        return "function"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return "m: [\(to_index)] = <\(expression)>"
    }
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case expression, to_index
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.expression = try container.decodeIfPresent(String.self, forKey: .expression) ?? ""
        self.to_index = try container.decodeIfPresent(Int.self, forKey: .to_index) ?? 0
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(expression, forKey: .expression)
        try container.encode(to_index, forKey: .to_index)
        
        try super.encode(to: encoder)
    }
}

///Changes registers by changer module.
public class ChangerModifierElement: ModifierElement
{
    public init(module_name: String = "")
    {
        self.module_name = module_name
        
        super.init()
    }
    
    /// A name of modifier module.
    @Published public var module_name = ""
    
    /// A module access type identifier – external or internal.
    public var is_internal_module: Bool
    {
        return !module_name.hasPrefix(".") // Intrnal module has not dot "." in name
    }
    
    public override var info: String
    {
        return "Module – \(is_internal_module ? module_name : String(module_name.dropFirst()))"
    }
    
    public override var symbol_name: String
    {
        return "wand.and.rays"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return "m: change.(\(module_name))"
    }
    
    public var change: (inout [Float]) throws -> Void = { _ in }
    
    // MARK: - Module handling
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
    
    /// Imported internal part modules.
    nonisolated(unsafe) public static var internal_modules = [ChangerModule]()
    
    /// Imported external part modules.
    nonisolated(unsafe) public static var external_modules = [ChangerModule]()
    
    /// A changer internal modules names array.
    nonisolated(unsafe) public static var internal_modules_list = [String]()
    
    /// A changer external modules names array.
    nonisolated(unsafe) public static var external_modules_list = [String]()
    
    /**
     Imports module by name.
     - Parameters:
        - name: An installed module name.
        - is_internal: Is module internal or external.
     */
    public func module_import_by_name(_ name: String, is_internal: Bool = true)
    {
        let modules = is_internal ? Changer.internal_modules : Changer.external_modules
        
        guard let index = modules.firstIndex(where: { is_internal ? $0.name == name : $0.name == name.dropFirst() }) // If external – drop "." before name
        else
        {
            change = { registers in }
            return
        }
        
        module_import(modules[index])
    }
    
    /**
     Imports external modules by names.
     - Parameters:
        - name: A list of external modules names.
     */
    public static func external_modules_import(by names: [String])
    {
        Changer.external_modules.removeAll()
        
        for name in names
        {
            Changer.external_modules.append(ChangerModule(external_name: name))
        }
    }
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case module_name
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.module_name = try container.decodeIfPresent(String.self, forKey: .module_name) ?? ""
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(module_name, forKey: .module_name)
        
        try super.encode(to: encoder)
    }
}

public typealias Changer = ChangerModifierElement

///Pushes info code from tool to registers.
public class ObserverModifierElement: ModifierElement
{
    public init(
        object_type: ObserverObjectType = .robot,
        object_name: String = "",
        outputs: [ObserverOutput] = []
    )
    {
        self.object_type = object_type
        self.object_name = object_name
        self.outputs = outputs
        
        super.init()
    }
    
    /// A type of observed object
    @Published public var object_type: ObserverObjectType = .robot
    
    /// A name of object to observe output.
    @Published public var object_name = ""
    
    /// Output bindings
    @Published public var outputs = [ObserverOutput]()
    
    public override var info: String
    {
        if outputs.count > 0
        {
            return "Observe form \(object_name) of \(outputs.map { String($0.from) }.joined(separator: ", ")) to \(outputs.map { String($0.to) }.joined(separator: ", "))"
        }
        else
        {
            return "No items to observe"
        }
    }
    
    public override var symbol_name: String
    {
        return "loupe"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return "m: \(object_type.code_string).(\(object_name)).observe.[\(outputs.map { String($0.from) }.joined(separator: ", "))] [\(outputs.map { String($0.to) }.joined(separator: ", "))]"
    }
    
    // File handling
    private enum CodingKeys: String, CodingKey
    {
        case object_type, object_name, outputs
    }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.object_type = try container.decodeIfPresent(ObserverObjectType.self, forKey: .object_type) ?? .robot
        self.object_name = try container.decodeIfPresent(String.self, forKey: .object_name) ?? ""
        self.outputs = try container.decodeIfPresent([ObserverOutput].self, forKey: .outputs) ?? []
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(object_type, forKey: .object_type)
        try container.encode(object_name, forKey: .object_name)
        try container.encode(outputs, forKey: .outputs)
        
        try super.encode(to: encoder)
    }
}

public class ObserverOutput: ObservableObject, Codable, Identifiable
{
    @Published public var from: Int
    @Published public var to: Int
    
    public var id = UUID()
    
    public init(from: Int, to: Int)
    {
        self.from = from
        self.to = to
    }
    
    // Codable
    private enum CodingKeys: String, CodingKey
    {
        case from, to
    }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.from = try container.decode(Int.self, forKey: .from)
        self.to = try container.decode(Int.self, forKey: .to)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
    }
}

///Cleares data in all registers.
public class CleanerModifierElement: ModifierElement
{
    public override init()
    {
        super.init()
    }
    
    public override var info: String
    {
        return "Clear all registers"
    }
    
    public override var symbol_name: String
    {
        return "clear"
    }
    
    // Code string conversion
    public override var code_string: String
    {
        return "m: clear"
    }
    
    // File handling
    public required init(from decoder: Decoder) throws
    {
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
    }
}

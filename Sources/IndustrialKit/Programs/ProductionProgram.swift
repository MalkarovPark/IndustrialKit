//
//  File.swift
//  IndustrialKit
//
//  Created by Artem on 06.02.2026.
//

import Foundation

/// A named sequence of production program elements executed within a workspace.
///
/// `ProductionProgram` defines a linear and logical structure of performing
/// instructions that control robots, tools, and auxiliary production objects.
///
/// The program consists of ordered ``ProductionProgramElement`` instances,
/// representing performers, modifiers, and logic constructs such as jumps
/// and conditional comparisons.
///
/// In addition to structured elements, the program can be represented as a
/// textual listing (`listing_text`) and supports bidirectional conversion
/// between code and internal element representation.
///
/// The class provides:
/// - Element management (add, update, delete)
/// - Logical linking via marks and jumps
/// - Code parsing and serialization
/// - State control for performing lifecycle
///
/// Equality between programs is determined by their ``name``.
///
public class ProductionProgram: Identifiable, Codable, Equatable, ObservableObject
{
    public let id: UUID = UUID()
    
    public static func == (lhs: ProductionProgram, rhs: ProductionProgram) -> Bool
    {
        return lhs.name == rhs.name // Identity condition by names
    }
    
    /// A textual code listing representing the program.
    ///
    /// This optional value may contain a serialized representation of program
    /// elements and is typically used for editor integration.
    public var name: String
    
    /// A textual code listing representing the program.
    ///
    /// This optional value may contain a serialized representation of program
    /// elements and is typically used for editor integration.
    @Published public var listing_text: String?
    
    /// An ordered collection of program elements.
    ///
    /// Elements define the performing logic, including performers, modifiers,
    /// and control flow constructs.
    @Published public var elements = [ProductionProgramElement]()
    
    // MARK: - Initializer
    /// Creates a new production program.
    ///
    /// - Parameters:
    ///   - name: A human-readable program name. Defaults to `"None"`.
    ///   - elements: An ordered list of production program elements representing a structured sequence of operations.
    public init(
        name: String = "None",
        elements: [ProductionProgramElement] = [ProductionProgramElement]()
    )
    {
        self.name = name
        self.elements = elements
    }
    
    // MARK: - Element Management
    /// Appends a new element to the program.
    ///
    /// - Parameter element: A program element to add.
    public func add_element(_ element: ProductionProgramElement)
    {
        elements.append(element)
    }
    
    /// Updates an existing element at the specified index.
    ///
    /// - Parameters:
    ///   - index: The position of the element to update.
    ///   - element: A new element to replace the existing one.
    public func update_element(index: Int, _ element: ProductionProgramElement)
    {
        if elements.indices.contains(index)
        {
            elements[index] = element
        }
    }
    
    /// Removes an element at the specified index, if it exists.
    ///
    /// - Parameter index: The index of the element to remove.
    public func delete_element(at index: Int)
    {
        if elements.indices.contains(index)
        {
            elements.remove(at: index)
        }
    }
    
    /// The number of elements contained in the program.
    public var elements_count: Int
    {
        return elements.count
    }
    
    /// Resets the performing state of all elements to `.none`.
    ///
    /// This method is typically used before starting program execution.
    public func reset_elements_states()
    {
        for element in elements
        {
            element.performing_state = .none
        }
    }
    
    /// A collection of all defined mark names within the program.
    ///
    /// Marks are used as jump targets for logic elements.
    public var mark_names: [String]
    {
        return elements.compactMap { ($0 as? MarkLogicElement)?.name }.filter { !$0.isEmpty }
    }
    
    /// Resolves and assigns element indices for all logic elements.
    ///
    /// The method builds a mapping between mark names and their positions,
    /// then assigns target indices for jump and comparator elements.
    public func defining_elements_indices()
    {
        // Build map of mark name – index in one pass
        let marks: [String: Int] = elements.enumerated().reduce(into: [:])
        { dict, pair in
            let (index, element) = pair
            
            if let mark = element as? MarkLogicElement
            {
                dict[mark.name] = index
            }
        }
        
        // Assign target indices for jump/comparator elements in one pass
        for element in elements
        {
            switch element
            {
            case let jump as JumpLogicElement:
                if !jump.target_mark_name.isEmpty, let target = marks[jump.target_mark_name]
                {
                    jump.target_element_index = target
                }
            case let cmp as ComparatorLogicElement:
                if !cmp.target_mark_name.isEmpty, let target = marks[cmp.target_mark_name]
                {
                    cmp.target_element_index = target
                }
            default:
                break
            }
        }
    }
    
    /// Resolves and assigns a target index for a specific logic element.
    ///
    /// - Parameter element: A logic element requiring mark resolution.
    public func set_mark_index(for element: ProductionProgramElement)
    {
        // Build map of mark name – index
        let marks: [String: Int] = elements.enumerated().reduce(into: [:])
        { dict, pair in
            let (index, elem) = pair
            if let mark = elem as? MarkLogicElement
            {
                dict[mark.name] = index
            }
        }
        
        switch element
        {
        case let jump as JumpLogicElement:
            guard !jump.target_mark_name.isEmpty, let index = marks[jump.target_mark_name] else { return }
            jump.target_element_index = index
        case let cmp as ComparatorLogicElement:
            guard !cmp.target_mark_name.isEmpty, let index = marks[cmp.target_mark_name] else { return }
            cmp.target_element_index = index
        default:
            return
        }
    }
    
    // MARK: - Listing functions
    /// A textual representation of the program.
    ///
    /// Getting this property serializes elements into code.
    /// Setting this property parses the code into program elements.
    public var code: String
    {
        get
        {
            return elements_to_code
        }
        set
        {
            code_to_elements(from: newValue)
        }
    }
    
    //private var code_text = String()
    
    /// Converts program elements into a multiline code string.
    private var elements_to_code: String
    {
        var code: String = ""
        
        for (index, element) in elements.enumerated()
        {
            code.append(element.code_string)
            
            if index < elements.count - 1
            {
                code.append("\n")
            }
        }
        
        return code
    }
    
    /// Parses a code string and rebuilds program elements.
    ///
    /// - Parameter code: A textual program representation.
    private func code_to_elements(from code: String)
    {
        elements.removeAll()
        
        let lines = code.split(separator: "\n")
        
        for line in lines
        {
            let trimmed_line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed_line.isEmpty else { continue }
            
            elements.append(parse_element(from: trimmed_line))
        }
    }
    
    // MARK: - File Hanlding
    private enum CodingKeys: String, CodingKey
    {
        case name
        case elements
        case listing_text
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        
        let wrapped = try container.decode([AnyProductionProgramElement].self, forKey: .elements)
        self.elements = wrapped.map { $0.base }
        
        self.listing_text = try container.decodeIfPresent(String.self, forKey: .listing_text)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        let wrapped = elements.map { AnyProductionProgramElement($0) }
        try container.encode(wrapped, forKey: .elements)
        
        try container.encode(listing_text, forKey: .listing_text)
    }
}

// MARK: - Conversion functions
public enum RegexPatterns: String, CaseIterable
{
    // Performers
    // RobotPerformerElement
    case RobotPerformerElement_program = #"p: r\.\((.*?)\)\.\((.*?)\)"#
    case RobotPerformerElement_index = #"p: r\.\(([^()]*)\)\.index\.\[([^\[\]]*)\]"#
    case RobotPerformerElement_single = #"p: r\.\(([^()]*)\)\.single\.\[(\d+), (\d+), (\d+), (\d+), (\d+), (\d+), (\d+), (\d+)\]"#
    
    // ToolPerformerElement
    case ToolPerformerElement_program = #"p: t\.\((.*?)\)\.\((.*?)\)"#
    case ToolPerformerElement_index = #"p: t\.\(([^()]*)\)\.index\.\[([^\[\]]*)\]"#
    case ToolPerformerElement_single = #"p: t\.\(([^()]*)\)\.single\.\[([^\[\]]*)\]"#
    
    // Modifiers
    // MathModifierElement
    case _MathModifierElement = #"m: \[([^\[\]]+)\] = <(.+)>"#
    
    // MoverModifierElement
    case _MoverModifierElement = #"m:\s*\[([^\[\]]+)\]\s*(move|copy)\s*\[([^\[\]]+)\]"#
    
    // WriterModifierElement
    case _WriterModifierElement = #"m:\s*\<([^\[\]]+)\>\s*write\s*\[([^\[\]]+)\]"# //#"m: <([^\]]+)>\s*write\s*\[([^\]]+)\]"#
    
    // ObserverModifierElement
    case _ObserverModifierElement = #"m: ([rt])\.\(([^()]*)\)\.observe\.\[(.*?)\] \[(.*?)\]"#
    
    // ChangerModifierElement
    case _ChangerModifierElement = #"m: change\.\(([^()]*)\)"#
    
    // CleanerModifierElement
    case _CleanerModifierElement = #"m: clear"#
    
    // Logic
    // ComparatorLogicElement
    case _ComparatorLogicElement = #"l: if \[([^\[\]]+)\] (!=|>=|<=|=|>|<) \[([^\[\]]+)\] jump\.\(([^()]*)\)"#
    
    // JumpLogicElement
    case _JumpLogicElement = #"l: jump\.\(([^()]*)\)"#
    
    // MarkLogicElement
    case _MarkLogicElement = #"l: mark\.\(([^()]*)\)"#
    
    public func make_element(from input: String) -> ProductionProgramElement?
    {
        guard match_regex(text: input, pattern: self.rawValue) else
        {
            return nil
        }
        
        let data = extract_data_array(from: input, pattern: self.rawValue)
        
        switch self
        {
        // Robot
        case .RobotPerformerElement_program: // p: r.(name).(program)
            return RobotPerformerElement(
                object_name: data[0],
                is_program_by_index: false,
                program_name: data[1]
            )
        case .RobotPerformerElement_index: // p: r.(name).index.[#]
            return RobotPerformerElement(
                object_name: data[0],
                is_program_by_index: true,
                program_index: Int(data[1]) ?? 0
            )
        case .RobotPerformerElement_single: // p: r.(name).single.[#, #, #, #, #, #, #, #]
            return RobotPerformerElement(
                object_name: data[0],
                is_single_perfrom: true,
                x_index: Int(data[1]) ?? 0, y_index: Int(data[2]) ?? 0, z_index: Int(data[3]) ?? 0,
                r_index: Int(data[4]) ?? 0, p_index: Int(data[5]) ?? 0, w_index: Int(data[6]) ?? 0,
                speed_index: Int(data[7]) ?? 0, type_index: Int(data[8]) ?? 0
            )
        // Tool
        case .ToolPerformerElement_program: // p: t.(name).(program)
            return ToolPerformerElement(
                object_name: data[0],
                is_program_by_index: false,
                program_name: data[1]
            )
        case .ToolPerformerElement_index: // p: t.(name).index.[#]
            return ToolPerformerElement(
                object_name: data[0],
                is_program_by_index: true,
                program_index: Int(data[1]) ?? 0
            )
        case .ToolPerformerElement_single: // p: t.(name).single.[#]
            return ToolPerformerElement(
                object_name: data[0],
                is_single_perfrom: true,
                opcode_index: Int(data[1]) ?? 0
            )
            
        // Math
        case ._MathModifierElement: // m: [#] = <expression>
            return MathModifierElement(
                expression: data[1],
                to_index: Int(data[0]) ?? 0
            )
        // Movers
        case ._MoverModifierElement: // m: [#, ...] move [#, ...]
            return MoverModifierElement(
                move_type: data[1] == "move" ? .move : .copy,
                links: {
                    let a = data[0].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                    let b = data[2].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                    return a.count == b.count ? zip(a, b).map { MoverLink(from: $0, to: $1) } : []
                }()
            )
        // Observers
        case ._ObserverModifierElement: // r.(name).observe.[#, ...] [#, ...]
            let typeChar = data[0].trimmingCharacters(in: .whitespaces)
            let objectType: ObserverObjectType = (typeChar == "r") ? .robot : .tool
            
            return ObserverModifierElement(
                object_type: objectType,
                object_name: data[1],
                outputs: zip(
                    data[2].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) },
                    data[3].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                ).map { ObserverOutput(from: $0, to: $1) }
            )
        // Writer
        case ._WriterModifierElement: // m: <#, ...> write [#, ...]
            return WriterModifierElement(
                inputs: zip(
                    data[0].split(separator: ",").compactMap { Float($0.trimmingCharacters(in: .whitespaces)) },
                    data[1].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                ).map { WriterInput(value: $0, to: $1) }
            )
        // Changer
        case ._ChangerModifierElement: // m: change.(Name)
            return ChangerModifierElement(module_name: data[0])
        // Cleaner
        case ._CleanerModifierElement: // m: clear
            return CleanerModifierElement()
            
        // Comparator
        case ._ComparatorLogicElement: // l: if [#] = [#] jump.(Name)
            guard let compareType = CompareType.allCases.first(where: { $0.code_string == data[1].trimmingCharacters(in: .whitespaces) }) else { return nil }
            return ComparatorLogicElement(
                compare_type: compareType,
                value_index: Int(data[0].trimmingCharacters(in: .whitespaces)) ?? 0,
                value2_index: Int(data[2].trimmingCharacters(in: .whitespaces)) ?? 0,
                target_mark_name: data[3].trimmingCharacters(in: .whitespaces)
            )
        // Jump
        case ._JumpLogicElement: // l: jump.(Name)
            return JumpLogicElement(target_mark_name: data[0])
        // Mark
        case ._MarkLogicElement: // l: mark.(Name)
            return MarkLogicElement(name: data[0])
        }
    }
}

private func match_regex(text: String, pattern: String) -> Bool
{
    do
    {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        let match = regex.firstMatch(in: text, options: [], range: range)
        return match != nil
    }
    catch
    {
        //print(error.localizedDescription)
        return false
    }
}

/// Parses a production program element from its textual representation.
///
/// - Parameter string: A string describing a production program element.
/// - Returns: A parsed production program element.
public func parse_element(from string: String) -> ProductionProgramElement
{
    for pattern in RegexPatterns.allCases
    {
        if let element = pattern.make_element(from: string)
        {
            return element
        }
    }
    
    return ProductionProgramElement()
}

private func extract_data_array(from text: String, pattern regex: String) -> [String]
{
    do
    {
        let regex = try NSRegularExpression(pattern: regex)
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        var results: [String] = []

        for match in matches
        {
            for groupIndex in 1..<match.numberOfRanges
            {
                if let range = Range(match.range(at: groupIndex), in: text)
                {
                    results.append(String(text[range]))
                }
            }
        }

        return results
    }
    catch
    {
        //print(error.localizedDescription)
        return []
    }
}

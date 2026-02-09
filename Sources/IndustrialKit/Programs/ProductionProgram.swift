//
//  File.swift
//  IndustrialKit
//
//  Created by Artem on 06.02.2026.
//

import Foundation

/**
 A type of named set of program elements performed by a workspace.
 
 Contains an array of opelements and a custom name used for identification.
 */
public class ProductionProgram: Identifiable, Codable, Equatable, ObservableObject
{
    public let id: UUID = UUID()
    
    public static func == (lhs: ProductionProgram, rhs: ProductionProgram) -> Bool
    {
        return lhs.name == rhs.name // Identity condition by names
    }
    
    /// An operations program name
    public var name: String
    
    /// Code listing with position for elements
    @Published public var listing_text: String?
    
    /// An array of opertaions elements.
    @Published public var elements = [WorkspaceProgramElement]()
    
    // MARK: - Init functions
    
    /// Creates a new operations program.
    public init()
    {
        self.name = "None"
    }
    
    /**
     Creates a new operations program.
     - Parameters:
        - name: A new program name.
     */
    public init(name: String?)
    {
        self.name = name ?? "None"
    }
    
    // MARK: - Code manage functions
    /**
     Add the new element to opertaions program.
     - Parameters:
        - element: An added element.
     */
    public func add_element(_ element: WorkspaceProgramElement)
    {
        elements.append(element)
    }
    
    /**
     Creates a new operations program.
     - Parameters:
        - index: Updated operation element index.
        - element: New operation element.
     */
    public func update_element(index: Int, _ element: WorkspaceProgramElement)
    {
        if elements.indices.contains(index)
        {
            elements[index] = element
        }
    }
    
    /**
     Checks for the presence of a element with a given index to delete.
     - Parameters:
        - index: An index of deleted element.
     */
    public func delete_element(index: Int)
    {
        if elements.indices.contains(index)
        {
            elements.remove(at: index)
        }
    }
    
    /// Returns the operations elements count.
    public var elements_count: Int
    {
        return elements.count
    }
    
    /// Resets the performing state of all operation elements to the `.none` state.
    public func reset_elements_states()
    {
        for element in elements
        {
            element.performing_state = .none
        }
    }
    
    // MARK: - Editor functions
    public var mark_names: [String]
    {
        return elements.compactMap { ($0 as? MarkLogicElement)?.name }
    }
    
    // MARK: - Listing functions
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
    
    private func code_to_elements(from code: String)
    {
        elements.removeAll()
        
        let lines = code.split(separator: "\n")
        
        for line in lines
        {
            let trimmed_line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed_line.isEmpty else { continue }
            
            for pattern in RegexPatterns.allCases
            {
                if let element = pattern.make_element(from: trimmed_line)
                {
                    elements.append(element)
                    break
                }
            }
        }
    }
    
    // MARK: - Work with file system
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
        
        let wrapped = try container.decode([AnyWorkspaceProgramElement].self, forKey: .elements)
        self.elements = wrapped.map { $0.base }
        
        self.listing_text = try container.decodeIfPresent(String.self, forKey: .listing_text)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        let wrapped = elements.map { AnyWorkspaceProgramElement($0) }
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
    case MoverModifierElement_move = #"m: \[([^\[\]]+)\] move \[([^\[\]]+)\]"#
    case MoverModifierElement_copy = #"m: \[([^\[\]]+)\] copy \[([^\[\]]+)\]"#
    
    // WriterModifierElement
    case _WriterModifierElement = #"m: write\.<(.*?)> \[(.*?)\]"#
    
    // ObserverModifierElement
    case ObserverModifierElement_robot = #"m: r\.\(([^()]*)\)\.observe\.\[(.*?)\] \[(.*?)\]"#
    case ObserverModifierElement_tool = #"m: t\.\(([^()]*)\)\.observe\.\[(.*?)\] \[(.*?)\]"#
    
    // ChangerModifierElement
    case _ChangerModifierElement = #"m: change\.\(([^()]*)\)"#
    
    // CleanerModifierElement
    case _CleanerModifierElement = #"m: clear"#
    
    // Logic
    // ComparatorLogicElement
    case _ComparatorLogicElement = #"l: if \[([^\[\]]+)\] (\>=|<=|=|>|<) \[([^\[\]]+)\] jump\.\(([^()]*)\)"#
    
    // JumpLogicElement
    case _JumpLogicElement = #"l: jump\.\(([^()]*)\)"#
    
    // MarkLogicElement
    case _MarkLogicElement = #"l: mark\.\(([^()]*)\)"#
    
    func make_element(from input: String) -> WorkspaceProgramElement?
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
        case .MoverModifierElement_move: // m: [#] move [#]
            return MoverModifierElement(
                move_type: .move,
                from_index: Int(data[1]) ?? 0,
                to_index: Int(data[0]) ?? 0
            )
        case .MoverModifierElement_copy: // m: [#] copy [#]
            return MoverModifierElement(
                move_type: .duplicate,
                from_index: Int(data[1]) ?? 0,
                to_index: Int(data[0]) ?? 0
            )
        // Observers
        case .ObserverModifierElement_robot:
            return ObserverModifierElement(
                object_type: .robot,
                object_name: data[0],
                outputs: zip(
                    data[1].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) },
                    data[2].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                ).map { ObserverOutput(from: $0, to: $1) }
            )
        case .ObserverModifierElement_tool:
            return ObserverModifierElement(
                object_type: .tool,
                object_name: data[0],
                outputs: zip(
                    data[1].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) },
                    data[2].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                ).map { ObserverOutput(from: $0, to: $1) }
            )
        // Writer
        case ._WriterModifierElement:
            return WriterModifierElement(
                inputs: zip(
                    data[0].split(separator: ",").compactMap { Float($0.trimmingCharacters(in: .whitespaces)) },
                    data[1].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                ).map { WriterInput(value: $0, to: $1) }
            )
        // Changer
        case ._ChangerModifierElement:
            return ChangerModifierElement(module_name: data[0])
        // Cleaner
        case ._CleanerModifierElement:
            return CleanerModifierElement()
            
        // Comparator
        case ._ComparatorLogicElement:
            guard let compareType = CompareType.allCases.first(where: { $0.rawValue == data[1] }) else { return nil }
            
            return ComparatorLogicElement(
                compare_type: compareType,
                value_index: Int(data[0]) ?? 0,
                value2_index: Int(data[2]) ?? 0,
                target_mark_name: data[3]
            )
        // Jump
        case ._JumpLogicElement:
            return JumpLogicElement(target_mark_name: data[0])
        // Mark
        case ._MarkLogicElement:
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
        print(error.localizedDescription)
        return false
    }
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
        print(error.localizedDescription)
        return []
    }
}

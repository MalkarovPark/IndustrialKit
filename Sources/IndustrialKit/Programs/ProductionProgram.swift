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
    
    private func code_to_elements(from: String)
    {
        elements.removeAll()
        
        let lines = code.split(separator: "\n")
        
        for line in lines
        {
            let trimmed_line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let element = line_to_element(trimmed_line)
            {
                elements.append(element)
            }
        }
        
        func line_to_element(_ input: String) -> WorkspaceProgramElement?
        {
            if match_regex(text: input, pattern: "p: r\\.\\((.*?)\\)\\.\\((.*?)\\)")
            {
                let data = extract_data_array(from: input, pattern: "p: r\\.\\((.*?)\\)\\.\\((.*?)\\)")
                return nil //RobotPerformerElement(data_array: [data[0], data[1], "0", "false", "false", "0", "0", "0", "0", "0", "0", "0", "0"])
            }
                        
            return nil
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
public enum RegexPatterns
{
    
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

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
    
    // MARK: - Work with file system
    /*private enum CodingKeys: String, CodingKey
    {
        case name
        case elements
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.elements = try container.decode([WorkspaceProgramElement].self, forKey: .elements)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(elements, forKey: .elements)
    }*/
    
    private enum CodingKeys: String, CodingKey
    {
        case name
        case elements
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        
        let wrapped = try container.decode([AnyWorkspaceProgramElement].self, forKey: .elements)
        self.elements = wrapped.map { $0.base }
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        let wrapped = elements.map { AnyWorkspaceProgramElement($0) }
        try container.encode(wrapped, forKey: .elements)
    }
}

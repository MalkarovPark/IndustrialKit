//
//  WorkspaceProgramElement.swift
//  IndustrialKit
//
//  Created by Artem on 01.04.2022.
//

import Foundation
import SwiftUI

/**
 A type of workspace program element that is performed to manage means of production.
 
 The element contains some action performed by the production system.
 */
public class WorkspaceProgramElement: Hashable, Identifiable
{
    public static func == (lhs: WorkspaceProgramElement, rhs: WorkspaceProgramElement) -> Bool
    {
        return lhs.id == rhs.id // Identity condition by id plus element type
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var id = UUID()
    
    public init()
    {
        
    }
    
    /// Inits workspace program element by appropriate codable structure.
    public init(element_struct: WorkspaceProgramElementStruct)
    {
        if element_struct.identifier == identifier && element_struct.data.count == data_count
        {
            data_from_array(element_struct.data)
        }
    }
    
    /// Inits workspace program element by appropriate identifier.
    public init(element_identifier: WorkspaceProgramElementIdentifier)
    {
        data_from_array([String]())
    }
    
    /// Inits workspace program element by appropriate data array.
    public init(data_array: [String])
    {
        data_from_array(data_array)
    }
    
    /// Element type identifier.
    open var identifier: WorkspaceProgramElementIdentifier?
    {
        return nil
    }
    
    /// Element data components count for type.
    open var data_count: Int
    {
        return 0
    }
    
    /**
     Input program element data from data array.
     - Parameters:
        - array: Appropriate data array.
     */
    open func data_from_array(_ data: [String])
    {
        
    }
    
    // MARK: - UI functions
    /// A string for the title in program element card.
    open var title: String
    {
        return "Title"
    }
    
    /// A string for the text in program element card.
    open var info: String
    {
        return "Info"
    }
    
    /// An image name for program element card.
    open var symbol_name: String
    {
        return "app"
    }
    
    /// An image for program element card.
    public var image: Image
    {
        return Image(systemName: symbol_name)
    }
    
    /// A color for the program element card.
    open var color: Color
    {
        return Color(.gray)
    }
    
    //@Published public var performing_state: PerformingState = .none
    
    // MARK: - Text representation
    /// A code string representing of element.
    open var code_string: String
    {
        return String()
    }
    
    // MARK: - Work with file system
    /// Converts tool data to codable tool struct.
    public var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct()
    }
}

//MARK: - Codable Types
///A codable tool struct.
public struct WorkspaceProgramElementStruct: Codable
{
    public var identifier: WorkspaceProgramElementIdentifier?
    
    public var data: [String]
    
    public init()
    {
        data = [String]()
    }
    
    public init(identifier: WorkspaceProgramElementIdentifier, data: [String])
    {
        self.identifier = identifier
        self.data = data
    }
}

public enum ModifierCopyType: String, Codable, Equatable, CaseIterable
{
    case duplicate = "Duplicate"
    case move = "Move"
    
    var code_string: String
    {
        switch self
        {
        case .duplicate:
            return "duplicate"
        case .move:
            return "move"
        }
    }
}

public enum ObserverObjectType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
    
    var code_string: String
    {
        switch self
        {
        case .robot:
            return "r"
        case .tool:
            return "t"
        }
    }
}

///A workspace program element type enum.
public enum WorkspaceProgramElementIdentifier: Codable, Equatable, CaseIterable
{
    // Performer
    case robot_performer
    case tool_performer
    
    // Modifier
    case mover_modifier
    case writer_modifier
    case math_modifier
    case changer_modifier
    case observer_modifier
    case cleaner_modifier
    
    // Logic
    case jump_logic
    case comparator_logic
    case mark_logic
}

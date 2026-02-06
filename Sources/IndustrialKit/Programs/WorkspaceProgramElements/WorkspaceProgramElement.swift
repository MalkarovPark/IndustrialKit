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
public class WorkspaceProgramElement: Hashable, Identifiable, ObservableObject, Codable
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
    public var type: String { String(describing: Self.self) }
    
    public init()
    {
        
    }
    
    /// Element type identifier.
    open var identifier: WorkspaceProgramElementIdentifier?
    {
        return nil
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
    
    @Published public var performing_state: PerformingState = .none
    
    // MARK: - Text representation
    /// A code string representing of element.
    open var code_string: String
    {
        return String()
    }
    
    // MARK: - Work with file system
    private enum CodingKeys: String, CodingKey { case id }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}

public class NewElement: WorkspaceProgramElement
{
    @Published public var link: String = ""
    @Published public var scale: Int = 100
    @Published public var description: String = ""

    public init(link: String, scale: Int = 100, description: String = "")
    {
        self.link = link
        self.scale = scale
        self.description = description
        
        super.init()
    }

    private enum CodingKeys: String, CodingKey
    {
        case link, scale, description
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        link = try container.decode(String.self, forKey: .link)
        scale = try container.decodeIfPresent(Int.self, forKey: .scale) ?? 100
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(link, forKey: .link)
        try container.encode(scale, forKey: .scale)
        try container.encode(description, forKey: .description)
        
        try super.encode(to: encoder)
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

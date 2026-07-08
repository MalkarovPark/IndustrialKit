//
//  ProductionProgramElement.swift
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
public class ProductionProgramElement: Hashable, Identifiable, ObservableObject, Codable
{
    public static func == (lhs: ProductionProgramElement, rhs: ProductionProgramElement) -> Bool
    {
        return lhs.id == rhs.id // Identity condition by id with element type
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
    open var identifier: ProductionProgramElementIdentifier?
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
        return "questionmark"
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
    
    // MARK: - File Hanlding
    private enum CodingKeys: String, CodingKey { case id }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
    }
}

// MARK: - Anytype Wrapper
public class AnyProductionProgramElement: ObservableObject, Codable, Identifiable
{
    @Published public var base: ProductionProgramElement
    
    public var id: UUID { base.id }
    
    public init(_ base: ProductionProgramElement)
    {
        self.base = base
    }
    
    private enum CodingKeys: String, CodingKey { case type, data }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(base.type, forKey: .type)
        let data = try JSONEncoder().encode(base)
        try container.encode(data, forKey: .data)
    }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let data = try container.decode(Data.self, forKey: .data)
        
        switch type
        {
        // Performers
        case "RobotPerformerElement": base = try JSONDecoder().decode(RobotPerformerElement.self, from: data)
        case "ToolPerformerElement": base = try JSONDecoder().decode(ToolPerformerElement.self, from: data)

        // Modifiers
        case "MoverModifierElement": base = try JSONDecoder().decode(MoverModifierElement.self, from: data)
        case "WriterModifierElement": base = try JSONDecoder().decode(WriterModifierElement.self, from: data)
        case "MathModifierElement": base = try JSONDecoder().decode(MathModifierElement.self, from: data)
        case "ChangerModifierElement": base = try JSONDecoder().decode(ChangerModifierElement.self, from: data)
        case "ObserverModifierElement": base = try JSONDecoder().decode(ObserverModifierElement.self, from: data)
        case "CleanerModifierElement": base = try JSONDecoder().decode(CleanerModifierElement.self, from: data)

        // Logic
        case "JumpLogicElement": base = try JSONDecoder().decode(JumpLogicElement.self, from: data)
        case "ComparatorLogicElement": base = try JSONDecoder().decode(ComparatorLogicElement.self, from: data)
        case "MarkLogicElement": base = try JSONDecoder().decode(MarkLogicElement.self, from: data)
            
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown ProductionProgramElement type: \(type)")
        }
    }
}

public enum ModifierMoveType: String, Codable, Equatable, CaseIterable
{
    case copy = "Copy"
    case move = "Move"
    
    var code_string: String
    {
        switch self
        {
        case .copy:
            return "copy"
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
public enum ProductionProgramElementIdentifier: Codable, Equatable, CaseIterable
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

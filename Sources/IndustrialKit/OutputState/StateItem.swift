//
//  StateItem.swift
//  IndustrialKit
//
//  Created by Artem on 08.12.2022.
//

import Foundation

/// A hierarchical element representing device state information.
///
/// `StateItem` models a single unit of state data that can be displayed
/// in a structured, tree-like form.
///
/// Each item may contain:
/// - A name identifying the parameter
/// - An optional textual value
/// - An optional symbol for visual representation
/// - Nested child items for hierarchical grouping
///
/// This structure enables representation of complex device states,
/// including grouped parameters and subsystem-level data.
///
public class StateItem: Hashable, Identifiable, ObservableObject, Codable
{
    public var id = UUID()
    
    public static func == (lhs: StateItem, rhs: StateItem) -> Bool
    {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    /// A name of the state item.
    @Published public var name: String
    
    /// A textual representation of the state value.
    @Published public var value: String?
    
    /// A symbol identifier used for visual representation in UI.
    @Published public var symbol_name: String?
    
    /// Nested child items forming a hierarchical structure.
    @Published public var children: [StateItem]?
    
    /// An index assigned during traversal of the state tree.
    ///
    /// This value is used for ordering and mapping items in flat representations.
    @Published public var item_index = Int()
    
    /// Creates a state item.
    ///
    /// - Parameters:
    ///   - name: A name of the state parameter.
    ///   - value: An optional textual value.
    ///   - symbol_name: An optional symbol identifier for UI representation.
    ///   - children: Optional nested state items.
    public init(
        name: String,
        value: String? = nil,
        symbol_name: String? = nil,
        
        children: [StateItem]? = nil
    )
    {
        self.name = name
        self.value = value
        self.symbol_name = symbol_name
        
        self.children = children
    }
    
    // MARK: - File Data
    enum CodingKeys: String, CodingKey
    {
        case name
        case value
        case symbol_name
        
        case children
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.value = try container.decodeIfPresent(String.self, forKey: .value)
        self.symbol_name = try container.decodeIfPresent(String.self, forKey: .symbol_name)
        
        self.children = try container.decodeIfPresent([StateItem].self, forKey: .children)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encodeIfPresent(symbol_name, forKey: .symbol_name)
        
        try container.encodeIfPresent(children, forKey: .children)
    }
}

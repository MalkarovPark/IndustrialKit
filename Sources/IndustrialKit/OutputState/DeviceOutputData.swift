//
//  DeviceOutputData.swift
//  IndustrialKit
//
//  Created by Artem on 22.02.2026.
//

import Foundation

/// A container that aggregates output data of a robotic device.
///
/// `DeviceOutputData` represents a unified storage of observable state data
/// produced by a device during its operation.
///
/// The data is organized into two complementary forms:
/// - Hierarchical state items (`StateItem`) for structured textual representation
/// - Charts (`StateChart`) for numerical visualization and analysis
///
/// This abstraction enables consistent synchronization between device state,
/// visualization layers, and UI components.
///
/// The class conforms to `ObservableObject`, allowing real-time updates of
/// output data in reactive interfaces.
/// 
public class DeviceOutputData: Hashable, Identifiable, ObservableObject, Codable
{
    public var id = UUID()
    
    public static func == (lhs: DeviceOutputData, rhs: DeviceOutputData) -> Bool
    {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    // MARK: - Init functions
    /// Creates a device output data container.
    ///
    /// - Parameters:
    ///   - items: A collection of hierarchical state items.
    ///   - charts: A collection of charts representing numerical data.
    public init(
        items: [StateItem] = [],
        charts: [StateChart] = []
    )
    {
        self.items = items
        self.charts = charts
    }
    
    // MARK: - Items
    /// A collection of charts representing device output data.
    ///
    /// Charts provide graphical representation of numerical values
    /// collected during device operation.
    @Published public var items: [StateItem]
    /*{
        didSet
        {
            define_item_indices()
        }
    }*/
    
    // MARK: - Charts
    /// A collection of charts representing device output data.
    ///
    /// Charts provide graphical representation of numerical values
    /// collected during device operation.
    @Published public var charts: [StateChart]
    
    // MARK: - Observable
    /// Assigns sequential indices to all state items in a depth-first order.
    ///
    /// The method traverses the hierarchical structure of ``items`` and assigns
    /// a unique ``item_index`` to each element. This is useful for stable ordering,
    /// indexing in UI lists, and mapping flat representations to hierarchical data.
    public func define_item_indices()//for items: [StateItem])
    {
        var counter = 0
        
        func traverse(_ item: StateItem)
        {
            item.item_index = counter
            counter += 1
            
            if let children = item.children
            {
                for child in children
                {
                    traverse(child)
                }
            }
        }
        
        for item in items
        {
            traverse(item)
        }
    }
    
    // MARK: - File Data
    enum CodingKeys: String, CodingKey
    {
        case items
        case charts
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.items = try container.decode([StateItem].self, forKey: .items)
        self.charts = try container.decode([StateChart].self, forKey: .charts)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(items, forKey: .items)
        try container.encode(charts, forKey: .charts)
    }
}

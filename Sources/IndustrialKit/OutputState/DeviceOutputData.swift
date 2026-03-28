//
//  DeviceOutputData.swift
//  IndustrialKit
//
//  Created by Artem on 22.02.2026.
//

import Foundation

public class DeviceOutputData: Hashable, Identifiable, ObservableObject, Codable
{
    public static func == (lhs: DeviceOutputData, rhs: DeviceOutputData) -> Bool
    {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var id = UUID()
    
    // MARK: - Init functions
    public init(
        items: [StateItem] = [],
        charts: [StateChart] = []
    )
    {
        self.items = items
        self.charts = charts
    }
    
    // MARK: - Items
    @Published public var items: [StateItem]
    /*{
        didSet
        {
            define_item_indices()
        }
    }*/
    
    // MARK: - Charts
    @Published public var charts: [StateChart]
    
    // MARK: - Observable
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
    
    // MARK: - Codable handling
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

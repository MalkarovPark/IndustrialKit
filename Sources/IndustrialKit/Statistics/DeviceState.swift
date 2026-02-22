//
//  DeviceState.swift
//  IndustrialKit
//
//  Created by Artem on 22.02.2026.
//

import Foundation

public class DeviceState: Hashable, Identifiable, ObservableObject, Codable
{
    public static func == (lhs: DeviceState, rhs: DeviceState) -> Bool
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
    
    // MARK: - Charts
    @Published public var charts: [StateChart]
    
    // MARK: - Observable
    open var output_values: [Float]
    {
        return []
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
        self.charts = try container.decode([StateChart].self, forKey: .items)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(items, forKey: .items)
        try container.encode(charts, forKey: .charts)
    }
}

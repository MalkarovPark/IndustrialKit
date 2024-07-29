//
//  WorkspaceObjectChart.swift
//  IndustrialKit
//
//  Created by Artem on 03.12.2022.
//

import Foundation

//MARK: - Chart class and structure
/**
 A storage for chart info.
 */
public class WorkspaceObjectChart: Identifiable, Codable, Hashable
{
    public static func == (lhs: WorkspaceObjectChart, rhs: WorkspaceObjectChart) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var name: String
    public var style: ChartStyle
    
    public var text_domain: Bool
    {
        guard data.count > 0
        else
        {
            return false
        }
        
        guard let first_domain: String = data.first!.domain.keys.first
        else
        {
            return false
        }
        
        return first_domain == "" ? false : true
    }
    
    @Published public var data = [ChartDataItem]()
    
    public init()
    {
        self.name = "None"
        self.style = .line
    }
    
    public init(name: String)
    {
        self.name = name
        self.style = .line
    }
    
    public init(name: String, style: ChartStyle)
    {
        self.name = name
        self.style = style
    }
    
    //MARK: Codable handling
    enum CodingKeys: String, CodingKey
    {
        case name
        case style
        case data
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.style = try container.decode(ChartStyle.self, forKey: .style)
        self.data = try container.decode([ChartDataItem].self, forKey: .data)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(style, forKey: .style)
        try container.encode(data, forKey: .data)
    }
}

public class ChartDataItem: Identifiable, Codable, Hashable
{
    //public var id = UUID()
    public static func == (lhs: ChartDataItem, rhs: ChartDataItem) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    @Published public var name: String
    
    @Published public var domain: [String: Float]
    @Published public var codomain: Float
    
    public init(name: String, domain: [String: Float], codomain: Float)
    {
        self.name = name
        self.domain = domain
        self.codomain = codomain
    }
    
    //MARK: Codable handling
    enum CodingKeys: String, CodingKey
    {
        case name
        case domain
        case codomain
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.domain = try container.decode([String: Float].self, forKey: .domain)
        self.codomain = try container.decode(Float.self, forKey: .codomain)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(domain, forKey: .domain)
        try container.encode(codomain, forKey: .codomain)
    }
}

public enum ChartStyle: Codable, Equatable, CaseIterable
{
    case area
    case line
    case point
    case rectange
    case rule
    case bar
}

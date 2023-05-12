//
//  WorkspaceObjectChart.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 03.12.2022.
//

import Foundation

//MARK: - Chart class and structure
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
    
    public var data = [ChartDataItem]()
    
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
}

public struct ChartDataItem: Identifiable, Codable
{
    public var id = UUID()
    public var name: String
    
    public var domain: [String: Float]
    public var codomain: Float
    
    public init(name: String, domain: [String: Float], codomain: Float)
    {
        self.name = name
        self.domain = domain
        self.codomain = codomain
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

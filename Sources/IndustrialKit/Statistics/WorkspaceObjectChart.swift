//
//  WorkspaceObjectChart.swift
//  Robotic Complex Workspace
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
    
    init()
    {
        self.name = "None"
        self.style = .line
    }
    
    init(name: String)
    {
        self.name = name
        self.style = .line
    }
    
    init(name: String, style: ChartStyle)
    {
        self.name = name
        self.style = style
    }
}

public struct ChartDataItem: Identifiable, Codable
{
    public var id = UUID()
    var name: String
    
    var domain: [String: Float]
    var codomain: Float
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

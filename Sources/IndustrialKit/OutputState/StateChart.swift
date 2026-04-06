//
//  ProductionObjectChart.swift
//  IndustrialKit
//
//  Created by Artem on 03.12.2022.
//

import Foundation

/// A model describing a chart for device output visualization.
///
/// `StateChart` represents a named dataset with a specific visual style
/// and a collection of data points.
///
/// The chart supports multiple rendering styles (e.g., line, bar, area),
/// enabling flexible visualization of device metrics over time or domain values.
///
/// The class is observable, allowing dynamic updates of chart data in UI.
///
public class StateChart: Hashable, Identifiable, ObservableObject, Codable
{
    public var id = UUID()
    
    public static func == (lhs: StateChart, rhs: StateChart) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    /// A human-readable name of the chart.
    @Published public var name: String
    
    /// A visual style used to render the chart.
    @Published public var style: ChartStyle
    
    /// A collection of data points forming the chart.
    @Published public var data: [ChartDataItem]
    
    /// Creates a chart instance.
    ///
    /// - Parameters:
    ///   - name: A human-readable chart name.
    ///   - style: A visual representation style of the chart.
    ///   - data: A collection of data points.
    public init(
        name: String = "Chart",
        style: ChartStyle = .line,
        data: [ChartDataItem] = []
    )
    {
        self.name = name
        
        self.style = style
        self.data = data
    }
    
    /// Indicates whether the chart uses a textual domain.
    ///
    /// Returns `true` if domain keys are non-empty strings,
    /// otherwise `false` for numeric or empty domains.
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
    
    // MARK: - File Data
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

/// A single data point within a chart.
///
/// `ChartDataItem` defines a mapping between a domain and a codomain value,
/// representing one measurable observation.
///
/// The domain is represented as a dictionary of named dimensions,
/// allowing multi-dimensional input (e.g., time, category).
///
/// The codomain represents the resulting numeric value associated
/// with the domain.
public class ChartDataItem: Hashable, Identifiable, ObservableObject, Codable
{
    public var id = UUID()
    
    public static func == (lhs: ChartDataItem, rhs: ChartDataItem) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    /// A label identifying the data point.
    public var name: String
    
    /// A dictionary representing domain dimensions of the data point.
    ///
    /// Keys correspond to dimension names (e.g., "time", "category"),
    /// values represent their numeric values.
    public var domain: [String: Float]
    
    /// A numeric value associated with the domain.
    public var codomain: Float
    
    /// Creates a chart data item.
    ///
    /// - Parameters:
    ///   - name: A label of the data point.
    ///   - domain: A dictionary describing input dimensions.
    ///   - codomain: A resulting numeric value.
    public init(
        name: String,
        
        domain: [String: Float],
        codomain: Float
    )
    {
        self.name = name
        
        self.domain = domain
        self.codomain = codomain
    }
    
    // MARK: - File Data
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

/// A type that defines available chart rendering styles.
///
/// `ChartStyle` enumerates supported visualization types used to render
/// chart data within UI components.
///
/// Each style corresponds to a specific graphical representation
/// of the underlying dataset.
public enum ChartStyle: String, Codable, Equatable, CaseIterable
{
    /// A bar chart representation.
    case bar
    
    /// A point-based chart representation.
    case point
    
    /// A line chart representation.
    case line
    
    /// An area chart representation.
    case area
    
    /// A rectangular mark representation.
    case rectangle
    
    /// A rule (line segment) representation.
    case rule
    
    /// A sector (pie-like) representation.
    case sector
}

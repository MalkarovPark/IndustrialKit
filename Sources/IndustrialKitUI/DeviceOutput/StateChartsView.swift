//
//  StateChartsVie.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI
import Charts

import IndustrialKit

public struct StateChartsView: View
{
    @ObservedObject var device_output: DeviceOutputData
    
    @State private var chart_selection = 0
    
    public init(
        device_output: DeviceOutputData
    )
    {
        self.device_output = device_output
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            let charts = device_output.charts
            
            if charts.count > 0
            {
                Picker("Statistics", selection: $chart_selection)
                {
                    ForEach(0..<charts.count, id: \.self)
                    { index in
                        Text(charts[index].name).tag(index)
                    }
                }
                .disabled(charts.count == 1)
                .controlSize(.regular)
                .pickerStyle(.segmented)
                .labelsHidden()
                #if os(iOS)
                .padding()
                #elseif os(visionOS)
                .padding(.horizontal)
                #endif
                
                ChartContent(chart: charts[chart_selection])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #if os(visionOS)
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .background
                    {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.thickMaterial)
                    }
                #endif
                    .padding()
            }
            else
            {
                ContentUnavailableView
                {
                    Text("No Charts")
                }
            }
        }
    }
    
    @ViewBuilder
    private func ChartContent(chart: StateChart) -> some View
    {
        switch chart.style
        {
        case .area:
            Chart
            {
                ForEach(chart.data)
                { item in
                    if chart.text_domain, let key = item.domain.keys.first
                    {
                        AreaMark(x: .value("Month", key), y: .value("Value", item.codomain))
                            .foregroundStyle(by: .value("Type", item.name))
                    }
                    else if let key = item.domain.keys.first, let value = item.domain[key]
                    {
                        AreaMark(x: .value("Month", Float(value)), y: .value("Value", item.codomain))
                            .foregroundStyle(by: .value("Type", item.name))
                    }
                }
            }
        case .line:
            Chart
            {
                ForEach(chart.data)
                { item in
                    if chart.text_domain, let key = item.domain.keys.first
                    {
                        LineMark(x: .value("Month", key), y: .value("Value", item.codomain))
                            .foregroundStyle(by: .value("Type", item.name))
                    }
                    else if let key = item.domain.keys.first, let value = item.domain[key]
                    {
                        LineMark(x: .value("Month", Float(value)), y: .value("Value", item.codomain))
                            .foregroundStyle(by: .value("Type", item.name))
                    }
                }
            }
        case .bar:
            Chart
            {
                ForEach(chart.data)
                { item in
                    if chart.text_domain, let key = item.domain.keys.first
                    {
                        BarMark(x: .value("Month", key), y: .value("Value", item.codomain))
                            .foregroundStyle(by: .value("Type", item.name))
                    }
                    else if let key = item.domain.keys.first, let value = item.domain[key]
                    {
                        BarMark(x: .value("Month", Float(value)), y: .value("Value", item.codomain))
                            .foregroundStyle(by: .value("Type", item.name))
                    }
                }
            }
        case .sector:
            Chart
            {
                ForEach(chart.data)
                { item in
                    SectorMark(
                        angle: .value("Value", item.codomain),
                        innerRadius: .ratio(0.8)
                    )
                    .foregroundStyle(by: .value("Type", item.name))
                }
            }
        default:
            EmptyView() //Spacer()
        }
    }
}

//MARK: - Previews
struct ChartsView_PreviewsContainer: PreviewProvider
{
    struct Container: View
    {
        var body: some View
        {
            ChartsView_Previews()
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    struct ChartsView_Previews: View
    {
        @ObservedObject var device_output = DeviceOutputData()
        
        var body: some View
        {
            StateChartsView(device_output: device_output)
                .frame(width: 640, height: 480)
                .onAppear
                {
                    /*device_output.charts.append(StateChart(name: "Location", style: .line))
                    device_output.charts.append(StateChart(name: "Rotation", style: .line))
                    
                    for d in 0..<16
                    {
                        let position_point = PositionPoint(x: Float.random(in: 0...100), y: Float.random(in: 0...100), z: Float.random(in: 0...100), r: Float.random(in: -180...180), p: Float.random(in: -180...180), w: Float.random(in: -180...180))
                        var axis_names = ["X", "Y", "Z"]
                        var components = [position_point.x, position_point.z, position_point.y]
                        for i in 0...axis_names.count - 1
                        {
                            device_output.charts[0].data.append(ChartDataItem(name: axis_names[i], domain: ["": Float(d)], codomain: Float(components[i])))
                        }
                        
                        axis_names = ["R", "P", "W"]
                        components = [position_point.r, position_point.p, position_point.w]
                        for i in 0...axis_names.count - 1
                        {
                            device_output.charts[1].data.append(ChartDataItem(name: axis_names[i], domain: ["": Float(d)], codomain: Float(components[i])))
                        }
                    }
                    
                    device_output.charts.append(
                        StateChart(
                            name: "Bar",
                            style: .bar,
                            data: [
                                ChartDataItem(name: "Piece 3", domain: ["Column 1" : 80], codomain: 10),
                                ChartDataItem(name: "Piece 1", domain: ["Column 2" : 80], codomain: 20),
                                ChartDataItem(name: "Piece 2", domain: ["Column 3" : 80], codomain: 10),
                                ChartDataItem(name: "Piece 4", domain: ["Column 3" : 80], codomain: 20)
                            ]
                        )
                    )
                    
                    device_output.charts.append(
                        StateChart(
                            name: "Circle",
                            style: .sector,
                            data: [
                                ChartDataItem(name: "Piece 1", domain: ["" : 80], codomain: 10),
                                ChartDataItem(name: "Piece 2", domain: ["" : 80], codomain: 15),
                                ChartDataItem(name: "Piece 3", domain: ["" : 80], codomain: 20),
                                ChartDataItem(name: "Piece 4", domain: ["" : 80], codomain: 25),
                                ChartDataItem(name: "Piece 5", domain: ["" : 80], codomain: 30)
                            ]
                        )
                    )*/
                }
                .padding(.top)
        }
    }
}

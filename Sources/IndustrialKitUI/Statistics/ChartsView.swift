//
//  ChartsView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI
import Charts
import IndustrialKit

public struct ChartsView: View
{
    @State private var chart_selection = 0
    @Binding public var charts_data: [WorkspaceObjectChart]?
    
    public init(charts_data: Binding<[WorkspaceObjectChart]?>)
    {
        self._charts_data = charts_data
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if let charts_data = charts_data
            {
                if charts_data.count > 0
                {
                    Picker("Statistics", selection: $chart_selection)
                    {
                        ForEach(0..<charts_data.count, id: \.self)
                        { index in
                            Text(charts_data[index].name).tag(index)
                        }
                    }
                    .disabled(charts_data.count == 1)
                    .controlSize(.regular)
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    //.padding()
                    
                    if charts_data[chart_selection].text_domain
                    {
                        switch charts_data[chart_selection].style
                        {
                        case .area:
                            Chart
                            {
                                ForEach(charts_data[chart_selection].data)
                                {
                                    AreaMark(x: .value("Mount", $0.domain.keys.first!), y: .value("Value", $0.codomain))
                                    .foregroundStyle(by: .value("Type", $0.name))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        case .line:
                            Chart
                            {
                                ForEach(charts_data[chart_selection].data)
                                {
                                    LineMark(x: .value("Mount", $0.domain.keys.first!), y: .value("Value", $0.codomain))
                                    .foregroundStyle(by: .value("Type", $0.name))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        case .bar:
                            Chart
                            {
                                ForEach(charts_data[chart_selection].data)
                                {
                                    BarMark(x: .value("Mount", $0.domain.keys.first!), y: .value("Value", $0.codomain))
                                    .foregroundStyle(by: .value("Type", $0.name))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        default:
                            Spacer()
                        }
                    }
                    else
                    {
                        switch charts_data[chart_selection].style
                        {
                        case .area:
                            Chart
                            {
                                ForEach(charts_data[chart_selection].data)
                                {
                                    AreaMark(x: .value("Mount", $0.domain[$0.domain.keys.first!]!), y: .value("Value", $0.codomain))
                                    .foregroundStyle(by: .value("Type", $0.name))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        case .line:
                            Chart
                            {
                                ForEach(charts_data[chart_selection].data)
                                {
                                    LineMark(x: .value("Mount", $0.domain[$0.domain.keys.first!]!), y: .value("Value", $0.codomain))
                                    .foregroundStyle(by: .value("Type", $0.name))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        case .bar:
                            Chart
                            {
                                ForEach(charts_data[chart_selection].data)
                                {
                                    BarMark(x: .value("Mount", $0.domain[$0.domain.keys.first!]!), y: .value("Value", $0.codomain))
                                    .foregroundStyle(by: .value("Type", $0.name))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        default:
                            Spacer()
                        }
                    }
                }
                else
                {
                    Text(charts_data.first?.name ?? "Statistics")
                        .font(.title2)
                        .padding([.top, .leading, .trailing])
                }
            }
            else
            {
                Text("Statistics")
                    .font(.title2)
                    .padding([.top, .leading, .trailing])
                EmptyView()
            }
        }
        #if !os(visionOS)
        .background(.white)
        #endif
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
        @State var chart_data: [WorkspaceObjectChart]? = [WorkspaceObjectChart]()
        
        var body: some View
        {
            ChartsView(charts_data: $chart_data)
                .frame(width: 640, height: 480)
                .onAppear
                {
                    chart_data?.append(WorkspaceObjectChart(name: "Location", style: .line))
                    chart_data?.append(WorkspaceObjectChart(name: "Rotation", style: .line))
                    
                    for d in 0..<16
                    {
                        let position_point = PositionPoint(x: Float.random(in: 0...100), y: Float.random(in: 0...100), z: Float.random(in: 0...100), r: Float.random(in: -180...180), p: Float.random(in: -180...180), w: Float.random(in: -180...180))
                        var axis_names = ["X", "Y", "Z"]
                        var components = [position_point.x, position_point.z, position_point.y]
                        for i in 0...axis_names.count - 1
                        {
                            chart_data?[0].data.append(ChartDataItem(name: axis_names[i], domain: ["": Float(d)], codomain: Float(components[i])))
                        }
                        
                        axis_names = ["R", "P", "W"]
                        components = [position_point.r, position_point.p, position_point.w]
                        for i in 0...axis_names.count - 1
                        {
                            chart_data?[1].data.append(ChartDataItem(name: axis_names[i], domain: ["": Float(d)], codomain: Float(components[i])))
                        }
                    }
                }
        }
    }
}

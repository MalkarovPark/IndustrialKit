//
//  SwiftUIView.swift
//  
//
//  Created by Malkarov Park on 22.12.2022.
//

import SwiftUI
import Charts

public struct ChartsView: View
{
    @State private var chart_selection = 0
    @Binding var charts_data: [WorkspaceObjectChart]?
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if charts_data != nil
            {
                if charts_data!.count > 0
                {
                    Text("Statistics")
                        .font(.title2)
                        .padding([.top, .leading, .trailing])
                    
                    Picker("Statistics", selection: $chart_selection)
                    {
                        ForEach(0..<charts_data!.count, id: \.self)
                        { index in
                            Text(charts_data![index].name).tag(index)
                        }
                    }
                    .controlSize(.regular)
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    .padding()
                }
                else
                {
                    Text(charts_data?.first?.name ?? "Statistics")
                        .font(.title2)
                        .padding([.top, .leading, .trailing])
                }
                
                if charts_data!.count > 1
                {
                    if charts_data![chart_selection].text_domain
                    {
                        switch charts_data![chart_selection].style
                        {
                        case .area:
                            Chart
                            {
                                ForEach(charts_data![chart_selection].data)
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
                                ForEach(charts_data![chart_selection].data)
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
                                ForEach(charts_data![chart_selection].data)
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
                        switch charts_data![chart_selection].style
                        {
                        case .area:
                            Chart
                            {
                                ForEach(charts_data![chart_selection].data)
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
                                ForEach(charts_data![chart_selection].data)
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
                                ForEach(charts_data![chart_selection].data)
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
                    EmptyView()
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
    }
}

//MARK: - Previews
struct ChartsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ChartsView(charts_data: .constant([WorkspaceObjectChart(name: "Chart 1", style: .line), WorkspaceObjectChart(name: "Chart 2", style: .line)]))
    }
}

//
//  DeviceStateView.swift
//  IndustrialKit
//
//  Created by Artem on 22.02.2026.
//

import SwiftUI
import IndustrialKit

public struct DeviceStateView: View
{
    @Binding var is_presented: Bool
    
    @ObservedObject var device: WorkspaceObject
    
    let on_update: () -> ()
    
    @State private var stats_selection = 0
    @State private var update_interval_view_presented = false
    
    public init(
        is_presented: Binding<Bool>,
        
        device: WorkspaceObject,
        on_update: @escaping () -> Void = {}
    )
    {
        self._is_presented = is_presented
        
        self.device = device
        self.on_update = on_update
    }
    
    public var body: some View
    {
        ZStack
        {
            if let state_output_device = device as? any StateOutputCapable, let device_state = state_output_device.device_state
            {
                VStack(spacing: 0)
                {
                    if stats_selection == 0
                    {
                        ChartView(device_state: device_state)
                    }
                    else
                    {
                        StateView(device_state: device_state)
                    }
                }
                .modifier(SheetCaption(is_presented: $is_presented, label: "Device State"))
                .overlay(alignment: .topTrailing)
                {
                    HStack(spacing: 0)
                    {
                        let is_state_updating = Binding(
                            get: { state_output_device.is_state_updating },
                            set:
                                { new_value in
                                    state_output_device.is_state_updating = new_value
                                    state_output_device.objectWillChange.send()
                                    
                                    on_update()
                                }
                        )
                        
                        let update_scope_type = Binding(
                            get: { state_output_device.update_scope_type },
                            set:
                                { new_value in
                                    state_output_device.update_scope_type = new_value
                                    state_output_device.objectWillChange.send()
                                    
                                    on_update()
                                }
                        )
                        
                        let state_update_interval = Binding(
                            get: { state_output_device.state_update_interval },
                            set:
                                { new_value in
                                    state_output_device.state_update_interval = new_value
                                    state_output_device.objectWillChange.send()
                                    
                                    on_update()
                                }
                        )
                        
                        Menu
                        {
                            Toggle(isOn: is_state_updating)
                            {
                                Text("Enabled")
                            }
                            
                            Divider()
                            
                            if !state_output_device.is_state_updating
                            {
                                #if os(macOS)
                                Picker(selection: $stats_selection, label: Label("View", systemImage: "eye"))
                                {
                                    Text("Charts").tag(0)
                                    Text("State").tag(1)
                                }
                                #else
                                Menu
                                {
                                    Picker(selection: $stats_selection, label: Label("View", systemImage: "eye"))
                                    {
                                        Text("Charts").tag(0)
                                        Text("State").tag(1)
                                    }
                                }
                                label:
                                {
                                    Label("View", systemImage: "eye")
                                }
                                #endif
                            }
                            else
                            {
                                Label("View", systemImage: "eye")
                                    .disabled(true)
                            }
                            
                            Button(action: { update_interval_view_presented = true })
                            {
                                Label("Set Interval...", systemImage: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                            }
                            
                            if !state_output_device.is_state_updating
                            {
                                #if os(macOS)
                                Picker(selection: update_scope_type, label: Label("Scope", systemImage: "selection.pin.in.out"))
                                {
                                    ForEach(ScopeType.allCases, id: \.self)
                                    { scope_type in
                                        Text(scope_type.rawValue).tag(scope_type)
                                    }
                                }
                                //.disabled(get_statistics)
                                #else
                                Menu
                                {
                                    Picker(selection: update_scope_type, label: Label("Scope", systemImage: "selection.pin.in.out"))
                                    {
                                        ForEach(ScopeType.allCases, id: \.self)
                                        { scope_type in
                                            Text(scope_type.rawValue).tag(scope_type)
                                        }
                                    }
                                }
                                label:
                                {
                                    Label("Scope", systemImage: "selection.pin.in.out")
                                }
                                //.disabled(get_statistics)
                                #endif
                            }
                            else
                            {
                                Label("Scope", systemImage: "clock")
                                    .disabled(true)
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: { state_output_device.reset_device_state() })
                            {
                                Label("Clear Output", systemImage: "eraser")
                            }
                            
                            Button(action: on_update)
                            {
                                Label("Update in File", systemImage: "arrow.down.doc")
                            }
                        }
                        label:
                        {
                            Image(systemName: "ellipsis")
                            #if !os(macOS)
                                .imageScale(.large)
                            #if !os(visionOS)
                                .frame(width: 16, height: 16)
                                .foregroundStyle(.black)
                            #else
                                .foregroundStyle(.white)
                            #endif
                            #endif
                        }
                        #if os(macOS)
                        .menuStyle(.borderlessButton)
                        .padding(10)
                        #else
                        .buttonBorderShape(.circle)
                        #if !os(visionOS)
                        .padding(15)
                        #endif
                        #endif
                        .popover(isPresented: $update_interval_view_presented, arrowEdge: .bottom)
                        {
                            UpdateIntervalView(is_presented: $update_interval_view_presented, time_interval: state_update_interval)
                                .controlSize(.regular)
                        }
                        #if !os(visionOS)
                        .glassEffect()
                        #else
                        .padding(4)
                        .buttonStyle(.borderless)
                        .glassBackgroundEffect()
                        .padding(6)
                        #endif
                    }
                    .padding(10)
                }
            }
        }
        #if os(macOS)
        .controlSize(.large)
        .frame(minWidth: 448, idealWidth: 480, maxWidth: 512, minHeight: 448, idealHeight: 480, maxHeight: 512)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

struct UpdateIntervalView: View
{
    @Binding var is_presented: Bool
    @Binding var time_interval: TimeInterval
    
    var body: some View
    {
        HStack
        {
            Text("sec")
            
            TextField("Time", text: Binding(
                get:
                    {
                        String(format: "%.2f", time_interval)
                    },
                set:
                    { newValue in
                        if let value = Double(newValue)
                        {
                            time_interval = value
                        }
                    })
            )
            .frame(minWidth: 64, maxWidth: 96)
            #if os(iOS) || os(visionOS)
                .frame(idealWidth: 96)
                .textFieldStyle(.roundedBorder)
            #endif
            
            Stepper("Time", value: $time_interval, in: 0.01...60, step: 0.01)
                .labelsHidden()
        }
        .padding()
        #if os(iOS)
        .presentationDetents([.height(96)])
        #endif
    }
}

struct EmptyStatisticsView: View
{
    var body: some View
    {
        VStack(spacing: 0)
        {
            Spacer()
            Text("No Data")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Previews
struct DeviceStateView_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var robot = Robot(name: "6DOF Robot")
        
        var body: some View
        {
            DeviceStateView(is_presented: .constant(true), device: robot)
                .onAppear
                {
                    prepare_state()
                }
        }
        
        private func prepare_state()
        {
            let device_state = DeviceState()
            device_state.charts.append(StateChart(name: "Line", style: .line))
            
            for d in 0..<16
            {
                let position_point = PositionPoint(x: Float.random(in: 0...100), y: Float.random(in: 0...100), z: Float.random(in: 0...100), r: Float.random(in: -180...180), p: Float.random(in: -180...180), w: Float.random(in: -180...180))
                let axis_names = ["X", "Y", "Z"]
                let components = [position_point.x, position_point.z, position_point.y]
                for i in 0...axis_names.count - 1
                {
                    device_state.charts[0].data.append(ChartDataItem(name: axis_names[i], domain: ["": Float(d)], codomain: Float(components[i])))
                }
            }
            
            device_state.charts.append(
                StateChart(
                    name: "Circle",
                    style: .sector,
                    data: [
                        ChartDataItem(name: "Piece 1", domain: ["" : 80], codomain: 2),
                        ChartDataItem(name: "Piece 2", domain: ["" : 80], codomain: 2),
                        ChartDataItem(name: "Piece 3", domain: ["" : 80], codomain: 2)
                    ]
                )
            )
            
            device_state.charts.append(
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
            
            //device_state.items.removeAll()
            device_state.items.append(StateItem(name: "Speed", value: "70 mm/sec", symbol_name: "windshield.front.and.wiper.intermittent"))
            device_state.items.append(
                StateItem(
                    name: "Temperature",
                    value: "+10º",
                    symbol_name: "thermometer",
                    children: [
                        StateItem(
                            name: "Еngine",
                            value: "+50º",
                            symbol_name: "thermometer.transmission"),
                        StateItem(
                            name: "Fridge",
                            value: "-40º",
                            symbol_name: "thermometer.snowflake.circle"
                        )
                    ]
                )
            )
            
            robot.device_state = device_state
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

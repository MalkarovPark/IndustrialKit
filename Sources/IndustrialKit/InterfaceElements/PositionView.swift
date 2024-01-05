//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 22.12.2022.
//

import SwiftUI

public struct PositionView: View
{
    @Binding public var location: [Float]
    @Binding public var rotation: [Float]
    
    public init(location: Binding<[Float]>, rotation: Binding<[Float]>)
    {
        self._location = location
        self._rotation = rotation
    }
    
    public var body: some View
    {
        ForEach(PositionComponents.allCases, id: \.self)
        { position_component in
            GroupBox(label: Text(position_component.rawValue)
                .font(.headline))
            {
                VStack(spacing: 12)
                {
                    switch position_component
                    {
                    case .location:
                        ForEach(LocationComponents.allCases, id: \.self)
                        { location_component in
                            HStack(spacing: 8)
                            {
                                Text(location_component.info.text)
                                #if os(macOS)
                                    .frame(width: 20.0)
                                #else
                                    .frame(width: 30.0)
                                #endif
                                TextField("0", value: $location[location_component.info.index], format: .number)
                                    .textFieldStyle(.roundedBorder)
                                #if os(iOS)
                                    .frame(minWidth: 60)
                                    .keyboardType(.decimalPad)
                                #elseif os(visionOS)
                                    .frame(minWidth: 80)
                                    .keyboardType(.decimalPad)
                                #endif
                                Stepper("Enter", value: $location[location_component.info.index], in: -1000...1000)
                                    .labelsHidden()
                            }
                        }
                    case .rotation:
                        ForEach(RotationComponents.allCases, id: \.self)
                        { rotation_component in
                            HStack(spacing: 8)
                            {
                                Text(rotation_component.info.text)
                                    #if os(macOS)
                                        .frame(width: 20.0)
                                    #else
                                        .frame(width: 30.0)
                                    #endif
                                TextField("0", value: $rotation[rotation_component.info.index], format: .number)
                                    .textFieldStyle(.roundedBorder)
                                #if os(iOS)
                                    .frame(minWidth: 60)
                                    .keyboardType(.decimalPad)
                                #elseif os(visionOS)
                                    .frame(minWidth: 80)
                                    .keyboardType(.decimalPad)
                                #endif
                                Stepper("Enter", value: $rotation[rotation_component.info.index], in: -180...180)
                                    .labelsHidden()
                            }
                        }
                    }
                }
                .padding(8.0)
            }
        }
    }
}

public struct PositionControl: View
{
    @Binding var location: [Float]
    @Binding var rotation: [Float]
    @Binding var scale: [Float]
    
    @State private var teach_selection = 0
    @State private var ppv_presented_location = [false, false, false]
    @State private var ppv_presented_rotation = [false, false, false]
    
    private let teach_items: [String] = ["Location", "Rotation"]
    
    public init(location: Binding<[Float]>, rotation: Binding<[Float]>, scale: Binding<[Float]>)
    {
        self._location = location
        self._rotation = rotation
        self._scale = scale
    }
    
    public var body: some View
    {
        GroupBox
        {
            VStack
            {
                Picker("LR", selection: $teach_selection)
                {
                    ForEach(0..<teach_items.count, id: \.self)
                    { index in
                        Text(self.teach_items[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                #if os(macOS)
                .padding(8)
                #else
                .padding(.bottom, 8)
                #endif
                
                if teach_selection == 0
                {
                    HStack
                    {
                        Button(action: { ppv_presented_location[0].toggle() })
                        {
                            Text("X: " + String(format: "%.0f", location[0]))
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 64)
                        .popover(isPresented: $ppv_presented_location[0])
                        {
                            PositionParameterView(position_parameter_view_presented: $ppv_presented_location[0], parameter_value: $location[0], limit_min: .constant(0), limit_max: $scale[0])
                        }
                        #if os(iOS)
                        .presentationDetents([.height(96)])
                        #endif
                        Slider(value: $location[0], in: 0.0...scale[0])
                            .padding(.trailing)
                    }
                    
                    HStack
                    {
                        Button(action: { ppv_presented_location[1].toggle() })
                        {
                            Text("Y: " + String(format: "%.0f", location[1]))
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 64)
                        .popover(isPresented: $ppv_presented_location[1])
                        {
                            PositionParameterView(position_parameter_view_presented: $ppv_presented_location[1], parameter_value: $location[1], limit_min: .constant(0), limit_max: $scale[1])
                        }
                        #if os(iOS)
                        .presentationDetents([.height(96)])
                        #endif
                        Slider(value: $location[1], in: 0.0...scale[1])
                            .padding(.trailing)
                    }
                    
                    HStack
                    {
                        Button(action: { ppv_presented_location[2].toggle() })
                        {
                            Text("Z: " + String(format: "%.0f", location[2]))
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 64)
                        .popover(isPresented: $ppv_presented_location[2])
                        {
                            PositionParameterView(position_parameter_view_presented: $ppv_presented_location[2], parameter_value: $location[2], limit_min: .constant(0), limit_max: $scale[2])
                        }
                        #if os(iOS)
                        .presentationDetents([.height(96)])
                        #endif
                        Slider(value: $location[2], in: 0.0...scale[2])
                            .padding(.trailing)
                    }
                    #if os(macOS)
                    .padding(.bottom, 8)
                    #else
                    .padding(.bottom, 4)
                    #endif
                }
                else
                {
                    HStack
                    {
                        Button(action: { ppv_presented_rotation[0].toggle() })
                        {
                            Text("R: " + String(format: "%.0f", rotation[0]))
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 64)
                        .popover(isPresented: $ppv_presented_rotation[0])
                        {
                            PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[0], parameter_value: $rotation[0], limit_min: .constant(-180), limit_max: .constant(180))
                        }
                        #if os(iOS)
                        .presentationDetents([.height(96)])
                        #endif
                        Slider(value: $rotation[0], in: -180.0...180)
                            .padding(.trailing)
                    }
                    
                    HStack
                    {
                        Button(action: { ppv_presented_rotation[1].toggle() })
                        {
                            Text("P: " + String(format: "%.0f", rotation[1]))
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 64)
                        .popover(isPresented: $ppv_presented_rotation[1])
                        {
                            PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[1], parameter_value: $rotation[1], limit_min: .constant(-180), limit_max: .constant(180))
                        }
                        #if os(iOS)
                        .presentationDetents([.height(96)])
                        #endif
                        Slider(value: $rotation[1], in: -180.0...180)
                            .padding(.trailing)
                    }
                    
                    HStack
                    {
                        Button(action: { ppv_presented_rotation[2].toggle() })
                        {
                            Text("W: " + String(format: "%.0f", rotation[2]))
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 64)
                        .popover(isPresented: $ppv_presented_rotation[2])
                        {
                            PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[2], parameter_value: $rotation[2], limit_min: .constant(-180), limit_max: .constant(180))
                        }
                        #if os(iOS)
                        .presentationDetents([.height(96)])
                        #endif
                        Slider(value: $rotation[2], in: -180.0...180)
                            .padding(.trailing)
                    }
                    #if os(macOS)
                    .padding(.bottom, 8)
                    #else
                    .padding(.bottom, 4)
                    #endif
                }
            }
        }
        .padding()
    }
}

struct PositionParameterView: View
{
    @Binding var position_parameter_view_presented: Bool
    @Binding var parameter_value: Float
    @Binding var limit_min: Float
    @Binding var limit_max: Float
    
    var body: some View
    {
        HStack(spacing: 8)
        {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {
                    parameter_value = 0
                }
                //parameter_value = 0
                position_parameter_view_presented.toggle()
            })
            {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            #if os(macOS)
            .foregroundColor(Color.white)
            #else
            .padding(.leading, 8)
            #endif
            
            TextField("0", value: $parameter_value, format: .number)
                .textFieldStyle(.roundedBorder)
            #if os(macOS)
                .frame(width: 64)
            #else
                .frame(width: 128)
            #endif
            
            Stepper("Enter", value: $parameter_value, in: Float(limit_min)...Float(limit_max))
                .labelsHidden()
            #if os(iOS) || os(visionOS)
                .padding(.trailing, 8)
            #endif
        }
        .padding(8)
    }
}

struct PositionView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            HStack(spacing: 16)
            {
                PositionView(location: .constant([20, 40, 60]), rotation: .constant([0, 90, 0]))
            }
            .frame(width: 256)
            .padding()
            
            PositionControl(location: .constant([20, 40, 60]), rotation: .constant([0, 90, 0]), scale: .constant([100, 100, 100]))
                .frame(width: 256)
        }
    }
}

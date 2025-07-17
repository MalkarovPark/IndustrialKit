//
//  SpaceOriginView.swift
//  IndustrialKit
//
//  Created by Artem on 16.07.2025.
//

import SwiftUI
import IndustrialKit

public struct SpaceOriginView: View
{
    @Binding var robot: Robot
    
    let on_update: () -> ()
    
    @State private var editor_selection = 0
    
    public init(robot: Binding<Robot>, on_update: @escaping () -> () = {})
    {
        self._robot = robot
        self.on_update = on_update
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            Picker(selection: $editor_selection, label: Text("Editor"))
            {
                /*Image(systemName: "move.3d").tag(0)
                Image(systemName: "rotate.3d").tag(1)
                Image(systemName: "scale.3d").tag(2)*/
                
                Label("Location", systemImage: "move.3d").tag(0)
                Label("Rotation", systemImage: "rotate.3d").tag(1)
                Label("Scale", systemImage: "scale.3d").tag(2)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity)
            .padding()
            
            switch editor_selection
            {
            case 0:
                VStack(spacing: 12)
                {
                    HStack(spacing: 8)
                    {
                        Text("X")
                            .frame(width: 20)
                        TextField("0", value: $robot.origin_position.x, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.origin_position.x, in: -20000...20000)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Y")
                            .frame(width: 20)
                        TextField("0", value: $robot.origin_position.y, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.origin_position.y, in: -20000...20000)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Z")
                            .frame(width: 20)
                        TextField("0", value: $robot.origin_position.z, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.origin_position.z, in: -20000...20000)
                            .labelsHidden()
                    }
                }
                .padding([.horizontal, .bottom])
                #if os(macOS)
                .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
                #else
                .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
                #endif
            case 1:
                VStack(spacing: 12)
                {
                    HStack(spacing: 8)
                    {
                        Text("R")
                            .frame(width: label_width)
                        TextField("0", value: $robot.origin_position.r, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.origin_position.r, in: -180...180)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("P")
                            .frame(width: label_width)
                        TextField("0", value: $robot.origin_position.p, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.origin_position.p, in: -180...180)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("W")
                            .frame(width: label_width)
                        TextField("0", value: $robot.origin_position.w, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.origin_position.w, in: -180...180)
                            .labelsHidden()
                    }
                }
                .padding([.horizontal, .bottom])
                #if os(macOS)
                .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
                #elseif os(iOS)
                .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
                #else
                .frame(minWidth: 256, idealWidth: 288, maxWidth: 320)
                #endif
            case 2:
                VStack(spacing: 12)
                {
                    HStack(spacing: 8)
                    {
                        Text("X")
                            .frame(width: 20)
                        TextField("0", value: $robot.space_scale.x, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.space_scale.x, in: 2...1000)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Y")
                            .frame(width: 20)
                        TextField("0", value: $robot.space_scale.y, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.space_scale.y, in: 2...1000)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Z")
                            .frame(width: 20)
                        TextField("0", value: $robot.space_scale.z, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $robot.space_scale.z, in: 2...1000)
                            .labelsHidden()
                    }
                }
                .padding([.horizontal, .bottom])
                #if os(macOS)
                .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
                #else
                .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
                #endif
            default:
                EmptyView()
            }
        }
        .onChange(of: PositionSnapshot(robot.origin_position))
        { _, _ in
            on_update()
        }
        .onChange(of: ScaleSnapshot(robot.space_scale))
        { _, _ in
            on_update()
        }
    }
}

#if !os(visionOS)
private let label_width = 20.0
#else
private let label_width = 26.0
#endif

public struct ScaleSnapshot: Equatable
{
    let x: Float, y: Float, z: Float
    
    public init(_ tuple: (x: Float, y: Float, z: Float))
    {
        self.x = tuple.x
        self.y = tuple.y
        self.z = tuple.z
    }
}

#Preview
{
    SpaceOriginView(robot: .constant(Robot()), on_update: {})
}

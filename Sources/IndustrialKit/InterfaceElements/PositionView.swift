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
                                    .frame(width: 20.0)
                                TextField("0", value: $location[location_component.info.index], format: .number)
                                    .textFieldStyle(.roundedBorder)
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
                                    .frame(width: 20.0)
                                TextField("0", value: $rotation[rotation_component.info.index], format: .number)
                                    .textFieldStyle(.roundedBorder)
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

struct PositionView_Previews: PreviewProvider
{
    static var previews: some View
    {
        HStack(spacing: 16)
        {
            PositionView(location: .constant([0, 0, 0]), rotation: .constant([0, 0, 0]))
        }
        .frame(width: 256)
        .padding()
    }
}

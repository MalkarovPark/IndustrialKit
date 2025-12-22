//
//  PositionView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI
import IndustrialKit

public struct PositionView: View
{
    @Binding public var position: (x: Float, y: Float, z: Float,
                                   r: Float, p: Float, w: Float)
    
    public init(position: Binding<(x: Float, y: Float, z: Float,
                                   r: Float, p: Float, w: Float)>)
    {
        self._position = position
    }
    
    private func binding(for component: PositionComponents) -> Binding<Float>
    {
        switch component
        {
        case .x:
            return Binding(get: { position.x }, set: { position.x = $0 })
        case .y:
            return Binding(get: { position.y }, set: { position.y = $0 })
        case .z:
            return Binding(get: { position.z }, set: { position.z = $0 })
            
        case .r:
            return Binding(get: { position.r }, set: { position.r = $0 })
        case .p:
            return Binding(get: { position.p }, set: { position.p = $0 })
        case .w:
            return Binding(get: { position.w }, set: { position.w = $0 })
        }
    }
    
    public var body: some View
    {
        ForEach(PositionComponents.Group.allCases, id: \.self)
        { group in
            GroupBox(label: Text(group.rawValue)
                .font(.headline))
            {
                VStack(spacing: 12)
                {
                    ForEach(PositionComponents.components(for: group), id: \.self)
                    { component in
                        HStack(spacing: 8)
                        {
                            Text(component.info.text)
                            #if os(macOS)
                                .frame(width: 20.0)
                            #else
                                .frame(width: 30.0)
                            #endif
                            TextField("0", value: binding(for: component), format: .number)
                                .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                                .frame(minWidth: 60)
                                .keyboardType(.decimalPad)
                            #elseif os(visionOS)
                                .frame(minWidth: 80)
                                .keyboardType(.decimalPad)
                            #endif
                            Stepper("Enter",
                                    value: binding(for: component),
                                    in: group == .location ? (-Float.infinity)...(Float.infinity) : -180...180)
                            .labelsHidden()
                        }
                    }
                }
                .padding(8)
            }
        }
    }
}

public struct PositionControl: View
{
    @Binding var position: (x: Float, y: Float, z: Float,
                            r: Float, p: Float, w: Float)
    @Binding var scale: (x: Float, y: Float, z: Float)
    
    @State private var teach_selection = 0
    @State private var ppv_presented_location = [false, false, false]
    @State private var ppv_presented_rotation = [false, false, false]
    
    private let teach_items: [String] = ["Location", "Rotation"]
    
    public init(position: Binding<(x: Float, y: Float, z: Float,
                                   r: Float, p: Float, w: Float)>,
                scale: Binding<(x: Float, y: Float, z: Float)>)
    {
        self._position = position
        self._scale = scale
    }
    
    private func binding(for component: PositionComponents) -> Binding<Float>
    {
        switch component
        {
        case .x:
            return Binding(get: { position.x }, set: { position.x = $0 })
        case .y:
            return Binding(get: { position.y }, set: { position.y = $0 })
        case .z:
            return Binding(get: { position.z }, set: { position.z = $0 })
            
        case .r:
            return Binding(get: { position.r }, set: { position.r = $0 })
        case .p:
            return Binding(get: { position.p }, set: { position.p = $0 })
        case .w:
            return Binding(get: { position.w }, set: { position.w = $0 })
        }
    }
    
    private func scale_limit(for component: PositionComponents) -> Float
    {
        switch component
        {
        case .x:
            return scale.x
        case .y:
            return scale.y
        case .z:
            return scale.z
        default:
            return 1.0
        }
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
                        Text(teach_items[index]).tag(index)
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
                    ForEach([PositionComponents.x, .y, .z], id: \.self)
                    { component in
                        let index = component.info.order
                        HStack
                        {
                            Button(action: { ppv_presented_location[index].toggle() })
                            {
                                Text(component.info.text + String(format: "%.0f", binding(for: component).wrappedValue))
                                #if !os(visionOS)
                                    .foregroundColor(Color.accentColor)
                                #endif
                            }
                            .buttonStyle(.borderless)
                            .frame(width: button_width)
                            .popover(isPresented: $ppv_presented_location[index])
                            {
                                PositionParameterView(
                                    position_parameter_view_presented: $ppv_presented_location[index],
                                    parameter_value: binding(for: component),
                                    limit_min: .constant(0),
                                    limit_max: .constant(scale_limit(for: component))
                                )
                            }
                            Slider(value: binding(for: component), in: 0.0...scale_limit(for: component))
                                .padding(.trailing)
                        }
                    }
                    #if os(macOS)
                    .padding(.bottom, 8)
                    #else
                    .padding(.bottom, 4)
                    #endif
                }
                else
                {
                    ForEach([PositionComponents.r, .p, .w], id: \.self)
                    { component in
                        let index = component.info.order
                        HStack
                        {
                            Button(action: { ppv_presented_rotation[index].toggle() })
                            {
                                Text(component.info.text + String(format: "%.0f", binding(for: component).wrappedValue))
                                #if !os(visionOS)
                                    .foregroundColor(Color.accentColor)
                                #endif
                            }
                            .buttonStyle(.borderless)
                            .frame(width: button_width)
                            .popover(isPresented: $ppv_presented_rotation[index])
                            {
                                PositionParameterView(
                                    position_parameter_view_presented: $ppv_presented_rotation[index],
                                    parameter_value: binding(for: component),
                                    limit_min: .constant(-180),
                                    limit_max: .constant(180)
                                )
                            }
                            Slider(value: binding(for: component), in: -180.0...180)
                                .padding(.trailing)
                        }
                    }
                    #if os(macOS)
                    .padding(.bottom, 8)
                    #else
                    .padding(.bottom, 4)
                    #endif
                }
            }
        }
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
                // parameter_value = 0
                
                position_parameter_view_presented.toggle()
            })
            {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            #if os(macOS)
            .foregroundColor(Color.white)
            #else
            .padding(.leading, 4)
            #endif
            
            TextField("0", value: $parameter_value, format: .number)
                .textFieldStyle(.roundedBorder)
            #if os(macOS)
                .frame(width: 64)
            #else
                .frame(width: 128)
                .keyboardType(.decimalPad)
            #endif
            
            Stepper("Enter", value: $parameter_value, in: Float(limit_min)...Float(limit_max))
                .labelsHidden()
            #if os(iOS) || os(visionOS)
                .padding(.trailing, 8)
            #endif
        }
        .padding(8)
        #if os(iOS)
        .presentationDetents([.height(96)])
        #endif
    }
}

#if !os(visionOS)
let button_width = 64.0
#else
let button_width = 96.0
#endif

///Sendable struct for onChange handling.
public struct PositionSnapshot: Equatable
{
    let x: Float, y: Float, z: Float, r: Float, p: Float, w: Float
    
    public init(_ tuple: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float))
    {
        self.x = tuple.x
        self.y = tuple.y
        self.z = tuple.z
        
        self.r = tuple.r
        self.p = tuple.p
        self.w = tuple.w
    }
}

public enum PositionComponents: Equatable, CaseIterable
{
    case x
    case y
    case z
    
    case r
    case p
    case w
    
    public enum Group: String, CaseIterable
    {
        case location = "Location"
        case rotation = "Rotation"
    }
    
    public var info: (text: String, group: Group, order: Int)
    {
        switch self
        {
        case .x:
            return ("X ", .location, 0)
        case .y:
            return ("Y ", .location, 1)
        case .z:
            return ("Z ", .location, 2)
            
        case .r:
            return ("R ", .rotation, 0)
        case .p:
            return ("P ", .rotation, 1)
        case .w:
            return ("W ", .rotation, 2)
        }
    }
    
    public static func components(for group: Group) -> [PositionComponents]
    {
        Self.allCases
            .filter { $0.info.group == group }
            .sorted { $0.info.order < $1.info.order }
    }
}

// MARK: - Previews
struct PositionView_Previews: PreviewProvider
{
    struct Container: View
    {
        @State private var position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 20, y: 40, z: 60, r: 0, p: 90, w: 0)
        
        var body: some View
        {
            HStack
            {
                HStack(spacing: 16)
                {
                    PositionView(position: $position)
                }
                .frame(width: 256)
                .modifier(PreviewBorder())
                
                PositionControl(position: $position, scale: .constant((x: 100, y: 100, z: 100)))
                    .frame(width: 208)
                    .modifier(PreviewBorder())
            }
            .padding()
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    private struct PreviewBorder: ViewModifier
    {
        public func body(content: Content) -> some View
        {
            content
                //.frame(width: 256)
                .padding()
                .background(.bar)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 8)
                .padding()
        }
    }
}

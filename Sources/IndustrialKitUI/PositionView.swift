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
    
    private var with_steppers: Bool = true
    
    public init(position: Binding<(x: Float, y: Float, z: Float,
                                   r: Float, p: Float, w: Float)>)
    {
        self._position = position
    }
    
    public init(position: Binding<(x: Float, y: Float, z: Float,
                                   r: Float, p: Float, w: Float)>,
                with_steppers: Bool)
    {
        self._position = position
        self.with_steppers = with_steppers
    }
    
    public var body: some View
    {
        VStack(spacing: 10)
        {
            ForEach(PositionComponents.Group.allCases, id: \.self)
            { group in
                VStack
                {
                    HStack
                    {
                        Text(group.rawValue)
                            .fontWeight(.light)
                            //.font(.system(size: 14, weight: .light))
                        Spacer()
                    }
                    
                    HStack(spacing: 12)
                    {
                        ForEach(PositionComponents.components(for: group), id: \.self)
                        { component in
                            VStack
                            {
                                #if os(macOS)
                                HStack(spacing: 8)
                                {
                                    TextField("0", value: binding(for: component), format: .number)
                                        .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                        .frame(minWidth: 60)
                                        .keyboardType(.decimalPad)
                                    #elseif os(visionOS)
                                        .frame(minWidth: 80)
                                        .keyboardType(.decimalPad)
                                    #endif
                                    Stepper("Position",
                                            value: binding(for: component),
                                            in: group == .location ? (-Float.infinity)...(Float.infinity) : -180...180)
                                    .labelsHidden()
                                }
                                #else
                                VStack(spacing: 8)
                                {
                                    TextField("0", value: binding(for: component), format: .number)
                                        .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                        .frame(minWidth: 60)
                                        .keyboardType(.decimalPad)
                                    #elseif os(visionOS)
                                        .frame(minWidth: 80)
                                        .keyboardType(.decimalPad)
                                    #endif
                                    if with_steppers
                                    {
                                        Stepper("Position",
                                                value: binding(for: component),
                                                in: group == .location ? (-Float.infinity)...(Float.infinity) : -180...180)
                                        .labelsHidden()
                                    }
                                }
                                #endif
                                
                                Text(component.info.text)
                                    .fontWeight(.light)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
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
    
    // Sendable struct for onChange handling.
    private struct PositionSnapshot: Equatable
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

    private enum PositionComponents: Equatable, CaseIterable
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

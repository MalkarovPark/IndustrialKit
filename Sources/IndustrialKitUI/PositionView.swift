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
    
    private var with_steppers: Bool = false
    
    public init(position: Binding<(x: Float, y: Float, z: Float,
                                   r: Float, p: Float, w: Float)>,
                with_steppers: Bool = false)
    {
        self._position = position
        
        self.with_steppers = with_steppers
        
        self.with_location = true
        self.with_rotation = true
    }
    
    private var with_location = false
    private var with_rotation = false
    
    public init(location: Binding<(x: Float, y: Float, z: Float)>,
                with_steppers: Bool = false)
    {
        self._position = Binding(
            get: {
                (
                    x: location.wrappedValue.x,
                    y: location.wrappedValue.y,
                    z: location.wrappedValue.z,
                    r: 0, p: 0, w: 0
                )
            },
            set: { newValue in
                location.wrappedValue = (
                    x: newValue.x,
                    y: newValue.y,
                    z: newValue.z
                )
            }
        )
        
        self.with_steppers = with_steppers
        
        self.with_location = true
    }
    
    public init(rotation: Binding<(r: Float, p: Float, w: Float)>,
                with_steppers: Bool = false)
    {
        self._position = Binding(
            get: {
                (
                    x: 0, y: 0, z: 0,
                    r: rotation.wrappedValue.r,
                    p: rotation.wrappedValue.p,
                    w: rotation.wrappedValue.w,
                )
            },
            set: { newValue in
                rotation.wrappedValue = (
                    r: newValue.r,
                    p: newValue.p,
                    w: newValue.w
                )
            }
        )
        
        self.with_steppers = with_steppers
        
        self.with_rotation = true
    }
    
    //private let hstack_spacing: CGFloat = 12
    
    public var body: some View
    {
        VStack(spacing: 10)
        {
            ForEach(PositionComponents.Group.allCases, id: \.self)
            { group in
                if (
                    (with_location && with_rotation) ||
                    (with_location && group != .rotation) ||
                    (with_rotation && group != .location)
                )
                {
                    VStack
                    {
                        HStack
                        {
                            Text(group.rawValue)
                                .fontWeight(.light)
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
                                        
                                        if with_steppers
                                        {
                                            Stepper("Position",
                                                    value: binding(for: component),
                                                    in: group == .location ? (-Float.infinity)...(Float.infinity) : -180...180)
                                            .labelsHidden()
                                        }
                                    }
                                    #else
                                    VStack//(spacing: 8)
                                    {
                                        TextField("0", value: binding(for: component), format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.decimalPad)
                                        
                                        if with_steppers
                                        {
                                            Rectangle()
                                                .fill(.clear)
                                                .frame(height: 42)
                                                .overlay
                                                {
                                                    Stepper("Position",
                                                            value: binding(for: component),
                                                            in: group == .location ? (-Float.infinity)...(Float.infinity) : -180...180)
                                                        .labelsHidden()
                                                        #if os(visionOS)
                                                        .scaleEffect(0.85)
                                                        #endif
                                            }
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
        #if os(macOS)
        .frame(minWidth: 260)
        #elseif os(iOS)
        .frame(minWidth: 300)
        #elseif os(visionOS)
        .frame(minWidth: 340)
        #endif
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
            case location = "Location (mm)"
            case rotation = "Rotation (º)"
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
        
        @State private var location: (x: Float, y: Float, z: Float) = (x: 20, y: 40, z: 60)
        
        @State private var rotation: (r: Float, p: Float, w: Float) = (r: 0, p: 90, w: 0)
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                HStack(spacing: 16)
                {
                    PositionView(position: $position, with_steppers: true)
                }
                .modifier(PreviewBorder())
                
                HStack(spacing: 16)
                {
                    PositionView(location: $location, with_steppers: true)
                }
                .modifier(PreviewBorder())
                
                HStack(spacing: 16)
                {
                    PositionView(rotation: $rotation, with_steppers: true)
                }
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
            #if !os(visionOS)
            #if os(macOS)
                .frame(width: 260)
            #elseif os(iOS)
                .frame(width: 300)
            #endif
                .padding()
                .background(.bar)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 8)
                .padding()
                .padding()
            #else
                .frame(width: 340)
                .padding()
                .glassBackgroundEffect(in: .rect(cornerRadius: 24, style: .continuous))
            #endif
        }
    }
}

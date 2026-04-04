//
//  GlassStyleBindings.swift
//  IndustrialKit
//
//  Created by Artem on 03.04.2026.
//

#if os(visionOS)
import Foundation
import SwiftUI

//public typealias RealityViewCameraContent = RealityViewContent

// MARK: - Glass
public struct Glass: Equatable, @unchecked Sendable
{
    public static let regular = Glass()
    public static let clear = Glass()
    
    var tint: Color? = nil
    var isInteractive: Bool = false
    var intensity: Double = 1.0
    
    public init() {}
}

// MARK: - modifiers
public extension Glass
{
    func tint(_ color: Color) -> Glass
    {
        var copy = self
        copy.tint = color
        return copy
    }
    
    func interactive(_ value: Bool = true) -> Glass
    {
        var copy = self
        copy.isInteractive = value
        return copy
    }
}

// MARK: - AnyShape
public struct AnyShape: Shape, @unchecked Sendable
{
    private let pathBuilder: @Sendable (CGRect) -> Path
    
    public init<S: Shape>(_ shape: S)
    {
        self.pathBuilder = { rect in
            shape.path(in: rect)
        }
    }
    
    public func path(in rect: CGRect) -> Path
    {
        pathBuilder(rect)
    }
}

// MARK: - Core modifier (visionOS replacement)
private struct GlassEffectModifier<S: InsettableShape>: ViewModifier
{
    let glass: Glass
    let shape: S
    
    func body(content: Content) -> some View
    {
        content
            .background(glass.tint)
            .glassBackgroundEffect(in: shape)
    }
}

// MARK: - View API
public extension View
{
    func glassEffect<S: InsettableShape>(
        _ glass: Glass = .regular,
        in shape: S
    ) -> some View
    {
        modifier(GlassEffectModifier(glass: glass, shape: shape))
    }
}

// MARK: - Glass Effect Container
public struct GlassEffectContainer<Content: View>: View
{
    private let content: Content
    
    public init(@ViewBuilder content: () -> Content)
    {
        self.content = content()
    }
    
    public var body: some View
    {
        ZStack
        {
            content
        }
        .compositingGroup()
    }
}
#endif

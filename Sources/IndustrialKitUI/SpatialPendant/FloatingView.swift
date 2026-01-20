//
//  FloatingView.swift
//  IndustrialKit
//
//  Created by Artem Malkarov on 20.01.2026.
//

import SwiftUI

public struct FloatingView<Content: View>: View
{
    // MARK: - States
    @State private var position: CGPoint = .zero
    @State private var drag_offset: CGSize = .zero
    @State private var is_dragging = false
    @State private var view_size: CGSize = .zero
    
    // MARK: - Content
    let alignment: Alignment
    let content: () -> Content
    
    public init(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> Content)
    {
        self.alignment = alignment
        self.content = content
    }
    
    public var body: some View
    {
        GeometryReader
        { container in
            content()
                .background(
                    GeometryReader
                    { geometry in
                        Rectangle()
                            .fill(.clear)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))
                        //.padding(8)
                            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .onAppear
                        {
                            view_size = geometry.size
                        }
                        .onChange(of: geometry.size)
                        { _, new_size in
                            //let old_size = view_size
                            view_size = new_size
                            
                            guard !is_dragging else { return }
                            
                            let corrected = clamped_edge_target(
                                from: position,
                                in: container.size
                            )
                            
                            let dx = abs(corrected.x - position.x)
                            let dy = abs(corrected.y - position.y)
                            guard dx > 0.5 || dy > 0.5 else { return }
                            
                            withAnimation(.spring(
                                response: 0.45,
                                dampingFraction: 0.85,
                                blendDuration: 0.25
                            )) {
                                position = corrected
                            }
                        }
                    }
                )
                .position(rendered_position)
                .gesture(drag_gesture(in: container.size))
                .onAppear
                {
                    let half_w = view_size.width / 2
                    let half_h = view_size.height / 2
                    
                    switch (alignment.horizontal, alignment.vertical)
                    {
                        // MARK: Center
                    case (.center, .center):
                        position = CGPoint(
                            x: container.size.width / 2,
                            y: container.size.height / 2
                        )
                        
                        // MARK: Horizontal edges
                    case (.leading, .center):
                        position = CGPoint(
                            x: half_w,
                            y: container.size.height / 2
                        )
                        
                    case (.trailing, .center):
                        position = CGPoint(
                            x: container.size.width - half_w,
                            y: container.size.height / 2
                        )
                        
                        // MARK: Vertical edges
                    case (.center, .top):
                        position = CGPoint(
                            x: container.size.width / 2,
                            y: half_h
                        )
                        
                    case (.center, .bottom):
                        position = CGPoint(
                            x: container.size.width / 2,
                            y: container.size.height - half_h
                        )
                        
                        // MARK: Corners
                    case (.leading, .top):
                        position = CGPoint(
                            x: half_w,
                            y: half_h
                        )
                        
                    case (.leading, .bottom):
                        position = CGPoint(
                            x: half_w,
                            y: container.size.height - half_h
                        )
                        
                    case (.trailing, .top):
                        position = CGPoint(
                            x: container.size.width - half_w,
                            y: half_h
                        )
                        
                    case (.trailing, .bottom):
                        position = CGPoint(
                            x: container.size.width - half_w,
                            y: container.size.height - half_h
                        )
                        
                        // MARK: Fallback
                    default:
                        position = CGPoint(
                            x: container.size.width / 2,
                            y: container.size.height / 2
                        )
                    }
                }
        }
    }
    
    // MARK: - Gesture
    private func drag_gesture(in container_size: CGSize) -> some Gesture
    {
        DragGesture()
            .onChanged
        { value in
            is_dragging = true
            drag_offset = value.translation
        }
        .onEnded
        { value in
            position.x += value.translation.width
            position.y += value.translation.height
            drag_offset = .zero
            is_dragging = false
            
            let projected = CGPoint(
                x: position.x + value.predictedEndTranslation.width * 0.4,
                y: position.y + value.predictedEndTranslation.height * 0.4
            )
            
            let target = clamped_edge_target(from: projected, in: container_size)
            
            withAnimation(.interpolatingSpring(mass: 0.7, stiffness: 260, damping: 20, initialVelocity: 6))
            {
                position = target
            }
        }
    }
    
    // MARK: - Rendering
    private var rendered_position: CGPoint
    {
        is_dragging
        ? CGPoint(x: position.x + drag_offset.width, y: position.y + drag_offset.height)
        : position
    }
    
    // MARK: - Clamp + Edge
    private func clamped_edge_target(from point: CGPoint, in container: CGSize) -> CGPoint
    {
        let half_w = view_size.width / 2
        let half_h = view_size.height / 2
        
        let can_snap_x = view_size.width  < container.width
        let can_snap_y = view_size.height < container.height
        
        let min_x = half_w
        let max_x = container.width - half_w
        let min_y = half_h
        let max_y = container.height - half_h
        
        let clamped = CGPoint(
            x: can_snap_x ? min(max(min_x, point.x), max_x) : container.width / 2,
            y: can_snap_y ? min(max(min_y, point.y), max_y) : container.height / 2
        )
        
        var candidates: [(CGPoint, CGFloat)] = []
        
        if can_snap_x
        {
            candidates.append((CGPoint(x: min_x, y: clamped.y), abs(clamped.x - min_x)))
            candidates.append((CGPoint(x: max_x, y: clamped.y), abs(clamped.x - max_x)))
        }
        
        if can_snap_y
        {
            candidates.append((CGPoint(x: clamped.x, y: min_y), abs(clamped.y - min_y)))
            candidates.append((CGPoint(x: clamped.x, y: max_y), abs(clamped.y - max_y)))
        }
        
        guard let best = candidates.min(by: { $0.1 < $1.1 })
        else
        {
            return clamped
        }
        
        return best.0
    }
}

#Preview
{
    ZStack
    {
        FloatingView()
        {
            Rectangle()
                .fill(.clear)
                .frame(width: 128, height: 128)
        }
        .padding()
    }
    .frame(width: 400, height: 400)
}

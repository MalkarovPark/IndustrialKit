//
//  FloatingView.swift
//  IndustrialKit
//
//  Created by Artem Malkarov on 20.01.2026.
//

import SwiftUI

public struct FloatingView<Content: View>: View
{
    @State private var position: CGPoint = .zero
    @State private var drag_offset: CGSize = .zero
    @State private var is_dragging = false
    @State private var view_size: CGSize = .zero
    @State private var stuck_alignment: Alignment?
    
    // Content
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
                            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .onAppear { view_size = geometry.size }
                            .onChange(of: geometry.size)
                            { _, new_size in
                                view_size = new_size
                                update_position_on_resize(container_size: container.size)
                            }
                    }
                )
                .position(rendered_position)
                .gesture(drag_gesture(in: container.size))
                .onChange(of: container.size)
                { _, new_size in
                    update_position_on_resize(container_size: new_size)
                }
                .onAppear
                {
                    let half_w = view_size.width / 2
                    let half_h = view_size.height / 2
                    
                    switch (alignment.horizontal, alignment.vertical) {
                    case (.center, .center):
                        position = CGPoint(x: container.size.width / 2, y: container.size.height / 2)
                    case (.leading, .center):
                        position = CGPoint(x: half_w, y: container.size.height / 2)
                    case (.trailing, .center):
                        position = CGPoint(x: container.size.width - half_w, y: container.size.height / 2)
                    case (.center, .top):
                        position = CGPoint(x: container.size.width / 2, y: half_h)
                    case (.center, .bottom):
                        position = CGPoint(x: container.size.width / 2, y: container.size.height - half_h)
                    case (.leading, .top):
                        position = CGPoint(x: half_w, y: half_h)
                    case (.leading, .bottom):
                        position = CGPoint(x: half_w, y: container.size.height - half_h)
                    case (.trailing, .top):
                        position = CGPoint(x: container.size.width - half_w, y: half_h)
                    case (.trailing, .bottom):
                        position = CGPoint(x: container.size.width - half_w, y: container.size.height - half_h)
                    default:
                        position = CGPoint(x: container.size.width / 2, y: container.size.height / 2)
                    }
                    stuck_alignment = alignment
                }
        }
    }
    
    // Helpers
    private var rendered_position: CGPoint
    {
        is_dragging
            ? CGPoint(x: position.x + drag_offset.width, y: position.y + drag_offset.height)
            : position
    }
    
    private func update_position_on_resize(container_size: CGSize)
    {
        guard !is_dragging else { return }
        
        if let stuck = stuck_alignment
        {
            let corrected = position_on_edge(stuck, in: container_size)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0.2))
            {
                position = corrected
            }
        }
        else
        {
            let corrected = clamped_edge_target(from: position, in: container_size)
            position = corrected
        }
    }
    
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
                
                stuck_alignment = edge_for_position(target, in: container_size)
            }
    }
    
    // MARK: - Clamp + Edge
    private func clamped_edge_target(from point: CGPoint, in container: CGSize) -> CGPoint
    {
        let half_w = view_size.width / 2
        let half_h = view_size.height / 2
        
        let can_snap_x = view_size.width < container.width
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
        
        guard let best = candidates.min(by: { $0.1 < $1.1 }) else { return clamped }
        return best.0
    }
    
    private func edge_for_position(_ point: CGPoint, in container: CGSize) -> Alignment
    {
        let half_w = view_size.width / 2
        let half_h = view_size.height / 2
        let min_x = half_w
        let max_x = container.width - half_w
        let min_y = half_h
        let max_y = container.height - half_h
        
        let dx_min = abs(point.x - min_x)
        let dx_max = abs(point.x - max_x)
        let dy_min = abs(point.y - min_y)
        let dy_max = abs(point.y - max_y)
        let minDist = min(dx_min, dx_max, dy_min, dy_max)
        
        switch minDist
        {
        case dx_min:
            return .leading
        case dx_max:
            return .trailing
        case dy_min:
            return .top
        case dy_max:
            return .bottom
        default:
            return .center
        }
    }
    
    private func position_on_edge(_ alignment: Alignment, in container: CGSize) -> CGPoint
    {
        let half_w = view_size.width / 2
        let half_h = view_size.height / 2
        
        switch (alignment.horizontal, alignment.vertical)
        {
        case (.leading, .center):
            return CGPoint(x: half_w, y: container.height / 2)
        case (.trailing, .center):
            return CGPoint(x: container.width - half_w, y: container.height / 2)
        case (.center, .top):
            return CGPoint(x: container.width / 2, y: half_h)
        case (.center, .bottom):
            return CGPoint(x: container.width / 2, y: container.height - half_h)
        case (.leading, .top):
            return CGPoint(x: half_w, y: half_h)
        case (.leading, .bottom):
            return CGPoint(x: half_w, y: container.height - half_h)
        case (.trailing, .top):
            return CGPoint(x: container.width - half_w, y: half_h)
        case (.trailing, .bottom):
            return CGPoint(x: container.width - half_w, y: container.height - half_h)
        default:
            return CGPoint(x: container.width / 2, y: container.height / 2)
        }
    }
}
/*public struct FloatingView<Content: View>: View
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
}*/

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

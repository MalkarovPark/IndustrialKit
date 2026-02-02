//
//  AdaptiveDotGrid.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI

public struct AdaptiveDotGrid: View
{
    let count: Int
    let square_size: CGFloat
    let spacing_ratio: CGFloat = 0.75
    
    public init(count: Int, square_size: CGFloat)
    {
        self.count = count
        self.square_size = square_size
    }

    private var side: Int
    {
        if count > 1
        {
            Int(ceil(sqrt(Double(count))))
        }
        else
        {
            Int(ceil(sqrt(Double(2))))
        }
    }

    public var body: some View
    {
        GeometryReader
        { _ in
            let spacing = square_size / CGFloat(side) * spacing_ratio
            let dot_size = (square_size - spacing * CGFloat(side - 1)) / CGFloat(side)

            VStack(spacing: spacing)
            {
                ForEach(0..<side, id: \.self)
                { row in
                    HStack(spacing: spacing)
                    {
                        ForEach(0..<side, id: \.self)
                        { column in
                            let index = row * side + (side - 1 - column)

                            if index < count
                            {
                                Circle()
                                    .fill(.tertiary)
                                    .frame(width: dot_size, height: dot_size)
                            }
                            else
                            {
                                Color.clear
                                    .frame(width: dot_size, height: dot_size)
                            }
                        }
                    }
                }
            }
            .frame(width: square_size, height: square_size)
        }
        .frame(width: square_size, height: square_size)
    }
}

#Preview
{
    @Previewable @State var count = 14
    
    Button
    {
        if count < 16
        {
            count += 1
        }
        else
        {
            count = 0
        }
    }
    label:
    {
        AdaptiveDotGrid(count: count, square_size: 80)
            .padding(10)
            .glassEffect(.regular, in: .rect(cornerRadius: 8, style: .continuous))
            .padding(40)
    }
    .buttonStyle(.borderless)
}

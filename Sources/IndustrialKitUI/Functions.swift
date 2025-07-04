//
//  Functions.swift
//  IndustrialKit
//
//  Created by Artem Malkarov on 04.07.2025.
//

import Foundation
import SwiftUI

//MARK: - UI functions
private func colors_by_seed(seed: Int) -> [Color]
{
    var colors = [Color]()

    srand48(seed)
    
    for _ in 0..<256
    {
        var color = [Double]()
        for _ in 0..<3
        {
            let random_number = Double(drand48() * Double(128) + 64)
            
            color.append(random_number)
        }
        colors.append(Color(red: color[0] / 255, green: color[1] / 255, blue: color[2] / 255))
    }

    return colors
}

let registers_colors = colors_by_seed(seed: 5433)

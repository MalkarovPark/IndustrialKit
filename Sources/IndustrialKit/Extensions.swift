//
//  Extensions.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 24.11.2022.
//

import Foundation

//MARK: - Angles convertion extension
public extension Float
{
    var to_deg: Float
    {
        return self * 180 / .pi
    }
    
    var to_rad: Float
    {
        return self * .pi / 180
    }
}

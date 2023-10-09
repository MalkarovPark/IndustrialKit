//
//  Extensions.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 24.11.2022.
//

import Foundation
#if os(macOS)
import AppKit
#endif

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

//MARK: - NSImage to UIImage
#if os(macOS)
public typealias UIImage = NSImage
public typealias UIColor = NSColor

public extension UIImage
{
    func pngData() -> Data?
    {
        //image_data = newValue.tiffRepresentation ?? Data()
        
        if let tiffRepresentation = self.tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation)
        {
            return bitmapImage.representation(using: .png, properties: [:])
        }

        return nil
    }
}
#endif

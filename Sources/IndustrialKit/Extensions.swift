//
//  Extensions.swift
//  IndustrialKit
//
//  Created by Artem on 24.11.2022.
//

import Foundation
import SceneKit
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

//MARK: - SCNNode edit extensions
public extension SCNNode
{
    ///Removes all constrains from node.
    func remove_all_constraints()
    {
        guard self.constraints != nil
        else
        {
            return
        }
        
        if self.constraints?.count ?? 0 > 0
        {
            self.constraints?.removeAll() //Remove constraint
            
            //Update position
            self.position.x += 1
            self.position.x -= 1
            self.rotation.x += 1
            self.rotation.x -= 1
        }
    }
    
    ///Removes all child nodes from node.
    func remove_all_child_nodes()
    {
        self.childNodes.forEach { $0.removeFromParentNode() }
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
        if let tiffRepresentation = self.tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation)
        {
            return bitmapImage.representation(using: .png, properties: [:])
        }

        return nil
    }
}
#endif

//MARK: - Safe access to array elements
extension Array where Element == Float
{
    subscript(safe index: Int) -> Float
    {
        get
        {
            guard index >= 0 && index < count else
            {
                return 0
            }
            return self[index]
        }
        set
        {
            guard index >= 0 && index < count else
            {
                return
            }
            self[index] = newValue
        }
    }
}

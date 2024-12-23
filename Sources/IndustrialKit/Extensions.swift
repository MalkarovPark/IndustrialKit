//
//  Extensions.swift
//  IndustrialKit
//
//  Created by Artem on 24.11.2022.
//

import Foundation
import SceneKit
import SwiftUICore
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
public extension Array
{
    subscript(safe index: Int) -> Element?
    {
        get
        {
            guard index >= 0 && index < count else
            {
                return nil
            }
            return self[index]
        }
        set
        {
            guard let newValue = newValue, index >= 0 && index < count else
            {
                return
            }
            self[index] = newValue
        }
    }
}

extension Array where Element == Float
{
    subscript(safe_float index: Int) -> Float
    {
        get
        {
            guard let saved = self[safe: index]
            else
            {
                return 0
            }
            return saved
        }
        set
        {
            self[safe: index] = newValue
        }
    }
}

/*public extension Dictionary where Key == String
{
    subscript<T>(safe key: String, default defaultValue: T) -> T
    {
        return self[key] as? T ?? defaultValue
    }
}*/

public extension Dictionary where Key == String
{
    subscript<T>(safe key: String, default defaultValue: T) -> T
    {
        return self[key] as? T ?? defaultValue
    }
    
    subscript<T>(safe key: String) -> T where T: ExpressibleByNilLiteral
    {
        return self[key] as? T ?? T(nilLiteral: ())
    }
}

//MARK: - Color by hex import
extension Color
{
    init(hex: String)
    {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#")
        {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

extension UIColor
{
    func to_hex() -> String?
    {
        #if os(macOS)
        let color = usingColorSpace(.deviceRGB) ?? self
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255)

        return String(format:"#%06x", rgb).uppercased()
        #else
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255)

        return String(format:"#%06x", rgb).uppercased()
        #endif
    }
}

//MARK: - Color to hex
extension Color
{
    func to_hex() -> String
    {
        let components = self.cgColor?.components ?? []
        let r = components.count > 0 ? components[0] : 0.0
        let g = components.count > 1 ? components[1] : 0.0
        let b = components.count > 2 ? components[2] : 0.0

        let hexString = String(format: "#%02lX%02lX%02lX",
                               lroundf(Float(r * 255)),
                               lroundf(Float(g * 255)),
                               lroundf(Float(b * 255)))
        return hexString
    }
}

extension UIColor
{
    convenience init?(hex: String)
    {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

//MARK: - Deep SCNNode clone
public extension SCNNode
{
    func deep_clone() -> SCNNode
    {
        let clonedNode = self.clone()
        clonedNode.geometry = self.geometry?.copy() as? SCNGeometry
        if let materials = self.geometry?.materials
        {
            clonedNode.geometry?.materials = materials.map { $0.copy() as! SCNMaterial }
        }
        clonedNode.childNodes.forEach
        { childNode in
            let clonedChild = childNode.deep_clone()
            clonedNode.addChildNode(clonedChild)
        }
        return clonedNode
    }
}

//MARK: - JSON data output of codable objects
public extension Encodable
{
    func json_data() -> Data
    {
        var data = Data()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do
        {
            data = try encoder.encode(self)
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        return data
    }
}

//MARK: - JSON string output of codable objects
public extension Encodable
{
    func json_string() -> String
    {
        var string = String()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do
        {
            let json_data = try encoder.encode(self)
            if let json_string = String(data: json_data, encoding: .utf8)
            {
                string = json_string
            }
        }
        catch
        {
            string = "\(error)"
        }
        
        return string
    }
}

//MARK: - Fitted sheet view for any platforms
public extension View
{
    @ViewBuilder
    func fitted() -> some View
    {
        if #available(macOS 15.0, iOS 18.0, visionOS 2.0, *)
        {
            self.presentationSizing(.fitted)
        }
    }
}

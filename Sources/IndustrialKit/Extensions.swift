//
//  Extensions.swift
//  IndustrialKit
//
//  Created by Artem on 24.11.2022.
//

import Foundation

import RealityKit
//import SceneKit
import SwiftUI//Core
#if os(macOS)
import AppKit
#endif

// MARK: - Angles convertion extension
public extension Float
{
    /// Radians to degrees
    var to_deg: Float
    {
        return self * 180 / .pi
    }
    
    /// Degrees to radians
    var to_rad: Float
    {
        return self * .pi / 180
    }
}

// MARK: - SCNNode edit extensions
/*public extension SCNNode
{
    /// Removes all constraints and refreshes node
    func remove_all_constraints()
    {
        guard self.constraints != nil
        else
        {
            return
        }
        
        if self.constraints?.count ?? 0 > 0
        {
            self.constraints?.removeAll()
            
            self.position.x += 1
            self.position.x -= 1
            self.rotation.x += 1
            self.rotation.x -= 1
        }
    }
    
    /// Removes all child nodes
    func remove_all_child_nodes()
    {
        self.childNodes.forEach { $0.removeFromParentNode() }
    }
}*/

// MARK: - NSImage to UIImage
#if os(macOS)
public typealias UIImage = NSImage
public typealias UIColor = NSColor

public extension UIImage
{
    /// Returns PNG data from NSImage
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

// MARK: - Safe access to array elements
public extension Array
{
    /// Safe get/set element by index, returns nil if out of bounds
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
    /// Safe get/set Float element, returns 0 if out of bounds
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
    /// Safe entity get by key with default
    subscript(safe_name key: String, default defaultValue: Entity) -> Entity
    {
        return self[key] as? Entity ?? defaultValue
    }
    
    /// Safe entity get by key, returns new node if missing
    subscript(safe_name key: String) -> Entity
    {
        return self[key] as? Entity ?? Entity()
    }
}

public extension Dictionary where Key == String
{
    /// Safe get with default for any type
    subscript<T>(safe key: String, default defaultValue: T) -> T
    {
        return self[key] as? T ?? defaultValue
    }
    
    /// Safe get for optional-returning types
    subscript<T>(safe key: String) -> T where T: ExpressibleByNilLiteral
    {
        return self[key] as? T ?? T(nilLiteral: ())
    }
}

// MARK: - Color by hex import
public extension Color
{
    /// Initialize Color from HEX string with optional alpha
    init(hex: String, alpha: Double = 1.0)
    {
        let sanitizedHex = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
        
        var hexValue: UInt64 = 0
        guard Scanner(string: sanitizedHex).scanHexInt64(&hexValue)
        else
        {
            self = .clear
            return
        }
        
        let red, green, blue, computedAlpha: Double
        
        switch sanitizedHex.count
        {
        case 6:
            red = Double((hexValue >> 16) & 0xFF) / 255.0
            green = Double((hexValue >> 8) & 0xFF) / 255.0
            blue = Double(hexValue & 0xFF) / 255.0
            computedAlpha = alpha
        case 8:
            red = Double((hexValue >> 24) & 0xFF) / 255.0
            green = Double((hexValue >> 16) & 0xFF) / 255.0
            blue = Double((hexValue >> 8) & 0xFF) / 255.0
            computedAlpha = Double(hexValue & 0xFF) / 255.0
        default:
            self = .clear
            return
        }
        
        self = Color(
            red: red,
            green: green,
            blue: blue,
            opacity: computedAlpha
        )
    }
}

/*extension Color
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
}*/

extension UIColor
{
    /// Returns HEX string of UIColor
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

// MARK: - Color to hex
extension Color
{
    /// Returns HEX string of Color
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
    /// Initialize UIColor from HEX string
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
/*public extension SCNNode
{
    /// Deep clone node including geometry, materials, and children
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
}*/

// MARK: - JSON data output of codable objects
public extension Encodable
{
    /// Encodes object to JSON Data (pretty-printed)
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

// MARK: - JSON string output of codable objects
public extension Encodable
{
    /// Encodes object to JSON String (pretty-printed)
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

// MARK: - Code correction functions
public extension String
{
    /// Returns code-safe string: spaces → underscores, digits → prefixed _
    var code_correct_format: String
    {
        let correctedName = self.replacingOccurrences(of: " ", with: "_")
        return correctedName.prefix(1).rangeOfCharacter(from: .decimalDigits) != nil ? "_\(correctedName)" : correctedName
    }
}

// MARK: - RealityKit extensions
#if canImport(RealityKit)
public extension Entity
{
    func childEntity(withName name: String, recursively: Bool) -> Entity?
    {
        for child in children
        {
            if child.name == name
            {
                return child
            }
            
            if recursively
            {
                if let found = child.childEntity(withName: name, recursively: true)
                {
                    return found
                }
            }
        }
        
        return nil
    }
}

public extension Entity
{
    func visit(_ action: (Entity) -> Void)
    {
        action(self)
        for child in children
        {
            child.visit(action)
        }
    }
}

public extension Entity
{
    func update_position(_ position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float))
    {
        let location = SIMD3<Float>(position.y / 1000, position.z / 1000, position.x / 1000)
        self.position = location
        
        let r_rot = simd_quatf(angle: Float(position.r.to_rad), axis: [0, 0, 1])
        let p_rot = simd_quatf(angle: Float(position.p.to_rad), axis: [1, 0, 0])
        let w_rot = simd_quatf(angle: Float(position.w.to_rad), axis: [0, 1, 0])
        
        self.orientation = w_rot * p_rot * r_rot
    }
}

public extension Entity
{
    func rotate_x(by radians: Float)
    {
        let delta = simd_quatf(angle: radians, axis: [1, 0, 0])
        transform.rotation = delta * transform.rotation
    }
    
    func rotate_y(by radians: Float)
    {
        let delta = simd_quatf(angle: radians, axis: [0, 1, 0])
        transform.rotation = delta * transform.rotation
    }
    
    func rotate_z(by radians: Float)
    {
        let delta = simd_quatf(angle: radians, axis: [0, 0, 1])
        transform.rotation = delta * transform.rotation
    }
    
    var eulerAngles: SIMD3<Float>
    {
        get
        {
            let q = transform.rotation
            
            let sinr = 2 * (q.real * q.imag.x + q.imag.y * q.imag.z)
            let cosr = 1 - 2 * (q.imag.x * q.imag.x + q.imag.y * q.imag.y)
            let x = atan2(sinr, cosr)
            
            let sinp = 2 * (q.real * q.imag.y - q.imag.z * q.imag.x)
            let y = abs(sinp) >= 1 ? copysign(.pi/2, sinp) : asin(sinp)
            
            let siny = 2 * (q.real * q.imag.z + q.imag.x * q.imag.y)
            let cosy = 1 - 2 * (q.imag.y * q.imag.y + q.imag.z * q.imag.z)
            let z = atan2(siny, cosy)
            
            return SIMD3<Float>(x, y, z)
        }
        set
        {
            let (cx, sx) = (cos(newValue.x * 0.5), sin(newValue.x * 0.5))
            let (cy, sy) = (cos(newValue.y * 0.5), sin(newValue.y * 0.5))
            let (cz, sz) = (cos(newValue.z * 0.5), sin(newValue.z * 0.5))
            
            let qw = cx * cy * cz + sx * sy * sz
            let qx = sx * cy * cz - cx * sy * sz
            let qy = cx * sy * cz + sx * cy * sz
            let qz = cx * cy * sz - sx * sy * cz
            
            transform.rotation = simd_quatf(ix: qx, iy: qy, iz: qz, r: qw)
        }
    }
}
#endif

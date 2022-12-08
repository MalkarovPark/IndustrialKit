import Foundation
import SceneKit
import SwiftUI

public class PositionsProgram: Identifiable, Equatable
{
    public static func == (lhs: PositionsProgram, rhs: PositionsProgram) -> Bool
    {
        return lhs.name == rhs.name //Identity condition by names
    }
    
    public var name: String?
    public var points = [PositionPoint]()
    
    //MARK: - Positions program init functions
    public init()
    {
        self.name = "None"
    }
    
    public init(name: String?)
    {
        self.name = name ?? "None"
    }
    
    //MARK: - Point manage functions
    public func add_point(_ point: PositionPoint)
    {
        points.append(point)
        visual_build()
    }
    
    public func update_point(number: Int, _ point: PositionPoint)
    {
        if points.indices.contains(number) //Checking for the presence of a point with a given number to update
        {
            points[number] = point
            visual_build()
        }
    }
    
    public func delete_point(number: Int) //Checking for the presence of a point with a given number to delete
    {
        if points.indices.contains(number)
        {
            points.remove(at: number)
            visual_build()
        }
    }
    
    /*public var points_info: [[Float]]
    {
        var pinfo = [[Float]]()
        if points.count > 0
        {
            var pindex: Float = 1.0
            for point in points
            {
                pinfo.append([point.x, point.y, point.z, point.r, point.p, point.w, pindex])
                pindex += 1
            }
        }
        return pinfo
    }*/
    
    public var points_count: Int
    {
        return points.count
    }
    
    //MARK: - Visual functions
    public var positions_group = SCNNode() //Node with all positions points model
    public var selected_point_index = -1
    {
        didSet
        {
            visual_build() //Update positions model fot selected point color changing
        }
    }
    
    //Define colors for path and points of program
    #if os(macOS)
    private let target_point_color = NSColor.systemPurple
    private let target_point_cone_colors = [NSColor.systemIndigo, NSColor.systemPink, NSColor.systemTeal]
    private let selected_point_color = NSColor.systemIndigo
    private let target_point_cone_pos = [[0.0, 0.0, 8], [8, 0.0, 0.0], [0.0, 8, 0.0]]
    private let target_point_cone_rot = [[90.0 * .pi / 180, 0.0, 0.0], [0.0, 0.0, -90 * .pi / 180], [0.0, 0.0, 0.0]]
    private let cylinder_color = NSColor.white
    #else
    private let target_point_color = UIColor.systemPurple
    private let target_point_cone_colors = [UIColor.systemIndigo, UIColor.systemPink, UIColor.systemTeal]
    private let selected_point_color = UIColor.systemIndigo
    private let target_point_cone_pos: [[Float]] = [[0.0, 0.0, 8], [8, 0.0, 0.0], [0.0, 8, 0.0]]
    private let target_point_cone_rot: [[Float]] = [[90.0 * .pi / 180, 0.0, 0.0], [0.0, 0.0, -90 * .pi / 180], [0.0, 0.0, 0.0]]
    private let cylinder_color = UIColor.white
    #endif
    
    private var cone_node: SCNNode
    {
        //MARK: Building cones showing tool rotation at point
        let cone_node = SCNNode()
        
        for i in 0..<3 //Set point conical arrows for points
        {
            let cone = SCNNode()
            cone.geometry = SCNCone(topRadius: 0, bottomRadius: 2, height: 4)
            cone.geometry?.firstMaterial?.diffuse.contents = target_point_cone_colors[i]
            cone.position = SCNVector3(x: target_point_cone_pos[i][0], y: target_point_cone_pos[i][1], z: target_point_cone_pos[i][2])
            cone.eulerAngles.x = target_point_cone_rot[i][0]
            cone.eulerAngles.y = target_point_cone_rot[i][1]
            cone.eulerAngles.z = target_point_cone_rot[i][2]
            cone_node.addChildNode(cone.copy() as! SCNNode)
        }
        
        return cone_node
    }
    
    //MARK: Build points visual model
    public func visual_build()
    {
        visual_clear()
        
        if points.count > 0
        {
            //MARK: Build positions points in robot cell
            var point_location = SCNVector3()
            if points.count > 1
            {
                var is_first = true
                var pivot_points = [SCNVector3(), SCNVector3()] //Positions for point-to-point line
                var point_index = 0
                
                for point in points
                {
                    var visual_point = SCNNode() //Create the point node
                    
                    node_by_data(node: &visual_point, point: point, location: &point_location)
                    
                    //Change point node color by selection state
                    if point_index == selected_point_index
                    {
                        visual_point.geometry?.firstMaterial?.diffuse.contents = selected_point_color
                    }
                    else
                    {
                        visual_point.geometry?.firstMaterial?.diffuse.contents = target_point_color
                    }
                    
                    if is_first == true
                    {
                        //If point is first – save first location for the point-to-point line
                        pivot_points[0] = point_location
                        is_first = false
                    }
                    else
                    {
                        //If point is not first – build point-to-point line between the neighboring points
                        #if os(macOS)
                        pivot_points[1] = SCNVector3(point_location.x + CGFloat.random(in: -0.001..<0.001), point_location.y + CGFloat.random(in: -0.001..<0.001), point_location.z + CGFloat.random(in: -0.001..<0.001))
                        #else
                        pivot_points[1] = SCNVector3(point_location.x + Float.random(in: -0.001..<0.001), point_location.y + Float.random(in: -0.001..<0.001), point_location.z + Float.random(in: -0.001..<0.001))
                        #endif
                        
                        positions_group.addChildNode(build_ptp_line(from: simd_float3(pivot_points[0]), to: simd_float3(pivot_points[1]))) //Add point-to-point line model to the positions node
                        pivot_points[0] = pivot_points[1] //Update first point for point-to-point line
                    }
                    
                    positions_group.addChildNode(visual_point.clone()) //Add point model with point-to-point line to points model
                    point_index += 1 //Increment index
                }
            }
            else
            {
                //MARK: If there is only one point
                var visual_point = SCNNode() //Create the point node
                visual_point.geometry = SCNSphere(radius: 4) //Add sphere geometry to the point node
                
                let point = points.first ?? PositionPoint() //Get first point data
                
                node_by_data(node: &visual_point, point: point, location: &point_location)
                
                //Change point node color by selection state
                if selected_point_index == 0
                {
                    visual_point.geometry?.firstMaterial?.diffuse.contents = selected_point_color
                }
                else
                {
                    visual_point.geometry?.firstMaterial?.diffuse.contents = target_point_color
                }
                
                positions_group.addChildNode(visual_point)
            }
        }
        
        func build_ptp_line(from: simd_float3, to: simd_float3) -> SCNNode //Build line between the neighboring points
        {
            let vector = to - from
            let height = simd_length(vector)
            
            let cylinder = SCNCylinder(radius: 2, height: CGFloat(height))
            
            cylinder.firstMaterial?.diffuse.contents = cylinder_color
            //cylinder.firstMaterial?.transparency = 0.5
            
            let line_node = SCNNode(geometry: cylinder)
            
            let line_axis = simd_float3(0, height/2, 0)
            line_node.simdPosition = from + line_axis

            let vector_cross = simd_cross(line_axis, vector)
            let qw = simd_length(line_axis) * simd_length(vector) + simd_dot(line_axis, vector)
            let q = simd_quatf(ix: vector_cross.x, iy: vector_cross.y, iz: vector_cross.z, r: qw).normalized

            line_node.simdRotate(by: q, aroundTarget: from)
            return line_node
        }
        
        func node_by_data(node: inout SCNNode, point: PositionPoint, location: inout SCNVector3) //Add geometry for position point node by position data
        {
            node.geometry = SCNSphere(radius: 4) //Add sphere geometry to the point node
            
            //Set point node location
            #if os(macOS)
            location = SCNVector3(x: CGFloat(point.y) - 100, y: CGFloat(point.z) - 100, z: CGFloat(point.x) - 100)
            #else
            location = SCNVector3(x: point.y - 100, y: point.z - 100, z: point.x - 100)
            #endif
            node.position = location
            
            let internal_cone_node = cone_node.clone() //Add cones for point rotated by position in point rotation
            
            //Rotate cone node by roll angle
            #if os(macOS)
            internal_cone_node.eulerAngles.z = CGFloat(point.r.to_rad)
            #else
            internal_cone_node.eulerAngles.z = point.r.to_rad
            #endif
            
            node.addChildNode(internal_cone_node) //Add cone model to point
            
            //Rotate point node by pitch and yaw angles
            #if os(macOS)
            node.eulerAngles.x = CGFloat(point.p.to_rad)
            node.eulerAngles.y = CGFloat(point.w.to_rad)
            #else
            node.eulerAngles.x = point.p.to_rad
            node.eulerAngles.y = point.w.to_rad
            #endif
        }
    }
    
    public func visual_clear() //Remove positions points models from cell
    {
        positions_group.enumerateChildNodes
        { (node, stop) in
            node.removeFromParentNode()
        }
    }
    
    //MARK: - Create moving group for robot
    public func points_moving_group(move_time: TimeInterval) -> (moving: [SCNAction], rotation: [SCNAction])
    {
        var moving_position: SCNVector3
        var moving_rotation: [Float] = [0.0, 0.0, 0.0]
        
        var movings_array = [SCNAction]() //Position moving array by position program
        var movings_array2 = [SCNAction]() //Rotation moving array by position program for tool node
        
        if points.count > 0
        {
            for point in points
            {
                moving_position = SCNVector3(point.y, point.z, point.x) //Convert location to scnvector
                moving_rotation = [point.p.to_rad, point.w.to_rad, 0] //Get rotation from from position point
                
                //Append scnactions
                movings_array.append(SCNAction.group([SCNAction.move(to: moving_position, duration: move_time), SCNAction.rotateTo(x: CGFloat(moving_rotation[0]), y: CGFloat(moving_rotation[1]), z: CGFloat(moving_rotation[2]), duration: move_time)]))
                movings_array2.append(SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(point.r.to_rad), duration: move_time))
            }
        }
        
        return (movings_array, movings_array2)
    }
    
    //MARK: - Work with file system
    public var file_info: program_struct
    {
        return program_struct(name: name ?? "None", points: self.points)
    }
}

//MARK: - Program structure for workspace preset document handling
public struct program_struct: Codable
{
    var name: String
    var points = [PositionPoint]()
}

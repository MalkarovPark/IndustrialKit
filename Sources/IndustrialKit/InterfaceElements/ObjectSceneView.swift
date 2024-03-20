//
//  SwiftUIView.swift
//  
//
//  Created by Artem on 06.11.2023.
//

import SwiftUI
import SceneKit

public struct ObjectSceneView: UIViewRepresentable
{
    private let scene_view = SCNView(frame: .zero)
    private let viewed_scene: SCNScene
    private let node: SCNNode
    private let on_render: ((_ scene_view: SCNView) -> Void)
    private let on_tap: ((_ recognizer: UITapGestureRecognizer, _ scene_view: SCNView) -> Void)
    
    private var inited_with_scene = false
    private var inited_with_node = false
    
    //MARK: Init functions
    public init(node: SCNNode, on_render: @escaping (_ scene_view: SCNView) -> Void = { _ in }, on_tap: @escaping (_: UITapGestureRecognizer, _: SCNView) -> Void = { _, _ in })
    {
        self.viewed_scene = SCNScene()
        self.node = node
        
        self.on_render = on_render
        self.on_tap = on_tap
        self.inited_with_node = true
    }
    
    /*public init(node: SCNNode = SCNNode(), scene: SCNScene = SCNScene(), on_render: @escaping (_ scene_view: SCNView) -> Void = { _ in }, on_tap: @escaping (_: UITapGestureRecognizer, _: SCNView) -> Void = { _, _ in })
    {
        self.node = node
        self.viewed_scene = scene
        
        self.on_render = on_render
        self.on_tap = on_tap
        self.inited_with_node = true
    }*/
    
    public init(scene: SCNScene, on_render: @escaping (_ scene_view: SCNView) -> Void = { _ in }, on_tap: @escaping (_: UITapGestureRecognizer, _: SCNView) -> Void = { _, _ in })
    {
        self.viewed_scene = scene
        self.node = SCNNode()
        
        self.on_render = on_render
        self.on_tap = on_tap
        
        self.inited_with_scene = true
    }
    
    public init(scene: SCNScene, node: SCNNode, on_render: @escaping (_ scene_view: SCNView) -> Void = { _ in }, on_tap: @escaping (_: UITapGestureRecognizer, _: SCNView) -> Void = { _, _ in })
    {
        self.viewed_scene = scene
        self.node = node
        
        self.on_render = on_render
        self.on_tap = on_tap
        
        self.inited_with_node = true
        self.inited_with_scene = true
    }
    
    #if os(macOS)
    private let base_camera_position_node = SCNNode()
    #endif
    
    func scn_scene(context: Context) -> SCNView
    {
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        scene_view.scene?.background.contents = UIColor.clear
        
        if inited_with_node
        {
            let new_node = node.clone()
            new_node.name = "Node"
            
            scene_view.scene?.rootNode.addChildNode(new_node)
            //scene_view.scene?.rootNode.addChildNode(node.clone())
        }
        
        if inited_with_scene
        {
            #if os(macOS)
            base_camera_position_node.position = scene_view.pointOfView?.position ?? SCNVector3(0, 0, 2)
            base_camera_position_node.rotation = scene_view.pointOfView?.rotation ?? SCNVector4Zero
            #endif
        }
        
        return scene_view
    }
    
    //MARK: Scene functions
    #if os(macOS)
    public func makeNSView(context: Context) -> SCNView
    {
        //Add gesture recognizer
        scene_view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:))))
        
        //Add reset double tap recognizer for macOS
        let double_tap_gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_reset_double_tap(_:)))
        double_tap_gesture.numberOfClicksRequired = 2
        scene_view.addGestureRecognizer(double_tap_gesture)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = UIColor.clear
        
        return scn_scene(context: context)
    }
    #else
    public func makeUIView(context: Context) -> SCNView
    {
        //Add gesture recognizer
        scene_view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:))))
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = UIColor.clear
        
        if !inited_with_scene //&& inited_with_node
        {
            let camera_node = SCNNode()
            camera_node.camera = SCNCamera()
            camera_node.position = SCNVector3(0, 0, 2)
            viewed_scene.rootNode.addChildNode(camera_node)
            scene_view.pointOfView = camera_node
        }
        
        return scn_scene(context: context)
    }
    #endif
    
    #if os(macOS)
    public func updateNSView(_ ui_view: SCNView, context: Context)
    {
        
    }
    #else
    public func updateUIView(_ ui_view: SCNView, context: Context)
    {
        
    }
    #endif
    
    public func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final public class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ObjectSceneView
        
        init(_ control: ObjectSceneView, _ scn_view: SCNView)
        {
            self.control = control
            
            self.scn_view = scn_view
            super.init()
        }
        
        public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.on_render(scn_view)
        }
        
        private let scn_view: SCNView
        
        #if os(macOS)
        private var on_reset_view = false
        #endif
        
        @objc func handle_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            control.on_tap(gesture_recognize, scn_view)
        }
        
        #if os(macOS)
        @objc func handle_reset_double_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            reset_camera_view_position(locataion: SCNVector3(0, 0, 2), rotation: SCNVector4Zero, view: scn_view)
            
            func reset_camera_view_position(locataion: SCNVector3, rotation: SCNVector4, view: SCNView)
            {
                if !on_reset_view
                {
                    on_reset_view = true
                    
                    let reset_action = SCNAction.group([SCNAction.move(to: control.base_camera_position_node.position, duration: 0.5), SCNAction.rotate(toAxisAngle: control.base_camera_position_node.rotation, duration: 0.5)])
                    scn_view.defaultCameraController.pointOfView?.runAction(
                        reset_action, completionHandler: { self.on_reset_view = false })
                }
            }
        }
        #endif
    }
}

//MARK: - Scene Views typealilases
#if os(macOS)
public typealias UIViewRepresentable = NSViewRepresentable
public typealias UITapGestureRecognizer = NSClickGestureRecognizer
#endif

struct ObjectSceneView_PreviewsContainer: PreviewProvider
{
    struct Container: View
    {
        var body: some View
        {
            ObjectSceneView_Previews()
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    struct ObjectSceneView_Previews: View
    {
        @State var node = SCNNode(geometry: SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1))
        
        var body: some View
        {
            ObjectSceneView(node: node)
                .onAppear
                {
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.671, green: 0.533, blue: 1, alpha: 1)
                }
        }
    }
}

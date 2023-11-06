//
//  SwiftUIView.swift
//  
//
//  Created by Artiom Malkarov on 06.11.2023.
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
    
    private var inited_with_scene = true
    private var inited_with_node = true
    
    //MARK: Init functions
    public init(node: SCNNode)
    {
        self.viewed_scene = SCNScene()
        self.node = node
        
        self.on_render = {_ in }
        self.on_tap = {_, _ in }
        
        self.inited_with_node = true
    }
    
    public init(node: SCNNode, on_render: @escaping (_ scene_view: SCNView) -> Void, on_tap: @escaping (_: UITapGestureRecognizer, _: SCNView) -> Void)
    {
        self.viewed_scene = SCNScene()
        self.node = node
        
        self.on_render = on_render
        self.on_tap = on_tap
        
        self.inited_with_node = true
    }
    
    public init(scene: SCNScene)
    {
        self.viewed_scene = scene
        self.node = SCNNode()
        
        self.on_render = {_ in }
        self.on_tap = {_, _ in }
        
        self.inited_with_scene = true
    }
    
    public init(scene: SCNScene, on_render: @escaping (_ scene_view: SCNView) -> Void, on_tap: @escaping (_: UITapGestureRecognizer, _: SCNView) -> Void)
    {
        self.viewed_scene = scene
        self.node = SCNNode()
        
        self.on_render = on_render
        self.on_tap = on_tap
        
        self.inited_with_scene = true
    }
    
    public init(scene: SCNScene, node: SCNNode)
    {
        self.viewed_scene = scene
        self.node = node
        
        self.on_render = {_ in }
        self.on_tap = {_, _ in }
        
        self.inited_with_scene = true
        self.inited_with_node = true
    }
    
    public init(scene: SCNScene, on_render: @escaping (_ scene_view: SCNView) -> Void, node: SCNNode, on_tap: @escaping (_: UITapGestureRecognizer, _: SCNView) -> Void)
    {
        self.viewed_scene = scene
        self.node = node
        
        self.on_render = on_render
        self.on_tap = on_tap
        
        self.inited_with_scene = true
        self.inited_with_node = true
    }
    
    func scn_scene(context: Context) -> SCNView
    {
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        scene_view.scene?.background.contents = UIColor.clear
        
        if inited_with_node
        {
            scene_view.scene?.rootNode.addChildNode(node.clone())
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
    #else
    func makeUIView(context: Context) -> SCNView
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
    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        
    }
    #endif
    
    public func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view, on_tap: on_tap)
    }
    
    final public class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ObjectSceneView
        var on_tap: (UITapGestureRecognizer, SCNView) -> ()
        
        init(_ control: ObjectSceneView, _ scn_view: SCNView, on_tap: @escaping (UITapGestureRecognizer, SCNView) -> ())
        {
            self.control = control
            self.on_tap = on_tap
            
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
            on_tap(gesture_recognize, scn_view)
        }
        
        @objc func handle_reset_double_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            reset_camera_view_position(locataion: SCNVector3(0, 0, 2), rotation: SCNVector4Zero, view: scn_view)
            
            func reset_camera_view_position(locataion: SCNVector3, rotation: SCNVector4, view: SCNView)
            {
                if !on_reset_view
                {
                    on_reset_view = true
                    
                    let reset_action = SCNAction.group([SCNAction.move(to: locataion, duration: 0.5), SCNAction.rotate(toAxisAngle: rotation, duration: 0.5)])
                    view.defaultCameraController.pointOfView?.runAction(
                        reset_action, completionHandler: { self.on_reset_view = false })
                }
            }
        }
    }
}

//MARK: - Scene Views typealilases
#if os(macOS)
public typealias UIViewRepresentable = NSViewRepresentable
public typealias UITapGestureRecognizer = NSClickGestureRecognizer
#endif

#Preview
{
    ObjectSceneView(node: SCNNode())
}

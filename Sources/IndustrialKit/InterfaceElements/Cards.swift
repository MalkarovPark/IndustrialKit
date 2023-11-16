//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Malkarov Park on 22.12.2022.
//

import SwiftUI
import SceneKit

//MARK: - Large card view
public struct LargeCardView: View
{
    //View parameters
    @State public var color: Color
    let image: UIImage?
    let node: SCNNode?
    @State public var title: String
    @State public var subtitle: String
    
    //Rename parameters
    @Binding public var to_rename: Bool
    @Binding public var edited_name: String
    @State private var new_name: String
    @FocusState private var is_focused: Bool
    let on_rename: () -> ()
    
    public init(color: Color, image: UIImage?, title: String, subtitle: String)
    {
        self.color = color
        self.image = image
        self.node = nil
        self.title = title
        self.subtitle = subtitle
        
        self._to_rename = .constant(false)
        self._edited_name = .constant("")
        self.new_name = ""
        self.on_rename = { }
    }
    
    public init(color: Color, image: UIImage?, title: String, subtitle: String, to_rename: Binding<Bool>, edited_name: Binding<String>, on_rename: @escaping () -> ())
    {
        self.color = color
        self.image = image
        self.node = nil
        self.title = title
        self.subtitle = subtitle
        
        self._to_rename = to_rename
        self._edited_name = edited_name
        _new_name = State(initialValue: _edited_name.wrappedValue)
        self.on_rename = on_rename
    }
    
    public init(color: Color, node: SCNNode?, title: String, subtitle: String)
    {
        self.color = color
        self.image = nil
        self.node = node
        self.title = title
        self.subtitle = subtitle
        
        self._to_rename = .constant(false)
        self._edited_name = .constant("")
        self.new_name = ""
        self.on_rename = { }
    }
    
    public init(color: Color, node: SCNNode?, title: String, subtitle: String, to_rename: Binding<Bool>, edited_name: Binding<String?>, on_rename: @escaping () -> ())
    {
        self.color = color
        self.image = nil
        self.node = node
        self.title = title
        self.subtitle = subtitle
        
        self._to_rename = to_rename
        self._edited_name = Binding<String>(
            get: {
                edited_name.wrappedValue ?? ""
            },
            set: {
                edited_name.wrappedValue = $0
            }
        )
        _new_name = State(initialValue: _edited_name.wrappedValue)
        self.on_rename = on_rename
    }
    
    public var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundColor(color)
                .overlay
            {
                if image != nil
                {
                    #if os(macOS)
                    Image(nsImage: image!)
                        .resizable()
                        .scaledToFill()
                    #else
                    Image(uiImage: image!)
                        .resizable()
                        .scaledToFill()
                    #endif
                }
                
                if node != nil
                {
                    ObjectSceneView(node: node!)
                        .disabled(true)
                }
            }
            
            VStack
            {
                Spacer()
                HStack
                {
                    if !to_rename
                    {
                        VStack(alignment: .leading)
                        {
                            Text(title)
                                .font(.headline)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                            
                            Text(subtitle)
                                .foregroundColor(.gray)
                                .padding(.bottom, 8)
                                .padding(.leading, 4)
                        }
                        .padding(.horizontal, 8)
                        Spacer()
                    }
                    else
                    {
                        VStack(alignment: .leading)
                        {
                            HStack
                            {
                                #if os(macOS)
                                TextField("Name", text: $new_name)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($is_focused)
                                    .labelsHidden()
                                    .padding()
                                    .onSubmit
                                    {
                                        edited_name = new_name
                                        title = new_name
                                        on_rename()
                                        to_rename = false
                                    }
                                    .onExitCommand
                                    {
                                        to_rename = false
                                    }
                                #else
                                TextField("Name", text: $title, onCommit: {
                                    edited_name = new_name
                                    title = new_name
                                    on_rename()
                                    to_rename = false
                                })
                                    .textFieldStyle(.roundedBorder)
                                    .focused($is_focused)
                                    .labelsHidden()
                                    .padding()
                                #endif
                            }
                        }
                    }
                }
                .background(color.opacity(0.2))
                .background(.thinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .frame(height: 192)
        //.shadow(radius: 8)
    }
}

//MARK: Circle button for large card
public struct CircleDeleteButtonModifier: ViewModifier
{
    @State private var delete_alert_presented = false
    
    let workspace: Workspace
    
    let object_item: WorkspaceObject
    let objects: [WorkspaceObject]
    let on_delete: (IndexSet) -> ()
    
    public var object_type_name: String
    
    public init(workspace: Workspace, object_item: WorkspaceObject, objects: [WorkspaceObject], on_delete: @escaping (IndexSet) -> (), object_type_name: String)
    {
        self.workspace = workspace
        self.object_item = object_item
        self.objects = objects
        self.on_delete = on_delete
        self.object_type_name = object_type_name
    }
    
    public func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .topTrailing)
        {
            Spacer()
            
            ZStack
            {
                Image(systemName: "xmark")
                    .padding(4.0)
            }
            .frame(width: 24, height: 24)
            .background(.thinMaterial)
            .clipShape(Circle())
            .onTapGesture
            {
                delete_alert_presented = true
            }
            .padding(8.0)
        }
        .alert(isPresented: $delete_alert_presented)
        {
            Alert(
                title: Text("Delete \(object_type_name)?"),
                message: Text("Do you want to delete this \(object_type_name) – \(object_item.name)"),
                primaryButton: .destructive(Text("Yes"), action: delete_object),
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
    
    func delete_object()
    {
        if let index = objects.firstIndex(of: object_item)
        {
            self.on_delete(IndexSet(integer: index))
            workspace.elements_check()
        }
    }
}

//MARK: - Small card view
public struct SmallCardView: View
{
    //View properties
    @State public var color: Color
    let image: UIImage?
    let node: SCNNode?
    @State public var title: String
    
    //Rename properties
    @Binding public var to_rename: Bool
    @Binding public var edited_name: String
    @State private var new_name: String
    @FocusState private var is_focused: Bool
    let on_rename: () -> ()
    
    public init(color: Color, image: UIImage?, title: String)
    {
        self.color = color
        self.image = image
        self.node = nil
        self.title = title
        
        self._to_rename = .constant(false)
        self._edited_name = .constant("")
        self.new_name = ""
        self.on_rename = { }
    }
    
    public init(color: Color, image: UIImage?, title: String, to_rename: Binding<Bool>, edited_name: Binding<String>, on_rename: @escaping () -> ())
    {
        self.color = color
        self.image = image
        self.node = nil
        self.title = title
        
        self._to_rename = to_rename
        self._edited_name = edited_name
        _new_name = State(initialValue: _edited_name.wrappedValue)
        self.on_rename = on_rename
    }
    
    public init(color: Color, node: SCNNode?, title: String)
    {
        self.color = color
        self.image = nil
        self.node = node
        self.title = title
        
        self._to_rename = .constant(false)
        self._edited_name = .constant("")
        self.new_name = ""
        self.on_rename = { }
    }
    
    public init(color: Color, node: SCNNode?, title: String, to_rename: Binding<Bool>, edited_name: Binding<String?>, on_rename: @escaping () -> ())
    {
        self.color = color
        self.image = nil
        self.node = node
        self.title = title
        
        self._to_rename = to_rename
        self._edited_name = Binding<String>(
            get: {
                edited_name.wrappedValue ?? ""
            },
            set: {
                edited_name.wrappedValue = $0
            }
        )
        _new_name = State(initialValue: _edited_name.wrappedValue)
        self.on_rename = on_rename
    }
    
    public var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    HStack(spacing: 0)
                    {
                        if !to_rename
                        {
                            Text(title)
                                .font(.headline)
                                .padding()
                            
                            Spacer()
                        }
                        else
                        {
                            #if os(macOS)
                            TextField("Name", text: $new_name)
                                .focused($is_focused)
                                .labelsHidden()
                                .font(.headline)
                                .padding()
                                .onSubmit
                                {
                                    edited_name = new_name
                                    title = new_name
                                    on_rename()
                                    to_rename = false
                                }
                                .onExitCommand
                                {
                                    to_rename = false
                                }
                            #else
                            TextField("Name", text: $title, onCommit: {
                                edited_name = new_name
                                title = new_name
                                on_rename()
                                to_rename = false
                            })
                            .focused($is_focused)
                            .labelsHidden()
                            .font(.headline)
                            .padding()
                            #endif
                        }
                        
                        Rectangle()
                            .fill(.clear)
                            .overlay
                        {
                            if image != nil
                            {
                                #if os(macOS)
                                Image(nsImage: image!)
                                    .resizable()
                                    .scaledToFill()
                                #else
                                Image(uiImage: image!)
                                    .resizable()
                                    .scaledToFill()
                                #endif
                            }
                            
                            if node != nil
                            {
                                ObjectSceneView(node: node!)
                                    .disabled(true)
                                    .padding(8)
                            }
                        }
                        .frame(width: 64, height: 64)
                        .background(Color.clear)
                    }
                    
                    Rectangle()
                        .foregroundColor(color)
                        .frame(width: 32, height: 64)
                }
            }
            .background(.thinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        //.shadow(radius: 8)
    }
}

//MARK: Borderless button for small card
public struct BorderlessDeleteButtonModifier: ViewModifier
{
    @State private var delete_alert_presented = false
    
    let workspace: Workspace
    
    let object_item: WorkspaceObject
    let objects: [WorkspaceObject]
    let on_delete: (IndexSet) -> ()
    
    public var object_type_name: String
    
    public init(workspace: Workspace, object_item: WorkspaceObject, objects: [WorkspaceObject], on_delete: @escaping (IndexSet) -> (), object_type_name: String)
    {
        self.workspace = workspace
        self.object_item = object_item
        self.objects = objects
        self.on_delete = on_delete
        self.object_type_name = object_type_name
    }
    
    public func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .trailing)
        {
            ZStack
            {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(4.0)
            }
            .frame(width: 24, height: 24)
            .onTapGesture
            {
                delete_alert_presented = true
            }
            .padding(4.0)
        }
        .alert(isPresented: $delete_alert_presented)
        {
            Alert(
                title: Text("Delete \(object_type_name)?"),
                message: Text("Do you want to delete this \(object_type_name) – \(object_item.name)"),
                primaryButton: .destructive(Text("Delete"), action: delete_object),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    func delete_object()
    {
        if let index = objects.firstIndex(of: object_item)
        {
            self.on_delete(IndexSet(integer: index))
            workspace.elements_check()
        }
    }
}

//MARK: - Cards preview
struct Cards_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            VStack()
            {
                LargeCardView(color: .green, image: nil, title: "Title", subtitle: "Subtitle")
                    .shadow(radius: 8)
                    .modifier(CircleDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "name"))
                    .padding([.horizontal, .top])
                SmallCardView(color: .green, image: nil, title: "Title")
                    .shadow(radius: 8)
                    .modifier(BorderlessDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "none"))
                    .padding()
            }
            .padding(4)
            .frame(width: 320)
            //.background(.white)
            
            VStack()
            {
                LargeCardView(color: .gray, node: SCNNode(geometry: SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)), title: "Cube", subtitle: "Model")
                    .shadow(radius: 8)
                    .padding([.horizontal, .top])
                
                SmallCardView(color: .gray, node: SCNNode(geometry: SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)), title: "Cube")
                    .shadow(radius: 8)
                    .padding()
            }
            .padding(4)
            .frame(width: 320)
            //.background(.white)
        }
    }
}

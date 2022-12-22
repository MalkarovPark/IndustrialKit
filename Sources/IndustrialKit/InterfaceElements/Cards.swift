//
//  SwiftUIView.swift
//  
//
//  Created by Malkarov Park on 22.12.2022.
//

import SwiftUI

//MARK: - Large card view
public struct LargeCardView: View
{
    @State var color: Color
    #if os(macOS)
    @State var image: NSImage
    #else
    @State var image: UIImage
    #endif
    @State var title: String
    @State var subtitle: String
    
    public var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundColor(color)
                .overlay
            {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #else
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            }
            
            VStack
            {
                Spacer()
                HStack
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
                .background(color.opacity(0.2))
                .background(.thinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .frame(height: 192)
        .shadow(radius: 8.0)
    }
}

//MARK: Large card preview for drag
struct LargeCardViewPreview: View
{
    @State var color: Color
    #if os(macOS)
    @State var image: NSImage
    #else
    @State var image: UIImage
    #endif
    @State var title: String
    @State var subtitle: String
    
    var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundColor(color)
                .overlay
            {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #else
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            }
            
            VStack
            {
                Spacer()
                HStack
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
                .background(color.opacity(0.2))
                .background(.thinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .frame(height: 192)
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
    
    var object_type_name: String
    
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
                message: Text("Do you wand to delete this \(object_type_name) – \(object_item.name ?? "")"),
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
    @State var color: Color
    #if os(macOS)
    @State var image: NSImage
    #else
    @State var image: UIImage
    #endif
    @State var title: String
    
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
                        Text(title)
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(.clear)
                            .overlay
                        {
                            #if os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                            #else
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                            #endif
                        }
                        .frame(width: 64, height: 64)
                        .background(Color.clear)
                    }
                    /*.onTapGesture
                    {
                        part_view_presented = true
                    }
                    .popover(isPresented: $part_view_presented)
                    {
                        PartView(document: $document, part_item: $part_item)
                            .onDisappear()
                        {
                            part_view_presented = false
                        }
                    }*/
                    
                    Rectangle()
                        .foregroundColor(color)
                        .frame(width: 32, height: 64)
                }
            }
            .background(.thinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .shadow(radius: 8.0)
    }
}

//MARK: Small card preview for drag
public struct SmallCardViewPreview: View
{
    @State var color: Color
    #if os(macOS)
    @State var image: NSImage
    #else
    @State var image: UIImage
    #endif
    @State var title: String
    
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
                        Text(title)
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(.clear)
                            .overlay
                        {
                            #if os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                            #else
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                            #endif
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
    
    var object_type_name: String
    
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
                message: Text("Do you wand to delete this \(object_type_name) – \(object_item.name ?? "")"),
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
                #if os(macOS)
                LargeCardView(color: .green, image: NSImage(), title: "Title", subtitle: "Subtitle")
                    .modifier(CircleDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "name"))
                    .padding([.horizontal, .top])
                SmallCardView(color: .green, image: NSImage(), title: "Title")
                    .modifier(BorderlessDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "none"))
                    .padding()
                #else
                LargeCardView(color: .green, image: UIImage(), title: "Title", subtitle: "Subtitle")
                    .modifier(CircleDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "name"))
                    .padding([.horizontal, .top])
                SmallCardView(color: .green, image: UIImage(), title: "Title")
                    .modifier(BorderlessDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "none"))
                    .padding()
                #endif
            }
            .padding(4)
            //.background(.white)
        }
    }
}

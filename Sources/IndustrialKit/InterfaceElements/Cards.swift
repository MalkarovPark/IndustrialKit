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
    
    public init(color: Color, node: SCNNode?, title: String, subtitle: String, to_rename: Binding<Bool>, edited_name: Binding<String>, on_rename: @escaping () -> ())
    {
        self.color = color
        self.image = nil
        self.node = node
        self.title = title
        self.subtitle = subtitle
        
        self._to_rename = to_rename
        self._edited_name = edited_name
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
                            #if os(macOS) || os(iOS)
                                .foregroundColor(.gray)
                            #endif
                                .padding(.bottom, 8)
                                .padding(.leading, 4)
                        }
                        #if !os(visionOS)
                        .padding(.horizontal, 8)
                        #else
                        .padding(.horizontal, 32)
                        #endif
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
                                    .onAppear
                                    {
                                        is_focused = true
                                    }
                                #else
                                TextField("Name", text: $new_name, onCommit: {
                                    edited_name = new_name
                                    title = new_name
                                    on_rename()
                                    to_rename = false
                                })
                                    .textFieldStyle(.roundedBorder)
                                    .focused($is_focused)
                                    .labelsHidden()
                                    .padding()
                                    .onAppear
                                    {
                                        is_focused = true
                                    }
                                #endif
                            }
                        }
                    }
                }
                .background(color.opacity(0.2))
                .background(.thinMaterial)
            }
        }
        #if !os(visionOS)
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        #endif
        .frame(height: 192)
        #if os(visionOS)
        .glassBackgroundEffect()
        #endif
        //.shadow(radius: 8)
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
    
    public init(color: Color, node: SCNNode?, title: String, to_rename: Binding<Bool>, edited_name: Binding<String>, on_rename: @escaping () -> ())
    {
        self.color = color
        self.image = nil
        self.node = node
        self.title = title
        
        self._to_rename = to_rename
        self._edited_name = edited_name
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
                            #if os(visionOS)
                                .padding(.leading, 8)
                            #endif
                            
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
                                .onAppear
                                {
                                    is_focused = true
                                }
                            #else
                            TextField("Name", text: $new_name, onCommit: {
                                edited_name = new_name
                                title = new_name
                                on_rename()
                                to_rename = false
                            })
                            .onAppear
                            {
                                is_focused = true
                            }
                            .focused($is_focused)
                            .labelsHidden()
                            .font(.headline)
                            .padding()
                            #if os(visionOS)
                            .padding(.leading, 8)
                            #endif
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
        #if !os(visionOS)
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        #else
        .glassBackgroundEffect()
        #endif
        //.shadow(radius: 8)
    }
}

public struct ElementCardView: View
{
    let title: String
    let info: String
    let image: Image
    let color: Color
    let is_current: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    
    public init(title: String, info: String, image: Image, color: Color, is_current: Bool)
    {
        self.color = color
        self.image = image
        self.title = title
        self.info = info
        
        self.is_current = is_current
    }
    
    public init(title: String, info: String, image: Image, color: Color)
    {
        self.color = color
        self.image = image
        self.title = title
        self.info = info
        
        self.is_current = false
    }
    
    public var body: some View
    {
        ZStack
        {
            /*if is_current
            {
                Rectangle()
                    .foregroundStyle(.mint.opacity(0.5))
            }*/
            
            VStack
            {
                HStack(spacing: 0)
                {
                    ZStack
                    {
                        image
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .animation(.easeInOut(duration: 0.2), value: image)
                    }
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: color)
                    
                    HStack(spacing: 0)
                    {
                        HStack(spacing: 0)
                        {
                            VStack(alignment: .leading)
                            {
                                Text(title)
                                    .font(.title3)
                                    .animation(.easeInOut(duration: 0.2), value: title)
                                Text(info)
                                    .foregroundColor(.secondary)
                                    .animation(.easeInOut(duration: 0.2), value: info)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity)
            }
            .background(.thinMaterial)
        }
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        //.shadow(radius: 8)
        .overlay(alignment: .topTrailing)
        {
            if is_current
            {
                Circle()
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 16, height: 16)
                    .padding()
                    .transition(AnyTransition.scale)
            }
        }
    }
}

public struct RegisterCardView: View
{
    @Binding var value: Float
    
    public var number: Int
    public var color: Color
    
    public init(value: Binding<Float>, number: Int, color: Color)
    {
        self._value = value
        self.number = number
        self.color = color
    }
    
    public var body: some View
    {
        ZStack
        {
            VStack
            {
                VStack(spacing: 0)
                {
                    ZStack
                    {
                        TextField("0", value: $value, format: .number)
                            .font(.system(size: register_card_font_size))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                    }
                    #if os(macOS)
                    .frame(height: 48)
                    #else
                    .frame(height: 72)
                    #endif
                    .background(Color.clear)
                    
                    Rectangle()
                        .foregroundColor(color)
                    #if os(macOS)
                        .frame(height: 32)
                    #else
                        .frame(height: 48)
                    #endif
                        .overlay(alignment: .leading)
                        {
                            Text("\(number)")
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                            #if os(iOS) || os(visionOS)
                                .font(.system(size: 20))
                            #endif
                        }
                    #if !os(visionOS)
                        .shadow(radius: 2)
                    #endif
                }
            }
            .background(.thinMaterial)
        }
        .frame(width: register_card_scale, height: register_card_scale)
        .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
        #if !os(visionOS)
        .shadow(radius: 4)
        #else
        .frame(depth: 8)
        #endif
    }
}

//MARK: - Cards preview
struct Cards_Previews: PreviewProvider
{
    static var previews: some View
    {
        let element = MoverModifierElement(element_struct: WorkspaceProgramElementStruct(identifier: .mover_modifier, data: ["8", "16"]))
        
        Group
        {
            VStack()
            {
                LargeCardView(color: .green, image: nil, title: "Title", subtitle: "Subtitle")
                #if !os(visionOS)
                    .shadow(radius: 8)
                #else
                    .frame(depth: 24)
                #endif
                    .padding([.horizontal, .top])
                
                SmallCardView(color: .green, image: nil, title: "Title")
                #if !os(visionOS)
                    .shadow(radius: 8)
                #else
                    .frame(depth: 24)
                #endif
                    .padding()
            }
            .padding(4)
            .frame(width: 320)
            //.background(.white)
            
            VStack()
            {
                LargeCardView(color: .gray, node: SCNNode(geometry: SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)), title: "Cube", subtitle: "Model")
                #if !os(visionOS)
                    .shadow(radius: 8)
                #else
                    .frame(depth: 24)
                #endif
                    .padding([.horizontal, .top])
                
                SmallCardView(color: .gray, node: SCNNode(geometry: SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)), title: "Cube")
                #if !os(visionOS)
                    .shadow(radius: 8)
                #else
                    .frame(depth: 24)
                #endif
                    .padding()
            }
            .padding(4)
            .frame(width: 320)
            //.background(.white)
            
            VStack()
            {
                ElementCardView(title: element.title, info: element.info, image: element.image, color: element.color, is_current: true)
                #if !os(visionOS)
                    .shadow(radius: 8)
                #else
                    .frame(depth: 24)
                #endif
            }
            .padding(16)
            .frame(width: 288)
            
            VStack()
            {
                RegisterCardView(value: .constant(4), number: 60, color: .cyan)
                    .padding(16)
            }
        }
        .padding(8)
        //.background(.white)
    }
}

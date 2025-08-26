//
//  CardsView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI
import SceneKit
import IndustrialKit

//MARK: - Box card view
public struct BoxCard<Content: View>: View
{
    // View parameters
    @State public var title: String
    @State public var subtitle: String?
    let color: Color
    let image_name: String
    
    // Rename parameters
    @Binding public var to_rename: Bool
    @Binding public var edited_name: String
    @State private var new_name: String
    @FocusState private var is_focused: Bool
    let on_rename: () -> ()
    
    // Overlay
    let overlay_view: Content?
    
    private let default_color = Color(red: 192/255, green: 192/255, blue: 192/255)
    private let gradient: LinearGradient
    
    public init(
        title: String,
        subtitle: String? = nil,
        color: Color? = nil,
        image_name: String = String(),
        
        @ViewBuilder overlay: () -> Content? = { EmptyView() }
    )
    {
        self.title = title
        self.subtitle = subtitle
        self.color = color ?? default_color
        self.gradient = LinearGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: self.color.opacity(0.4), location: 0.0),
                Gradient.Stop(color: self.color.opacity(0.2), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        self.image_name = image_name
        
        self._to_rename = .constant(false)
        self._edited_name = .constant("")
        self.new_name = ""
        self.on_rename = { }
        
        self.overlay_view = overlay()
    }
    
    @State private var hovered = false
    
    public var body: some View
    {
        ZStack
        {
            // Shadow
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .intersection(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .offset(y: 10)
                )
                .foregroundStyle(color)
                .blur(radius: 16)
                .opacity(0.5)
            
            // Box
            ZStack
            {
                // Bottom
                Rectangle()
                    .foregroundStyle(color)
                    .brightness(-0.05)
                
                Rectangle()
                    .foregroundStyle(gradient)
                
                // Top
                VStack(spacing: 0)
                {
                    ZStack
                    {
                        Rectangle()
                            .foregroundStyle(color)
                        
                        Rectangle()
                            .foregroundStyle(gradient)
                            .overlay
                            {
                                Image(systemName: image_name)
                                    .fontWeight(.semibold)
                                    .font(.system(size: 96))
                                    .foregroundStyle(.black)
                                    .opacity(0.1)
                                    .padding()
                            }
                            .overlay(alignment: .bottomLeading)
                            {
                                // Rename Handling
                                HStack
                                {
                                    if !to_rename
                                    {
                                        VStack(alignment: .leading)
                                        {
                                            if let subtitle = subtitle
                                            {
                                                Text(title)
                                                    .font(.system(size: 28, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .padding(.top, 8)
                                                    .padding(.leading, 4)
                                                
                                                Text(subtitle)
                                                    .font(.system(size: 20, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .opacity(0.75)
                                                    .padding(.bottom, 8)
                                                    .padding(.leading, 4)
                                            }
                                            else
                                            {
                                                Text(title)
                                                    .font(.system(size: 28, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .padding(.vertical, 8)
                                                    .padding(.leading, 4)
                                            }
                                        }
                                        #if !os(visionOS)
                                        .padding(.horizontal, 8)
                                        #else
                                        .padding(.horizontal, 32)
                                        #endif
                                        .padding(.trailing, 4)
                                    }
                                    else
                                    {
                                        VStack(alignment: .leading)
                                        {
                                            HStack
                                            {
                                                #if os(macOS)
                                                TextField("Name", text: $new_name)
                                                    .font(.system(size: 28, design: .rounded))
                                                    .textFieldStyle(.plain)
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
                                                .font(.system(size: 28, design: .rounded))
                                                .textFieldStyle(.plain)
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
                                .padding(4)
                            }
                        
                        overlay_view
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Spacer(minLength: 10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onHover
            { hovered in
                withAnimation(.easeInOut(duration: 0.2))
                {
                    self.hovered = hovered
                }
            }
            .offset(y: hovered ? -2 : 0)
        }
    }
}

//MARK: - Glass box card view
public struct GlassBoxCard<Content: View>: View
{
    // View parameters
    @State public var title: String
    @State public var subtitle: String?
    let color: Color
    let image: UIImage?
    let node: SCNNode?
    
    // Rename parameters
    @Binding public var to_rename: Bool
    @Binding public var edited_name: String
    @State private var new_name: String
    @FocusState private var is_focused: Bool
    let on_rename: () -> ()
    
    // Overlay
    let overlay_view: Content?
    
    private let default_color = Color(red: 192/255, green: 192/255, blue: 192/255)
    private let gradient: LinearGradient
    
    public init(
        title: String,
        subtitle: String? = nil,
        color: Color? = nil,
        image: UIImage?,
        
        @ViewBuilder overlay: () -> Content? = { EmptyView() }
    )
    {
        self.node = nil
        self.title = title
        self.subtitle = subtitle
        self.color = color ?? default_color
        self.gradient = LinearGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: self.color.opacity(0.4), location: 0.0),
                Gradient.Stop(color: self.color.opacity(0.2), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        self.image = image
        
        self._to_rename = .constant(false)
        self._edited_name = .constant("")
        self.new_name = ""
        self.on_rename = { }
        
        self.overlay_view = overlay()
    }
    
    public init(
        title: String,
        subtitle: String? = nil,
        color: Color? = nil,
        image: UIImage?,
        
        to_rename: Binding<Bool>,
        edited_name: Binding<String>,
        on_rename: @escaping () -> (),
        
        @ViewBuilder overlay: () -> Content? = { EmptyView() }
    )
    {
        self.node = nil
        self.title = title
        self.subtitle = subtitle
        self.color = color ?? default_color
        self.gradient = LinearGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: self.color.opacity(0.4), location: 0.0),
                Gradient.Stop(color: self.color.opacity(0.2), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        self.image = image
        
        self._to_rename = to_rename
        self._edited_name = edited_name
        _new_name = State(initialValue: _edited_name.wrappedValue)
        self.on_rename = on_rename
        
        self.overlay_view = overlay()
    }
    
    public init(
        title: String,
        subtitle: String? = nil,
        color: Color? = nil,
        node: SCNNode?,
        
        @ViewBuilder overlay: () -> Content? = { EmptyView() }
    )
    {
        self.title = title
        self.subtitle = subtitle
        self.color = color ?? default_color
        self.gradient = LinearGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: self.color.opacity(0.4), location: 0.0),
                Gradient.Stop(color: self.color.opacity(0.2), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        self.image = nil
        self.node = node
        
        self._to_rename = .constant(false)
        self._edited_name = .constant("")
        self.new_name = ""
        self.on_rename = { }
        
        self.overlay_view = overlay()
    }
    
    public init(
        title: String,
        subtitle: String? = nil,
        color: Color? = nil,
        node: SCNNode?,
        
        to_rename: Binding<Bool>,
        edited_name: Binding<String>,
        on_rename: @escaping () -> (),
        
        @ViewBuilder overlay: () -> Content? = { EmptyView() }
    )
    {
        self.title = title
        self.subtitle = subtitle
        self.color = color ?? default_color
        self.gradient = LinearGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: self.color.opacity(0.4), location: 0.0),
                Gradient.Stop(color: self.color.opacity(0.2), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        self.image = nil
        self.node = node
        
        self._to_rename = to_rename
        self._edited_name = edited_name
        _new_name = State(initialValue: _edited_name.wrappedValue)
        self.on_rename = on_rename
        
        self.overlay_view = overlay()
    }
    
    @State private var hovered = false
    
    public var body: some View
    {
        ZStack
        {
            // Shadow
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .intersection(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .offset(y: 10)
                )
                .foregroundStyle(color)
                .blur(radius: 16)
                .opacity(0.1)
            
            // Box
            ZStack
            {
                // Bottom Side
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .intersection(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .offset(y: 10)
                    )
                    .foregroundStyle(gradient)
                    .opacity(0.2)
                
                // Back Side
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .subtracting(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .offset(y: 10)
                    )
                    .foregroundStyle(gradient)
                    .opacity(0.5)
                
                // Internals
                if image != nil
                {
                    #if os(macOS)
                    Image(nsImage: image!)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    #else
                    Image(uiImage: image!)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    #endif
                }
                
                if node != nil
                {
                    ObjectSceneView(node: node!)
                        .disabled(true)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                // Forward Side
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .subtracting(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .offset(y: -10)
                    )
                    .foregroundStyle(gradient)
                    .opacity(0.5)
                
                // Top Side
                VStack(spacing: 0)
                {
                    ZStack
                    {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .foregroundStyle(gradient)
                            .opacity(0.2)
                            .overlay(alignment: .bottomLeading)
                            {
                                // Rename Handling
                                HStack
                                {
                                    if !to_rename
                                    {
                                        VStack(alignment: .leading)
                                        {
                                            if let subtitle = subtitle
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
                                            else
                                            {
                                                Text(title)
                                                    .font(.headline)
                                                    .padding(.vertical, 8)
                                                    .padding(.leading, 4)
                                            }
                                        }
                                        #if !os(visionOS)
                                        .padding(.horizontal, 8)
                                        #else
                                        .padding(.horizontal, 32)
                                        #endif
                                        .padding(.trailing, 4)
                                        //Spacer()
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
                                .background(.bar)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .padding(8)
                            }
                        
                        overlay_view
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Spacer(minLength: 10)
                }
            }
            .onHover
            { hovered in
                withAnimation(.easeInOut(duration: 0.2))
                {
                    self.hovered = hovered
                }
            }
            .offset(y: hovered ? -2 : 0)
        }
        .frame(height: 192)
    }
}

//MARK: - Program element card view
public struct ProgramElementCard: View
{
    @StateObject var program_element: WorkspaceProgramElement
    
    public init(_ program_element: WorkspaceProgramElement)
    {
        _program_element = StateObject(wrappedValue: program_element)
    }
    
    public var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    ZStack
                    {
                        program_element.image
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .animation(.easeInOut(duration: 0.2), value: program_element.image)
                    }
                    .frame(width: 48, height: 48)
                    .background(program_element.color)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: program_element.color)
                    
                    HStack(spacing: 0)
                    {
                        HStack(spacing: 0)
                        {
                            VStack(alignment: .leading)
                            {
                                Text(program_element.title)
                                    .font(.title3)
                                    .animation(.easeInOut(duration: 0.2), value: program_element.title)
                                Text(program_element.info)
                                    .foregroundColor(.secondary)
                                    .animation(.easeInOut(duration: 0.2), value: program_element.info)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity)
            }
            .background(.white)
            
            if program_element.performing_state != .none
            {
                VStack
                {
                    HStack
                    {
                        Spacer()
                        
                        Circle()
                            .foregroundColor(program_element.performing_state.color.opacity(0.5))
                            .frame(width: 16, height: 16)
                            .padding()
                            .transition(AnyTransition.scale)
                        
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

public struct RegisterCard: View
{
    @Binding var value: Float
    
    public var number: Int
    public var color: Color
    private let gradient: LinearGradient
    
    public init(value: Binding<Float>, number: Int, color: Color)
    {
        self._value = value
        self.number = number
        self.color = color
        self.gradient = LinearGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: .clear, location: 0.0),
                Gradient.Stop(color: .white.opacity(0.1), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    public var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundStyle(color)
                .brightness(-0.05)
            
            Rectangle()
                .foregroundStyle(gradient)
            
            VStack(spacing: 0)
            {
                ZStack
                {
                    Rectangle()
                        .foregroundStyle(color)
                    
                    Rectangle()
                        .foregroundStyle(gradient)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Spacer(minLength: 4)
            }
            
            TextField("0", value: $value, format: .number)
                .font(.system(size: register_card_font_size))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .textFieldStyle(.plain)
            #if !os(macOS)
                .keyboardType(.decimalPad)
            #endif
        }
        .frame(width: register_card_scale, height: register_card_scale)
        .overlay(alignment: .bottomLeading)
        {
            Text("\(number)")
                .foregroundColor(.white)
                .padding(10)
            #if os(iOS) || os(visionOS)
                .font(.system(size: 20))
            #endif
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        #if !os(visionOS)
        .shadow(color: color.opacity(0.2), radius: 8)
        #else
        .frame(depth: 8)
        #endif
    }
}

#if os(macOS)
let register_card_scale: CGFloat = 80
let register_card_spacing: CGFloat = 16
let register_card_font_size: CGFloat = 20
#else
let register_card_scale: CGFloat = 112
let register_card_spacing: CGFloat = 20
let register_card_font_size: CGFloat = 32
#endif

//MARK: - Cards preview
struct Cards_Previews: PreviewProvider
{
    static var previews: some View
    {
        let element = MoverModifierElement(element_struct: WorkspaceProgramElementStruct(identifier: .mover_modifier, data: ["8", "16"]))
        
        Group
        {
            VStack(spacing: 0)
            {
                VStack()
                {
                    BoxCard(title: "Robotic", subtitle: "Workspace", color: .teal, image_name: "cube")
                        .padding()
                }
                .padding(4)
                .frame(width: 320, height: 192)
                
                VStack()
                {
                    GlassBoxCard(title: "Title", color: .green, image: nil)
                        .padding()
                }
                .padding(4)
                .frame(width: 320)
                
                VStack()
                {
                    GlassBoxCard(title: "Cube", subtitle: "Model", node: SCNNode(geometry: SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)))
                        .padding()
                }
                .padding(4)
                .frame(width: 320)
            }
            
            VStack()
            {
                ProgramElementCard(element)
                #if !os(visionOS)
                    .shadow(color: .black.opacity(0.2), radius: 8)
                #else
                    .frame(depth: 24)
                #endif
            }
            .padding(16)
            .frame(width: 288)
            
            VStack()
            {
                RegisterCard(value: .constant(4), number: 60, color: .cyan)
                    .padding(16)
            }
        }
        .padding(8)
    }
}

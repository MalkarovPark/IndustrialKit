//
//  CardsView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI
import SceneKit
import IndustrialKit

//MARK: - Large card view
public struct LargeCardView<Content: View>: View
{
    // View parameters
    @State public var title: String
    @State public var subtitle: String?
    let color: Color?
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
        self.color = color
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
        self.color = color
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
        self.color = color
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
        self.color = color
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
            if let color = color
            {
                Rectangle()
                    .foregroundStyle(color)
                    .opacity(0.5)
            }
            
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
            
            Rectangle()
                .subtracting(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .offset(y: -10)
                )
                .foregroundStyle(
                    .linearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 239 / 255, green: 239 / 255, blue: 242 / 255), location: 0.0),
                            Gradient.Stop(color: Color(red: 242 / 255, green: 242 / 255, blue: 243 / 255), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(0.75)
                .brightness(-0.05)
            
            VStack(spacing: 0)
            {
                ZStack
                {
                    Rectangle()
                        .foregroundStyle(
                            .linearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 239 / 255, green: 239 / 255, blue: 242 / 255), location: 0.0),
                                    Gradient.Stop(color: Color(red: 242 / 255, green: 242 / 255, blue: 243 / 255), location: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(0.5)
                        .overlay(alignment: .bottomLeading)
                        {
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
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                //.opacity(0.5)
                
                Spacer(minLength: 10)
            }
            
            overlay_view
        }
        #if !os(visionOS)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        #endif
        .frame(height: 192)
        #if os(visionOS)
        .glassBackgroundEffect()
        #endif
        .onHover
        { hovered in
            withAnimation
            {
                self.hovered = hovered
            }
        }
        .scaleEffect(hovered ? 1.02 : 1.0)
        // .shadow(radius: 8)
    }
}

//MARK: - Small card view
public struct SmallCardView: View
{
    // View properties
    @State public var color: Color
    let image: UIImage?
    let node: SCNNode?
    @State public var title: String
    
    // Rename properties
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
        // .shadow(radius: 8)
    }
}

public struct ElementCardView: View
{
    @StateObject var program_element: WorkspaceProgramElement
    
    public init(program_element: WorkspaceProgramElement)
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
            .background(.white)//.thinMaterial)
            
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
            Rectangle()
                .foregroundStyle(color)
                .brightness(-0.05)
            
            Rectangle()
                .foregroundStyle(
                    .linearGradient(
                        stops: [
                            Gradient.Stop(color: .clear, location: 0.0),
                            Gradient.Stop(color: .white.opacity(0.1), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(spacing: 0)
            {
                ZStack
                {
                    Rectangle()
                        .foregroundStyle(color)
                    
                    Rectangle()
                        .foregroundStyle(
                            .linearGradient(
                                stops: [
                                    Gradient.Stop(color: .clear, location: 0.0),
                                    Gradient.Stop(color: .white.opacity(0.1), location: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
            VStack()
            {
                LargeCardView(title: "Title", color: .green, image: nil)
                #if !os(visionOS)
                    .shadow(color: .black.opacity(0.2), radius: 8)
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
            // .background(.white)
            
            VStack()
            {
                LargeCardView(title: "Cube", subtitle: "Model", node: SCNNode(geometry: SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)))
                #if !os(visionOS)
                    .shadow(color: .black.opacity(0.2), radius: 8)
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
            // .background(.white)
            
            VStack()
            {
                ElementCardView(program_element: element)
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
        // .background(.white)
    }
}

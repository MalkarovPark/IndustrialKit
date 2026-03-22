//
//  CardsView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI
import RealityKit
import IndustrialKit

//MARK: - Box card view
public struct BoxCard<Content: View>: View
{
    // Titles
    let title: String?
    let subtitle: String?
    
    // Color
    let color: Color
    
    // Symbol
    let symbol_name: String
    let symbol_size: CGFloat
    let symbol_weight: Font.Weight
    
    // Rename
    @Binding public var is_renaming: Bool
    @State private var new_name: String
    @FocusState private var is_focused: Bool
    let on_rename: (String) -> ()
    
    // Overlay
    let overlay_view: Content?
    
    private let default_color = Color(red: 192/255, green: 192/255, blue: 192/255)
    private let gradient: LinearGradient
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        
        color: Color? = nil,
        
        symbol_name: String = String(),
        symbol_size: CGFloat = 96,
        symbol_weight: Font.Weight = .semibold,
        
        is_renaming: Binding<Bool> = .constant(false),
        on_rename: @escaping (String) -> () = { _ in },
        
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
        
        self.symbol_name = symbol_name
        self.symbol_size = symbol_size
        self.symbol_weight = symbol_weight
        
        self._is_renaming = is_renaming
        self.new_name = title ?? String()
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
                                Image(systemName: symbol_name)
                                    .font(.system(size: symbol_size))
                                    .fontWeight(symbol_weight)
                                    .foregroundStyle(.black)
                                    .opacity(0.1)
                                    .padding()
                            }
                            .overlay(alignment: .bottomLeading)
                            {
                                if let displayed_title = title
                                {
                                    // Rename Handling
                                    HStack
                                    {
                                        if !is_renaming
                                        {
                                            VStack(alignment: .leading)
                                            {
                                                if let subtitle = subtitle
                                                {
                                                    Text(displayed_title)
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
                                                    Text(displayed_title)
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
                                                        .foregroundColor(.white)
                                                        .textFieldStyle(.plain)
                                                        .focused($is_focused)
                                                        .labelsHidden()
                                                        .padding()
                                                        .onSubmit
                                                        {
                                                            on_rename(new_name)
                                                            is_renaming = false
                                                        }
                                                        .onExitCommand
                                                        {
                                                            is_renaming = false
                                                        }
                                                    #else
                                                    TextField("Name", text: $new_name, onCommit: {
                                                        on_rename(new_name)
                                                        is_renaming = false
                                                    })
                                                    .font(.system(size: 28, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .textFieldStyle(.plain)
                                                    .focused($is_focused)
                                                    .labelsHidden()
                                                    .padding()
                                                    #endif
                                                }
                                            }
                                        }
                                    }
                                    .padding(4)
                                    .onChange(of: is_renaming)
                                    { _, new_value in
                                        is_focused = new_value
                                    }
                                }
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
            .offset(y: hovered && !is_renaming ? -2 : 0)
        }
    }
}

//MARK: - Glass box card view
public struct GlassBoxCard<Content: View>: View
{
    // Titles
    let title: String?
    let subtitle: String?
    
    // Color
    let color: Color
    
    // Image
    let image: UIImage?
    
    // Symbol
    let symbol_name: String?
    let symbol_size: CGFloat
    let symbol_weight: Font.Weight
    
    // Entity
    let entity: Entity?
    private var vertical_entity_reposition = false
    
    // Rename
    @Binding public var is_renaming: Bool
    @State private var new_name: String
    @FocusState private var is_focused: Bool
    let on_rename: (String) -> ()
    
    // Overlay
    let overlay_view: Content?
    
    private let default_color = Color(red: 192/255, green: 192/255, blue: 192/255)
    private let gradient: LinearGradient
    
    // Init without any properties
    public init(
        color: Color? = nil,
        
        @ViewBuilder overlay: () -> Content? = { EmptyView() }
    )
    {
        self.color = color ?? default_color
        self.gradient = LinearGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: self.color.opacity(0.4), location: 0.0),
                Gradient.Stop(color: self.color.opacity(0.2), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        self.title = nil
        self.subtitle = nil
        self.image = nil
        
        self.symbol_name = nil
        self.symbol_size = 96
        self.symbol_weight = .semibold
        self.entity = nil
        
        self._is_renaming = .constant(false)
        self.new_name = title ?? String()
        self.on_rename = { _ in }
        
        self.overlay_view = overlay()
    }
    
    // Init with Image
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        
        color: Color? = nil,
        image: UIImage?,
        
        is_renaming: Binding<Bool> = .constant(false),
        on_rename: @escaping (String) -> () = { _ in },
        
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
        
        self.image = image
        
        self.symbol_name = nil
        self.symbol_size = 96
        self.symbol_weight = .semibold
        self.entity = nil
        
        self._is_renaming = is_renaming
        self.new_name = title ?? String()
        self.on_rename = on_rename
        
        self.overlay_view = overlay()
    }
    
    // Init with Symbol
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        
        color: Color? = nil,
        
        symbol_name: String = String(),
        symbol_size: CGFloat = 96,
        symbol_weight: Font.Weight = .semibold,
        
        is_renaming: Binding<Bool> = .constant(false),
        on_rename: @escaping (String) -> () = { _ in },
        
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
        
        self.symbol_name = symbol_name
        self.symbol_size = symbol_size
        self.symbol_weight = symbol_weight
        
        self.image = nil
        self.entity = nil
        
        self._is_renaming = is_renaming
        self.new_name = title ?? String()
        self.on_rename = on_rename
        
        self.overlay_view = overlay()
    }
    
    // Init with Entity
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        color: Color? = nil,
        
        entity: Entity?,
        vertical_repostion: Bool = false,
        
        is_renaming: Binding<Bool> = .constant(false),
        on_rename: @escaping (String) -> () = { _ in },
        
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
        
        self.entity = entity
        self.vertical_entity_reposition = vertical_repostion
        
        self.image = nil
        self.symbol_name = nil
        self.symbol_size = 96
        self.symbol_weight = .semibold
        
        self._is_renaming = is_renaming
        self.new_name = title ?? String()
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
                if let image = image
                {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .overlay
                        {
                            #if os(macOS)
                            Image(nsImage: image)
                            #else
                            Image(uiImage: image)
                            #endif
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                else if let symbol_name = symbol_name
                {
                    Image(systemName: symbol_name)
                        .font(.system(size: symbol_size))
                        .fontWeight(symbol_weight)
                        .foregroundStyle(.black)
                        .opacity(0.1)
                        .padding()
                }
                else if let entity = entity
                {
                    RealityView
                    { content in
                        content.add(entity)
                        
                        // Camera reposition
                        let camera = PerspectiveCamera()
                        //camera.camera.fieldOfViewInDegrees = 60
                        camera.position = [0, vertical_entity_reposition ? (entity.visualBounds(relativeTo: nil).extents.y) / 2 : 0, (entity.visualBounds(relativeTo: nil).extents.z) * 2]
                        
                        content.add(camera)
                        
                        /*let camera = PerspectiveCamera()
                        camera.camera.fieldOfViewInDegrees = 60
                        camera.position = [0, 0, 1]
                        //camera.rotate_x(by: -.pi / 6)
                        content.add(camera)*/
                    }
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
                                if let displayed_title = title
                                {
                                    // Rename Handling
                                    HStack
                                    {
                                        if !is_renaming
                                        {
                                            VStack(alignment: .leading)
                                            {
                                                if let subtitle = subtitle
                                                {
                                                    Text(displayed_title)
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
                                                    Text(displayed_title)
                                                        .font(.headline)
                                                        .padding(.vertical, 8)
                                                        .padding(.leading, 4)
                                                }
                                            }
                                            .padding(.horizontal, 8)
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
                                                            on_rename(new_name)
                                                            is_renaming = false
                                                        }
                                                        .onExitCommand
                                                        {
                                                            is_renaming = false
                                                        }
                                                    #else
                                                    TextField("Name", text: $new_name, onCommit: {
                                                        on_rename()
                                                        is_renaming = false
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
                                    #if !os(visionOS)
                                    .background(.bar)
                                    #else
                                    .background(.thinMaterial)
                                    #endif
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .padding(8)
                                    .onChange(of: is_renaming)
                                    { _, new_value in
                                        is_focused = new_value
                                    }
                                }
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
            .offset(y: hovered && !is_renaming ? -2 : 0)
        }
    }
}

//MARK: - Register card view
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
    struct Container: View
    {
        @State var is_renaming = [false, false, false]
        @State var names = ["Robotic", "Image", "Scene"]
        @State var values: [Float] = [2, 4, 6]
        
        var body: some View
        {
            Group
            {
                VStack(spacing: 0) //HStack(spacing: 0)
                {
                    VStack()
                    {
                        BoxCard(
                            title: names[0],
                            subtitle: "Workspace",
                            color: .teal,
                            symbol_name: "cube",
                            is_renaming: $is_renaming[0]
                        )
                        { new_name in
                            names[0] = new_name
                        }
                        .contextMenu
                        {
                            RenameButton()
                                .renameAction
                            {
                                withAnimation
                                {
                                    is_renaming[0].toggle()
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(4)
                    .frame(width: 320, height: 192)
                    
                    VStack()
                    {
                        GlassBoxCard(
                            title: names[1],
                            subtitle: "Color Wheel",
                            color: .green,
                            image: UIImage(named: "NSTouchBarColorPickerFill"),
                            is_renaming: $is_renaming[1]
                        )
                        { new_name in
                            names[1] = new_name
                        }
                        .contextMenu
                        {
                            RenameButton()
                                .renameAction
                            {
                                withAnimation
                                {
                                    is_renaming[1].toggle()
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(4)
                    .frame(width: 320, height: 192)
                    
                    VStack()
                    {
                        GlassBoxCard(
                            title: names[2],
                            entity: ModelEntity(
                                mesh: .generateBox(size: 1.0, cornerRadius: 0.1),
                                materials: [SimpleMaterial(color: .white, isMetallic: false)]
                            ),
                            is_renaming: $is_renaming[2]
                        )
                        { new_name in
                            names[2] = new_name
                        }
                        .contextMenu
                        {
                            RenameButton()
                                .renameAction
                            {
                                withAnimation
                                {
                                    is_renaming[2].toggle()
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(4)
                    .frame(width: 320, height: 192)
                }
                .padding(8)
                
                HStack(spacing: 24)
                {
                    RegisterCard(value: $values[0], number: 40, color: .mint)
                    
                    RegisterCard(value: $values[1], number: 60, color: .cyan)
                    
                    RegisterCard(value: $values[2], number: 20, color: .indigo)
                }
                .padding(16)
            }
            .padding(8)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    struct RegistersView_Previews: View
    {
        @Binding var registers: [Float]
        
        var body: some View
        {
            EmptyView()
        }
    }
    
    struct RegistersSelectors_Previews: View
    {
        @Binding var index: [Int]
        @Binding var indices: [Int]
        
        var body: some View
        {
            EmptyView()
        }
    }
    
    struct RegistersDataPreview: View
    {
        @State private var is_presented: Bool = false
        
        var body: some View
        {
            EmptyView()
        }
    }
}

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
    // View parameters
    @State public var title: String
    @State public var subtitle: String?
    let color: Color
    let image_name: String
    let image_size: CGFloat
    let image_weight: Font.Weight
    
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
        image_size: CGFloat = 96,
        image_weight: Font.Weight = .semibold,
        
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
        self.image_size = image_size
        self.image_weight = image_weight
        
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
                                    .font(.system(size: image_size))
                                    .fontWeight(image_weight)
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
    let entity: Entity?
    
    private var vertical_entity_reposition = false
    
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
        self.entity = nil
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
        self.entity = nil
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
        entity: Entity?,
        vertical_repostion: Bool = false,
        
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
        self.entity = entity
        self.vertical_entity_reposition = vertical_repostion
        
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
        entity: Entity?,
        vertical_repostion: Bool = false,
        
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
        self.entity = entity
        self.vertical_entity_reposition = vertical_repostion
        
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
                    /*#if os(macOS)
                    Image(nsImage: image!)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    #else
                    Image(uiImage: image!)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    #endif*/
                    
                    Rectangle()
                        .foregroundStyle(.clear)
                        .overlay
                        {
                            #if os(macOS)
                            Image(nsImage: image!)
                            #else
                            Image(uiImage: image!)
                            #endif
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                if entity != nil
                {
                    RealityView
                    { content in
                        content.add(entity ?? Entity())
                        
                        // Camera reposition
                        let camera = PerspectiveCamera()
                        //camera.camera.fieldOfViewInDegrees = 60
                        camera.position = [0, vertical_entity_reposition ? (entity?.visualBounds(relativeTo: nil).extents.y ?? 0) / 2 : 0, (entity?.visualBounds(relativeTo: nil).extents.z ?? 0) * 2]
                        
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
                                #if !os(visionOS)
                                .background(.bar)
                                #else
                                .background(.thinMaterial)
                                #endif
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
    }
}

//MARK: - Program element card view
public struct ProgramElementCard: View
{
    /*@StateObject var program_element: WorkspaceProgramElement
    
    public init(_ program_element: WorkspaceProgramElement)
    {
        _program_element = StateObject(wrappedValue: program_element)
    }*/
    
    @ObservedObject var program_element: WorkspaceProgramElement
    
    public init(_ program_element: WorkspaceProgramElement)
    {
        self.program_element = program_element
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
                        
                        Rectangle()
                            .foregroundStyle(LinearGradient(
                                gradient: Gradient(stops: [
                                    Gradient.Stop(color: .clear, location: 0.0),
                                    Gradient.Stop(color: .white.opacity(0.1), location: 1.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
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
            #if !os(visionOS)
            .background(.white)
            #else
            .background(.thinMaterial)
            #endif
            
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
    struct Container: View
    {
        @State var performer_element = RobotPerformerElement(element_struct: WorkspaceProgramElementStruct(identifier: .robot_performer, data: ["Device", "Program", "", "false", "false", "", "", "", "", "", "", "", ""]))
        @State var modifier_element = MoverModifierElement(element_struct: WorkspaceProgramElementStruct(identifier: .mover_modifier, data: ["duplicate", "2", "4"]))
        @State var logic_element = JumpLogicElement(element_struct: WorkspaceProgramElementStruct(identifier: .jump_logic, data: ["Mark"]))
        
        @State var to_rename = [false, false]
        @State var names = ["Image", "Scene"]
        @State var values: [Float] = [2, 4, 6]
        
        var body: some View
        {
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
                        GlassBoxCard(title: names[0], subtitle: "Color Wheel", color: .green, image: UIImage(named: "NSTouchBarColorPickerFill"), to_rename: $to_rename[0], edited_name: $names[0], on_rename: {})
                            .contextMenu
                            {
                                RenameButton()
                                    .renameAction
                                {
                                    withAnimation
                                    {
                                        to_rename[0].toggle()
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
                            entity: ModelEntity(
                                mesh: .generateBox(size: 1.0, cornerRadius: 0.1),
                                materials: [SimpleMaterial(color: .white, isMetallic: false)]
                            ),
                            /*entity: ModelEntity(
                                mesh: .generateBox(
                                    size: SIMD3<Float>(1.0, 1.0, 0.5), // X, Y, Z
                                    cornerRadius: 0.1
                                ),
                                materials: [
                                    SimpleMaterial(color: .white, isMetallic: false)
                                ]
                            ),*/
                            to_rename: $to_rename[1],
                            edited_name: $names[1],
                            on_rename: {}
                        )
                        .contextMenu
                        {
                            RenameButton()
                                .renameAction
                            {
                                withAnimation
                                {
                                    to_rename[1].toggle()
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(4)
                    .frame(width: 320, height: 192)
                }
                .padding(8)
                
                VStack(spacing: 24)
                {
                    ProgramElementCard(performer_element)
                        .shadow(color: .black.opacity(0.2), radius: 8)
                    
                    ProgramElementCard(modifier_element)
                        .shadow(color: .black.opacity(0.2), radius: 8)
                    
                    ProgramElementCard(logic_element)
                        .shadow(color: .black.opacity(0.2), radius: 8)
                }
                .padding(16)
                .frame(width: 288)
                
                HStack(spacing: 24)
                {
                    RegisterCard(value: $values[0], number: 40, color: .mint)
                    
                    RegisterCard(value: $values[1], number: 60, color: .cyan)
                    
                    RegisterCard(value: $values[2], number: 20, color: .indigo)
                }
                .padding(16)
            }
            .padding(8)
            .onAppear
            {
                performer_element.performing_state = .completed
            }
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

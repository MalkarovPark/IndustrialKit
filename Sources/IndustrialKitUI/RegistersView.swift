//
//  RegistersView.swift
//  IndustrialKit
//
//  Created by Artem on 16.12.2023.
//

import SwiftUI
import IndustrialKit

public struct RegistersView: View
{
    @Binding var registers: [Float]
    
    public let colors: [Color]
    
    private let numbers: [Int]
    
    private let top_spacing: CGFloat
    private let bottom_spacing: CGFloat
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: register_card_maximum, maximum: register_card_maximum), spacing: 0)]
    
    public init(registers: Binding<[Float]>, colors: [Color], top_spacing: CGFloat = 0, bottom_spacing: CGFloat = 0)
    {
        self._registers = registers
        self.numbers = (0...registers.count - 1).map { $0 }
        
        self.colors = colors
        
        self.top_spacing = top_spacing
        self.bottom_spacing = bottom_spacing
    }
    
    public init(registers: Binding<[Float]>)
    {
        self._registers = registers
        self.numbers = (0...registers.count - 1).map { $0 }
        
        self.colors = [Color](repeating: .accentColor, count: numbers.count)
        
        self.top_spacing = 0
        self.bottom_spacing = 0
    }
    
    public var body: some View
    {
        ScrollView
        {
            if top_spacing > 0
            {
                Spacer(minLength: top_spacing)
            }
            
            LazyVGrid(columns: columns, spacing: register_card_spacing)
            {
                ForEach(numbers, id: \.self)
                { number in
                    let color_index = number % colors.count
                    
                    if number < registers.count
                    {
                        RegisterCard(value: $registers[number], number: number, color: colors[color_index])
                            .id(number)
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
            }
            .padding()
            #if os(macOS)
            .padding(.vertical, 10)
            #else
            .padding(.vertical)
            #endif
            
            if bottom_spacing > 0
            {
                Spacer(minLength: bottom_spacing)
            }
        }
    }
}

public struct RegistersSelector: View
{
    let text: String
    let registers_count: Int
    let colors: [Color]
    
    @Binding var indices: [Int]
    @State var names: [String]
    
    @State private var is_presented = false
    
    public init(text: String, registers_count: Int, colors: [Color], indices: Binding<[Int]>, names: [String])
    {
        self.text = text
        self.registers_count = registers_count
        self.colors = colors
        
        self._indices = indices
        self.names = names
    }
    
    public init(text: String, registers_count: Int, indices: Binding<[Int]>, names: [String])
    {
        self.text = text
        self.registers_count = registers_count
        self.colors = [Color](repeating: .accentColor, count: registers_count)
        
        self._indices = indices
        self.names = names
    }
    
    public var body: some View
    {
        Button("\(text)", action: { is_presented = true })
            .popover(isPresented: $is_presented)
            {
                RegistersSelectorView(registers_count: registers_count, colors: colors, indices: $indices, names: names)
            }
    }
}

private struct RegistersSelectorView: View
{
    private let registers_count: [Int]
    private let colors: [Color]
    
    @Binding var indices: [Int]
    @State var names: [String]
    
    @State private var current_parameter = 0
    @State private var selections: [Bool]
    @State private var texts: [String]
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: 56, maximum: .infinity), spacing: 12)]
    
    init(registers_count: Int, colors: [Color], indices: Binding<[Int]>, names: [String])
    {
        self.registers_count = (0...registers_count - 1).map { $0 }
        self.colors = colors
        
        self.selections = [Bool](repeating: false, count: registers_count)
        self.texts = [String](repeating: String(), count: registers_count)
        
        self._indices = indices
        self.names = names
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if names.count > 1
            {
                Picker(selection: .constant(1), label: Text("placeholder")) { }
                .padding()
                .hidden()
            }
            
            ScrollView
            {
                LazyVGrid(columns: columns, spacing: 12)
                {
                    ForEach(registers_count, id: \.self)
                    { number in
                        let color_index = number % colors.count
                        
                        RegistersSelectorCardView(is_selected: $selections[number], number: number, color: colors[color_index], selection_text: texts[number])
                        .onTapGesture
                        {
                            select_index(number)
                        }
                        .animation(.easeInOut(duration: 0.2), value: selections)
                    }
                }
                .padding()
            }
        }
        .frame(width: 240, height: 240)
        .overlay(alignment: .top)
        {
            if names.count > 1
            {
                Picker("Parameters", selection: $current_parameter)
                {
                    ForEach(Array(indices.enumerated()), id: \.offset)
                    { index, _ in
                        Text("\(names[index])")
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thinMaterial)
            }
        }
        .onAppear
        {
            update_selections()
            update_texts()
        }
    }
    
    private func update_selections()
    {
        selections = [Bool](repeating: false, count: selections.count)
        
        for index in indices
        {
            if index < selections.count
            {
                selections[index] = true
            }
            else
            {
                selections[selections.count - 1] = true
            }
        }
    }
    
    private func update_texts()
    {
        texts = [String](repeating: String(), count: texts.count)
        
        for (index, value) in indices.enumerated()
        {
            if value < texts.count
            {
                texts[value] += "\(names[index]) "
            }
            else
            {
                texts[texts.count - 1] += "\(names[index]) "
            }
        }
        
        for index in texts.indices
        {
            texts[index] = String(texts[index].dropLast())
        }
    }
    
    private func select_index(_ number: Int)
    {
        indices[current_parameter] = number
        
        update_selections()
        update_texts()
    }
}

private struct RegistersSelectorCardView: View
{
    @Binding var is_selected: Bool
    
    let number: Int
    let color: Color
    
    let selection_text: String
    
    init(is_selected: Binding<Bool>, number: Int, color: Color, selection_text: String)
    {
        self._is_selected = is_selected
        
        self.number = number
        self.color = color
        
        self.selection_text = selection_text
    }
    
    var body: some View
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
            
            Text(is_selected ? "\(selection_text)" :"\(number)")
                .font(.system(size: is_selected ? 16 : 20))
                .foregroundColor(is_selected ? .black : .white)
                .padding(8)
            #if !os(macOS)
                .keyboardType(.decimalPad)
            #endif
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .brightness(is_selected ? 0.25 : 0)
        #if !os(visionOS)
        //.shadow(color: .black.opacity(0.2), radius: 2)
        .shadow(color: color.opacity(is_selected ? 0.2 : 0.1), radius: 4)
        #else
        .frame(depth: 4)
        #endif
    }
}

//MARK: - Registers data view
public struct RegistersDataView: View
{
    @Binding var is_presented: Bool
    
    @State private var is_registers_count_presented = false
    
    @EnvironmentObject var workspace: Workspace
    
    let save_registers: () -> ()
    
    public init(is_presented: Binding<Bool>, save_registers: @escaping () -> Void = {})
    {
        self._is_presented = is_presented
        self.save_registers = save_registers
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            RegistersView(registers: $workspace.registers, colors: registers_colors, top_spacing: 48, bottom_spacing: 48)
                .overlay(alignment: .bottom)
                {
                    #if !os(visionOS)
                    GlassEffectContainer
                    {
                        HStack(spacing: 0)
                        {
                            Button(role: .destructive, action: clear_registers)
                            {
                                Image(systemName: "eraser")
                                    .modifier(CircleButtonImageFramer())
                            }
                            .modifier(CircleButtonGlassBorderer())
                            .padding(.trailing, 8)
                            
                            Button(action: save_registers)
                            {
                                Image(systemName: "arrow.down.doc")
                                    .modifier(CircleButtonImageFramer())
                            }
                            .modifier(CircleButtonGlassBorderer())
                            .padding(.trailing, 8)
                            
                            Button(action: { is_registers_count_presented = true })
                            {
                                Image(systemName: "square.grid.2x2")
                                    .modifier(CircleButtonImageFramer())
                            }
                            .modifier(CircleButtonGlassBorderer())
                            .popover(isPresented: $is_registers_count_presented, arrowEdge: default_popover_edge)
                            {
                                RegistersCountView(is_presented: $is_registers_count_presented, registers_count: workspace.registers.count)
                                {
                                    save_registers()
                                }
                                #if os(iOS)
                                .presentationDetents([.height(96)])
                                #endif
                            }
                        }
                        .padding()
                    }
                    #else
                    HStack(spacing: 0)
                    {
                        Button(role: .destructive, action: clear_registers)
                        {
                            Image(systemName: "eraser")
                                .imageScale(.large)
                                .frame(width: 24, height: 24)
                                .padding(8)
                        }
                        .buttonBorderShape(.circle)
                        .glassBackgroundEffect()
                        .padding(.trailing, 8)
                        
                        Button(action: save_registers)
                        {
                            Image(systemName: "arrow.down.doc")
                                .imageScale(.large)
                                .frame(width: 24, height: 24)
                                .padding(8)
                        }
                        .buttonBorderShape(.circle)
                        .glassBackgroundEffect()
                        .padding(.trailing, 8)
                        
                        Button(action: { is_registers_count_presented = true })
                        {
                            Image(systemName: "square.grid.2x2")
                                .imageScale(.large)
                                .frame(width: 24, height: 24)
                                .padding(8)
                        }
                        .buttonBorderShape(.circle)
                        .glassBackgroundEffect()
                        .popover(isPresented: $is_registers_count_presented, arrowEdge: default_popover_edge)
                        {
                            RegistersCountView(is_presented: $is_registers_count_presented, registers_count: workspace.registers.count)
                            {
                                save_registers()
                            }
                        }
                    }
                    .padding()
                    #endif
                }
        }
        .controlSize(.regular)
        .modifier(SheetCaption(is_presented: $is_presented, label: "Registers", plain: false))
    }
    
    private func clear_registers()
    {
        workspace.clear_registers()
    }
    
    /*private func save_registers()
    {
        controller.registers_document_data_update.toggle()
    }*/
    
    /*private func update_registers_count()
    {
        workspace.update_registers_count(Workspace.default_registers_count)
        save_registers()
    }*/
    
    #if os(macOS)
    let default_popover_edge: Edge = .top
    #else
    let default_popover_edge: Edge = .bottom
    #endif
}

private struct RegistersCountView: View
{
    @Binding var is_presented: Bool
    @State var registers_count: Int
    
    @EnvironmentObject var workspace: Workspace
    
    let save_registers: () -> ()
    
    var body: some View
    {
        HStack(spacing: 8)
        {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {
                    registers_count = Workspace.default_registers_count
                    update_count()
                }
            })
            {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            #if os(macOS)
            .foregroundColor(Color.white)
            #else
            .padding(.leading, 4)
            #endif
            
            TextField("\(Workspace.default_registers_count)", value: $registers_count, format: .number)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    update_count()
                    // additive_func()
                }
            #if os(macOS)
                .frame(width: 64)
            #else
                .frame(width: 128)
            #endif
            
            Stepper("Enter", value: $registers_count, in: 1...1000)
                .labelsHidden()
            #if os(iOS) || os(visionOS)
                .padding(.trailing, 8)
            #endif
        }
        /*.onChange(of: registers_count)
        { _, _ in
            update_count()
            additive_func()
        }*/
        .padding(10)
        .controlSize(.regular)
    }
    
    private func update_count()
    {
        if registers_count > 0
        {
            workspace.update_registers_count(registers_count)
            save_registers()
        }
    }
}

let register_card_maximum = register_card_scale + register_card_spacing

//MARK: - Previews
struct RegistersSelectors_PreviewsContainer: PreviewProvider
{
    struct Container: View
    {
        @State var registers = [Float](repeating: 0, count: 16)
        
        @State var index = [0]
        @State var indices = [0, 0, 0]
        
        var body: some View
        {
            RegistersView_Previews(registers: $registers)
            RegistersSelectors_Previews(index: $index, indices: $indices)
            RegistersDataPreview()
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
            RegistersView(registers: $registers, colors: colors_by_seed(seed: 5433))
            #if !os(visionOS)
                .frame(width: 420, height: 420)
                .background(.white)
            #else
                .frame(width: 600, height: 600)
            #endif
        }
        
        private func colors_by_seed(seed: Int) -> [Color]
        {
            var colors = [Color]()

            srand48(seed)
            
            for _ in 0..<256
            {
                var color = [Double]()
                for _ in 0..<3
                {
                    let random_number = Double(drand48() * Double(128) + 64)
                    
                    color.append(random_number)
                }
                colors.append(Color(red: color[0] / 255, green: color[1] / 255, blue: color[2] / 255))
            }

            return colors
        }
    }
    
    struct RegistersSelectors_Previews: View
    {
        @Binding var index: [Int]
        @Binding var indices: [Int]
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                RegistersSelector(text: "Value of \(index[0])", registers_count: 12, colors: colors_by_seed(seed: 5433), indices: $index, names: ["Value"])
                    .padding([.horizontal, .top])
                
                RegistersSelector(text: "Location of X: \(indices[0]), Y: \(indices[1]), Z: \(indices[2])", registers_count: 12, colors: colors_by_seed(seed: 5433), indices: $indices, names: ["X", "Y", "Z"])
                    .padding()
            }
        }
        
        private func colors_by_seed(seed: Int) -> [Color]
        {
            var colors = [Color]()

            srand48(seed)
            
            for _ in 0..<256
            {
                var color = [Double]()
                for _ in 0..<3
                {
                    let random_number = Double(drand48() * Double(128) + 64)
                    
                    color.append(random_number)
                }
                colors.append(Color(red: color[0] / 255, green: color[1] / 255, blue: color[2] / 255))
            }

            return colors
        }
    }
    
    struct RegistersDataPreview: View
    {
        @State private var is_presented: Bool = false
        
        var body: some View
        {
            ZStack
            {
                Rectangle()
                    .foregroundStyle(.white)
                
                RegistersDataView(is_presented: $is_presented)
                    .frame(width: 420, height: 480)
                    .environmentObject(Workspace())
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 16)
                    .padding(32)
            }
        }
    }
}

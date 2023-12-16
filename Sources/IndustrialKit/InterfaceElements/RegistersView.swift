//
//  SwiftUIView.swift
//  
//
//  Created by Malkarov Park on 16.12.2023.
//

import SwiftUI

public struct RegistersView: View
{
    @Binding var registers: [Float]
    
    public let colors: [Color]
    
    private let numbers: [Int]
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: register_card_maximum, maximum: register_card_maximum), spacing: 0)]
    
    public init(registers: Binding<[Float]>, colors: [Color])
    {
        self._registers = registers
        self.numbers = (0...registers.count - 1).map { $0 }
        
        self.colors = colors
    }
    
    public init(registers: Binding<[Float]>)
    {
        self._registers = registers
        self.numbers = (0...registers.count - 1).map { $0 }
        
        self.colors = [Color](repeating: .accentColor, count: numbers.count)
    }
    
    public var body: some View
    {
        ScrollView
        {
            LazyVGrid(columns: columns, spacing: register_card_spacing)
            {
                ForEach(numbers, id: \.self)
                { number in
                    RegisterCardView(value: $registers[number], number: number, color: colors[number])
                        .id(number)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            .padding()
            #if os(macOS)
            .padding(.vertical, 10)
            #else
            .padding(.vertical)
            #endif
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

struct RegistersSelectorView: View
{
    let registers_count: [Int]
    let colors: [Color]
    
    @Binding var indices: [Int]
    @State var names: [String]
    
    @State private var current_parameter = 0
    @State private var selections = [Bool](repeating: false, count: 256)
    @State private var texts = [String](repeating: String(), count: 256)
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: 70, maximum: 70), spacing: 0)]
    
    init(registers_count: Int, colors: [Color], indices: Binding<[Int]>, names: [String])
    {
        self.registers_count = (0...registers_count - 1).map { $0 }
        self.colors = colors
        
        self._indices = indices
        self.names = names
    }
    
    var body: some View
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
                LazyVGrid(columns: columns, spacing: 6)
                {
                    ForEach(registers_count, id: \.self)
                    { number in
                        RegistersSelectorCardView(is_selected: $selections[number], number: number, color: colors[number], selection_text: texts[number])
                        .onTapGesture
                        {
                            select_index(number)
                        }
                    }
                }
                .padding()
                #if os(macOS)
                .padding(.vertical, 10)
                #else
                .padding(.vertical)
                #endif
            }
        }
        .frame(width: 256, height: 256)
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
        selections = [Bool](repeating: false, count: 256)
        
        for index in indices
        {
            selections[index] = true
        }
    }
    
    private func update_texts()
    {
        texts = [String](repeating: String(), count: 256)
        
        for (index, value) in indices.enumerated()
        {
            texts[value] += "\(names[index]) "
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

struct RegistersSelectorCardView: View
{
    @Binding var is_selected: Bool
    
    let number: Int
    let color: Color
    
    let selection_text: String
    
    var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundStyle(Color(color).opacity(0.75))
            
            Text("\(number)")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(8)
            
            if is_selected
            {
                ZStack
                {
                    Text(selection_text)
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .padding(8)
                        //.lineLimit(1)
                }
                .frame(width: 64, height: 64)
                .background(.regularMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .frame(width: 64, height: 64)
        .shadow(radius: 2)
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

let register_card_maximum = register_card_scale + register_card_spacing

#Preview
{
    RegistersView(registers: .constant([Float](repeating: 0, count: 256)))
        .frame(width: 400, height: 512)
}

#Preview
{
    RegistersSelectorView(registers_count: 41, colors: [Color](repeating: .accentColor, count: 41), indices: .constant([Int](repeating: 0, count: 6)), names: ["X", "Y", "Z", "R", "P", "W"])
        .environmentObject(Workspace())
}

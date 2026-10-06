//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI
import IndustrialKit

public struct OperationControl: View
{
    @ObservedObject var tool: Tool
    
    @State private var is_expanded = false
    @State private var is_central_pressed = false
    
    @Namespace private var pane_glass
    
    public init(
        tool: Tool
    )
    {
        self.tool = tool
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            ZStack
            {
                if !is_expanded
                {
                    // Operation Pane
                    HStack(spacing: 0)
                    {
                        VStack
                        {
                            Text(tool.codes.count > 0 ? tool.code_info(tool.current_operation.value).name : "")
                            #if os(macOS)
                                .font(.system(size: 14, design: .rounded))
                            #elseif os(iOS)
                                .font(.system(size: 18, design: .rounded))
                            #elseif os(visionOS)
                                .font(.system(size: 16, design: .rounded))
                                .padding(2)
                            #endif
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .lineLimit(1)
                                //.truncationMode(.tail)
                                .padding(10)
                            #if os(iOS)
                                .padding(tool.codes.count > 0 ? 0 : 4)
                                .foregroundStyle(.black)
                            #endif
                        }
                    }
                    .background(.clear)
                    .frame(width: 104) //.frame(maxWidth: .infinity)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onChanged
                            { _ in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                                {
                                    is_central_pressed = true
                                }
                            }
                            .onEnded
                            { _ in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                                {
                                    is_expanded = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                                    {
                                        is_central_pressed = false
                                    }
                                }
                            }
                            .simultaneously(
                                with:
                                    TapGesture()
                                    .onEnded
                                    {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                                        {
                                            is_central_pressed = true
                                            is_expanded = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                                            {
                                                is_central_pressed = false
                                            }
                                        }
                                    }
                                )
                    )
                }
                else
                {
                    // Editor
                    VStack(spacing: 0)
                    {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75))
                            {
                                is_expanded = false
                            }
                        })
                        {
                            Image(systemName: "chevron.compact.down")
                                .padding(10)
                            #if os(iOS)
                                .font(.system(size: 16))
                            #endif
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .tint(.black)
                        #endif
                        .contentShape(Rectangle())
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: is_expanded)
                        
                        HStack
                        {
                            ScrollView
                            {
                                if !current_code_info.description.isEmpty
                                {
                                    Text(current_code_info.description)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    #if os(macOS)
                                        .font(.system(size: 10))
                                    #else
                                        .font(.system(size: 14))
                                    #endif
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .background(.quinary)
                            #if os(macOS)
                            .frame(width: 80, height: 80)
                            #else
                            .frame(width: 96, height: 96)
                            #endif
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay
                            {
                                if current_code_info.description.isEmpty
                                {
                                    ZStack
                                    {
                                        Text("No Info")
                                            .frame(maxWidth: .infinity)
                                            #if os(macOS)
                                            .font(.system(size: 12))
                                            #else
                                            .font(.system(size: 16))
                                            #endif
                                            .foregroundStyle(.secondary)
                                    }
                                    #if os(macOS)
                                    .frame(width: 80, height: 80)
                                    #else
                                    .frame(width: 96, height: 96)
                                    #endif
                                    .background(.quinary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            
                            ZStack
                            {
                                let operation_binding = Binding(
                                    get: { current_code_info },
                                    set:
                                        { new_value in
                                            tool.current_operation = OperationCode(new_value.value)
                                        }
                                )
                                
                                Rectangle()
                                    .fill(.clear)
                                
                                #if os(macOS)
                                ScrollView
                                {
                                    Picker("Code", selection: operation_binding)
                                    {
                                        if tool.codes.count > 0
                                        {
                                            ForEach(tool.codes, id:\.self)
                                            { code in
                                                Text(code.name)
                                                    .font(.system(size: 12))
                                            }
                                        }
                                        else
                                        {
                                            Text("None")
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .pickerStyle(.radioGroup)
                                    .labelsHidden()
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                }
                                #else
                                Picker("Code", selection: operation_binding)
                                {
                                    if tool.codes.count > 0
                                    {
                                        ForEach(tool.codes, id:\.self)
                                        { code in
                                            Text(code.name)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .pickerStyle(.wheel)
                                .buttonStyle(.borderedProminent)
                                #endif
                            }
                            .background(.quinary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            #if os(macOS)
                            .frame(maxWidth: .infinity, maxHeight: 80)
                            #else
                            .frame(maxWidth: .infinity, maxHeight: 96)
                            #endif
                            
                            ZStack
                            {
                                let value_binding = Binding(
                                    get: { current_code_info.value },
                                    set:
                                        { new_value in
                                            tool.current_operation = OperationCode(new_value)
                                        }
                                )
                                
                                Rectangle()
                                    .fill(.clear)
                                
                                TextField("Value", value: value_binding, format: .number)
                                #if os(macOS)
                                    .font(.system(size: 20))
                                #else
                                    .font(.system(size: 24))
                                    .keyboardType(.decimalPad)
                                #endif
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(.plain)
                            }
                            #if os(macOS)
                            .frame(width: 80, height: 80)
                            #else
                            .frame(width: 96, height: 96)
                            #endif
                            .background(.quinary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .padding([.horizontal, .bottom], 10)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.0)))
                    #if os(macOS)
                    .frame(width: is_expanded ? 300 : 120)
                    #else
                    .frame(width: is_expanded ? 360 : 120)
                    #endif
                }
            }
            .clipShape(ExpandingShape(progress: is_expanded ? 1 : 0))
            .glassEffect(.regular, in: ExpandingShape(progress: is_expanded ? 1 : 0))
            .scaleEffect(is_central_pressed ? 1.05 : 1)
            
            Button
            {
                tool.start_pause_single_operation()
            }
            label:
            {
                if tool.codes.count > 0
                {
                    Image(systemName:
                            is_valid_symbol(current_code_info.symbol_name) ?
                            current_code_info.symbol_name :
                            ""
                    )
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .modifier(CircleButtonImageFramer())
                }
                else
                {
                    Rectangle()
                        .fill(.clear)
                        .modifier(CircleButtonImageFramer())
                }
            }
            .modifier(CircleButtonGlassBorderer())
            #if os(macOS) || os(iOS)
            .padding(10)
            #else
            .padding(16)
            #endif
        }
        .disabled(tool.codes.count == 0)
        #if os(visionOS)
        .offset(z: 2)
        #endif
    }
    
    private func is_valid_symbol(_ symbol: String) -> Bool
    {
        #if os(macOS)
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil
        #else
        return UIImage(systemName: symbol) != nil
        #endif
    }
    
    private var current_code_info: OperationCodeInfo
    {
        return tool.code_info(tool.current_operation.value)
    }
}

private struct ExpandingShape: InsettableShape
{
    var progress: CGFloat
    var inset_amount: CGFloat = 0
    
    var animatableData: AnimatablePair<CGFloat, CGFloat>
    {
        get
        {
            AnimatablePair(progress, inset_amount)
        }
        set
        {
            progress = newValue.first
            inset_amount = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path
    {
        let rect = rect.insetBy(dx: inset_amount, dy: inset_amount)
        let capsule_radius = min(rect.width, rect.height) / 2
        let radius = 16 + (capsule_radius - 16) * (1 - progress)
        
        return RoundedRectangle(
            cornerRadius: radius,
            style: .continuous
        )
        .path(in: rect)
    }
    
    func inset(by amount: CGFloat) -> ExpandingShape
    {
        var copy = self
        copy.inset_amount += amount
        return copy
    }
}

// MARK: - Previews
struct OperationControl_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var tool = Tool(name: "Gripper")
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                Spacer()
                
                OperationControl(tool: tool)
                    .padding()
            }
            .frame(width: 400, height: 400)
            .onAppear
            {
                tool.codes = [
                    OperationCodeInfo(value: 0, name: "Close", symbol_name: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", description: "Close the Tool"),
                    OperationCodeInfo(value: 1, name: "Open", symbol_name: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", description: "Open the Tool")
                ]
            }
        }
    }
    
    static var previews: some View
    {
        Container()
            .padding()
    }
}

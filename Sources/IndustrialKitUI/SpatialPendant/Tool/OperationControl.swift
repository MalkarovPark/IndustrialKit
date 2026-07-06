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
        GlassEffectContainer
        {
            HStack(spacing: 0)
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
                    .glassEffect(.regular.interactive(), in: .capsule(style: .continuous))
                    .matchedGeometryEffect(id: "glass", in: pane_glass)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .scaleEffect(is_central_pressed ? 0.95 : 1)
                    .animation(
                        .interactiveSpring(response: 0.35, dampingFraction: 0.6, blendDuration: 0),
                        value: is_central_pressed
                    )
                    .onTapGesture
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
                    .transition(.opacity.combined(with: .scale(scale: 1.0)))
                    #if os(macOS)
                    .padding(.leading, 10)
                    #else
                    .padding(.leading, 16)
                    #endif
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
                            #if os(iOS)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 16)
                            #endif
                        }
                        #if !os(visionOS)
                        .buttonStyle(.plain)
                        #else
                        .buttonStyle(.borderless)
                        .frame(height: 24)
                        #endif
                        .padding(.top, 10)
                        .scaleEffect(is_expanded ? 1 : 0.01)
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
                        .padding(10)
                    }
                    #if os(macOS)
                    .frame(width: is_expanded ? 300 : 120)
                    #else
                    .frame(width: is_expanded ? 360 : 120)
                    #endif
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
                    .matchedGeometryEffect(id: "glass", in: pane_glass)
                    .animation(.spring(response: 0.35, dampingFraction: 0.95), value: is_expanded)
                }
                
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
        }
        //.animation(.spring(response: 0.35, dampingFraction: 0.95), value: is_expanded)
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

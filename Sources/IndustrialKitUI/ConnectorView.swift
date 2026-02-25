//
//  ConnectorView.swift
//  IndustrialKit
//
//  Created by Artem on 13.11.2024.
//

import SwiftUI
import IndustrialKit

public struct ConnectorView: View
{
    @ObservedObject var connector: WorkspaceObjectConnector
    
    @Binding var demo: Bool
    @Binding var update_model: Bool
    
    let on_update: () -> Void
    
    @State private var connection_toggle: Bool = false
    
    public init(
        connector: WorkspaceObjectConnector,
        
        demo: Binding<Bool>,
        update_model: Binding<Bool>,
        
        on_update: @escaping () -> Void = {}
    )
    {
        self.connector = connector
        
        self._demo = demo
        self._update_model = update_model
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            ZStack
            {
                #if os(iOS)
                Rectangle()
                    .foregroundStyle(.white)
                #endif
                
                List
                {
                    /*if connector.parameters.count > 0
                    {
                        ForEach($connector.current_parameters.indices, id: \.self)
                        { index in
                            ConnectionParameterView(parameter: $connector.current_parameters[index], on_update: on_update)
                        }
                    }*/
                }
                .listStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(ViewBorderer())
            .overlay(alignment: .center)
            {
                if !(connector.parameters.count > 0)
                {
                    Text("No connection parameters")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .controlSize(.regular)
            .padding(.bottom)
            
            HStack(spacing: 0)
            {
                TextEditor(text: $connector.output)
                    .scrollIndicators(.hidden)
                
                VStack
                {
                    Rectangle()
                    #if !os(visionOS)
                        .fill(.white)
                    #else
                        .fill(.clear)
                    #endif
                }
                #if !os(visionOS)
                .frame(width: 32)
                #else
                .frame(width: 68)
                #endif
            }
            .modifier(ViewBorderer())
            #if os(visionOS)
            .frame(height: 128)
            #endif
            .overlay(alignment: .topTrailing)
            {
                VStack(spacing: 0)
                {
                    Toggle(isOn: $connector.get_output)
                    {
                        Image(systemName: "text.append")
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.bordered)
                    .toggleStyle(.button)
                    .buttonBorderShape(.circle)
                    .padding(8)
                    
                    Button(action: {
                        connector.clear_output()
                    })
                    {
                        Image(systemName: "eraser")
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .toggleStyle(.button)
                    .padding(.horizontal, 8)
                }
                #if !os(iOS)
                .controlSize(.large)
                #endif
            }
            .frame(maxWidth: .infinity, maxHeight: 112)
            #if !os(visionOS)
            .backgroundStyle(.white)
            #endif
            .padding(.bottom)
            
            HStack(spacing: 0)
            {
                #if os(iOS) || os(visionOS)
                Text("Demo")
                    .padding(.trailing)
                #endif
                
                Toggle(isOn: $demo)
                {
                    Text("Demo")
                }
                .toggleStyle(.switch)
                #if os(iOS) || os(visionOS)
                .tint(.accentColor)
                .labelsHidden()
                #endif
                
                Spacer()
                
                Toggle(isOn: $update_model)
                {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .help("Sync Model")
                .disabled(demo)
                #if os(macOS)
                .controlSize(.large)
                #endif
                .toggleStyle(.button)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .padding(.trailing)
                
                Button
                {
                    
                }
                label:
                {
                    HStack
                    {
                        Text(connector.connection_button.label)
                        /*Image(systemName: "circle.fill")
                            .foregroundColor(connector.connection_button.color)*/
                        
                        Circle()
                            .foregroundColor(.clear)
                            .glassEffect(.regular.tint(connector.connection_button.color).interactive())
                            .frame(width: 10, height: 10)
                    }
                }
                .disabled(demo)
                #if os(macOS)
                .controlSize(.large)
                #endif
                .buttonStyle(.glass)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .controlSize(.regular)
    }
}

public struct ConnectionParameterView: View
{
    @Binding var parameter: ConnectionParameter
    
    var on_update: () -> Void
    
    public init(
        parameter: Binding<ConnectionParameter>,
        on_update: @escaping () -> Void
    )
    {
        self._parameter = parameter
        self.on_update = on_update
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            Text(parameter.name)
            
            Spacer()
            
            switch parameter.value
            {
            case let stringValue as String:
                TextField(parameter.name, text: Binding(
                    get: { stringValue },
                    set: { new_value in
                        parameter.value = new_value
                        on_update()
                    }
                ))
                #if os(macOS)
                    .textFieldStyle(.squareBorder)
                #endif
                    .labelsHidden()
                
            case let intValue as Int:
                HStack
                {
                    TextField("0", value: Binding(
                        get: { intValue },
                        set: { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                    ), format: .number.grouping(.never)) //, format: .number)
                    #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                    #endif
                    Stepper("", value: Binding(
                        get: { intValue },
                        set: { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                    ), in: -1_000_000_000...1_000_000_000)
                    .labelsHidden()
                    .padding(.leading, 8)
                }

            case let floatValue as Float:
                HStack
                {
                    TextField("0", value: Binding(
                        get: { floatValue },
                        set: { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                    ), format: .number.grouping(.never)) //, format: .number)
                    #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                    #endif
                    Stepper("", value: Binding(
                        get: { floatValue },
                        set: { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                    ), in: (-Float.infinity)...(Float.infinity))
                    .labelsHidden()
                    .padding(.leading, 8)
                }

            case let boolValue as Bool:
                Toggle(isOn: Binding(
                    get: { boolValue },
                    set: { new_value in
                        parameter.value = new_value
                        on_update()
                    }
                ))
                {
                    Text("Bool")
                }
                #if os(iOS) || os(visionOS)
                    .tint(.accentColor)
                #endif
                .labelsHidden()

            default:
                Text("Unknown parameter")
            }
        }
    }
}

// MARK: - Previews
struct ConnectorView_Previews: PreviewProvider
{
    struct Container: View
    {
        @State private var demo = false
        @State private var update_model = false
        
        var body: some View
        {
            ConnectorView(
                connector: Test_Connector(),
                demo: $demo,
                update_model: $update_model
            )
            .frame(width: 320)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    class Test_Connector: ToolConnector, @unchecked Sendable
    {
        override var parameters: [ConnectionParameter]
        {
            [
                .init(name: "String", value: "Text"),
                .init(name: "Int", value: 8),
                .init(name: "Float", value: Float(6)),
                .init(name: "Bool", value: true)
            ]
        }
    }
}

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
    @Binding var demo: Bool
    @Binding var update_model: Bool
    
    @StateObject var connector: WorkspaceObjectConnector
    
    var update_file_data: () -> Void
    
    @State private var connected = false
    @State private var toggle_enabled = true
    
    public init(demo: Binding<Bool>, update_model: Binding<Bool>, connector: @autoclosure @escaping () -> WorkspaceObjectConnector, update_file_data: @escaping () -> Void)
    {
        _demo = demo
        _update_model = update_model
        _connector = StateObject(wrappedValue: connector())
        self.update_file_data = update_file_data
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
                    if connector.parameters.count > 0
                    {
                        ForEach($connector.current_parameters.indices, id: \.self)
                        { index in
                            ConnectionParameterView(parameter: $connector.current_parameters[index], update_file_data: update_file_data)
                        }
                    }
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
                .frame(width: 48)
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
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .toggleStyle(.button)
                    .padding(8)
                    
                    Button(action: {
                        connector.clear_output()
                    })
                    {
                        Image(systemName: "eraser")
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
                .onChange(of: demo)
                { _, new_value in
                    if new_value && connected
                    {
                        connected = false
                        // connector.disconnect()
                    }
                    
                    update_file_data()
                }
                
                Spacer()
                
                Toggle(isOn: $update_model)
                {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .onChange(of: update_model)
                { _, _ in
                    update_file_data()
                }
                .disabled(demo)
                #if os(macOS)
                .controlSize(.large)
                #else
                .buttonStyle(.bordered)
                #endif
                #if os(visionOS)
                .buttonBorderShape(.circle)
                #endif
                .toggleStyle(.button)
                .buttonBorderShape(.circle)
                .padding(.trailing)
                
                Toggle(isOn: $connected)
                {
                    HStack
                    {
                        Text(connector.connection_button.label)
                        Image(systemName: "circle.fill")
                            .foregroundColor(connector.connection_button.color)
                    }
                }
                .disabled(demo)
                .toggleStyle(.button)
                #if os(macOS)
                .controlSize(.large)
                #else
                .buttonStyle(.bordered)
                #endif
                .onChange(of: connected)
                { _, new_value in
                    if !toggle_enabled
                    {
                        if new_value
                        {
                            connector.connect()
                        }
                        else
                        {
                            connector.disconnect()
                        }
                    }
                }
                .onChange(of: connector.connection_failure)
                { _, new_value in
                    if new_value
                    {
                        toggle_enabled = true
                        connected = false
                        toggle_enabled = false
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear
        {
            connected = connector.connected
            toggle_enabled = false
            
            if connector.connection_failure
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                {
                    connector.connection_failure = false
                }
            }
        }
        .controlSize(.regular)
    }
}

public struct ConnectionParameterView: View
{
    @Binding var parameter: ConnectionParameter
    
    var update_file_data: () -> Void
    
    public init(parameter: Binding<ConnectionParameter>, update_file_data: @escaping () -> Void)
    {
        self._parameter = parameter
        self.update_file_data = update_file_data
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
                        update_file_data()
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
                            update_file_data()
                        }
                    ), format: .number.grouping(.never))
                    #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                    #endif
                    Stepper("", value: Binding(
                        get: { intValue },
                        set: { new_value in
                            parameter.value = new_value
                            update_file_data()
                        }
                    ), in: (-.infinity)...(.infinity))
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
                            update_file_data()
                        }
                    ), format: .number)
                    #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                    #endif
                    Stepper("", value: Binding(
                        get: { floatValue },
                        set: { new_value in
                            parameter.value = new_value
                            update_file_data()
                        }
                    ), in: (-.infinity)...(.infinity))
                    .labelsHidden()
                    .padding(.leading, 8)
                }

            case let boolValue as Bool:
                Toggle(isOn: Binding(
                    get: { boolValue },
                    set: { new_value in
                        parameter.value = new_value
                        update_file_data()
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

struct ConnectorView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ConnectorView(
            demo: .constant(true),
            update_model: .constant(true),
            connector: Test_Connector(),
            update_file_data: {}
        )
        .environmentObject(Workspace())
        .frame(width: 320)
    }
    
    class Test_Connector: ToolConnector
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

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
    @ObservedObject var object: WorkspaceObject
    
    let on_update: () -> Void
    
    public init(
        object: WorkspaceObject,
        
        on_update: @escaping () -> Void = {}
    )
    {
        self.object = object
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if let device = object as? any DeviceTwin
            {
                ConnectionStatusView(connector: device.connector, on_update: on_update)
                
                HStack(spacing: 0)
                {
                    let is_twin_sync = Binding(
                        get: { device.is_twin_sync },
                        set:
                            { new_value in
                                device.is_twin_sync = new_value
                                
                                on_update()
                            }
                    )
                    
                    let device_mode = Binding(
                        get: { device.device_mode },
                        set:
                            { new_value in
                                device.device_mode = new_value
                                
                                on_update()
                            }
                    )
                    
                    Picker("Mode", selection: device_mode)
                    {
                        ForEach(DeviceMode.allCases, id: \.self)
                        { device_mode in
                            Text(device_mode.rawValue).tag(device_mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .labelsHidden()
                    
                    Spacer()
                    
                    #if os(macOS)
                    ExternalConnectorView(connector: device.connector)
                        .disabled(device.device_mode == .simulation)
                    #endif
                    
                    Toggle(isOn: is_twin_sync)
                    {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .help("Sync Model")
                    .disabled(device.device_mode == .simulation)
                    #if os(macOS)
                    .controlSize(.large)
                    #endif
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .padding(.trailing)
                    
                    ConnectionButton(
                        connector: device.connector,
                        connect_device: { device.connect_device() },
                        disconnect_device: { device.disconnect_device() }
                    )
                    .disabled(device.device_mode == .simulation)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .controlSize(.regular)
    }
}

private struct ConnectionStatusView: View
{
    @ObservedObject var connector: WorkspaceObjectConnector
    
    let on_update: () -> Void
    
    var body: some View
    {
        ZStack
        {
            #if os(iOS)
            Rectangle()
                .foregroundStyle(.white)
            #endif
            
            List
            {
                if connector.default_parameters.count > 0
                {
                    ForEach(connector.parameters.indices, id: \.self)
                    { index in
                        ConnectionParameterView(parameter: connector.parameters[index], on_update: on_update)
                    }
                }
            }
            .listStyle(.plain)
            
            if !(connector.default_parameters.count > 0)
            {
                Text("No connection parameters")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(ViewBorderer())
        .overlay(alignment: .bottomLeading)
        {
            VStack(spacing: 8)
            {
                if let output_string = connector.connection_output_string
                {
                    Button
                    {
                        connector.connection_output_string = nil
                    }
                    label:
                    {
                        ZStack
                        {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .foregroundStyle(.thinMaterial)
                            
                            VStack(alignment: .leading)
                            {
                                Label("Connection", systemImage: "info.circle.fill")
                                
                                ScrollView
                                {
                                    Text(output_string)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(nil)
                                    #if os(macOS)
                                        .font(.system(size: 10))
                                    #else
                                        .font(.system(size: 14))
                                    #endif
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(8)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .buttonStyle(.plain)
                }
                
                if let error = connector.connection_error
                {
                    Button
                    {
                        connector.connection_error = nil
                    }
                    label:
                    {
                        ZStack
                        {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .foregroundStyle(.thinMaterial)
                            
                            VStack(alignment: .leading)
                            {
                                Label("Error", systemImage: "xmark.octagon.fill")
                                
                                ScrollView
                                {
                                    Text(error.localizedDescription)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(nil)
                                    #if os(macOS)
                                        .font(.system(size: 10))
                                    #else
                                        .font(.system(size: 14))
                                    #endif
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(8)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .controlSize(.regular)
        .padding(.bottom)
    }
}

private struct ConnectionButton: View
{
    @ObservedObject var connector: WorkspaceObjectConnector
    
    let connect_device: () -> Void
    let disconnect_device: () -> Void
    
    var body: some View
    {
        Button
        {
            if !connector.connected
            {
                connect_device()
            }
            else
            {
                disconnect_device()
            }
        }
        label:
        {
            HStack
            {
                Text(connector.connection_button.label)
                
                Circle()
                    .fill(connector.connection_button.color)
                    .frame(width: 10, height: 10)
            }
        }
        #if os(macOS)
        .controlSize(.large)
        #endif
        .buttonStyle(.bordered)
    }
}

public struct ConnectionParameterView: View
{
    @ObservedObject var parameter: ConnectionParameter
    var on_update: () -> Void
    
    public init(
        parameter: ConnectionParameter,
        
        on_update: @escaping () -> Void
    )
    {
        self.parameter = parameter
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            Text(parameter.name)
                .fontWeight(.bold)
            
            Spacer()
            
            switch parameter.value
            {
            case is String:
                TextField("String", text: Binding(
                    get: { parameter.value as? String ?? "" },
                    set: { new_value in
                        parameter.value = new_value
                        on_update()
                    }
                ))
                .multilineTextAlignment(.trailing)
                .labelsHidden()
            case is Int:
                HStack
                {
                    TextField("Int", value: Binding(
                        get: { parameter.value as? Int ?? 0 },
                        set: { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                    ), format: .number.grouping(.never))
                    .multilineTextAlignment(.trailing)
                    .labelsHidden()

                    Stepper("Int", value: Binding(
                        get: { parameter.value as? Int ?? 0 },
                        set: { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                    ), in: -1_000_000_000...1_000_000_000)
                    .labelsHidden()
                    .padding(.leading, 8)
                }
            case is Float:
                HStack
                {
                    TextField("Float", value: Binding(
                        get: { parameter.value as? Float ?? 0 },
                        set: { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                    ), format: .number.grouping(.never))
                    .multilineTextAlignment(.trailing)
                    .labelsHidden()

                    Stepper("Float", value: Binding(
                        get: { parameter.value as? Float ?? 0 },
                        set: { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                    ), in: (-Float.infinity)...Float.infinity)
                    .labelsHidden()
                    .padding(.leading, 8)
                }
            case is Bool:
                Toggle(isOn: Binding(
                    get: { parameter.value as? Bool ?? false },
                    set:
                        { new_value in
                            parameter.value = new_value
                            on_update()
                        }
                ))
                {
                    Text("Bool")
                }
                .toggleStyle(.switch)
                #if os(iOS) || os(visionOS)
                .tint(.accentColor)
                #endif
                .labelsHidden()
            default:
                Text("Unknown Parameter")
            }
        }
        .frame(height: 32)
    }
}

// MARK: - External Connector
#if os(macOS)
private struct ExternalConnectorView: View
{
    @ObservedObject var connector: WorkspaceObjectConnector
    
    @State private var is_presented = false
    
    @State private var enabled = false
    
    @State private var sharing_enabled = false
    @State private var sharing_address = "0.0.0.0"
    
    var body: some View
    {
        if let external_connector = connector as? any ExternalConnector
        {
            Button
            {
                is_presented = true
            }
            label:
            {
                Image(systemName: "apple.terminal")
                    .frame(width: 20, height: 20)
            }
            .help("External Connector")
            //.disabled(device.device_mode == .simulation)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .popover(isPresented: $is_presented)
            {
                VStack(spacing: 16)
                {
                    /*#if os(iOS)
                    if is_compact
                    {
                        HStack
                        {
                            Text("External Connector")
                                .font(.title2)
                            
                            Spacer()
                            
                            Button
                            {
                                position_item_view_presented = false
                            }
                            label:
                            {
                                Image(systemName: "xmark")
                                    .font(.system(size: 24))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    #endif*/
                    
                    HStack
                    {
                        VStack(alignment: .leading, spacing: 4)
                        {
                            Text("External Program")
                            
                            HStack
                            {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(external_connector.program_component_status.color)
                                    .font(.system(size: program_item_light_size))
                                
                                Text(external_connector.program_component_status.rawValue)
                                    .fontWeight(.light)
                            }
                        }
                        //.padding(.leading, program_item_light_padding)
                        
                        Spacer(minLength: 32)
                        
                        Toggle(isOn: Binding(
                            get: { external_connector.program_component_enabled },
                            set:
                                { new_value in
                                    external_connector.program_component_enabled = new_value
                                    //on_update()
                                }
                        ))
                        {
                            Text("Bool")
                        }
                        .toggleStyle(.switch)
                        #if os(iOS) || os(visionOS)
                        .tint(.accentColor)
                        #endif
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    VStack(spacing: 8)
                    {
                        HStack
                        {
                            Text("Enable Sharing")
                            
                            Spacer(minLength: 32)
                            
                            Toggle(isOn: Binding(
                                get: { sharing_enabled },
                                set:
                                    { new_value in
                                        sharing_enabled = new_value
                                        //on_update()
                                    }
                            ))
                            {
                                Text("Bool")
                            }
                            .toggleStyle(.switch)
                            #if os(iOS) || os(visionOS)
                            .tint(.accentColor)
                            #endif
                            .labelsHidden()
                        }
                        
                        HStack
                        {
                            Text("Address")
                            
                            TextField(
                                "0.0.0.0",
                                text: Binding(
                                    get: { sharing_address },
                                    set:
                                        { new_value in
                                            sharing_address = new_value
                                            //on_update()
                                        }
                                )
                            )
                            .textFieldStyle(.plain)
                        }
                        .disabled(!sharing_enabled)
                    }
                }
                .padding()
            }
            .padding(.trailing)
        }
    }
}
#endif

// MARK: - Previews
struct ConnectorView_Previews: PreviewProvider
{
    struct Container: View
    {
        @ObservedObject private var object = Tool(name: "Test", entity_name: "??", connector: Test_Connector())
        @State private var update_model = false
        
        var body: some View
        {
            ConnectorView(object: object)
                .frame(width: 420)
                .onAppear
                {
                    object.device_mode = .real
                }
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    class Test_Connector: ToolConnector, ExternalConnector, @unchecked Sendable
    {
        // MARK: Program component handling
        public var program_component_enabled: Bool = false
        {
            didSet
            {
                program_component_enabled ?
                start_program_component() :
                stop_program_component()
            }
        }
        
        public func start_program_component()
        {
            Task
            {
                program_component_status = .starting
                
                sleep(1)
                
                program_component_status = .running//.disabled
                
                //program_component_enabled = false
            }
        }
        
        public func stop_program_component()
        {
            program_component_status = .not_running
        }
        
        @Published public var program_component_status: ProgramComponentStatus = .not_running
        
        public var program_component_url: URL = URL(fileURLWithPath: "")
        
        public var socket_postfix: String = ""
        
        // MARK: Connection handling
        override var default_parameters: [ConnectionParameter]
        {
            [
                .init(name: "Bool", value: true)
            ]
        }
        
        override func connection_process() async -> Bool
        {
            sleep(1)
            
            let result = parameters[safe: 0]?.value as? Bool ?? false
            
            if result
            {
                connection_output_string = "Connected"
            }
            else
            {
                connection_output_string = "Failed"
                connection_error = NSError(domain: "Connection failed", code: 0, userInfo: nil)
            }
            
            return result
        }
    }
}

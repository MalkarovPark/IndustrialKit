//
//  StateItemsView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI
import IndustrialKit

public struct StateItemsView: View
{
    @ObservedObject var device_output: DeviceOutputData
    
    let shows_output_indices: Bool
    
    @State private var expanded_items: [UUID: Bool] = [:]
    
    public init(
        device_output: DeviceOutputData,
        
        shows_output_indices: Bool = false
    )
    {
        self.device_output = device_output
        
        self.shows_output_indices = shows_output_indices
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if device_output.items.count > 0
            {
                List
                {
                    ForEach(device_output.items.indices, id: \.self)
                    { index in
                        StateItemListView(
                            item: device_output.items[index],
                            shows_indices: shows_output_indices,
                            
                            expanded_items: $expanded_items
                        )
                    }
                }
                .listStyle(.plain)
                .padding()
                /*.onChange(of: device_output.items)
                {
                    if shows_output_indices
                    {
                        device_output.define_item_indices()
                    }
                }*/
            }
            else
            {
                ContentUnavailableView
                {
                    Text("No Items")
                }
            }
        }
        //#if !os(visionOS)
        //.background(.white)
        //#endif
    }
}

public struct StateItemListView: View
{
    @ObservedObject var item: StateItem
    
    let shows_indices: Bool
    
    @Binding var expanded_items: [UUID: Bool]
    
    private var is_expanded_binding: Binding<Bool>
    
    public init(
        item: StateItem,
        
        expanded_items: Binding<[UUID: Bool]>
    )
    {
        self.item = item
        self.shows_indices = false
        
        self._expanded_items = expanded_items
        self.is_expanded_binding = Binding(
            get: { expanded_items.wrappedValue[item.id] ?? true },
            set: { expanded_items.wrappedValue[item.id] = $0 }
        )
    }
    
    public init(
        item: StateItem,
        shows_indices: Bool,
        
        expanded_items: Binding<[UUID: Bool]>
    )
    {
        self.item = item
        self.shows_indices = shows_indices
        
        self._expanded_items = expanded_items
        self.is_expanded_binding = Binding(
            get: { expanded_items.wrappedValue[item.id] ?? true },
            set: { expanded_items.wrappedValue[item.id] = $0 }
        )
    }
    
    public var body: some View
    {
        if let children = item.children, !children.isEmpty
        {
            DisclosureGroup(isExpanded: is_expanded_binding)
            {
                ForEach(children.indices, id: \.self)
                { index in
                    StateItemListView(
                        item: children[index],
                        shows_indices: shows_indices,
                        
                        expanded_items: $expanded_items
                    )
                    .padding(.leading, 20)
                }
            }
            label:
            {
                item_label
                    .modifier(IndexBadge(show_index: shows_indices, index_text: "\(item.item_index)"))
            }
        }
        else
        {
            item_label
                .modifier(IndexBadge(show_index: shows_indices, index_text: "\(item.item_index)"))
        }
    }
    
    private var item_label: some View
    {
        HStack
        {
            if let symbol_name = item.symbol_name, is_valid_symbol(symbol_name)
            {
                Image(systemName: symbol_name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.accentColor)
            }
            
            Text(item.name)
            
            Spacer()
            
            Text(item.value ?? "")
        }
    }
    
    private func is_valid_symbol(_ symbol: String) -> Bool
    {
        #if os(macOS)
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil
        #else
        return UIImage(systemName: symbol) != nil
        #endif
    }
}

private struct IndexBadge: ViewModifier
{
    let show_index: Bool
    let index_text: String
    
    public func body(content: Content) -> some View
    {
        if !show_index
        {
            content
        }
        else
        {
            HStack
            {
                Text(index_text)
                    //.font(.system(size: program_index_font_size))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .padding(.leading, -6)
                    .allowsHitTesting(false)
                
                content
                    //.badge(index_text)
            }
        }
    }
}

//MARK: - Previews
struct StateView_PreviewsContainer: PreviewProvider
{
    struct Container: View
    {
        var body: some View
        {
            StateView_Previews()
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    struct StateView_Previews: View
    {
        @ObservedObject var device_output = DeviceOutputData(
            items: [
                //StateItem(name: "Temperature", value: "+10º", symbol_name: "thermometer"),
                //StateItem(name: "Еngine", value: "+50º", symbol_name: "thermometer.transmission"), StateItem(name: "Fridge", value: "-40º", symbol_name: "thermometer.snowflake.circle"),
                
                StateItem(name: "Speed", value: "70 mm/sec", symbol_name: "windshield.front.and.wiper.intermittent")
            ]
        )
        
        var body: some View
        {
            StateItemsView(
                device_output: device_output,
                shows_output_indices: true
            )
            .frame(width: 320, height: 240)
        }
    }
}

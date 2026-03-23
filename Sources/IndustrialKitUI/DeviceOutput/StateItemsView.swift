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
                    if !shows_output_indices
                    {
                        ForEach(device_output.items.indices, id: \.self)
                        { index in
                            StateItemListView(
                                item: device_output.items[index],
                                expanded_items: $expanded_items
                            )
                        }
                    }
                    else
                    {
                        let index_map = index_map(for: device_output.items)
                        
                        ForEach(device_output.items.indices, id: \.self)
                        { index in
                            HStack
                            {
                                Text("\(index_map[device_output.items[index].id] ?? 0)")
                                    //.font(.system(size: program_index_font_size))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .padding(.leading, -6)
                                    .allowsHitTesting(false)
                                
                                StateItemListView(
                                    item: device_output.items[index],
                                    expanded_items: $expanded_items
                                )
                            }
                            
                            /*StateItemListView(
                                item: device_output.items[index],
                                expanded_items: $expanded_items
                            )
                            .badge("\(index_map[device_output.items[index].id] ?? 0)")*/
                        }
                        /*ForEach(flatten_items_with_indices(device_output.items), id: \.item.id)
                        { element in
                            StateItemListView(
                                item: element.item,
                                expanded_items: $expanded_items
                            )
                            .badge("\(element.index)")
                        }*/
                    }
                }
                .listStyle(.plain)
                .padding()
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
    
    func index_map(for items: [StateItem]) -> [UUID: Int]
    {
        var index_map: [UUID: Int] = [:]
        var counter = 0
        
        func traverse(_ item: StateItem)
        {
            index_map[item.id] = counter
            counter += 1
            
            if let children = item.children
            {
                for child in children
                {
                    traverse(child)
                }
            }
        }
        
        for item in items
        {
            traverse(item)
        }
        
        return index_map
    }
    /*private func flatten_items_with_indices(_ items: [StateItem]) -> [(index: Int, item: StateItem)]
    {
        var result: [(Int, StateItem)] = []
        var counter = 0
        
        func traverse(_ item: StateItem)
        {
            result.append((counter, item))
            counter += 1
            
            if let children = item.children
            {
                for child in children
                {
                    traverse(child)
                }
            }
        }
        
        for item in items
        {
            traverse(item)
        }
        
        return result
    }*/
}

public struct StateItemListView: View
{
    @ObservedObject var item: StateItem
    @Binding var expanded_items: [UUID: Bool]
    
    private var is_expanded_binding: Binding<Bool>
    
    public init(item: StateItem, expanded_items: Binding<[UUID: Bool]>)
    {
        self.item = item
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
                        expanded_items: $expanded_items
                    )
                    .padding(.leading, 20)
                }
            }
            label:
            {
                item_label
            }
        }
        else
        {
            item_label
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

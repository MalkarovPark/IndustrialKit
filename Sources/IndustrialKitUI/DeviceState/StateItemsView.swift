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
    @ObservedObject var device_state: DeviceState
    
    @State private var expandedItems: [UUID: Bool] = [:]
    
    public init(
        device_state: DeviceState
    )
    {
        self.device_state = device_state
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if device_state.items.count > 0
            {
                List
                {
                    ForEach(device_state.items.indices, id: \.self)
                    { index in
                        StateItemListView(
                            item: device_state.items[index],
                            expandedItems: $expandedItems
                        )
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
}

struct StateItemListView: View
{
    @ObservedObject var item: StateItem
    @Binding var expandedItems: [UUID: Bool]
    
    private var isExpandedBinding: Binding<Bool>
    
    init(item: StateItem, expandedItems: Binding<[UUID: Bool]>)
    {
        self.item = item
        self._expandedItems = expandedItems
        
        self.isExpandedBinding = Binding(
            get: { expandedItems.wrappedValue[item.id] ?? true },
            set: { expandedItems.wrappedValue[item.id] = $0 }
        )
    }
    
    var body: some View
    {
        if let children = item.children, !children.isEmpty
        {
            DisclosureGroup(isExpanded: isExpandedBinding)
            {
                ForEach(children.indices, id: \.self)
                { index in
                    StateItemListView(
                        item: children[index],
                        expandedItems: $expandedItems
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
        @ObservedObject var device_state = DeviceState(
            items: [
                //StateItem(name: "Temperature", value: "+10º", symbol_name: "thermometer"),
                //StateItem(name: "Еngine", value: "+50º", symbol_name: "thermometer.transmission"), StateItem(name: "Fridge", value: "-40º", symbol_name: "thermometer.snowflake.circle"),
                
                StateItem(name: "Speed", value: "70 mm/sec", symbol_name: "windshield.front.and.wiper.intermittent")
            ]
        )
        
        var body: some View
        {
            StateItemsView(device_state: device_state)
                .frame(width: 320, height: 240)
        }
    }
}

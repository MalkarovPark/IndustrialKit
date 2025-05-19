//
//  StateView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI

public struct StateView: View
{
    @Binding public var states_data: [StateItem]?
    
    public init(states_data: Binding<[StateItem]?>)
    {
        self._states_data = states_data
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if states_data != nil
            {
                List
                {
                    ForEach(is_expanded_binding($states_data, default: []).wrappedValue.indices, id: \.self)
                    { index in
                        StateItemListView(item: is_expanded_binding($states_data, default: [])[index])
                    }
                }
                .listStyle(.plain)
                .padding()
            }
            else
            {
                EmptyView()
            }
        }
        #if !os(visionOS)
        .background(.white)
        #endif
    }
    
    private func is_expanded_binding(_ binding: Binding<[StateItem]?>, default defaultValue: [StateItem]) -> Binding<[StateItem]>
    {
        Binding<[StateItem]>(
            get: { binding.wrappedValue ?? defaultValue },
            set: { binding.wrappedValue = $0 }
        )
    }
}

struct StateItemListView: View
{
    @Binding var item: StateItem
    
    @State private var is_expanded = true
    
    var body: some View
    {
        if let children = item.children, !children.isEmpty
        {
            DisclosureGroup(isExpanded: $is_expanded)
            {
                ForEach(children.indices, id: \.self)
                { index in
                    StateItemListView(item: Binding(
                        get: { item.children![index] },
                        set: { item.children![index] = $0 }
                    ))
                }
            }
            label:
            {
                itemLabel
            }
        }
        else
        {
            itemLabel
        }
    }
    
    private var itemLabel: some View
    {
        HStack
        {
            if let imageName = item.image
            {
                Image(systemName: imageName)
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
}

struct StateItemView: View
{
    var item: StateItem
    
    var body: some View
    {
        HStack
        {
            if item.image != nil
            {
                Image(systemName: item.image ?? "questionmark")
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
        @State var chart_data: [WorkspaceObjectChart]? = [WorkspaceObjectChart]()
        @State var states_data: [StateItem]? = [StateItem]()
        
        var body: some View
        {
            StateView(states_data: $states_data)
                .frame(width: 320, height: 240)
                .onAppear
                {
                    states_data?.append(StateItem(name: "Temperature", value: "+10º", image: "thermometer"))
                    states_data?[0].children = [StateItem(name: "Еngine", value: "+50º", image: "thermometer.transmission"),
                                         StateItem(name: "Fridge", value: "-40º", image: "thermometer.snowflake.circle")]
                    
                    states_data?.append(StateItem(name: "Speed", value: "70 mm/sec", image: "windshield.front.and.wiper.intermittent"))
                }
        }
    }
}

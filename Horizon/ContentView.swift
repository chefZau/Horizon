//
//  ContentView.swift
//  Horizon
//
//  Created by Luca Zhou on 2026-01-03.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
            .padding()

#if DEBUG
            DebugLocationView()
                .padding()
#endif
        }
    }
}

#Preview {
    ContentView()
}

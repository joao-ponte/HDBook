//
//  ContentView.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "book")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("HD Book")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

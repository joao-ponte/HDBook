//
//  ModifiedTutorialView.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI
import InterfaceOrientation

struct ModifiedTutorialView: View {
    @ObservedObject var viewModel: TutorialCardsViewModel
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @State private var currentIndex = 0  // To track the currently visible card
    
    init(viewModel: TutorialCardsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(viewModel.tutorialCards.enumerated()), id: \.element.title) { index, card in
                        ModifiedTutorialCardView(card: card)
                            .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.90, alignment: .leading)
                            .opacity(currentIndex == index ? 1.0 : 0.5)  // Full opacity for current card, reduced for others
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)  // Add smooth transition
                            .tag(index)  // Use the index to track the current view
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))  // Hide default indicators
                
                // HStack with indicators
                HStack {
                    ForEach(0..<viewModel.tutorialCards.count, id: \.self) { index in
                        Image("ElipseTutorial")
                            .resizable()
                            .frame(width: index == currentIndex ? 20 : 10, height: index == currentIndex ? 20 : 10)
                            .padding(.horizontal, 2)
                    }
                }
                .padding(.bottom, 61)
                
                HStack(alignment: .center, spacing: 0) {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()  // Dismiss the view
                    }) {
                        Text("Close")
                            .font(Font.custom("CaslonDoric-Medium", size: 17))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(50)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom)
                .frame(width: geometry.size.width, alignment: .bottom)
            }
        }
        .interfaceOrientations(.portrait)
        .background(Color(red: 1, green: 0.4, blue: 0.36))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchTutorialCards()
        }
    }
}

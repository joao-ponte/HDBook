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
    
    init(viewModel: TutorialCardsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.tutorialCards, id: \.title) { card in
                            ModifiedTutorialCardView(card: card)
                                .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.90, alignment: .leading)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .rotation3DEffect(.degrees(phase.value * -40.0), axis: (x: 0, y: 1, z: 0))
                                }
                        }
                    }
                }
                Spacer()
                
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
                .padding(.bottom, 36)
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

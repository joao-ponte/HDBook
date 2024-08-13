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
        
        GeometryReader{ geometry in
            VStack {
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack{
                        ForEach(viewModel.tutorialCards, id: \.title) { card in
                            
                            ModifiedTutorialCardView(card: card)
                                .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.90, alignment: .leading)
                                .scrollTransition(axis: .horizontal){ content, phase in
                                    content
                                        .rotation3DEffect(.degrees(phase.value * -40.0), axis: (x: 0, y: 1, z: 0))
                                }
                        }
                    }
                }
            }
        }
        .interfaceOrientations(.portrait)
        .background(.black)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "arrow.backward.circle")
            }
            .foregroundColor(AppColors.Active.red)
        })
        .onAppear {
            viewModel.fetchTutorialCards()
        }
    }
}

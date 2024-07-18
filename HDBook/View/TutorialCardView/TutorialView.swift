//
//  TutorialView.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI

struct TutorialView: View {
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
                            
                            TutorialCardView(card: card)
                                .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.90, alignment: .leading)
                                .scrollTransition(axis: .horizontal){ content, phase in
                                    content
                                        .rotation3DEffect(.degrees(phase.value * -40.0), axis: (x: 0, y: 1, z: 0))
                                }
                        }
                    }
                }
                
                NavigationLink("Skip") {
                    ARCameraView()
                }
                .frame(width: 100, height: 40, alignment: .center)
                .font(Font.custom(Fonts.CaslonDoric.medium, size: 19))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.Active.grey))
                .foregroundStyle(Color.white)
            }
        }
        .background(.black)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchTutorialCards()
        }
    }
}

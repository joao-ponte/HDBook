//
//  TutorialCardView.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI

struct TutorialCardView: View {
    
    let card: TutorialCards
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                .frame(height: geometry.size.height * (120 / 844))
                
                Text(card.title)
                    .foregroundColor(.white)
                    .font(.custom(Fonts.CaslonDoric.medium, size: geometry.size.width * 0.18))
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                
                VStack {
                    VStack(alignment: .center, spacing: 0) {
                        Image(card.backgroundImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                    }
                    .padding(0)
                    .frame(width: 260, height: 260, alignment: .center)
                    
                    Text(card.textTutorial)
                        .foregroundColor(.white)
                        .font(.custom(Fonts.CaslonDoric.regular, size: geometry.size.width * 0.07))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil) // Allow unlimited lines
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .background(Color(red: 1, green: 0.4, blue: 0.36))
            .dynamicTypeSize(.xSmall ... .xxLarge)
        }
    }
}

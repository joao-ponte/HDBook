//
//  TutorialCardView.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import SwiftUI

struct TutorialCardView: View {
    
    let card: TutorialCards
    let linkToPhotos = URL(string: "https://www.hayesdavidson.com/stories/cinemagraphs")!
    
    var body: some View {
        
        GeometryReader { geometry in
            VStack {
                Spacer()
                Text(card.title)
                    .foregroundColor(.white)
                    .font(.custom(Fonts.CaslonDoric.medium, size: geometry.size.width * 0.13))
                    .padding(.top, geometry.size.height * 0.03)
                    .padding(.leading, geometry.size.width * 0.08)
                    .padding(.bottom, geometry.size.height * 0.05)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .minimumScaleFactor(0.5)
                
                Spacer()
                VStack {
                    Text(card.textTutorial)
                        .foregroundColor(.white)
                        .font(.custom(Fonts.CaslonDoric.regular, size: geometry.size.width * 0.06))
                        .multilineTextAlignment(.leading)
                        .padding(.top, geometry.size.height * 0.05)
                        .padding([.leading, .trailing], geometry.size.height * 0.035)
                        .minimumScaleFactor(0.5)
                        .minimumScaleFactor(0.5)
                    
                    
                    Image(card.backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                    
                    if card.hasShareButton || card.hasStartButton {
                        
                        if(card.hasShareButton) {
                            ShareLink(item: linkToPhotos) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .padding()
                            .font(Font.custom(Fonts.CaslonDoric.medium, size: 16))
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppColors.Active.red))
                            .foregroundStyle(Color.white)
                            .padding(.bottom, 24)
                            .minimumScaleFactor(0.5)
                        }
                        if(card.hasStartButton) {
                            NavigationLink(card.buttonText) {
                                ARCameraView()
                            }
                            .padding()
                            .font(Font.custom(Fonts.CaslonDoric.medium, size: geometry.size.width * 0.04))
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppColors.Active.red))
                            .foregroundStyle(Color.white)
                            .padding(.bottom, 24)
                            .minimumScaleFactor(0.5)
                        }
                        
                    } else {
                        Button(card.buttonText) {
                            // Action for share button
                        }
                        .padding()
                        .font(Font.custom(Fonts.CaslonDoric.medium, size: geometry.size.width * 0.04))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.Active.grey))
                        .foregroundStyle(AppColors.Active.grey)
                        .padding(.bottom, 24)
                    }
                    
                }
                .background(AppColors.Active.grey)
                .overlay(
                    RoundedRectangle(cornerRadius: 60)
                        .stroke(linearGradient, style: StrokeStyle(lineWidth: 5))
                )
                .cornerRadius(60)
                .frame(width: geometry.size.width, height: geometry.size.height * 0.55, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                Spacer()
            }
            .background(.black)
            .dynamicTypeSize(.xSmall ... .xxLarge)
        }
    }
    
    var linearGradient: LinearGradient {
        LinearGradient(colors: [.clear, .white, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

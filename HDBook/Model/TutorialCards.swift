//
//  TutorialCards.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import Foundation

struct TutorialCards {
    let title: String
    let textTutorial: String
    let backgroundImage: String
}

struct TutorialCardsData {
    static let cards: [TutorialCards] = [
        TutorialCards(title: "Let's get you started!",
                      textTutorial: "Swipe left for a couple of tips on how to get the best experience.",
                      backgroundImage: "smileTutorial"
                     ),
        
        TutorialCards(title: "Volume up.",
                      textTutorial: "",
                      backgroundImage: "volumeTutorial"
                     ),
        
        TutorialCards(title: "Prepare your images.",
                      textTutorial: "Lay them on a flat surface",
                      backgroundImage: "prepareImageTutorial"
                     ),
        
        TutorialCards(title: "Capture the full image.",
                      textTutorial: "Try to capture the entire image in the centre of your camera's screen.",
                      backgroundImage: "captureTutorial"
                     ),
        
        TutorialCards(title: "Check your environment.",
                      textTutorial: "Make sure your environment isn't too dark or too light.",
                      backgroundImage: "environmentTutorial"
                     ),
        
        TutorialCards(title: "Keep it simple.",
                      textTutorial: "Try to avoid reflections or direct lighting.",
                      backgroundImage: "keepSimpleTutorial"
                     )
    ]
}

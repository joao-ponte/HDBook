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
    let hasShareButton: Bool
    let hasStartButton: Bool
    let buttonText: String
}

struct TutorialCardsData {
    static let cards: [TutorialCards] = [
        TutorialCards(title: "Let's get you started!",
                      textTutorial: "Swipe left for a couple of tips on how to get the best experience.",
                      backgroundImage: "Hand-wave-white",
                      hasShareButton: false,
                      hasStartButton: false,
                      buttonText: "PlaceHolder"),
        
        TutorialCards(title: "Prepare your images.",
                      textTutorial: "Lay them out on a flat surface, or share the digital library to a nearby device.",
                      backgroundImage: "Stack-white",
                      hasShareButton: true,
                      hasStartButton: false,
                      buttonText: "Share"),
        
        TutorialCards(title: "Capture the full image.",
                      textTutorial: "Try to capture the entire image in the centre of your camera's screen.",
                      backgroundImage: "CentreFrameComposite",
                      hasShareButton: false,
                      hasStartButton: false,
                      buttonText: "PlaceHolder"),
        
        TutorialCards(title: "Check your environment.",
                      textTutorial: "Make sure your environment isn't too dark or too light.",
                      backgroundImage: "Brightness-icon-5-white",
                      hasShareButton: false,
                      hasStartButton: false,
                      buttonText: "PlaceHolder"),
        
        TutorialCards(title: "Keep it simple.",
                      textTutorial: "Try to avoid reflections or direct lighting.",
                      backgroundImage: "reflection_white",
                      hasShareButton: false,
                      hasStartButton: false,
                      buttonText: "PlaceHolder"),
        
        TutorialCards(title: "You're all set!",
                      textTutorial: "Click the button below to launch your device's camera.",
                      backgroundImage: "tick_black with white arrow crop",
                      hasShareButton: false,
                      hasStartButton: true,
                      buttonText: "Let's go")
    ]
}

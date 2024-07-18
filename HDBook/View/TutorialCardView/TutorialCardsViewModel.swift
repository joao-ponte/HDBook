//
//  TutorialCardsViewModel.swift
//  HDBook
//
//  Created by hayesdavidson on 18/07/2024.
//

import Foundation

class TutorialCardsViewModel: ObservableObject {
    @Published var tutorialCards: [TutorialCards] = []
    
    private let isFirstLaunchKey = "isFirstLaunch"
    
    @Published var isFirstLaunch: Bool {
            didSet {
                UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch")
            }
        }
    
    init() {
        if UserDefaults.standard.object(forKey: isFirstLaunchKey) == nil {
            UserDefaults.standard.set(true, forKey: isFirstLaunchKey)
        }
        self.isFirstLaunch = UserDefaults.standard.bool(forKey: isFirstLaunchKey)
        fetchTutorialCards()
    }
    
    func fetchTutorialCards() {
        tutorialCards = TutorialCardsData.cards
    }
}

//
//  NoInternetAlertView.swift
//  HDBook
//
//  Created by hayesdavidson on 21/08/2024.
//

import SwiftUI

struct NoInternetAlertView: View {
    var dismissAction: () -> Void
    
    var body: some View {
        ZStack {
            // Background dimming effect
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer() // Pushes the alert to the bottom
                
                VStack(alignment: .center, spacing: 18) {
                    // Main text
                    Text("Please check your\nconnection and try again.")
                        .font(Font.custom("CaslonDoric-Medium", size: 24))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 1, green: 0.4, blue: 0.36))
                        .padding(.top, 14)
                        .frame(maxWidth: .infinity, alignment: .top)
                    
                    // OK Button
                    Button(action: {
                        dismissAction()
                    }) {
                        Text("OK")
                            .font(Font.custom("CaslonDoric-Medium", size: 24))
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(Color(red: 1, green: 0.4, blue: 0.36))
                            .cornerRadius(50)
                    }
                    .frame(width: 78)
                    
                    Spacer()
                        .frame(height: 32) // Adds spacing below the button
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 0)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.95, green: 0.82, blue: 0.83))
                .cornerRadius(12)
                .shadow(radius: 10)
            }
            .edgesIgnoringSafeArea(.bottom) // Ensure it goes to the bottom of the screen
        }
    }
}

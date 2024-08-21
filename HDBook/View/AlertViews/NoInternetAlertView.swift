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
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image("sadDog")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                Text("No Internet Connection")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                
                Text("Please check your internet connection and try again.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    dismissAction()
                }) {
                    Text("OK")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .frame(maxWidth: 300)
        }
    }
}

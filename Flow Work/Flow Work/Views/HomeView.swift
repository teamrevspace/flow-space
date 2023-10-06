//
//  HomeView.swift
//  Flow Work
//
//  Created by Allen Lin on 10/6/23.
//

import Foundation
import SwiftUI
import Firebase

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack {
            Text("Hi \(viewModel.displayName)!")
            Button("Create a session") {
                viewModel.createSession()
            }
            Button("Join a session") {
                viewModel.joinSession()
            }
            Button("Log out") {
                viewModel.signOut()
            }
        }.standardFrame()
    }
}

//
//  AuthServiceProtocol.swift
//  Flow Work
//
//  Created by Allen Lin on 10/12/23.
//

import Foundation
import Combine

protocol AuthServiceDelegate: AnyObject {
    func didSignIn()
    func didSignOut()
}

protocol AuthServiceProtocol {
    var delegate: AuthServiceDelegate? { get set }
    
    var statePublisher: AnyPublisher<AuthState, Never> { get }
    
    func signInWithGoogle()
    func signOut()
}
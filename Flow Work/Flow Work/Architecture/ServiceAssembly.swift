//
//  ServiceAssembly.swift
//  Flow Work
//
//  Created by Allen Lin on 10/12/23.
//

import Swinject

final class ServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(AuthServiceProtocol.self) { r in
            AuthService(resolver: r)
        }
        .inObjectScope(.container)
        
        container.register(SessionServiceProtocol.self) { r in
            SessionService(resolver: r)
        }
        .inObjectScope(.container)
        
        container.register(StoreServiceProtocol.self) { r in
            StoreService(resolver: r)
        }
        .inObjectScope(.container)

        container.register(ErrorServiceProtocol.self) { _ in
            ErrorService()
        }
        .inObjectScope(.container)
    
    }
}
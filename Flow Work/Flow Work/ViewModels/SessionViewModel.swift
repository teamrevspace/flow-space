//
//  SessionViewModel.swift
//  Flow Work
//
//  Created by Allen Lin on 10/6/23.
//

import Foundation
import Combine
import Swinject
import AppKit

protocol SessionViewModelDelegate: AnyObject {
    func showLobbyView()
}

class SessionViewModel: ObservableObject {
    weak var delegate: SessionViewModelDelegate?
    
    @Published var authService: AuthServiceProtocol
    @Published var sessionService: SessionServiceProtocol
    @Published var roomService: RoomServiceProtocol
    @Published var storeService: StoreServiceProtocol
    @Published var todoService: TodoServiceProtocol
    @Published var networkService: NetworkServiceProtocol
    
    @Published var authState = AuthState()
    @Published var sessionState = SessionState()
    @Published var todoState = TodoState()
    
    @Published var totalSessionsCount: Int? = nil
    @Published var inFocusMode: Bool = false
    
    private let defaults = UserDefaults.standard
    private let ignoreSystemWindows: Bool = false
    private let closeApps: Bool = false
    
    private let resolver: Resolver
    private var cancellables = Set<AnyCancellable>()
    
    init(resolver: Resolver) {
        self.resolver = resolver
        self.authService = resolver.resolve(AuthServiceProtocol.self)!
        self.sessionService = resolver.resolve(SessionServiceProtocol.self)!
        self.roomService = resolver.resolve(RoomServiceProtocol.self)!
        self.todoService = resolver.resolve(TodoServiceProtocol.self)!
        self.storeService = resolver.resolve(StoreServiceProtocol.self)!
        self.networkService = resolver.resolve(NetworkServiceProtocol.self)!
        
        authService.statePublisher
            .assign(to: \.authState, on: self)
            .store(in: &cancellables)
        sessionService.statePublisher
            .assign(to: \.sessionState, on: self)
            .store(in: &cancellables)
        todoService.statePublisher
            .assign(to: \.todoState, on: self)
            .store(in: &cancellables)
    }
    
    func fetchTodoList() {
        guard let currentUserId = self.authState.currentUser?.id else { return }
        self.storeService.findTodosByUserId(userId: currentUserId) { todos in
            self.todoService.initTodoList(todos: todos)
        }
    }
    
    func copyToClipboard(textToCopy: String) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(textToCopy, forType: .string)
    }
    
    func addDraftTodo() {
        if (!self.todoState.draftTodo.title.isEmpty) {
            guard let currentUserId = self.authState.currentUser?.id else { return }
            var newTodo = self.todoState.draftTodo
            newTodo.userIds = [currentUserId]
            self.storeService.addTodo(todo: newTodo)
            self.todoService.updateDraftTodo(todo: Todo())
            self.todoState.isHoveringActionButtons.append(false)
        }
    }
    
    func leaveSession() {
        if let currentSessionId = self.sessionState.currentSession?.id {
            self.sessionService.leaveSession(currentSessionId)
        }
        self.delegate?.showLobbyView()
    }
    
    func createAudioRoom() {
        guard let roomId = self.sessionState.currentSession?.id else {
            print("No room Id available.")
            return
        }
        
        roomService.createRoom(roomId: roomId)
    }
    
    func joinAudioRoom() {
        guard let roomId = self.sessionState.currentSession?.id else {
            print("No room Id available.")
            return
        }
        
        roomService.joinRoom(roomId: roomId)
    }
}

// MARK: focus mode implementation
extension SessionViewModel {
    func saveSessionGlobal() {
        var array = [String]()
        var arrayNames = [String]()
        var sessionName = ""
        var sessionFull = ""
        var sessionsAdded = 1
        var sessionsRemaining = 0
        var totalSessions = 0
        var lastState = false;
        
        let runningApp = NSWorkspace.shared.frontmostApplication!
        
        NSApp.setActivationPolicy(.regular)
        
        for runningApplication in NSWorkspace.shared.runningApplications {
            
            // Check if the application is in the exception list
            if ((ignoreSystemWindows && (runningApplication.localizedName != "Finder" && runningApplication.localizedName != "Activity Monitor" && runningApplication.localizedName != "System Preferences" && runningApplication.localizedName != "App Store")) || !ignoreSystemWindows) {
                
                // Ignore itself + only affect regular applications
                if (runningApplication.activationPolicy == .regular && runningApplication.localizedName != "Later" && runningApplication != runningApp) {
                    array.append(runningApplication.executableURL!.absoluteString)
                    arrayNames.append(runningApplication.localizedName!)
                    
                    // Only close applications if "keep windows open" is disabled
                    if (!closeApps) {
                        runningApplication.hide()
                    } else {
                        if (runningApplication.localizedName != "Finder") {
                            runningApplication.terminate()
                        }
                        lastState = true;
                    }
                    
                    // Get application names for session label
                    if (sessionName == "") {
                        sessionName = runningApplication.localizedName!
                        sessionFull = runningApplication.localizedName!
                    } else if (sessionsAdded <= 3) {
                        sessionName += ", "+runningApplication.localizedName!
                    } else {
                        sessionsRemaining += 1
                    }
                    sessionFull += ", "+runningApplication.localizedName!
                    sessionsAdded += 1
                    totalSessions += 1
                }
            }
        }
        
        if ((ignoreSystemWindows && (runningApp.localizedName != "Finder" && runningApp.localizedName != "Activity Monitor" && runningApp.localizedName != "System Preferences" && runningApp.localizedName != "App Store")) || !ignoreSystemWindows) {
            if (runningApp.activationPolicy == .regular && runningApp.localizedName != "Later") {
                array.append(runningApp.executableURL!.absoluteString)
                arrayNames.append(runningApp.localizedName!)
                
                // Only close applications if "keep windows open" is disabled
                if (!closeApps) {
                    runningApp.hide()
                } else {
                    if (runningApp.localizedName != "Finder") {
                        runningApp.terminate()
                    }
                    lastState = true;
                }
                // Get application names for session label
                if (sessionName == "") {
                    sessionName = runningApp.localizedName!
                    sessionFull = runningApp.localizedName!
                } else if (sessionsAdded <= 3) {
                    sessionName += ", "+runningApp.localizedName!
                } else {
                    sessionsRemaining += 1
                }
                sessionFull += ", "+runningApp.localizedName!
                sessionsAdded += 1
                totalSessions += 1
            }
        }
        
        if (sessionsRemaining > 0) {
            sessionName += ", +"+String(sessionsRemaining)+" more"
        }
        
        NSApp.setActivationPolicy(.accessory)
        
        // Save session data
        defaults.set(lastState, forKey:"lastState")
        defaults.set(array, forKey: "apps")
        defaults.set(arrayNames, forKey: "appNames")
        defaults.set(sessionName, forKey: "sessionName")
        defaults.set(sessionFull, forKey: "sessionFullName")
        defaults.set(String(totalSessions), forKey: "totalSessions")
        updateSession()
        
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.closeMenuPopover(self)
    }
    
    func restoreSessionGlobal() {
        
        // Check if apps are to be terminated as opposed to hiding them
        if (closeApps) {
            for runningApplication in NSWorkspace.shared.runningApplications {
                if ((ignoreSystemWindows && (runningApplication.localizedName != "Finder" && runningApplication.localizedName != "Activity Monitor" && runningApplication.localizedName != "System Preferences" && runningApplication.localizedName != "App Store")) || !ignoreSystemWindows) {
                    if (runningApplication.activationPolicy == .regular && runningApplication.localizedName != "Terminal") {
                        runningApplication.terminate()
                    }
                }
            }
        }
        
        // Restore apps
        if let apps = defaults.object(forKey: "appNames") as? [String] {
            if let executables = defaults.object(forKey: "apps") as? [String] {
                for (index, app) in apps.enumerated() {
                    activate(name:app, url:executables[index])
                }
                noSessions()
            }
        }
        
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.closeMenuPopover(self)
    }
    
    private func checkAnyWindows() {
        var totalSessions = 0
        for runningApplication in NSWorkspace.shared.runningApplications {
            if ((ignoreSystemWindows && (runningApplication.localizedName != "Finder" && runningApplication.localizedName != "Activity Monitor" && runningApplication.localizedName != "System Preferences" && runningApplication.localizedName != "App Store")) || !ignoreSystemWindows) {
                if (runningApplication.activationPolicy == .regular) {
                    totalSessions += 1
                }
            }
        }
        
        self.totalSessionsCount = totalSessions
    }
    
    private func activate(name: String, url: String) {
        guard let app = NSWorkspace.shared.runningApplications.filter ({
            return $0.localizedName == name
        }).first else {
            do {
                let task = Process()
                task.executableURL = URL.init(string:url)
                try task.run()
            } catch {
                print("Error activating windows")
            }
            return
        }
        
        app.unhide()
    }
    
    private func updateSession() {
        defaults.set(true, forKey:"session")
        self.inFocusMode = true
        checkAnyWindows()
    }
    
    private func noSessions() {
        defaults.set(false, forKey:"session")
        self.inFocusMode = false
        checkAnyWindows()
    }
}

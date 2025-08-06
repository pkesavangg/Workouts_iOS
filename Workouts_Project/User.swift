//
//  User.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 05/08/25.
//


import Foundation
import SwiftUI
import Combine

struct User: Codable {
    let id: Int
    let name: String
    let username: String
    let email: String
}

import Network
import Foundation
import Combine

// MARK: - Network Monitor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.filter {
                    path.usesInterfaceType($0.type)
                }.first?.type
            }
        }
        monitor.start(queue: queue)
        
        // Immediately evaluate current path (optional)
        let currentPath = monitor.currentPath
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = currentPath.status == .satisfied
            self?.connectionType = currentPath.availableInterfaces.first?.type
        }
    }
    
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        stopMonitoring()
    }
}

final class HTTPClient {
    static let shared = HTTPClient()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }
    
    func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
protocol UserAPIRepositoryProtocol {
    func fetchUser() async throws -> User
}

final class UserAPIRepository: UserAPIRepositoryProtocol {
    func fetchUser() async throws -> User {
        let url = URL(string: "https://jsonplaceholder.typicode.com/users/1")!
        let fetchedUser: User = try await HTTPClient.shared.get(url)
        return fetchedUser
    }
}

protocol UserServiceProtocol {
    var user: User? { get }
    func loadUser() async throws
}

final class UserService: UserServiceProtocol, ObservableObject {
    static let shared = UserService()
    @Published private(set) var user: User?
    private let apiRepo: UserAPIRepositoryProtocol
    
    init(apiRepo: UserAPIRepositoryProtocol = UserAPIRepository()) {
        self.apiRepo = apiRepo
    }
    
    func loadUser() async throws {
        self.user = try await apiRepo.fetchUser()
    }
}


@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userService: UserService
    private var cancellables = Set<AnyCancellable>()
    
    init(userService: UserService = UserService.shared) {
        self.userService = userService
        
        // Bind user from service
        userService.$user
            .receive(on: RunLoop.main)
            .assign(to: &$user)
    }
    
    func loadUser() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await userService.loadUser()
            } catch {
                errorMessage = "Failed to load user: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

struct UserView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let user = viewModel.user {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Name: \(user.name)")
                    Text("Username: \(user.username)")
                    Text("Email: \(user.email)")
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            UserNameView()
            
            Button("Get User") {
                viewModel.loadUser()
            }
        }
        .padding()
    }
}


@MainActor
final class UserNameViewModel: ObservableObject {
    @Published var user: User?
    @Published var isNetworkConnected: Bool = false
    private let userService: UserService
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NetworkMonitor.shared
    
    init(userService: UserService = UserService.shared) {
        self.userService = userService
        
        // Bind user from service
        userService.$user
            .receive(on: RunLoop.main)
            .assign(to: &$user)
        
        // Observe network changes
        networkMonitor.$isConnected
            .receive(on: RunLoop.main)
            .assign(to: &$isNetworkConnected)
        
    }
}

struct UserNameView: View {
    @StateObject private var viewModel = UserNameViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            
            if !viewModel.isNetworkConnected {
                Text("No internet connection")
                    .foregroundColor(.red)
            } else {
                Text("Internet is connected")
                    .foregroundColor(.green)
            }
            
            if let user = viewModel.user {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Name: \(user.name)")
                        .fontWeight(.bold)
                }
            } else {
                Text("No user data available")
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

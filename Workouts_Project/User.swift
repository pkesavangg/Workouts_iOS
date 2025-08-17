//
//  User.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 05/08/25.
//


import Foundation
import SwiftUI
import Combine
import SwiftData

struct User: Codable {
    let id: Int
    let name: String
    let username: String
    let email: String
}

@Model
class UserData {
    var id: Int
    var name: String
    var username: String
    var email: String
    var lastUpdated: Date
    
    init(id: Int, name: String, username: String, email: String) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.lastUpdated = Date()
    }
    
    convenience init(from user: User) {
        self.init(id: user.id, name: user.name, username: user.username, email: user.email)
    }
    
    func toUser() -> User {
        return User(id: id, name: name, username: username, email: email)
    }
}

import Network
import Foundation
import Combine

// MARK: - Network Monitor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected = true
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
    
    func post<T: Decodable, U: Encodable>(_ url: URL, body: U) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
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

protocol UserRepositoryProtocol {
    func saveUser(_ user: User) async throws
    func loadUser() async throws -> User?
    func deleteAllUsers() async throws
}

final class UserRepository: UserRepositoryProtocol {
    private let modelContext: ModelContext = DataStore.shared.context
    
    func saveUser(_ user: User) async throws {
        // Remove existing user data
        let descriptor = FetchDescriptor<UserData>()
        let existingUsers = try modelContext.fetch(descriptor)
        for existingUser in existingUsers {
            modelContext.delete(existingUser)
        }
        
        // Save new user data
        let userData = UserData(from: user)
        modelContext.insert(userData)
        try modelContext.save()
    }
    
    func loadUser() async throws -> User? {
        let descriptor = FetchDescriptor<UserData>(sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)])
        let userData = try modelContext.fetch(descriptor)
        return userData.first?.toUser()
    }
    
    func deleteAllUsers() async throws {
        let descriptor = FetchDescriptor<UserData>()
        let existingUsers = try modelContext.fetch(descriptor)
        for existingUser in existingUsers {
            modelContext.delete(existingUser)
        }
        try modelContext.save()
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
    private let userRepo: UserRepositoryProtocol
    
    init(apiRepo: UserAPIRepositoryProtocol = UserAPIRepository(), userRepo: UserRepositoryProtocol = UserRepository()) {
        self.apiRepo = apiRepo
        self.userRepo = userRepo
        
        // Load user from SwiftData on initialization
        Task {
            await loadUserFromStorage()
        }
    }
    
    private func loadUserFromStorage() async {
        do {
            if let storedUser = try await userRepo.loadUser() {
                self.user = storedUser
            }
        } catch {
            print("Failed to load user from storage: \(error)")
        }
    }
    
    func loadUser() async throws {
        do {
            // Try to fetch from API first
            let fetchedUser = try await apiRepo.fetchUser()
            
            self.user = fetchedUser
            // Save to SwiftData
            try await userRepo.saveUser(fetchedUser)
            
        } catch {
            // If network fails, try to load from SwiftData
            await loadUserFromStorage()
            
            // If no data in storage, rethrow the original error
            if user == nil {
                throw error
            }
        }
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

// MARK: - Email Validation Models
struct EmailCheckRequest: Codable {
    let email: String
}

struct EmailCheckResponse: Codable {
    let isInUse: Bool
}

enum EmailValidationState {
    case idle
    case checking
    case available
    case inUse
    case error(String)
}

// MARK: - Email Validation Service
@MainActor
final class EmailValidationService: ObservableObject {
    @Published var validationState: EmailValidationState = .idle
    @Published var email: String = "" {
        didSet {
            validateEmail()
        }
    }
    
    private var validationTask: Task<Void, Never>?
    private let debounceDelay: TimeInterval = 0.5
    
    private func validateEmail() {
        // Cancel previous validation task
        validationTask?.cancel()
        
        // Reset state if email is empty
        guard !email.isEmpty else {
            validationState = .idle
            return
        }
        
        // Basic email format validation
        guard isValidEmailFormat(email) else {
            validationState = .error("Invalid email format")
            return
        }
        
        // Set checking state immediately
        validationState = .checking
        
        // Create new debounced validation task
        validationTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await checkEmailAvailability()
        }
    }
    
    private func checkEmailAvailability() async {
        do {
            let url = URL(string: "https://api.smartbaby.greatergoods.com/v1/account/email-check")!
            let request = EmailCheckRequest(email: email)
            let response: EmailCheckResponse = try await HTTPClient.shared.post(url, body: request)
            
            guard !Task.isCancelled else { return }
            
            validationState = response.isInUse ? .inUse : .available
        } catch {
            guard !Task.isCancelled else { return }
            validationState = .error("Network error occurred")
        }
    }
    
    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Email Validation View
struct EmailValidationView: View {
    @StateObject private var emailService = EmailValidationService()
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Email Availability Checker")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter email address", text: $emailService.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                // Validation status
                HStack {
                    switch emailService.validationState {
                    case .idle:
                        Text("Enter an email to check availability")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    
                    case .checking:
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Checking availability...")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    
                    case .available:
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Email is available!")
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                                .font(.caption)
                        }
                    
                    case .inUse:
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Email is already in use")
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                                .font(.caption)
                        }
                    
                    case .error(let message):
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(message)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                                .font(.caption)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Email Validation")
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

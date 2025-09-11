//
//  ContentView.swift
//  ShambaGo
//
//  Created by Vince Mwangi on 3/20/25.
//

import SwiftUI
import UIKit

// MARK: - Color Extensions
extension Color {
    static let shambaGreen = Color(hex: "4CAF50")
    static let shambaBlue = Color(hex: "007BFF")
    static let shambaYellow = Color(hex: "FFD700")
    static let shambaRed = Color(hex: "FF5733")
    static let shambaText = Color(hex: "2C3E50")
    static let shambaBackgroundPrimary = Color(hex: "E0E5E0")
    static let shambaBackgroundSecondary = Color(hex: "C8E6C9")
    static let shambaCardBackground = Color(hex: "F8F9F8")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - User Model
struct User: Codable {
    let email: String
    let name: String
    var isAuthenticated: Bool = false
}

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    init() {
        loadUser()
    }
    
    func loadUser() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = user.isAuthenticated
        }
    }
    
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        self.currentUser = nil
        self.isAuthenticated = false
    }
}

// Add after AuthenticationManager
class LocalizationManager: ObservableObject {
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "AppLanguage")
            updateLocale()
        }
    }
    
    @Published var translations: [String: [String: String]] = [
        // English is default
        "Welcome Back!": ["en": "Welcome Back!", "sw": "Karibu Tena!"],
        "Create Account": ["en": "Create Account", "sw": "Fungua Akaunti"],
        "Connect with farmers": ["en": "Connect with farmers and grow together", "sw": "Unganisha na wakulima na kukua pamoja"],
        "Email": ["en": "Email", "sw": "Barua pepe"],
        "Password": ["en": "Password", "sw": "Nywila"],
        "Full Name": ["en": "Full Name", "sw": "Jina Kamili"],
        "Sign In": ["en": "Sign In", "sw": "Ingia"],
        "Sign Out": ["en": "Sign Out", "sw": "Toka"],
        "Settings": ["en": "Settings", "sw": "Mipangilio"],
        "Language": ["en": "Language", "sw": "Lugha"],
        "Notifications": ["en": "Notifications", "sw": "Arifa"],
        "Privacy": ["en": "Privacy", "sw": "Faragha"],
        "Help Center": ["en": "Help Center", "sw": "Kituo cha Usaidizi"],
        "Contact Us": ["en": "Contact Us", "sw": "Wasiliana Nasi"],
        "About": ["en": "About", "sw": "Kuhusu"],
        "Quick Actions": ["en": "Quick Actions", "sw": "Vitendo vya Haraka"],
        "Scan Crop": ["en": "Scan Crop", "sw": "Chunguza Mazao"],
        "Crop Health": ["en": "Crop Health", "sw": "Afya ya Mazao"],
        "Analytics": ["en": "Analytics", "sw": "Uchambuzi"],
        "Alerts": ["en": "Alerts", "sw": "Arifa"],
        // Add more translations as needed
    ]
    
    init() {
        self.language = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"
        updateLocale()
    }
    
    private func updateLocale() {
        // Update app locale if needed
    }
    
    func localizedString(_ key: String) -> String {
        if let translations = translations[key],
           let translated = translations[language] {
            return translated
        }
        return key // Return original string if translation not found
    }
}

struct AuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var email = ""
    @State private var name = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSigningIn = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPasswordSuggestion = false
    @State private var suggestedPassword = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and Welcome Text
                    VStack(spacing: 20) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.shambaGreen)
                        
                        Text(localizationManager.localizedString("Welcome Back!"))
                            .font(.title.bold())
                        
                        Text(localizationManager.localizedString("Connect with farmers"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Sign In Form
                    VStack(spacing: 20) {
                        TextField(localizationManager.localizedString("Email"), text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        if !isSigningIn {
                            TextField(localizationManager.localizedString("Full Name"), text: $name)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }
                        
                        if !isSigningIn {
                            // Password Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    SecureField(localizationManager.localizedString("Password"), text: $password)
                                        .textFieldStyle(RoundedTextFieldStyle())
                                    
                                    Button {
                                        suggestedPassword = generateSecurePassword()
                                        showingPasswordSuggestion = true
                                    } label: {
                                        Image(systemName: "key.fill")
                                            .foregroundStyle(Color.shambaGreen)
                                    }
                                }
                                
                                if showingPasswordSuggestion {
                                    HStack(spacing: 8) {
                                        Text("Suggested: \(suggestedPassword)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Button {
                                            password = suggestedPassword
                                            confirmPassword = suggestedPassword
                                        } label: {
                                            Text("Use")
                                                .font(.caption.bold())
                                                .foregroundStyle(Color.shambaGreen)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                }
                                
                                // Password strength indicator
                                if !password.isEmpty {
                                    PasswordStrengthView(password: password)
                                }
                            }
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedTextFieldStyle())
                        } else {
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }
                        
                        Button(action: handleAuthentication) {
                            HStack {
                                Text(isSigningIn ? localizationManager.localizedString("Sign In") : localizationManager.localizedString("Create Account"))
                                    .bold()
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.shambaGreen)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        if isSigningIn {
                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.shambaGreen)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.secondary.opacity(0.3))
                        Text("OR")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.secondary.opacity(0.3))
                    }
                    .padding(.horizontal)
                    
                    // Social Sign In Options
                    VStack(spacing: 16) {
                        Button(action: signInWithApple) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.title3)
                                Text("Sign in with Apple")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.shambaCardBackground)
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.05), radius: 5)
                        }
                        
                        Button(action: signInWithGoogle) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                Text("Sign in with Google")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.shambaCardBackground)
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.05), radius: 5)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Toggle Sign In/Sign Up
                    HStack {
                        Text(isSigningIn ? localizationManager.localizedString("Don't have an account?") : localizationManager.localizedString("Already have an account?"))
                            .foregroundStyle(.secondary)
                        Button(isSigningIn ? localizationManager.localizedString("Sign Up") : localizationManager.localizedString("Sign In")) {
                            withAnimation {
                                isSigningIn.toggle()
                            }
                        }
                        .foregroundStyle(Color.shambaGreen)
                        .bold()
                    }
                    .font(.subheadline)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.shambaBackgroundPrimary, .shambaBackgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .alert("Authentication Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleAuthentication() {
        // Validate inputs
        guard !email.isEmpty else {
            alertMessage = "Please enter your email"
            showingAlert = true
            return
        }
        
        guard !password.isEmpty else {
            alertMessage = "Please enter your password"
            showingAlert = true
            return
        }
        
        if !isSigningIn {
            // Additional sign up validation
            guard !name.isEmpty else {
                alertMessage = "Please enter your name"
                showingAlert = true
                return
            }
            
            guard password == confirmPassword else {
                alertMessage = "Passwords do not match"
                showingAlert = true
                return
            }
            
            // Create new user and trigger navigation
            let user = User(email: email, name: name, isAuthenticated: true)
            withAnimation(.spring()) {
                authManager.saveUser(user)
            }
        } else {
            // Sign in validation
            if let savedUserData = UserDefaults.standard.data(forKey: "currentUser"),
               let savedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
                if savedUser.email == email {
                    // Trigger navigation with animation
                    withAnimation(.spring()) {
                        authManager.saveUser(savedUser)
                    }
                } else {
                    alertMessage = "Invalid email or password"
                    showingAlert = true
                }
            } else {
                alertMessage = "No account found. Please sign up."
                showingAlert = true
            }
        }
    }
    
    private func signInWithApple() {
        // Implement Apple Sign In
    }
    
    private func signInWithGoogle() {
        // Implement Google Sign In
    }
    
    private func generateSecurePassword() -> String {
        let length = 16
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    var strength: (value: Double, label: String, color: Color) {
        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasNumbers = password.contains(where: { $0.isNumber })
        let hasSpecialCharacters = password.contains(where: { "!@#$%^&*".contains($0) })
        
        let criteria = [hasUppercase, hasLowercase, hasNumbers, hasSpecialCharacters]
        let metCriteria = criteria.filter { $0 }.count
        
        switch (password.count, metCriteria) {
        case (0, _):
            return (0.0, "Empty", .gray)
        case (1...7, _):
            return (0.25, "Weak", .red)
        case (8..., 1):
            return (0.25, "Weak", .red)
        case (8..., 2):
            return (0.5, "Fair", .orange)
        case (8..., 3):
            return (0.75, "Good", .yellow)
        case (8..., 4):
            return (1.0, "Strong", .green)
        default:
            return (0.0, "Empty", .gray)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(strength.color)
                        .frame(width: geometry.size.width * strength.value, height: 4)
                }
            }
            .frame(height: 4)
            
            Text(strength.label)
                .font(.caption)
                .foregroundStyle(strength.color)
        }
        .padding(.horizontal, 8)
    }
}

// Custom TextField Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.shambaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var localizationManager = LocalizationManager()
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var rotation: Double = 0 // For loading animation
    
    var body: some View {
        Group {
            if isLoading {
                // Enhanced Loading screen
                VStack(spacing: 24) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.shambaGreen)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                    
                    Text("ShambaGo")
                        .font(.title.bold())
                    
                    // Loading indicator
                    HStack(spacing: 12) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.shambaGreen)
                                .frame(width: 8, height: 8)
                                .opacity(0.3)
                                .animation(
                                    Animation
                                        .easeInOut(duration: 0.5)
                                        .repeatForever()
                                        .delay(0.2 * Double(index)),
                                    value: isLoading
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [.shambaBackgroundPrimary, .shambaBackgroundSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .onAppear {
                    // Simulate brief loading to ensure state is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.spring()) {
                            isLoading = false
                        }
                    }
                }
            } else if authManager.isAuthenticated {
                TabView(selection: $selectedTab) {
                    HomeView(selectedTab: $selectedTab)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    DataInputView()
                        .tabItem {
                            Label("Record", systemImage: "square.and.pencil")
                        }
                        .tag(1)
                    
                    ProfileView(selectedTab: $selectedTab)
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                        .tag(2)
                }
                .tint(.shambaGreen)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
                    .environmentObject(localizationManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: authManager.isAuthenticated)
        .animation(.spring(), value: isLoading)
        .environmentObject(authManager)
        .environmentObject(localizationManager)
    }
}

struct HomeView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    AppHeader(selectedTab: $selectedTab)
                    
                    WeatherCard()
                    
                    // Quick Actions Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        FeatureCard(
                            icon: "leaf.fill",
                            title: "Soil Health",
                            subtitle: "pH: 6.5 • Good",
                            color: .shambaGreen,
                            backgroundColor: .shambaGreen.opacity(0.1)
                        )
                        FeatureCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Crop Alert",
                            subtitle: "Pest detected",
                            color: .shambaRed,
                            backgroundColor: .shambaRed.opacity(0.1)
                        )
                        FeatureCard(
                            icon: "chart.bar.fill",
                            title: "Today's Market",
                            subtitle: "Maize: ↑ +5%",
                            color: .shambaYellow,
                            backgroundColor: .shambaYellow.opacity(0.1)
                        )
                        FeatureCard(
                            icon: "person.2.fill",
                            title: "Community",
                            subtitle: "5 new posts",
                            color: .shambaBlue,
                            backgroundColor: .shambaBlue.opacity(0.1)
                        )
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.shambaText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                QuickActionButton(
                                    icon: "camera.fill",
                                    title: "Scan Crop",
                                    color: .shambaGreen
                                ) {
                                    // Handle scan crop action
                                }
                                QuickActionButton(
                                    icon: "cart.fill",
                                    title: "Sell Produce",
                                    color: .shambaYellow
                                ) {
                                    // Handle sell produce action
                                }
                                QuickActionButton(
                                    icon: "doc.text.fill",
                                    title: "Guide",
                                    color: .shambaBlue
                                ) {
                                    // Handle guide action
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    AppFooter()
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.shambaBackgroundPrimary, .shambaBackgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Color.shambaGreen)
                        Text("ShambaGo")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.shambaText)
                    }
                }
            }
        }
    }
}

struct DataInputView: View {
    @State private var soilPH = ""
    @State private var soilMoisture = ""
    @State private var selectedCrop = "Maize"
    @State private var plantingDate = Date()
    @State private var hasDisease = false
    @State private var notes = ""
    @State private var showingSuccessAlert = false
    
    let crops = ["Maize", "Beans", "Potatoes", "Wheat", "Rice"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Soil Data") {
                    TextField("Soil pH (0-14)", text: $soilPH)
                        .keyboardType(.decimalPad)
                    TextField("Soil Moisture (%)", text: $soilMoisture)
                        .keyboardType(.decimalPad)
                }
                
                Section("Crop Information") {
                    Picker("Crop Type", selection: $selectedCrop) {
                        ForEach(crops, id: \.self) { crop in
                            Text(crop)
                        }
                    }
                    DatePicker("Planting Date", selection: $plantingDate, displayedComponents: .date)
                    Toggle("Disease Symptoms", isOn: $hasDisease)
                }
                
                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: submitData) {
                        HStack {
                            Spacer()
                            Text("Submit Data")
                                .bold()
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.shambaGreen)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Record Data")
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your farming data has been recorded successfully.")
            }
        }
    }
    
    private func submitData() {
        // Here you would typically save the data to your backend
        // For now, we'll just show a success message
        showingSuccessAlert = true
        
        // Clear the form
        soilPH = ""
        soilMoisture = ""
        selectedCrop = "Maize"
        plantingDate = Date()
        hasDisease = false
        notes = ""
    }
}

struct WeatherCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Weather Header
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.title2)
                    .foregroundStyle(Color.yellow)  // Changed to yellow for sun icon
                Text("Today's Weather")
                    .font(.headline)
                Spacer()
                Text("Kiambu")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Temperature and Conditions
            HStack(alignment: .center, spacing: 16) {
                Text("24°C")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)  // Changed to primary color for better contrast
                
                VStack(alignment: .leading) {
                    Text("Partly Cloudy")
                        .font(.subheadline)
                        .foregroundStyle(.primary)  // Changed to primary color
                    Text("H: 26° L: 18°")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Additional Info
            HStack(spacing: 20) {
                WeatherInfoItem(icon: "humidity", value: "65%", label: "Humidity")
                WeatherInfoItem(icon: "wind", value: "8 km/h", label: "Wind")
                WeatherInfoItem(icon: "umbrella", value: "10%", label: "Rain")
            }
        }
        .padding()
        .background(Color.shambaCardBackground)  // Using card background color
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct WeatherInfoItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)  // Changed to primary color
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let backgroundColor: Color
    @State private var showingMarketOverview = false
    @State private var showingCommunity = false
    @State private var showingSoilHealth = false
    @State private var showingCropAlert = false
    
    var body: some View {
        Button {
            switch title {
            case "Today's Market":
                showingMarketOverview = true
            case "Community":
                showingCommunity = true
            case "Soil Health":
                showingSoilHealth = true
            case "Crop Alert":
                showingCropAlert = true
            default:
                break
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(backgroundColor)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.shambaText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showingMarketOverview) {
            MarketOverviewView()
        }
        .sheet(isPresented: $showingCommunity) {
            CommunityView()
        }
        .sheet(isPresented: $showingSoilHealth) {
            SoilHealthView()
        }
        .sheet(isPresented: $showingCropAlert) {
            CropAlertView()
        }
    }
}

struct MarketplaceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingNewListing = false
    
    let categories = ["All", "Vegetables", "Fruits", "Cereals", "Dairy", "Other"]
    
    let sampleListings = [
        ProduceListing(
            title: "Fresh Maize",
            price: "KSh 50/kg",
            location: "Kiambu",
            image: "corn",
            category: "Cereals",
            seller: "John Doe"
        ),
        ProduceListing(
            title: "Ripe Tomatoes",
            price: "KSh 120/kg",
            location: "Nakuru",
            image: "tomato",
            category: "Vegetables",
            seller: "Jane Smith"
        ),
        // Add more sample listings
    ]
    
    var filteredListings: [ProduceListing] {
        sampleListings.filter { listing in
            let matchesSearch = searchText.isEmpty || 
                listing.title.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All" || 
                listing.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search produce...", text: $searchText)
                    }
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    withAnimation {
                                        selectedCategory = category
                                    }
                                } label: {
                                    Text(category)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == category ?
                                            Color.shambaGreen : Color.shambaCardBackground
                                        )
                                        .foregroundStyle(
                                            selectedCategory == category ?
                                            Color.white : Color.primary
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.shambaBackgroundPrimary)
                
                // Listings Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredListings) { listing in
                            ProduceCard(listing: listing)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewListing = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.shambaGreen)
                    }
                }
            }
            .sheet(isPresented: $showingNewListing) {
                NewListingView()
            }
        }
    }
}

struct ProduceListing: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let location: String
    let image: String
    let category: String
    let seller: String
}

struct ProduceCard: View {
    let listing: ProduceListing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            Image(systemName: listing.image)
                .font(.system(size: 40))
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.shambaGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                
                Text(listing.price)
                    .font(.subheadline)
                    .foregroundStyle(Color.shambaGreen)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(listing.location)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct NewListingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var price = ""
    @State private var category = "Vegetables"
    @State private var description = ""
    @State private var location = ""
    @State private var showingImagePicker = false
    
    let categories = ["Vegetables", "Fruits", "Cereals", "Dairy", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Title", text: $title)
                    TextField("Price (KSh)", text: $price)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    TextField("Location", text: $location)
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section("Photos") {
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                    }
                }
                
                Section {
                    Button("Post Listing") {
                        // Handle posting
                        dismiss()
                    }
                }
                .listRowBackground(Color.shambaGreen)
                .foregroundColor(.white)
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                // Add image picker here
            }
        }
    }
}

struct MarketInsightRow: View {
    enum Trend {
        case up, down, neutral
    }
    
    let title: String
    let value: String
    let trend: Trend
    
    var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .neutral: return "equal.circle.fill"
        }
    }
    
    var trendColor: Color {
        switch trend {
        case .up: return .shambaGreen
        case .down: return .shambaRed
        case .neutral: return .shambaBlue
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
            Image(systemName: trendIcon)
                .foregroundStyle(trendColor)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var showingMarketplace = false
    @State private var showingScanView = false
    @State private var showingGuideView = false
    
    var body: some View {
        Button(action: {
            switch title {
            case "Scan Crop":
                showingScanView = true
            case "Sell Produce":
                showingMarketplace = true
            case "Guide":
                showingGuideView = true
            default:
                action()
            }
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .sheet(isPresented: $showingMarketplace) {
            MarketplaceView()
        }
        .sheet(isPresented: $showingScanView) {
            CropScannerView()
        }
        .sheet(isPresented: $showingGuideView) {
            GuideView()
        }
    }
}

struct MarketOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    struct CropPrice {
        let name: String
        let currentPrice: Double
        let previousPrice: Double
        let unit: String
        
        var trend: MarketInsightRow.Trend {
            if currentPrice > previousPrice { return .up }
            if currentPrice < previousPrice { return .down }
            return .neutral
        }
        
        var changePercentage: Double {
            ((currentPrice - previousPrice) / previousPrice) * 100
        }
    }
    
    let prices = [
        CropPrice(name: "Maize", currentPrice: 45, previousPrice: 42, unit: "Kg"),
        CropPrice(name: "Beans", currentPrice: 120, previousPrice: 125, unit: "Kg"),
        CropPrice(name: "Potatoes", currentPrice: 35, previousPrice: 30, unit: "Kg"),
        CropPrice(name: "Wheat", currentPrice: 52, previousPrice: 52, unit: "Kg"),
        CropPrice(name: "Rice", currentPrice: 150, previousPrice: 140, unit: "Kg")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Market Summary Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Market Summary", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                            .foregroundStyle(Color.shambaGreen)
                        
                        Text("Today's Trading Activity")
                            .font(.title2.bold())
                        
                        Text("Overall market sentiment is positive with increased trading volume across major crops.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Price List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Price Updates")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        ForEach(prices, id: \.name) { crop in
                            MarketPriceCard(crop: crop)
                        }
                    }
                    
                    // Market Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Trading Tips", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(Color.shambaYellow)
                        
                        MarketTipRow(tip: "Best time to sell: Early morning markets tend to offer better prices")
                        MarketTipRow(tip: "Quality grading: Grade A produce can fetch up to 20% premium")
                        MarketTipRow(tip: "Bulk sales: Consider combining with other farmers for better negotiating power")
                    }
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.shambaBackgroundPrimary, .shambaBackgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Market Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MarketPriceCard: View {
    let crop: MarketOverviewView.CropPrice
    
    var body: some View {
        HStack(spacing: 16) {
            // Crop Icon and Name
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(Color.shambaGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.shambaGreen.opacity(0.1))
                    .clipShape(Circle())
                
                Text(crop.name)
                    .font(.headline)
            }
            
            Spacer()
            
            // Price and Trend
            VStack(alignment: .trailing) {
                Text("KES \(Int(crop.currentPrice))/\(crop.unit)")
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: crop.trend == .up ? "arrow.up.right" : 
                                    crop.trend == .down ? "arrow.down.right" : "equal")
                        .foregroundStyle(crop.trend == .up ? Color.shambaGreen :
                                       crop.trend == .down ? Color.shambaRed : Color.shambaBlue)
                    
                    Text(String(format: "%.1f%%", abs(crop.changePercentage)))
                        .font(.caption)
                        .foregroundStyle(crop.trend == .up ? Color.shambaGreen :
                                       crop.trend == .down ? Color.shambaRed : Color.shambaBlue)
                }
            }
        }
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct MarketTipRow: View {
    let tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.shambaGreen)
            
            Text(tip)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct CommunityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilter = "All Posts"
    @State private var showingNewPost = false
    
    let filters = ["All Posts", "Questions", "Tips", "Success Stories"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Community Stats
                    HStack(spacing: 20) {
                        StatCard(
                            icon: "person.2.fill",
                            value: "2,450",
                            title: "Members"
                        )
                        StatCard(
                            icon: "message.fill",
                            value: "127",
                            title: "Today's Posts"
                        )
                    }
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                FilterChip(
                                    title: filter,
                                    isSelected: filter == selectedFilter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Featured Posts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Featured Posts")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        ForEach(samplePosts) { post in
                            CommunityPostCard(post: post)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    colors: [.shambaBackgroundPrimary, .shambaBackgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search posts...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewPost = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostView()
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.shambaGreen)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.shambaGreen : Color.shambaCardBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}

struct CommunityPost: Identifiable {
    let id = UUID()
    let author: String
    let title: String
    let content: String
    let category: String
    let likes: Int
    let comments: Int
    let timeAgo: String
}

struct CommunityPostCard: View {
    let post: CommunityPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author and Category
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.shambaGreen)
                Text(post.author)
                    .font(.subheadline.bold())
                Spacer()
                Text(post.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.shambaGreen.opacity(0.1))
                    .foregroundStyle(Color.shambaGreen)
                    .clipShape(Capsule())
            }
            
            // Content
            Text(post.title)
                .font(.headline)
            Text(post.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            // Engagement Stats
            HStack {
                Label("\(post.likes)", systemImage: "heart.fill")
                    .foregroundStyle(.red)
                Label("\(post.comments)", systemImage: "message.fill")
                    .foregroundStyle(Color.shambaBlue)
                Spacer()
                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)
    }
}

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory = "Question"
    
    let categories = ["Question", "Tip", "Success Story"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(height: 150)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Post") { 
                        // Handle post submission
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// Add sample data
let samplePosts = [
    CommunityPost(
        author: "John Farmer",
        title: "Best practices for maize planting",
        content: "I've been farming maize for 10 years and wanted to share some tips that have helped me improve my yields...",
        category: "Tip",
        likes: 24,
        comments: 8,
        timeAgo: "2h ago"
    ),
    CommunityPost(
        author: "Sarah K.",
        title: "Help with tomato disease identification",
        content: "My tomato plants have developed some spots on their leaves. Can anyone help identify the issue?",
        category: "Question",
        likes: 15,
        comments: 12,
        timeAgo: "4h ago"
    ),
    CommunityPost(
        author: "Michael M.",
        title: "Doubled my potato yield!",
        content: "Using the soil management techniques from this app, I managed to double my potato yield this season...",
        category: "Success Story",
        likes: 45,
        comments: 16,
        timeAgo: "1d ago"
    )
]

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @AppStorage("selectedLanguage") private var selectedLanguage = "English" {
        didSet {
            // Update localization when language changes
            localizationManager.language = selectedLanguage == "Swahili" ? "sw" : "en"
        }
    }
    @State private var showingEditProfile = false
    @State private var showingLanguagePicker = false
    @State private var showingScanSheet = false
    @Binding var selectedTab: Int
    
    let languages = ["English", "Swahili", "Kikuyu", "Luo", "Kamba"]
    
    var firstName: String {
        if let fullName = authManager.currentUser?.name {
            return fullName.split(separator: " ").first?.description ?? fullName
        }
        return "User"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.shambaGreen)
                        
                        VStack(spacing: 4) {
                            Text(localizationManager.localizedString("Welcome Back!"))
                                .font(.title2.bold())
                            
                            if let email = authManager.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button("Edit Profile") {
                            showingEditProfile = true
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.shambaGreen)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                QuickActionButton(
                                    icon: "camera.viewfinder",
                                    title: "Scan Crop",
                                    color: .shambaGreen
                                ) {
                                    showingScanSheet = true
                                }
                                
                                QuickActionButton(
                                    icon: "leaf.arrow.circlepath",
                                    title: "Crop Health",
                                    color: .shambaBlue
                                ) {
                                    withAnimation {
                                        selectedTab = 1  // Switch to data input tab
                                    }
                                }
                                
                                QuickActionButton(
                                    icon: "chart.bar.fill",
                                    title: "Analytics",
                                    color: .shambaYellow
                                ) {
                                    // Handle analytics action
                                }
                                
                                QuickActionButton(
                                    icon: "bell.badge.fill",
                                    title: "Alerts",
                                    color: .shambaRed
                                ) {
                                    // Handle alerts action
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizationManager.localizedString("Settings"))
                            .font(.headline)
                        
                        VStack(spacing: 0) {
                            // Language Setting
                            Button {
                                showingLanguagePicker = true
                            } label: {
                                HStack {
                                    Label(localizationManager.localizedString("Language"), systemImage: "globe")
                                    Spacer()
                                    Text(selectedLanguage)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                            
                            Divider()
                                .padding(.horizontal)
                            
                            // Notifications Setting
                            NavigationLink {
                                Text("Notifications Settings")
                            } label: {
                                Label(localizationManager.localizedString("Notifications"), systemImage: "bell")
                                    .padding()
                            }
                            
                            Divider()
                                .padding(.horizontal)
                            
                            // Privacy Setting
                            NavigationLink {
                                Text("Privacy Settings")
                            } label: {
                                Label(localizationManager.localizedString("Privacy"), systemImage: "lock")
                                    .padding()
                            }
                        }
                        .background(Color.shambaCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.shambaBackgroundPrimary, .shambaBackgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle(localizationManager.localizedString("Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            selectedTab = 0
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Home")
                        }
                        .foregroundStyle(Color.shambaGreen)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        withAnimation(.spring()) {
                            authManager.signOut()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingLanguagePicker) {
                LanguagePickerView(
                    selectedLanguage: $selectedLanguage,
                    languages: languages,
                    isPresented: $showingLanguagePicker
                )
            }
        }
        .sheet(isPresented: $showingScanSheet) {
            CropScannerView()
        }
    }
}

struct ProfileHeaderView: View {
    @Binding var showingEditProfile: Bool
    let name: String
    let email: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.shambaGreen)
            
            VStack(spacing: 4) {
                Text(name)
                    .font(.title2.bold())
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button("Edit Profile") {
                showingEditProfile = true
            }
            .buttonStyle(.bordered)
            .tint(.shambaGreen)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsSectionView: View {
    @Binding var selectedLanguage: String
    @Binding var showingLanguagePicker: Bool
    let languages: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "globe",
                    title: "Language",
                    value: selectedLanguage,
                    action: { showingLanguagePicker = true }
                )
                
                Divider().padding(.horizontal)
                
                NavigationLink {
                    Text("Notifications Settings")
                } label: {
                    Label("Notifications", systemImage: "bell")
                        .padding()
                }
                
                Divider().padding(.horizontal)
                
                NavigationLink {
                    Text("Help & Support")
                } label: {
                    Label("Help & Support", systemImage: "questionmark.circle")
                        .padding()
                }
            }
            .background(Color.shambaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .foregroundStyle(.primary)
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var location: String = ""
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Location", text: $location)
                }
                
                Section("Account") {
                    LabeledContent("Email", value: authManager.currentUser?.email ?? "")
                }
                
                Section {
                    Button("Save Changes") {
                        showingSaveAlert = true
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.shambaGreen)
                .foregroundColor(.white)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = authManager.currentUser?.name ?? ""
            }
            .alert("Profile Updated", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your profile has been updated successfully.")
            }
        }
    }
}

struct AppInfoView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("ShambaGo")
                .font(.headline)
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    let languages: [String]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(languages, id: \.self) { language in
                    Button {
                        selectedLanguage = language
                        isPresented = false
                    } label: {
                        HStack {
                            Text(language)
                            Spacer()
                            if language == selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.shambaGreen)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct SoilHealthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var soilMoisture = 65.0
    @State private var soilPH = 6.8
    @State private var nitrogenLevel = 75.0
    @State private var lastUpdated = Date()
    @State private var showingAddReadingSheet = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Soil Health Status")
                                    .font(.headline)
                                Text("Last updated: \(dateFormatter.string(from: lastUpdated))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(action: { showingAddReadingSheet = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.shambaGreen)
                            }
                        }
                        
                        // Soil Health Metrics
                        HStack(spacing: 20) {
                            SoilMetricCard(
                                icon: "drop.fill",
                                title: "Moisture",
                                value: soilMoisture,
                                unit: "%",
                                color: .blue
                            )
                            
                            SoilMetricCard(
                                icon: "leaf.fill",
                                title: "pH Level",
                                value: soilPH,
                                unit: "pH",
                                color: .green
                            )
                            
                            SoilMetricCard(
                                icon: "n.circle.fill",
                                title: "Nitrogen",
                                value: nitrogenLevel,
                                unit: "mg/kg",
                                color: .purple
                            )
                        }
                    }
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        RecommendationCard(
                            title: "Moisture Management",
                            description: "Soil moisture is optimal. Continue current irrigation schedule.",
                            icon: "drop.fill",
                            color: .blue
                        )
                        
                        RecommendationCard(
                            title: "pH Balance",
                            description: "pH levels are slightly acidic. Consider adding lime to raise pH.",
                            icon: "leaf.fill",
                            color: .green
                        )
                        
                        RecommendationCard(
                            title: "Nitrogen Levels",
                            description: "Nitrogen levels are good. Plan next fertilizer application in 2 weeks.",
                            icon: "n.circle.fill",
                            color: .purple
                        )
                    }
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.shambaBackgroundPrimary, .shambaBackgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Soil Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddReadingSheet) {
                AddSoilReadingView(
                    soilMoisture: $soilMoisture,
                    soilPH: $soilPH,
                    nitrogenLevel: $nitrogenLevel,
                    lastUpdated: $lastUpdated
                )
            }
        }
    }
}

struct SoilMetricCard: View {
    let icon: String
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(value, specifier: "%.1f")\(unit)")
                    .font(.title3.bold())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RecommendationCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.shambaCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct AddSoilReadingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var soilMoisture: Double
    @Binding var soilPH: Double
    @Binding var nitrogenLevel: Double
    @Binding var lastUpdated: Date
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Soil Measurements") {
                    VStack(alignment: .leading) {
                        Text("Soil Moisture (%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Slider(value: $soilMoisture, in: 0...100)
                            Text("\(soilMoisture, specifier: "%.1f")%")
                                .monospacedDigit()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("pH Level")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Slider(value: $soilPH, in: 0...14)
                            Text("\(soilPH, specifier: "%.1f")")
                                .monospacedDigit()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Nitrogen Level (mg/kg)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Slider(value: $nitrogenLevel, in: 0...100)
                            Text("\(nitrogenLevel, specifier: "%.1f")")
                                .monospacedDigit()
                        }
                    }
                }
                
                Section {
                    Button("Save Reading") {
                        lastUpdated = Date()
                        dismiss()
                    }
                }
                .listRowBackground(Color.shambaGreen)
                .foregroundColor(.white)
            }
            .navigationTitle("Add Soil Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CropAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter = "Active"
    @State private var showingNewAlertSheet = false
    
    let filters = ["Active", "Resolved", "All"]
    
    // Sample alerts - in a real app, these would come from a database
    let alerts = [
        CropAlert(
            type: .pest,
            severity: .high,
            description: "Fall Armyworm detected in Maize field",
            location: "Field A",
            dateDetected: Date().addingTimeInterval(-3600 * 2),
            status: .active,
            recommendedAction: "Apply approved pesticide. Inspect neighboring plants."
        ),
        CropAlert(
            type: .disease,
            severity: .medium,
            description: "Early signs of leaf blight in potato crops",
            location: "Field B",
            dateDetected: Date().addingTimeInterval(-3600 * 24),
            status: .active,
            recommendedAction: "Remove affected leaves. Apply fungicide treatment."
        ),
        CropAlert(
            type: .nutrient,
            severity: .low,
            description: "Nitrogen deficiency symptoms in beans",
            location: "Field C",
            dateDetected: Date().addingTimeInterval(-3600 * 48),
            status: .resolved,
            recommendedAction: "Apply nitrogen-rich fertilizer. Monitor leaf color."
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Alert Summary
                    HStack(spacing: 16) {
                        AlertStatCard(
                            count: alerts.filter { $0.severity == .high }.count,
                            title: "High Priority",
                            color: .shambaRed
                        )
                        AlertStatCard(
                            count: alerts.filter { $0.severity == .medium }.count,
                            title: "Medium",
                            color: .shambaYellow
                        )
                        AlertStatCard(
                            count: alerts.filter { $0.severity == .low }.count,
                            title: "Low",
                            color: .shambaGreen
                        )
                    }
                    .padding(.horizontal)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                FilterPill(
                                    title: filter,
                                    isSelected: filter == selectedFilter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Alert List
                    VStack(spacing: 16) {
                        ForEach(filteredAlerts) { alert in
                            AlertCard(alert: alert)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    colors: [.shambaBackgroundPrimary, .shambaBackgroundSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Crop Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewAlertSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.shambaGreen)
                    }
                }
            }
            .sheet(isPresented: $showingNewAlertSheet) {
                NewAlertView()
            }
        }
    }
    
    var filteredAlerts: [CropAlert] {
        switch selectedFilter {
        case "Active":
            return alerts.filter { $0.status == .active }
        case "Resolved":
            return alerts.filter { $0.status == .resolved }
        default:
            return alerts
        }
    }
}

struct AlertStatCard: View {
    let count: Int
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.shambaGreen : Color.shambaCardBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct AlertCard: View {
    let alert: CropAlert
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: alert.type.icon)
                    .font(.title2)
                    .foregroundStyle(alert.severity.color)
                
                VStack(alignment: .leading) {
                    Text(alert.description)
                        .font(.headline)
                    Text(alert.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                SeverityBadge(severity: alert.severity)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Recommended Action", systemImage: "checkmark.circle")
                    .font(.subheadline.bold())
                
                Text(alert.recommendedAction)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label(dateFormatter.string(from: alert.dateDetected), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if alert.status == .active {
                    Button("Mark Resolved") {
                        // Handle resolution
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.shambaGreen)
                }
            }
        }
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SeverityBadge: View {
    let severity: CropAlert.Severity
    
    var body: some View {
        Text(severity.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severity.color.opacity(0.1))
            .foregroundStyle(severity.color)
            .clipShape(Capsule())
    }
}

// Models
struct CropAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let severity: Severity
    let description: String
    let location: String
    let dateDetected: Date
    var status: Status
    let recommendedAction: String
    
    enum AlertType {
        case pest, disease, nutrient
        
        var icon: String {
            switch self {
            case .pest: return "ladybug.fill"
            case .disease: return "leaf.fill"
            case .nutrient: return "drop.fill"
            }
        }
    }
    
    enum Severity: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var color: Color {
            switch self {
            case .high: return .shambaRed
            case .medium: return .shambaYellow
            case .low: return .shambaGreen
            }
        }
    }
    
    enum Status {
        case active, resolved
    }
}

struct NewAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var location = ""
    @State private var selectedType: CropAlert.AlertType = .pest
    @State private var selectedSeverity: CropAlert.Severity = .medium
    @State private var recommendedAction = ""
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Alert Details") {
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                    
                    Picker("Type", selection: $selectedType) {
                        Text("Pest").tag(CropAlert.AlertType.pest)
                        Text("Disease").tag(CropAlert.AlertType.disease)
                        Text("Nutrient").tag(CropAlert.AlertType.nutrient)
                    }
                    
                    Picker("Severity", selection: $selectedSeverity) {
                        Text("High").tag(CropAlert.Severity.high)
                        Text("Medium").tag(CropAlert.Severity.medium)
                        Text("Low").tag(CropAlert.Severity.low)
                    }
                }
                
                Section("Recommended Action") {
                    TextEditor(text: $recommendedAction)
                        .frame(height: 100)
                }
                
                Section {
                    Button("Save Alert") {
                        // Here you would typically save the alert
                        showingSaveAlert = true
                    }
                }
                .listRowBackground(Color.shambaGreen)
                .foregroundColor(.white)
            }
            .navigationTitle("New Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Alert Created", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your crop alert has been created successfully.")
            }
        }
    }
}

struct AppHeader: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Binding var selectedTab: Int
    
    var displayName: String {
        if let name = authManager.currentUser?.name {
            return name.split(separator: " ").first?.description ?? name
        }
        return "Guest"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Logo, App Name, and Profile
            HStack(spacing: 12) {
                // Logo and App Name
                HStack(spacing: 12) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.shambaGreen)
                        .symbolEffect(.bounce, options: .repeating)
                    
                    Text("ShambaGo")
                        .font(.title3.bold())
                }
                
                Spacer()
                
                // Updated Profile Section with navigation
                Button {
                    withAnimation {
                        selectedTab = 2
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.shambaGreen)
                            .overlay(
                                Circle()
                                    .stroke(Color.shambaGreen.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.shambaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Quick Stats
            HStack(spacing: 20) {
                StatisticView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Yield",
                    value: "+15%",
                    color: .shambaGreen
                )
                
                StatisticView(
                    icon: "cloud.sun.fill",
                    title: "Weather",
                    value: "24°C",
                    color: .shambaBlue
                )
                
                StatisticView(
                    icon: "drop.fill",
                    title: "Soil",
                    value: "Good",
                    color: .shambaYellow
                )
            }
        }
        .padding()
    }
}

struct AppFooter: View {
    @Environment(\.openURL) private var openURL
    @State private var showingHelpSheet = false
    @State private var showingContactSheet = false
    @State private var showingAboutSheet = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Quick Actions Grid
            Grid(horizontalSpacing: 24, verticalSpacing: 24) {
                GridRow {
                    FooterActionButton(
                        icon: "questionmark.circle.fill",
                        title: "Help Center",
                        subtitle: "Get support",
                        color: .shambaBlue
                    ) {
                        showingHelpSheet = true
                    }
                    
                    FooterActionButton(
                        icon: "envelope.fill",
                        title: "Contact Us",
                        subtitle: "Send message",
                        color: .shambaGreen
                    ) {
                        showingContactSheet = true
                    }
                }
                
                GridRow {
                    FooterActionButton(
                        icon: "leaf.circle.fill",
                        title: "About Us",
                        subtitle: "Our mission",
                        color: .shambaYellow
                    ) {
                        showingAboutSheet = true
                    }
                    
                    FooterActionButton(
                        icon: "star.fill",
                        title: "Rate App",
                        subtitle: "Share feedback",
                        color: .shambaRed
                    ) {
                        // Open App Store rating
                        openURL(URL(string: "https://apps.apple.com/app/id123456789?action=write-review")!)
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
            
            // Social Links
            VStack(spacing: 16) {
                Text("Connect With Us")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 24) {
                    SocialLink(icon: "twitter", url: "https://twitter.com/shambago")
                    SocialLink(icon: "facebook", url: "https://facebook.com/shambago")
                    SocialLink(icon: "instagram", url: "https://instagram.com/shambago")
                    SocialLink(icon: "youtube", url: "https://youtube.com/shambago")
                }
            }
            
            // App Info
            VStack(spacing: 8) {
                Text("ShambaGo v1.0.0")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Text("© 2024 ShambaGo. All rights reserved.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("Made with ♥️ in Kenya")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom)
        }
        .padding(.top)
        .background(Color.shambaCardBackground)
        .sheet(isPresented: $showingHelpSheet) {
            HelpCenterView()
        }
        .sheet(isPresented: $showingContactSheet) {
            ContactView()
        }
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
    }
}

struct FooterActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct SocialLink: View {
    let icon: String
    let url: String
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button {
            openURL(URL(string: url)!)
        } label: {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

struct StatisticView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    
    let helpCategories = [
        HelpCategory(
            title: "Getting Started",
            icon: "leaf.circle",
            color: .shambaGreen,
            topics: [
                "Account Setup",
                "Basic Navigation",
                "Profile Settings",
                "App Features Overview"
            ]
        ),
        HelpCategory(
            title: "Crop Management",
            icon: "leaf",
            color: .green,
            topics: [
                "Adding New Crops",
                "Monitoring Growth",
                "Disease Detection",
                "Harvest Planning"
            ]
        ),
        HelpCategory(
            title: "Market Features",
            icon: "cart",
            color: .shambaYellow,
            topics: [
                "Creating Listings",
                "Price Guidelines",
                "Buyer Communication",
                "Payment Process"
            ]
        ),
        HelpCategory(
            title: "Weather & Alerts",
            icon: "cloud.sun",
            color: .shambaBlue,
            topics: [
                "Weather Notifications",
                "Alert Settings",
                "Emergency Updates",
                "Seasonal Forecasts"
            ]
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search help topics...", text: $searchQuery)
                        
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Quick Help Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            QuickHelpButton(
                                title: "Chat Support",
                                icon: "message.fill",
                                color: .shambaGreen
                            ) {
                                // Handle chat support
                            }
                            
                            QuickHelpButton(
                                title: "Video Guides",
                                icon: "play.circle.fill",
                                color: .shambaBlue
                            ) {
                                // Handle video guides
                            }
                            
                            QuickHelpButton(
                                title: "FAQs",
                                icon: "questionmark.circle.fill",
                                color: .shambaYellow
                            ) {
                                // Handle FAQs
                            }
                        }
                    }
                    
                    // Help Categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Help Topics")
                            .font(.headline)
                        
                        ForEach(helpCategories) { category in
                            NavigationLink(destination: HelpCategoryDetail(category: category)) {
                                HelpCategoryRow(category: category)
                            }
                        }
                    }
                    
                    // Contact Support
                    VStack(spacing: 16) {
                        Text("Still need help?")
                            .font(.headline)
                        
                        Button {
                            // Handle contact support
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Contact Support Team")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.shambaGreen)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Help Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let topics: [String]
}

struct HelpCategoryRow: View {
    let category: HelpCategory
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(category.color)
                .frame(width: 40, height: 40)
                .background(category.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.headline)
                Text("\(category.topics.count) topics")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HelpCategoryDetail: View {
    let category: HelpCategory
    
    var body: some View {
        List {
            ForEach(category.topics, id: \.self) { topic in
                NavigationLink {
                    TopicDetailView(topic: topic)
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(category.color)
                        Text(topic)
                    }
                }
            }
        }
        .navigationTitle(category.title)
    }
}

struct TopicDetailView: View {
    let topic: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About \(topic)")
                    .font(.headline)
                
                Text("Detailed information about \(topic) will be displayed here.")
                    .foregroundStyle(.secondary)
                
                // Add more content specific to each topic
            }
            .padding()
        }
        .navigationTitle(topic)
    }
}

struct QuickHelpButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.shambaCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ContactView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var showingSentAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Message Details") {
                    TextField("Subject", text: $subject)
                    
                    TextEditor(text: $message)
                        .frame(height: 150)
                }
                
                Section {
                    Button("Send Message") {
                        showingSentAlert = true
                    }
                }
                .listRowBackground(Color.shambaGreen)
                .foregroundColor(.white)
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
            }
            }
            .alert("Message Sent", isPresented: $showingSentAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Thank you for your message. We'll get back to you soon.")
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App Logo and Version
                    VStack(spacing: 16) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.shambaGreen)
                        
                        VStack(spacing: 4) {
                            Text("ShambaGo")
                                .font(.title.bold())
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Mission Statement
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Our Mission")
                            .font(.headline)
                        
                        Text("Empowering farmers with smart technology for sustainable agriculture and improved yields.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "leaf.circle", title: "Smart Farming")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Market Insights")
                            FeatureRow(icon: "cloud.sun", title: "Weather Alerts")
                            FeatureRow(icon: "person.2", title: "Community Support")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        Label {
            Text(title)
                .font(.subheadline)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Color.shambaGreen)
        }
    }
}

struct CropScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var scannedImage: UIImage?
    @State private var analysisResult: String?
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = scannedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                    
                    if isAnalyzing {
                        ProgressView("Analyzing crop...")
                    } else if let result = analysisResult {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Analysis Result")
                                .font(.headline)
                            
                            Text(result)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.shambaCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.shambaGreen)
                        
                        Text("Scan your crop for instant analysis")
                            .font(.headline)
                        
                        Text("Point your camera at the crop to identify issues and get recommendations")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingCamera = true
                        }) {
                            Text("Start Scanning")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.shambaGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("Crop Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if scannedImage != nil {
                        Button("New Scan") {
                            showingCamera = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $scannedImage)
            }
            .onChange(of: scannedImage) { _ in
                if scannedImage != nil {
                    analyzeImage()
                }
            }
        }
    }
    
    private func analyzeImage() {
        guard scannedImage != nil else { return }
        isAnalyzing = true
        
        // Simulate analysis delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            analysisResult = """
                Crop Type: Maize
                Health Status: Good
                Potential Issues:
                - Minor leaf spots detected
                - Early signs of nitrogen deficiency
                
                Recommendations:
                1. Monitor leaf spots for spread
                2. Consider applying nitrogen-rich fertilizer
                3. Maintain current watering schedule
                """
            isAnalyzing = false
        }
    }
}

// Add ImagePicker for camera access
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Add GuideView
struct GuideView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Featured Guides
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Featured Guides")
                            .font(.title3.bold())
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                FeaturedGuideCard(
                                    title: "Crop Rotation",
                                    description: "Learn the best practices for crop rotation",
                                    icon: "leaf.circle.fill"
                                )
                                
                                FeaturedGuideCard(
                                    title: "Pest Control",
                                    description: "Natural ways to protect your crops",
                                    icon: "ladybug.fill"
                                )
                                
                                FeaturedGuideCard(
                                    title: "Water Management",
                                    description: "Efficient irrigation techniques",
                                    icon: "drop.fill"
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quick Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Tips")
                            .font(.title3.bold())
                        
                        ForEach(1...5, id: \.self) { index in
                            TipRow(
                                tip: "Farming Tip \(index)",
                                description: "Quick tip description goes here"
                            )
                        }
                    }
                    .padding()
                    .background(Color.shambaCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Farming Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeaturedGuideCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.shambaGreen)
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(width: 160)
        .padding()
        .background(Color.shambaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TipRow: View {
    let tip: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tip)
                .font(.subheadline.bold())
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ChatSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isTyping = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome Message
                            ChatBubble(
                                message: ChatMessage(
                                    text: "Hello! I'm your ShambaGo assistant. How can I help you today?",
                                    isUser: false,
                                    timestamp: Date()
                                )
                            )
                            
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                            
                            if isTyping {
                                HStack {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(Color.shambaGreen)
                                            .frame(width: 8, height: 8)
                                            .opacity(0.5)
                                            .animation(
                                                .easeInOut(duration: 0.5).repeatForever(),
                                                value: isTyping
                                            )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                // Message Input
                HStack(spacing: 12) {
                    TextField("Type your message...", text: $newMessage)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.shambaGreen)
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Chat Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let userMessage = ChatMessage(
            text: newMessage,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        newMessage = ""
        
        // Simulate AI typing
        isTyping = true
        
        // Generate AI response after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = generateAIResponse(to: userMessage.text)
            isTyping = false
            messages.append(ChatMessage(
                text: response,
                isUser: false,
                timestamp: Date()
            ))
        }
    }
    
    private func generateAIResponse(to message: String) -> String {
        // Simulate AI responses based on keywords
        let lowercased = message.lowercased()
        
        if lowercased.contains("hello") || lowercased.contains("hi") {
            return "Hello! How can I assist you with your farming needs today?"
        }
        
        if lowercased.contains("weather") {
            return "I can help you check weather conditions and set up alerts. What specific information would you like to know?"
        }
        
        if lowercased.contains("crop") || lowercased.contains("plant") {
            return "I can provide information about crop management, disease detection, and growing tips. What would you like to learn more about?"
        }
        
        if lowercased.contains("market") || lowercased.contains("price") {
            return "I can help you check current market prices and connect with buyers. Would you like to see the latest market trends?"
        }
        
        if lowercased.contains("soil") {
            return "I can help you monitor soil health and provide recommendations for improvement. Would you like to check your soil analysis?"
        }
        
        // Default response
        return "I understand you're asking about '\(message)'. Could you please provide more details so I can better assist you?"
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(message.isUser ? Color.shambaGreen : Color.shambaCardBackground)
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}

// Also add previews for individual components for better development
#Preview("Authentication View") {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}

#Preview("Home View") {
    HomeView(selectedTab: .constant(0))
}

#Preview("Profile View") {
    ProfileView(selectedTab: .constant(2))
        .environmentObject(AuthenticationManager())
}

#Preview("Market Overview") {
    MarketOverviewView()
}

#Preview("Community View") {
    CommunityView()
}

#Preview("Soil Health") {
    SoilHealthView()
}

#Preview("Crop Alerts") {
    CropAlertView()
}

#Preview("New Alert") {
    NewAlertView()
}

#Preview("Help Center") {
    HelpCenterView()
}

#Preview("Contact") {
    ContactView()
}

#Preview("About") {
    AboutView()
}

//
//  LoginView.swift
//  QuickkSynkk
//
//  Created by VED PATEL on 06/09/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showPassword = false
    @State private var keyboardHeight: CGFloat = 0
    
    @StateObject private var firebaseManager = FirebaseManager.shared
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, email, password
    }
    
    var body: some View {
        ZStack {
            // Animated Background
            AnimatedBackgroundView()
            
            // Scrollable Content
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top spacing
                        Spacer()
                            .frame(height: max(60, geometry.safeAreaInsets.top + 20))
                        
                        // Logo Section
                        logoSection
                            .padding(.bottom, 40)
                        
                        // Auth Card
                        authCard
                            .padding(.horizontal, 20)
                        
                        // Footer
                        footerSection
                            .padding(.top, 40)
                            .padding(.bottom, max(30, keyboardHeight > 0 ? 20 : 30))
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
        }
        .ignoresSafeArea(.all)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                keyboardHeight = keyboardFrame.cgRectValue.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    var logoSection: some View {
        VStack(spacing: 24) {
            // App Logo with Animation
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                Image("logoooo")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .black, radius: 20, x: 0, y: 10)
            
            // App Title
            VStack(spacing: 8) {
                Text("QuickSync")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black, radius: 2, x: 0, y: 2)
                
                Text("Find Your Perfect Collaborators")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    var authCard: some View {
        VStack(spacing: 32) {
            // Toggle Buttons
            toggleSection
            
            // Input Fields
            inputFieldsSection
            
            // Main Action Button
            mainActionButton
            
            // Or Divider
            orDivider
            
            // Social Login
            socialLoginSection
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black, radius: 30, x: 0, y: 15)
    }
    
    var toggleSection: some View {
        HStack(spacing: 0) {
            ToggleButton(
                title: "Sign Up",
                isSelected: isSignUp,
                action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isSignUp = true
                        clearFields()
                    }
                }
            )
            
            ToggleButton(
                title: "Log In",
                isSelected: !isSignUp,
                action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isSignUp = false
                        clearFields()
                    }
                }
            )
        }
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 27)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 27)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    var inputFieldsSection: some View {
        VStack(spacing: 20) {
            // Name field (Sign Up only)
            if isSignUp {
                ModernTextField(
                    placeholder: "Full Name",
                    text: $name,
                    icon: "person.fill",
                    isSecure: false,
                    focusedField: $focusedField,
                    fieldType: .name
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Email field
            ModernTextField(
                placeholder: isSignUp ? "Your E-mail Address" : "abc@gmail.com",
                text: $email,
                icon: "envelope.fill",
                isSecure: false,
                keyboardType: .emailAddress,
                focusedField: $focusedField,
                fieldType: .email
            )
            
            // Password field
            ModernTextField(
                placeholder: isSignUp ? "Create Password" : "xyz123",
                text: $password,
                icon: "lock.fill",
                isSecure: !showPassword,
                showPasswordToggle: true,
                showPassword: $showPassword,
                focusedField: $focusedField,
                fieldType: .password
            )
            
            // Error Message
            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    var mainActionButton: some View {
        Button(action: handleAuthentication) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Image(systemName: isSignUp ? "person.badge.plus.fill" : "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
                
                Text(isLoading ? "Please wait..." : (isSignUp ? "CREATE ACCOUNT" : "SIGN IN"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appAccent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.appAccent, radius: 15, x: 0, y: 8)
            )
            .scaleEffect(isFormValid ? 1.0 : 0.95)
            .animation(.spring(response: 0.3), value: isFormValid)
        }
        .disabled(!isFormValid || isLoading)
    }
    
    var orDivider: some View {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
            
            Text("or")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    var socialLoginSection: some View {
        VStack(spacing: 16) {
            Text("Or Sign Up With")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 20) {
                SocialLoginButton(
                    icon: "globe",
                    title: "Google",
                    color: .orange,
                    action: handleGoogleSignIn
                )
                
                SocialLoginButton(
                    icon: "applelogo",
                    title: "Apple",
                    color: .white,
                    action: handleAppleSignIn
                )
            }
        }
    }
    
    var footerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                FooterLink(text: "Terms of use")
                Text("•").foregroundColor(.white.opacity(0.6))
                FooterLink(text: "Privacy")
                Text("•").foregroundColor(.white.opacity(0.6))
                FooterLink(text: "Contact")
            }
            
            Text("Made with ❤️ for collaborative innovation")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        let nameValid = isSignUp ? !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : true
        
        return emailValid && passwordValid && nameValid
    }
    
    func clearFields() {
        errorMessage = ""
        focusedField = nil
    }
    
    func hideKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func handleAuthentication() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        hideKeyboard()
        
        if isSignUp {
            firebaseManager.signUp(email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                 password: password,
                                 name: name.trimmingCharacters(in: .whitespacesAndNewlines)) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        self.errorMessage = self.friendlyErrorMessage(error)
                        self.showError = true
                    }
                }
            }
        } else {
            firebaseManager.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                 password: password) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        self.errorMessage = self.friendlyErrorMessage(error)
                        self.showError = true
                    }
                }
            }
        }
    }
    
    func handleGoogleSignIn() {
        errorMessage = "Google Sign-In coming soon! 🚀"
        showError = true
    }
    
    func handleAppleSignIn() {
        errorMessage = "Apple Sign-In coming soon! 🍎"
        showError = true
    }
    
    func friendlyErrorMessage(_ error: Error) -> String {
        let errorCode = (error as NSError).code
        switch errorCode {
        case 17007: return "This email is already registered. Try signing in instead."
        case 17008: return "Invalid email format. Please check your email."
        case 17009: return "Incorrect password. Please try again."
        case 17011: return "No account found with this email."
        case 17026: return "Password should be at least 6 characters."
        default: return "Something went wrong. Please try again."
        }
    }
}

// MARK: - Supporting Views

struct ToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(isSelected ? Color.appAccent : Color.clear)
                        .shadow(color: isSelected ? Color.appAccent.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                )
        }
        .padding(2)
    }
}

struct ModernTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var showPasswordToggle: Bool = false
    @Binding var showPassword: Bool
    @FocusState.Binding var focusedField: LoginView.Field?
    let fieldType: LoginView.Field
    
    init(placeholder: String, text: Binding<String>, icon: String, isSecure: Bool = false, keyboardType: UIKeyboardType = .default, showPasswordToggle: Bool = false, showPassword: Binding<Bool> = .constant(false), focusedField: FocusState<LoginView.Field?>.Binding, fieldType: LoginView.Field) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.showPasswordToggle = showPasswordToggle
        self._showPassword = showPassword
        self._focusedField = focusedField
        self.fieldType = fieldType
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($focusedField, equals: fieldType)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                        .focused($focusedField, equals: fieldType)
                }
            }
            .foregroundColor(.white)
            .font(.system(size: 16))
            .disableAutocorrection(true)
            .submitLabel(fieldType == .password ? .done : .next)
            .onSubmit {
                switch fieldType {
                case .name:
                    focusedField = .email
                case .email:
                    focusedField = .password
                case .password:
                    focusedField = nil
                }
            }
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 16))
            }
            
            if showPasswordToggle {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: focusedField == fieldType ?
                                    [.white, .white.opacity(0.8)] :
                                    [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: focusedField == fieldType ? 2 : 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: focusedField == fieldType)
    }
}

struct SocialLoginButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct FooterLink: View {
    let text: String
    
    var body: some View {
        Button(text) {
            // Handle footer links
        }
        .font(.system(size: 12))
        .foregroundColor(.white.opacity(0.8))
    }
}

struct AnimatedBackgroundView: View {
    @State private var animate = false
    @State private var animate2 = false
    @State private var animate3 = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.3, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated orbs
            ForEach(0..<6) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: CGFloat.random(in: 100...300))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(animate ? 1.5 : 0.5)
                    .opacity(animate2 ? 0.8 : 0.3)
                    .rotationEffect(.degrees(animate3 ? 360 : 0))
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 4...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.5),
                        value: animate
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                        value: animate2
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 10...20))
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.2),
                        value: animate3
                    )
            }
        }
        .onAppear {
            animate = true
            animate2 = true
            animate3 = true
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
}

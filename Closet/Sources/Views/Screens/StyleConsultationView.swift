import SwiftUI

struct StyleConsultationView: View {
    @State private var email = ""
    @State private var showConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection

                    featuresSection

                    waitlistSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Style Consultation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
            .alert("You're on the list!", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("We'll reach out when style consultations become available.")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#B8A898").opacity(0.2), Color(hex: "#D4C5B5").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "#B8A898"))
            }

            Text("Expert Style Guidance")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("Coming Soon")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(hex: "#B8A898"))
                .clipShape(Capsule())

            Text("Connect with certified personal stylists who understand your wardrobe, your style, and your goals.")
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 10)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 12) {
            Text("What to Expect")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            FeatureRow(
                icon: "browse",
                title: "Personalized Lookbooks",
                description: "Seasonal collections curated for your style"
            )

            FeatureRow(
                icon: "tshirt",
                title: "Outfit Recommendations",
                description: "AI-assisted outfit suggestions reviewed by stylists"
            )

            FeatureRow(
                icon: "cart",
                title: "Shopping Guidance",
                description: "Know exactly what to buy — and what to skip"
            )

            FeatureRow(
                icon: "message",
                title: "Direct stylist chat",
                description: "Ongoing style conversations, not one-time advice"
            )
        }
        .padding(16)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var waitlistSection: some View {
        VStack(spacing: 16) {
            Text("Join the Waitlist")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("Be the first to know when consultations launch")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))

            HStack(spacing: 8) {
                TextField("your@email.com", text: $email)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color(hex: "#FFFFFF"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                    }
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                Button {
                    showConfirmation = true
                } label: {
                    Text("Join")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(email.isEmpty ? Color(hex: "#E8E8E6") : Color(hex: "#1C1C1E"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(email.isEmpty || !email.contains("@"))
            }

            Text("No spam. Unsubscribe anytime.")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#6E6E73"))
        }
        .padding(16)
        .background(Color(hex: "#FAFAF8"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#B8A898").opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#B8A898"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            }

            Spacer()
        }
    }
}

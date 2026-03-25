import SwiftUI

struct GiftView: View {
    @State private var selectedItem: ClothingItem?
    @State private var recipientName = ""
    @State private var giftMessage = ""
    @State private var giftCode: String?
    @State private var showShareSheet = false
    @State private var showConfirmation = false
    @Environment(\.dismiss) private var dismiss

    let item: ClothingItem?
    let onSend: (String, String, String?) async -> String?

    init(item: ClothingItem? = nil, onSend: @escaping (String, String, String?) async -> String? = { _, _, _ in nil }) {
        self.item = item
        self.onSend = onSend
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if let item = item {
                        itemPreviewSection(item: item)
                    }

                    giftFormSection

                    if let code = giftCode {
                        giftCodeSection(code: code)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Gift Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
            .alert("Gift Sent!", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your gift code has been generated and is ready to share.")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#B8A898").opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "gift.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "#B8A898"))
            }

            Text("Share the Love")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("Gift a wardrobe item to a friend with a unique code they can redeem.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private func itemPreviewSection(item: ClothingItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gifting")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#6E6E73"))

            HStack(spacing: 12) {
                ItemThumbnail(item: item)
                    .frame(width: 64, height: 80)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))

                    Text(item.category.rawValue)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    HStack(spacing: 4) {
                        ForEach(item.dominantColors.prefix(3), id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 16, height: 16)
                                .overlay {
                                    Circle()
                                        .stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                                }
                        }
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(Color(hex: "#FFFFFF"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var giftFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gift Details")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#6E6E73"))

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recipient's Name")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    TextField("Enter name", text: $recipientName)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Color(hex: "#FFFFFF"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Personal Message (optional)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    TextEditor(text: $giftMessage)
                        .font(.system(size: 15))
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(hex: "#FFFFFF"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                        }
                }
            }

            Button {
                Task {
                    if let code = await onSend(recipientName, giftMessage, item?.id.uuidString) {
                        giftCode = code
                        showConfirmation = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "gift.fill")
                    Text("Generate Gift Code")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(recipientName.isEmpty ? Color(hex: "#E8E8E6") : Color(hex: "#1C1C1E"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(recipientName.isEmpty)
        }
    }

    private func giftCodeSection(code: String) -> some View {
        VStack(spacing: 12) {
            Text("Your Gift Code")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#6E6E73"))

            Text(code)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#B8A898"), lineWidth: 2)
                }

            Text("Valid for 30 days. Share this code with \(recipientName) so they can redeem it.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)

            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Code")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#FAFAF8"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ItemThumbnail: View {
    let item: ClothingItem
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(hex: "#E8E8E6"))
                    .overlay {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
            }
        }
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}

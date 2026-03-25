import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ExportView: View {
    let items: [ClothingItem]
    let outfits: [Outfit]
    let styleProfile: StyleProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportService.ExportFormat = .json
    @State private var isExporting = false
    @State private var exportedData: Data?
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    formatSection

                    summarySection

                    exportButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Export Wardrobe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = exportedData {
                    ShareSheetView(data: data, filename: ExportService.shared.getExportFileName(format: selectedFormat))
                }
            }
            .alert("Export Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#B8A898").opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "#B8A898"))
            }

            Text("Export Your Wardrobe")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("Download your wardrobe data in your preferred format for backup or analysis.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)
        }
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#6E6E73"))

            VStack(spacing: 8) {
                FormatOption(
                    title: "JSON",
                    description: "Full data export — items, outfits, colors, tags, style profile",
                    icon: "curlybraces",
                    isSelected: selectedFormat == .json
                ) {
                    selectedFormat = .json
                }

                FormatOption(
                    title: "CSV",
                    description: "Spreadsheet-compatible — items and outfits in tabular format",
                    icon: "tablecells",
                    isSelected: selectedFormat == .csv
                ) {
                    selectedFormat = .csv
                }

                FormatOption(
                    title: "PDF (Coming Soon)",
                    description: "Beautiful printable wardrobe report",
                    icon: "doc.richtext",
                    isSelected: selectedFormat == .pdf
                ) {
                    // Not available yet
                }
                .opacity(0.5)
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's Included")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#6E6E73"))

            VStack(spacing: 8) {
                SummaryRow(label: "Clothing Items", value: "\(items.count)")
                SummaryRow(label: "Saved Outfits", value: "\(outfits.count)")
                SummaryRow(label: "Style Profile", value: styleProfile != nil ? "Yes" : "No")
                SummaryRow(label: "Date", value: Date().formatted(date: .abbreviated, time: .omitted))
            }
            .padding(16)
            .background(Color(hex: "#FFFFFF"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var exportButton: some View {
        Button {
            Task {
                await performExport()
            }
        } label: {
            HStack {
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.down")
                }
                Text(isExporting ? "Exporting..." : "Export Wardrobe")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#1C1C1E"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isExporting)
    }

    private func performExport() async {
        isExporting = true
        do {
            let data = try await ExportService.shared.exportWardrobe(
                items: items,
                outfits: outfits,
                styleProfile: styleProfile,
                format: selectedFormat
            )
            exportedData = data
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isExporting = false
    }
}

struct FormatOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "#1C1C1E") : Color(hex: "#E8E8E6"))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? .white : Color(hex: "#6E6E73"))
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

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color(hex: "#1C1C1E") : Color(hex: "#E8E8E6"))
            }
            .padding(12)
            .background(Color(hex: "#FFFFFF"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#1C1C1E"), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#1C1C1E"))
        }
    }
}

struct ShareSheetView: View {
    let data: Data
    let filename: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color(hex: "#B8A898"))

                Text("Ready to Share")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))

                Text("Your wardrobe export is ready. Use the share button to save or send it.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#6E6E73"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#1C1C1E"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 40)
            .navigationTitle(filename)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

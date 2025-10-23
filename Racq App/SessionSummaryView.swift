import SwiftUI

struct SessionSummaryView: View {
    @ObservedObject private var wc = PhoneWCManager.shared

    var body: some View {
        NavigationView {
            List {
                if wc.completedSessions.isEmpty {
                    Text("No sessions received yet.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(wc.completedSessions) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.date.formatted(date: .abbreviated, time: .standard))
                                .font(.headline)

                            Text("Shots: \(session.shots)")
                                .font(.subheadline)

                            Text("Duration: \(formatDuration(session.duration))")
                                .font(.subheadline)

                            // 🔗 Open CSV file
                            NavigationLink(destination: CSVViewerView(fileURL: session.fileURL)) {
                                Text(session.fileURL.lastPathComponent)
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                                    .underline()
                            }

                            // 📤 Share CSV button
                            Button {
                                presentShareSheet(for: session.fileURL)
                            } label: {
                                Label("Share CSV", systemImage: "square.and.arrow.up")
                                    .font(.footnote)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Session Summary")
        }
    }

    // MARK: - Helpers
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02dm %02ds", minutes, seconds)
    }

    private func presentShareSheet(for url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            print("⚠️ Could not find root view controller to present share sheet.")
            return
        }
        wc.shareFile(url, from: root)
    }
}

#Preview {
    SessionSummaryView()
}

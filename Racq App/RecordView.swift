
//RecordView.swift

import SwiftUI

struct RecordView: View {
    @ObservedObject private var wcManager = PhoneWCManager.shared
    @State private var lastSession: PhoneWCManager.SessionSummary?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("🎾 Racq Session Tracker")
                    .font(.largeTitle)
                    .bold()

                // Watch connection indicator
                HStack {
                    Image(systemName: wcManager.isWatchConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(wcManager.isWatchConnected ? .green : .red)
                    Text(wcManager.isWatchConnected ? "Watch Connected" : "Watch Not Connected")
                        .foregroundColor(.secondary)
                }

                Divider()

                // Latest session info
                if let session = lastSession {
                    VStack(spacing: 8) {
                        Text("Last Session File:")
                            .font(.headline)

                        // 🔗 Open CSV file
                        NavigationLink(destination: CSVViewerView(fileURL: session.fileURL)) {
                            Text(session.fileURL.lastPathComponent)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .underline()
                        }

                        Text("Shots: \(session.shots)")
                            .font(.title3)
                            .bold()

                        Text("Duration: \(formatDuration(session.duration))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button {
                            presentShareSheet(for: session.fileURL)
                        } label: {
                            Label("Share CSV", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                } else {
                    Text("No session data yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 30)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        loadLatestSession()
                    } label: {
                        Label("Load Latest Session", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(role: .destructive) {
                        lastSession = nil
                    } label: {
                        Label("Clear Data", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .onAppear { loadLatestSession() }
            .onReceive(wcManager.$completedSessions) { _ in loadLatestSession() }
            .navigationTitle("Record Session")
        }
    }

    // MARK: - Load latest session
    private func loadLatestSession() {
        lastSession = wcManager.completedSessions.last
        if let session = lastSession {
            print("📂 Loaded latest session: \(session.fileURL.lastPathComponent)")
        }
    }

    // MARK: - Share CSV
    private func presentShareSheet(for url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            print("⚠️ Could not find root view controller to present share sheet.")
            return
        }
        wcManager.shareFile(url, from: root)
    }

    // MARK: - Duration formatting
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02dm %02ds", minutes, seconds)
    }
}

#Preview {
    RecordView()
}

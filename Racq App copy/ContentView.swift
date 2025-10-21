//
//  ContentView.swift
//  Racq App
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var wcManager = PhoneWCManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Racq App")
                    .font(.largeTitle)
                    .bold()

                Label("RACQ Data Dashboard", systemImage: "chart.bar.xaxis")
                    .font(.headline)

                HStack {
                    Image(systemName: wcManager.isWatchConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(wcManager.isWatchConnected ? .green : .red)
                    Text(wcManager.isWatchConnected ? "Watch Connected" : "Watch Not Connected")
                        .foregroundColor(.secondary)
                }

                Divider()

                if wcManager.receivedFiles.isEmpty {
                    Text("No data received yet.")
                        .foregroundColor(.gray)
                } else {
                    List(wcManager.receivedFiles, id: \.self) { fileURL in
                        HStack {
                            Image(systemName: "doc.text")
                            Text(fileURL.lastPathComponent)
                            Spacer()
                            Button(action: { shareFile(fileURL) }) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()

                Button(role: .destructive) {
                    wcManager.receivedFiles.removeAll()
                } label: {
                    Label("Clear All Logs", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
    }

    private func shareFile(_ fileURL: URL) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .keyWindow?
            .rootViewController?
            .present(activityVC, animated: true)
    }
}

#Preview {
    ContentView()
}

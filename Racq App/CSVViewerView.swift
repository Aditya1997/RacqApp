
//  CSVViewerView.swift
//  Racq App
//

import SwiftUI

struct CSVViewerView: View {
    let fileURL: URL
    @State private var fileContent: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 15) {
            if isLoading {
                ProgressView("Loading file...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let errorMessage {
                Text("❌ \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ScrollView {
                    Text(fileContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
        .onAppear(perform: loadFile)
    }

    private func loadFile() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                DispatchQueue.main.async {
                    self.fileContent = content
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load file: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    CSVViewerView(fileURL: URL(fileURLWithPath: "/Users/preview/motionData.csv"))
}

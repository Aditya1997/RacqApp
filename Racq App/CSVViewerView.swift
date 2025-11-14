
//  CSVViewerView.swift
//  Racq App
//  11/13/2025 - Updated to add new swing summary csv

import SwiftUI


struct SwingRecord: Identifiable {
    let id = UUID()
    let timestamp: String
    let type: String
    let peakMagnitude: String
    let peakRMSGyroMagnitude: String
    let duration: String
}

struct CSVViewerView: View {
    let fileURL: URL
    @State private var fileContent: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var swingRows: [SwingRecord] = []

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
                if !swingRows.isEmpty {
                    List(swingRows) { swing in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Timestamp: \(swing.timestamp)")
                            Text("Type: \(swing.type)")
                            Text("Peak: \(swing.peakMagnitude) g")
                            Text("Duration: \(swing.duration) s")
                        }
                        .font(.system(.body, design: .monospaced))
                    }
                }
                // ▸ 2) Otherwise → fall back to monospaced raw text viewer
                else {
                    ScrollView {
                        Text(fileContent)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
        .onAppear(perform: loadFile)
    }

    private func loadFile() {
        do {
            let raw = try String(contentsOf: fileURL, encoding: .utf8)
            fileContent = raw

            let rows = raw.components(separatedBy: .newlines)

            // If header looks like the SwingSummaries.csv format, parse it
            if rows.count > 1,
               let header = rows.first,
               header.contains("PeakMagnitude") && header.contains("Duration") {

                var parsed: [SwingRecord] = []

                for row in rows.dropFirst() {
                    let cols = row.components(separatedBy: ",")
                    guard cols.count == 5 else { continue }
                    let record = SwingRecord(
                        timestamp: cols[0],
                        type: cols[1],
                        peakMagnitude: cols[2],
                        peakRMSGyroMagnitude: cols[3],
                        duration: cols[4]
                    )
                    parsed.append(record)
                }
                swingRows = parsed
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to read file: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    CSVViewerView(fileURL: URL(fileURLWithPath: "/Users/preview/motionData.csv"))
}

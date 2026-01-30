//
//  StorageService.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//  Integrates image/etc. storage into Firestore


import Foundation
import Firebase
import FirebaseStorage
import UIKit

final class StorageService {
    static let shared = StorageService()
    private init() {}

    private var storage: Storage { Storage.storage() }

    func uploadJPEGs(
        datas: [Data],
        pathPrefix: String
    ) async throws -> [String] {
        guard FirebaseApp.app() != nil else { return [] }

        var urls: [String] = []
        urls.reserveCapacity(datas.count)

        for (idx, data) in datas.enumerated() {
            let name = "\(UUID().uuidString)_\(idx).jpg"
            let ref = storage.reference(withPath: "\(pathPrefix)/\(name)")

            _ = try await ref.putDataAsync(data, metadata: {
                let meta = StorageMetadata()
                meta.contentType = "image/jpeg"
                return meta
            }())

            let url = try await ref.downloadURL()
            urls.append(url.absoluteString)
        }

        return urls
    }
}

// MARK: - FirebaseStorage async helpers
extension StorageReference {
    func putDataAsync(_ data: Data, metadata: StorageMetadata?) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { continuation in
            putData(data, metadata: metadata) { meta, err in
                if let err { continuation.resume(throwing: err); return }
                continuation.resume(returning: meta ?? StorageMetadata())
            }
        }
    }

    func downloadURL() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            downloadURL { url, err in
                if let err { continuation.resume(throwing: err); return }
                continuation.resume(returning: url!)
            }
        }
    }
}

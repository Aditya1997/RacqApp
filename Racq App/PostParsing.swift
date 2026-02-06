//
//  PostParsing.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//


import Foundation
import FirebaseFirestore

enum PostParsing {
    
    // Helpers
    // Firestore sometimes stores numbers as Int, Double, or even NSNumber.
    // This prevents “as? Double” from failing and producing nil/0 unexpectedly.
    private static func parseDouble(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let n = value as? NSNumber { return n.doubleValue }
        if let s = value as? String, let d = Double(s) { return d }
        return nil
    }

    private static func parseInt(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let n = value as? NSNumber { return n.intValue }
        if let s = value as? String, let i = Int(s) { return i }
        return nil
    }
    
    static func parsePost(docId: String, data: [String: Any]) -> AppPost? {
        let authorId = data["authorId"] as? String ?? ""
        let authorName = data["authorName"] as? String ?? "Anonymous"
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let type = PostType(rawValue: data["type"] as? String ?? "text") ?? .text

        let caption = data["caption"] as? String ?? ""
        let locationText = data["locationText"] as? String
        let tagged = data["taggedUsernames"] as? [String] ?? []
        let imageURLs = data["imageURLs"] as? [String] ?? []
        let commentCount = data["commentCount"] as? Int ?? 0
        let lastCommentAt = (data["lastCommentAt"] as? Timestamp)?.dateValue()

        let sessionId = data["sessionId"] as? String

        // Use robust numeric parsing for consistency
        let shotCount = parseInt(data["shotCount"])
        let forehandCount = parseInt(data["forehandCount"])
        let backhandCount = parseInt(data["backhandCount"])
        let durationSec = parseInt(data["durationSec"])
        let heartRate = parseDouble(data["heartRate"])
        let fastestSwing = parseDouble(data["fastestSwing"])
        let fhAvgMph = parseDouble(data["fhAvgMph"])
        let fhMaxMph = parseDouble(data["fhMaxMph"])
        let bhAvgMph = parseDouble(data["bhAvgMph"])
        let bhMaxMph = parseDouble(data["bhMaxMph"])

        return AppPost(
            id: docId,
            authorId: authorId,
            authorName: authorName,
            createdAt: createdAt,
            type: type,
            caption: caption,
            locationText: locationText,
            taggedUsernames: tagged,
            imageURLs: imageURLs,
            commentCount: commentCount,
            lastCommentAt: lastCommentAt,
            sessionId: sessionId,
            shotCount: shotCount,
            forehandCount: forehandCount,
            backhandCount: backhandCount,
            durationSec: durationSec,
            heartRate: heartRate,
            fastestSwing: fastestSwing,
            fhAvgMph: fhAvgMph,
            fhMaxMph: fhMaxMph,
            bhAvgMph: bhAvgMph,
            bhMaxMph: bhMaxMph
        )
    }
}

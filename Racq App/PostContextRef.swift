//
//  PostContextRef.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//

enum PostContextRef: Hashable, Identifiable {
    case profile(ownerId: String, postId: String) // users/{ownerId}/posts/{postId}
    case group(groupId: String, postId: String)    // groups/{groupId}/posts/{postId}

    var postPath: String {
        switch self {
        case .profile(let ownerId, let postId):
            return "users/\(ownerId)/posts/\(postId)"
        case .group(let groupId, let postId):
            return "groups/\(groupId)/posts/\(postId)"
        }
    }

    var id: String { postPath }
}

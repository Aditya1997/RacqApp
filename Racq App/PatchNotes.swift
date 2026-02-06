//
//  PatchNotes.swift
//  Racq App
//
//  Created by Deets on 1/14/26.
//

// 1/14/2026 - Added fastestSwing as needed into PhoneWCManager, ProfileVIew, SessionSummary, UserProfile/Store, and UserSession/Store
// 1.7.6: 1/28/26 - Updated recordView to be a live viewer, modified swingSummary csv to use a stream+buffer method to prevent growth.
// 1.7.7: 1/28/26 - Updated GroupDetailView and member count/Firestore management
// 1.7.8: 1/29/26 - Updated profile and groups to support posts
// 1.7.8: New files: TinyPostCard, GroupPostCardView, UserPostStore, PostParsing, PostService, CreateSessionPostView, CreateGroupPostView, StorageService, PostType, HomeGroupFeedStore, DetailedAnalyticsCard, GroupMultiSelectPickerView
// 1.7.9: 2/2/26 - Added emoji support and better nvaigation
// 1.7.9: New files: PostContextRef, post DetailView, PostInteractionModels, PostInteractionsService, PostInteractionsStore, PostInteractionsView, ReactionsBarView, FeedPostRow
// 1.7.10 2/4/26 - Re-order groups and challenges, groups have a profile picture, change plus at top of community to createnewgroupview, challenges streamlined, clicking sessions in profile/groups should show the whole original session card, attempted comment bubble added and shows unread, cleaned up Firebase user profiles
// 1.7.10 New files: ChallengeDetailView, CreateNewGroupView, SessionSpeedMetrics,CommentBubbleBadge, NewCommentsTracker, UserStats
// 1.7.11 2/5/26 - Cleaned up cardviews to look nicer, corrected issue with posts getting wrong numbers vs. record view. Comment bubble badge modified

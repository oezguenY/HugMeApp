//
//  Protocols.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 19.07.23.
//

import UIKit
import Kingfisher
import Firebase

// implements the timestamp property. It uses a switch statement to extract the timestamp from either a FriendRequest or a HugRequest depending on the case.
extension NotificationType: TimestampSortable {
    var timestamp: Timestamp {
        switch self {
        case .friendRequest(let friendRequest):
            return friendRequest.timestamp
        case .hugRequest(let hugRequest):
            return hugRequest.timestamp
        }
    }
}

// TimestampSortable is a protocol that requires its conforming types to have a property named timestamp of type Timestamp
// Here, TimestampSortable is a protocol with a single requirement: a read-only property named timestamp of type Timestamp.
protocol TimestampSortable {
    var timestamp: Timestamp { get }
}

protocol MultiCamInheritanceVCDelegate: AnyObject {
    func didFinishPostingHug(success: Bool)
}

// This extension is for arrays of elements that conform to the TimestampSortable protocol. It provides a method sortedByTimestamp() which sorts an array of such elements based on their timestamps in descending order.
extension Array where Element: TimestampSortable {
    func sortedByTimestamp() -> [Element] {
        return self.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
    }
}

extension UIViewController {
    func clearCachesAndData() {
        // Clear image cache
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
        
        // Clear data arrays
        HugsGivenManager.shared.hugPostsGiven.removeAll()
        HugPostsGottenManager.shared.hugPostsGotten.removeAll()
        HugPostsFriendsManager.shared.hugPosts.removeAll()
        HugPostsDiscoveryManager.shared.hugPostsDiscovery.removeAll()
        FriendRequestsSentManager.shared.friendRequestsSent.removeAll()
        FriendRequestsReceivedManager.shared.friendRequestsReceived.removeAll()
        FriendsManager.shared.friends.removeAll()
        HugRequestsReceivedManager.shared.hugRequestsReceived.removeAll()
        HugRequestsSentManager.shared.hugRequestsSent.removeAll()
        
        // Reset app user singleton
        AppUserSingleton.shared.appUser = nil
    }
}

enum LogoutResult {
    case noPreviouslyAuthenticatedUser
    case previouslyAuthenticatedUserWasLoggedOut
    case previouslyAuthenticatedUserCouldNotBeLoggedOut(Error)
}

extension UIViewController {
    func logOutPreviousUser(completion: @escaping (LogoutResult) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            // A user is authenticated; you can log them out
            do {
                try Auth.auth().signOut()
                // Log out successful
                completion(.previouslyAuthenticatedUserWasLoggedOut)
            } catch let signOutError as NSError {
                print("Error signing out: \(signOutError.localizedDescription)")
                // Handle sign-out error if needed
                completion(.previouslyAuthenticatedUserCouldNotBeLoggedOut(signOutError))
            }
        } else {
            // No user is authenticated
            completion(.noPreviouslyAuthenticatedUser)
        }
    }
}

extension UIViewController {
    var hasRegistered: Bool {
        return UserDefaults.standard.bool(forKey: "HasRegistered")
    }

}

extension UIImage {
    static func extractFirstFrameFromGIF(named gifName: String) -> UIImage? {
        guard let gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif") else {
            return nil
        }

        guard let source = CGImageSourceCreateWithURL(gifURL as CFURL, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        
        guard frameCount > 0 else {
            return nil
        }

        let firstFrame = CGImageSourceCreateImageAtIndex(source, 0, nil)
        let uiImage = UIImage(cgImage: firstFrame!)

        return uiImage
    }
}

protocol SelectGIFVCDelegate: AnyObject {
    func hugRequestSent(success: Bool)
}







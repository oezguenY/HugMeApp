//
//  Singleton.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 17.07.23.
//

import Foundation
import Firebase

class AppUserSingleton {
    static let shared = AppUserSingleton()
    var appUser: AppUser?
    
    init(appUser: AppUser? = nil) {
        self.appUser = appUser
    }
}

class FirestoreListenerManager {
    static let shared = FirestoreListenerManager() // Singleton instance

    var listeners: [ListenerRegistration] = []

    private init() {} // Private initializer for singleton

    func add(_ listener: ListenerRegistration) {
        listeners.append(listener)
    }

    func remove(_ listener: ListenerRegistration) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listener.remove()
            listeners.remove(at: index)
        }
    }

    func removeAllListeners() {
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
}


class FriendRequestsReceivedManager {
    static let shared = FriendRequestsReceivedManager()
    
    var friendRequestsReceived: [FriendRequest] = []
}

class FriendRequestsSentManager {
    static let shared = FriendRequestsSentManager()
    
    var friendRequestsSent: [FriendRequest] = []
}

class FriendsManager {
    static let shared = FriendsManager()
    
    var friends: [AppUser] = []
}

class HugRequestsReceivedManager {
    static let shared = HugRequestsReceivedManager()
    
    var hugRequestsReceived: [HugRequest] = []
}

class HugRequestsSentManager {
    static let shared = HugRequestsSentManager()
    
    var hugRequestsSent: [HugRequest] = []
}

class HugPostsFriendsManager {
    static let shared = HugPostsFriendsManager()
    
    var hugPosts: [Hug] = []
}

class HugPostsDiscoveryManager {
    static let shared = HugPostsDiscoveryManager()
    
    var hugPostsDiscovery: [Hug] = []
}

class HugPostsGottenManager {
    static let shared = HugPostsGottenManager()
    
    var hugPostsGotten: [Hug] = []
}

class HugsGivenManager {
    static let shared = HugsGivenManager()
    
    var hugPostsGiven: [Hug] = []
}

class PaginationHugPostsDiscoveryManager {
    static let shared = PaginationHugPostsDiscoveryManager()
    
    var hugPostsDiscovery: [Hug] = []
    var currentPage: Int = 1
    let pageSize: Int = 20 // Number of posts per page
    var lastDocumentRef: QueryDocumentSnapshot?
    
    func fetchTwentyDiscoveryPostsWithPagination(lastDocumentReference: QueryDocumentSnapshot?, completion: @escaping ([Hug], QueryDocumentSnapshot?, Error?) -> Void) {
        let hugPostsCollectionRef = Constants.Collections.HugPostsRef
        var recentHugPosts: [Hug] = []
        var newLastReference: QueryDocumentSnapshot?

        let dispatchGroup = DispatchGroup() // Create a DispatchGroup

        dispatchGroup.enter() // Enter the DispatchGroup

        var query = hugPostsCollectionRef
            .order(by: "timestamp", descending: true)
            .limit(to: 20) // Fetch the most recent 3 hug posts

        if let lastDocumentReference = lastDocumentReference {
            query = query.start(afterDocument: lastDocumentReference)
        }

        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let _ = self, let querySnapshot = querySnapshot else {
                // Handle error or nil self
                dispatchGroup.leave() // Leave the DispatchGroup
                completion([], nil, error)
                return
            }

            for document in querySnapshot.documents {
                do {
                    let hugPost = try document.data(as: Hug.self)
                    recentHugPosts.append(hugPost)
                } catch {
                    print("Error decoding hug post document: \(error)")
                }
            }

            newLastReference = querySnapshot.documents.last // Get the reference to the last document

            dispatchGroup.leave() // Leave the DispatchGroup
            
        }

        dispatchGroup.notify(queue: .main) {
            completion(recentHugPosts, newLastReference, nil)
        }
    }

}

class PaginationHugPostsFriendsManager {
    static let shared = PaginationHugPostsFriendsManager()
    
    var hugPostsFriends: [Hug] = []
    var currentPage: Int = 1
    let pageSize: Int = 20 // Number of posts per page
    var lastDocumentRef: QueryDocumentSnapshot?
    
    func fetchTwentyFriendsPostsWithPagination(lastDocumentReference: QueryDocumentSnapshot?, completion: @escaping ([Hug], QueryDocumentSnapshot?, Error?) -> Void) {
        let hugPostsCollectionRef = Constants.Collections.HugPostsRef
        var recentHugPosts: [Hug] = []
        var newLastReference: QueryDocumentSnapshot?
        
        let friends = FriendsManager.shared.friends.map { $0.userName }
        if friends.isEmpty {
            completion([], nil, nil)
            return
        }
        
        let dispatchGroup = DispatchGroup() // Create a DispatchGroup
        
        // Create a DispatchQueue for safely updating newLastReference
        let updateQueue = DispatchQueue(label: "com.example.updateQueue")
        
        dispatchGroup.enter() // Enter the DispatchGroup
        
        var query = hugPostsCollectionRef
            .whereField("receiverUsername", in: friends) // Filter by multiple friend usernames
            .order(by: "timestamp", descending: true)
            .limit(to: 20) // Fetch the most recent hug posts
            
        if let lastDocumentReference = lastDocumentReference {
            query = query.start(afterDocument: lastDocumentReference)
        }
        
        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let _ = self, let querySnapshot = querySnapshot else {
                // Handle error or nil self
                dispatchGroup.leave() // Leave the DispatchGroup
                completion([], nil, error)
                return
            }
            
            var localLastReference: QueryDocumentSnapshot?
            
            for document in querySnapshot.documents {
                do {
                    let hugPost = try document.data(as: Hug.self)
                    recentHugPosts.append(hugPost)
                } catch {
                    print("Error decoding hug post document: \(error)")
                }
                
                // Update the localLastReference inside the loop
                localLastReference = document
            }
            
            // Safely update newLastReference using the updateQueue
            updateQueue.sync {
                if let localLastReference = localLastReference {
                    // Only update newLastReference if localLastReference is not nil
                    newLastReference = localLastReference
                }
            }
            
            dispatchGroup.leave() // Leave the DispatchGroup
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(recentHugPosts, newLastReference, nil)
        }
    }


}

class PaginationSearchedUserHugPostsManager {
    static let shared = PaginationSearchedUserHugPostsManager()
    
    var hugPostsFriends: [Hug] = []
    var currentPage: Int = 1
    let pageSize: Int = 20 // Number of posts per page
    var lastDocumentRef: QueryDocumentSnapshot?
    
    func fetchMorePostsOfSearchedUser(searchedUserUsername: String, lastDocumentReference: QueryDocumentSnapshot?, completion: @escaping ([Hug], QueryDocumentSnapshot?, Error?) -> Void) {
        let hugPostsCollectionRef = Constants.Collections.HugPostsRef
        var recentHugPosts: [Hug] = []
        var newLastReference: QueryDocumentSnapshot?
        
        let dispatchGroup = DispatchGroup() // Create a DispatchGroup
        
        // Create a DispatchQueue for safely updating newLastReference
        let updateQueue = DispatchQueue(label: "com.example.updateQueue")
        
        dispatchGroup.enter() // Enter the DispatchGroup
        
        var query = hugPostsCollectionRef
            .whereField("receiverUsername", isEqualTo: searchedUserUsername) // Filter by multiple friend usernames
            .order(by: "timestamp", descending: true)
            .limit(to: 10) // Fetch the most recent hug posts
            
        if let lastDocumentReference = lastDocumentReference {
            query = query.start(afterDocument: lastDocumentReference)
        }
        
        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let _ = self, let querySnapshot = querySnapshot else {
                // Handle error or nil self
                dispatchGroup.leave() // Leave the DispatchGroup
                completion([], nil, error)
                return
            }
            
            var localLastReference: QueryDocumentSnapshot?
            
            for document in querySnapshot.documents {
                do {
                    let hugPost = try document.data(as: Hug.self)
                    recentHugPosts.append(hugPost)
                } catch {
                    print("Error decoding hug post document: \(error)")
                }
                
                // Update the localLastReference inside the loop
                localLastReference = document
            }
            
            // Safely update newLastReference using the updateQueue
            updateQueue.sync {
                if let localLastReference = localLastReference {
                    // Only update newLastReference if localLastReference is not nil
                    newLastReference = localLastReference
                }
            }
            
            dispatchGroup.leave() // Leave the DispatchGroup
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(recentHugPosts, newLastReference, nil)
        }
    }


}


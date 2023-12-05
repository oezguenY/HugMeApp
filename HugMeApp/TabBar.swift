//
//  TabBar.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 16.08.22.
//

import UIKit
import Firebase
import Kingfisher

class TabBar: UITabBarController {

    let firestoreListenerManager = FirestoreListenerManager.shared
    
    var userDocListener: ListenerRegistration?
    
    fileprivate func createNavController(for rootViewController: UIViewController,
                                         title: String,
                                         image: UIImage) -> UIViewController {
        let navController = UINavigationController(rootViewController: rootViewController)
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        rootViewController.navigationItem.title = title
        return navController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        UITabBar.appearance().barTintColor = .systemBackground
        tabBar.tintColor = .label
        setupVCs()
        setUpListeners()
    }
    
    func setUpListeners() {
        // Get the UID of the currently authenticated user
        if let currentUserUID = Auth.auth().currentUser?.uid {
            // Reference to the Firestore document for the current user
            let userDocRef = Firestore.firestore().collection("users").document(currentUserUID)
            // Add a listener for the user's document
            
            if let userDocListener = self.userDocListener {
                firestoreListenerManager.remove(userDocListener)
            }
            
            userDocListener = userDocRef.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    return
                }
                
                
                if let hugsGottenArray = document["hugsgotten"] as? [String] {
                    // Check for hugs in HugPostsGottenManager.shared.hugPostsGotten that are not in hugsGottenArray
                    let missingHugUIDs = HugPostsGottenManager.shared.hugPostsGotten
                        .filter { !hugsGottenArray.contains($0.uid) }
                        .map { $0.uid }
                    
                    // Remove missing hugs from HugPostsGottenManager.shared.hugPostsGotten
                    HugPostsGottenManager.shared.hugPostsGotten.removeAll { missingHugUIDs.contains($0.uid) }
                    
                    // Check for hugs in hugsGottenArray that are not in HugPostsGottenManager.shared.hugPostsGotten
                    let newHugUIDs = hugsGottenArray.filter { uid in
                        !HugPostsGottenManager.shared.hugPostsGotten.contains { $0.uid == uid }
                    }
                    
                    // Fetch missing hugs from Firestore and add them to HugPostsGottenManager.shared.hugPostsGotten
                    let hugPostsCollectionRef = Firestore.firestore().collection("hugposts")
                    var fetchedHugs: [Hug] = []
                    
                    let fetchGroup = DispatchGroup()
                    
                    for uid in newHugUIDs {
                        fetchGroup.enter()
                        
                        hugPostsCollectionRef.document(uid).getDocument { document, error in
                            defer {
                                fetchGroup.leave()
                            }
                            
                            if let error = error {
                                print("Error fetching hug post document with UID \(uid): \(error)")
                                return
                            }
                            
                            if let document = document, document.exists {
                                do {
                                    // Decode the fetched document into a Hug model
                                    let hug = try document.data(as: Hug.self)
                                    fetchedHugs.append(hug)
                                    
                                } catch {
                                    print("Error decoding hug post document with UID \(uid): \(error)")
                                }
                            }
                        }
                    }
                    
                    fetchGroup.notify(queue: .main) {
                        // Append the fetched hugs to HugPostsGottenManager.shared.hugPostsGotten
                        HugPostsGottenManager.shared.hugPostsGotten.append(contentsOf: fetchedHugs)
                        HugPostsGottenManager.shared.hugPostsGotten = Array(Set(HugPostsGottenManager.shared.hugPostsGotten))
                        HugPostsGottenManager.shared.hugPostsGotten = HugPostsGottenManager.shared.hugPostsGotten.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                        
                    }
                }
                
                if let hugsGivenArray = document["hugsgiven"] as? [String] {
                    // Check for hugs in HugPostsGottenManager.shared.hugPostsGotten that are not in hugsGottenArray
                    let missingHugUIDs = HugsGivenManager.shared.hugPostsGiven
                        .filter { !hugsGivenArray.contains($0.uid) }
                        .map { $0.uid }
                    
                    // Remove missing hugs from HugPostsGottenManager.shared.hugPostsGotten
                    HugsGivenManager.shared.hugPostsGiven.removeAll { missingHugUIDs.contains($0.uid) }
                    
                    // Check for hugs in hugsGottenArray that are not in HugPostsGottenManager.shared.hugPostsGotten
                    let newHugUIDs = hugsGivenArray.filter { uid in
                        !HugsGivenManager.shared.hugPostsGiven.contains { $0.uid == uid }
                    }
                    
                    // Fetch missing hugs from Firestore and add them to HugPostsGottenManager.shared.hugPostsGotten
                    let hugPostsCollectionRef = Firestore.firestore().collection("hugposts")
                    var fetchedHugs: [Hug] = []
                    
                    let fetchGroup = DispatchGroup()
                    
                    for uid in newHugUIDs {
                        fetchGroup.enter()
                        
                        hugPostsCollectionRef.document(uid).getDocument { document, error in
                            defer {
                                fetchGroup.leave()
                            }
                            
                            if let error = error {
                                print("Error fetching hug post document with UID \(uid): \(error)")
                                return
                            }
                            
                            if let document = document, document.exists {
                                do {
                                    // Decode the fetched document into a Hug model
                                    let hug = try document.data(as: Hug.self)
                                    fetchedHugs.append(hug)
                                    
                                } catch {
                                    print("Error decoding hug post document with UID \(uid): \(error)")
                                }
                            }
                        }
                    }
                    
                    fetchGroup.notify(queue: .main) {
                        // Append the fetched hugs to HugPostsGottenManager.shared.hugPostsGotten
                        HugsGivenManager.shared.hugPostsGiven.append(contentsOf: fetchedHugs)
                        HugsGivenManager.shared.hugPostsGiven = Array(Set(HugsGivenManager.shared.hugPostsGiven))
                        HugsGivenManager.shared.hugPostsGiven = HugsGivenManager.shared.hugPostsGiven.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    }
                }
                
                
                // Add a listener for the "friends" field (based on usernames)
                if let friendsArray = document["friends"] as? [String] {
                    print("FRIENDS FIELD HAS CHANGED!")
                    // Get usernames of friends not present in FriendsManager.shared.friends
                    let newFriendUsernames = friendsArray.filter { userName in
                        !FriendsManager.shared.friends.contains { $0.userName == userName }
                    }
                    
                    // Fetch documents for the new friend usernames from the "users" collection
                    let usersCollectionRef = Firestore.firestore().collection("users")
                    
                    // Create a dispatch group to track when all fetch operations are completed
                    let fetchGroup = DispatchGroup()
                    
                    for username in newFriendUsernames {
                        fetchGroup.enter() // Enter the dispatch group for this fetch operation
                        
                        // Fetch documents where "username" field matches the new friend's username
                        usersCollectionRef.whereField("username", isEqualTo: username).getDocuments { querySnapshot, error in
                            defer {
                                fetchGroup.leave() // Leave the dispatch group when this fetch operation is completed
                            }
                            
                            if let error = error {
                                print("Error fetching user document with username \(username): \(error)")
                                return
                            }
                            
                            // Iterate through the documents (usually only one)
                            for document in querySnapshot?.documents ?? [] {
                                do {
                                    // Decode the fetched document into an AppUser model
                                    let appUser = try document.data(as: AppUser.self)
                                    print("DECODING APP USER: \(appUser.userName)")
                                    
                                    // Append it to the fetched friends list
                                    FriendsManager.shared.friends.append(appUser)
                                    
                                } catch {
                                    print("Error decoding user document with username \(username): \(error)")
                                }
                            }
                        }
                    }
                    
                    // Notify when all fetch operations are completed
                    fetchGroup.notify(queue: .main) {
                        // Filter out duplicates in case of multiple listeners triggering
                        FriendsManager.shared.friends = Array(Set(FriendsManager.shared.friends))
                        
                        // Remove friends who are no longer in friendsArray
                        FriendsManager.shared.friends = FriendsManager.shared.friends.filter { friend in
                            friendsArray.contains(friend.userName)
                        }
                    }
                }
                
                // Convert "friendrequestsreceived" string array to an array of UIDs
                if let friendRequestsReceivedStrings = document["friendrequestsreceived"] as? [String] {
                    print("FRIEND REQUEST RECEIVED FIELD HAS CHANGED!")
                    // Get UIDs that are not in FriendRequestsReceivedManager.shared.friendRequestsReceived
                    let newUIDs = friendRequestsReceivedStrings.filter { uid in
                        !FriendRequestsReceivedManager.shared.friendRequestsReceived.contains { $0.uid == uid }
                    }
                    
                    // Fetch documents for the new UIDs from the "friendrequests" collection
                    let friendRequestsCollectionRef = Firestore.firestore().collection("friendrequests")
                    var fetchedFriendRequests: [FriendRequest] = []
                    
                    // Create a dispatch group to track when all fetch operations are completed
                    let fetchGroup = DispatchGroup()
                    
                    for uid in newUIDs {
                        fetchGroup.enter() // Enter the dispatch group for this fetch operation
                        
                        friendRequestsCollectionRef.document(uid).getDocument { document, error in
                            defer {
                                fetchGroup.leave() // Leave the dispatch group when this fetch operation is completed
                            }
                            
                            if let error = error {
                                print("Error fetching friend request document with UID \(uid): \(error)")
                                return
                            }
                            
                            if let document = document, document.exists {
                                do {
                                    // Decode the fetched document into a FriendRequest model
                                    let friendRequest = try document.data(as: FriendRequest.self)
                                    // Append it to the fetchedFriendRequests array
                                    fetchedFriendRequests.append(friendRequest)
                                } catch {
                                    print("Error decoding friend request document with UID \(uid): \(error)")
                                }
                            }
                        }
                    }
                    
                    // Notify when all fetch operations are completed
                    fetchGroup.notify(queue: .main) {
                        // Append the fetched friend requests to FriendRequestsReceivedManager.shared.friendRequestsReceived
                        FriendRequestsReceivedManager.shared.friendRequestsReceived.append(contentsOf: fetchedFriendRequests)
                        
                        // Filter out UIDs from FriendRequestsReceivedManager.shared.friendRequestsReceived
                        // that are not in friendRequestsReceivedStrings
                        FriendRequestsReceivedManager.shared.friendRequestsReceived = FriendRequestsReceivedManager.shared.friendRequestsReceived.filter { friendRequest in
                            friendRequestsReceivedStrings.contains(friendRequest.uid)
                        }
                        FriendRequestsReceivedManager.shared.friendRequestsReceived = Array(Set(FriendRequestsReceivedManager.shared.friendRequestsReceived))
                        FriendRequestsReceivedManager.shared.friendRequestsReceived = FriendRequestsReceivedManager.shared.friendRequestsReceived.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    }
                    self.updateInboxBadge()
                }
                
                // Convert "friendrequestssent" string array to an array of UIDs
                if let friendRequestsSentStrings = document["friendrequestssent"] as? [String] {
                    // Get UIDs that are not in FriendRequestsSentManager.shared.friendRequestsSent
                    let newUIDs = friendRequestsSentStrings.filter { uid in
                        !FriendRequestsSentManager.shared.friendRequestsSent.contains { $0.uid == uid }
                    }
                    
                    // Fetch documents for the new UIDs from the "friendrequests" collection
                    let friendRequestsCollectionRef = Firestore.firestore().collection("friendrequests")
                    var fetchedFriendRequests: [FriendRequest] = []
                    
                    // Create a dispatch group to track when all fetch operations are completed
                    let fetchGroup = DispatchGroup()
                    
                    for uid in newUIDs {
                        fetchGroup.enter() // Enter the dispatch group for this fetch operation
                        
                        friendRequestsCollectionRef.document(uid).getDocument { document, error in
                            defer {
                                fetchGroup.leave() // Leave the dispatch group when this fetch operation is completed
                            }
                            
                            if let error = error {
                                print("Error fetching friend request document with UID \(uid): \(error)")
                                return
                            }
                            
                            if let document = document, document.exists {
                                do {
                                    // Decode the fetched document into a FriendRequest model
                                    let friendRequest = try document.data(as: FriendRequest.self)
                                    // Append it to the fetchedFriendRequests array
                                    fetchedFriendRequests.append(friendRequest)
                                } catch {
                                    print("Error decoding friend request document with UID \(uid): \(error)")
                                }
                            }
                        }
                    }
                    
                    // Notify when all fetch operations are completed
                    fetchGroup.notify(queue: .main) {
                        // Append the fetched friend requests to FriendRequestsSentManager.shared.friendRequestsSent
                        FriendRequestsSentManager.shared.friendRequestsSent.append(contentsOf: fetchedFriendRequests)
                        
                        // Filter out friend requests that are not in friendRequestsSentStrings
                        FriendRequestsSentManager.shared.friendRequestsSent = FriendRequestsSentManager.shared.friendRequestsSent.filter { friendRequest in
                            friendRequestsSentStrings.contains(friendRequest.uid)
                        }
                        FriendRequestsSentManager.shared.friendRequestsSent = Array(Set(FriendRequestsSentManager.shared.friendRequestsSent))
                        FriendRequestsSentManager.shared.friendRequestsSent = FriendRequestsSentManager.shared.friendRequestsSent.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    }
                }
                
                
                // Convert "hugrequestsreceived" string array to an array of UIDs
                if let hugRequestsReceivedStrings = document["hugrequestsreceived"] as? [String] {
                    // Get UIDs that are not in HugRequestsReceivedManager.shared.hugRequestsReceived
                    let newUIDs = hugRequestsReceivedStrings.filter { uid in
                        !HugRequestsReceivedManager.shared.hugRequestsReceived.contains { $0.uid == uid }
                    }
                    
                    // Fetch documents for the new UIDs from the "hugrequests" collection
                    let hugRequestsCollectionRef = Firestore.firestore().collection("hugrequests")
                    var fetchedHugRequests: [HugRequest] = []
                    
                    // Create a dispatch group to track when all fetch operations are completed
                    let fetchGroup = DispatchGroup()
                    
                    for uid in newUIDs {
                        fetchGroup.enter() // Enter the dispatch group for this fetch operation
                        
                        hugRequestsCollectionRef.document(uid).getDocument { document, error in
                            defer {
                                fetchGroup.leave() // Leave the dispatch group when this fetch operation is completed
                            }
                            
                            if let error = error {
                                print("Error fetching hug request document with UID \(uid): \(error)")
                                return
                            }
                            
                            if let document = document, document.exists {
                                do {
                                    // Decode the fetched document into a HugRequest model
                                    let hugRequest = try document.data(as: HugRequest.self)
                                    // Append it to the fetchedHugRequests array
                                    fetchedHugRequests.append(hugRequest)
                                } catch {
                                    print("Error decoding hug request document with UID \(uid): \(error)")
                                }
                            }
                        }
                    }
                    
                    // Notify when all fetch operations are completed
                    fetchGroup.notify(queue: .main) {
                        // Append the fetched hug requests to HugRequestsReceivedManager.shared.hugRequestsReceived
                        HugRequestsReceivedManager.shared.hugRequestsReceived.append(contentsOf: fetchedHugRequests)
                        
                        // Filter out UIDs from HugRequestsReceivedManager.shared.hugRequestsReceived
                        // that are not in hugRequestsReceivedStrings
                        HugRequestsReceivedManager.shared.hugRequestsReceived = HugRequestsReceivedManager.shared.hugRequestsReceived.filter { hugRequest in
                            hugRequestsReceivedStrings.contains(hugRequest.uid)
                        }
                        HugRequestsReceivedManager.shared.hugRequestsReceived = Array(Set(HugRequestsReceivedManager.shared.hugRequestsReceived))
                        HugRequestsReceivedManager.shared.hugRequestsReceived = HugRequestsReceivedManager.shared.hugRequestsReceived.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    }
                    self.updateInboxBadge()
                }
                
                // Convert "hugrequestssent" string array to an array of UIDs
                if let hugRequestsSentStrings = document["hugrequestssent"] as? [String] {
                    // Get UIDs that are not in HugRequestsSentManager.shared.hugRequestsSent
                    let newUIDs = hugRequestsSentStrings.filter { uid in
                        !HugRequestsSentManager.shared.hugRequestsSent.contains { $0.uid == uid }
                    }
                    
                    // Fetch documents for the new UIDs from the "hugrequests" collection
                    let hugRequestsCollectionRef = Firestore.firestore().collection("hugrequests")
                    var fetchedHugRequests: [HugRequest] = []
                    
                    // Create a dispatch group to track when all fetch operations are completed
                    let fetchGroup = DispatchGroup()
                    
                    for uid in newUIDs {
                        fetchGroup.enter() // Enter the dispatch group for this fetch operation
                        
                        hugRequestsCollectionRef.document(uid).getDocument { document, error in
                            defer {
                                fetchGroup.leave() // Leave the dispatch group when this fetch operation is completed
                            }
                            
                            if let error = error {
                                print("Error fetching hug request document with UID \(uid): \(error)")
                                return
                            }
                            
                            if let document = document, document.exists {
                                do {
                                    // Decode the fetched document into a HugRequest model
                                    let hugRequest = try document.data(as: HugRequest.self)
                                    // Append it to the fetchedHugRequests array
                                    fetchedHugRequests.append(hugRequest)
                                } catch {
                                    print("Error decoding hug request document with UID \(uid): \(error)")
                                }
                            }
                        }
                    }
                    
                    // Notify when all fetch operations are completed
                    fetchGroup.notify(queue: .main) {
                        // Append the fetched hug requests to HugRequestsSentManager.shared.hugRequestsSent
                        HugRequestsSentManager.shared.hugRequestsSent.append(contentsOf: fetchedHugRequests)
                        
                        // Filter out UIDs from HugRequestsSentManager.shared.hugRequestsSent
                        // that are not in hugRequestsSentStrings
                        HugRequestsSentManager.shared.hugRequestsSent = HugRequestsSentManager.shared.hugRequestsSent.filter { hugRequest in
                            hugRequestsSentStrings.contains(hugRequest.uid)
                        }
                        HugRequestsSentManager.shared.hugRequestsSent = Array(Set(HugRequestsSentManager.shared.hugRequestsSent))
                        HugRequestsSentManager.shared.hugRequestsSent = HugRequestsSentManager.shared.hugRequestsSent.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    }
                }
            }
            if let userDocListener = self.userDocListener {
                firestoreListenerManager.add(userDocListener)
            }
        }
    }
    
    func removeUserDocListener() {
        firestoreListenerManager.removeAllListeners()
    }
    
    
    func setupVCs() {
        viewControllers = [
            
            createNavController(for: ProfileViewVC(), title: NSLocalizedString("My Profile", comment: ""), image: UIImage(systemName: "person")!),
            createNavController(for: DiscoveryVC(), title: NSLocalizedString("Discovery", comment: ""), image: UIImage(systemName: "globe.europe.africa.fill")!),
            createNavController(for: InboxVC(), title: NSLocalizedString("Inbox", comment: ""), image: UIImage(systemName: "tray")!),
            createNavController(for: SearchVC(), title: NSLocalizedString("Search", comment: ""), image: UIImage(systemName: "magnifyingglass")!),
        ]
    }

        override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            updateInboxBadge()
        }
    
    func updateInboxBadge() {
        if let inboxTabBarItem = tabBar.items?[2] { // Assuming InboxVC is at index 2
            let notificationsCount = FriendRequestsReceivedManager.shared.friendRequestsReceived.count + HugRequestsReceivedManager.shared.hugRequestsReceived.count
            inboxTabBarItem.badgeValue = notificationsCount > 0 ? "\(notificationsCount)" : nil
        }
    }
    
}

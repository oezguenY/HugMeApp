//
//  InboxVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 16.08.22.
//

import UIKit
import Firebase
import FirebaseAuth
import Kingfisher

enum NotificationType: Equatable {
    case friendRequest(FriendRequest)
    case hugRequest(HugRequest)
}

class InboxVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MultiCamInheritanceVCDelegate {
    
    var inboxListener: ListenerRegistration?
    
    let firestoreListenerManager = FirestoreListenerManager.shared
    
    func didFinishPostingHug(success: Bool) {
        dismiss(animated: true) {
            if success {
                // Show success alert
                let alertController = UIAlertController(title: "Hug posted successfully!", message: nil, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Great!", style: .default, handler: { _ in
                    // Handle success if needed
                }))
                self.present(alertController, animated: true, completion: nil)
            } else {
                // Show error alert
                let title = "Hug Posting Error"
                let message = "Minimum 2 faces are required in the picture to post a Hug."
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Understood!", style: .default, handler: { _ in
                    // Handle error if needed
                }))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    
    
    var hugRequest: HugRequest?
    
    var tappedImageView: UIImageView?
    var displayedHugImageView: UIImageView?

    
    let tableView = UITableView()
    let firestoreUsersRef: CollectionReference = Constants.Collections.UsersCollectionRef
    var friendRequests = [FriendRequest?]()
    var hugRequests = [HugRequest?]()
    var notifications: [NotificationType] = []
    var swiftAppUser: AppUser?
    var someUser: AppUser?
    var snapshotListener: ListenerRegistration?
    
    //    func displayFriendRequestDeniedNotification() {
    //        // Create your notification content
    //        let notificationTitle = "Friend Request Denied"
    //        let notificationMessage = "Your friend request has been denied."
    //
    //        // Create and display the notification using your preferred method (e.g., a custom notification view)
    //        let notification = InAppNotification(title: notificationTitle, message: notificationMessage)
    //
    //        // Add the notification view to your view hierarchy or present it as needed
    //        self.view.addSubview(notification)
    //    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureTableView()
        self.tableView.register(InboxCell.self, forCellReuseIdentifier: InboxCell.identifier)
        self.setTableViewDelegate()
        self.saveFriendRequestsInNotifications()
        self.listenToNotifications()
      

        
    }
    
    func saveFriendRequestsInNotifications() {
        let friendRequests = FriendRequestsReceivedManager.shared.friendRequestsReceived
        let hugRequests = HugRequestsReceivedManager.shared.hugRequestsReceived
        let combinedNotifications = friendRequests.map { NotificationType.friendRequest($0) } +
        hugRequests.map { NotificationType.hugRequest($0) }
        let sortedNotifications = combinedNotifications.sortedByTimestamp()
        self.notifications = sortedNotifications
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listenToNotifications()
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayedHugImageView?.removeFromSuperview()
        displayedHugImageView = nil
        
        // Remove the tap gesture recognizer
        for gestureRecognizer in view.gestureRecognizers ?? [] {
            view.removeGestureRecognizer(gestureRecognizer)
        }
    }
    
    func listenToNotifications() {
        let docRef = firestoreUsersRef.document(Auth.auth().currentUser?.uid ?? "")
        
        if let inboxListener = self.inboxListener {
            firestoreListenerManager.remove(inboxListener)
        }
        
        inboxListener = docRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            
            guard let data = document.data() else {
                print("Document does not exist")
                return
            }
            
            guard let friendRequests = data["friendrequestsreceived"] as? [String] else { return }
            guard let hugRequests = data["hugrequestsreceived"] as? [String] else { return }
            
            // Create concurrent dispatch queues for friendRequests and hugRequests
            let friendRequestsQueue = DispatchQueue(label: "com.myapp.friendRequests", attributes: .concurrent)
            let hugRequestsQueue = DispatchQueue(label: "com.myapp.hugRequests", attributes: .concurrent)
            
            var friendRequestsNotifications: [FriendRequest] = []
            var hugRequestsNotifications: [HugRequest] = []
            
            // Use DispatchGroup to wait for both queues to finish
            let dispatchGroup = DispatchGroup()
            
            
            // Enter the DispatchGroup before processing friendRequests
            dispatchGroup.enter()
            friendRequestsQueue.async {
                self?.getFriendsDocuments(friendRequests: friendRequests) { friendRequests in
                    friendRequestsNotifications = friendRequests.compactMap { $0 }
                    FriendRequestsReceivedManager.shared.friendRequestsReceived = friendRequestsNotifications
                    dispatchGroup.leave()
                }
            }
            
            // Enter the DispatchGroup before processing hugRequests
            dispatchGroup.enter()
            hugRequestsQueue.async {
                self?.getHugRequestsDocuments(hugRequests: hugRequests) { hugRequests in
                    hugRequestsNotifications = hugRequests.compactMap { $0 }
                    HugRequestsReceivedManager.shared.hugRequestsReceived = hugRequestsNotifications
                    dispatchGroup.leave()
                }
            }
            
            // Notify when both queues are completed
            dispatchGroup.notify(queue: .main) {
                
                // Combine sorted friend requests and sorted hug requests notifications
                let combinedNotifications = friendRequestsNotifications.map { NotificationType.friendRequest($0) } +
                hugRequestsNotifications.map { NotificationType.hugRequest($0) }
                
                // Use sortedByTimestamp() on combinedNotifications
                let sortedNotifications = combinedNotifications.sortedByTimestamp()
                
                if let self = self, self.notifications != sortedNotifications {
                    print("THERE WERE CHANGES BECAUSE NOTIFICATIONS HAVE CHANGED")
                    self.notifications = sortedNotifications
                    self.tableView.reloadData()
                }
            }
        }
        if let inboxListener = self.inboxListener {
            firestoreListenerManager.add(inboxListener)
        }
        
    }
    
    func getHugRequestsDocuments(hugRequests: [String], completion: @escaping ([HugRequest?]) -> Void) {
        let hugRequestCollection = Constants.Collections.HugRequestsCollectionRef
        let dispatchGroup = DispatchGroup()
        var hugRequestsArray: [HugRequest?] = [] // Step 1: Create an array to store decoded FriendRequest instances
        
        for hugRequest in hugRequests {
            let documentRef = hugRequestCollection.document(hugRequest)
            
            dispatchGroup.enter()
            documentRef.getDocument { document, error in
                
                if let error = error {
                    print("Error getting document: \(error)")
                } else if let document = document, document.exists {
                    let data = document.data()
                    do {
                        // Step 2: Attempt to decode the data into FriendRequest using Firestore.Decoder
                        let hugRequest = try Firestore.Decoder().decode(HugRequest.self, from: data ?? [:])
                        // Step 3: Append the decoded FriendRequest to the array
                        hugRequestsArray.append(hugRequest)
                    } catch {
                        print("Error decoding document: \(error)")
                        // In case of decoding error, append nil to the array
                        hugRequestsArray.append(nil)
                    }
                }
                
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            // Step 4: Call the completion closure with the array of FriendRequest instances
            completion(hugRequestsArray)
        }
    }
    
    func getFriendsDocuments(friendRequests: [String], completion: @escaping ([FriendRequest?]) -> Void) {
        let friendReqsRef = Constants.Collections.FriendRequestsCollectionRef
        let dispatchGroup = DispatchGroup()
        var friendRequestArray: [FriendRequest?] = [] // Step 1: Create an array to store decoded FriendRequest instances
        
        for friendRequest in friendRequests {
            let documentRef = friendReqsRef.document(friendRequest)
            
            dispatchGroup.enter()
            documentRef.getDocument { document, error in
                
                if let error = error {
                    print("Error getting document: \(error)")
                } else if let document = document, document.exists {
                    let data = document.data()
                    
                    do {
                        // Step 2: Attempt to decode the data into FriendRequest using Firestore.Decoder
                        let friendRequest = try Firestore.Decoder().decode(FriendRequest.self, from: data ?? [:])
                        // Step 3: Append the decoded FriendRequest to the array
                        friendRequestArray.append(friendRequest)
                    } catch {
                        print("Error decoding document: \(error)")
                        // In case of decoding error, append nil to the array
                        friendRequestArray.append(nil)
                    }
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Step 4: Call the completion closure with the array of FriendRequest instances
            completion(friendRequestArray)
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let someText = searchController.searchBar.text else { return }
        self.searchUser(username: someText) { check in
            if check {
                print(someText)
            }
        }
    }
    
    func searchUser(username: String, completion: @escaping (Bool) -> Void) {
        
        let collectionRef = firestoreUsersRef
        
        collectionRef.whereField("username", isEqualTo: username).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                completion(false)
            } else {
                for document in (snapshot?.documents)! {
                    if document.data()["username"] != nil {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func configureTableView() {
        view.addSubview(tableView)
    }
    
    func setTableViewDelegate() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.frame
    }
    
    @objc func friendRequestAccepted(sender: UIButton) {
        print("friendRequestAccepted called")
        let index = sender.tag
        
        addedFriendToFirebase(index: index) {
            self.deleteFriendRequestFromFriendRequestArray(index: index) {
            }
                    // Once the friend request is removed from the array, proceed to the final step
            self.deleteFriendRequestFromFriendRequestsCollection(index: index) {
            }
        }
    }

    
    @objc func friendRequestDenied(sender: UIButton) {
        print("friendRequestDenied called")
        let index = sender.tag
        deleteFriendRequestFromFriendRequestArray(index: index) { }
        deleteFriendRequestFromFriendRequestsCollection(index: index) { }
    }
    
    @objc func hugRequestAccepted(sender: UIButton) {
        print("hugRequestAccepted called")
        let multiCamInheritanceVC = MultiCamInheritanceVC()
        multiCamInheritanceVC.delegate = self
        multiCamInheritanceVC.hugRequest = self.hugRequest
        multiCamInheritanceVC.modalPresentationStyle = .fullScreen
        present(multiCamInheritanceVC, animated: false)
    }
    
    
    @objc func hugRequestDenied(sender: UIButton) {
        print("hugRequestDenied called")
        let index = sender.tag
        self.deleteHugRequestFromUserDocument(index: index) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success():
                print("Hug request was deleted successfully from Receiver document.")
            case .failure(let error):
                print("Hug request could not be deleted from Receiver document: \(error)")
            }
        }
        
        self.deleteHugRequestFromSenderDocument(index: index) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success():
                print("Hug request was deleted successfully from Sender document.")
            case .failure(let error):
                print("Hug request could not be deleted from Sender document: \(error)")
            }
        }
        deleteHugRequestPictureFromStorage(index: index) { }
        deleteHugRequestFromHugRequestArray(index: index) { }
        deleteHugRequestFromHugRequestsCollection(index: index) { }
    }
    
    func addedFriendToFirebase(index: Int, completion: @escaping () -> ()) {
        print("1")
        guard let appUser = AppUserSingleton.shared.appUser else {
            print("No current appuser in InboxVC")
            completion()
            return
        }
        print("2")
        guard let documentPathOfCurrentAppUser = appUser.uid else {
            print("Current app user does not have a document uid.")
            completion()
            return
        }
        print("3")
        guard case let .friendRequest(friendRequest) = notifications[index] else {
            print("No friend request notification at index \(index)")
            completion()
            return
        }
        print("4")
        let friendUsername = friendRequest.senderUsername
        
        let usersRef = Constants.Collections.UsersCollectionRef
        
        // Update the "friends" array for the current app user
        usersRef.document(documentPathOfCurrentAppUser).updateData([
            Constants.Firebase.FRIENDS: FieldValue.arrayUnion([friendUsername])
        ]) { error in
            print("5")
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
                completion()
                return
            }
            
            // Once the update for the current app user is complete, proceed to the next operation
            self.queryFriendDocumentAndUpdate(index, friendUsername, completion: completion)
        }
    }

    func queryFriendDocumentAndUpdate(_ index: Int, _ friendUsername: String, completion: @escaping () -> ()) {
        guard let appUser = AppUserSingleton.shared.appUser else {
            print("No current appuser in InboxVC")
            completion()
            return
        }
        
        let usersRef = Constants.Collections.UsersCollectionRef
        
        // Query the Users collection to find the document with matching "username" field
        usersRef.whereField(Constants.Firebase.USERNAME, isEqualTo: friendUsername).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                completion()
                return
            }
            print("7")
            
            // Check if any matching document is found
            guard let document = querySnapshot?.documents.first else {
                print("No matching document found.")
                completion()
                return
            }
            print("8")
            
            // Update the "friends" array of the matching document to add appUser.username
            print("DOCUMENT UID: \(document.documentID)")
            document.reference.updateData([
                Constants.Firebase.FRIENDS: FieldValue.arrayUnion([appUser.userName])
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                } else {
                    print("\(appUser.userName) added successfully to the friends array of \(friendUsername).")
                }
                completion()
            }
        }
    }

    
    
//    func addedFriendToFirebase(index: Int, completion: @escaping () -> ()) {
//        print("1")
//        guard let appUser = AppUserSingleton.shared.appUser else {
//            print("No current appuser in InboxVC")
//            completion()
//            return
//        }
//        print("2")
//        guard let documentPathOfCurrentAppUser = appUser.uid else {
//            print("Current app user does not have a document uid.")
//            completion()
//            return
//        }
//        print("3")
//        guard case let .friendRequest(friendRequest) = notifications[index] else {
//            print("No friend request notification at index \(index)")
//            completion()
//            return
//        }
//        print("4")
//        let friendUsername = friendRequest.senderUsername
//        
//        let usersRef = Constants.Collections.UsersCollectionRef
//        
//        usersRef.document(documentPathOfCurrentAppUser).updateData([
//            Constants.Firebase.FRIENDS: FieldValue.arrayUnion([friendUsername])
//        ]) { error in
//            print("5")
//            if let error = error {
//                print("Error updating document: \(error.localizedDescription)")
//            } else {
//                print("Friend added successfully to the friends array.")
//            }
//            print("6")
//            
//            // Query the Users collection to find the document with matching "username" field
//            usersRef.whereField(Constants.Firebase.USERNAME, isEqualTo: friendUsername).getDocuments { (querySnapshot, error) in
//                if let error = error {
//                    print("Error fetching document: \(error.localizedDescription)")
//                    completion()
//                    return
//                }
//                print("7")
//                
//                // Check if any matching document is found
//                guard let document = querySnapshot?.documents.first else {
//                    print("No matching document found.")
//                    completion()
//                    return
//                }
//                print("8")
//                
//                // Update the "friends" array of the matching document to add appUser.username
//                print("DOCUMENT UID: \(document.documentID)")
//                document.reference.updateData([
//                    Constants.Firebase.FRIENDS: FieldValue.arrayUnion([appUser.userName])
//                ]) { error in
//                    if let error = error {
//                        print("Error updating document: \(error.localizedDescription)")
//                    } else {
//                        print("\(appUser.userName) added successfully to the friends array of \(friendUsername).")
//                    }
//                    completion()
//                }
//            }
//        }
//    }
    
    
    func deleteFriendRequestFromFriendRequestArray(index: Int, completion: @escaping () -> ()) {
        guard let appUser = AppUserSingleton.shared.appUser else {
            print("No current appuser in InboxVC")
            completion()
            return
        }
        
        guard let documentPathofCurrentAppUser = appUser.uid else {
            print("Current app user does not have a document uid")
            completion()
            return
        }
        
        let usersRef = Constants.Collections.UsersCollectionRef
        
        guard case let .friendRequest(friendRequest) = notifications[index] else {
            print("No friend request notification at index \(index)")
            completion()
            return
        }
        
        let friendRequestUID = friendRequest.uid
        let friendReq = friendRequest.senderUsername
        
        // Fetch the document
        usersRef.document(documentPathofCurrentAppUser).getDocument { querySnapshot, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                completion()
                return
            }
            
            // Safely unwrap the document data
            var data = querySnapshot?.data() ?? [String: Any]()
            
            // Safely unwrap the friendrequests array
            var friendRequests = data["friendrequests"] as? [String] ?? [String]()
            
            // Remove the friendRequestUID from the array
            if let index = friendRequests.firstIndex(of: friendRequestUID) {
                friendRequests.remove(at: index)
            }
            
            // Update the friend requests array in the document data
            data["friendrequestsreceived"] = friendRequests
            
            // Update the document in Firestore
            usersRef.document(documentPathofCurrentAppUser).setData(data) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                    completion()
                    return
                }
                
                // Fetch the sender's document using their username
                usersRef.whereField("username", isEqualTo: friendReq).getDocuments { querySnapshot, error in
                    if let error = error {
                        print("Error fetching sender's document: \(error.localizedDescription)")
                        completion()
                        return
                    }
                    
                    // Safely unwrap the sender's document data
                    guard let senderDocument = querySnapshot?.documents.first else {
                        print("Sender's document not found.")
                        completion()
                        return
                    }
                    
                    var senderData = senderDocument.data()
                    
                    // Safely unwrap the friendrequestssent array
                    var sentFriendRequests = senderData["friendrequestssent"] as? [String] ?? [String]()
                    
                    // Remove the friendRequestUID from the sender's "friendrequestssent" field
                    if let senderIndex = sentFriendRequests.firstIndex(of: friendRequestUID) {
                        sentFriendRequests.remove(at: senderIndex)
                    }
                    
                    // Update the sender's document with the modified "friendrequestssent" field
                    senderData["friendrequestssent"] = sentFriendRequests
                    
                    senderDocument.reference.setData(senderData) { error in
                        if let error = error {
                            print("Error updating sender's document: \(error.localizedDescription)")
                        } else {
                            print("Friend request deleted successfully.")
                        }
                        completion()
                    }
                }
            }
        }
    }
    
    
    func deleteFriendRequestFromFriendRequestsCollection(index: Int, completion: @escaping () -> ()) {
        let friendRequestsRef = Constants.Collections.FriendRequestsCollectionRef
        
        guard case let .friendRequest(friendRequest) = notifications[index] else {
            print("No friend request notification at index \(index)")
            completion()
            return
        }
        
        let friendRequestUID = friendRequest.uid
        
        friendRequestsRef.document(friendRequestUID).delete { error in
            if let error = error {
                print("Error deleting friend request document in friendrequests collection: \(error.localizedDescription)")
                completion()
            } else {
                print("Friend request document deleted successfully.")
                completion()
            }
            completion()
        }
    }
    
    func deleteHugRequestPictureFromStorage(index: Int, completion: @escaping () -> ()) {
        
        
        guard case let .hugRequest(hugRequest) = notifications[index] else {
            print("No friend request notification at index \(index)")
            completion()
            return
        }
        
        guard let hugImgURL = hugRequest.hugRequestImage, !hugImgURL.isEmpty else {
            completion()
            return
        }
        
        let storageRef = Storage.storage()
        let fileRef = storageRef.reference(forURL: hugImgURL)
        
        fileRef.delete { error in
            if let error = error {
                print("There was an error deleting the old profile image from firestore storage \(error.localizedDescription)")
                completion()
                return
            } else {
                completion()
            }
        }
    }
    
    func deleteHugRequestFromHugRequestArray(index: Int, completion: @escaping () -> ()) {
        guard let appUser = AppUserSingleton.shared.appUser else {
            print("No current appuser in InboxVC")
            completion()
            return
        }
        
        guard let documentPathofCurrentAppUser = appUser.uid else {
            print("Current app user does not have a document uid")
            completion()
            return
        }
        
        let usersRef = Constants.Collections.UsersCollectionRef
        
        guard case let .hugRequest(hugRequest) = notifications[index] else {
            print("No friend request notification at index \(index)")
            completion()
            return
        }
        
        let hugRequestUID = hugRequest.uid
        
        // Fetch the document
        usersRef.document(documentPathofCurrentAppUser).getDocument { querySnapshot, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                completion()
                return
            } else {
                if var data = querySnapshot?.data(),
                   var hugRequests = data["hugrequestsreceived"] as? [String] {
                    
                    // Remove the friendRequestUID from the array
                    if let index = hugRequests.firstIndex(of: hugRequestUID) {
                        hugRequests.remove(at: index)
                    }
                    
                    // Update the friend requests array in the document data
                    data[Constants.Firebase.HUGREQUESTS] = hugRequests
                    
                    // Update the document in Firestore
                    usersRef.document(documentPathofCurrentAppUser).setData(data) { error in
                        if let error = error {
                            print("Error updating document: \(error.localizedDescription)")
                        } else {
                            print("Hug request deleted successfully.")
                            
                        }
                        completion()
                    }
                } else {
                    print("Document data or friend requests array not found.")
                    completion()
                }
            }
        }
    }
    
    func deleteHugRequestFromHugRequestsCollection(index: Int, completion: @escaping () -> ()) {
        let hugCollectionRef = Constants.Collections.HugRequestsCollectionRef
        
        guard case let .hugRequest(hugRequest) = notifications[index] else {
            print("No friend request notification at index \(index)")
            completion()
            return
        }
        
        let hugRequestUID = hugRequest.uid
        
        hugCollectionRef.document(hugRequestUID).delete { error in
            if let error = error {
                print("Error deleting friend request document in friendrequests collection: \(error.localizedDescription)")
                completion()
            } else {
                print("Friend request document deleted successfully.")
                completion()
            }
            completion()
        }
    }
    
    func deleteHugRequestFromUserDocument(index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard case let .hugRequest(hugRequest) = notifications[index] else {
            let error = NSError(domain: "Invalid hugRequest", code: -1, userInfo: nil)
            print("No friend request notification at index \(index)")
            completion(.failure(error))
            return
        }
        // Check if hugRequest is nil or sender is nil
        let sender = hugRequest.sender
        let hugRequestUID = hugRequest.uid
        
        // Get the UID of the currently authenticated user
        if let currentUserUID = Auth.auth().currentUser?.uid {
            // Reference to the Firestore document for the current user
            let userDocRef = Firestore.firestore().collection("users").document(currentUserUID)
            
            // Update the "hugrequestsreceived" field to remove the specified hugRequestUID
            userDocRef.updateData([
                "hugrequestsreceived": FieldValue.arrayRemove([hugRequestUID])
            ]) { error in
                if let error = error {
                    print("Error removing hug request from user document: \(error)")
                    completion(.failure(error))
                    return
                } else {
                    print("Hug request removed from user document successfully.")
                    completion(.success(()))
                }
            }
        } else {
            // Handle the case where the user is not authenticated
            let error = NSError(domain: "User not authenticated", code: -1, userInfo: nil)
            completion(.failure(error))
            return
        }
    }
    
    func deleteHugRequestFromSenderDocument(index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard case let .hugRequest(hugRequest) = notifications[index] else {
            let error = NSError(domain: "Invalid hugRequest", code: -1, userInfo: nil)
            print("No friend request notification at index \(index)")
            completion(.failure(error))
            return
        }
        // Check if hugRequest is nil or sender is nil
        let sender = hugRequest.sender
        let hugRequestUID = hugRequest.uid
        
        let usersCollectionRef = Firestore.firestore().collection("users")
        
        // Query for the user document with the matching sender username
        usersCollectionRef.whereField("username", isEqualTo: sender).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let document = snapshot?.documents.first {
                let documentID = document.documentID
                var hugRequestsSentStrings = document["hugrequestssent"] as? [String] ?? []
                
                // Remove the hugRequestUID from the hugRequestsSentStrings array
                hugRequestsSentStrings.removeAll { $0 == hugRequestUID }
                
                // Update the user document with the modified hugRequestsSentStrings
                usersCollectionRef.document(documentID).updateData(["hugrequestssent": hugRequestsSentStrings]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                let error = NSError(domain: "Sender document not found", code: -1, userInfo: nil)
                completion(.failure(error))
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard case let .hugRequest(hugRequest) = notifications[indexPath.row] else {
            return
        }
        
        guard let hugImgURL = hugRequest.hugRequestImage, !hugImgURL.isEmpty else {
            return
        }
        
        // Create and show a loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        
        // Fetch the image from Firebase Storage
        let storageRef = Storage.storage().reference(forURL: hugImgURL)
        storageRef.getData(maxSize: 10 * 1024 * 1024) { [weak self] data, error in
            DispatchQueue.main.async {
                // Remove the loading indicator
                loadingIndicator.removeFromSuperview()
                
                if let error = error {
                    print("Error fetching image from Firebase Storage: \(error.localizedDescription)")
                    return
                }
                
                if let imageData = data, let image = UIImage(data: imageData) {
                    let fullScreenVC = FullScreenHugVC()
                    let snapDataInstance = SnapData(text: hugRequest.description, position: hugRequest.textLocation ?? CGPoint(), image: image)
                    fullScreenVC.senderScreenWidth = hugRequest.senderScreenWidth
                    fullScreenVC.senderScreenHeight = hugRequest.senderScreenHeight
                    fullScreenVC.snapData = snapDataInstance
                    fullScreenVC.modalPresentationStyle = .fullScreen
                    self?.present(fullScreenVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AppDelegate.screenHeight / 11
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InboxCell.identifier, for: indexPath) as! InboxCell
        cell.contentView.isUserInteractionEnabled = false
        let friendRequestTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameLabelTapped))
        let hugRequestTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameLabelTapped))
        let notification = notifications[indexPath.row]
        
        print("INDEX PATH. ROW: \(indexPath.row)")
        
        switch notification {
        case .friendRequest(let friendRequest):
            let profileimgurl = friendRequest.pictureURL
            if !profileimgurl.isEmpty {
                let url = URL(string: profileimgurl)
                cell.profileImageView.kf.setImage(with: url)
            } else {
                cell.profileImageView.image = UIImage.extractFirstFrameFromGIF(named: "gif17")
            }
            
            cell.usernameLbl.text = friendRequest.senderUsername
            cell.usernameLbl.isUserInteractionEnabled = true
            cell.usernameLbl.addGestureRecognizer(friendRequestTapGesture)
            cell.inboxLbl.text = "wants to be your friend"
            cell.acceptRequestBtn.tag = indexPath.row
            cell.denyRequestBtn.tag = indexPath.row
            cell.acceptRequestBtn.removeTarget(nil, action: nil, for: .allEvents)
            cell.acceptRequestBtn.addTarget(self, action: #selector(friendRequestAccepted(sender:)), for: .touchUpInside)
            cell.denyRequestBtn.removeTarget(nil, action: nil, for: .allEvents)
            cell.denyRequestBtn.addTarget(self, action: #selector(friendRequestDenied(sender:)), for: .touchUpInside)
            cell.gifImage.isHidden = true
            cell.acceptRequestBtn.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
            cell.acceptRequestBtn.setBackgroundImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            cell.denyRequestBtn.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
            cell.backgroundColor = .clear
            cell.timestampLbl.text = friendRequest.formattedTimestamp
            
            
        case .hugRequest(let hugRequest):
            print("CASE HUGREQUEST IS CALLED: \(hugRequest)")
            if let profileimgurl = hugRequest.senderProfileImgUrl, !profileimgurl.isEmpty {
                if let url = URL(string: profileimgurl) {
                    cell.profileImageView.kf.setImage(with: url)
                }
            } else {
                cell.profileImageView.image = UIImage.extractFirstFrameFromGIF(named: "gif17")
            }
            

            self.hugRequest = hugRequest
            cell.usernameLbl.text = hugRequest.sender
            cell.usernameLbl.isUserInteractionEnabled = true
            cell.usernameLbl.addGestureRecognizer(hugRequestTapGesture)
            cell.inboxLbl.text = "wants a hug"
            cell.acceptRequestBtn.tag = indexPath.row
            cell.denyRequestBtn.tag = indexPath.row
            cell.acceptRequestBtn.removeTarget(nil, action: nil, for: .allEvents)
            cell.acceptRequestBtn.addTarget(self, action: #selector(hugRequestAccepted(sender:)), for: .touchUpInside)
            cell.denyRequestBtn.removeTarget(nil, action: nil, for: .allEvents)
            cell.denyRequestBtn.addTarget(self, action: #selector(hugRequestDenied(sender:)), for: .touchUpInside)
            cell.acceptRequestBtn.tintColor = .white
            cell.acceptRequestBtn.setBackgroundImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
            cell.denyRequestBtn.tintColor = .white
            cell.timestampLbl.text = hugRequest.formattedTimestamp
            cell.backgroundColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
            cell.gifImage.isHidden = false
            cell.gifImage.loadGif(name: "\(hugRequest.gif ?? "")")
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gifImageTapped(sender:)))
            cell.gifImage.addGestureRecognizer(tapGesture)
            cell.gifImage.isUserInteractionEnabled = true
             
        }
        return cell
    }
    
    @objc func gifImageTapped(sender: UITapGestureRecognizer) {
        guard let gifImageView = sender.view as? UIImageView, let image = gifImageView.image else {
            return
        }
        
        // Dismiss any currently displayed hug image view
        displayedHugImageView?.removeFromSuperview()
        
        // Create an image view to display the tapped image
        let tappedImageView = UIImageView(image: image)
        tappedImageView.frame = CGRect(x: 0, y: 0, width: AppDelegate.screenWidth / 2, height: AppDelegate.screenWidth / 2) // Set your desired frame
        tappedImageView.center = view.center
        tappedImageView.contentMode = .scaleAspectFit
        tappedImageView.layer.cornerRadius = 10
        tappedImageView.clipsToBounds = true
        view.addSubview(tappedImageView)
        
        // Set the currently displayed hug image view
        displayedHugImageView = tappedImageView
        
        // Add a tap gesture recognizer to dismiss the image view
        let tapToDismissGesture = UITapGestureRecognizer(target: self, action: #selector(dismissTappedImage))
        view.addGestureRecognizer(tapToDismissGesture)
    }
    
    
    @objc func dismissTappedImage() {
        // Remove the displayed hug image view
        displayedHugImageView?.removeFromSuperview()
        displayedHugImageView = nil
        
        // Remove the tap gesture recognizer
        for gestureRecognizer in view.gestureRecognizers ?? [] {
            view.removeGestureRecognizer(gestureRecognizer)
        }
    }
    
    
    @objc func usernameLabelTapped(_ sender: UITapGestureRecognizer) {
        // Ensure that the tapped label is of type UILabel
        guard let label = sender.view as? UILabel else {
            return
        }
        
        // Get the sender's username from receivedHugPosts
        guard let senderUsername = label.text, !senderUsername.isEmpty else { return }

        // Fetch the user document based on sender's username
        fetchAppUserByUsername(senderUsername) { result in
            switch result {
            case .success(let tappedUser):
                self.transitionToTappedUser(tappedUser: tappedUser)
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                return
            }
        }
        
    }
    
    func fetchAppUserByUsername(_ username: String, completion: @escaping (Result<AppUser, Error>) -> Void) {
            let usersCollectionRef = Firestore.firestore().collection("users")
            
            // Query for the user document with the given username
            usersCollectionRef.whereField("username", isEqualTo: username).getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    // No matching document found
                    completion(.failure(NSError(domain: "AppUserNotFound", code: 404, userInfo: nil)))
                    return
                }
                
                do {
                    // Decode the document data into an AppUser object
                    let appUser = try document.data(as: AppUser.self)
                        completion(.success(appUser))
                } catch {
                    // Error decoding the document data
                    completion(.failure(error))
                }
            }
        }
    
    
    func transitionToTappedUser(tappedUser: AppUser?) {
        let searchedUserVC = SearchedUserVC()
        let navController = UINavigationController(rootViewController: searchedUserVC)
        
        
        guard let searchingForUser = tappedUser else { return }
        searchedUserVC.navTitle = "@\(searchingForUser.userName) "
        searchedUserVC.searchedUser = searchingForUser
        searchedUserVC.isProfileVC = false
        if searchedUserVC.searchedUser?.userName == AppUserSingleton.shared.appUser?.userName {
            searchedUserVC.isOwnProfile = true
        }
        fetchSearchedUserHugPostsGotten(searchedUser: searchingForUser) { searchedUserHugsGotten, error in
            if let error = error {
                print("Error fetching hug posts of searched user: \(error.localizedDescription)")
            }
            let sortedHugs = searchedUserHugsGotten.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            searchedUserVC.searchedUsersHugs = sortedHugs
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true)
        }
    }
    
//    
//    func fetchSearchedUserReceivedHugPosts(searchedUser: AppUser, completion: @escaping ([Hug]) -> ()) {
//        let receivedPosts = searchedUser.hugsGotten
//        
//        var fetchedHugPosts: [Hug] = []
//        
//        guard !receivedPosts.isEmpty else {
//            // If there are no received posts, return an empty array immediately
//            completion([])
//            return
//        }
//        
//        let dispatchGroup = DispatchGroup()
//        
//        for documentID in receivedPosts {
//            dispatchGroup.enter()
//            
//            Constants.Collections.HugPostsRef.document(documentID ?? "").getDocument { (document, error) in
//                defer {
//                    dispatchGroup.leave()
//                }
//                
//                if let error = error {
//                    print("Error fetching document with ID \(documentID ?? ""): \(error.localizedDescription)")
//                    return
//                }
//                
//                if let documentData = document?.data() {
//                    do {
//                        let decoder = Firestore.Decoder()
//                        let hug = try decoder.decode(Hug.self, from: documentData)
//                        fetchedHugPosts.append(hug)
//                    } catch {
//                        print("Error decoding document with ID \(documentID ?? ""): \(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//        
//        dispatchGroup.notify(queue: .main) {
//            completion(fetchedHugPosts)
//        }
//    }
    
    func fetchSearchedUserHugPostsGotten(searchedUser: AppUser, completion: @escaping ([Hug], Error?) -> ()) {
        let dispatchGroup = DispatchGroup()
        var searchedUserHugPostsGotten: [Hug] = []
        var hugErrorOccurred: Error?
        var lastDocument: QueryDocumentSnapshot?

        let username = searchedUser.userName

        dispatchGroup.enter()

        Constants.Collections.HugPostsRef
            .whereField("receiverUsername", isEqualTo: username) // Filter by friend usernames
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { hugQuerySnapshot, hugError in
                if let hugError = hugError {
                    hugErrorOccurred = hugError
                    print("Error fetching friend's hug posts: \(hugError)")
                } else {
                    for hugDocument in hugQuerySnapshot!.documents {
                        do {
                            let friendHugPost = try Firestore.Decoder().decode(Hug.self, from: hugDocument.data())
                            searchedUserHugPostsGotten.append(friendHugPost)
                        } catch {
                            print("Error decoding friend's hug post document: \(error.localizedDescription)")
                        }
                        lastDocument = hugDocument
                        PaginationSearchedUserHugPostsManager.shared.lastDocumentRef = lastDocument
                    }

                    dispatchGroup.leave()
                }
            }

        dispatchGroup.notify(queue: .main) {
            if let error = hugErrorOccurred {
                completion([], error)
            } else {
                completion(searchedUserHugPostsGotten, nil)
            }
        }

    }
   
    
}

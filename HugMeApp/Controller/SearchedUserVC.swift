//
//  SearchedUserVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 15.03.23.
//

import UIKit
import Firebase
import AVFoundation
import Kingfisher

class SearchedUserVC: ProfileViewVC, SelectGIFVCDelegate {
    func hugRequestSent(success: Bool) {
        dismiss(animated: true) {
            if success {
                // Show success alert
                let alertController = UIAlertController(title: "Hug sent successfully!", message: nil, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Great!", style: .default, handler: { _ in
                    // Handle success if needed
                }))
                self.present(alertController, animated: true, completion: nil)
            } else {
                // Show error alert
                let alertController = UIAlertController(title: "Hug couldn't be sent. There was an error. Try again later.", message: nil, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Understood!", style: .default, handler: { _ in
                    // Handle error if needed
                }))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    enum SearchedUserFriendshipInteractionState {
        case friends
        case receivedRequest
        case sentRequestToCurrentUser
        case noInteractionYet
    }
    
    enum SearchedUserHugInteractionState {
        case sentHugRequestToCurrentUser
        case receivedHugRequest
        case noHugInteractionYet
    }
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    var searchedUserPaginationReference: QueryDocumentSnapshot?
    var isFetchingPosts = false
    var isLoadingMorePosts = false
    var searchedUsersHugs: [Hug]?
    
    var searchedUserCell: ProfileTableViewCell?
    
    var friendshipInteractionState: SearchedUserFriendshipInteractionState = .noInteractionYet
    var hugInteractionState: SearchedUserHugInteractionState = .noHugInteractionYet
    
    var isSendingRequest = false
    var addButton: UIButton = UIButton()
    var navTitle: String?
    
    var personAdded: Bool?
    var searchedUser: AppUser?
    //    var isOwnProfile = false
    var actionSheet: UIAlertController?
    
    override func viewDidLoad() {
        setupUI()
        determineInteractionState()
        // Create a custom back button
        let backButton = UIButton(type: .custom)
        backButton.frame = CGRect(x: 0.0, y: 0.0, width: 40, height: 40)
        backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Create a UIBarButtonItem with the custom button
        let customBackButton = UIBarButtonItem(customView: backButton)
        
        // Assign the custom button to the left navigation bar button item
        navigationItem.leftBarButtonItem = customBackButton
        
        searchedUserPaginationReference = PaginationSearchedUserHugPostsManager.shared.lastDocumentRef
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        determineInteractionState()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //        KingfisherManager.shared.cache.clearMemoryCache()
        //        KingfisherManager.shared.cache.clearDiskCache()
        displayedHugImageView?.removeFromSuperview()
        displayedHugImageView = nil
        // Remove the tap gesture recognizer
        for gestureRecognizer in view.gestureRecognizers ?? [] {
            view.removeGestureRecognizer(gestureRecognizer)
        }
    }
    
    @objc func backButtonTapped() {
        // Dismiss the current view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func setUIElements(cell: ProfileTableViewCell) {
        guard let appUser = searchedUser else {
            print("No app user in ProfileVC")
            return
        }
        let profileImgURL = appUser.profileImageURL
        if !profileImgURL.isEmpty {
            let url = URL(string: profileImgURL)
            cell.profileImageView.kf.setImage(with: url)
        } else {
            cell.profileImageView.image = UIImage.extractFirstFrameFromGIF(named: "gif17")
        }
        
        switch friendshipInteractionState {
        case .friends:
            // Update UI for friends
            cell.addFriendBtn.setTitle("Friends", for: .normal)
            cell.addFriendBtn.isEnabled = false
            cell.sendHugRequestBtn.addTarget(self, action: #selector(transitionToMultiCamVC), for: .touchUpInside)
            cell.sendHugRequestBtn.alpha = 1
            cell.sendHugRequestBtn.isEnabled = true
            // Update other UI elements accordingly
        case .receivedRequest:
            // Update UI for received friend request
            cell.addFriendBtn.setTitle("Requested", for: .normal)
            cell.addFriendBtn.isEnabled = false
            cell.sendHugRequestBtn.alpha = 0.4
            // Update other UI elements accordingly
        case .sentRequestToCurrentUser:
            // Update UI for sent friend request
            cell.addFriendBtn.setTitle("Requested", for: .normal)
            cell.addFriendBtn.isEnabled = false
            cell.sendHugRequestBtn.alpha = 0.4
            //             Update other UI elements accordingly
        case .noInteractionYet:
            // Update UI for no interaction
            cell.addFriendBtn.setTitle("Add Friend", for: .normal)
            cell.addFriendBtn.isEnabled = true
            cell.sendHugRequestBtn.alpha = 0.4
            // Update other UI elements accordingly
        }
        
        switch hugInteractionState {
        case .receivedHugRequest:
            cell.sendHugRequestBtn.alpha = 0.4
            cell.sendHugRequestBtn.isEnabled = false
            cell.sendHugRequestBtn.setTitle("Hug Requested", for: .normal)
        case .sentHugRequestToCurrentUser:
            cell.sendHugRequestBtn.alpha = 0.4
            cell.sendHugRequestBtn.isEnabled = false
            cell.sendHugRequestBtn.setTitle("Hug Received", for: .normal)
        case .noHugInteractionYet:
            if FriendsManager.shared.friends.contains(where: { $0.userName == searchedUser?.userName }) {
                cell.sendHugRequestBtn.alpha = 1.0
                cell.sendHugRequestBtn.isEnabled = true
                cell.sendHugRequestBtn.setTitle("Send Hug", for: .normal)
            } else {
                cell.sendHugRequestBtn.alpha = 0.4
                cell.sendHugRequestBtn.isEnabled = false
                cell.sendHugRequestBtn.setTitle("Send Hug", for: .normal)
            }
            
        }
        
        cell.fullNameLbl.text = appUser.fullName
        cell.usernameLbl.text = "@\(appUser.userName)"
        cell.friendsAmountLbl.text = String(appUser.friends.count)
        cell.hugsReceivedAmountLbl.text = String(appUser.hugsGotten.count)
        cell.hugsGiveAmountnLbl.text = String(appUser.hugsGiven.count)
        cell.addFriendBtn.addTarget(self, action: #selector(addFriendTapped), for: .touchUpInside)
    }
    
    @objc func addFriendTapped() {
        sendFriendRequest()
    }
    
    
    func determineInteractionState() {
        let friends = FriendsManager.shared.friends.compactMap({ $0.userName })
        let friendRequestsReceived = FriendRequestsReceivedManager.shared.friendRequestsReceived.compactMap({ $0.senderUsername })
        let friendRequestsSentSenderUsername = FriendRequestsSentManager.shared.friendRequestsSent.compactMap({ $0.senderUsername })
        let friendRequestsSentReceiverUsername = FriendRequestsSentManager.shared.friendRequestsSent.compactMap({ $0.receiverUsername })
        let hugRequestsSent = HugRequestsSentManager.shared.hugRequestsSent.compactMap { $0.receiver }
        let hugRequestsReceived = HugRequestsReceivedManager.shared.hugRequestsReceived.compactMap { $0.sender }
        
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName, let searchedUserUsername = searchedUser?.userName else { return }

        if friends.contains(searchedUserUsername) {
            friendshipInteractionState = .friends
        } else if friendRequestsReceived.contains(searchedUserUsername) {
            friendshipInteractionState = .sentRequestToCurrentUser
        } else if friendRequestsSentSenderUsername.contains(currentUserUsername) && friendRequestsSentReceiverUsername.contains(searchedUserUsername) {
            friendshipInteractionState = .receivedRequest
        } else {
            friendshipInteractionState = .noInteractionYet
        }
        
        if hugRequestsSent.contains(searchedUserUsername) {
            hugInteractionState = .receivedHugRequest
        } else if hugRequestsReceived.contains(searchedUserUsername) {
            hugInteractionState = .sentHugRequestToCurrentUser
        } else {
            hugInteractionState = .noHugInteractionYet
        }
    }
    
    func sendFriendRequest() {
        guard let searchedUserFCMtoken = self.searchedUser?.fcmToken else { return }
        if friendshipInteractionState == .noInteractionYet {
            guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName,
                  let currentUserUID = AppUserSingleton.shared.appUser?.uid,
                  let searchedUserUsername = searchedUser?.userName,
                  let searchedUserUID = searchedUser?.uid,
                  let currentUserProfileImageURL = AppUserSingleton.shared.appUser?.profileImageURL else {
                return
            }
            
            // Create a reference to the Firestore database
            let db = Firestore.firestore()
            
            // Create a reference to the "friendrequests" collection
            let friendRequestsCollection = db.collection("friendrequests")
            
            // Add an empty document to the "friendrequests" collection
            let newFriendRequestDocument = friendRequestsCollection.document()
            
            // Obtain the document ID of the newly created document
            let friendRequestDocumentID = newFriendRequestDocument.documentID
            
            // Create a friend request instance with the document ID
            let friendRequest = FriendRequest(friendRequestSenderUID: currentUserUID,
                                              friendRequestReceiverUID: searchedUserUID,
                                              senderUsername: currentUserUsername,
                                              receiverUsername: searchedUserUsername,
                                              timestamp: Timestamp(date: Date()),
                                              pictureURL: currentUserProfileImageURL,
                                              uid: friendRequestDocumentID)
            
            // Encode and set the friend request instance in the document
            newFriendRequestDocument.setData(try! Firestore.Encoder().encode(friendRequest)) { err in
                if let err = err {
                    print("Error setting document: \(err)")
                } else {
                    print("Friend request sent successfully!")
                    
                    // Insert the friend request at the top of the sent requests array
                    //                    FriendRequestsSentManager.shared.friendRequestsSent.insert(friendRequest, at: 0)
                    
                    self.updateSearchedUserDocument(withFriendRequestUID: friendRequest.uid)
                    self.updateOwnUsersDocument(withFriendRequestUID: friendRequest.uid)
                    self.sendPushNotification(toToken: searchedUserFCMtoken, withMessage: "You received a friend request by \(currentUserUsername)", badgeCount: 1)
                    // Searched User received the request
                    self.friendshipInteractionState = .receivedRequest
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func updateOwnUsersDocument(withFriendRequestUID uid: String) {
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            return
        }

        let usersCollection = Firestore.firestore().collection("users")
        let searchedUserDocRef = usersCollection.whereField("username", isEqualTo: currentUserUsername)

        searchedUserDocRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching searched user's document: \(error)")
                return
            }

            guard let document = querySnapshot?.documents.first else {
                print("Searched user's document not found")
                return
            }

            // Update the "friendrequests" array field in the searched user's document
            usersCollection.document(document.documentID).updateData([
                "friendrequestssent": FieldValue.arrayUnion([uid])
            ]) { error in
                if let error = error {
                    print("Error updating searched user's document: \(error)")
                } else {
                    print("Friend request added to searched user's document")
                }
            }
        }
        
    }
    
    func updateSearchedUserDocument(withFriendRequestUID uid: String) {
        guard let searchedUserUsername = searchedUser?.userName else {
            return
        }

        let usersCollection = Firestore.firestore().collection("users")
        let searchedUserDocRef = usersCollection.whereField("username", isEqualTo: searchedUserUsername)
        
        searchedUserDocRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching searched user's document: \(error)")
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                print("Searched user's document not found")
                return
            }
            // Update the "friendrequests" array field in the searched user's document
            usersCollection.document(document.documentID).updateData([
                "friendrequestsreceived": FieldValue.arrayUnion([uid])
            ]) { error in
                if let error = error {
                    print("Error updating searched user's document: \(error)")
                } else {
                    print("Friend request added to searched user's document")
                }
            }
        }
    }

    @objc func transitionToMultiCamVC() {
        let multiCamVC = MultiCamVC()
        multiCamVC.searchedUser = self.searchedUser
        multiCamVC.searchedUserVC = self
        multiCamVC.modalPresentationStyle = .fullScreen
        self.present(multiCamVC, animated: true)
    }

    func changeAddFriendButton(completion: ((UIImage) -> Void)?) {
        self.addButton.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        self.addButton.tintColor = .black
    }
    

    func sendPushNotification(toToken token: String, withMessage message: String, badgeCount: Int) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        guard let url = URL(string: urlString) else {
            return
        }
        
        let headers: [String: String] = [
            "Authorization": SensitiveData.SERVER_KEY, // Your actual server key
            "Content-Type": "application/json"
        ]
        
        let notification: [String: Any] = [
            "title": "New Friend Request",
            "body": message,
            "badge": badgeCount
        ]
        
        let data: [String: Any] = [
            "to": token,
            "notification": notification
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending push notification: \(error)")
                // Handle the error appropriately.
                return
            }
            
            // Handle the response if needed.
        }
        
        task.resume()
    }
    
    @objc func actionSheetBackgroundTapped()
    {
        self.actionSheet?.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func searchedUserFriendsTapped() {
        guard let searchedUser = self.searchedUser else {
            return
        }

        // Create an empty array to store the friend usernames
        var friendUsernames: [String] = []

        // Get a reference to the Firestore users collection
        let usersCollection = Firestore.firestore().collection("users")

        // Fetch the document of the searched user
        if let searchedUserUID = searchedUser.uid {
            usersCollection.document(searchedUserUID).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching user document: \(error.localizedDescription)")
                    return
                }
            

                if let document = document, document.exists {
                
                    if let friends = document.data()?["friends"] as? [String] {
                    
                        friendUsernames = friends
                        // Fetch users with matching usernames
                        self.fetchUsersWithUsernames(usernames: friendUsernames) { friendUsers in
                        
                            let friendListVC = FriendListVC()
                        
                            friendListVC.friendList = friendUsers.sorted(by: { $0.userName < $1.userName })
                        
                            let navigationController = UINavigationController(rootViewController: friendListVC) // Embed in a navigation controller
                        
                            friendListVC.modalPresentationStyle = .fullScreen
                        
                            self.present(navigationController, animated: true)
                        
                        }
                    }
                }
            }
        }
    }

    func fetchUsersWithUsernames(usernames: [String], completion: @escaping ([AppUser]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var foundUsers: [AppUser] = []

        for username in usernames {
            dispatchGroup.enter()

            Constants.Collections.UsersCollectionRef
                .whereField("username", isEqualTo: username)
                .getDocuments { (querySnapshot, error) in
                    defer {
                        dispatchGroup.leave()
                    }

                    guard let documents = querySnapshot?.documents, error == nil else {
                        print("Error fetching documents for username \(username): \(error?.localizedDescription ?? "")")
                        return
                    }

                    for document in documents {
                        do {
                            let appUser = try document.data(as: AppUser.self)
                            foundUsers.append(appUser)
                        } catch {
                            print("Error decoding document for username \(username): \(error.localizedDescription)")
                        }
                    }
                }
        }

        dispatchGroup.notify(queue: .main) {
            completion(foundUsers)
        }
    }




    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            // Height of the first cell (40% of view height)
            if isOwnProfile {
                return view.bounds.height * 0.32
            } else {
                return view.bounds.height * 0.4
            }
            
        } else {
            if isOwnProfile {
                return view.bounds.height * 0.68
            } else {
                return view.bounds.height * 0.6
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max((searchedUsersHugs?.count ?? 0) + 1, 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as! ProfileTableViewCell
            self.searchedUserCell = cell
            setUIElements(cell: cell)
            hideAndDisableButtons(cell: cell)
            let friendsAmountLblTapGesture = UITapGestureRecognizer(target: self, action: #selector(searchedUserFriendsTapped))
            cell.stackView3.addGestureRecognizer(friendsAmountLblTapGesture)
            cell.stackView3.isUserInteractionEnabled = true
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoveryCell.identifier, for: indexPath) as! DiscoveryCell
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(usernameLabelTapped))
            let tapGestureTwo = UITapGestureRecognizer(target: self, action: #selector(usernameLabelTapped))
            let hugIndex = indexPath.row - 1 // Adjust the index to match the receivedHugPosts array
            cell.usernameLbl.text = searchedUsersHugs?[hugIndex].receiverUsername
            cell.usernameLbl.isUserInteractionEnabled = true
            cell.usernameLbl.addGestureRecognizer(tapGestureTwo)
            
            
            if let profileimgurl = searchedUsersHugs?[hugIndex].receiverImageUrl, !profileimgurl.isEmpty {
                let url_1 = URL(string: profileimgurl)
                cell.profileImg.kf.setImage(with: url_1)
            } else {
                cell.profileImg.image = UIImage.extractFirstFrameFromGIF(named: "gif17")
            }
            
            let hugImgurl = searchedUsersHugs?[hugIndex].hugPicture
            let url_2 = URL(string: hugImgurl ?? "")
            cell.hugImg.kf.setImage(with: url_2)
            cell.gifImageView.loadGif(name: searchedUsersHugs?[hugIndex].gif ?? "")
            cell.usernameOfPersonTwoLbl.text = searchedUsersHugs?[hugIndex].senderUsername
            cell.usernameOfPersonTwoLbl.isUserInteractionEnabled = true
            cell.usernameOfPersonTwoLbl.addGestureRecognizer(tapGestureRecognizer)
            cell.timestampLbl.text = searchedUsersHugs?[hugIndex].formattedTimestamp
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gifImageTapped(sender:)))
            cell.gifImageView.addGestureRecognizer(tapGesture)
            cell.gifImageView.isUserInteractionEnabled = true
            cell.imageOptionsBtn.isHidden = true
            cell.imageOptionsBtn.isEnabled = false
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard let searchedUserHugs = self.searchedUsersHugs, !searchedUserHugs.isEmpty else {
            return
        }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.size.height
        
        // Check if the user has scrolled to the bottom and isLoading is false
        if offsetY > contentHeight - screenHeight, !isLoadingMorePosts {
            print("IS LOADING NEW HUG POSTS!")
            loadSearchedUsersHugsGotten() // Load more friends' posts
        }
    }
    
    func loadSearchedUsersHugsGotten() {
        
        guard !isFetchingPosts else {
            
            return // Prevent multiple requests while one is already in progress
        }
        
        
        isFetchingPosts = true
        isLoadingMorePosts = true // Set isLoadingMore to true to prevent multiple calls
        
        activityIndicator.startAnimating()
        
        guard let paginationReference = self.searchedUserPaginationReference else {
            
            isFetchingPosts = false
            isLoadingMorePosts = false // Reset isLoadingMore
            return
        }
        
        
        PaginationSearchedUserHugPostsManager.shared.fetchMorePostsOfSearchedUser(searchedUserUsername: searchedUser?.userName ?? "", lastDocumentReference: paginationReference) { hugPosts, referenceToLastPost, error in
            if let error = error {
                print("There was an error: \(error.localizedDescription)")
                
                self.activityIndicator.stopAnimating()
                return
            } else {
                
                // MARK: - REFERNCETOLASTPOST IS NIL BUG!!!!!!!
                if referenceToLastPost == nil {
                    self.isFetchingPosts = false
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }
                    
                    return
                }
                
                self.searchedUsersHugs?.append(contentsOf: hugPosts)
                self.searchedUserPaginationReference = referenceToLastPost
                
                print("PAGINATION REFERNCE FRIENDS: \(paginationReference.documentID)")
                PaginationHugPostsFriendsManager.shared.lastDocumentRef = referenceToLastPost
                
                DispatchQueue.main.async {
                    
                    self.tableView.reloadData()
                }
            }
            
            self.isFetchingPosts = false
            self.isLoadingMorePosts = false // Reset isLoadingMore
            self.activityIndicator.stopAnimating()
        }
        
        
    }
    
    @objc override func usernameLabelTapped(_ sender: UITapGestureRecognizer) {
        // Ensure that the tapped label is of type UILabel
        guard let label = sender.view as? UILabel else {
            return
        }
        
        // Get the sender's username from receivedHugPosts
        guard let senderUsername = label.text, !senderUsername.isEmpty else { return }
        
        guard searchedUser?.userName != senderUsername else {
            return
        }
        
        
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
    
    
}



//
//  FriendListVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 05.11.23.
//

import UIKit
import Firebase
import Kingfisher
import FirebaseFirestore

class FriendListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    var friendList: [AppUser]? = []
    
    private func addSubviews() {
        view.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.frame
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AppDelegate.screenHeight / 11
    }
    
    private func registerCell() {
        tableView.register(FriendCell.self, forCellReuseIdentifier: FriendCell.identifier)
    }
    
    private func setDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setDelegates()
        registerCell()
        
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissButtonTapped))
               navigationItem.leftBarButtonItem = dismissButton
    }
    
    @objc func dismissButtonTapped() {
           self.dismiss(animated: true, completion: nil)
       }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return friendList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let friendList = friendList else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendCell.identifier, for: indexPath) as! FriendCell
        let friend = friendList[indexPath.row]
        let profileImgURL = friend.profileImageURL
        if !profileImgURL.isEmpty {
            let url = URL(string: profileImgURL)
            cell.profileImg.kf.setImage(with: url)
        } else {
               cell.profileImg.image = UIImage.extractFirstFrameFromGIF(named: "gif17")
        }
        cell.usernameLbl.text = friend.userName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let searchedUserVC = SearchedUserVC()
        let navController = UINavigationController(rootViewController: searchedUserVC)
        
        guard let friendList = friendList else { return }
        let selectedUser = friendList[indexPath.row]
        self.fetchSelectedProfile(selectedUser: selectedUser) { appUser in
            guard let appUser = appUser else { return }
            searchedUserVC.navTitle = "@\(appUser.userName) "
            searchedUserVC.searchedUser = appUser
            searchedUserVC.isProfileVC = false
            if searchedUserVC.searchedUser?.userName == AppUserSingleton.shared.appUser?.userName {
                searchedUserVC.isOwnProfile = true
            }
            self.fetchSearchedUserHugPostsGotten(searchedUser: appUser) { searchedUserHugsGotten, error in
                if let error = error {
                    print("Error fetching hug posts of searched user: \(error.localizedDescription)")
                }
                let sortedHugs = searchedUserHugsGotten.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                searchedUserVC.searchedUsersHugs = sortedHugs
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func fetchSelectedProfile(selectedUser: AppUser, completion: @escaping (AppUser?) -> ()) {
        guard let uid = selectedUser.uid else {
            // Handle the case where the selected user's UID is not available
            completion(nil)
            return
        }

        let usersRef = Constants.Collections.UsersCollectionRef

        usersRef.document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user's profile: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let document = document, document.exists {
                do {
                    // Attempt to decode the document data into an AppUser
                    let appUser = try Firestore.Decoder().decode(AppUser.self, from: document.data()!)
                    completion(appUser)
                } catch {
                    print("Error decoding user's profile document: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                // Handle the case where the document doesn't exist
                print("User's profile document does not exist.")
                completion(nil)
            }
        }
    }

    
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

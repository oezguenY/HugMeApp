//
//  FriendsVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 14.02.23.
//

import UIKit
import Firebase
import Kingfisher


class SearchVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let firestoreListenerManager = FirestoreListenerManager.shared
    
    var searchListener: ListenerRegistration?
    
    var searchingForUser: AppUser?
    var queriedUsers: [AppUser]? = []
    var keyword: String = ""
    
    lazy var searchBar: UISearchBar = UISearchBar()
    let tableView = UITableView()
    var searching = false
    
    let db = Firestore.firestore()
    
    var someBool = false
    
    enum FirestoreError: Error {
        case fetchDocument
        case noCurrentUser
        case dataConversion
    }
    
    enum SwiftUserError: Error {
        case noAppUser
        case noSearchedUser
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setDelegates()
        registerCell()
        setupSearchBar()
        addTapGestureRecognizer()
        addSearchListener()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func addTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func addSearchListener() {
        if let searchListener = self.searchListener {
            firestoreListenerManager.add(searchListener)
        }
    }
    
    func fetchUsers(with keyword: String) {
        guard !keyword.isEmpty else {
            // Clear the queriedUsers array when the search bar is empty
            queriedUsers = []
            tableView.reloadData()
            return
        }

        db.collection("users").whereField("keywordsForLookup", arrayContains: keyword).getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents, error == nil else {
                print("No documents")
                return
            }
            DispatchQueue.main.async {
                self.queriedUsers = documents.compactMap { queryDocumentSnapshot in
                    try? queryDocumentSnapshot.data(as: AppUser.self)
                }
                self.tableView.reloadData()
            }
        }
    }


    
    func searchForUser(withUsername username: String) {
        
        // Create a query that listens for changes in the "users" collection
        searchListener = Constants.Collections.UsersCollectionRef
            .whereField("username", isEqualTo: username)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error searching for user: \(error.localizedDescription)")
                    return
                }
                
                // Process the querySnapshot to get user data
                let decoder = Firestore.Decoder()
                for document in querySnapshot!.documents {
                    do {
                        let appUser = try decoder.decode(AppUser.self, from: document.data())
                        self.searchingForUser = appUser
                        
                        // Reload the table view to display the found user immediately
                        self.tableView.reloadData()
                    } catch {
                        print("Error decoding document: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    private func setupSearchBar() {
        searchBar.searchBarStyle = UISearchBar.Style.default
        searchBar.placeholder = "Searching for..."
        searchBar.autocapitalizationType = .none
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        navigationItem.titleView = searchBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("FIRESTORELISTENER COUNT: \(firestoreListenerManager.listeners.count)")
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchingForUser = nil
        searchBar.text = ""
        self.queriedUsers = []
        searchBar.resignFirstResponder()
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.frame
    }
    
    private func addSubviews() {
        view.addSubview(tableView)
    }
    
    private func registerCell() {
        tableView.register(FriendCell.self, forCellReuseIdentifier: FriendCell.identifier)
    }
    
    func setProfileImages(indexPath: IndexPath, cell: FriendCell, profileArray: [AppUser?]) {
        
        let profileImgURL = profileArray[indexPath.row]?.profileImageURL
        if !(profileImgURL?.isEmpty ?? false) {
            let url = URL(string: profileImgURL ?? "")
            cell.profileImg.kf.setImage(with: url)
        } else {
            cell.profileImg.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AppDelegate.screenHeight / 11
    }
    
    private func setDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queriedUsers?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendCell.identifier, for: indexPath) as! FriendCell
        guard let user = queriedUsers?[indexPath.row] else { return UITableViewCell() }
        let profileImgURL = user.profileImageURL
        if !profileImgURL.isEmpty {
            let url = URL(string: profileImgURL)
            cell.profileImg.kf.setImage(with: url)
        } else {
            cell.profileImg.image = UIImage.extractFirstFrameFromGIF(named: "gif17")
        }
        cell.usernameLbl.text = user.userName
        return cell
}

func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let searchedUserVC = SearchedUserVC()
    let navController = UINavigationController(rootViewController: searchedUserVC)
    guard let friendList = queriedUsers else { return }
    guard let friendList = queriedUsers, indexPath.row < friendList.count else {
           return
       }
    let selectedUser = friendList[indexPath.row]

    searchedUserVC.navTitle = "@\(selectedUser.userName) "
    searchedUserVC.searchedUser = selectedUser
    searchedUserVC.isProfileVC = false
    if searchedUserVC.searchedUser?.userName == AppUserSingleton.shared.appUser?.userName {
        searchedUserVC.isOwnProfile = true
    }
    fetchSearchedUserHugPostsGotten(searchedUser: selectedUser) { searchedUserHugsGotten, error in
        if let error = error {
            print("Error fetching hug posts of searched user: \(error.localizedDescription)")
        }
        let sortedHugs = searchedUserHugsGotten.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
        searchedUserVC.searchedUsersHugs = sortedHugs
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true)
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

extension SearchVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        keyword = searchText
        self.fetchUsers(with: keyword)
        tableView.reloadData()
    }
}

extension SearchVC {
    @objc func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
}

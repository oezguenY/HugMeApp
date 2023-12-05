//
//  DiscoveryVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 11.08.23.
//

import UIKit
import Firebase
import Kingfisher

class DiscoveryVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var displayedHugImageView: UIImageView?
    let refreshControl = UIRefreshControl()
    var discoveryBtn = UIButton()
    var friendsBtn = UIButton()
    
    var discoveryOrNot = true
    
    var paginationReference: QueryDocumentSnapshot?
    var friendsPaginationReference: QueryDocumentSnapshot?
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    var isLoadingMoreDiscoveryPosts = false// Flag to track if data is currently being loaded
    var isLoadingMoreFriendsPosts = false
    var isFetchingDiscoveryPosts = false
    var isFetchingFriendsPosts = false
    
    let tableView = UITableView()
    let reuseIdentifier = "DiscoveryCell"
    var discoveryPosts = [Hug]()
    var friendsPosts = [Hug]()
    var refreshedPosts = [Hug]()
    var currentDataSource: [Hug] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        setupNavigationBar()
        currentDataSource = HugPostsDiscoveryManager.shared.hugPostsDiscovery
        discoveryPosts = HugPostsDiscoveryManager.shared.hugPostsDiscovery
        friendsPosts = HugPostsFriendsManager.shared.hugPosts
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        paginationReference = PaginationHugPostsDiscoveryManager.shared.lastDocumentRef
        friendsPaginationReference = PaginationHugPostsFriendsManager.shared.lastDocumentRef
        setButtonFontSizes(selectedButton: discoveryBtn, unselectedButton: friendsBtn)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.frame
    }
    
//    func setButtonFontWeight(_ button: UIButton, weight: UIFont.Weight) {
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: weight)
//    }
    
    func setupNavigationBar() {
        // Create a custom view to hold the stack view
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: AppDelegate.screenWidth / 2.2, height: 44))
        
        // Create a stack view to hold the buttons
        let stackView = UIStackView(frame: titleView.bounds)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        discoveryBtn = UIButton(type: .system)
        discoveryBtn.setTitle("Discovery", for: .normal)
        discoveryBtn.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        discoveryBtn.addTarget(self, action: #selector(discoveryButtonTapped), for: .touchUpInside)
        discoveryBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        
        // Create a second button
        friendsBtn = UIButton(type: .system)
        friendsBtn.setTitle("Friends", for: .normal)
        friendsBtn.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        friendsBtn.addTarget(self, action: #selector(friendsButtonTapped), for: .touchUpInside)
        friendsBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)

        // Add buttons to the stack view
        stackView.addArrangedSubview(discoveryBtn)
        stackView.addArrangedSubview(friendsBtn)
        
        // Add the stack view to the title view
        titleView.addSubview(stackView)
        
        // Set the title view as the custom title view
        navigationItem.titleView = titleView
        
    }
    
    @objc func friendsButtonTapped() {
        if discoveryOrNot {
            setButtonFontSizes(selectedButton: friendsBtn, unselectedButton: discoveryBtn)
        }
        UIView.animate(withDuration: 0.2) {
            self.friendsBtn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        // After a short delay, revert the scaling animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: 0.2) {
                self.friendsBtn.transform = .identity
            }
        }
        discoveryOrNot = false
        currentDataSource = friendsPosts
        tableView.reloadData()
        
        let indexPath = IndexPath(row: 0, section: 0)
        if currentDataSource.isEmpty {
            return
        }
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        
    }
    
    
    @objc func discoveryButtonTapped() {
        if !discoveryOrNot {
            setButtonFontSizes(selectedButton: discoveryBtn, unselectedButton: friendsBtn)
        }
        UIView.animate(withDuration: 0.2) {
            self.discoveryBtn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        // After a short delay, revert the scaling animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: 0.2) {
                self.discoveryBtn.transform = .identity
            }
        }
        discoveryOrNot = true
        currentDataSource = discoveryPosts
        tableView.reloadData()
        
        let indexPath = IndexPath(row: 0, section: 0)
        if currentDataSource.isEmpty {
            return
        }
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    func setButtonFontSizes(selectedButton: UIButton? = nil, unselectedButton: UIButton? = nil) {
            if let selectedButton = selectedButton {
                selectedButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: .heavy)
                selectedButton.tintColor = .white
            }
            if let unselectedButton = unselectedButton {
                unselectedButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
                unselectedButton.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
            }
        }
    
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DiscoveryCell.self, forCellReuseIdentifier: reuseIdentifier)
        view.addSubview(tableView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentDataSource.isEmpty {
            return
        }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.size.height
        
        // Check if the user has scrolled to the bottom and isLoading is false
        if !discoveryOrNot, offsetY > contentHeight - screenHeight, !isLoadingMoreFriendsPosts {
            loadFriendsData() // Load more friends' posts
        }
        if discoveryOrNot, offsetY > contentHeight - screenHeight, !isLoadingMoreDiscoveryPosts {
            loadMoreData() // Load more discovery posts
        }
    }
    
    @objc func refreshData() {
        
        if discoveryOrNot {
            
            guard !isFetchingDiscoveryPosts else {
                
                refreshControl.endRefreshing()
                return // Prevent multiple requests while one is already in progress
            }
            
            
            isFetchingDiscoveryPosts = true
            isLoadingMoreDiscoveryPosts = false // Reset isLoadingMore as this is not a load more operation
            
            activityIndicator.startAnimating()
            
            PaginationHugPostsDiscoveryManager.shared.fetchTwentyDiscoveryPostsWithPagination(lastDocumentReference: nil) { [weak self] hugPosts, referenceToLastPost, error in
                
                guard let self = self else { return }
                
                if let error = error {
                    print("Error refreshing data: \(error.localizedDescription)")
                    
                    self.activityIndicator.stopAnimating()
                } else {
                    
                    if referenceToLastPost == nil {
                        
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                        }
                    }
                    
                    // Update the currentDataSource with the new data
                    self.paginationReference = referenceToLastPost
                    PaginationHugPostsDiscoveryManager.shared.lastDocumentRef = referenceToLastPost
                    discoveryPosts = hugPosts
                    self.currentDataSource = hugPosts // Replace the data with the refreshed data
                    
                    DispatchQueue.main.async {
                        
                        self.tableView.reloadData()
                    }
                    
                }
                
                // End the refreshing
                self.isFetchingDiscoveryPosts = false
                self.refreshControl.endRefreshing()
                
            }
        } else {
            guard !isFetchingFriendsPosts else {
                refreshControl.endRefreshing()
                return
            }
            isFetchingFriendsPosts = true
            isLoadingMoreFriendsPosts = false
            
            activityIndicator.startAnimating()
            
            PaginationHugPostsFriendsManager.shared.fetchTwentyFriendsPostsWithPagination(lastDocumentReference: nil) { [weak self] hugPosts, referenceToLastPost, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error refreshing data: \(error.localizedDescription)")
                    self.activityIndicator.stopAnimating()
                } else {
                    if referenceToLastPost == nil {
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                        }
                    }
                    self.friendsPaginationReference = referenceToLastPost
                    PaginationHugPostsFriendsManager.shared.lastDocumentRef = referenceToLastPost
                    self.friendsPosts = hugPosts
                    self.currentDataSource = hugPosts
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
                self.isFetchingFriendsPosts = false
                self.refreshControl.endRefreshing()
            }
        }
        self.activityIndicator.stopAnimating()
    }
    
    func loadMoreData() {
        guard !isFetchingDiscoveryPosts else {
            return // Prevent multiple requests while one is already in progress
        }
        
        isFetchingDiscoveryPosts = true
        isLoadingMoreDiscoveryPosts = true // Set isLoadingMore to true to prevent multiple calls
        
        activityIndicator.startAnimating()
        
        guard let paginationReference = self.paginationReference else {
            isFetchingDiscoveryPosts = false
            isLoadingMoreDiscoveryPosts = false // Reset isLoadingMore
            return
        }
        
        PaginationHugPostsDiscoveryManager.shared.fetchTwentyDiscoveryPostsWithPagination(lastDocumentReference: paginationReference) { hugPosts, referenceToLastPost, error in
            if let error = error {
                print("There was an error: \(error.localizedDescription)")
                self.activityIndicator.stopAnimating()
                return
            } else {
                if referenceToLastPost == nil {
                    self.isFetchingDiscoveryPosts = false
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }
                    return
                }
                self.currentDataSource.append(contentsOf: hugPosts)
                self.discoveryPosts.append(contentsOf: hugPosts)
                self.paginationReference = referenceToLastPost
                print("PAGINATION REFERNCE DISCOVERY: \(paginationReference.documentID)")
                PaginationHugPostsDiscoveryManager.shared.lastDocumentRef = referenceToLastPost
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
            self.isFetchingDiscoveryPosts = false
            self.isLoadingMoreDiscoveryPosts = false // Reset isLoadingMore
            self.activityIndicator.stopAnimating()
        }
    }
    
    func loadFriendsData() {
        
        guard !isFetchingFriendsPosts else {
            
            return // Prevent multiple requests while one is already in progress
        }
        
        
        isFetchingFriendsPosts = true
        isLoadingMoreFriendsPosts = true // Set isLoadingMore to true to prevent multiple calls
        
        activityIndicator.startAnimating()
        
        guard let paginationReference = self.friendsPaginationReference else {
            
            isFetchingFriendsPosts = false
            isLoadingMoreFriendsPosts = false // Reset isLoadingMore
            return
        }
        
        
        PaginationHugPostsFriendsManager.shared.fetchTwentyFriendsPostsWithPagination(lastDocumentReference: paginationReference) { hugPosts, referenceToLastPost, error in
            if let error = error {
                print("There was an error: \(error.localizedDescription)")
                
                self.activityIndicator.stopAnimating()
                return
            } else {
                
                // MARK: - REFERNCETOLASTPOST IS NIL BUG!!!!!!!
                if referenceToLastPost == nil {
                    self.isFetchingFriendsPosts = false
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }
                    
                    return
                }
                
                self.currentDataSource.append(contentsOf: hugPosts)
                self.friendsPosts.append(contentsOf: hugPosts)
                self.friendsPaginationReference = referenceToLastPost
                
                print("PAGINATION REFERNCE FRIENDS: \(paginationReference.documentID)")
                PaginationHugPostsFriendsManager.shared.lastDocumentRef = referenceToLastPost
                
                DispatchQueue.main.async {
                    
                    self.tableView.reloadData()
                }
            }
            
            self.isFetchingFriendsPosts = false
            self.isLoadingMoreFriendsPosts = false // Reset isLoadingMore
            self.activityIndicator.stopAnimating()
        }
        
        
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AppDelegate.screenHeight * 0.7
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! DiscoveryCell
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(usernameLabelTapped))
        let tapGestureTwo = UITapGestureRecognizer(target: self, action: #selector(usernameLabelTapped))
        
        
        
        let post = currentDataSource[indexPath.row] // Use the currentDataSource
        // Configure the cell with the data from the post
        cell.usernameLbl.text = post.receiverUsername
        cell.usernameLbl.isUserInteractionEnabled = true
        cell.usernameLbl.addGestureRecognizer(tapGestureTwo)
        
        
        if let profileimgurl = post.receiverImageUrl, !profileimgurl.isEmpty {
            let url = URL(string: profileimgurl)
            cell.profileImg.kf.setImage(with: url)
        } else {
            cell.profileImg.image = UIImage.extractFirstFrameFromGIF(named: "gif17")
        }
        
        let hugImgUrl = post.hugPicture
        let url2 = URL(string: hugImgUrl ?? "")
        cell.hugImg.kf.setImage(with: url2)
        cell.gifImageView.loadGif(name: post.gif)
        cell.usernameOfPersonTwoLbl.text = post.senderUsername
        cell.timestampLbl.text = post.formattedTimestamp
        cell.usernameOfPersonTwoLbl.isUserInteractionEnabled = true
        cell.usernameOfPersonTwoLbl.addGestureRecognizer(tapGestureRecognizer)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gifImageTapped(sender:)))
        cell.gifImageView.addGestureRecognizer(tapGesture)
        cell.gifImageView.isUserInteractionEnabled = true
        cell.imageOptionsBtn.isHidden = true
        cell.imageOptionsBtn.isEnabled = false
        
        return cell
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
        fetchSearchedUserHugPostsGotten(searchedUser: searchingForUser) { searchedUserHugsGotten, error  in
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayedHugImageView?.removeFromSuperview()
        displayedHugImageView = nil
        
        // Remove the tap gesture recognizer
        for gestureRecognizer in view.gestureRecognizers ?? [] {
            view.removeGestureRecognizer(gestureRecognizer)
        }
    }
    
    
}




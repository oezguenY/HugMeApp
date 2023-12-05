//
//  ProfileViewVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 31.08.23.
//

import UIKit
import CropViewController
import Firebase
import FirebaseStorage
import Kingfisher
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices


class ProfileViewVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CropViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var userDeleted = false
    
    let activityIndicatorProfileVC = UIActivityIndicatorView(style: .large)
    var userSignedOut = false
    
    // Function to show the loading indicator
    func showLoadingIndicator() {
        
        activityIndicatorProfileVC.center = view.center
        activityIndicatorProfileVC.hidesWhenStopped = true
        view.addSubview(activityIndicatorProfileVC)
        activityIndicatorProfileVC.startAnimating()
    }
    
    // Function to hide the loading indicator
    func hideLoadingIndicator() {
        activityIndicatorProfileVC.stopAnimating()
        activityIndicatorProfileVC.removeFromSuperview()
    }
    
    var deletionFinished = false
    var documentID: String?
    
    var displayedHugImageView: UIImageView?
    let firestoreListenerManager = FirestoreListenerManager.shared
    
    // MARK: - Properties
    var profileCell: ProfileTableViewCell?
    let storage = Storage.storage()
    var loadingIndicator: UIActivityIndicatorView!
    var isProfileVC = true
    var isOwnProfile = false
    
    var receivedHugPosts = HugPostsGottenManager.shared.hugPostsGotten
    
    var friendsCount: Int = 0 {
        didSet {
            profileCell?.friendsAmountLbl.text = "\(friendsCount)"
            print("FRIENDSCOUNT IS NOW: \(friendsCount)")
        }
    }
    
    var hugPostsGottenCount: Int = 0 {
        didSet {
            profileCell?.hugsReceivedAmountLbl.text = "\(hugPostsGottenCount)"
        }
    }
    
    var hugsGivenCount: Int = 0 {
        didSet {
            profileCell?.hugsGiveAmountnLbl.text = "\(hugsGivenCount)"
        }
    }
    
    var selectedProfileImage: UIImage? {
        didSet {
            // Whenever the image changes, update the profileImageView
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileTableViewCell {
                cell.profileImageView.contentMode = .scaleAspectFill
                cell.profileImageView.image = selectedProfileImage
            }
        }
    }
    
    let loadingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .white // You can set the color to your preference
        view.center = view.center
        view.hidesWhenStopped = true
        return view
    }()
    
    let tableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNotifications()
        friendsCount = FriendsManager.shared.friends.count
        hugPostsGottenCount = HugPostsGottenManager.shared.hugPostsGotten.count
        hugsGivenCount = HugsGivenManager.shared.hugPostsGiven.count
        if receivedHugPosts != HugPostsGottenManager.shared.hugPostsGotten {
            receivedHugPosts = HugPostsGottenManager.shared.hugPostsGotten
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        navigationItem.title = ""
        let gearImage = UIImage(systemName: "gear")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let rightBarButtonItem = UIBarButtonItem(image: gearImage, style: .plain, target: self, action: #selector(gearButtonTapped))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    // MARK: - UI Setup
    
    func hideAndDisableButtons(cell: ProfileTableViewCell) {
        if isProfileVC {
            cell.addFriendBtn.isHidden = true
            cell.sendHugRequestBtn.isHidden = true
            return
        }
        
        if isOwnProfile {
            cell.addFriendBtn.isHidden = true
            cell.sendHugRequestBtn.isHidden = true
            cell.cameraBtn.isHidden = true
            return
        }
        
        cell.addFriendBtn.isHidden = false
        cell.sendHugRequestBtn.isHidden = false
        cell.profileImageView.isUserInteractionEnabled = false
        cell.cameraBtn.isHidden = true
        cell.cameraBtn.isEnabled = false
        
    }
    
    @objc func signOutUser(userDeleted: Bool) {
        // Start the loading indicator
        loadingIndicatorView.startAnimating()
        
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        
        // Stop the loading indicator
        self.loadingIndicatorView.stopAnimating()
        self.transitionToWelcomeScreen()
        if userDeleted {
            NotificationCenter.default.post(name: NSNotification.Name("ProfileDeletedNotification"), object: nil)
        }
    }
    
    private func transitionToWelcomeScreen() {
        let welcomeVC = WelcomeVC()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = welcomeVC
    }
    
    @objc func gearButtonTapped() {
        // Show the action sheet when the gear button is tapped
        showGearActionSheet()
    }
    
    func showGearActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let logoutAction = UIAlertAction(title: "Log out", style: .destructive) { (_) in
            self.showLogoutConfirmationAlert()
        }

        let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .destructive) { (_) in
            self.showDeleteAccountConfirmationAlert()
        }

        let privacyPolicyAction = UIAlertAction(title: "Privacy Policy", style: .default) { (_) in
            // Open the Privacy Policy website in Safari
            if let url = URL(string: "https://sites.google.com/view/hugme-privacy-policy/home") {
                UIApplication.shared.open(url)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(logoutAction)
        alertController.addAction(deleteAccountAction)
        alertController.addAction(privacyPolicyAction) // Add the Privacy Policy action
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    
    func showLogoutConfirmationAlert() {
        let alertController = UIAlertController(title: "Are you sure you want to log out?", message: nil, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            KingfisherManager.shared.cache.clearMemoryCache()
            KingfisherManager.shared.cache.clearDiskCache()
            self.firestoreListenerManager.removeAllListeners()
            HugsGivenManager.shared.hugPostsGiven.removeAll()
            HugPostsGottenManager.shared.hugPostsGotten.removeAll()
            HugPostsFriendsManager.shared.hugPosts.removeAll()
            HugPostsDiscoveryManager.shared.hugPostsDiscovery.removeAll()
            FriendRequestsSentManager.shared.friendRequestsSent.removeAll()
            FriendRequestsReceivedManager.shared.friendRequestsReceived.removeAll()
            FriendsManager.shared.friends.removeAll()
            HugRequestsReceivedManager.shared.hugRequestsReceived.removeAll()
            HugRequestsSentManager.shared.hugRequestsSent.removeAll()
            AppUserSingleton.shared.appUser = nil
            self.receivedHugPosts = []
            if let tabBar = self.tabBarController as? TabBar {
                tabBar.removeUserDocListener()
            }
            self.signOutUser(userDeleted: false)
        }
        yesAction.setValue(UIColor.red, forKey: "titleTextColor")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            // Handle cancel action if needed
        }
        
        // Set the text color of the "Cancel" button to red
        
        
        alertController.addAction(yesAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func showDeleteAccountConfirmationAlert() {
        let alertController = UIAlertController(title: "Are you sure you want to delete your account?", message: nil, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (_) in
            self.showDeleteProfileAlert()
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func hideNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    
    public func setUIElements(cell: ProfileTableViewCell) {
        
        guard let appUser = AppUserSingleton.shared.appUser else {
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
        
        cell.fullNameLbl.text = appUser.fullName
        print("APPUSER FULL NAME: \(appUser.fullName)")
        cell.usernameLbl.text = "@\(appUser.userName)"
        print("APPUSER USERNAME: \(appUser.userName)")
        print("APUUSER FRIENDS COUNT:\(String(FriendsManager.shared.friends.count))")
        cell.friendsAmountLbl.text = String(FriendsManager.shared.friends.count)
        cell.hugsReceivedAmountLbl.text = String(HugPostsGottenManager.shared.hugPostsGotten.count)
        cell.hugsGiveAmountnLbl.text = String(HugsGivenManager.shared.hugPostsGiven.count)
    }
    
    func getCurrentUserUID() -> String? {
        let currentUserUID = Auth.auth().currentUser?.uid
        print("CURRENT USER UID: \(currentUserUID)")
        return currentUserUID
    }
    
    
    func setupUI() {
        
        // Constrain tableView
        view.addSubview(tableView)
        view.addSubview(loadingIndicatorView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true // Adjust the constant value as needed
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: "ProfileTableViewCell")
        tableView.register(DiscoveryCell.self, forCellReuseIdentifier: DiscoveryCell.identifier)
        tableView.separatorStyle = .none
        
        tableView.dataSource = self
        tableView.delegate = self
        // Register your table view cells if needed
    }
    
    func showActionSheet() {
        let alertController = UIAlertController(title: "Change your profile picture", message: nil, preferredStyle: .actionSheet)
        
        let photoArchiveAction = UIAlertAction(title: "Photo Archive", style: .default) { (_) in
            self.showImagePicker()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(photoArchiveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.allowsEditing = false
        guard let selectedImage = info[.originalImage] as? UIImage else {
            return
        }
        picker.dismiss(animated: true, completion: nil)
        
        showCrop(image: selectedImage)
    }
    
    func showCrop(image: UIImage) {
        let vc = CropViewController(croppingStyle: .default, image: image)
        vc.aspectRatioPreset = .presetSquare
        vc.aspectRatioLockEnabled = false
        vc.toolbarPosition = .bottom
        vc.doneButtonTitle = "Continue"
        vc.cancelButtonTitle = "Quit"
        vc.delegate = self
        present(vc, animated: true)
        
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        cropViewController.dismiss(animated: true)
        
        uploadImageToFirebaseStorage(image) {
            self.setNewProfileImageForHugPosts()
        }
    }
    
    func showImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    
    func uploadImageToFirebaseStorage(_ image: UIImage, completion: @escaping () -> Void) {
        
        deleteOldPicutreFromFirestoreStorage {
            
            self.uploadFunction(image) { url in
                
                if let downloadURL = url?.absoluteString {
                    
                    AppUserSingleton.shared.appUser?.profileImageURL = downloadURL
                    
                    self.saveImageURLToFirestore(downloadURL) {
                        
                        self.updateProfileImgInFriendrequestsCollection(newProfileImgUrl: downloadURL) { error in
                            
                            if let error = error {
                                
                                print(error.localizedDescription)
                                
                            }
                            
                            
                            self.updateProfileImgInHugPostsCollection(newProfileImgUrl: downloadURL) { error in
                                
                                if let error = error {
                                    
                                    print(error.localizedDescription)
                                    
                                }
                                
                                
                                self.updateProfileImgInHugRequestsCollection(newProfileImgUrl: downloadURL) { error in
                                    
                                    if let error = error {
                                        
                                        print(error.localizedDescription)
                                    }
                                    
                                    completion()
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func setNewProfileImageForHugPosts() {
        if let newProfileImgUrl = AppUserSingleton.shared.appUser?.profileImageURL {
            // Update the receiverImageUrl for each hug post in receivedHugPosts
            for (index, var hug) in receivedHugPosts.enumerated() {
                hug.receiverImageUrl = newProfileImgUrl
                receivedHugPosts[index] = hug
            }
            
            // Update the receiverImageUrl for each hug post in HugPostsGottenManager.shared.hugPostsGotten
            for (index, var hug) in HugPostsGottenManager.shared.hugPostsGotten.enumerated() {
                hug.receiverImageUrl = newProfileImgUrl
                HugPostsGottenManager.shared.hugPostsGotten[index] = hug
            }
            
            // Reload the table view to reflect the changes
            tableView.reloadData()
        }
    }
    
    
    func uploadFunction(_ image: UIImage, completion: @escaping (URL?) -> ()) {
        print("UPLOAD FUNCTION IS CALLED!")
        guard let imageData = image.jpegData(compressionQuality: 0.1) else {
            completion(nil)
            return
        }
        let storageRef = self.storage.reference()
        let imageRef = storageRef.child(Constants.Storage.images).child("\(UUID().uuidString).jpg")
        
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            imageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error getting image download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                } else {
                    guard let url = url else { return }
                    
                    completion(url)
                }
            }
        }
    }
    
    func updateProfileImgInHugRequestsCollection(newProfileImgUrl: String, completion: @escaping (Error?) -> ()) {
        let hugrequestsCollectionRef = Constants.Collections.HugRequestsCollectionRef
        guard let appUserSingleton = AppUserSingleton.shared.appUser else {
            print("No App User in the ProfileVC")
            return
        }
        
        hugrequestsCollectionRef.whereField("sender", isEqualTo: appUserSingleton.userName).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                // No documents found with the given username
                completion(nil)
                return
            }
            
            // Create a batched write
            let batch = Firestore.firestore().batch()
            
            // Update the "profileImgUrl" field for each matching document in the batch
            for document in documents {
                let documentRef = hugrequestsCollectionRef.document(document.documentID)
                batch.updateData(["senderProfileImgUrl": newProfileImgUrl], forDocument: documentRef)
            }
            
            // Commit the batched write
            batch.commit { (error) in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil) // Success
                }
            }
        }
    }
    
    func updateProfileImgInHugPostsCollection(newProfileImgUrl: String, completion: @escaping (Error?) -> ()) {
        let hugpostsCollectionRef = Constants.Collections.HugPostsRef
        guard let appUserSingleton = AppUserSingleton.shared.appUser else {
            print("No App User in the ProfileVC")
            return
        }
        
        hugpostsCollectionRef.whereField("receiverUsername", isEqualTo: appUserSingleton.userName).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                // No documents found with the given username
                completion(nil)
                return
            }
            
            // Create a batched write
            let batch = Firestore.firestore().batch()
            
            // Update the "profileImgUrl" field for each matching document in the batch
            for document in documents {
                let documentRef = hugpostsCollectionRef.document(document.documentID)
                batch.updateData(["receiverImageUrl": newProfileImgUrl], forDocument: documentRef)
            }
            
            // Commit the batched write
            batch.commit { (error) in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil) // Success
                }
            }
        }
    }
    
    
    func updateProfileImgInFriendrequestsCollection(newProfileImgUrl: String, completion: @escaping (Error?) -> ()) {
        let friendsCollectionRef = Constants.Collections.FriendRequestsCollectionRef
        guard let appUserSingleton = AppUserSingleton.shared.appUser else {
            print("No App User in the ProfileVC")
            return
        }
        
        friendsCollectionRef.whereField("senderUsername", isEqualTo: appUserSingleton.userName).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                // No documents found with the given username
                completion(nil)
                return
            }
            
            // Create a batched write
            let batch = Firestore.firestore().batch()
            
            // Update the "profileImgUrl" field for each matching document in the batch
            for document in documents {
                let documentRef = friendsCollectionRef.document(document.documentID)
                batch.updateData(["profileImageURL": newProfileImgUrl], forDocument: documentRef)
            }
            
            // Commit the batched write
            batch.commit { (error) in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil) // Success
                }
            }
        }
    }
    
    
    func saveImageURLToFirestore(_ imageURL: String, completion: @escaping () -> ()) {
        let documentData: [String: Any] = [
            Constants.Firebase.PROFILEIMGURL: imageURL
        ]
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        Constants.Collections.UsersCollectionRef.document(currentUserUID).setData(documentData, merge: true) { error in
            if let error = error {
                print("Error updating imageURL: \(error)")
                completion()
            } else {
                print("ImageURL updated successfully!")
                completion()
            }
        }
    }
    
    
    func deleteOldPicutreFromFirestoreStorage(completion: @escaping () -> ()) {
        guard let currentUserUID = AppUserSingleton.shared.appUser?.uid else {
            completion()
            return
        }
        let currentUserRef = Constants.Collections.UsersCollectionRef.document(currentUserUID)
        currentUserRef.getDocument { document, error in
            if error != nil {
                print("There was an error retrieving the profile image \(error!.localizedDescription)")
                completion()
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                guard let profileImgURL = data?[Constants.Firebase.PROFILEIMGURL] as? String else {
                    completion()
                    return
                }
                if profileImgURL.isEmpty {
                    completion()
                    return
                }
                let storageRef = Storage.storage()
                let fileRef = storageRef.reference(forURL: profileImgURL)
                
                fileRef.delete { error in
                    if let error = error {
                        print("There was an error deleting the old profile image from firestore storage \(error.localizedDescription)")
                        completion()
                        return
                    } else {
                        print("Old profile picture successfully deleted from Storage!")
                        completion()
                    }
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource and UITableViewDelegate methods
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            // Height of the first cell (40% of view height)
            if isProfileVC || isOwnProfile {
                return view.bounds.height * 0.32
            } else {
                return view.bounds.height * 0.4
            }
            
        } else {
            if isProfileVC || isOwnProfile {
                return view.bounds.height * 0.68
            } else {
                return view.bounds.height * 0.6
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("RECEIVEDHUGPOSTS COUNT: \(receivedHugPosts.count)")
        return max(receivedHugPosts.count + 1, 1)
    }
    
    @objc func friendsAmountLblTapped() {
        let friendListVC = FriendListVC()
        friendListVC.friendList = FriendsManager.shared.friends.sorted(by: { $0.userName < $1.userName })
        let navigationController = UINavigationController(rootViewController: friendListVC) // Embed in a navigation controller
        friendListVC.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as! ProfileTableViewCell
            self.profileCell = cell
            setUIElements(cell: cell)
            hideAndDisableButtons(cell: cell)
            if isProfileVC {
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profilePictureTapped))
                let friendsAmountLblTapGesture = UITapGestureRecognizer(target: self, action: #selector(friendsAmountLblTapped))
                cell.stackView3.addGestureRecognizer(friendsAmountLblTapGesture)
                cell.stackView3.isUserInteractionEnabled = true
                cell.profileImageView.addGestureRecognizer(tapGestureRecognizer)
                cell.profileImageView.isUserInteractionEnabled = true
                cell.cameraBtn.addTarget(self, action: #selector(cameraBtnTapped), for: .touchUpInside)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoveryCell.identifier, for: indexPath) as! DiscoveryCell
            let hugIndex = indexPath.row - 1 // Adjust the index to match the receivedHugPosts array
            cell.usernameLbl.text = receivedHugPosts[hugIndex].receiverUsername
            
            if let profileimgurl = receivedHugPosts[hugIndex].receiverImageUrl, !profileimgurl.isEmpty {
                let url_1 = URL(string: profileimgurl)
                cell.profileImg.kf.setImage(with: url_1)
            } else {
                cell.profileImg.image = UIImage.extractFirstFrameFromGIF(named: "gif17")
            }
            
            let hugImgurl = receivedHugPosts[hugIndex].hugPicture
            let url_2 = URL(string: hugImgurl ?? "")
            cell.hugImg.kf.setImage(with: url_2)
            cell.gifImageView.loadGif(name: receivedHugPosts[hugIndex].gif)
            cell.usernameOfPersonTwoLbl.text = receivedHugPosts[hugIndex].senderUsername
            cell.timestampLbl.text = receivedHugPosts[hugIndex].formattedTimestamp
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(usernameLabelTapped))
            cell.usernameOfPersonTwoLbl.isUserInteractionEnabled = true
            cell.usernameOfPersonTwoLbl.addGestureRecognizer(tapGestureRecognizer)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gifImageTapped(sender:)))
            cell.gifImageView.addGestureRecognizer(tapGesture)
            cell.gifImageView.isUserInteractionEnabled = true
            cell.imageOptionsBtn.isHidden = false
            cell.imageOptionsBtn.isEnabled = true
            cell.imageOptionsBtn.tag = indexPath.row - 1
            cell.imageOptionsBtn.addTarget(self, action: #selector(imageOptionsBtnTapped), for: .touchUpInside)
            return cell
        }
    }
    
    func deleteSelectedHugPost(index: Int) {
        // Create and start the loading indicator
        let loadingIndicator = createAndStartLoadingIndicator()
        
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            // Stop and dismiss the loading indicator in case of an error
            stopAndDismissLoadingIndicator(loadingIndicator)
            return
        }
        
        let hugPostToDelete = receivedHugPosts[index]
        let hugPostToDeleteUID = hugPostToDelete.uid
        let senderUsername = hugPostToDelete.senderUsername
        let hugPictureURL = hugPostToDelete.hugPicture
        
        // Step 1: Fetch the user document for the current user
        Constants.Collections.UsersCollectionRef
            .whereField("username", isEqualTo: currentUserUsername)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching user document: \(error.localizedDescription)")
                    // Stop and dismiss the loading indicator in case of an error
                    self.stopAndDismissLoadingIndicator(loadingIndicator)
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No user documents found for username: \(currentUserUsername)")
                    // Stop and dismiss the loading indicator if no user document found
                    self.stopAndDismissLoadingIndicator(loadingIndicator)
                    return
                }
                
                // Assuming there's only one user document with the given username
                if let userDocument = documents.first {
                    var hugsgottenArray = userDocument.data()["hugsgotten"] as? [String] ?? []
                    
                    // Step 2: Remove the hugPostToDeleteUID from the hugsgottenArray
                    if let indexToRemove = hugsgottenArray.firstIndex(of: hugPostToDeleteUID) {
                        hugsgottenArray.remove(at: indexToRemove)
                    }
                    
                    // Update the user document with the modified hugsgottenArray
                    userDocument.reference.updateData(["hugsgotten": hugsgottenArray]) { (error) in
                        if let error = error {
                            print("Error updating user document: \(error.localizedDescription)")
                            // Stop and dismiss the loading indicator in case of an error
                            self.stopAndDismissLoadingIndicator(loadingIndicator)
                            return
                        }
                        
                        // Step 3: Delete the hug post document from "hugposts" collection
                        Constants.Collections.HugPostsRef
                            .document(hugPostToDeleteUID)
                            .delete { (error) in
                                if let error = error {
                                    print("Error deleting hug post document: \(error.localizedDescription)")
                                    // Stop and dismiss the loading indicator in case of an error
                                    self.stopAndDismissLoadingIndicator(loadingIndicator)
                                    return
                                }
                                
                                // Successfully deleted the hug post
                                print("Hug post deleted successfully!")
                                
                                // Now, you can also remove the deleted hug post from your data source
                                self.receivedHugPosts.remove(at: index)
                                
                                // Reload the table view to reflect the changes
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                                
                                // Step 4: Fetch the user document for the sender of the hug post
                                Constants.Collections.UsersCollectionRef
                                    .whereField("username", isEqualTo: senderUsername)
                                    .getDocuments { (querySnapshot, error) in
                                        if let error = error {
                                            print("Error fetching sender's user document: \(error.localizedDescription)")
                                            // Stop and dismiss the loading indicator in case of an error
                                            self.stopAndDismissLoadingIndicator(loadingIndicator)
                                            return
                                        }
                                        
                                        guard let senderDocuments = querySnapshot?.documents else {
                                            print("No user documents found for sender: \(senderUsername)")
                                            // Stop and dismiss the loading indicator if no sender document found
                                            self.stopAndDismissLoadingIndicator(loadingIndicator)
                                            return
                                        }
                                        
                                        // Assuming there's only one sender document with the given username
                                        if let senderUserDocument = senderDocuments.first {
                                            var hugsgivenArray = senderUserDocument.data()["hugsgiven"] as? [String] ?? []
                                            
                                            // Step 5: Remove the hugPostToDeleteUID from the hugsgivenArray
                                            if let indexToRemove = hugsgivenArray.firstIndex(of: hugPostToDeleteUID) {
                                                hugsgivenArray.remove(at: indexToRemove)
                                            }
                                            
                                            // Update the sender user document with the modified hugsgivenArray
                                            senderUserDocument.reference.updateData(["hugsgiven": hugsgivenArray]) { (error) in
                                                if let error = error {
                                                    print("Error updating sender's user document: \(error.localizedDescription)")
                                                } else {
                                                    print("Updated sender's user document successfully!")
                                                }
                                                
                                                guard let hugPictureURL = hugPictureURL else { return }
                                                // Step 6: Delete the picture from Firestore Storage
                                                if !hugPictureURL.isEmpty {
                                                    self.deleteHugPictureFromStorage(hugPictureURL) {
                                                        // Stop and dismiss the loading indicator after all operations are complete
                                                        self.stopAndDismissLoadingIndicator(loadingIndicator)
                                                        
                                                        // Show a success alert
                                                        self.showSuccessAlert(message: "Post deleted successfully!")
                                                    }
                                                } else {
                                                    // Stop and dismiss the loading indicator after all operations are complete
                                                    self.stopAndDismissLoadingIndicator(loadingIndicator)
                                                    
                                                    // Show a success alert
                                                    self.showSuccessAlert(message: "Post deleted successfully!")
                                                }
                                            }
                                        }
                                    }
                            }
                    }
                }
            }
    }
    
    func deleteHugPictureFromStorage(_ pictureURL: String, completion: @escaping () -> ()) {
        let storageRef = Storage.storage().reference(forURL: pictureURL)
        storageRef.delete { error in
            if let error = error {
                print("Error deleting hug post picture from storage: \(error.localizedDescription)")
            } else {
                print("Hug post picture deleted from storage successfully!")
            }
            
            // Call the completion handler after the delete operation
            completion()
        }
    }
    
    
    
    // Function to show a success alert
    func showSuccessAlert(message: String) {
        let alertController = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    // Function to create and start the loading indicator
    func createAndStartLoadingIndicator() -> UIActivityIndicatorView {
        let loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .black // You can set the color to your preference
        loadingIndicator.center = view.center
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
        return loadingIndicator
    }
    
    // Function to stop and dismiss the loading indicator
    func stopAndDismissLoadingIndicator(_ loadingIndicator: UIActivityIndicatorView) {
        loadingIndicator.stopAnimating()
        loadingIndicator.removeFromSuperview()
    }
    
    
    
    
    @objc func imageOptionsBtnTapped(sender: UIButton) {
        let index = sender.tag
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Create a "Delete Post" action with red text
        let deleteAction = UIAlertAction(title: "Delete Post", style: .destructive) { (_) in
            self.deleteSelectedHugPost(index: index)
        }
        deleteAction.setValue(UIColor.red, forKey: "titleTextColor")
        
        // Add the delete action to the action sheet
        alertController.addAction(deleteAction)
        
        // Create a "Cancel" action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Add the cancel action to the action sheet
        alertController.addAction(cancelAction)
        
        // Present the action sheet
        present(alertController, animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Your didSelectRowAt code here
        
        // Deselect the cell with animation
        tableView.deselectRow(at: indexPath, animated: true)
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
    
    @objc func profilePictureTapped() {
        showActionSheet()
    }
    
    @objc func cameraBtnTapped() {
        showActionSheet()
    }

    
    func setNotifications() {
        // Calculate notificationsCount as you did before
        let reqsCount = HugRequestsReceivedManager.shared.hugRequestsReceived
        let friendsCount = FriendRequestsReceivedManager.shared.friendRequestsReceived
        //        let notificationsCount = friendsCount.count + reqsCount.count
        
        // Update the badge in the TabBar
        if let tabBar = self.tabBarController as? TabBar {
            tabBar.updateInboxBadge()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayedHugImageView?.removeFromSuperview()
        displayedHugImageView = nil
        
        // Remove the tap gesture recognizer
        for gestureRecognizer in view.gestureRecognizers ?? [] {
            view.removeGestureRecognizer(gestureRecognizer)
        }
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
    
    func showDeleteProfileAlert() {
        
        guard let currentUser = Auth.auth().currentUser else {
            // User is not authenticated
            // Show an error or handle this case as needed
            return
        }
        
        self.checkAuthenticationProvider { provider in
            if let provider = provider {
                switch provider {
                case "Email/Password":
                    // Create an alert controller
                    let alertController = UIAlertController(title: "Delete Your Profile",
                                                            message: "Enter your login data to delete your profile",
                                                            preferredStyle: .alert)
                    
                    // Add an email text field
                    alertController.addTextField { textField in
                        textField.placeholder = "E-mail"
                        textField.keyboardType = .emailAddress
                    }
                    
                    // Add a password text field
                    alertController.addTextField { textField in
                        textField.placeholder = "Password"
                        textField.isSecureTextEntry = true
                    }
                    
                    // Create a cancel action
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    
                    // Create a delete action
                    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                        // Handle the deletion logic here
                        if let emailTextField = alertController.textFields?.first,
                           let passwordTextField = alertController.textFields?.last,
                           let email = emailTextField.text,
                           let password = passwordTextField.text {
                            // Authenticate the user with email and password
                            self?.authenticateUserForDeletion(email: email, password: password)
                        }
                    }
                    
                    // Add actions to the alert controller
                    alertController.addAction(cancelAction)
                    alertController.addAction(deleteAction)
                    
                    // Present the alert
                    self.present(alertController, animated: true, completion: nil)
                case "Google":
                    GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
                        guard error == nil else {
                            return
                        }
                        
                        guard let user = result?.user,
                              let idToken = user.idToken?.tokenString
                        else {
                            return
                        }
                        
                        let googleCredential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                             accessToken: user.accessToken.tokenString)
                        currentUser.reauthenticate(with: googleCredential) { [weak self] (authResult, error) in
                            if let error = error {
                                // Reauthentication failed
                                self?.showReauthenticationErrorAlert(errorMessage: error.localizedDescription)
                            } else {
                                // Reauthentication successful
                                // Proceed with user deletion
                                self?.deleteUserAccount()
                            }
                        }
                    }
                    return
                case "Apple":
                    print("Apple Sign in")
                    // Use ASAuthorizationAppleIDProvider to create Apple ID credentials
                    let provider = ASAuthorizationAppleIDProvider()
                    let request = provider.createRequest()
                    
                    // Specify the requested scope (e.g., .fullName and .email)
                    request.requestedScopes = [.fullName, .email]
                    
                    // Perform the Apple Sign-In
                    let controller = ASAuthorizationController(authorizationRequests: [request])
                    controller.delegate = self
                    controller.presentationContextProvider = self
                    controller.performRequests()
                    return
                    
                    
                default:
                    return
                }
                
            } else {
                print("No user is currently signed in.")
                return
            }
        }
    }
    
    func authenticateUserForDeletion(email: String, password: String) {
        
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        
        self.checkAuthenticationProvider { provider in
            if let provider = provider, provider == "Email/Password" {
                let emailCredential = EmailAuthProvider.credential(withEmail: email, password: password)
                
                currentUser.reauthenticate(with: emailCredential) { [weak self] (authResult, error) in
                    if let error = error {
                        // Reauthentication failed
                        self?.showReauthenticationErrorAlert(errorMessage: error.localizedDescription)
                    } else {
                        // Reauthentication successful
                        // Proceed with user deletion
                        self?.deleteUserAccount()
                    }
                }
            } else {
                return
            }
        }
    }
    
    func showReauthenticationErrorAlert(errorMessage: String) {
        let alert = UIAlertController(title: "Error", message: "Wrong log-in data", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func checkAuthenticationProvider(completion: @escaping (String?) -> Void) {
        if let user = Auth.auth().currentUser {
            for userInfo in user.providerData {
                let providerID = userInfo.providerID
                switch providerID {
                case "password":
                    completion("Email/Password")
                case "google.com":
                    completion("Google")
                case "apple.com":
                    completion("Apple")
                default:
                    completion("Unknown Provider: \(providerID)")
                }
            }
        } else {
            completion(nil) // No user is currently signed in
        }
    }
    
    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    
    func deleteUserAccount() {
        if deletionFinished {
            return
        }
        
        deletionFinished = true
        
        showLoadingIndicator()
        
        self.deleteOldPicutreFromFirestoreStorage { }
        self.deleteFirebaseStorageElementsOfUser { }
        self.deleteUserInfoData { }
        self.deleteUsernameFromFriends { }
        self.fetchReceivedFriendRequests { friendRequestsReceived in
            self.updateSentFriendRequests(withReceivedFriendRequests: friendRequestsReceived) {
                self.deleteFetchedFriendRequestsDocuments(friendRequests: friendRequestsReceived) { }
            }
        }
        
        self.fetchSentFriendRequests { friendRequestsSent in
            self.updateReceivedFriendRequests(withSentFriendRequests: friendRequestsSent) {
                self.deleteFetchedFriendRequestsDocuments(friendRequests: friendRequestsSent) { }
            }
        }
        
        
        self.fetchSentHugRequests { hugrequestsSent in
            self.updateReceivedHugRequests(withSentHugRequests: hugrequestsSent) {
                self.deleteFetchedHugRequestsDocuments(hugRequests: hugrequestsSent) {
                }
            }
        }
        self.fetchReceivedHugRequests { hugrequestsReceived in
            self.updateSentHugRequests(withReceivedHugRequests: hugrequestsReceived) {
                self.deleteFetchedHugRequestsReceivedDocuments(hugRequests: hugrequestsReceived) {
                }
            }
        }
        
        self.fetchHugsGotten { hugsGotten in
            self.updateHugposts(withHugsGotten: hugsGotten) {
                self.deleteHugsGottenDocumentsInHugPostsCollection(hugsGotten: hugsGotten) {
                }
            }
        }
        
        self.fetchHugsGiven { hugsGiven in
            self.updateHugpostsGotten(withHugsGiven: hugsGiven) {
                // IS HUGS GIVEN
                self.deleteHugsGottenDocumentsInHugPostsCollection(hugsGotten: hugsGiven) {
                }
            }
        }
        
        self.removeFriendFromAllUsers { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        self.deleteUser {[weak self] success, err in
            if let err = err {
                let errorMessage = "An error occurred while deleting your profile. Try again later"
                self?.showErrorAlert(message: err.localizedDescription)
                self?.deletionFinished = false
                return
            }
            if success {
                self?.deleteEmail(completion: { [weak self] success, error in
                    if success {
                        KingfisherManager.shared.cache.clearMemoryCache()
                        KingfisherManager.shared.cache.clearDiskCache()
                        self?.firestoreListenerManager.removeAllListeners()
                        HugsGivenManager.shared.hugPostsGiven.removeAll()
                        HugPostsGottenManager.shared.hugPostsGotten.removeAll()
                        HugPostsFriendsManager.shared.hugPosts.removeAll()
                        HugPostsDiscoveryManager.shared.hugPostsDiscovery.removeAll()
                        FriendRequestsSentManager.shared.friendRequestsSent.removeAll()
                        FriendRequestsReceivedManager.shared.friendRequestsReceived.removeAll()
                        FriendsManager.shared.friends.removeAll()
                        HugRequestsReceivedManager.shared.hugRequestsReceived.removeAll()
                        HugRequestsSentManager.shared.hugRequestsSent.removeAll()
                        AppUserSingleton.shared.appUser = nil
                        self?.receivedHugPosts = []
                        if let tabBar = self?.tabBarController as? TabBar {
                            tabBar.removeUserDocListener()
                        }
                        if !(self?.userSignedOut ?? false) {
                            UserDefaults.standard.set(false, forKey: "HasRegistered")
                            self?.userDeleted = true
                            self?.signOutUser(userDeleted: self?.userDeleted ?? false)
                        }
                        self?.hideLoadingIndicator()
                    } else {
                        self?.deletionFinished = false
                        let errorMessage = "An error occurred while deleting your profile. Try again later"
                        self?.showErrorAlert(message: error?.localizedDescription ?? errorMessage)
                        return
                    }
                })
            } else {
                self?.deletionFinished = false
                let errorMessage = "An error occurred while deleting your profile. Try again later"
                self?.showErrorAlert(message: errorMessage)
                return
            }
        }
    }
    
    func deleteUsernameFromFriends(completion: @escaping () -> Void) {
        // Assuming 'username' is the username of the user to be deleted
        
        guard let username = AppUserSingleton.shared.appUser?.userName else { return }

        // Get a reference to the "users" collection
        let usersCollectionRef = Firestore.firestore().collection("users")

        // Fetch documents where the "friends" field contains the username
        usersCollectionRef
            .whereField("friends", arrayContains: username)
            .getDocuments { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents, error == nil else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "")")
                    return
                }

                // Update each document to remove the username from the "friends" field
                let batch = Firestore.firestore().batch()

                for document in documents {
                    let documentRef = usersCollectionRef.document(document.documentID)
                    batch.updateData(["friends": FieldValue.arrayRemove([username])], forDocument: documentRef)
                }

                // Commit the batch update
                batch.commit { batchError in
                    if let batchError = batchError {
                        print("Error updating documents: \(batchError.localizedDescription)")
                    } else {
                        print("Successfully updated documents")
                        completion()
                    }
                }
            }
    }

    func deleteUserInfoData(completion: @escaping () -> ()) {
        // Get the current user's UID
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            completion()
            return
        }
        
        // Create a reference to the "userinfo" document with the same UID as the current user
        let userinfoDocRef = Constants.Collections.UserInfoRef.document(currentUserUID)
        
        // Delete the document
        userinfoDocRef.delete { error in
            if let error = error {
                print("Error deleting userinfo document: \(error.localizedDescription)")
            } else {
                print("Userinfo document deleted successfully.")
            }
            
            // Call the completion handler
            completion()
        }
    }

    
    
    func deleteUsernameInHugPostsGiven(completion: @escaping () -> ()) {
        // Get the hugPostsGivenDocumentIDs
        let hugPostsGivenDocumentIDs = HugsGivenManager.shared.hugPostsGiven.compactMap { $0.uid }
        
        // Create a batched write to update multiple documents
        let batch = Firestore.firestore().batch()
        
        // Define the collection reference
        let hugPostsCollectionRef = Firestore.firestore().collection("hugposts")
        
        // Loop through each document ID and update the senderUsername field
        for documentID in hugPostsGivenDocumentIDs {
            // Create a reference to the document
            let documentRef = hugPostsCollectionRef.document(documentID)
            
            // Update the senderUsername field to an empty string
            batch.updateData(["senderUsername": ""], forDocument: documentRef)
        }
        
        // Commit the batched write
        batch.commit { error in
            if let error = error {
                print("Error updating documents: \(error)")
            } else {
                print("Sender usernames updated successfully.")
            }
            
            // Call the completion handler
            completion()
        }
    }
    
    
    func fetchReceivedFriendRequests(completion: @escaping ([String?]) -> ()) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Constants.Collections.UsersCollectionRef.document(uid).getDocument { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let document = querySnapshot, document.exists, let friendrequestsreceived = document.data()?["friendrequestsreceived"] as? [String] else {
                print("User document not found or friend requests array not present.")
                completion([])
                return
            }
            completion(friendrequestsreceived)
        }
    }
    
    func updateSentFriendRequests(withReceivedFriendRequests receivedFriendRequests: [String?], completion: @escaping () -> Void) {
        for receivedRequestUID in receivedFriendRequests {
            // Query the "users" collection for documents where "hugrequestsreceived" contains the current sentRequestUID
            Constants.Collections.UsersCollectionRef.whereField("friendrequestssent", arrayContains: receivedRequestUID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error querying documents: \(error)")
                    completion()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion()
                    return
                }
                
                // Loop over the matching documents and update the "hugrequestsreceived" field
                for document in documents {
                    var sentFriendRequests = document.data()["friendrequestssent"] as? [String] ?? []
                    // Remove the sentRequestUID from the "hugrequestsreceived" array
                    sentFriendRequests.removeAll { $0 == receivedRequestUID }
                    // Update the "hugrequestsreceived" field in Firestore
                    document.reference.updateData(["friendrequestssent": sentFriendRequests]) { (error) in
                        if let error = error {
                            print("Error updating document: \(error)")
                        }
                    }
                }
            }
        }
        completion()
    }
    
    func fetchSentFriendRequests(completion: @escaping ([String?]) -> ()) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Constants.Collections.UsersCollectionRef.document(uid).getDocument { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let document = querySnapshot, document.exists, let friendrequestssent = document.data()?["friendrequestssent"] as? [String] else {
                print("User document not found or friend requests array not present.")
                completion([])
                return
            }
            completion(friendrequestssent)
        }
    }
    
    func updateReceivedFriendRequests(withSentFriendRequests sentFriendRequests: [String?], completion: @escaping () -> Void) {
        for sentRequestUID in sentFriendRequests {
            // Query the "users" collection for documents where "hugrequestsreceived" contains the current sentRequestUID
            Constants.Collections.UsersCollectionRef.whereField("friendrequestsreceived", arrayContains: sentRequestUID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error querying documents: \(error)")
                    completion()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion()
                    return
                }
                
                // Loop over the matching documents and update the "hugrequestsreceived" field
                for document in documents {
                    var receivedFriendRequests = document.data()["friendrequestsreceived"] as? [String] ?? []
                    // Remove the sentRequestUID from the "hugrequestsreceived" array
                    receivedFriendRequests.removeAll { $0 == sentRequestUID }
                    // Update the "hugrequestsreceived" field in Firestore
                    document.reference.updateData(["friendrequestsreceived": receivedFriendRequests]) { (error) in
                        if let error = error {
                            print("Error updating document: \(error)")
                        }
                    }
                }
            }
        }
        completion()
    }
    
    func deleteFetchedFriendRequestsDocuments(friendRequests: [String?], completion: @escaping () -> ()) {
        let dispatchGroup = DispatchGroup()
        
        for friendRequest in friendRequests {
            // Check if the friend request is not nil before entering the DispatchGroup
            guard let friendRequest = friendRequest else {
                continue
            }
            
            dispatchGroup.enter()
            
            Constants.Collections.FriendRequestsCollectionRef.document(friendRequest).delete { error in
                if let error = error {
                    print("Failed to delete user account:", error.localizedDescription)
                } else {
                    print("User account deleted successfully")
                }
                
                // Notify the DispatchGroup that this task is completed
                dispatchGroup.leave()
            }
        }
        
        // This block will be called once all the enter() calls have been matched with leave() calls
        dispatchGroup.notify(queue: .main) {
            print("All hug requests have been deleted.")
            // Call the completion handler when all deletions are completed
            completion()
        }
    }
    
    func deleteFirebaseStorageElementsOfUser(completion: @escaping () -> ()) {
        // Create a DispatchGroup to track deletions
        let deletionGroup = DispatchGroup()
        
        let hugImgSentURLS = HugRequestsSentManager.shared.hugRequestsSent.compactMap { $0.hugRequestImage }
        let hugImgReceivedURLS = HugRequestsReceivedManager.shared.hugRequestsReceived.compactMap { $0.hugRequestImage }
        let hugsGottenURLS = HugPostsGottenManager.shared.hugPostsGotten.compactMap { $0.hugPicture }
        let hugsGivenURLS = HugsGivenManager.shared.hugPostsGiven.compactMap { $0.hugPicture }
        
        let storageRef = Storage.storage()
        
        // Delete hugImgSentURLS
        for hugImgSentURL in hugImgSentURLS {
            deletionGroup.enter() // Enter the DispatchGroup before each deletion
            let fileRef = storageRef.reference(forURL: hugImgSentURL)
            fileRef.delete { error in
                if let error = error {
                    print("Error deleting image from Firestore Storage: \(error.localizedDescription)")
                }
                deletionGroup.leave() // Leave the DispatchGroup when the deletion is done
            }
        }
        
        // Continue this pattern for other URLs...
        // Delete hugImgReceivedURLS
        for hugImgUrl in hugImgReceivedURLS {
            deletionGroup.enter() // Enter the DispatchGroup before each deletion
            let fileRef = storageRef.reference(forURL: hugImgUrl)
            fileRef.delete { error in
                if let error = error {
                    print("Error deleting image from Firestore Storage: \(error.localizedDescription)")
                }
                deletionGroup.leave() // Leave the DispatchGroup when the deletion is done
            }
        }
        
        // Delete hugsGottenURLS
        for hugGottenURL in hugsGottenURLS {
            deletionGroup.enter() // Enter the DispatchGroup before each deletion
            let fileRef = storageRef.reference(forURL: hugGottenURL)
            fileRef.delete { error in
                if let error = error {
                    print("Error deleting image from Firestore Storage: \(error.localizedDescription)")
                }
                deletionGroup.leave() // Leave the DispatchGroup when the deletion is done
            }
        }
        
        // Delete hugsGottehugsGivenURLSnURLS
        for hugGivenURL in hugsGivenURLS {
            deletionGroup.enter() // Enter the DispatchGroup before each deletion
            let fileRef = storageRef.reference(forURL: hugGivenURL)
            fileRef.delete { error in
                if let error = error {
                    print("Error deleting image from Firestore Storage: \(error.localizedDescription)")
                }
                deletionGroup.leave() // Leave the DispatchGroup when the deletion is done
            }
        }
        
        // Notify the completion handler when all deletions are complete
        deletionGroup.notify(queue: .main) {
            completion()
        }
    }
    
    
    
    func fetchHugRequestsSentImageUrls(hugrequests: [String?], completion: @escaping ([String]) -> ()) {
        // Create an array to store hugRequestImage URLs
        var hugRequestImageURLs: [String] = []
        
        let hugRequestsFiltered = hugrequests.compactMap { $0 }
        
        guard !hugRequestsFiltered.isEmpty else {
            completion([]) // Return an empty array if there are no URLs
            return
        }
        
        // Create a DispatchGroup
        let dispatchGroup = DispatchGroup()
        
        // Fetch the "hugRequestImage" values from the documents
        for documentID in hugRequestsFiltered {
            dispatchGroup.enter() // Enter the DispatchGroup before each fetch operation
            Constants.Collections.HugRequestsCollectionRef.document(documentID).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching document: \(error)")
                    // Handle the error if needed
                }
                if let data = document?.data(),
                   let hugRequestImageURL = data["hugRequestImage"] as? String {
                    // Store the hugRequestImageURL in the array
                    hugRequestImageURLs.append(hugRequestImageURL)
                    
                }
                
                dispatchGroup.leave() // Leave the DispatchGroup when the fetch operation is done
            }
        }
        
        // Notify the completion handler when all fetch operations are complete
        dispatchGroup.notify(queue: .main) {
            completion(hugRequestImageURLs) // Complete with the URLs
        }
    }
    
    func deleteImagesFromStorage(folderName: String, imageUrls: [String]) {
        let storageRef = Storage.storage().reference().child(folderName) // Use the appropriate folder name
        print("STORAGEREF: \(storageRef)")
        print("IMAGE URLS: \(imageUrls)")
        
        for imageURL in imageUrls {
            let imageRef = storageRef.child(imageURL)
            print("IMAGE REF:\(imageRef)")
            imageRef.delete { error in
                if let error = error {
                    print("Error deleting image from storage: \(error)")
                } else {
                    print("Image deleted from storage: \(imageURL)")
                }
            }
        }
    }
    
    func updateReceivedHugRequests(withSentHugRequests sentHugRequests: [String?], completion: @escaping () -> Void) {
        for sentRequestUID in sentHugRequests {
            // Query the "users" collection for documents where "hugrequestsreceived" contains the current sentRequestUID
            Constants.Collections.UsersCollectionRef.whereField("hugrequestsreceived", arrayContains: sentRequestUID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error querying documents: \(error)")
                    completion()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion()
                    return
                }
                
                // Loop over the matching documents and update the "hugrequestsreceived" field
                for document in documents {
                    var receivedHugRequests = document.data()["hugrequestsreceived"] as? [String] ?? []
                    // Remove the sentRequestUID from the "hugrequestsreceived" array
                    receivedHugRequests.removeAll { $0 == sentRequestUID }
                    // Update the "hugrequestsreceived" field in Firestore
                    document.reference.updateData(["hugrequestsreceived": receivedHugRequests]) { (error) in
                        if let error = error {
                            print("Error updating document: \(error)")
                        }
                    }
                }
            }
        }
        completion()
    }
    
    func deleteFetchedHugRequestsDocuments(hugRequests: [String?], completion: @escaping () -> ()) {
        let dispatchGroup = DispatchGroup()
        
        for hugRequest in hugRequests {
            // Check if the friend request is not nil before entering the DispatchGroup
            guard let hugRequest = hugRequest else {
                continue
            }
            
            dispatchGroup.enter()
            
            Constants.Collections.HugRequestsCollectionRef.document(hugRequest).delete { error in
                if let error = error {
                    print("Failed to delete user account:", error.localizedDescription)
                } else {
                    print("User account deleted successfully")
                }
                
                // Notify the DispatchGroup that this task is completed
                dispatchGroup.leave()
            }
        }
        
        // This block will be called once all the enter() calls have been matched with leave() calls
        dispatchGroup.notify(queue: .main) {
            print("All hug requests have been deleted.")
            // Call the completion handler when all deletions are completed
            completion()
        }
    }
    
    
    func fetchSentHugRequests(completion: @escaping ([String?]) -> ()) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Constants.Collections.UsersCollectionRef.document(uid).getDocument { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let document = querySnapshot, document.exists, let hugrequestssent = document.data()?["hugrequestssent"] as? [String] else {
                print("User document not found or friend requests array not present.")
                completion([])
                return
            }
            completion(hugrequestssent)
        }
    }
    
    func fetchReceivedHugRequests(completion: @escaping ([String?]) -> ()) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Constants.Collections.UsersCollectionRef.document(uid).getDocument { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let document = querySnapshot, document.exists, let hugrequestsreceived = document.data()?["hugrequestsreceived"] as? [String] else {
                print("User document not found or friend requests array not present.")
                completion([])
                return
            }
            completion(hugrequestsreceived)
        }
    }
    
    
    func updateSentHugRequests(withReceivedHugRequests receivedHugRequests: [String?], completion: @escaping () -> Void) {
        for receivedRequestUID in receivedHugRequests {
            // Query the "users" collection for documents where "hugrequestsreceived" contains the current sentRequestUID
            Constants.Collections.UsersCollectionRef.whereField("hugrequestssent", arrayContains: receivedRequestUID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error querying documents: \(error)")
                    completion()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion()
                    return
                }
                
                // Loop over the matching documents and update the "hugrequestsreceived" field
                for document in documents {
                    var sentHugRequests = document.data()["hugrequestssent"] as? [String] ?? []
                    // Remove the sentRequestUID from the "hugrequestsreceived" array
                    sentHugRequests.removeAll { $0 == receivedRequestUID }
                    // Update the "hugrequestsreceived" field in Firestore
                    document.reference.updateData(["hugrequestsreceived": sentHugRequests]) { (error) in
                        if let error = error {
                            print("Error updating document: \(error)")
                        }
                    }
                }
            }
        }
        completion()
    }
    
    func deleteFetchedHugRequestsReceivedDocuments(hugRequests: [String?], completion: @escaping () -> ()) {
        let dispatchGroup = DispatchGroup()
        
        for hugRequest in hugRequests {
            // Check if the friend request is not nil before entering the DispatchGroup
            guard let hugRequest = hugRequest else {
                continue
            }
            
            dispatchGroup.enter()
            
            Constants.Collections.HugRequestsCollectionRef.document(hugRequest).delete { error in
                if let error = error {
                    print("Failed to delete user account:", error.localizedDescription)
                } else {
                    print("User account deleted successfully")
                }
                
                // Notify the DispatchGroup that this task is completed
                dispatchGroup.leave()
            }
        }
        
        // This block will be called once all the enter() calls have been matched with leave() calls
        dispatchGroup.notify(queue: .main) {
            print("All hug requests have been deleted.")
            // Call the completion handler when all deletions are completed
            completion()
        }
    }
    
    func fetchHugRequestsReceivedImageUrls(hugrequests: [String?], completion: @escaping ([String]) -> ()) {
        // Create an array to store hugRequestImage URLs
        var hugRequestImageURLs: [String] = []
        
        let hugRequestsFiltered = hugrequests.compactMap { $0 }
        
        guard !hugRequestsFiltered.isEmpty else {
            completion([]) // Return an empty array if there are no URLs
            return
        }
        
        // Fetch the "hugRequestImage" values from the documents
        for documentID in hugRequestsFiltered {
            Constants.Collections.HugRequestsCollectionRef.document(documentID).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching document: \(error)")
                    completion([]) // Return an empty array in case of an error
                    return
                }
                
                if let data = document?.data(),
                   let hugRequestImageURL = data["hugRequestImage"] as? String {
                    // Store the hugRequestImageURL in the array
                    hugRequestImageURLs.append(hugRequestImageURL)
                }
            }
        }
        
        completion(hugRequestImageURLs) // Complete with the URLs
    }
    
    func fetchHugsGiven(completion: @escaping ([String?]) -> ()) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Constants.Collections.UsersCollectionRef.document(uid).getDocument { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let document = querySnapshot, document.exists, let hugsgiven = document.data()?["hugsgiven"] as? [String] else {
                print("User document not found or friend requests array not present.")
                completion([])
                return
            }
            completion(hugsgiven)
        }
    }
    
    func updateHugpostsGotten(withHugsGiven hugsgiven: [String?], completion: @escaping () -> Void) {
        for hugpostUID in hugsgiven {
            // Query the "users" collection for documents where "hugrequestsreceived" contains the current sentRequestUID
            Constants.Collections.UsersCollectionRef.whereField("hugsgotten", arrayContains: hugpostUID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error querying documents: \(error)")
                    completion()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion()
                    return
                }
                
                // Loop over the matching documents and update the "hugrequestsreceived" field
                for document in documents {
                    var hugsgotten = document.data()["hugsgotten"] as? [String] ?? []
                    // Remove the sentRequestUID from the "hugrequestsreceived" array
                    hugsgotten.removeAll { $0 == hugpostUID }
                    // Update the "hugrequestsreceived" field in Firestore
                    document.reference.updateData(["hugsgotten": hugsgotten]) { (error) in
                        if let error = error {
                            print("Error updating document: \(error)")
                        }
                    }
                }
            }
        }
        completion()
    }
    
    func fetchHugsGotten(completion: @escaping ([String?]) -> ()) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Constants.Collections.UsersCollectionRef.document(uid).getDocument { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let document = querySnapshot, document.exists, let hugsgotten = document.data()?["hugsgotten"] as? [String] else {
                print("User document not found or friend requests array not present.")
                completion([])
                return
            }
            completion(hugsgotten)
        }
    }
    
    func updateHugposts(withHugsGotten hugsgotten: [String?], completion: @escaping () -> Void) {
        for hugpostUID in hugsgotten {
            // Query the "users" collection for documents where "hugrequestsreceived" contains the current sentRequestUID
            Constants.Collections.UsersCollectionRef.whereField("hugsgiven", arrayContains: hugpostUID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error querying documents: \(error)")
                    completion()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion()
                    return
                }
                
                // Loop over the matching documents and update the "hugrequestsreceived" field
                for document in documents {
                    var hugsgiven = document.data()["hugsgiven"] as? [String] ?? []
                    // Remove the sentRequestUID from the "hugrequestsreceived" array
                    hugsgiven.removeAll { $0 == hugpostUID }
                    // Update the "hugrequestsreceived" field in Firestore
                    document.reference.updateData(["hugsgiven": hugsgiven]) { (error) in
                        if let error = error {
                            print("Error updating document: \(error)")
                        }
                    }
                }
            }
        }
        completion()
    }
    
    func deleteHugsGottenDocumentsInHugPostsCollection(hugsGotten: [String?], completion: @escaping () -> ()) {
        let dispatchGroup = DispatchGroup()
        
        for hug in hugsGotten {
            // Check if the friend request is not nil before entering the DispatchGroup
            guard let hug = hug else {
                continue
            }
            
            dispatchGroup.enter()
            
            Constants.Collections.HugPostsRef.document(hug).delete { error in
                if let error = error {
                    print("Failed to delete user account:", error.localizedDescription)
                } else {
                    print("User account deleted successfully")
                }
                
                // Notify the DispatchGroup that this task is completed
                dispatchGroup.leave()
            }
        }
        
        // This block will be called once all the enter() calls have been matched with leave() calls
        dispatchGroup.notify(queue: .main) {
            print("All hugs have been deleted.")
            // Call the completion handler when all deletions are completed
            completion()
        }
    }
    
    func fetchHugsGottenImageUrls(hugsGotten: [String?], completion: @escaping ([String]) -> ()) {
        // Create an array to store hugRequestImage URLs
        var hugsGottenImageURLS: [String] = []
        
        let hugsGottenFiltered = hugsGotten.compactMap { $0 }
        
        guard !hugsGottenFiltered.isEmpty else {
            completion([]) // Return an empty array if there are no URLs
            return
        }
        
        // Fetch the "hugRequestImage" values from the documents
        for documentID in hugsGottenFiltered {
            Constants.Collections.HugPostsRef.document(documentID).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching document: \(error)")
                    completion([]) // Return an empty array in case of an error
                    return
                }
                
                if let data = document?.data(),
                   let hugGottenImageURL = data["hugPicture"] as? String {
                    // Store the hugRequestImageURL in the array
                    hugsGottenImageURLS.append(hugGottenImageURL)
                }
            }
        }
        
        completion(hugsGottenImageURLS) // Complete with the URLs
    }
    
    func removeFriendFromAllUsers(completion: @escaping (Error?) -> Void) {
        let usersRef = Constants.Collections.UsersCollectionRef
        guard let appUserUsername = AppUserSingleton.shared.appUser?.userName else {
            print("No app user in ProfileVC function 'removedFriendFromAllUsers'")
            return
        }
        
        usersRef.whereField(Constants.Firebase.FRIENDS, arrayContains: appUserUsername).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(error)
                return
            }
            
            for document in querySnapshot!.documents {
                guard var friendsArray = document.data()[Constants.Firebase.FRIENDS] as? [String] else {
                    print("Error: 'friends' field is not an array of strings.")
                    continue
                }
                
                if let index = friendsArray.firstIndex(of: appUserUsername) {
                    friendsArray.remove(at: index)
                }
                
                // Update the 'friends' array in the document
                usersRef.document(document.documentID).updateData([Constants.Firebase.FRIENDS: friendsArray]) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                        completion(error)
                    } else {
                        print("Friend removed from document with ID: \(document.documentID)")
                    }
                }
            }
            
            completion(nil) // Success, no errors
        }
    }
    
    func deleteEmail(completion: @escaping (Bool, Error?) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            currentUser.delete { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        } else {
            completion(false, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."]))
        }
    }
    
    
    func deleteUser(completion: @escaping (Bool, Error?) -> Void) {
        
        guard let currentUserUID = AppUserSingleton.shared.appUser?.uid else {
            print("No document ID. Delete User aborted")
            return
        }
        
        Constants.Collections.UsersCollectionRef.document(currentUserUID).delete { error in
            if let error = error {
                print("Failed to delete user account:", error.localizedDescription)
                completion(false,error)
            } else {
                print("User account deleted successfully")
                completion(true,nil)
            }
        }
    }
    
}

extension ProfileViewVC: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let currentUser = Auth.auth().currentUser else { return }
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Successfully authenticated with Apple ID
            if let identityTokenData = appleIDCredential.identityToken {
                let identityTokenString = String(data: identityTokenData, encoding: .utf8) // Convert to string
                let appleCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: identityTokenString ?? "", rawNonce: nil)
                
                currentUser.reauthenticate(with: appleCredential) { [weak self] (authResult, error) in
                    if let error = error {
                        // Reauthentication failed
                        self?.showReauthenticationErrorAlert(errorMessage: error.localizedDescription)
                    } else {
                        // Reauthentication successful
                        // Proceed with user deletion
                        self?.deleteUserAccount()
                    }
                }
            }
        }
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle Apple Sign-In error
        print("Apple Sign-In error: \(error.localizedDescription)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}



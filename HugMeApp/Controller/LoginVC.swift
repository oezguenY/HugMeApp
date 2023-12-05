//
//  LoginVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 16.08.22.
//

import UIKit
import Firebase
import Kingfisher
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class LoginVC: UIViewController {
    
    let firestoreListenerManager = FirestoreListenerManager.shared
    
    let emailTF = UITextField()
    let passwordTF = UITextField()
    let logInBtn = UIButton()
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    let forgotPWBtn = UIButton()
    
    private func createNavigationItem() {
        let dismissButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissSelf))
        
        // Define the text attributes for the button title
        let textAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white, // Change the color to white
        ]
        
        // Apply the text attributes to the button's title
        dismissButton.setTitleTextAttributes(textAttributes, for: .normal)
        
        navigationItem.leftBarButtonItem = dismissButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        addSubviews()
        setUpUI()
        createNavigationItem()
        addConstraints()
        self.clearCachesAndData()
        firestoreListenerManager.removeAllListeners()
        fetchUserDataAndNavigate()
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func transitionToWelcomeScreen() {
        let welcomeVC = WelcomeVC()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = welcomeVC
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Auth.auth().currentUser != nil {
            emailTF.isHidden = true
            passwordTF.isHidden = true
            logInBtn.isHidden = true
            forgotPWBtn.isHidden = true
            loadingIndicator.startAnimating()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loadingIndicator.stopAnimating()
    }
    
    func fetchUserDataAndNavigate() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            return
        }
        let userRef = Firestore.firestore().collection(Constants.Firebase.USERS).document(userUID)
        userRef.getDocument { (document, err) in
            if let document = document, document.exists {
                guard let data = document.data(), let appUser = try? Firestore.Decoder().decode(AppUser.self, from: data) else {
                    print("Failed to decode App User")
                    self.loadingIndicator.stopAnimating()
                    return
                }
                AppUserSingleton.shared.appUser = appUser
                print("AppUser in LoginVC: \(appUser)")
                // Fetch all required data
                self.fetchAllData(appUser: appUser) {
                    // This completion handler will be called after all data is fetched
                    self.loadingIndicator.stopAnimating()
                    self.transitionToProfileVC()
                }
            }
        }
    }
    
    
    private func addSubviews() {
        view.addSubview(emailTF)
        view.addSubview(passwordTF)
        view.addSubview(logInBtn)
        view.addSubview(loadingIndicator)
        view.addSubview(forgotPWBtn)
    }
    
    private func setUpUI() {
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
               NSAttributedString.Key.foregroundColor: UIColor.gray, // Change the color to your desired color
           ]
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        emailTF.translatesAutoresizingMaskIntoConstraints = false
        emailTF.placeholder = "Email"
        emailTF.text = ""
        emailTF.textColor = .black
        emailTF.keyboardType = UIKeyboardType.default
        emailTF.returnKeyType = UIReturnKeyType.done
        emailTF.autocorrectionType = UITextAutocorrectionType.no
        emailTF.font = UIFont.systemFont(ofSize: 13)
        emailTF.borderStyle = UITextField.BorderStyle.roundedRect
        emailTF.clearButtonMode = UITextField.ViewMode.whileEditing
        emailTF.widthAnchor.constraint(equalToConstant: AppDelegate.screenWidth / 1.5).isActive = true
        emailTF.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emailTF.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        emailTF.layer.borderWidth = 1.0 // You can adjust the border width as well
        emailTF.layer.cornerRadius = 5.0
        emailTF.layer.borderColor = UIColor.black.cgColor
        emailTF.backgroundColor = .white
        emailTF.attributedPlaceholder = NSAttributedString(string: "Email", attributes: placeholderAttributes)
        
        passwordTF.translatesAutoresizingMaskIntoConstraints = false
        passwordTF.placeholder = "Password"
        passwordTF.text = ""
        passwordTF.textColor = .black
        passwordTF.keyboardType = UIKeyboardType.default
        passwordTF.returnKeyType = UIReturnKeyType.done
        passwordTF.autocorrectionType = UITextAutocorrectionType.no
        passwordTF.font = UIFont.systemFont(ofSize: 13)
        passwordTF.borderStyle = UITextField.BorderStyle.roundedRect
        passwordTF.clearButtonMode = UITextField.ViewMode.whileEditing
        passwordTF.widthAnchor.constraint(equalToConstant: AppDelegate.screenWidth / 1.5).isActive = true
        passwordTF.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        passwordTF.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        passwordTF.layer.borderWidth = 1.0 // You can adjust the border width as well
        passwordTF.layer.cornerRadius = 5.0
        passwordTF.layer.borderColor = UIColor.black.cgColor
        passwordTF.backgroundColor = .white
        passwordTF.attributedPlaceholder = NSAttributedString(string: "Password", attributes: placeholderAttributes)
        
        logInBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logInBtn.setTitle("Log in", for: .normal)
        logInBtn.titleLabel?.font = UIFont(name: "HelveticaNeue", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 10)
        logInBtn.setTitleColor(#colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1), for: .normal)
        logInBtn.translatesAutoresizingMaskIntoConstraints = false
        logInBtn.addTarget(self, action: #selector(logIn), for: .touchUpInside)
        
        forgotPWBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        forgotPWBtn.setTitle("Forgot Password?", for: .normal)
        forgotPWBtn.titleLabel?.font = UIFont(name: "HelveticaNeue", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 7)
        forgotPWBtn.setTitleColor(.white, for: .normal)
        forgotPWBtn.translatesAutoresizingMaskIntoConstraints = false
        forgotPWBtn.addTarget(self, action: #selector(forgotPWBtnTapped), for: .touchUpInside)
    }
    
    private func addConstraints() {
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(NSLayoutConstraint(item: emailTF, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: AppDelegate.screenHeight / 7))
        constraints.append(NSLayoutConstraint(item: passwordTF, attribute: .top, relatedBy: .equal, toItem: emailTF, attribute: .bottom, multiplier: 1.0, constant: 20))
        constraints.append(NSLayoutConstraint(item: logInBtn, attribute: .top, relatedBy: .equal, toItem: passwordTF, attribute: .bottom, multiplier: 1.0, constant: 20))
        constraints.append(NSLayoutConstraint(item: forgotPWBtn, attribute: .top, relatedBy: .equal, toItem: logInBtn, attribute: .bottom, multiplier: 1.0, constant: AppDelegate.screenHeight / 100))
        constraints.append(NSLayoutConstraint(item: forgotPWBtn, attribute: .centerX, relatedBy: .equal, toItem: logInBtn, attribute: .centerX, multiplier: 1.0, constant: 0))
        
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func forgotPWBtnTapped() {
        let alertController = UIAlertController(title: "Forgot Password", message: "Enter your E-Mail", preferredStyle: .alert)
        
        // Create a UITextField
        alertController.addTextField { textField in
            textField.placeholder = "E-Mail"
            textField.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
        }
        
        // Create the "Cancel" button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        // Create the "Send" button (initially disabled)
        let sendAction = UIAlertAction(title: "Send", style: .default) { _ in
            guard let emailTextField = alertController.textFields?.first,
                  let email = emailTextField.text?.lowercased() else {
                return
            }
            
            self.sendPasswordResetEmail(forEmail: email) { error in
                if let error = error {
                    // Handle the error (e.g., show an alert)
                    print("Password reset error: \(error.localizedDescription)")
                } else {
                    // Password reset email sent successfully
                    print("Password reset email sent successfully.")
                }
            }
        }
        sendAction.isEnabled = false
        
        alertController.addAction(cancelAction)
        alertController.addAction(sendAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func textChanged(sender: UITextField) {
        // Enable the "Send" button only if there is text in the UITextField
        let alertController = presentedViewController as? UIAlertController
        let sendAction = alertController?.actions.first { $0.title == "Send" }
        sendAction?.isEnabled = !sender.text!.isEmpty
    }
    
    
    func sendPasswordResetEmail(forEmail email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    
    @objc func logIn() {
        loadingIndicator.startAnimating()
        disableTextFieldsAfterLogIn()
        guard let email = emailTF.text, !email.isEmpty,
              let password = passwordTF.text, !password.isEmpty else {
            loadingIndicator.stopAnimating()
            return
        }
        print("User's Email is: \(email)")
        Auth.auth().signIn(withEmail: email.lowercased(), password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                print(error.localizedDescription)
                self.loadingIndicator.stopAnimating()
                return
            } else {
                let userRef = Firestore.firestore().collection(Constants.Firebase.USERS).document(authResult?.user.uid ?? "")
                userRef.getDocument { (document, err) in
                    if let document = document, document.exists {
                        guard let data = document.data(), let appUser = try? Firestore.Decoder().decode(AppUser.self, from: data) else {
                            print("Failed to decode App User")
                            self.loadingIndicator.stopAnimating()
                            return
                        }
                        AppUserSingleton.shared.appUser = appUser
                        // Fetch all required data
                        self.fetchAllData(appUser: appUser) {
                            // This completion handler will be called after all data is fetched
                            self.loadingIndicator.stopAnimating()
                            self.transitionToProfileVC()
                        }
                    }
                }
            }
        }
    }
    
    func fetchAllData(appUser: AppUser, completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        // Fetch friend requests
        dispatchGroup.enter()
        self.fetchFriendRequests(documentIDs: appUser.friendrequestsReceived) { result in
            switch result {
            case .success(let friendRequests):
                let sortedFriendRequests = friendRequests.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                FriendRequestsReceivedManager.shared.friendRequestsReceived = sortedFriendRequests
            case .failure(let error):
                print("Error fetching friend requests: \(error)")
            }
            dispatchGroup.leave()
        }
        
//         Fetch sent friend requests
        dispatchGroup.enter()
        self.fetchUserSentFriendRequests { friendRequestsSent, error in
            if let error = error {
                print("Error fetching sent friend requests: \(error)")
            } else {
                let sortedSentFriendRequests = friendRequestsSent.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                FriendRequestsSentManager.shared.friendRequestsSent = sortedSentFriendRequests
            }
            dispatchGroup.leave()
        }
        
//         Fetch friends
        dispatchGroup.enter()
        self.fetchFriends(appUser: appUser) { result in
            switch result {
            case .success(let friends):
                FriendsManager.shared.friends = friends
            case .failure(let error):
                print("Error fetching friends: \(error)")
            }
            dispatchGroup.leave()
        }
        
        // Fetch 20 most recent discovery posts
        dispatchGroup.enter()
        fetchTwentyDiscoveryPosts { recentDiscoveryPosts, error in
            if let error = error {
                print("Error fetching recent discovery posts: \(error)")
            } else {
                let sortedDiscoveryPosts = recentDiscoveryPosts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                HugPostsDiscoveryManager.shared.hugPostsDiscovery = sortedDiscoveryPosts
            }
            dispatchGroup.leave()
        }
        
        // MARK: - fetchHugPostsOfFriends produces a bug
        
        dispatchGroup.enter()
        fetchHugPostsOfFriends(appUser: appUser) { friendsHugPosts, error in
            if let error = error {
                print("Error fetching friend's posts: \(error)")
            } else {
                let sortedFriendsPosts = friendsHugPosts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                HugPostsFriendsManager.shared.hugPosts = sortedFriendsPosts
            }
            dispatchGroup.leave()
        }
        
        // Fetch user hug posts
        dispatchGroup.enter()
        self.fetchUserHugPosts { hugPosts, error in
            if let error = error {
                print("Error fetching user hug posts: \(error)")
            } else {
                let sortedHugPosts = hugPosts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                HugPostsGottenManager.shared.hugPostsGotten = sortedHugPosts
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.fetchUsersGivenHugPosts { hugPosts, error in
            if let error = error {
                print("Error fetching user hug posts: \(error)")
            } else {
                let sortedHugPosts = hugPosts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                HugsGivenManager.shared.hugPostsGiven = sortedHugPosts
            }
            dispatchGroup.leave()
        }
        
        // Fetch user hug requests
        dispatchGroup.enter()
        self.fetchUserHugRequestsReceived { hugRequests, error in
            if let error = error {
                print("Error fetching user hug requests: \(error)")
            } else {
                let sortedHugRequests = hugRequests.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                HugRequestsReceivedManager.shared.hugRequestsReceived = sortedHugRequests
            }
            dispatchGroup.leave()
        }
        
        // Fetch user sent hug requests
        dispatchGroup.enter()
        self.fetchUserHugRequestsSent { sentHugRequests, error in
            if let error = error {
                print("Error fetching user sent hug requests: \(error)")
            } else {
                let sortedSentHugRequests = sentHugRequests.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                HugRequestsSentManager.shared.hugRequestsSent = sortedSentHugRequests
            }
            dispatchGroup.leave()
        }
        
        // Notify completion when all data is fetched
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    
    
    func fetchFriendRequests(documentIDs: [String?], completion: @escaping (Result<[FriendRequest], Error>) -> ()) {
        guard !documentIDs.isEmpty else {
            completion(.success([]))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        let firebaseDecoder = Firestore.Decoder()
        var friendRequests: [FriendRequest] = []
        
        for documentID in documentIDs {
            dispatchGroup.enter()
            
            Constants.Collections.FriendRequestsCollectionRef.document(documentID ?? "").getDocument { snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    completion(.failure(error))
                    return
                }
                
                if let data = snapshot?.data() {
                    do {
                        // Attempt to decode FriendRequest using the Firestore.Decoder
                        let friendRequest = try firebaseDecoder.decode(FriendRequest.self, from: data)
                        friendRequests.append(friendRequest)
                    } catch {
                        // Handle the error if the decoding fails
                        print("Error decoding document: \(error)")
                        // If there's an error, you might want to append nil to the array or handle it differently
                    }
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(friendRequests))
        }
    }
    
    func fetchFriends(appUser: AppUser, completion: @escaping (Result<[AppUser], Error>) -> ()) {
        let dispatchGroup = DispatchGroup()
        var friendUsers: [AppUser] = []
        
        let friends = appUser.friends
        
        if friends.isEmpty {
            completion(.success([]))
            return
        }
        
        dispatchGroup.enter() // Enter the DispatchGroup
        
        Constants.Collections.UsersCollectionRef
            .whereField("username", in: friends) // Filter by usernames in the friends array
            .getDocuments { userQuerySnapshot, userError in
                if let userError = userError {
                    dispatchGroup.leave() // Leave the DispatchGroup in case of an error
                    completion(.failure(userError))
                    return
                }
                
                for userDocument in userQuerySnapshot!.documents {
                    
                    do {
                        let friendUser = try Firestore.Decoder().decode(AppUser.self, from: userDocument.data())
                        let simplifiedFriendUser = AppUser(simplifiedFrom: friendUser)
                        friendUsers.append(simplifiedFriendUser)
                    } catch {
                        print("Error decoding friend document: \(error.localizedDescription)")
                    }
                }
                
                dispatchGroup.leave() // Leave the DispatchGroup after processing all documents
            }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(friendUsers))
        }
    }
    
    func fetchTwentyDiscoveryPosts(completion: @escaping ([Hug], Error?) -> Void) {
        let hugPostsCollectionRef = Constants.Collections.HugPostsRef
        var recentHugPosts: [Hug] = []
        var lastDocument: QueryDocumentSnapshot?
        
        let dispatchGroup = DispatchGroup() // Create a DispatchGroup
        
        dispatchGroup.enter() // Enter the DispatchGroup
        
        hugPostsCollectionRef
            .order(by: "timestamp", descending: true)
            .limit(to: 20) // Fetch the most recent 20 hug posts
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let _ = self, let querySnapshot = querySnapshot else {
                    // Handle error or nil self
                    dispatchGroup.leave() // Leave the DispatchGroup
                    completion([], error)
                    return
                }
                
                for document in querySnapshot.documents {
                    do {
                        let hugPost = try document.data(as: Hug.self)
                        recentHugPosts.append(hugPost)
                    } catch {
                        print("Error decoding hug post document: \(error)")
                    }
                    // THE REF OF THE LAST DOCUMENT IN THE FOR LOOP WILL BE SAVED IN lastDocument
                    lastDocument = querySnapshot.documents.last
                    PaginationHugPostsDiscoveryManager.shared.lastDocumentRef = lastDocument
                    
                }
                
                dispatchGroup.leave() // Leave the DispatchGroup
            }
        
        dispatchGroup.notify(queue: .main) {
            // This closure is called when all async tasks in the DispatchGroup are done
            completion(recentHugPosts, nil)
        }
    }
    
    func fetchHugPostsOfFriends(appUser: AppUser, completion: @escaping ([Hug], Error?) -> ()) {
        let dispatchGroup = DispatchGroup()
        var friendHugPosts: [Hug] = []
        var hugErrorOccurred: Error?
        var lastDocument: QueryDocumentSnapshot?
//        guard let friends = appUser.friends, !friends.isEmpty else {
//            // Screen didn't pass the loginVC; error was due to lack of call to completion closure - always call the completion closure
//            completion([], nil)
//            return
//        }
        
        let friends = appUser.friends
        
        if friends.isEmpty {
            completion([], nil)
            return
        }
        
        
        dispatchGroup.enter()
        
        Constants.Collections.HugPostsRef
            .whereField("receiverUsername", in: friends) // Filter by friend usernames
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments { hugQuerySnapshot, hugError in
                if let hugError = hugError {
                    hugErrorOccurred = hugError
                    print("Error fetching friend's hug posts: \(hugError)")
                } else {
                    for hugDocument in hugQuerySnapshot!.documents {
                        do {
                            let friendHugPost = try Firestore.Decoder().decode(Hug.self, from: hugDocument.data())
                            friendHugPosts.append(friendHugPost)
                        } catch {
                            print("Error decoding friend's hug post document: \(error.localizedDescription)")
                        }
                        lastDocument = hugDocument
                        PaginationHugPostsFriendsManager.shared.lastDocumentRef = lastDocument
                    }
                    
                    dispatchGroup.leave()
                }
            }
        
        dispatchGroup.notify(queue: .main) {
            if let error = hugErrorOccurred {
                completion([], error)
            } else {
                completion(friendHugPosts, nil)
            }
        }
        
    }
  
    
    func fetchUserHugPosts(completion: @escaping ([Hug], Error?) -> ()) {
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            completion([], NSError(domain: "AppErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user's username not found."]))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var hugPosts: [Hug] = []
        
        Constants.Collections.HugPostsRef
            .whereField("receiverUsername", isEqualTo: currentUserUsername)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion([], error) // Pass Firestore error
                    print("Error fetching hugPosts: \(error)")
                    return
                }
                
                for document in querySnapshot!.documents {
                    dispatchGroup.enter()
                    do {
                        let hugPost = try Firestore.Decoder().decode(Hug.self, from: document.data())
                        hugPosts.append(hugPost)
                    } catch {
                        print("Error decoding hug post document: \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) {
                    completion(hugPosts, nil)
                }
            }
    }
    
    func fetchUsersGivenHugPosts(completion: @escaping ([Hug], Error?) -> ()) {
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            completion([], NSError(domain: "AppErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user's username not found."]))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var hugPosts: [Hug] = []
        
        Constants.Collections.HugPostsRef
            .whereField("senderUsername", isEqualTo: currentUserUsername)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion([], error) // Pass Firestore error
                    print("Error fetching hugPosts: \(error)")
                    return
                }
                
                for document in querySnapshot!.documents {
                    dispatchGroup.enter()
                    do {
                        let hugPost = try Firestore.Decoder().decode(Hug.self, from: document.data())
                        hugPosts.append(hugPost)
                    } catch {
                        print("Error decoding hug post document: \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) {
                    completion(hugPosts, nil)
                }
            }
    }
    
    
    
    func fetchUserHugRequestsReceived(completion: @escaping ([HugRequest], Error?) -> ()) {
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            completion([], NSError(domain: "AppErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user's username not found."]))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var hugRequests: [HugRequest] = []
        var errorOccurred: Error?
        
        Constants.Collections.HugRequestsCollectionRef
            .whereField("receiver", isEqualTo: currentUserUsername)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    errorOccurred = error
                    print("Error fetching hugRequests: \(error)")
                }
                
                for document in querySnapshot!.documents {
                    dispatchGroup.enter()
                    do {
                        let hugRequest = try Firestore.Decoder().decode(HugRequest.self, from: document.data())
                        hugRequests.append(hugRequest)
                    } catch {
                        print("Error decoding hug request document: \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) {
                    if let error = errorOccurred {
                        completion([], error)
                    } else {
                        completion(hugRequests, nil)
                    }
                }
            }
    }
    
    func fetchUserHugRequestsSent(completion: @escaping ([HugRequest], Error?) -> ()) {
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            completion([], NSError(domain: "AppErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user's username not found."]))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var sentHugRequests: [HugRequest] = []
        var errorOccurred: Error?
        
        Constants.Collections.HugRequestsCollectionRef
            .whereField("sender", isEqualTo: currentUserUsername)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    errorOccurred = error
                    print("Error fetching sent hug requests: \(error)")
                }
                
                for document in querySnapshot!.documents {
                    dispatchGroup.enter()
                    do {
                        let sentHugRequest = try Firestore.Decoder().decode(HugRequest.self, from: document.data())
                        sentHugRequests.append(sentHugRequest)
                    } catch {
                        print("Error decoding sent hug request document: \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) {
                    if let error = errorOccurred {
                        completion([], error)
                    } else {
                        completion(sentHugRequests, nil)
                    }
                }
            }
    }
    
    
    func fetchUserSentFriendRequests(completion: @escaping ([FriendRequest], Error?) -> ()) {
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            completion([], NSError(domain: "AppErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user's username not found."]))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var sentFriendRequests: [FriendRequest] = []
        var errorOccurred: Error?
        
        Constants.Collections.FriendRequestsCollectionRef
            .whereField("senderUsername", isEqualTo: currentUserUsername)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    errorOccurred = error
                    print("Error fetching sent friend requests: \(error)")
                }
                
                for document in querySnapshot!.documents {
                    dispatchGroup.enter()
                    do {
                        let sentFriendRequest = try Firestore.Decoder().decode(FriendRequest.self, from: document.data())
                        sentFriendRequests.append(sentFriendRequest)
                    } catch {
                        print("Error decoding sent friend request document: \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) {
                    if let error = errorOccurred {
                        completion([], error)
                    } else {
                        completion(sentFriendRequests, nil)
                    }
                }
            }
    }
    
//    func transitionToLastViewController() {
//        let tabbar = TabBar()
//        if let lastViewController = tabbar.viewControllers?.last {
//            // Optionally, you can configure the lastViewController here
//            // For example, you can set properties or perform any necessary setup
//            
//            // Switch to the last view controller
//            self.present(lastViewController, animated: true)
//        }
//    }

    
    func transitionToProfileVC() {
        let tabbar = TabBar()
        tabbar.modalPresentationStyle = .fullScreen
        self.present(tabbar, animated: true)
    }
    
    // MARK: - Without this function, the appropriate UI elements for the user will not load, because the textfields are still active and intefere with the UI of the ProfileVC for some reason
    func disableTextFieldsAfterLogIn() {
        self.emailTF.isUserInteractionEnabled = false
        self.passwordTF.isUserInteractionEnabled = false
    }
}

//
//  InitialVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 30.08.22.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import FirebaseMessaging

class WelcomeVC: UIViewController {
    
    var appleUserIdentifier: String?
    var appleCredential: OAuthCredential?
    
    var googleUser: GIDGoogleUser?
    var googleCredential: AuthCredential?
    
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    let firestoreListenerManager = FirestoreListenerManager.shared
    
    let signInConfig = GIDConfiguration(clientID: "145811182354-vserm3bcp85f1g65njgvo5f55lpcrg0t.apps.googleusercontent.com")
    //    let signInWithGoogleButton = GIDSignInButton()
    let signInWithGoogleButton = UIButton()
    let signInWithAppleButton = UIButton()
    let createAccountButton = UIButton()
    let signInButton = UIButton()
    let db = Firestore.firestore()
    
    var logOutResult: LogoutResult?
    
    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Send hugs to the people you love or you want to be loved by."
        label.font = UIFont(name: "HelveticaNeue-Thin", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 21)
        label.numberOfLines = 0
        label.textColor = .white
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    let logInLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.text = "Have an account already?"
        label.font = UIFont(name: "HelveticaNeue-Thin", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 11)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpView()
        self.setUpSignInButtons()
        self.addConstraints()
        self.view.backgroundColor = .black
        NotificationCenter.default.addObserver(self, selector: #selector(profileDeleted(_:)), name: NSNotification.Name("ProfileDeletedNotification"), object: nil)
        self.firestoreListenerManager.removeAllListeners()
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        self.logOutPreviousUser { result in
            switch result {
            case .noPreviouslyAuthenticatedUser:
                self.logOutResult = .noPreviouslyAuthenticatedUser
                print("NO PREVIOUSLY AUTHENTICATED USER!")
            case .previouslyAuthenticatedUserCouldNotBeLoggedOut(let error):
                self.logOutResult = .previouslyAuthenticatedUserCouldNotBeLoggedOut(error.localizedDescription as! Error)
                print("PREVIOUSLY AUTHENTICATED USER COULD NOT BE LOGGED OUT!")
            case .previouslyAuthenticatedUserWasLoggedOut:
                self.logOutResult = .previouslyAuthenticatedUserWasLoggedOut
                print("PREVIOUSLY AUTHENTICATED USER WAS LOGGED OUT!")
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Auth.auth().currentUser == nil {
            print("Current user is nil")
        } else {
            print("Thereis a current user")
        }
    }
    
    @objc func profileDeleted(_ notification: Notification) {
        // Show an alert indicating that the profile was deleted
        let alertController = UIAlertController(title: "Profile Deleted", message: "Your profile was deleted.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func setUpSignInButtons() {
        
        let googleImage = UIImage(named: "google")
        self.signInWithGoogleButton.translatesAutoresizingMaskIntoConstraints = false
        self.signInWithGoogleButton.setImage(googleImage, for: .normal)
        self.signInWithGoogleButton.setTitle("", for: .normal)
        self.signInWithGoogleButton.imageView?.contentMode = .scaleAspectFit
        self.signInWithGoogleButton.setTitleColor(.white, for: .normal)
        self.signInWithGoogleButton.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 16).isActive = true
        self.signInWithGoogleButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.signInWithGoogleButton.layer.cornerRadius = 5
        self.signInWithGoogleButton.layer.borderWidth = 1
        self.signInWithGoogleButton.layer.borderColor = UIColor.white.cgColor
        self.signInWithGoogleButton.addTarget(self, action: #selector(signInWithGoogle), for: .touchUpInside)
        
        let appleImage = UIImage(systemName: "apple.logo")
        self.signInWithAppleButton.tintColor = .white
        self.signInWithAppleButton.translatesAutoresizingMaskIntoConstraints = false
        self.signInWithAppleButton.setImage(appleImage, for: .normal)
        self.signInWithAppleButton.imageView?.contentMode = .scaleAspectFill
        self.signInWithAppleButton.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 16).isActive = true
        self.signInWithAppleButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.signInWithAppleButton.layer.cornerRadius = 5
        self.signInWithAppleButton.layer.borderWidth = 1
        self.signInWithAppleButton.layer.borderColor = UIColor.white.cgColor
        self.signInWithAppleButton.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)
        
        self.createAccountButton.translatesAutoresizingMaskIntoConstraints = false
        self.createAccountButton.setTitle("Create Account", for: .normal)
        self.createAccountButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 11)
        self.createAccountButton.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 16).isActive = true
        self.createAccountButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.createAccountButton.backgroundColor = .black
        self.createAccountButton.setTitleColor(.white, for: .normal)
        self.createAccountButton.layer.cornerRadius = 5
        self.createAccountButton.layer.borderWidth = 1
        self.createAccountButton.layer.borderColor = UIColor.white.cgColor
        self.createAccountButton.addTarget(self, action: #selector(createAccountButtonPressed), for: .touchUpInside)
        
        self.signInButton.translatesAutoresizingMaskIntoConstraints = false
        self.signInButton.setTitle("Log in", for: .normal)
        self.signInButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 9)
        self.signInButton.setTitleColor(#colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1), for: .normal)
        self.signInButton.addTarget(self, action: #selector(signInPressed), for: .touchUpInside)
    }
    
    
    @objc func signInWithApple() {
        switch logOutResult {
        case .noPreviouslyAuthenticatedUser:
            break
        case .previouslyAuthenticatedUserWasLoggedOut:
            break
        case .previouslyAuthenticatedUserCouldNotBeLoggedOut(let error):
            print("Previously authenticated user could not be logged out: \(error.localizedDescription)")
            return
        case nil:
            return
        }
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // Implement the ASAuthorizationControllerDelegate method
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let appleUserIdentifier = appleIDCredential.user
            if let identityTokenData = appleIDCredential.identityToken {
                if let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                    // Create an OAuthCredential using the Apple ID credential
                    let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                              idToken: identityTokenString,
                                                              rawNonce: nil)
                    
                    self.appleCredential = credential
                    self.appleUserIdentifier = appleUserIdentifier
                    
                    self.checkAppleUserExistence(identityToken: appleUserIdentifier) { [weak self] userExists in
                        guard let self = self else { return }
                        
                        if userExists {
                            Auth.auth().signIn(with: credential) { authResult, error in
                                if let error = error {
                                    print("Firebase Sign-In error: \(error.localizedDescription)")
                                    // Handle the sign-in error appropriately
                                } else {
                                    // Firebase Authentication sign-in was successful
                                    print("Firebase Sign-In successful")
                                    
                                    // Continue with the code to fetch user data and transition to the home screen
                                    self.loadingIndicator.startAnimating()
                                    self.db.collection(Constants.Firebase.USERS)
                                        .whereField("appleUserIdentifier", isEqualTo: appleUserIdentifier)
                                        .getDocuments { (querySnapshot, error) in
                                            if let error = error {
                                                print("Error fetching user document: \(error.localizedDescription)")
                                                self.loadingIndicator.stopAnimating()
                                                return
                                            }
                                            
                                            // Check if a document exists
                                            guard let document = querySnapshot?.documents.first,
                                                  let appUser = try? Firestore.Decoder().decode(AppUser.self, from: document.data()) else {
                                                print("User document not found.")
                                                self.loadingIndicator.stopAnimating()
                                                return
                                            }
                                            
                                            // Set the retrieved AppUser instance in your singleton
                                            AppUserSingleton.shared.appUser = appUser
                                            
                                            self.fetchAllData(appUser: appUser) {
                                                // This completion handler will be called after all data is fetched
                                                self.loadingIndicator.stopAnimating()
                                                self.transitionToHomeScreen()
                                            }
                                        }
                                }
                            }
                        } else {
                            self.presentProfileCompletionAlertApple()
                        }
                    }
                }
            }
        }
    }
    
    func checkAppleUserExistence(identityToken: String, completion: @escaping (Bool) -> Void) {
        // Query your Firestore collection to check if a user with this identityToken exists
        let collectionRef = db.collection("userinfo")
        collectionRef.whereField("appleUserIdentifier", isEqualTo: self.appleUserIdentifier ?? "").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error checking user existence: \(error.localizedDescription)")
                completion(false) // Assume user doesn't exist in case of an error
            } else if let snapshot = snapshot, !snapshot.isEmpty {
                // User with this identity token exists in Firestore
                completion(true)
            } else {
                // User does not exist
                completion(false)
            }
        }
    }
    
    func createFirestoreUserApple(fullName: String, username: String) {
        guard let appleCredential = self.appleCredential else {
            // Handle this case appropriately
            return
        }
        
        self.loadingIndicator.startAnimating()
        
        // Create a Firestore user document without specifying the UID
        let fcmToken = Messaging.messaging().fcmToken
        var appUser = AppUser(fullName: fullName.lowercased(), userName: username.lowercased(), email: "", uid: "", fcmToken: fcmToken, appleUserIdentifier: self.appleUserIdentifier)
        
        // Sign in with the Apple credential
        Auth.auth().signIn(with: appleCredential) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Apple Sign-In error: \(error.localizedDescription)")
                // Handle the sign-in error appropriately
                return
            }
            
            // Firebase Authentication with Apple credential was successful
            print("Apple Sign-In successful")
            
            // Get the authenticated user's UID from Firebase Authentication
            guard let uid = Auth.auth().currentUser?.uid else {
                // Handle the case where UID is not available
                return
            }
            
            let userRef = Constants.Collections.UsersCollectionRef.document(uid)
            
            // Update the appUser's UID
            appUser.uid = uid
            
            // Update the Firestore user document with the generated UID
            self.db.collection(Constants.Firebase.USERS)
                .document(uid)
                .setData(try! Firestore.Encoder().encode(appUser)) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        print("User document created successfully.")
                    }
                    
                    userRef.updateData(["keywordsForLookup": appUser.keywordsForLookup])
                    
                    let userinfoCollectionRef = Constants.Collections.UserInfoRef
                    let userinfoDocRef = userinfoCollectionRef.document(uid)
                    userinfoDocRef.setData(["username": username.lowercased(), "email": "", "appleUserIdentifier": self.appleUserIdentifier ?? ""]) { error in
                        if let error = error {
                            print("Error updating userinfo: \(error.localizedDescription)")
                        }
                    }
                    // Set the new AppUser instance in your singleton
                    AppUserSingleton.shared.appUser = appUser
                    
                    let dispatchGroup = DispatchGroup()
                    
                    dispatchGroup.enter()
                    self.fetchTwentyDiscoveryPosts { recentDiscoveryPosts, error in
                        if let error = error {
                            print("Error fetching recent discovery posts: \(error)")
                        } else {
                            let sortedDiscoveryPosts = recentDiscoveryPosts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                            HugPostsDiscoveryManager.shared.hugPostsDiscovery = sortedDiscoveryPosts
                        }
                        dispatchGroup.leave()
                    }
                    self.loadingIndicator.stopAnimating()
                    UserDefaults.standard.set(true, forKey: "HasRegistered")
                    self.transitionToHomeScreen()
                }
        }
    }
    
    
    
    func presentProfileCompletionAlertApple() {
        // Present an alert to collect full name and username
        let alert = UIAlertController(title: "Complete Your Profile", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Full Name"
        }
        alert.addTextField { textField in
            textField.placeholder = "Username"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let fullName = alert.textFields?.first?.text,
                  let username = alert.textFields?.last?.text else {
                return
            }
            
            // Validate full name and username using your regex functions
            let isFullNameValid = self.isFullnameValid(fullName: fullName)
            let isUsernameValid = self.isUsernameValid(username)
            
            if isFullNameValid && isUsernameValid {
                // Check if the username is unique
                self.checkUniqueUsername(username: username.lowercased()) { isUnique in
                    if isUnique {
                        self.createFirestoreUserApple(fullName: fullName, username: username.lowercased())
                    } else {
                        // Handle the case where the username is not unique
                        let usernameTakenAlert = UIAlertController(title: "Username is already taken", message: "Please choose a different username.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        usernameTakenAlert.addAction(okAction)
                        self.present(usernameTakenAlert, animated: true, completion: nil)
                    }
                }
            } else {
                // Handle the case where full name or username is not valid
                if !isFullNameValid {
                    let fullNameAlert = UIAlertController(title: "Full Name is not valid", message: "Your name must be between 2-20 characters. Please enter a valid full name.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    fullNameAlert.addAction(okAction)
                    self.present(fullNameAlert, animated: true, completion: nil)
                }
                if !isUsernameValid {
                    let usernameAlert = UIAlertController(title: "Username is not valid", message: "Please enter a valid username. It must contain 2 to 18 characters.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    usernameAlert.addAction(okAction)
                    self.present(usernameAlert, animated: true, completion: nil)
                }
            }
        }
        
        // Initially, the "Save" button is disabled
        saveAction.isEnabled = false
        
        // Add text change observers to enable the "Save" button when both fields have content
        let fullNameTextField = alert.textFields?.first
        let usernameTextField = alert.textFields?.last
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: fullNameTextField, queue: .main) { _ in
            saveAction.isEnabled = !(fullNameTextField?.text?.isEmpty ?? true) && !(usernameTextField?.text?.isEmpty ?? true)
        }
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: usernameTextField, queue: .main) { _ in
            saveAction.isEnabled = !(fullNameTextField?.text?.isEmpty ?? true) && !(usernameTextField?.text?.isEmpty ?? true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func signInWithGoogle2() {
        switch logOutResult {
        case .noPreviouslyAuthenticatedUser:
            break
        case .previouslyAuthenticatedUserWasLoggedOut:
            break
        case .previouslyAuthenticatedUserCouldNotBeLoggedOut(let error):
            print("Previously authenticated user could not be logged out: \(error.localizedDescription)")
            return
        case nil:
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] authentication, error in
            guard let self = self else { return }
            guard error == nil, let user = authentication?.user, let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            // Store user and credential for later use
            self.googleUser = user
            self.googleCredential = credential
            
            
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    // Handle sign-in error.
                    print("Google sign-in error: \(error.localizedDescription)")
                    return
                }
                
                if let user = authResult?.user {
                    // Check if this is a new user (account was just created).
                    let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                    
                    if isNewUser {
                        // This is a new user. Perform actions for new users.
                        print("NEW user signed in: \(user.uid)")
                        self.presentProfileCompletionAlert()
                        // Perform actions for new users, e.g., first-time setup.
                    } else {
                        // This is an existing user. Perform actions for existing users.
                        print("Existing user signed in: \(user.uid)")
                        self.loadingIndicator.startAnimating()
                        self.db.collection(Constants.Firebase.USERS)
                            .whereField(Constants.Firebase.EMAIL, isEqualTo: self.googleUser?.profile?.email ?? "")
                            .getDocuments { (querySnapshot, error) in
                                if let error = error {
                                    print("Error fetching user document: \(error.localizedDescription)")
                                    self.loadingIndicator.stopAnimating()
                                    return
                                }
                                
                                // Check if a document exists
                                guard let document = querySnapshot?.documents.first,
                                      let appUser = try? Firestore.Decoder().decode(AppUser.self, from: document.data()) else {
                                    print("User document not found.")
                                    self.loadingIndicator.stopAnimating()
                                    return
                                }
                                
                                // Set the retrieved AppUser instance in your singleton
                                AppUserSingleton.shared.appUser = appUser
                                
                                self.fetchAllData(appUser: appUser) {
                                    // This completion handler will be called after all data is fetched
                                    self.loadingIndicator.stopAnimating()
                                    self.transitionToHomeScreen()
                                }
                            }
                    }
                }
            }
        }
    }
    
    
    
    
    @objc func signInWithGoogle() {
        switch logOutResult {
        case .noPreviouslyAuthenticatedUser:
            break
        case .previouslyAuthenticatedUserWasLoggedOut:
            break
        case .previouslyAuthenticatedUserCouldNotBeLoggedOut(let error):
            print("Previously authenticated user could not be logged out: \(error.localizedDescription)")
            return
        case nil:
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] authentication, error in
            guard let self = self else { return }
            guard error == nil, let user = authentication?.user, let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            // Store user and credential for later use
            self.googleUser = user
            self.googleCredential = credential
            
            // Check if the user is already authenticated in Firestore
            self.checkEmail(user: user) { [weak self] userExists in
                guard let self = self else { return }
                
                if userExists {
                    // User exists in Firestore, sign in the user with Firebase Authentication
                    Auth.auth().signIn(with: credential) { authResult, error in
                        if let error = error {
                            print("Firebase Sign-In error: \(error.localizedDescription)")
                            // Handle the sign-in error appropriately
                        } else {
                            // Firebase Authentication sign-in was successful
                            print("Firebase Sign-In successful")
                            
                            // Continue with the code to fetch user data and transition to the home screen
                            self.loadingIndicator.startAnimating()
                            self.db.collection(Constants.Firebase.USERS)
                                .whereField(Constants.Firebase.EMAIL, isEqualTo: user.profile?.email ?? "")
                                .getDocuments { (querySnapshot, error) in
                                    if let error = error {
                                        print("Error fetching user document: \(error.localizedDescription)")
                                        self.loadingIndicator.stopAnimating()
                                        return
                                    }
                                    
                                    // Check if a document exists
                                    guard let document = querySnapshot?.documents.first,
                                          let appUser = try? Firestore.Decoder().decode(AppUser.self, from: document.data()) else {
                                        print("User document not found.")
                                        self.loadingIndicator.stopAnimating()
                                        return
                                    }
                                    
                                    // Set the retrieved AppUser instance in your singleton
                                    AppUserSingleton.shared.appUser = appUser
                                    
                                    self.fetchAllData(appUser: appUser) {
                                        // This completion handler will be called after all data is fetched
                                        self.loadingIndicator.stopAnimating()
                                        self.transitionToHomeScreen()
                                    }
                                }
                        }
                    }
                } else {
                    // User does not exist in Firestore, proceed with the profile completion alert
                    self.presentProfileCompletionAlert()
                }
            }
        }
    }
    
    func presentProfileCompletionAlert() {
        // Present an alert to collect full name and username
        let alert = UIAlertController(title: "Complete Your Profile", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Full Name"
        }
        alert.addTextField { textField in
            textField.placeholder = "Username"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let fullName = alert.textFields?.first?.text,
                  let username = alert.textFields?.last?.text else {
                return
            }
            
            // Validate full name and username using your regex functions
            let isFullNameValid = self.isFullnameValid(fullName: fullName)
            let isUsernameValid = self.isUsernameValid(username)
            
            if isFullNameValid && isUsernameValid {
                // Check if the username is unique
                self.checkUniqueUsername(username: username.lowercased()) { isUnique in
                    if isUnique {
                        self.createFirestoreUser(fullName: fullName, username: username.lowercased())
                    } else {
                        // Handle the case where the username is not unique
                        let usernameTakenAlert = UIAlertController(title: "Username is already taken", message: "Please choose a different username.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        usernameTakenAlert.addAction(okAction)
                        self.present(usernameTakenAlert, animated: true, completion: nil)
                    }
                }
            } else {
                // Handle the case where full name or username is not valid
                if !isFullNameValid {
                    let fullNameAlert = UIAlertController(title: "Full Name is not valid", message: "Your name must be between 2-20 characters. Please enter a valid full name.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    fullNameAlert.addAction(okAction)
                    self.present(fullNameAlert, animated: true, completion: nil)
                }
                if !isUsernameValid {
                    let usernameAlert = UIAlertController(title: "Username is not valid", message: "Please enter a valid username. It must contain 2 to 18 characters.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    usernameAlert.addAction(okAction)
                    self.present(usernameAlert, animated: true, completion: nil)
                }
            }
        }
        
        // Initially, the "Save" button is disabled
        saveAction.isEnabled = false
        
        // Add text change observers to enable the "Save" button when both fields have content
        let fullNameTextField = alert.textFields?.first
        let usernameTextField = alert.textFields?.last
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: fullNameTextField, queue: .main) { _ in
            saveAction.isEnabled = !(fullNameTextField?.text?.isEmpty ?? true) && !(usernameTextField?.text?.isEmpty ?? true)
        }
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: usernameTextField, queue: .main) { _ in
            saveAction.isEnabled = !(fullNameTextField?.text?.isEmpty ?? true) && !(usernameTextField?.text?.isEmpty ?? true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func createFirestoreUser(fullName: String, username: String) {
        guard let googleCredential = self.googleCredential else {
            // Handle this case appropriately
            return
        }
        
        self.loadingIndicator.startAnimating()
        
        // Retrieve the email and unique identifier from the Google user profile data
        let email = googleUser?.profile?.email ?? ""
        
        let fcmToken = Messaging.messaging().fcmToken
        var appUser = AppUser(fullName: fullName.lowercased(), userName: username.lowercased(), email: email.lowercased(), uid: "", fcmToken: fcmToken, appleUserIdentifier: "")
        
        // Sign in with the Google credential
        Auth.auth().signIn(with: googleCredential) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                // Handle the sign-in error appropriately
                return
            }
            
            // Firebase Authentication with Google credential was successful
            print("Google Sign-In successful")
            
            guard let uid = Auth.auth().currentUser?.uid else {
                // Handle the case where UID is not available
                return
            }
            
            let userRef = Constants.Collections.UsersCollectionRef.document(uid)
            
            appUser.uid = uid
            
            // Create the Firestore user document
            self.db.collection(Constants.Firebase.USERS)
                .document(uid)
                .setData(try! Firestore.Encoder().encode(appUser)) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        print("User document created successfully.")
                    }
                    
                    userRef.updateData(["keywordsForLookup": appUser.keywordsForLookup])
                   
                    let userinfoCollectionRef = Constants.Collections.UserInfoRef
                    let userinfoDocRef = userinfoCollectionRef.document(uid)
                    userinfoDocRef.setData(["username": username.lowercased(), "email": email, "appleUserIdentifier": ""]) { error in
                        if let error = error {
                            print("Error updating userinfo: \(error.localizedDescription)")
                        }
                    }
                    
                    AppUserSingleton.shared.appUser = appUser
                    
                    let dispatchGroup = DispatchGroup()
                    
                    dispatchGroup.enter()
                    self.fetchTwentyDiscoveryPosts { recentDiscoveryPosts, error in
                        if let error = error {
                            print("Error fetching recent discovery posts: \(error)")
                        } else {
                            let sortedDiscoveryPosts = recentDiscoveryPosts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                            HugPostsDiscoveryManager.shared.hugPostsDiscovery = sortedDiscoveryPosts
                        }
                        dispatchGroup.leave()
                    }
                    self.loadingIndicator.stopAnimating()
                    UserDefaults.standard.set(true, forKey: "HasRegistered")
                    self.transitionToHomeScreen()
                }
        }
    }
    
    
    func isUsernameValid(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9]{2,18}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    func isFullnameValid(fullName: String) -> Bool {
        let regEx = "^(?=.{2,20}$)[A-Za-zÀ-ú][A-Za-zÀ-ú.'-]+(?: [A-Za-zÀ-ú.'-]+)* *$"
        let test = NSPredicate(format: "SELF MATCHES %@", regEx)
        return test.evaluate(with: fullName)
    }
    
    func checkUniqueUsername(username: String, completion: @escaping (Bool) -> Void) {
        // Assuming you have a Firestore collection named "users"
        db.collection("userinfo")
            .whereField(Constants.Firebase.USERNAME, isEqualTo: username)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error checking username uniqueness: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // If there are no documents with the same username, it's unique
                let isUnique = querySnapshot?.isEmpty ?? true
                completion(isUnique)
            }
    }
    
    func signInUser(user: GIDGoogleUser, credential: AuthCredential) {
        // Sign in the user with the provided credential (Google credential)
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            if let error = error {
                print("Sign-In error: \(error.localizedDescription)")
                // Handle the sign-in error appropriately
            } else {
                // Sign-In successful, transition to the home screen
                self?.transitionToHomeScreen()
            }
        }
    }
    
    func checkEmail(user: GIDGoogleUser, completion: @escaping (Bool) -> Void) {
        let email = user.profile?.email ?? ""
        
        // Get your Firebase collection
        let collectionRef = db.collection("userinfo")
        
        // Get all the documents where the field username is equal to the String you pass, loop over all the documents.
        
        collectionRef.whereField("email", isEqualTo: email).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                completion(false)
            } else {
                for document in (snapshot?.documents)! {
                    if document.data()["email"] != nil {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func transitionToHomeScreen() {
        let tabbar = TabBar()
        tabbar.modalPresentationStyle = .fullScreen
        self.present(tabbar, animated: true)
    }
    
    @objc func createAccountButtonPressed(sender: UIButton!) {
        switch logOutResult {
        case .noPreviouslyAuthenticatedUser:
            break
        case .previouslyAuthenticatedUserWasLoggedOut:
            break
        case .previouslyAuthenticatedUserCouldNotBeLoggedOut(let error):
            print("Previously authenticated user could not be logged out: \(error.localizedDescription)")
            return
        case nil:
            return
        }
        let rootVC = SignUpVC()
        let navVC = UINavigationController(rootViewController: rootVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
    
    @objc func signInPressed(sender: UIButton!) {
        switch logOutResult {
        case .noPreviouslyAuthenticatedUser:
            break
        case .previouslyAuthenticatedUserWasLoggedOut:
            break
        case .previouslyAuthenticatedUserCouldNotBeLoggedOut(let error):
            print("Previously authenticated user could not be logged out: \(error.localizedDescription)")
            return
        case nil:
            return
        }
        let loginVC = LoginVC()
        let navigationController = UINavigationController(rootViewController: loginVC)
        navigationController.modalPresentationStyle = .fullScreen
        self.present(navigationController, animated: true)
    }
    
    private func setUpView() {
        self.view.addSubview(welcomeLabel)
        self.view.addSubview(signInWithGoogleButton)
        self.view.addSubview(signInWithAppleButton)
        self.view.addSubview(createAccountButton)
        self.view.addSubview(logInLabel)
        self.view.addSubview(signInButton)
    }
    
    private func addConstraints() {
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(NSLayoutConstraint(item: welcomeLabel, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: self.view.bounds.size.height/2 - 200))
        //
        constraints.append(NSLayoutConstraint(item: welcomeLabel, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: AppDelegate.screenWidth / 13))
        //
        constraints.append(NSLayoutConstraint(item: welcomeLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -AppDelegate.screenWidth / 13))
        //
        constraints.append(NSLayoutConstraint(item: signInWithGoogleButton, attribute: .top, relatedBy: .equal, toItem: welcomeLabel, attribute: .bottom, multiplier: 1.0, constant: AppDelegate.screenHeight / 7))
        
        constraints.append(NSLayoutConstraint(item: signInWithGoogleButton, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: AppDelegate.screenWidth / 5))
        
        constraints.append(NSLayoutConstraint(item: signInWithGoogleButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -AppDelegate.screenWidth / 5))
        
        //
        constraints.append(NSLayoutConstraint(item: signInWithAppleButton, attribute: .top, relatedBy: .equal, toItem: signInWithGoogleButton, attribute: .bottom, multiplier: 1.0, constant: AppDelegate.screenHeight / 40))
        
        constraints.append(NSLayoutConstraint(item: signInWithAppleButton, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: AppDelegate.screenWidth / 5))
        
        constraints.append(NSLayoutConstraint(item: signInWithAppleButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -AppDelegate.screenWidth / 5))
        
        //
        constraints.append(NSLayoutConstraint(item: createAccountButton, attribute: .top, relatedBy: .equal, toItem: signInWithAppleButton, attribute: .bottom, multiplier: 1.0, constant: AppDelegate.screenHeight / 40))
        
        constraints.append(NSLayoutConstraint(item: createAccountButton, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: AppDelegate.screenWidth / 5))
        
        constraints.append(NSLayoutConstraint(item: createAccountButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -AppDelegate.screenWidth / 5))
        //
        constraints.append(NSLayoutConstraint(item: logInLabel, attribute: .top, relatedBy: .equal, toItem: createAccountButton, attribute: .bottom, multiplier: 1.0, constant: AppDelegate.screenHeight / 40))
        //
        logInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //
        constraints.append(NSLayoutConstraint(item: signInButton, attribute: .top, relatedBy: .equal, toItem: logInLabel, attribute: .bottom, multiplier: 1.0, constant: AppDelegate.screenHeight / 200))
        //
        signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        NSLayoutConstraint.activate(constraints)
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
    
}

extension WelcomeVC: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle sign-in errors here
    }
}

extension WelcomeVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the view or window where you want to present the authorization controller
        return self.view.window!
    }
}

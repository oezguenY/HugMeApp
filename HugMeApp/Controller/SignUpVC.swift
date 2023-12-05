//
//  SignUpVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 16.08.22.
//

import UIKit
import Combine
import FirebaseAuth
import Firebase
import FirebaseMessaging

class SignUpVC: UIViewController {
    
    let firestoreListenerManager = FirestoreListenerManager.shared
    
    @Published var textFieldCleared = false
    private var cancellables = Set<AnyCancellable>()
    
    var someErr: Error?
//    let tabbar = TabBar()
    private var createButtonSubscriber: AnyCancellable?
    let registerBtn = UIButton()
    @Published var fullname = ""
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordAgain = ""
    @Published private var isUsernameAvailable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.createNavigationItem()
        self.setUpView()
        self.setUpDelegates()
        self.setUpButton()
        self.addConstraints()
        fullNameValidBtn.isHidden = true
        fullNameInvalidBtn.isHidden = true
        usernameAvailableBtn.isHidden = true
        usernameAlreadyTakenBtn.isHidden = true
        emailValidBtn.isHidden = true
        emailInvalidBtn.isHidden = true
        passwordValidBtn.isHidden = true
        passwordInvalidBtn.isHidden = true
        retypePassworValiddBtn.isHidden = true
        retypePasswordInvalidBtn.isHidden = true
        self.clearCachesAndData()
        firestoreListenerManager.removeAllListeners()
    }
    
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

    
    @objc func dismissSelf() {
        dismiss(animated: true)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        self.signUp(email: email, password: password)
    }
    
    func logOutPreviousUser() {
        if let _ = Auth.auth().currentUser {
            // A user is authenticated; you can log them out
            do {
                try Auth.auth().signOut()
                // Log out successful
            } catch let signOutError as NSError {
                print("Error signing out: \(signOutError.localizedDescription)")
                // Handle sign-out error if needed
            }
        } else {
            // No user is authenticated
            print("User was logged out.")
        }

    }
    
    private func signUp(email: String, password: String) {
        let username = nameTF.text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let email = emailTF.text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = passwordTF.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullname = fullNameTF.text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
            if let err = err {
                self.someErr = err
                self.createSignUpAlert(with: err)
                self.handleSignUpFailure()
                return
            } else {
                guard let user = result?.user else { return }
                let fcmToken = Messaging.messaging().fcmToken
                let userRef = Constants.Collections.UsersCollectionRef.document(user.uid)
                let appUser = AppUser(fullName: fullname.lowercased(), userName: username.lowercased(), email: email.lowercased(), uid: user.uid, fcmToken: fcmToken, appleUserIdentifier: "")

                do {
                    let encoder = Firestore.Encoder()
                    let data = try encoder.encode(appUser)

                    // Save the data in Constants.Collections.UsersCollectionRef
                    userRef.setData(data) { error in
                        if let error = error {
                            self.createSignUpAlert(with: error)
                            return
                        }
                        userRef.updateData(["keywordsForLookup": appUser.keywordsForLookup])

                        // Save username and email in "userinfo" collection with the same UID as the user
                        let userinfoRef = Constants.Collections.UserInfoRef.document(user.uid)
                        userinfoRef.setData(["username": username, "email": email, "appleUserIdentifier": ""]) { error in
                            if let error = error {
                                self.createSignUpAlert(with: error)
                                return
                            }

                            AppUserSingleton.shared.appUser = appUser
                            self.fetchTwentyDiscoveryPosts { discoveryPosts, error in
                                if let error = error {
                                    print("Discovery posts could not be fetched when registering the user: \(error.localizedDescription)")
                                }
                                HugPostsDiscoveryManager.shared.hugPostsDiscovery = discoveryPosts

                                // Move the transition here, inside the completion block
                                UserDefaults.standard.set(true, forKey: "HasRegistered")
                                UserDefaults.standard.synchronize()
                                print("ABOUT TO TRANSITION TO HOME SCREEN FROM SIGN UP!")
                                self.transitionToProfileVC()
                            }
                        }
                    }
                } catch let error {
                    self.createSignUpAlert(with: error)
                    return
                }
            }
        }
    }



    
    private func handleSignUpFailure() {
        if self.someErr != nil {
            return // Do not call transitionToHomeScreen if there is an error
        }
        
        DispatchQueue.main.async {
            self.transitionToProfileVC()
        }
    }
    
    func transitionToProfileVC() {
        let tabbar = TabBar()
        tabbar.modalPresentationStyle = .fullScreen
        self.present(tabbar, animated: true)
    }
    
    private func setUpNavigationbar() {
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        view.addSubview(navBar)
        
        let navItem = UINavigationItem(title: "SomeTitle")
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(backToWelcomeVC))
        navItem.rightBarButtonItem = doneItem
        
        navBar.setItems([navItem], animated: false)
    }
    
    @objc func backToWelcomeVC() {
        print("Done Pressed")
        self.dismiss(animated: true)
    }
    
    private func createSignUpAlert(with error: Error) {
        let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func setUpDelegates() {
        nameTF.delegate = self
        emailTF.delegate = self
        passwordTF.delegate = self
        passwordTF_2.delegate = self
        fullNameTF.delegate = self
    }
    
    func setUpButton() {
        registerBtn.translatesAutoresizingMaskIntoConstraints = false
        registerBtn.isEnabled = false
        registerBtn.heightAnchor.constraint(equalToConstant: view.bounds.size.height / 12).isActive = true
        registerBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        registerBtn.setTitle("Register", for: .normal)
        registerBtn.titleLabel?.font =  UIFont.boldSystemFont(ofSize: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 16)
        registerBtn.clipsToBounds = true
        registerBtn.backgroundColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        registerBtn.setTitleColor(.white, for: .normal)
        registerBtn.layer.cornerRadius = view.bounds.size.height / 30
        registerBtn.layer.borderColor = UIColor.blue.cgColor
        registerBtn.alpha = 0.5
        registerBtn.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        // Step 4: Hook our subscriber up to our validation publisher stream
        
        createButtonSubscriber = validatedCreds
        
            .receive(on: RunLoop.main)
//            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .assign(to: \.isEnabled, on: registerBtn)
        
    }
    
    var validatedFullname: AnyPublisher<String?, Never> {
        return $fullname
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { fullname in
                // Check if the fullname is valid using your isFullnameValid function
                let isValid = self.isFullnameValid(fullName: fullname)
                if fullname.isEmpty {
                    self.fullNameValidBtn.isHidden = true
                    self.fullNameInvalidBtn.isHidden = true
                    return nil
                }
                // Show/hide buttons based on validity
                if isValid {
                    self.fullNameValidBtn.isHidden = false
                    self.fullNameInvalidBtn.isHidden = true
                    print("VALIDATED FULLNAME: \(fullname)")
                    return fullname // Return fullname if it's valid
                } else {
                    self.fullNameValidBtn.isHidden = true
                    self.fullNameInvalidBtn.isHidden = false
                    return nil // Return nil if it's not valid
                }
            }
            .eraseToAnyPublisher()
    }
    
    var validatedUsername: AnyPublisher<String?, Never> {
        return $username
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap { username in
                if username.isEmpty {
                    // Username is empty, set button visibility accordingly
                    DispatchQueue.main.async {
                        self.usernameAvailableBtn.isHidden = true
                        self.usernameAlreadyTakenBtn.isHidden = true
                    }
                    return Just<String?>(nil).eraseToAnyPublisher()
                } else {
                    return self.isUsernameAvailable(username)
                        .map { isAvailable in
                            print("ISAVAILABLE USERNAME: \(isAvailable)")
                            if isAvailable {
                                print("VALIDATED USERNAME: \(username)")
                                return username // Return username if it's available
                            } else {
                                return nil // Return an error message if it's not available
                            }
                        }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    
    func isUsernameAvailable(_ username: String) -> AnyPublisher<Bool, Never> {
        if !isUsernameValid(username) {
            // Username is not valid, set button visibility accordingly
            DispatchQueue.main.async {
                self.usernameAvailableBtn.isHidden = true
                self.usernameAlreadyTakenBtn.isHidden = false
            }
            return Just<Bool>(false).eraseToAnyPublisher()
        }
        
        return Future { promise in
            let db = Firestore.firestore()
            let usersRef = Constants.Collections.UserInfoRef
            
            usersRef.whereField("username", isEqualTo: username.lowercased()).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print(error.localizedDescription)
                    promise(.success(false)) // Assume username is not available due to error
                } else {
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        print("USERNAME IS ALREADY TAKEN")
                        promise(.success(false))
                        self.usernameAvailableBtn.isHidden = true
                        self.usernameAlreadyTakenBtn.isHidden = false
                    } else {
                        print("USERNAME IS NOT ALREADY TAKEN")
                        promise(.success(true))
                        self.usernameAlreadyTakenBtn.isHidden = true
                        self.usernameAvailableBtn.isHidden = false
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    
    var validatedEmail: AnyPublisher<String?, Never> {
        return $email
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap { email in
                if email.isEmpty {
                    // Email is empty, set button visibility accordingly
                    DispatchQueue.main.async {
                        self.emailValidBtn.isHidden = true
                        self.emailInvalidBtn.isHidden = true
                    }
                    return Just<String?>(nil).eraseToAnyPublisher()
                } else {
                    return self.isEmailAvailable(email)
                        .map { isAvailable in
                            if isAvailable {
                                print("VALIDATED EMAIL: \(email)")
                                return email // Return email if it's available
                            } else {
                                return nil // Return an error message if it's not available
                            }
                        }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    
    func isEmailAvailable(_ email: String) -> AnyPublisher<Bool, Never> {
        if !isEmailValid(email) {
            print("It is valid")
            // Username is not valid, set button visibility accordingly
            DispatchQueue.main.async {
                self.emailValidBtn.isHidden = true
                self.emailInvalidBtn.isHidden = false
            }
            return Just<Bool>(false).eraseToAnyPublisher()
        }
        
        return Future { promise in
            let db = Firestore.firestore()
            let usersRef = Constants.Collections.UserInfoRef
            
            usersRef.whereField("email", isEqualTo: email.lowercased()).getDocuments { (querySnapshot, error) in
                if let error = error {
                    // Handle the error
                    print("Error checking email availability: \(error)")
                    promise(.success(false)) // Assume email is not available due to error
                } else  {
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        print("USERNAME IS ALREADY TAKEN")
                        promise(.success(false))
                        self.emailValidBtn.isHidden = true
                        self.emailInvalidBtn.isHidden = false
                    } else {
                        print("USERNAME IS NOT ALREADY TAKEN")
                        promise(.success(true))
                        self.emailInvalidBtn.isHidden = true
                        self.emailValidBtn.isHidden = false
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    var textFieldClearedPublisher: AnyPublisher<Bool, Never> {
        return $textFieldCleared.eraseToAnyPublisher()
    }
    
    var validatedPassword: AnyPublisher<String?, Never> {
        return Publishers.CombineLatest($password, $passwordAgain)
            .map { password, passwordRepeat in
      
                if self.isPasswordValid(password) && !self.isPasswordValid(passwordRepeat) {
                    self.passwordValidBtn.isHidden = false
                    self.passwordInvalidBtn.isHidden = true
                    self.retypePassworValiddBtn.isHidden = true
                    self.retypePasswordInvalidBtn.isHidden = true
                    return nil
                }
                
                if self.isPasswordValid(passwordRepeat) && !self.isPasswordValid(password) {
                    self.passwordValidBtn.isHidden = true
                    self.passwordInvalidBtn.isHidden = true
                    self.retypePassworValiddBtn.isHidden = false
                    self.retypePasswordInvalidBtn.isHidden = true
                    return nil
                }
              

                guard password == passwordRepeat, password.count > 0, passwordRepeat.count > 0, !password.isEmpty && !passwordRepeat.isEmpty, !self.textFieldCleared else {
                    // first block beginning
                    self.passwordValidBtn.isHidden = true
                    self.passwordInvalidBtn.isHidden = false
                    self.retypePassworValiddBtn.isHidden = true
                    self.retypePasswordInvalidBtn.isHidden = false
                    return nil
                    // first block end
                }
                if !self.isPasswordValid(password) {
                    print("Password inadequate")
                    self.passwordValidBtn.isHidden = true
                    self.passwordInvalidBtn.isHidden = false
                    self.retypePassworValiddBtn.isHidden = true
                    self.retypePasswordInvalidBtn.isHidden = true
                    return nil
                }

                if !self.isPasswordValid(passwordRepeat) {
                    print("Password inadequate")
                    self.passwordValidBtn.isHidden = true
                    self.passwordInvalidBtn.isHidden = true
                    self.retypePassworValiddBtn.isHidden = true
                    self.retypePasswordInvalidBtn.isHidden = false
                    return nil
                }

                if self.isPasswordValid(password) && !self.isPasswordValid(passwordRepeat) {
                    print("Password inadequate")
                    self.passwordValidBtn.isHidden = false
                    self.passwordInvalidBtn.isHidden = true
                    self.retypePassworValiddBtn.isHidden = true
                    self.retypePasswordInvalidBtn.isHidden = false
                    return nil
                }

                print("Validated password")
                if self.textFieldCleared == false && password == passwordRepeat {
                    self.passwordValidBtn.isHidden = false
                    self.passwordInvalidBtn.isHidden = true
                    self.retypePassworValiddBtn.isHidden = false
                    self.retypePasswordInvalidBtn.isHidden = true
                    print("VALIDATED PASSWORD: \(password)")
                    return password
                } else {
                    self.passwordValidBtn.isHidden = true
                    self.passwordInvalidBtn.isHidden = false
                    self.retypePassworValiddBtn.isHidden = true
                    self.retypePasswordInvalidBtn.isHidden = false
                    return nil
                }

            }
            .eraseToAnyPublisher()
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
    
    var validatedCreds: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest4(validatedFullname, validatedUsername, validatedEmail, validatedPassword)
            .receive(on: RunLoop.main)
            .map { fullname, username, email, password  in
                if !(fullname?.isEmpty ?? true) && !(password?.isEmpty ?? true) && !(username?.isEmpty ?? true) && !(email?.isEmpty ?? true) {
                    self.registerBtn.alpha = 1
                } else {
                    self.registerBtn.alpha = 0.5
                }
                return !(fullname?.isEmpty ?? true) && !(password?.isEmpty ?? true) && !(username?.isEmpty ?? true) && !(email?.isEmpty ?? true)
            }
            .eraseToAnyPublisher()
    }
    
    let fullNameValidBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let fullNameInvalidBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let usernameAvailableBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let usernameAlreadyTakenBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let emailValidBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let emailInvalidBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let passwordValidBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let passwordInvalidBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let retypePassworValiddBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let retypePasswordInvalidBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        button.layer.cornerRadius = 10
        return button
    }()
    
    let fullNameTF: UITextField = {
        let textfield = UITextField()
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.text = ""
        textfield.keyboardType = UIKeyboardType.default
        textfield.returnKeyType = UIReturnKeyType.done
        textfield.autocorrectionType = UITextAutocorrectionType.no
        textfield.font = UIFont.systemFont(ofSize: 13)
        textfield.borderStyle = UITextField.BorderStyle.roundedRect
        textfield.clearButtonMode = UITextField.ViewMode.whileEditing
        textfield.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        textfield.backgroundColor = .white
        textfield.textColor = UIColor.black
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
               NSAttributedString.Key.foregroundColor: UIColor.gray, // Change the color to your desired color
           ]
           textfield.attributedPlaceholder = NSAttributedString(string: "Full Name", attributes: placeholderAttributes)
        return textfield
    }()
    
    
    let nameTF: UITextField = {
        let textfield = UITextField()
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.text = ""
        textfield.keyboardType = UIKeyboardType.default
        textfield.returnKeyType = UIReturnKeyType.done
        textfield.autocorrectionType = UITextAutocorrectionType.no
        textfield.font = UIFont.systemFont(ofSize: 13)
        textfield.borderStyle = UITextField.BorderStyle.roundedRect
        textfield.clearButtonMode = UITextField.ViewMode.whileEditing
        textfield.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        textfield.backgroundColor = .white
        textfield.textColor = UIColor.black
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
               NSAttributedString.Key.foregroundColor: UIColor.gray, // Change the color to your desired color
           ]
           textfield.attributedPlaceholder = NSAttributedString(string: "Username", attributes: placeholderAttributes)
        return textfield
    }()
    
    let emailTF: UITextField = {
        let textfield = UITextField()
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.text = ""
        textfield.keyboardType = UIKeyboardType.default
        textfield.returnKeyType = UIReturnKeyType.done
        textfield.autocorrectionType = UITextAutocorrectionType.no
        textfield.font = UIFont.systemFont(ofSize: 13)
        textfield.borderStyle = UITextField.BorderStyle.roundedRect
        textfield.clearButtonMode = UITextField.ViewMode.whileEditing
        textfield.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        textfield.backgroundColor = .white
        textfield.textColor = UIColor.black
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
               NSAttributedString.Key.foregroundColor: UIColor.gray, // Change the color to your desired color
           ]
           textfield.attributedPlaceholder = NSAttributedString(string: "E-Mail", attributes: placeholderAttributes)
        return textfield
    }()
    
    let passwordTF: UITextField = {
        let textfield = UITextField()
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.text = ""
        textfield.isSecureTextEntry = true
        textfield.keyboardType = UIKeyboardType.default
        textfield.returnKeyType = UIReturnKeyType.done
        textfield.autocorrectionType = UITextAutocorrectionType.no
        textfield.font = UIFont.systemFont(ofSize: 13)
        textfield.borderStyle = UITextField.BorderStyle.roundedRect
        textfield.clearButtonMode = UITextField.ViewMode.whileEditing
        textfield.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        textfield.backgroundColor = .white
        textfield.textColor = UIColor.black
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
               NSAttributedString.Key.foregroundColor: UIColor.gray, // Change the color to your desired color
           ]
           textfield.attributedPlaceholder = NSAttributedString(string: "Password", attributes: placeholderAttributes)
        return textfield
    }()
    
    let passwordTF_2: UITextField = {
        let textfield = UITextField()
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.text = ""
        textfield.isSecureTextEntry = true
        textfield.keyboardType = UIKeyboardType.default
        textfield.returnKeyType = UIReturnKeyType.done
        textfield.autocorrectionType = UITextAutocorrectionType.no
        textfield.font = UIFont.systemFont(ofSize: 13)
        textfield.borderStyle = UITextField.BorderStyle.roundedRect
        textfield.clearButtonMode = UITextField.ViewMode.whileEditing
        textfield.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        textfield.backgroundColor = .white
        textfield.textColor = UIColor.black
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
               NSAttributedString.Key.foregroundColor: UIColor.gray, // Change the color to your desired color
           ]
           textfield.attributedPlaceholder = NSAttributedString(string: "Retype Password", attributes: placeholderAttributes)
        return textfield
    }()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func setUpView() {
        self.view.addSubview(fullNameTF)
        self.view.addSubview(nameTF)
        self.view.addSubview(emailTF)
        self.view.addSubview(passwordTF)
        self.view.addSubview(passwordTF_2)
        self.view.addSubview(registerBtn)
        fullNameTF.addSubview(fullNameValidBtn)
        fullNameTF.addSubview(fullNameInvalidBtn)
        nameTF.addSubview(usernameAlreadyTakenBtn)
        nameTF.addSubview(usernameAvailableBtn)
        emailTF.addSubview(emailValidBtn)
        emailTF.addSubview(emailInvalidBtn)
        passwordTF.addSubview(passwordValidBtn)
        passwordTF.addSubview(passwordInvalidBtn)
        passwordTF_2.addSubview(retypePassworValiddBtn)
        passwordTF_2.addSubview(retypePasswordInvalidBtn)
    }
    
    func isUsernameValid(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9]{2,18}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    private func isPasswordValid(_ password : String) -> Bool{
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
    
    private func isEmailValid(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    
    func isFullnameValid(fullName: String) -> Bool {
        let regEx = "^(?=.{2,20}$)[A-Za-zÀ-ú][A-Za-zÀ-ú.'-]+(?: [A-Za-zÀ-ú.'-]+)* *$"
        let test = NSPredicate(format: "SELF MATCHES %@", regEx)
        return test.evaluate(with: fullName)
    }
    
    
    private func addConstraints() {
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(NSLayoutConstraint(item: fullNameTF, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 150))
        
        constraints.append(NSLayoutConstraint(item: fullNameTF, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: fullNameTF, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -20))
        
        constraints.append(NSLayoutConstraint(item: nameTF, attribute: .top, relatedBy: .equal, toItem: fullNameTF, attribute: .bottom, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: nameTF, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: nameTF, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -20))
        
        constraints.append(NSLayoutConstraint(item: emailTF, attribute: .top, relatedBy: .equal, toItem: nameTF, attribute: .bottom, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: emailTF, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: emailTF, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -20))
        
        constraints.append(NSLayoutConstraint(item: passwordTF, attribute: .top, relatedBy: .equal, toItem: emailTF, attribute: .bottom, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: passwordTF, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: passwordTF, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -20))
        
        constraints.append(NSLayoutConstraint(item: passwordTF_2, attribute: .top, relatedBy: .equal, toItem: passwordTF, attribute: .bottom, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: passwordTF_2, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 20))
        
        constraints.append(NSLayoutConstraint(item: passwordTF_2, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -20))
        
        
        constraints.append(NSLayoutConstraint(item: registerBtn, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -view.bounds.size.height / 10))
        constraints.append(NSLayoutConstraint(item: registerBtn, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: view.bounds.size.width / 15))
        constraints.append(NSLayoutConstraint(item: registerBtn, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -1 * (view.bounds.size.width / 15)))
        
        constraints.append(NSLayoutConstraint(item: usernameAlreadyTakenBtn, attribute: .centerY, relatedBy: .equal, toItem: nameTF, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: usernameAlreadyTakenBtn, attribute: .trailing, relatedBy: .equal, toItem: nameTF, attribute: .trailing, multiplier: 1.0, constant: -30))
        constraints.append(NSLayoutConstraint(item: usernameAvailableBtn, attribute: .centerY, relatedBy: .equal, toItem: nameTF, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: usernameAvailableBtn, attribute: .trailing, relatedBy: .equal, toItem: nameTF, attribute: .trailing, multiplier: 1.0, constant: -30))
        
        
        constraints.append(NSLayoutConstraint(item: fullNameValidBtn, attribute: .centerY, relatedBy: .equal, toItem: fullNameTF, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: fullNameValidBtn, attribute: .trailing, relatedBy: .equal, toItem: fullNameTF, attribute: .trailing, multiplier: 1.0, constant: -30))
        constraints.append(NSLayoutConstraint(item: fullNameInvalidBtn, attribute: .centerY, relatedBy: .equal, toItem: fullNameTF, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: fullNameInvalidBtn, attribute: .trailing, relatedBy: .equal, toItem: fullNameTF, attribute: .trailing, multiplier: 1.0, constant: -30))
        
        constraints.append(NSLayoutConstraint(item: emailValidBtn, attribute: .centerY, relatedBy: .equal, toItem: emailTF, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: emailValidBtn, attribute: .trailing, relatedBy: .equal, toItem: emailTF, attribute: .trailing, multiplier: 1.0, constant: -30))
        constraints.append(NSLayoutConstraint(item: emailInvalidBtn, attribute: .centerY, relatedBy: .equal, toItem: emailTF, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: emailInvalidBtn, attribute: .trailing, relatedBy: .equal, toItem: emailTF, attribute: .trailing, multiplier: 1.0, constant: -30))
        
        constraints.append(NSLayoutConstraint(item: passwordValidBtn, attribute: .centerY, relatedBy: .equal, toItem: passwordTF, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: passwordValidBtn, attribute: .trailing, relatedBy: .equal, toItem: passwordTF, attribute: .trailing, multiplier: 1.0, constant: -30))
        constraints.append(NSLayoutConstraint(item: passwordInvalidBtn, attribute: .centerY, relatedBy: .equal, toItem: passwordTF, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: passwordInvalidBtn, attribute: .trailing, relatedBy: .equal, toItem: passwordTF, attribute: .trailing, multiplier: 1.0, constant: -30))
        
        constraints.append(NSLayoutConstraint(item: retypePassworValiddBtn, attribute: .centerY, relatedBy: .equal, toItem: passwordTF_2, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: retypePassworValiddBtn, attribute: .trailing, relatedBy: .equal, toItem: passwordTF_2, attribute: .trailing, multiplier: 1.0, constant: -30))
        constraints.append(NSLayoutConstraint(item: retypePasswordInvalidBtn, attribute: .centerY, relatedBy: .equal, toItem: passwordTF_2, attribute: .centerY, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: retypePasswordInvalidBtn, attribute: .trailing, relatedBy: .equal, toItem: passwordTF_2, attribute: .trailing, multiplier: 1.0, constant: -30))
        
        NSLayoutConstraint.activate(constraints)
    }
    
}

extension SignUpVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textFieldText = textField.text ?? ""
        let text = (textFieldText as NSString).replacingCharacters(in: range, with: string)
        
        if textField == nameTF { username = text }
        if textField == emailTF { email = text }
        if textField == passwordTF { password = text}
        if textField == passwordTF_2 { passwordAgain = text }
        if textField == fullNameTF { fullname = text }
        
        registerBtn.isEnabled = false
        
        textFieldCleared = false
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        if textField == fullNameTF {
            fullname = ""
            self.fullNameValidBtn.isHidden = true
            self.fullNameInvalidBtn.isHidden = false
            self.registerBtn.alpha = 0.5
            self.registerBtn.isEnabled = false
        }
        
        if textField == emailTF {
            email = ""
            self.emailValidBtn.isHidden = true
            self.emailInvalidBtn.isHidden = false
            self.registerBtn.alpha = 0.5
            self.registerBtn.isEnabled = false
        }
        
        if textField == nameTF {
            username = ""
            self.usernameAvailableBtn.isHidden = true
            self.usernameAlreadyTakenBtn.isHidden = false
            self.registerBtn.alpha = 0.5
            self.registerBtn.isEnabled = false
        }
        
        if textField == passwordTF {
            password = ""
            self.passwordValidBtn.isHidden = true
            self.passwordInvalidBtn.isHidden = false
            self.registerBtn.alpha = 0.5
            self.registerBtn.isEnabled = false
        }
        
        if textField == passwordTF_2 {
            passwordAgain = ""
            self.retypePassworValiddBtn.isHidden = true
            self.retypePasswordInvalidBtn.isHidden = false
            self.registerBtn.alpha = 0.5
            self.registerBtn.isEnabled = false
        }
        
        
        return true
    }
    
}




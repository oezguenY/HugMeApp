//
//  SelectGIFVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 04.08.23.
//
import UIKit
import Firebase

class SelectGIFVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var selectGIFDelegate: SelectGIFVCDelegate?
    
    var multiCamVCInstance: MultiCamVC?
    
    enum FirestoreError: Error {
        case fetchDocument
        case noCurrentUser
        case dataConversion
    }
    
    enum SwiftError: Error {
        case noCurrentUser
        case noSearchedUser
    }
    
    enum HugRequestResult {
        case saved
        case fireStoreError(FirestoreError)
        case swiftError(SwiftError)
    }
    
    enum ImageError: Error {
        case invalidImageData
    }
    
    let hugRequestsCollection = Constants.Collections.HugRequestsCollectionRef
    let usersCollection = Constants.Collections.UsersCollectionRef
    
    var loadingIndicator: UIActivityIndicatorView!
    
    var snapData: SnapData?
    
    var originalBackgroundColor: UIColor?
    
    var searchedUser: AppUser?
    
    var selectedGIF: String?
    
    let gifs = ["gif1", "gif2", "gif3", "gif4", "gif5", "gif6","gif7", "gif8", "gif9", "gif10", "gif11", "gif12","gif13", "gif14", "gif15", "gif16", "gif17", "gif18","gif19", "gif20", "gif21", "gif22", "gif23", "gif24","gif25", "gif26", "gif27", "gif28", "gif29", "gif30","gif31", "gif32", "gif33", "gif34", "gif35", "gif36", "gif37", "gif38", "gif39", "gif40", "gif41", "gif42", "gif43", "gif44"]
    
    let cancelHugBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 20
        button.backgroundColor = #colorLiteral(red: 0.9559771419, green: 0.9609491229, blue: 0.9737699628, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelHugRequest), for: .touchUpInside)
        return button
    }()
    
    let requestHugBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Request Hug", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        button.backgroundColor = #colorLiteral(red: 1, green: 0.70080477, blue: 0.6055344939, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendHugRequest), for: .touchUpInside)
        return button
    }()
    
    func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .white
        loadingIndicator.center = view.center
        view.addSubview(loadingIndicator)
    }
    
    private func setConstraints() {
        var constraints = [NSLayoutConstraint]()
        
        // Constraints for the cancelHugBtn
        constraints.append(cancelHugBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -AppDelegate.screenHeight * 0.02))
        constraints.append(cancelHugBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDelegate.screenWidth * 0.1))
        constraints.append(cancelHugBtn.widthAnchor.constraint(equalToConstant: AppDelegate.screenWidth * 0.37))
        constraints.append(cancelHugBtn.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight * 0.06))
        
        // Constraints for the requestHugBtn
        constraints.append(requestHugBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -AppDelegate.screenHeight * 0.02))
        constraints.append(requestHugBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDelegate.screenWidth * 0.1))
        constraints.append(requestHugBtn.widthAnchor.constraint(equalToConstant: AppDelegate.screenWidth * 0.37))
        constraints.append(requestHugBtn.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight * 0.06))
        
        // Constraints for the collectionView
        constraints.append(collectionView.topAnchor.constraint(equalTo: view.topAnchor))
        constraints.append(collectionView.bottomAnchor.constraint(equalTo: cancelHugBtn.topAnchor, constant: -AppDelegate.screenHeight * 0.01))
        constraints.append(collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10))
        constraints.append(collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10))
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func addSubViews() {
        view.addSubview(collectionView)
        view.addSubview(cancelHugBtn)
        view.addSubview(requestHugBtn)
    }
    
    var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        addSubViews()
        requestHugBtn.isEnabled = false
        originalBackgroundColor = requestHugBtn.backgroundColor
        let lighterColor = requestHugBtn.backgroundColor?.withAlphaComponent(0.4)
        requestHugBtn.backgroundColor = lighterColor
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GIFCell.self, forCellWithReuseIdentifier: "GIFCell")
        setConstraints()
        setupLoadingIndicator()
    }
    
    func saveHugImageInStorage(image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        
        self.loadingIndicator.startAnimating()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData))
            return
        }
        
        let imageName = UUID().uuidString
        let imageRef = Storage.storage().reference().child("HugRequestsImages/\(imageName).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = imageRef.putData(imageData, metadata: metadata) { metadata, error in
            
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let downloadURL = url {
                    self.loadingIndicator.stopAnimating()
                    completion(.success(downloadURL))
                }
            }
        }
        
        // You can also monitor the upload progress if needed
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Upload progress: \(percentComplete * 100)%")
        }
    }
    
    
    func saveHugRequestInFirestore(completion: @escaping (HugRequestResult) -> ()) {
        
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            completion(HugRequestResult.swiftError(.noCurrentUser))
            return
        }
        
        guard let searchedUserUsername = self.searchedUser?.userName else {
            completion(HugRequestResult.swiftError(.noSearchedUser))
            return
        }
        
        guard let searchedUserFCMToken = searchedUser?.fcmToken else {
            // Handle the case where the FCM token of the searched user is missing.
            return
        }
        
        guard let currentUserUID = AppUserSingleton.shared.appUser?.uid else {
            completion(HugRequestResult.swiftError(.noCurrentUser))
            return
        }
        
        guard let seaerchedUserUID = self.searchedUser?.uid else {
            completion(HugRequestResult.swiftError(.noCurrentUser))
            return
        }
        
        
        guard let hugImage = self.snapData?.image else {
            return
        }
        
        var hugRequestImageURLString: String?
        
        
        let hugsReqCollectionPath = Constants.Collections.HugRequestsCollectionRef
        
        let timeInterval = Date().timeIntervalSince1970
        let timestamp = Timestamp(date: Date(timeIntervalSince1970: timeInterval))
        
        
        saveHugImageInStorage(image: hugImage) { result in
            switch result {
            case .failure(ImageError.invalidImageData):
                print("Invalid Image Error")
            case .success(let url):
                hugRequestImageURLString = url.absoluteString
                let hugReqsDocRef = Constants.Collections.HugRequestsCollectionRef.document()
                let docID = hugReqsDocRef.documentID
                let senderScreenWidth = AppDelegate.screenWidth
                let senderScreenHeight = AppDelegate.screenHeight
                
                let hugRequest = HugRequest(hugrequestSenderUID: currentUserUID, hugrequestReceiverUID: seaerchedUserUID, sender: currentUserUsername, receiver: searchedUserUsername, description: self.snapData?.text ?? "", senderProfileImgUrl: AppUserSingleton.shared.appUser?.profileImageURL ?? "", hugRequestImage: hugRequestImageURLString, gif: self.selectedGIF, timestamp: timestamp, textLocation: self.snapData?.position, senderScreenWidth: senderScreenWidth, senderScreenHeight: senderScreenHeight, uid: docID)
                
                
                do {
                    let data = try Firestore.Encoder().encode(hugRequest)
                    hugReqsDocRef.setData(data) { error in
                        if let error = error {
                            print("Error saving hug request document: \(error)")
                            completion(HugRequestResult.fireStoreError(.dataConversion))
                            return
                        } else {
                            HugRequestsSentManager.shared.hugRequestsSent.append(hugRequest)
                            print("Hug request document saved successfully.")
                        }
                    }
                } catch {
                    completion(HugRequestResult.fireStoreError(.dataConversion))
                    return
                }
                
                self.usersCollection.whereField(Constants.Firebase.USERNAME, isEqualTo: currentUserUsername).getDocuments { querySnapshot, error in
                    if let error = error {
                        print("Error getting documents: \(error)")
                        return
                    } else {
                        for document in querySnapshot!.documents {
                            // Access the document data here
                            let docRef = document.reference
                            docRef.updateData([
                                "hugrequestssent": FieldValue.arrayUnion([docID])
                            ]) { err in
                                if let err = err {
                                    print("Error updating document: \(err)")
                                    completion(HugRequestResult.fireStoreError(.fetchDocument))
                                    return
                                } else {
                                    print("Document successfully updated.")
                                    completion(.saved)
                                }
                            }
                        }
                    }
                }
                
                self.usersCollection.whereField(Constants.Firebase.USERNAME, isEqualTo: searchedUserUsername).getDocuments { querySnapshot, error in
                    if let error = error {
                        print("Error getting documents: \(error)")
                        return
                    } else {
                        for document in querySnapshot!.documents {
                            // Access the document data here
                            let docRef = document.reference
                            docRef.updateData([
                                "hugrequestsreceived": FieldValue.arrayUnion([docID])
                                
                            ]) { err in
                                if let err = err {
                                    print("Error updating document: \(err)")
                                    completion(HugRequestResult.fireStoreError(.fetchDocument))
                                    return
                                } else {
                                    print("Document successfully updated.")
                                    completion(.saved)
                                    self.sendPushNotification(toToken: searchedUserFCMToken, withMessage: "You have received a hug by \(currentUserUsername)")
                                    return
                                }
                            }
                        }
                    }
                }
            default:
                break
                
            }
        }
        
    }
    
    func sendPushNotification(toToken token: String, withMessage message: String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        guard let url = URL(string: urlString) else {
            return
        }
        
        let headers: [String: String] = [
            "Authorization": SensitiveData.SERVER_KEY,
            "Content-Type": "application/json"
        ]
        
        let notification: [String: Any] = [
            "title": "New Hug Request",
            "body": message
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
    
    
    
    
    @objc func sendHugRequest() {
        requestHugBtn.isEnabled = false
        checkIfHugRequestWasAlreadySent { result in
            switch result {
            case .success(let wasSent):
                if !wasSent {
                    self.saveHugRequestInFirestore { hugRequestResult in
                        switch hugRequestResult {
                        case .saved:
                            print("Hug request was sent!")
                            self.selectGIFDelegate?.hugRequestSent(success: true)
                            self.transitionToSearchedUser()
                        case .fireStoreError(.fetchDocument):
                            self.selectGIFDelegate?.hugRequestSent(success: false)
                            self.transitionToSearchedUser()
                            print("There was an error with the network")
                        case .swiftError(.noCurrentUser):
                            self.selectGIFDelegate?.hugRequestSent(success: false)
                            self.transitionToSearchedUser()
                            print("There was no current user")
                        case .swiftError(.noSearchedUser):
                            self.selectGIFDelegate?.hugRequestSent(success: false)
                            self.transitionToSearchedUser()
                            print("There was no searched user")
                        default:
                            break
                        }
                        self.loadingIndicator.stopAnimating()
                    }
                } else {
                    self.loadingIndicator.stopAnimating()
                }
            case .failure(let error):
                switch error {
                case FirestoreError.fetchDocument:
                    print("Fetch document error")
                case FirestoreError.noCurrentUser:
                    print("No current user")
                case FirestoreError.dataConversion:
                    print("Error converting data")
                case SwiftError.noCurrentUser:
                    print("No current Swift user")
                case SwiftError.noSearchedUser:
                    print("No searched user")
                default:
                    break
                }
                self.loadingIndicator.stopAnimating()
            }
        }
    }
    
    func checkIfHugRequestWasAlreadySent(completion: @escaping (Result <Bool, Error>) -> ()) {
        guard let currentUserUsername = AppUserSingleton.shared.appUser?.userName else {
            completion(.failure(SwiftError.noCurrentUser))
            return
        }
        
        guard let searchedUserUsername = self.searchedUser?.userName else {
            completion(.failure(SwiftError.noSearchedUser))
            return
        }
        
        
        // Query 1: Fetch documents where sender is "Özgün" and receiver is "Sanya"
        let query1 = hugRequestsCollection
            .whereField("sender", isEqualTo: currentUserUsername)
            .whereField("receiver", isEqualTo: searchedUserUsername)
        
        // Query 2: Fetch documents where sender is "Sanya" and receiver is "Özgün"
        let query2 = hugRequestsCollection
            .whereField("sender", isEqualTo: searchedUserUsername)
            .whereField("receiver", isEqualTo: currentUserUsername)
        // Perform Query 1
        query1.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents from Query 1: \(error)")
                completion(.failure(FirestoreError.fetchDocument))
                return
            }
            
            // Process the documents from Query 1
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                // Handle the documents
                completion(.success(true))
                return
            }
            // Perform Query 2
            query2.getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents from Query 2: \(error.localizedDescription)")
                    completion(.failure(FirestoreError.fetchDocument))
                    return
                }
                // Process the documents from Query 2
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    completion(.success(true))
                    return
                } else {
                    completion(.success(false))
                    return
                }
            }
        }
    }
    
    func transitionToSearchedUser() {
        
        let thisViewController = self
        guard let lastViewController = self.multiCamVCInstance else { return }
        
        thisViewController.dismiss(animated: false) {
            lastViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func cancelHugRequest() {
        // Create the alert controller
        let alertController = UIAlertController(title: "Are you sure you want to cancel?", message: nil, preferredStyle: .alert)
        
        // Add "No" button action
        alertController.addAction(UIAlertAction(title: "No", style: .default, handler: { _ in
            // Dismiss the alert if "No" is tapped
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        // Add "Yes" button action
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            // Run the code in your cancelHugRequest function
            self?.transitionToSearchedUser()
        }))
        
        // Present the alert
        present(alertController, animated: true, completion: nil)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        requestHugBtn.backgroundColor = originalBackgroundColor
        requestHugBtn.isEnabled = true
        selectedGIF = gifs[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GIFCell", for: indexPath) as! GIFCell
        cell.gifImageView.loadGif(name: gifs[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow: CGFloat = 3
        let spacingBetweenCells: CGFloat = 10
        let totalSpacing = (numberOfItemsPerRow - 1) * spacingBetweenCells
        let width = (collectionView.bounds.width - totalSpacing) / numberOfItemsPerRow
        return CGSize(width: width, height: width)
    }
    
    
}

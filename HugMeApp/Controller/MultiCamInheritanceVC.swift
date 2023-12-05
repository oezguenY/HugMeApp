//
//  MultiCamInheritanceVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 16.08.23.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseCore
import FirebaseStorage
import Vision

class MultiCamInheritanceVC: MultiCamVC {
    
    private var isPostButtonEnabled = true
    
    weak var delegate: MultiCamInheritanceVCDelegate?
    
    var hugRequest: HugRequest?
    
    var loadingIndicator: UIActivityIndicatorView!
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "TAKE A PICTURE OF YOUR HUG! 😊❤️"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.boldSystemFont(ofSize: (AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000 * 12)
        label.textColor = .white
        return label
    }()
    
    private let postPictureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Post", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: (AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000 * 14)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.backgroundColor = #colorLiteral(red: 0.6748731732, green: 0.286393702, blue: 0.3081133366, alpha: 1)
        return button
    }()
    
    func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .white
        loadingIndicator.center = view.center
        view.addSubview(loadingIndicator)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide unnecessary buttons and features
        addTextFieldButton.removeFromSuperview()
        selectGIFButton.removeFromSuperview()
//        switchCameraButton.removeFromSuperview()
//        addTextFieldButton.isHidden = true
//        selectGIFButton.isHidden = true
        postPictureButton.isHidden = true
    
        
//        setConstraints()
        postPictureButton.addTarget(self, action: #selector(postPictureButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        shutterButton.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height - 100)
    }
    
    // Inside MultiCamInheritanceVC class

    
    override func setConstraints() {
        super.setConstraints()
        view.addSubview(titleLabel)
        view.addSubview(postPictureButton)
       // Constraints for the titleLabel
       titleLabel.translatesAutoresizingMaskIntoConstraints = false
       postPictureButton.translatesAutoresizingMaskIntoConstraints = false
        
//        let configuration = UIImage.SymbolConfiguration(pointSize: (AppDelegate.screenHeight / AppDelegate.screenWidth) * 16, weight: .bold)
//        let image = UIImage(systemName: "arrow.triangle.2.circlepath.camera", withConfiguration: configuration)
//        switchCameraButton.setBackgroundImage(image, for: .normal)
        
       NSLayoutConstraint.activate([
           titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
           titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: AppDelegate.screenHeight / 15),
           postPictureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -AppDelegate.screenHeight / 20),
           postPictureButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppDelegate.screenWidth / 30),
           postPictureButton.widthAnchor.constraint(equalToConstant: AppDelegate.screenWidth / 2.5),
           postPictureButton.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 18),
           titleLabel.widthAnchor.constraint(equalToConstant: AppDelegate.screenWidth / 2),
       ])
    }
    
    override func didTapTakePhoto() {
        super.didTapTakePhoto()
        
        // Show the postPictureButton
        selectGIFButton.isHidden = true
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    

    @objc func postPictureButtonTapped() {
        
        guard isPostButtonEnabled else {
               return
           }

           isPostButtonEnabled = false

           guard let capturedPhoto = self.capturedImage else {
               DispatchQueue.main.async {
                   self.loadingIndicator.stopAnimating()
                   self.delegate?.didFinishPostingHug(success: false)
                   self.isPostButtonEnabled = true
               }
               return
           }

           // Create a DispatchGroup
           let dispatchGroup = DispatchGroup()

           var facesDetected = false // Flag to track if any faces were detected

           // Step 1: Convert the captured photo to a CIImage
           guard let ciImage = CIImage(image: capturedPhoto.rotate()) else {
               DispatchQueue.main.async {
                   self.loadingIndicator.stopAnimating()
                   self.delegate?.didFinishPostingHug(success: false)
               }
               return
           }

           // Step 2: Create a face detection request
           let faceDetectionRequest = VNDetectFaceRectanglesRequest { request, error in
               // Step 4: Process the results
               defer {
                   // Leave the DispatchGroup when the request is done
                   dispatchGroup.leave()
               }

               if let error = error {
                   print("Face detection error: \(error)")
                   DispatchQueue.main.async {
                       self.loadingIndicator.stopAnimating()
                       self.delegate?.didFinishPostingHug(success: false)
                   }
                   return
               }

               guard let results = request.results as? [VNFaceObservation] else {
                   // After TestFlight, add -> , results.count > 1 so it only works if at least two faces are detected
                   // No faces detected
                   print("No face detected")
                   return
               }

               // Faces were detected
               print("Face detected")
               facesDetected = true // Set the flag to true if any faces are detected
           }

           // Step 3: Perform face detection using Vision
           dispatchGroup.enter() // Enter the DispatchGroup before starting the request
           do {
               try VNImageRequestHandler(ciImage: ciImage, options: [:]).perform([faceDetectionRequest])
           } catch {
               print("Face detection request error: \(error)")
               dispatchGroup.leave() // Leave the DispatchGroup in case of an error
           }

           // Wait for the face detection to complete
           dispatchGroup.wait()

           // Check the facesDetected flag and return early if no faces were detected
           if !facesDetected {
               DispatchQueue.main.async {
                   self.loadingIndicator.stopAnimating()
                   self.delegate?.didFinishPostingHug(success: false)
                   self.isPostButtonEnabled = true
               }
               return
           }
        

        
        guard let hugRequest = self.hugRequest else {
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.delegate?.didFinishPostingHug(success: false)
                self.isPostButtonEnabled = true
            }
            return
        }

        
        // MARK: - CHANGE NECESSARY
            
        // muss geändert werden für den Fall ,dass der user kein profilbild hat
        guard let appUserProfileImgURL = AppUserSingleton.shared.appUser?.profileImageURL else {
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.delegate?.didFinishPostingHug(success: false)
                self.isPostButtonEnabled = true
            }
            return
        }
        
        uploadPhotoToFirestoreStorage(photo: capturedPhoto) { [weak self] result in
            guard let self = self else {
                self?.isPostButtonEnabled = true
                return
            }
            
            switch result {
            case .success(let photoURL):
                print("Photo uploaded successfully: \(photoURL)")
                
                self.saveHugPostToFirestore(
                    photoURL: photoURL,
                    hugRequest: hugRequest,
                    appUserProfileImgURL: appUserProfileImgURL
                ) { [weak self] result in
                    guard let self = self else {
                        return }
                    
                    switch result {
                    case .success(let docID):
                        // Hug post saved successfully
                        print("Hug post saved successfully.")
                        
                        // Add the docID to users' documents and remove hug requests
                        self.addHugToUsersDocumentsAndRemoveHugRequests(
                            docID: docID,
                            senderUsername: hugRequest.sender,
                            receiverUsername: hugRequest.receiver,
                            hugRequestUID: hugRequest.uid
                        ) { [weak self] addUserResult in
                            guard let self = self else {
                                return }
                            
                            switch addUserResult {
                            case .success:
                                // Successfully added hug to users' documents
                                print("Hug added to users' documents successfully.")
                                self.deleteHugRequestFromUserDocument(hugRequestUID: hugRequest.uid) { [weak self] result in
                                    guard let self = self else {
                                        return }
                                    
                                    switch result {
                                    case .success():
                                        print("Hug request was deleted successfully from Receiver document.")
                                    case .failure(let error):
                                        print("Hug request could not be deleted from Receiver document: \(error)")
                                    }
                                }
                                
                                deleteHugRequestPictureFromStorage { }
                                
                                self.deleteHugRequestFromSenderDocument(hugRequestUID: hugRequest.uid) { [weak self] result in
                                    guard let self = self else { return }
                                    
                                    switch result {
                                    case .success():
                                        print("Hug request was deleted successfully from Sender document.")
                                    case .failure(let error):
                                        print("Hug request could not be deleted from Sender document: \(error)")
                                    }
                                }
                                // Delete hug request from collection
                                self.deleteHugRequestFromHugRequestCollection(hugRequestUID: hugRequest.uid) { [weak self] deleteResult in
                                    guard let self = self else { return }
                                    
                                    switch deleteResult {
                                    case .success:
                                        // Hug request deleted successfully
                                        
                                        print("Hug request deleted successfully.")
                                        DispatchQueue.main.async {
                                            self.loadingIndicator.stopAnimating()
                                            self.delegate?.didFinishPostingHug(success: true)
                                            self.isPostButtonEnabled = true
                                        }
                                        
                                    case .failure(let deleteError):
                                        // Handle deleteError and display error alert
                                        print("Error deleting hug request: \(deleteError)")
                                        DispatchQueue.main.async {
                                            self.loadingIndicator.stopAnimating()
                                            self.delegate?.didFinishPostingHug(success: false)
                                            self.isPostButtonEnabled = true
                                        }
                                    }
                                }
                                
                            case .failure(let addUserError):
                                // Handle addUserError and display error alert
                                print("Error adding hug to users' documents: \(addUserError)")
                                DispatchQueue.main.async {
                                    self.loadingIndicator.stopAnimating()
                                    self.delegate?.didFinishPostingHug(success: false)
                                    self.isPostButtonEnabled = true
                                }
                            }
                        }
                        
                    case .failure(let error):
                        // Handle the error and display error alert
                        print("Error: \(error)")
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            self.delegate?.didFinishPostingHug(success: false)
                            self.isPostButtonEnabled = true
                        }
                    }
                }
                
            case .failure(let error):
                // Handle error, e.g., show an alert to the user, retry the upload, etc.
                print("Error uploading photo: \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.delegate?.didFinishPostingHug(success: false)
                    self.isPostButtonEnabled = true
                }
            }
        }
    }
   

    func uploadPhotoToFirestoreStorage(photo: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        loadingIndicator.startAnimating()
        guard let photoData = photo.jpegData(compressionQuality: 0.8) else {
            completion(.failure(PhotoUploadError.invalidImageData))
            return
        }
        
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = Storage.storage().reference().child("HugPosts").child(fileName)
        
        storageRef.putData(photoData, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let photoURL = url?.absoluteString {
                    completion(.success(photoURL))
                    self.loadingIndicator.stopAnimating()
                } else {
                    completion(.failure(PhotoUploadError.urlNotFound))
                }
            }
        }
    }
    
    func saveHugPostToFirestore(
        photoURL: String,
        hugRequest: HugRequest,
        appUserProfileImgURL: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let timestamp = Timestamp(date: Date())
        let hugPostDocumentRef = Constants.Collections.HugPostsRef.document()
        let docID = hugPostDocumentRef.documentID
        let hugPost = Hug(hugSenderUID: hugRequest.hugrequestSenderUID, hugReceiverUID: hugRequest.hugrequestReceiverUID, 
            senderUsername: hugRequest.sender,
            receiverUsername: hugRequest.receiver,
            senderImageUrl: hugRequest.senderProfileImgUrl,
            receiverImageUrl: appUserProfileImgURL,
            hugPicture: photoURL,
            gif: hugRequest.gif ?? "",
            timestamp: timestamp,
            uid: docID
        )
        
        do {
            let data = try Firestore.Encoder().encode(hugPost)
            hugPostDocumentRef.setData(data) { error in
                if let error = error {
                    print("Error saving hug request document: \(error)")
                    completion(.failure(error))
                } else {
                    print("Hug request document saved successfully.")
                    completion(.success(docID))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func addHugToUsersDocumentsAndRemoveHugRequests(docID: String, senderUsername: String, receiverUsername: String, hugRequestUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let usersCollectionRef = Constants.Collections.UsersCollectionRef
        
        // Search for the sender's document
        usersCollectionRef
            .whereField("username", isEqualTo: senderUsername)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let senderDocument = snapshot?.documents.first {
                    let senderDocumentRef = usersCollectionRef.document(senderDocument.documentID)
                    senderDocumentRef.updateData(["hugsgiven": FieldValue.arrayUnion([docID])]) { error in
                        if let error = error {
                            completion(.failure(error))
                            print(error.localizedDescription)
                        } else {
                            // Search for the receiver's document
                            usersCollectionRef
                                .whereField("username", isEqualTo: receiverUsername)
                                .getDocuments { (snapshot, error) in
                                    if let error = error {
                                        completion(.failure(error))
                                        return
                                    }
                                    
                                    if let receiverDocument = snapshot?.documents.first {
                                        let receiverDocumentRef = usersCollectionRef.document(receiverDocument.documentID)
                                        receiverDocumentRef.updateData([
                                            "hugsgotten": FieldValue.arrayUnion([docID]),
                                        ]) { error in
                                            if let error = error {
                                                completion(.failure(error))
                                            } else {
                                                completion(.success(()))
                                            }
                                        }
                                    } else {
                                        let error = NSError(domain: "Receiver document not found", code: -1, userInfo: nil)
                                        completion(.failure(error))
                                    }
                                }
                        }
                    }
                } else {
                    let error = NSError(domain: "Sender document not found", code: -1, userInfo: nil)
                    completion(.failure(error))
                }
            }
    }
    
    func deleteHugRequestPictureFromStorage(completion: @escaping () -> ()) {
        
        guard let hugRequest = hugRequest else {
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
    
    func deleteHugRequestFromHugRequestCollection(hugRequestUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let hugRequestCollectionRef = Constants.Collections.HugRequestsCollectionRef.document(hugRequestUID)
        
        hugRequestCollectionRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteHugRequestFromUserDocument(hugRequestUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
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
    
    func deleteHugRequestFromSenderDocument(hugRequestUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Check if hugRequest is nil or sender is nil
        guard let sender = hugRequest?.sender else {
            let error = NSError(domain: "Invalid hugRequest", code: -1, userInfo: nil)
            completion(.failure(error))
            return
        }
        
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


    enum PhotoUploadError: Error {
        case invalidImageData
        case urlNotFound
    }
    
    override func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        super.photoOutput(output, didFinishProcessingPhoto: photo, error: error)
        view.addSubview(postPictureButton)
        setupLoadingIndicator()
        
        // Delay the appearance of the postPictureButton by 0.5 seconds (adjust as needed)
        self.postPictureButton.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.postPictureButton.isHidden = false
            self.postPictureButton.isEnabled = true
        }
    }
}

extension UIImage {

func rotate() -> UIImage {
    var rotatedImage = UIImage()
    guard let cgImage = cgImage else {
        print("could not rotate image")
        return self
    }
    switch imageOrientation {
    case .right:
        rotatedImage = UIImage(cgImage: cgImage, scale: scale, orientation: .down)
    case .down:
        rotatedImage = UIImage(cgImage: cgImage, scale: scale, orientation: .left)
    case .left:
        rotatedImage = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    default:
        rotatedImage = UIImage(cgImage: cgImage, scale: scale, orientation: .right)
    }
    
    return rotatedImage
}
}


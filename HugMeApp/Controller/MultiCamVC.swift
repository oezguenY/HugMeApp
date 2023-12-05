//
//  MultiCamVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 04.08.23.
//

import UIKit
import AVFoundation

class MultiCamVC: UIViewController {
    
    var searchedUserVC: SearchedUserVC?
    
    private var snapTextPosition: CGPoint?
    
    private var snapData: SnapData?
    
    var capturedImage: UIImage?
    
    var searchedUser: AppUser?
    
    // Capture Session
    var session: AVCaptureSession?
    // Photo Output
    let output = AVCapturePhotoOutput()
    // Video Preview
    let previewLayer = AVCaptureVideoPreviewLayer()
    // Shutter Button
     let shutterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: (AppDelegate.screenHeight / AppDelegate.screenWidth) * 16, weight: .bold)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        return button
    }()
    
     let switchCameraButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()
    
     let addTextFieldButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add Text", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
     let selectGIFButton: UIButton = {
        let button = UIButton()
        button.setTitle("Select GIF", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        return button
    }()
    
    private var activeTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutterButton)
        checkCameraPermission()
        view.addSubview(switchCameraButton)
        view.addSubview(addTextFieldButton)
        view.addSubview(selectGIFButton)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideTextField))
        view.addGestureRecognizer(tapGesture)
        selectGIFButton.addTarget(self, action: #selector(didTapSelectGIF), for: .touchUpInside)
        selectGIFButton.isHidden = true
        switchCameraButton.addTarget(self, action: #selector(didTapSwitchCamera), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(didTapTakePhoto), for: .touchUpInside)
        addTextFieldButton.addTarget(self, action: #selector(didTapAddTextField), for: .touchUpInside)
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        setConstraints()
        snapTextPosition = CGPoint(x: view.center.x, y: view.center.y)
    }
    
    @objc private func handleTapOutsideTextField() {
        // If there's an active text field, resign its first responder status to dismiss the keyboard
        activeTextField?.resignFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        shutterButton.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height - 100)
        
        selectGIFButton.frame = CGRect(x: view.bounds.width - 120, y: view.bounds.height - 80, width: 100, height: 40)
        selectGIFButton.layer.cornerRadius = 20
    }
    
    @objc private func didTapSelectGIF() {
        
        guard let capturedPhoto = self.capturedImage else { return }
        // snapTextPosition was given an initial value in the viewDidLoad, so it is ensured it always has a value. If the text was not moved by the user, it will be centered in the view
        let snapInstance = SnapData(text: activeTextField?.text ?? "", position: self.snapTextPosition!, image: capturedPhoto)
        
        let selectGIFVC = SelectGIFVC()
        selectGIFVC.snapData = snapInstance
        selectGIFVC.searchedUser = self.searchedUser
        selectGIFVC.selectGIFDelegate = searchedUserVC
        selectGIFVC.multiCamVCInstance = self
        selectGIFVC.modalPresentationStyle = .fullScreen
        present(selectGIFVC, animated: true)
    }
    
    
    @objc private func didTapSwitchCamera() {
        guard let currentInput = session?.inputs.first as? AVCaptureDeviceInput else { return }
        let currentCamera = currentInput.device
        
        let newCameraPosition: AVCaptureDevice.Position
        if currentCamera.position == .back {
            newCameraPosition = .front
        } else {
            newCameraPosition = .back
        }
        
        guard let newCamera = getCamera(with: newCameraPosition) else { return }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            session?.beginConfiguration()
            session?.removeInput(currentInput)
            if session?.canAddInput(newInput) == true {
                session?.addInput(newInput)
            }
            session?.commitConfiguration()
        } catch {
            print("Error switching camera: \(error)")
        }
    }
    
    private func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        return discoverySession.devices.first { $0.position == position }
    }
    
    @objc private func didTapAddTextField() {
        // Create a UITextField and add it to the view
        addTextFieldButton.setTitle("", for: .normal)
        let textField = UITextField()
        textField.becomeFirstResponder()
        activeTextField = textField
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.backgroundColor = UIColor.white.withAlphaComponent(0.5) // Set the background color with alpha
        textField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)
        // Position the text field in the middle of the screen using Auto Layout
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            textField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Make the text field the first responder to show the keyboard
        textField.becomeFirstResponder()
    }
    
     func setConstraints() {
        view.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        addTextFieldButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDelegate.screenWidth / 30),
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: AppDelegate.screenHeight / 15),
            switchCameraButton.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: AppDelegate.screenHeight / 30),
            switchCameraButton.centerXAnchor.constraint(equalTo: dismissButton.centerXAnchor),
            addTextFieldButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addTextFieldButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            addTextFieldButton.widthAnchor.constraint(equalToConstant: 150),
            addTextFieldButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    return
                }
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    private func setUpCamera() {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                session.startRunning()
                self.session = session
            }
            catch {
                print(error)
            }
        }
    }
    
    @objc func didTapTakePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        showSelectGIFButton()
    }
    
    private func showSelectGIFButton() {
        selectGIFButton.isHidden = false
    }
    
}

extension MultiCamVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        let image = UIImage(data: data)
        
        capturedImage = image
        
        session?.stopRunning()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        view.addSubview(imageView)
        
        view.addSubview(dismissButton)
        
        if let text = activeTextField?.text, !text.isEmpty {
            let snapText = UILabel()
            snapText.translatesAutoresizingMaskIntoConstraints = false
            snapText.text = text
            snapText.font = UIFont.systemFont(ofSize: 30)
            snapText.textAlignment = .center
            snapText.textColor = .white
            snapText.backgroundColor = .clear
            snapText.numberOfLines = 0 // Allow multiple lines of text
            snapText.adjustsFontSizeToFitWidth = true // Auto-shrink text to fit width
            snapText.minimumScaleFactor = 0.5 // Minimum font scale factor (you can adjust this value)
            snapText.sizeToFit()
            snapText.preferredMaxLayoutWidth = AppDelegate.screenWidth * 0.9

            snapText.lineBreakMode = .byWordWrapping
            snapText.center = view.center
            snapText.isUserInteractionEnabled = true
            snapText.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
            view.addSubview(snapText)
            
            snapText.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            snapText.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
        view.addSubview(selectGIFButton)
    }
}

extension MultiCamVC {
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let label = gestureRecognizer.view as? UILabel else { return }
        
        if gestureRecognizer.state == .began {
                   // Store the initial position of the snapText
                   snapTextPosition = label.center
               }

        
        let translation = gestureRecognizer.translation(in: view)
        let center = CGPoint(x: label.center.x + translation.x, y: label.center.y + translation.y)
        
        // Ensure the label remains within the bounds of the view
        let halfWidth = label.bounds.width / 2
        let halfHeight = label.bounds.height / 2
        let minX = halfWidth
        let maxX = view.bounds.width - halfWidth
        let minY = halfHeight
        let maxY = view.bounds.height - halfHeight
        
        let clampedX = max(minX, min(maxX, center.x))
        let clampedY = max(minY, min(maxY, center.y))
        
        label.center = CGPoint(x: clampedX, y: clampedY)
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
                    // Update the snapText position when the user finishes dragging
                    snapTextPosition = label.center
                }
        gestureRecognizer.setTranslation(.zero, in: view)
    }
    
    @objc private func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

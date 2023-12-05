//
//  FullScreenHugVC.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 16.08.23.
//

import UIKit

class FullScreenHugVC: UIViewController {
     let imageView = UIImageView()
     let textLabel = UILabel()
     let dismissButton = UIButton(type: .system)

    var snapData: SnapData?
    var senderScreenWidth: Double?
    var senderScreenHeight: Double?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        textLabel.textColor = .white
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)

        let configuration = UIImage.SymbolConfiguration(pointSize: (AppDelegate.screenHeight / AppDelegate.screenWidth) * 16, weight: .bold)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration)
        dismissButton.setImage(image, for: .normal)
        dismissButton.tintColor = .white
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        view.addSubview(dismissButton)

        setupConstraints()
        imageView.image = snapData?.image
        textLabel.text = snapData?.text
        textLabel.font = UIFont.systemFont(ofSize: 30)
    }
    
    private func convertCGPoint() -> CGPoint? {
        
        guard let senderScreenWidth = self.senderScreenWidth, let senderScreenHeight = self.senderScreenHeight, let originalPoint = snapData?.position else { return nil }
        
        let scaleX = AppDelegate.screenWidth / senderScreenWidth
        let scaleY = AppDelegate.screenHeight / senderScreenHeight
        
        let convertedPoint = CGPoint(
            x: originalPoint.x * scaleX,
            y: originalPoint.y * scaleY
        )
        return convertedPoint
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppDelegate.screenWidth / 30),
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: AppDelegate.screenHeight / 15),
        ])

        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: convertCGPoint()?.x ?? 0.0),
            textLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: convertCGPoint()?.y ?? 0.0)
        ])
    }
    
  

    @objc private func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}





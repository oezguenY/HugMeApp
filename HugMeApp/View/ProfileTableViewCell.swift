//
//  ProfileTableViewCell.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 02.09.23.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

    let profileBackgroundView: UIView = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = UIScreen.main.bounds
        gradientLayer.colors = [
            UIColor(red: 1, green: 0.70080477, blue: 0.6055344939, alpha: 0.3).cgColor, // Your specified color
            UIColor.systemPink.cgColor, // Another color for gradient
        ]
        gradientLayer.locations = [0.0, 1.0] // Adjust the positions of colors
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        let view = UIView()
        view.layer.insertSublayer(gradientLayer, at: 0) // Add the gradient layer as the background
        
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()

    
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
//        imageView.loadGif(name: "gif17")
        return imageView
    }()
    
    let cameraBtn: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.layer.cornerRadius = button.frame.size.width / 2 // Make it round
        button.backgroundColor = .black
        button.tintColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        
        // Create the camera image with the desired size and content mode
        let cameraImage = UIImage(systemName: "camera.circle.fill")
        let imageView = UIImageView(image: cameraImage)
        imageView.contentMode = .scaleAspectFill // Fill the entire button
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the image view to the button
        button.addSubview(imageView)
        
        // Center the image view inside the button
        imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        
        return button
    }()
    
    
    // Define your UILabels here
    let fullNameLbl: UILabel = {
        let label = UILabel()
        label.text = "Özgün Yildiz"
        label.minimumScaleFactor = 0.7
        label.font = UIFont.systemFont(ofSize: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 18, weight: .heavy)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = .byClipping
        return label
    }()

    
    let usernameLbl: UILabel = {
        let label = UILabel()
        label.text = "@bestdonutinbakery"
        label.minimumScaleFactor = 0.5
        label.font = UIFont(name: "HelveticaNeue", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 10)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = .byClipping
        return label
    }()
    
    let hugsReceivedAmountLbl: UILabel = {
        let label = UILabel()
        label.text = "105"
        label.font = UIFont.systemFont(ofSize: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 16, weight: .heavy)
        return label
    }()
    
    let hugsReceivedLbl: UILabel = {
        let label = UILabel()
        label.text = "Hugs gotten"
        label.font = UIFont(name: "HelveticaNeue", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 10)
        return label
    }()
    
    let friendsAmountLbl: UILabel = {
        let label = UILabel()
        label.text = "39"
        label.font = UIFont.systemFont(ofSize: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 16, weight: .heavy)
        return label
    }()
    
    let friendsLbl: UILabel = {
        let label = UILabel()
        label.text = "Friends"
        label.font = UIFont(name: "HelveticaNeue", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 10)
        return label
    }()
    
    let hugsGiveAmountnLbl: UILabel = {
        let label = UILabel()
        label.text = "59"
        label.font = UIFont.systemFont(ofSize: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 16, weight: .heavy)
        return label
    }()
    
    let hugsGivenLbl: UILabel = {
        let label = UILabel()
        label.text = "Hugs given"
        label.font = UIFont(name: "HelveticaNeue", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 10)
        return label
    }()
    
    let addFriendBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Add Friend", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.layer.cornerRadius = 15 // Adjust the corner radius as needed
        button.backgroundColor = .white
        button.clipsToBounds = true // This is important to clip the content inside the rounded corners
        button.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 11) // Replace yourFontSize with the desired font size
        return button
    }()
    
    
    let sendHugRequestBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Send Hug", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 15 // Adjust the corner radius as needed
        button.backgroundColor = .black
        button.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: ((AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000) * 11)
        button.clipsToBounds = true // This is important to clip the content inside the rounded corners
        return button
    }()
    
    let stackview1: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .vertical
        stackview.spacing = AppDelegate.screenHeight / 200
        stackview.alignment = .center
        return stackview
    }()
    
    let stackView2: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .vertical
        stackview.spacing = 1
        stackview.alignment = .center
        return stackview
    }()
    
    let stackView3: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .vertical
        stackview.spacing = 1
        stackview.alignment = .center
        return stackview
    }()
    
    let stackView4: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .vertical
        stackview.spacing = 1
        stackview.alignment = .center
        return stackview
    }()
    
    let stackView5: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .horizontal
        stackview.spacing = AppDelegate.screenWidth / 40
        stackview.distribution = .fillEqually
        return stackview
    }()
    
    let stackView6: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .horizontal
        stackview.spacing = AppDelegate.screenWidth / 12
        return stackview
    }()
    
    let stackView7: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .vertical
        //        stackview.spacing = 1 // Set the desired spacing between elements
        //        stackview.alignment = .center
        stackview.distribution = .fill
        return stackview
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2.0
        cameraBtn.layer.cornerRadius = cameraBtn.frame.size.width / 2
    }
    
    // Add other UI elements as needed
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    
        // Configure the layout and add subviews to the cell's content view
        // Add constraints to position and size your UI elements
        contentView.addSubview(stackView7)
        stackView7.addArrangedSubview(profileImageView)
        stackView7.addArrangedSubview(stackview1)
        stackView7.addArrangedSubview(stackView5)
        stackView7.addArrangedSubview(stackView6)
        
        contentView.addSubview(profileBackgroundView)
        contentView.addSubview(profileImageView)
        contentView.addSubview(stackview1)
        stackview1.addArrangedSubview(fullNameLbl)
        stackview1.addArrangedSubview(usernameLbl)
        
        contentView.addSubview(stackView2)
        stackView2.addArrangedSubview(hugsReceivedAmountLbl)
        stackView2.addArrangedSubview(hugsReceivedLbl)
        
        contentView.addSubview(stackView3)
        stackView3.addArrangedSubview(friendsAmountLbl)
        stackView3.addArrangedSubview(friendsLbl)
        
        contentView.addSubview(stackView4)
        stackView4.addArrangedSubview(hugsGiveAmountnLbl)
        stackView4.addArrangedSubview(hugsGivenLbl)
        
        contentView.addSubview(stackView5)
        stackView5.addArrangedSubview(addFriendBtn)
        stackView5.addArrangedSubview(sendHugRequestBtn)
        
        contentView.addSubview(stackView6)
        stackView6.addArrangedSubview(stackView2)
        stackView6.addArrangedSubview(stackView3)
        stackView6.addArrangedSubview(stackView4)
        
        
        stackView7.translatesAutoresizingMaskIntoConstraints = false
        stackView7.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        stackView7.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        stackView7.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        stackView7.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        
        stackview1.translatesAutoresizingMaskIntoConstraints = false
        stackview1.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: AppDelegate.screenHeight / 200).isActive = true
        stackview1.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppDelegate.screenHeight / 100).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 8).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 8).isActive = true
        
        profileBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        profileBackgroundView.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: AppDelegate.screenHeight / 18).isActive = true
        profileBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppDelegate.screenWidth / 50).isActive = true
        profileBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppDelegate.screenWidth / 50).isActive = true
        profileBackgroundView.bottomAnchor.constraint(equalTo: stackView7.bottomAnchor, constant: -AppDelegate.screenHeight / 100).isActive = true
        
        fullNameLbl.translatesAutoresizingMaskIntoConstraints = false
        fullNameLbl.widthAnchor.constraint(lessThanOrEqualToConstant: AppDelegate.screenWidth * 0.7).isActive = true
        fullNameLbl.setContentCompressionResistancePriority(.required, for: .horizontal)
        fullNameLbl.centerXAnchor.constraint(equalTo: stackview1.centerXAnchor).isActive = true
        fullNameLbl.topAnchor.constraint(equalTo: stackview1.topAnchor, constant: 10).isActive = true
        
        usernameLbl.translatesAutoresizingMaskIntoConstraints = false
        usernameLbl.widthAnchor.constraint(lessThanOrEqualToConstant: AppDelegate.screenWidth / 2).isActive = true
        usernameLbl.setContentCompressionResistancePriority(.required, for: .horizontal)
        usernameLbl.centerXAnchor.constraint(equalTo: stackview1.centerXAnchor).isActive = true
        usernameLbl.topAnchor.constraint(equalTo: fullNameLbl.bottomAnchor, constant: 20).isActive = true
        
        stackView3.translatesAutoresizingMaskIntoConstraints = false
        
        friendsAmountLbl.translatesAutoresizingMaskIntoConstraints = false
        friendsAmountLbl.topAnchor.constraint(equalTo: stackView3.topAnchor, constant: AppDelegate.screenHeight / 100).isActive = true
        friendsAmountLbl.centerXAnchor.constraint(equalTo: stackView3.centerXAnchor).isActive = true
        
        friendsLbl.translatesAutoresizingMaskIntoConstraints = false
        friendsLbl.topAnchor.constraint(equalTo: friendsAmountLbl.bottomAnchor, constant: AppDelegate.screenHeight / 100).isActive = true
        friendsLbl.centerXAnchor.constraint(equalTo: stackView3.centerXAnchor).isActive = true
        
        stackView2.translatesAutoresizingMaskIntoConstraints = false
        
        hugsReceivedAmountLbl.translatesAutoresizingMaskIntoConstraints = false
        hugsReceivedAmountLbl.topAnchor.constraint(equalTo: stackView3.topAnchor, constant: AppDelegate.screenHeight / 100).isActive = true
        hugsReceivedAmountLbl.centerXAnchor.constraint(equalTo: stackView2.centerXAnchor).isActive = true
        
        hugsReceivedLbl.translatesAutoresizingMaskIntoConstraints = false
        hugsReceivedLbl.topAnchor.constraint(equalTo: hugsReceivedAmountLbl.bottomAnchor, constant: AppDelegate.screenHeight / 500).isActive = true
        hugsReceivedLbl.centerXAnchor.constraint(equalTo: stackView2.centerXAnchor).isActive = true
        
        stackView4.translatesAutoresizingMaskIntoConstraints = false
        
        hugsGiveAmountnLbl.translatesAutoresizingMaskIntoConstraints = false
        hugsGiveAmountnLbl.topAnchor.constraint(equalTo: stackView4.topAnchor, constant: AppDelegate.screenHeight / 100).isActive = true
        hugsGiveAmountnLbl.centerXAnchor.constraint(equalTo: stackView4.centerXAnchor).isActive = true
        
        hugsGivenLbl.translatesAutoresizingMaskIntoConstraints = false
        hugsGivenLbl.topAnchor.constraint(equalTo: hugsGiveAmountnLbl.bottomAnchor, constant: AppDelegate.screenHeight / 100).isActive = true
        hugsGivenLbl.centerXAnchor.constraint(equalTo: stackView4.centerXAnchor).isActive = true
        
        stackView5.translatesAutoresizingMaskIntoConstraints = false
        stackView5.bottomAnchor.constraint(equalTo: profileBackgroundView.bottomAnchor, constant: -AppDelegate.screenHeight / 75).isActive = true
        stackView5.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        stackView6.translatesAutoresizingMaskIntoConstraints = false
        stackView6.topAnchor.constraint(equalTo: stackview1.bottomAnchor, constant: AppDelegate.screenHeight / 60).isActive = true
        stackView6.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        addFriendBtn.translatesAutoresizingMaskIntoConstraints = false
        addFriendBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppDelegate.screenWidth / 20).isActive = true
        addFriendBtn.heightAnchor.constraint(greaterThanOrEqualToConstant: AppDelegate.screenHeight / 18).isActive = true
        
        sendHugRequestBtn.translatesAutoresizingMaskIntoConstraints = false
        sendHugRequestBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppDelegate.screenWidth / 20).isActive = true
        sendHugRequestBtn.heightAnchor.constraint(greaterThanOrEqualToConstant: AppDelegate.screenHeight / 18).isActive = true
        
        contentView.addSubview(cameraBtn)
        
        cameraBtn.translatesAutoresizingMaskIntoConstraints = false
        cameraBtn.widthAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 30).isActive = true // Adjust the width as needed
        cameraBtn.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 30).isActive = true // Adjust the height as needed
        cameraBtn.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 1).isActive = true
        cameraBtn.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 1).isActive = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}





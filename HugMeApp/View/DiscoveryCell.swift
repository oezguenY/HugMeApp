//
//  DiscoveryCell.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 11.08.23.
//

import UIKit

class DiscoveryCell: UITableViewCell {
    
    static let identifier = "DiscoveryCell"
    var profileImg = UIImageView()
    var hugImg = UIImageView()
    var usernameLbl = UILabel()
    var usernameOfPersonTwoLbl = UILabel()
    var gifImageView = UIImageView()
    var timestampLbl = UILabel()
    let imageOptionsBtn = UIButton()
    let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
        addSubviews()
        self.style()
        layout()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        hugImg.layer.cornerRadius                = hugImg.frame.size.width / 20
        hugImg.clipsToBounds                     = true
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
    }
    
    private func addSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(profileImg)
        stackView.addArrangedSubview(usernameLbl)
        stackView.addArrangedSubview(gifImageView)
        stackView.addArrangedSubview(usernameOfPersonTwoLbl)
        addSubview(hugImg)
        addSubview(timestampLbl)
        addSubview(imageOptionsBtn)
    }
    
    private func style() {
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = AppDelegate.screenWidth / 40
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = true
        
        hugImg.translatesAutoresizingMaskIntoConstraints = false
        hugImg.image = UIImage(named: "gif1")
        hugImg.tintColor                         = .label
        hugImg.contentMode = .scaleAspectFill
        hugImg.clipsToBounds                     = true
        hugImg.layoutIfNeeded()
        
        usernameLbl.translatesAutoresizingMaskIntoConstraints = false
        usernameLbl.tintColor                                 = .white
        usernameLbl.font = UIFont(name: "HelveticaNeue-Thin", size: (AppDelegate.screenHeight + AppDelegate.screenWidth) / 90)
        usernameLbl.numberOfLines = 2
        usernameLbl.isUserInteractionEnabled = true
        
        profileImg.translatesAutoresizingMaskIntoConstraints = false
        profileImg.image = UIImage(named: "gif5")
        profileImg.tintColor                         = .label
        profileImg.contentMode = .scaleAspectFill
        profileImg.clipsToBounds                     = true
        profileImg.layoutIfNeeded()
        
        usernameOfPersonTwoLbl.translatesAutoresizingMaskIntoConstraints = false
        usernameOfPersonTwoLbl.tintColor                                 = .white
        usernameOfPersonTwoLbl.font = UIFont(name: "HelveticaNeue-Thin", size: (AppDelegate.screenHeight + AppDelegate.screenWidth) / 90)
        usernameOfPersonTwoLbl.numberOfLines = 2
        usernameOfPersonTwoLbl.isUserInteractionEnabled = true
        
        
        gifImageView.translatesAutoresizingMaskIntoConstraints = false
        gifImageView.contentMode = .scaleAspectFill
        
        timestampLbl.translatesAutoresizingMaskIntoConstraints = false
        timestampLbl.tintColor = .white
        timestampLbl.adjustsFontSizeToFitWidth = true
        timestampLbl.font = UIFont(name: "HelveticaNeue-Thin", size: (AppDelegate.screenHeight + AppDelegate.screenWidth) / 120)
        
        imageOptionsBtn.translatesAutoresizingMaskIntoConstraints = false
        imageOptionsBtn.setImage(UIImage(systemName: "ellipsis"), for: .normal) // You can change the systemName as needed
        imageOptionsBtn.tintColor = .black
        imageOptionsBtn.contentMode = .scaleToFill
        imageOptionsBtn.clipsToBounds = true
        imageOptionsBtn.widthAnchor.constraint(equalToConstant: 32).isActive = true // Adjust the width as needed
        imageOptionsBtn.heightAnchor.constraint(equalToConstant: 32).isActive = true // Adjust the height as needed
        
        
    }
    
    private func layout() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: AppDelegate.screenHeight / 30),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppDelegate.screenHeight / 50),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -AppDelegate.screenHeight / 50),
            
            profileImg.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 20),
            profileImg.widthAnchor.constraint(equalTo: profileImg.heightAnchor),
            usernameLbl.centerYAnchor.constraint(equalTo: profileImg.centerYAnchor, constant: -AppDelegate.screenHeight / 150),
            usernameLbl.leadingAnchor.constraint(equalTo: profileImg.trailingAnchor, constant: AppDelegate.screenWidth / 50),
            gifImageView.centerYAnchor.constraint(equalTo: profileImg.centerYAnchor, constant: -AppDelegate.screenHeight / 150),
            gifImageView.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 30),
            gifImageView.widthAnchor.constraint(equalTo: gifImageView.heightAnchor),
            usernameOfPersonTwoLbl.centerYAnchor.constraint(equalTo: profileImg.centerYAnchor, constant: -AppDelegate.screenHeight / 150),
            hugImg.topAnchor.constraint(equalTo: profileImg.bottomAnchor, constant: AppDelegate.screenHeight / 100),
            hugImg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(AppDelegate.screenHeight / 100)),
            hugImg.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppDelegate.screenWidth / 50),
            hugImg.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppDelegate.screenWidth / 50),
            timestampLbl.topAnchor.constraint(equalTo: topAnchor, constant: AppDelegate.screenHeight / 75),
            timestampLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppDelegate.screenHeight / 50),
            imageOptionsBtn.topAnchor.constraint(equalTo: hugImg.topAnchor, constant: 8), // Adjust the top offset as needed
            imageOptionsBtn.trailingAnchor.constraint(equalTo: hugImg.trailingAnchor, constant: -8),
        ])
    }
    
}

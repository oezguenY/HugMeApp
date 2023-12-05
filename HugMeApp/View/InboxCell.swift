//
//  InboxCell.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 16.08.22.
//

import UIKit

class InboxCell: UITableViewCell {
    
    var cameraBtn: UIButton = {
        let camera = UIButton()
        camera.translatesAutoresizingMaskIntoConstraints = false
        camera.setBackgroundImage(UIImage(systemName: "camera.fill"), for: .normal)
        camera.isHidden = true
        camera.tintColor = .white
        
        return camera
    }()
    
    var tappedImageView: UIImageView? // To display the tapped image
    
    static let identifier      = "InboxCell"
    var profileImageView  = UIImageView()
    var usernameLbl       = UILabel()
    var inboxLbl          = UILabel()
    var acceptRequestBtn  = UIButton()
    var denyRequestBtn    = UIButton()
    var requestStackView  = UIStackView()
    var cellTextStackView = UIStackView()
    var gifImage          = UIImageView()
    var timestampLbl      = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layout()
        self.style()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius                = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds                     = true
    }
    
    func style() {
        requestStackView.translatesAutoresizingMaskIntoConstraints = false
        requestStackView.spacing = AppDelegate.screenWidth / 30
        requestStackView.axis = .horizontal
        requestStackView.alignment = .center
        requestStackView.isUserInteractionEnabled = true
        
        cellTextStackView.translatesAutoresizingMaskIntoConstraints = false
        cellTextStackView.spacing = AppDelegate.screenHeight / 100
        cellTextStackView.axis = .vertical
        cellTextStackView.alignment = .leading
        cellTextStackView.isUserInteractionEnabled = true
        
        usernameLbl.translatesAutoresizingMaskIntoConstraints = false
        usernameLbl.numberOfLines                             = 0
        usernameLbl.adjustsFontSizeToFitWidth                 = true
        usernameLbl.tintColor                                 = .label
        usernameLbl.font = UIFont(name: "HelveticaNeue-Bold", size: (AppDelegate.screenHeight / AppDelegate.screenWidth) * 7)
        usernameLbl.isUserInteractionEnabled = true
        
        inboxLbl.translatesAutoresizingMaskIntoConstraints = false
        inboxLbl.numberOfLines = 0
        inboxLbl.adjustsFontSizeToFitWidth = true
        inboxLbl.tintColor = .gray
        inboxLbl.font = UIFont(name: "HelveticaNeue-Thin", size: (AppDelegate.screenHeight / AppDelegate.screenWidth) * 7)
        
        acceptRequestBtn.translatesAutoresizingMaskIntoConstraints = false
        acceptRequestBtn.tintColor = .label
        
        denyRequestBtn.translatesAutoresizingMaskIntoConstraints   = false
        denyRequestBtn.setBackgroundImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        denyRequestBtn.tintColor = .label
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layoutIfNeeded()
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor                         = .label
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.isUserInteractionEnabled = true
        
        gifImage.translatesAutoresizingMaskIntoConstraints = false
        gifImage.contentMode = .scaleAspectFill
        gifImage.isUserInteractionEnabled = true
        
        timestampLbl.translatesAutoresizingMaskIntoConstraints = false
        timestampLbl.tintColor = .label
        timestampLbl.adjustsFontSizeToFitWidth = true
        timestampLbl.font = UIFont(name: "HelveticaNeue-Thin", size: (AppDelegate.screenHeight + AppDelegate.screenWidth) / 130)
    }
    
    func layout() {
        addSubview(cellTextStackView)
        requestStackView.addArrangedSubview(acceptRequestBtn)
        requestStackView.addArrangedSubview(denyRequestBtn)
        addSubview(requestStackView)
        cellTextStackView.addArrangedSubview(usernameLbl)
        cellTextStackView.addArrangedSubview(inboxLbl)
        addSubview(profileImageView)
        addSubview(gifImage)
        addSubview(timestampLbl)
        
        print("APPDELEGATE SCREENWIDTH PROFILEIMAGE LEADING: \(AppDelegate.screenWidth / 32)")
        
        NSLayoutConstraint.activate([
            requestStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            requestStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(AppDelegate.screenWidth / 20)),
            acceptRequestBtn.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.45),
            acceptRequestBtn.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 0.45),
            denyRequestBtn.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.45),
            denyRequestBtn.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 0.45),
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: AppDelegate.screenHeight / 100),
            profileImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(AppDelegate.screenHeight / 100)),
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppDelegate.screenWidth / 32),
            profileImageView.widthAnchor.constraint(equalTo: profileImageView.heightAnchor),
            usernameLbl.widthAnchor.constraint(lessThanOrEqualToConstant: AppDelegate.screenWidth / 2),
            cellTextStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cellTextStackView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: AppDelegate.screenWidth / 25),
            cellTextStackView.heightAnchor.constraint(equalToConstant: (AppDelegate.screenHeight / AppDelegate.screenWidth) * 25),
            cellTextStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            gifImage.centerYAnchor.constraint(equalTo: inboxLbl.centerYAnchor),
            gifImage.leadingAnchor.constraint(equalTo: inboxLbl.trailingAnchor, constant: AppDelegate.screenWidth / 20),
            gifImage.heightAnchor.constraint(equalToConstant: AppDelegate.screenHeight / 30),
            gifImage.widthAnchor.constraint(equalTo: gifImage.heightAnchor),
            
            timestampLbl.topAnchor.constraint(equalTo: topAnchor, constant: AppDelegate.screenHeight / 300),
            timestampLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppDelegate.screenWidth / 20)
        ])
    }
}

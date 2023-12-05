//
//  FriendCell.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 21.02.23.
//

import UIKit

class FriendCell: UITableViewCell {
    
    static let identifier = "FriendCell"
    lazy var profileImg = UIImageView()
    lazy var usernameLbl = UILabel()
    lazy var requestStackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        layout()
        self.style()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImg.layer.cornerRadius                = profileImg.frame.size.width / 2
        profileImg.clipsToBounds                     = true
    }
    
    private func addSubviews() {
        addSubview(requestStackView)
        requestStackView.addArrangedSubview(profileImg)
        requestStackView.addArrangedSubview(usernameLbl)
    }
    
    private func style() {
        requestStackView.translatesAutoresizingMaskIntoConstraints = false
        requestStackView.spacing = 20
        requestStackView.axis = .horizontal
        requestStackView.alignment = .center
        
        profileImg.translatesAutoresizingMaskIntoConstraints = false
        profileImg.image = UIImage(systemName: "person.circle.fill")
        profileImg.tintColor                         = .label
        profileImg.contentMode = .scaleAspectFill
        profileImg.clipsToBounds                     = true
        profileImg.layoutIfNeeded()
        
        usernameLbl.translatesAutoresizingMaskIntoConstraints = false
        usernameLbl.numberOfLines                             = 0
        usernameLbl.adjustsFontSizeToFitWidth                 = true
        usernameLbl.tintColor                                 = .label
        usernameLbl.font = UIFont(name: "HelveticaNeue-Thin", size: (AppDelegate.screenHeight / AppDelegate.screenWidth) * 8)
    }
    
    private func layout() {
        NSLayoutConstraint.activate([
            requestStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            requestStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            profileImg.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImg.topAnchor.constraint(equalTo: topAnchor, constant: AppDelegate.screenHeight / 100),
            profileImg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(AppDelegate.screenHeight / 100)),
            profileImg.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            profileImg.widthAnchor.constraint(equalTo: profileImg.heightAnchor),
            usernameLbl.centerYAnchor.constraint(equalTo: centerYAnchor),
            usernameLbl.leadingAnchor.constraint(equalTo: usernameLbl.trailingAnchor, constant: 20),
            usernameLbl.heightAnchor.constraint(equalToConstant: 80),
            usernameLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }
    

}

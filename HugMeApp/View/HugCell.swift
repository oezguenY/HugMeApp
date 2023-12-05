//
//  HomefeedCell.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 25.01.23.
//

import UIKit

class HugCell: UITableViewCell {

    static let identifier = "HugCell"
    let hugLbl = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        setUpConstraints()
        styleUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        addSubview(hugLbl)
    }
    
    private func styleUI() {
        hugLbl.translatesAutoresizingMaskIntoConstraints = false
        hugLbl.numberOfLines = 0
        hugLbl.lineBreakMode = .byWordWrapping
        hugLbl.textColor = .black
        hugLbl.font = UIFont.systemFont(ofSize: (AppDelegate.screenWidth + AppDelegate.screenHeight) / 1000 * 12)
    }

    
    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            hugLbl.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
            hugLbl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: AppDelegate.screenWidth / 20),
            hugLbl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -1 * (AppDelegate.screenWidth / 20))
        ])
    }
    
    
    

}

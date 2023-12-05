//
//  GifCollectionViewCell.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 04.08.23.
//

import UIKit

class GIFCell: UICollectionViewCell {
    let gifImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(gifImageView)
        gifImageView.translatesAutoresizingMaskIntoConstraints = false
        gifImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        gifImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        gifImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        gifImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        gifImageView.layer.cornerRadius = 20
        gifImageView.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init coder has not been implemented")
    }
    
    override var isSelected: Bool {
            didSet {
                // Update cell appearance when the selection changes
                if isSelected {
                    animateSelectionEffects()
                } else {
                    layer.removeAllAnimations() // Remove any existing animations
                    layer.borderWidth = 0
                    contentView.backgroundColor = .clear
                    transform = .identity
                }
            }
        }
    
    private func animateSelectionEffects() {
            // Add the border and set its initial properties
            layer.borderWidth = 2
            layer.borderColor = UIColor.orange.cgColor
            
            // Animate the background color to give a flash effect
            UIView.animate(withDuration: 0.2, animations: {
                self.contentView.backgroundColor = UIColor.orange.withAlphaComponent(0.2)
            }, completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.contentView.backgroundColor = .clear
                }
            })
            
            // Apply scaling animation to the cell to make it visually stimulating
            let scaleAnimation = CASpringAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = 1.2
            scaleAnimation.duration = 0.2
            scaleAnimation.repeatCount = 1
            scaleAnimation.initialVelocity = 5.0
            scaleAnimation.damping = 0.8
            layer.add(scaleAnimation, forKey: "scaleAnimation")
        }
    
}


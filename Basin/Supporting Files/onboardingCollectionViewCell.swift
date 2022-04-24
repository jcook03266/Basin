//
//  onboardingCollectionViewCell.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/5/22.
//

import UIKit

/** Simple Collection View Cell class that handles adding content to the content view and basic garbage disposal*/
class onboardingCollectionViewCell: UICollectionViewCell{
    static let identifier = "onboardingCollectionViewCell"
    weak var containedView: UIView? = nil
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    
    func setUp(with view: UIView){
        self.isExclusiveTouch = true
        self.containedView = view
        contentView.addSubview(containedView!)
    }
        
    override func prepareForReuse(){
        super.prepareForReuse()
        
        containedView!.removeFromSuperview()
        containedView = nil
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


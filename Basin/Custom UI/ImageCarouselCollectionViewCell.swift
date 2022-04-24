//
//  ImageCarouselCollectionViewCell.swift
//  Inspec
//
//  Created by Justin Cook on 1/6/22.
//

import UIKit

/** Simple Collection View Cell class that handles adding content to the content view and basic garbage disposal*/
class ImageCarouselCollectionViewCell: UICollectionViewCell{
    static let identifier = "ImageCarouselCollectionViewCell"
    weak var imageViewContainer: UIView? = nil
    weak var containedImageView: UIImageView? = nil
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    
    func setUp(with view: UIView, containedImageView: UIImageView){
        self.imageViewContainer = view
        self.containedImageView = containedImageView
        contentView.addSubview(imageViewContainer!)
    }
        
    override func prepareForReuse(){
        super.prepareForReuse()
        
        imageViewContainer = nil
        
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

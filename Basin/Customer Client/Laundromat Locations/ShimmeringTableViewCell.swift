//
//  ShimmeringTableViewCell.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 4/6/22.
//
import UIKit
import SkeletonView

/** Tableview cell that acts as a place holder for other tableview cells once the data for those cells has been fully downloaded and parsed*/
class ShimmeringTableViewCell: UITableViewCell {
    static let identifier = "ShimmeringTableViewCell"
    /** The color of the shimmer animation*/
    var shimmerColor: UIColor!
    /** The duration of the shimmer animation*/
    var duration: CGFloat!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: ShimmeringTableViewCell.identifier)
    }
    
    func create(with shimmerColor: UIColor, duration: CGFloat){
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.clipsToBounds = true
        self.shimmerColor = shimmerColor
        self.duration = duration
        
        let placeholderImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.24, height: self.frame.width * 0.24))
        placeholderImageView.backgroundColor = .clear
        placeholderImageView.layer.cornerRadius = placeholderImageView.frame.height/4
        placeholderImageView.clipsToBounds = true
        placeholderImageView.isSkeletonable = true
        
        let placeholderNameLabel = UILabel()
        placeholderNameLabel.frame.size = CGSize(width: (self.frame.width * 0.7), height: self.frame.height * 0.25)
        placeholderNameLabel.backgroundColor = .clear
        
        placeholderNameLabel.clipsToBounds = true
        placeholderNameLabel.isSkeletonable = true
        
        let placeholderPriceLabel = UILabel()
        placeholderPriceLabel.frame.size = CGSize(width: ((self.frame.width * 0.7)/2), height: self.frame.height * 0.25)
        placeholderPriceLabel.backgroundColor = .clear
        
        placeholderPriceLabel.clipsToBounds = true
        placeholderPriceLabel.isSkeletonable = true
        
        let placeholderDescriptionLabel = UILabel()
        placeholderDescriptionLabel.frame.size = CGSize(width: ((self.frame.width * 0.7)/1.5), height: self.frame.height * 0.3)
        placeholderDescriptionLabel.backgroundColor = .clear
        
        placeholderDescriptionLabel.clipsToBounds = true
        placeholderDescriptionLabel.isSkeletonable = true
        
        let placeholderAddButton = UIButton()
        placeholderAddButton.frame.size = CGSize(width: self.frame.width * 0.075, height: self.frame.width * 0.075)
        placeholderAddButton.isEnabled = false
        placeholderAddButton.isUserInteractionEnabled = false
        placeholderAddButton.backgroundColor = .clear
        
        placeholderAddButton.layer.cornerRadius = placeholderAddButton.frame.height/2
        placeholderAddButton.clipsToBounds = true
        placeholderAddButton.isSkeletonable = true
        
        /** Add shimmering animations*/
        let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight)
        let animation2 = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .topLeftBottomRight)
        let gradient = SkeletonGradient(baseColor: shimmerColor)
        
        /** Add place holder animations*/
        placeholderNameLabel.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
        placeholderPriceLabel.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
        placeholderDescriptionLabel.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
        
        placeholderAddButton.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation2)
        placeholderImageView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation2)
        
        /** Position and add the subviews*/
        placeholderNameLabel.frame.origin = CGPoint(x: self.frame.width * 0.05, y: self.frame.height/4 - placeholderNameLabel.frame.height/2)
        
        placeholderPriceLabel.frame.origin = CGPoint(x: self.frame.width * 0.05, y: placeholderNameLabel.frame.maxY + self.frame.height * 0.05)
        
        placeholderImageView.frame.origin = CGPoint(x: self.frame.maxX - (placeholderImageView.frame.width * 1.1), y: self.frame.height/2 - placeholderImageView.frame.height/2)
        
        placeholderAddButton.frame.origin = CGPoint(x: placeholderImageView.frame.minX - placeholderImageView.frame.width/10, y: placeholderImageView.frame.maxY - (placeholderAddButton.frame.height * 1.1))
        
        placeholderDescriptionLabel.frame.origin = CGPoint(x: self.frame.width * 0.05, y: placeholderPriceLabel.frame.maxY + self.frame.height * 0.05)

        self.contentView.addSubview(placeholderImageView)
        self.contentView.addSubview(placeholderNameLabel)
        self.contentView.addSubview(placeholderPriceLabel)
        self.contentView.addSubview(placeholderDescriptionLabel)
        self.contentView.addSubview(placeholderAddButton)
    }
    
    /** Various garbage collection procedures*/
    override func prepareForReuse(){
        super.prepareForReuse()
        
        shimmerColor = nil
        duration = nil
  
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

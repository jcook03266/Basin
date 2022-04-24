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
    /** The view that will be shimmering*/
    var shimmeringView: UIView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: ShimmeringTableViewCell.identifier)
    }
    
    func create(with shimmerColor: UIColor, duration: CGFloat){
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.clipsToBounds = true
        self.shimmerColor = shimmerColor
        self.duration = duration
        
        shimmeringView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.925, height: self.frame.height * 0.9))
        shimmeringView.backgroundColor = .clear
        shimmeringView.layer.cornerRadius = shimmeringView.frame.height/5
        shimmeringView.clipsToBounds = true
        shimmeringView.isSkeletonable = true
        
        let iconImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: shimmeringView.frame.width * 0.24, height: shimmeringView.frame.width * 0.24))
        iconImageView.backgroundColor = .clear
        iconImageView.layer.cornerRadius = iconImageView.frame.height/5
        iconImageView.clipsToBounds = true
        iconImageView.isSkeletonable = true
        
        /** Add shimmering animations*/
        let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight)
        let animation2 = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .topLeftBottomRight)
        let gradient = SkeletonGradient(baseColor: shimmerColor)
        
        shimmeringView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
        iconImageView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation2)
        
        /** Position and add the subviews*/
        shimmeringView.frame.origin = CGPoint(x: self.frame.width/2 - shimmeringView.frame.width/2, y: self.frame.height/2 - shimmeringView.frame.height/2)
        
        iconImageView.frame.origin = CGPoint(x: shimmeringView.frame.maxX - (iconImageView.frame.width * 1.1), y: self.frame.height/2 - iconImageView.frame.height/2)

        self.contentView.addSubview(shimmeringView)
        self.contentView.addSubview(iconImageView)
    }
    
    /** Various garbage collection procedures*/
    override func prepareForReuse(){
        super.prepareForReuse()
        
        shimmerColor = nil
        duration = nil
        shimmeringView = nil
  
        for subview in contentView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

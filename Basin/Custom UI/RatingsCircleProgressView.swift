//
//  RatingsCircleProgressView.swift
//  Inspec
//
//  Created by user211592 on 1/10/22.
//
import UIKit

/** View with a circle shape layer inside that's filled to a certain percentage and contains a UILabel inside to display any given text*/
class RatingsCircleProgressView: UIView{
    var layerBackgroundColor: UIColor
    var completionPercentage: CGFloat
    var trackColor: UIColor
    var fillColor: UIColor
    var useGradientColor: Bool
    var centerLabelText: String?
    var centerLabelSubtitleText: String?
    var centerLabelSecondarySubtitleText: String?
    var centerLabelFontColor: UIColor?
    var centerLabelSubtitleFontColor: UIColor?
    var centerLabelSecondarySubtitleFontColor: UIColor?
    var centerLabelFontSize: CGFloat?
    var centerLabelSubtitleFontSize: CGFloat?
    var centerLabelSecondarySubtitleFontSize: CGFloat?
    var displayCenterLabel: Bool
    var displayCenterLabelSubtitle: Bool
    var displayCenterLabelSecondarySubtitle: Bool
    
    /** Properties only usable by this class*/
    private var centerLabel = UILabel()
    private var centerLabelSubtitle = UILabel()
    private var centerLabelSecondarySubtitle = UILabel()
    private var circleLayer = CAShapeLayer()
    private var progressLayer = CAShapeLayer()
    /**Start the path from 90 degrees counter clockwise**/
    private var startPoint = CGFloat(-Double.pi / 2)
    /**Move the path 270 degrees clockwise*/
    private var endPoint = CGFloat(3 * Double.pi / 2)
    private var gradientColorSet = [UIColor.gray,UIColor.red,UIColor.orange,UIColor.systemYellow,appThemeColor]
    private var gradientColorSetCG = [UIColor.gray.cgColor,UIColor.red.cgColor,UIColor.orange.cgColor,UIColor.systemYellow.cgColor,appThemeColor.cgColor]
    
    init(frame: CGRect, layerBackgroundColor: UIColor, completionPercentage: CGFloat, trackColor: UIColor, fillColor: UIColor, useGradientColor: Bool, centerLabelText: String?, centerLabelSubtitleText: String?, centerLabelSecondarySubtitleText: String?, centerLabelFontColor: UIColor?, centerLabelSubtitleFontColor: UIColor?, centerLabelSecondarySubtitleFontColor: UIColor?, centerLabelFontSize: CGFloat?, centerLabelSubtitleFontSize: CGFloat?, centerLabelSecondarySubtitleFontSize: CGFloat?, displayCenterLabel: Bool, displayCenterLabelSubtitle: Bool, displayCenterLabelSecondarySubtitle: Bool){
        self.layerBackgroundColor = layerBackgroundColor
        self.completionPercentage = completionPercentage
        self.trackColor = trackColor
        self.fillColor = fillColor
        self.useGradientColor = useGradientColor
        self.centerLabelText = centerLabelText
        self.centerLabelSubtitleText = centerLabelSubtitleText
        self.centerLabelSecondarySubtitleText = centerLabelSecondarySubtitleText
        self.centerLabelFontColor = centerLabelFontColor
        self.centerLabelSubtitleFontColor = centerLabelSubtitleFontColor
        self.centerLabelSecondarySubtitleFontColor = centerLabelSecondarySubtitleFontColor
        self.centerLabelFontSize = centerLabelFontSize
        self.centerLabelSubtitleFontSize = centerLabelSubtitleFontSize
        self.centerLabelSecondarySubtitleFontSize = centerLabelSecondarySubtitleFontSize
        self.displayCenterLabel = displayCenterLabel
        self.displayCenterLabelSubtitle = displayCenterLabelSubtitle
        self.displayCenterLabelSecondarySubtitle = displayCenterLabelSecondarySubtitle
        
        super.init(frame: frame)
        
        /** If any of these properties for the labels aren't provided then don't display the label*/
        if centerLabelSecondarySubtitleText == nil || centerLabelSecondarySubtitleFontSize == nil || centerLabelSecondarySubtitleFontColor == nil || displayCenterLabelSubtitle == false{
            self.displayCenterLabelSubtitle = false
        }
        if centerLabelSubtitleText == nil || centerLabelSubtitleFontSize == nil || centerLabelSubtitleFontColor == nil || displayCenterLabel == false{
            self.displayCenterLabelSubtitle = false
        }
        if centerLabelText == nil || centerLabelFontSize == nil || centerLabelFontColor == nil{
            self.displayCenterLabel = false
        }
        
        /** The completion percentage is a percentage hence its from 0% - 100% 0 - 1, anything higher should be divided by 100*/
        if self.completionPercentage > 1{
            self.completionPercentage = self.completionPercentage/100
        }

        createCircularPath()
    }
    
    /** Create bezier paths and shape layers for the circle and progress views*/
    private func createCircularPath() {
        /** Bezier path for the circle specified for the progress and interior layers*/
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: (frame.size.width / 2.0), startAngle: startPoint, endAngle: endPoint, clockwise: true)
        
        /** Circle inside of the progress bar*/
        circleLayer.path = circularPath.cgPath
        circleLayer.fillColor = layerBackgroundColor.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineWidth = 5.0
        circleLayer.strokeEnd = 1.0
        circleLayer.strokeColor = trackColor.cgColor
        
        layer.addSublayer(circleLayer)
        
        /**Circular progress bar*/
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = 5.0
        progressLayer.strokeEnd = 0
        progressLayer.strokeColor = fillColor.cgColor
        
        if useGradientColor == true{
        progressLayer.strokeColor = gradientColorSetCG[0]
        }
        
        layer.addSublayer(progressLayer)
        
        /** Label that displays given text*/
        if displayCenterLabel == true{
            centerLabel = UILabel(frame: CGRect(x: self.frame.width/2 - (self.frame.width * 0.8)/2, y: self.frame.height/2 - (self.frame.height/2)/2 , width: self.frame.width * 0.8, height: self.frame.height/2))
            centerLabel.text = centerLabelText
            centerLabel.backgroundColor = UIColor.clear
            centerLabel.isUserInteractionEnabled = false
            centerLabel.adjustsFontSizeToFitWidth = true
            centerLabel.adjustsFontForContentSizeCategory = true
            centerLabel.clipsToBounds = true
            centerLabel.textAlignment = .center
            centerLabel.font = getCustomFont(name: .Ubuntu_Regular, size: centerLabelFontSize!, dynamicSize: true)
            centerLabel.textColor = centerLabelFontColor
            centerLabel.frame.size.height = centerLabel.intrinsicContentSize.height
            
            if useGradientColor == true{
                centerLabel.textColor = getGradientColor()
            }
            
            self.addSubview(centerLabel)
        }
        
        if displayCenterLabelSubtitle == true && displayCenterLabel == true{
            centerLabelSubtitle = UILabel(frame: CGRect(x: self.frame.width/2 - (self.frame.width * 0.75)/2, y: self.centerLabel.frame.maxY, width: self.frame.width * 0.75, height: self.frame.height/2))
            centerLabelSubtitle.text = centerLabelSubtitleText
            centerLabelSubtitle.backgroundColor = UIColor.clear
            centerLabelSubtitle.isUserInteractionEnabled = false
            centerLabelSubtitle.adjustsFontSizeToFitWidth = true
            centerLabelSubtitle.adjustsFontForContentSizeCategory = true
            centerLabelSubtitle.clipsToBounds = true
            centerLabelSubtitle.textAlignment = .center
            centerLabelSubtitle.font = getCustomFont(name: .Ubuntu_Regular, size: centerLabelSubtitleFontSize!, dynamicSize: true)
            centerLabelSubtitle.textColor = centerLabelSubtitleFontColor
            centerLabelSubtitle.frame.size.height = centerLabelSubtitle.intrinsicContentSize.height
            
            self.addSubview(centerLabelSubtitle)
        }
        
        if displayCenterLabelSubtitle == true && displayCenterLabel == true && displayCenterLabelSecondarySubtitle == true{
            centerLabelSecondarySubtitle = UILabel(frame: CGRect(x: self.frame.width/2 - (self.frame.width * 0.7)/2, y: self.centerLabelSubtitle.frame.maxY, width: self.frame.width * 0.65, height: self.frame.height/2))
            centerLabelSecondarySubtitle.text = centerLabelSecondarySubtitleText
            centerLabelSecondarySubtitle.backgroundColor = UIColor.clear
            centerLabelSecondarySubtitle.isUserInteractionEnabled = false
            centerLabelSecondarySubtitle.adjustsFontSizeToFitWidth = true
            centerLabelSecondarySubtitle.adjustsFontForContentSizeCategory = true
            centerLabelSecondarySubtitle.clipsToBounds = true
            centerLabelSecondarySubtitle.textAlignment = .center
            centerLabelSecondarySubtitle.font = getCustomFont(name: .Ubuntu_Regular, size: centerLabelSecondarySubtitleFontSize!, dynamicSize: true)
            centerLabelSecondarySubtitle.textColor = centerLabelSecondarySubtitleFontColor
            centerLabelSecondarySubtitle.frame.size.height = centerLabelSecondarySubtitle.intrinsicContentSize.height
            
            self.addSubview(centerLabelSecondarySubtitle)
        }
    }
    
    /** Return color based on the completion percentage provided*/
    func getGradientColor()->UIColor{
        var color = gradientColorSet[0]
        
        if completionPercentage == 0{
            color = gradientColorSet[0]
            /**No Rating or Very Low Rating**/
        }
        else if completionPercentage > 0 && completionPercentage <= 0.25{
            color = gradientColorSet[1]
            /**Low Rating**/
        }
        else if completionPercentage > 0.25 && completionPercentage <= 0.50{
            color = gradientColorSet[2]
            /**Medium Rating**/
        }
        else if completionPercentage > 0.50 && completionPercentage <= 0.75{
            color = gradientColorSet[3]
            /**High Rating**/
        }
        else if completionPercentage > 0.75 && completionPercentage <= 1{
            color = gradientColorSet[4]
            /**Very High Rating**/
        }
        return color
    }
    
    /** Animate the progress bar goi*/
    func progressAnimation(duration: TimeInterval) {
        let circularProgressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        circularProgressAnimation.duration = duration
        circularProgressAnimation.toValue = completionPercentage
        circularProgressAnimation.fillMode = .forwards
        circularProgressAnimation.isRemovedOnCompletion = false
        
        progressLayer.add(circularProgressAnimation, forKey: "progressAnimation")
        
        if useGradientColor == true{
        if completionPercentage > 0 && completionPercentage <= 0.25{
            DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            let colorAnimation1 = CABasicAnimation(keyPath: "strokeColor")
            colorAnimation1.duration = duration/4
            colorAnimation1.fromValue = gradientColorSetCG[0]
            colorAnimation1.toValue = gradientColorSetCG[1]
            colorAnimation1.fillMode = .forwards
            colorAnimation1.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation1, forKey: "colorAnimation1")
            }
            /**Low Rating**/
        }
        else if completionPercentage > 0.25 && completionPercentage <= 0.50{
            DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            let colorAnimation1 = CABasicAnimation(keyPath: "strokeColor")
            colorAnimation1.duration = duration/4
            colorAnimation1.fromValue = gradientColorSetCG[0]
            colorAnimation1.toValue = gradientColorSetCG[1]
            colorAnimation1.fillMode = .forwards
            colorAnimation1.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation1, forKey: "colorAnimation1")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/4){[self] in
            let colorAnimation2 = CABasicAnimation(keyPath: "strokeColor")
                colorAnimation2.duration = duration/4
                colorAnimation2.fromValue = gradientColorSetCG[1]
                colorAnimation2.toValue = gradientColorSetCG[2]
                colorAnimation2.fillMode = .forwards
                colorAnimation2.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation2, forKey: "colorAnimation2")
            }
            /**Medium Rating**/
        }
        else if completionPercentage > 0.50 && completionPercentage <= 0.75{
            DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            let colorAnimation1 = CABasicAnimation(keyPath: "strokeColor")
            colorAnimation1.duration = duration/4
            colorAnimation1.fromValue = gradientColorSetCG[0]
            colorAnimation1.toValue = gradientColorSetCG[1]
            colorAnimation1.fillMode = .forwards
            colorAnimation1.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation1, forKey: "colorAnimation1")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/4){[self] in
            let colorAnimation2 = CABasicAnimation(keyPath: "strokeColor")
                colorAnimation2.duration = duration/4
                colorAnimation2.fromValue = gradientColorSetCG[1]
                colorAnimation2.toValue = gradientColorSetCG[2]
                colorAnimation2.fillMode = .forwards
                colorAnimation2.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation2, forKey: "colorAnimation2")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/3){[self] in
            let colorAnimation3 = CABasicAnimation(keyPath: "strokeColor")
                colorAnimation3.duration = duration/4
                colorAnimation3.fromValue = gradientColorSetCG[2]
                colorAnimation3.toValue = gradientColorSetCG[3]
                colorAnimation3.fillMode = .forwards
                colorAnimation3.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation3, forKey: "colorAnimation3")
            }
            /**High Rating**/
        }
        else if completionPercentage > 0.75 && completionPercentage <= 1{
            DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            let colorAnimation1 = CABasicAnimation(keyPath: "strokeColor")
            colorAnimation1.duration = duration/4
            colorAnimation1.fromValue = gradientColorSetCG[0]
            colorAnimation1.toValue = gradientColorSetCG[1]
            colorAnimation1.fillMode = .forwards
            colorAnimation1.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation1, forKey: "colorAnimation1")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/4){[self] in
            let colorAnimation2 = CABasicAnimation(keyPath: "strokeColor")
                colorAnimation2.duration = duration/4
                colorAnimation2.fromValue = gradientColorSetCG[1]
                colorAnimation2.toValue = gradientColorSetCG[2]
                colorAnimation2.fillMode = .forwards
                colorAnimation2.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation2, forKey: "colorAnimation2")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/3){[self] in
            let colorAnimation3 = CABasicAnimation(keyPath: "strokeColor")
                colorAnimation3.duration = duration/4
                colorAnimation3.fromValue = gradientColorSetCG[2]
                colorAnimation3.toValue = gradientColorSetCG[3]
                colorAnimation3.fillMode = .forwards
                colorAnimation3.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation3, forKey: "colorAnimation3")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration/2){[self] in
            let colorAnimation4 = CABasicAnimation(keyPath: "strokeColor")
                colorAnimation4.duration = duration
                colorAnimation4.fromValue = gradientColorSetCG[3]
                colorAnimation4.toValue = gradientColorSetCG[4]
                colorAnimation4.fillMode = .forwards
                colorAnimation4.isRemovedOnCompletion = false
                
            progressLayer.add(colorAnimation4, forKey: "colorAnimation4")
            }
            /**Very High Rating**/
        }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

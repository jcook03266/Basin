//
//  CustomAlertVC.swift
//  Basin
//
//  Created by Justin Cook on 5/18/22.
//

import UIKit

/** Various classes depicting custom alert view controllers made to fit the feel of this application*/

/** Custom Alert View Controller*/
public class JCAlertController: UIViewController{
    /** Customizable properties*/
    /** The background color to display behind all content*/
    var contextBackgroundColor: UIColor = .black.withAlphaComponent(0.25)
    /** Accent color to be displayed as the tint color for the controller's content*/
    var accentColor: UIColor = .systemBlue
    /** The background color of the view controller's subviews*/
    var bodyColor: UIColor = bgColor
    /** The corner radius of the main content containers and the bottom button*/
    var bodyCornerRadius: CGFloat = 20
    /** Border width for main content containers and bottom button*/
    var bodyBorderWidth: CGFloat = 1
    /** The font to use for this view controller*/
    var font: UIFont = getCustomFont(name: .Ubuntu_Medium, size: 16, dynamicSize: true)
    /** The color of the various borders in the subviews*/
    var borderColor: CGColor = darkMode ? UIColor.darkGray.cgColor : UIColor.lightGray.cgColor
    /** The alpha value of the visible containers in this view controller*/
    var alpha: CGFloat = 1
    /** Border width for all buttons*/
    var buttonBorderWidth: CGFloat = 0.25
    /** Background color for the headerview*/
    var headerViewBackgroundColor: UIColor = bgColor
    /** Font color for the header view's subviews*/
    var headerViewFontColor: UIColor = fontColor
    /** The font to use for the title*/
    var titleFont: UIFont = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
    /** The font to use for the message below the title*/
    var messageFont: UIFont = getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true)
    var messageTextAlignment: NSTextAlignment = .center
    var titleTextAlignment: NSTextAlignment = .center
    /** Customize the bottom button's appearance*/
    var bottomButtonFontColor: UIColor = fontColor
    var bottomButtonBackgroundColor: UIColor = bgColor
    
    /** Data to display*/
    /** (Optional) Title of this alert*/
    var alertTitle: String?
    /** (Optional)  Message to convery to the user below the title*/
    var message: String?
    /** The style of this alert*/
    var preferredStyle: UIAlertController.Style!
    /** The (optional) image to display above the message*/
    var image: UIImage? = nil
    
    /** Determine whether or not an image should be displayed by this alert view controller*/
    private var displaysImage: Bool = false
    
    /** UI Elements*/
    /** Alert UI*/
    private var alertContainer: UIView!
    
    /** Action Sheet UI*/
    private var actionSheetContainer: UIView!
    /** The button to display below the container*/
    private var bottomButton: UIButton!
    
    /** Shared UI*/
    /** Dynamic content height requires a scrollview*/
    /** Stackview that will contain a vertical collection of all button and textfield subviews if their quantity exceeds 2*/
    private var elementStackView: UIStackView!
    /** The scrollView isn't used when there's less than 3 buttons (actions)*/
    private var scrollView: UIScrollView!
    /** Background image view in which the user can tap in order to dismiss the view controller*/
    private var dismissableArea: UIVisualEffectView!
    /** Container for the title and message*/
    private var headerView: UIView!
    private var titleLabel: UILabel!
    private var messageLabel : UILabel!
    private var imageView: UIImageView? = nil
    /** Buttons attached to the given UIAlertActions*/
    private var buttons: [UIButton] = []
    ///private var textFields: [String : UITextField] = [:]
    
    /** UI Sizing constants*/
    /** The default height for the buttons displayed by the alert*/
    private var buttonHeight: CGFloat = 60
    private var headerViewDefaultHeight: CGFloat{
        return preferredStyle == .alert ? 95 : 75
    }
    private var defaultActionSheetContainerHeight: CGFloat {
        return self.view.frame.height * 0.4
    }
    private var defaultAlertContainerHeight: CGFloat {
        return self.view.frame.height * 0.25
    }
    private var defaultActionSheetContainerWidth: CGFloat {
        return self.view.frame.width * 0.9
    }
    private var defaultAlertContainerWidth: CGFloat {
        return self.view.frame.width * 0.75
    }
    
    /** Maximum allowed sizes for the different styles*/
    private var maximumAlertContainerHeight: CGFloat {
        return (self.view.frame.height * 0.9)
    }
    private var maximumActionSheetContainerHeight: CGFloat {
        return ((self.view.frame.height * 0.9) - (10 + (buttonHeight * 1.5)))
    }
    
    /** UI Actions map with alert action styles to specify the look of the button*/
    private var actions: [UIAction : UIAlertAction.Style] = [:]
    /** An ordered array of actions*/
    private var orderedActions: [UIAction] = []
    /** The preferred alert style type action (bolds the font of the corresponding button) (not used for action sheets)*/
    var preferredAction: UIAction? = nil
    
    /** ImageView Customizable properties (only takes effect if an image is provided)*/
    var imageViewBorderColor: CGColor = UIColor.clear.cgColor
    var imageViewBorderWidth: CGFloat = 0
    var imageViewBackgroundColor: UIColor = .clear
    var imageViewCornerRadius: CGFloat = 0
    var imageViewTintColor: UIColor = .systemBlue
    
    /** Extra functionality*/
    /** Determine whether or not to use a custom animation on the VC's subviews when the view controller is being dismissed by a user-initiatied action*/
    var useDismissAnimation: Bool = true
    /** Determine whether or not to animate the view controller's subviews when the view controller loads*/
    var useAppearAnimation: Bool = true
    /** Determine whether or not to display this alert with a blurred background*/
    var useBlurEffect: Bool = false
    /** Tap to dismiss functionality*/
    private var tapGestureRecognizer: UITapGestureRecognizer!
    /** Decide whether or not the user can tap outside of the main content in order to dismiss the view controller*/
    var tapOutSideToDismiss: Bool = true
    
    /** Note: I might add functionality for textfields to be added and easily accessed via a naming system, but not right now*/
    
    /** Specify the content of this alert and the preferred style of the controller*/
    init(title: String, message: String, preferredStyle: UIAlertController.Style) {
        self.alertTitle = title
        self.message = message
        self.preferredStyle = preferredStyle
        
        super.init(nibName: nil, bundle: nil)
    }
    
    /** Specify the content of this alert, including an image if desired, and the preferred style of the controller*/
    init(title: String, message: String, image: UIImage, preferredStyle: UIAlertController.Style) {
        self.alertTitle = title
        self.message = message
        self.preferredStyle = preferredStyle
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        /** Specify a maximum font size*/
        self.view.maximumContentSizeCategory = .large
        
        construct()
    }
    
    /** Change the background color of the dismissable area in an animated fashion*/
    func dimContext(){
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseIn]){[self] in
            dismissableArea.backgroundColor = contextBackgroundColor
        }
    }
    
    /** Reverse the dimming effect*/
    func undimContext(){
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn]){[self] in
            dismissableArea.backgroundColor = .clear
        }
    }
    
    /** Piece together all of the provided data to construct the UI for this VC*/
    func construct(){
        self.view.backgroundColor = .clear
        
        /** Tap to dismiss area*/
        dismissableArea = UIVisualEffectView(frame: self.view.frame)
        dismissableArea.effect = useBlurEffect ? UIBlurEffect(style: darkMode ? .dark : .light) : nil
        dismissableArea.backgroundColor = .clear
        dismissableArea.clipsToBounds = true
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerTriggered))
        tapGestureRecognizer.requiresExclusiveTouchType = true
        tapGestureRecognizer.numberOfTouchesRequired = 1
        
        dismissableArea.addGestureRecognizer(tapGestureRecognizer)
        /** Tap to dismiss area*/
        
        /** Action Sheet main content view*/
        actionSheetContainer = UIView(frame: CGRect(x: 0, y: 0, width: defaultActionSheetContainerWidth, height: defaultActionSheetContainerHeight))
        actionSheetContainer.backgroundColor = bodyColor.withAlphaComponent(alpha)
        actionSheetContainer.tintColor = accentColor
        actionSheetContainer.clipsToBounds = true
        actionSheetContainer.layer.cornerRadius = bodyCornerRadius
        actionSheetContainer.layer.borderColor = borderColor
        actionSheetContainer.layer.borderWidth = bodyBorderWidth
        /** Action Sheet main content view*/
        
        /** Alert Main content view*/
        alertContainer = UIView(frame: CGRect(x: 0, y: 0, width: defaultAlertContainerWidth, height: defaultAlertContainerHeight))
        alertContainer.backgroundColor = bodyColor.withAlphaComponent(alpha)
        alertContainer.tintColor = accentColor
        alertContainer.clipsToBounds = true
        alertContainer.layer.cornerRadius = bodyCornerRadius
        alertContainer.layer.borderColor = borderColor
        alertContainer.layer.borderWidth = bodyBorderWidth
        /** Alert Main content view*/
        
        buttons = createButtons(using: actions)
        
        /** Header container*/
        headerView = UIView(frame: CGRect(x: 0, y: 0, width: preferredStyle == .alert ? defaultAlertContainerWidth : defaultActionSheetContainerWidth, height: headerViewDefaultHeight + 10))
        headerView.backgroundColor = headerViewBackgroundColor.withAlphaComponent(alpha)
        headerView.clipsToBounds = true
        
        /** Title*/
        titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: headerView.frame.width * 0.9, height: headerViewDefaultHeight/3 - (preferredStyle == .alert ? 15 : 10)))
        titleLabel.font = titleFont
        titleLabel.textColor = headerViewFontColor
        titleLabel.tintColor = accentColor
        titleLabel.clipsToBounds = true
        titleLabel.numberOfLines = 3
        titleLabel.lineBreakMode = .byClipping
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = titleTextAlignment
        titleLabel.text = alertTitle
        titleLabel.sizeToFit()
        /** Title*/
        
        /** ImageView*/
        if image != nil{
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: (headerViewDefaultHeight/3 - (preferredStyle == .alert ? 5 : 5)), height: (headerViewDefaultHeight/3 - (preferredStyle == .alert ? 5 : 5))))
            imageView!.image = image
            imageView!.tintColor = imageViewTintColor
            imageView!.contentMode = .scaleAspectFit
            imageView!.layer.borderColor = imageViewBorderColor
            imageView!.layer.borderWidth = imageViewBorderWidth
            imageView!.backgroundColor = imageViewBackgroundColor
            imageView!.layer.cornerRadius = imageViewCornerRadius
            imageView!.clipsToBounds = true
        }
        /** ImageView*/
        
        /** Message*/
        messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: headerView.frame.width * 0.9, height: (headerViewDefaultHeight/3 - (preferredStyle == .alert ? 5 : 10))))
        messageLabel.font = messageFont
        messageLabel.textColor = headerViewFontColor
        messageLabel.tintColor = accentColor
        messageLabel.clipsToBounds = true
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.numberOfLines = 3
        messageLabel.lineBreakMode = .byClipping
        messageLabel.textAlignment = messageTextAlignment
        messageLabel.text = message
        messageLabel.sizeToFit()
        /** Message*/
        /** Header container*/
        
        /** Dynamic content container*/
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: headerView.frame.width, height: preferredStyle == .alert ? (alertContainer.frame.height - headerView.frame.height) : (actionSheetContainer.frame.height - headerView.frame.height)))
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .clear
        scrollView.indicatorStyle =  darkMode ? .white : .black
        
        elementStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: scrollView.frame.height))
        if actions.count <= 2 && preferredStyle == .alert{
            /** Horizontal stackview with two side by side buttons*/
            elementStackView.frame.size.height = buttonHeight
            elementStackView.axis = .horizontal
        }
        else if actions.count > 2 && preferredStyle == .alert || actions.count >= 1 && preferredStyle == .actionSheet{
            /** Vertical stackview*/
            elementStackView.axis = .vertical
        }
        elementStackView.backgroundColor = .clear
        elementStackView.alignment = .fill
        elementStackView.distribution = .fillEqually
        elementStackView.spacing = 0
        
        /** Add all buttons except the bottom button to the stackview*/
        for button in buttons{
        if button != bottomButton{
        elementStackView.addArrangedSubview(button)
        }
        }
        /** Dynamic content container*/
        
        resize()
        
        /** Layout these subviews*/
        self.view.addSubview(dismissableArea)
        
        /** Laying out subviews for optional data*/
        if alertTitle != ""{
            headerView.addSubview(titleLabel)
            
            /** Increase height if only two elements are in the header*/
            if message != nil && image == nil || message == nil && image != nil{
                titleLabel.frame.size.height = headerViewDefaultHeight * 0.4
                titleLabel.sizeToFit()
            }
            
            titleLabel.frame.origin = CGPoint(x: headerView.frame.width/2 - titleLabel.frame.width/2, y: preferredStyle == .alert ? 15 : 10)
            
            /** Center if its the only element in the header*/
            if message == nil && image == nil{
                /** Increase height if its the only view in the headerview*/
                titleLabel.frame.size.height = headerViewDefaultHeight * 0.9
                titleLabel.sizeToFit()
                
                titleLabel.centerInsideOf(this: headerView)
            }
        }
        if imageView != nil{
            headerView.addSubview(imageView!)
            
            /** Increase height if only two elements are in the header*/
            if alertTitle != nil && message == nil || alertTitle == nil && message != nil{
                imageView!.frame.size.height = headerViewDefaultHeight * 0.4
                imageView!.frame.size.width = imageView!.frame.height
            }
            
            imageView!.frame.origin = CGPoint(x: headerView.frame.width/2 - imageView!.frame.width/2, y: (alertTitle != "" ? titleLabel.frame.maxY : 0) + (preferredStyle == .alert ? 5 : 5))
            
            /** Center if its the only element in the header*/
            if alertTitle == nil && message == nil{
                /** Increase height if its the only view in the headerview*/
                imageView!.frame.size.height = headerViewDefaultHeight * 0.9
                imageView!.frame.size.width = imageView!.frame.height
                
                imageView!.centerInsideOf(this: headerView)
            }
        }
        if message != ""{
            headerView.addSubview(messageLabel)
            
            /** Increase height if only two elements are in the header*/
            if alertTitle != nil && image == nil || alertTitle == nil && image != nil{
                messageLabel.frame.size.height = headerViewDefaultHeight * 0.4
                messageLabel.sizeToFit()
            }
            
            messageLabel.frame.origin = CGPoint(x: headerView.frame.width/2 - messageLabel.frame.width/2, y: (imageView != nil ? imageView!.frame.maxY : titleLabel.frame.maxY) + (preferredStyle == .alert ? 5 : 10))
            
            /** Center if its the only element in the header*/
            if alertTitle == nil && image == nil{
                /** Increase height if its the only view in the headerview*/
                messageLabel.frame.size.height = headerViewDefaultHeight * 0.9
                messageLabel.sizeToFit()
                
                messageLabel.centerInsideOf(this: headerView)
            }
        }
        
        switch preferredStyle{
        case .alert:
            alertContainer.addSubview(headerView)
            self.view.addSubview(alertContainer)
            
            if actions.count > 2 && preferredStyle == .alert{
                /** Vertical scrollable stack view*/
                scrollView.addSubview(elementStackView)
                alertContainer.addSubview(scrollView)
                
                scrollView.frame.origin = CGPoint(x: 0, y: headerView.frame.maxY)
            }
            else{
                /** Horizontal non-scrollable stack view*/
                alertContainer.addSubview(elementStackView)
                
                elementStackView.frame.origin = CGPoint(x: 0, y: headerView.frame.maxY)
            }
            
            alertContainer.centerInsideOf(this: self.view)
        case .actionSheet:
            actionSheetContainer.addSubview(headerView)
            self.view.addSubview(actionSheetContainer)
            
            /** Vertical scrollable stack view*/
            scrollView.addSubview(elementStackView)
            actionSheetContainer.addSubview(scrollView)
            
            scrollView.frame.origin = CGPoint(x: 0, y: headerView.frame.maxY)
            
            if bottomButton != nil{
                self.view.addSubview(bottomButton)
                
                bottomButton.frame.origin = CGPoint(x: self.view.frame.width/2 - bottomButton.frame.width/2, y: self.view.frame.height - buttonHeight * 1.5)
                actionSheetContainer.frame.origin = CGPoint(x: self.view.frame.width/2 - actionSheetContainer.frame.width/2, y: bottomButton != nil ? bottomButton.frame.minY - (actionSheetContainer.frame.height + 10) : self.view.frame.height/2 - actionSheetContainer.frame.height/2)
            }
            else{
                actionSheetContainer.centerInsideOf(this: self.view)
            }
        default:
            /** Default case is an alert in the absence of a value*/
            self.preferredStyle = .alert
            
            alertContainer.addSubview(headerView)
            self.view.addSubview(alertContainer)
            
            if actions.count > 2 && preferredStyle == .alert{
                /** Vertical scrollable stack view*/
                scrollView.addSubview(elementStackView)
                alertContainer.addSubview(scrollView)
                
                scrollView.frame.origin = CGPoint(x: 0, y: headerView.frame.maxY)
            }
            else{
                /** Horizontal non-scrollable stack view*/
                alertContainer.addSubview(elementStackView)
                
                elementStackView.frame.origin = CGPoint(x: 0, y: headerView.frame.maxY)
            }
            
            alertContainer.centerInsideOf(this: self.view)
        }
        
        /** Constraints for dynamic content containers*/
        if actions.count > 2 && preferredStyle == .alert || actions.count >= 1 && preferredStyle == .actionSheet{
            
        elementStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        elementStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            elementStackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            elementStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
            
            /** Allow vertical scrolling*/
        elementStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()){ [self] in
        appearAnimation()
        dimContext()
        }
    }
    
    /** Resize the containers to fit all content in their subviews up until they reach the maximum allowed height*/
    private func resize(){
        let maxScrollViewHeight = preferredStyle == .alert ? maximumAlertContainerHeight - headerView.frame.height :  maximumActionSheetContainerHeight - headerView.frame.height
        let totalScrollViewHeight = computerTotalScrollViewHeight()
        
        /** Scrollview scroll disabled if the content doesn't stretch past the maximum specified size for each container type*/
        scrollView.isScrollEnabled = preferredStyle == .alert ? ((totalScrollViewHeight <= maximumAlertContainerHeight) ? false : true) : ((totalScrollViewHeight <= maximumActionSheetContainerHeight) ? false : true)
        
        switch preferredStyle{
        case .alert:
            if actions.count > 2{
                elementStackView.frame.size.height = totalScrollViewHeight
            }
            else{
                elementStackView.frame.size.height = buttonHeight
            }
            
            scrollView.contentSize = CGSize(width: alertContainer.frame.width, height: elementStackView.frame.height)
            scrollView.frame.size.height = totalScrollViewHeight <= maxScrollViewHeight ? totalScrollViewHeight : maxScrollViewHeight
    
            alertContainer.frame.size.height =  actions.count > 2 ? scrollView.frame.height + headerView.frame.size.height : elementStackView.frame.height + headerView.frame.size.height
        case .actionSheet:
            elementStackView.frame.size.height = totalScrollViewHeight
            
            scrollView.contentSize = CGSize(width: actionSheetContainer.frame.width, height: elementStackView.frame.height)
            scrollView.frame.size.height = totalScrollViewHeight <= maxScrollViewHeight ? totalScrollViewHeight : maxScrollViewHeight
            
            actionSheetContainer.frame.size.height = scrollView.frame.height + headerView.frame.size.height
        default:
            /** Alert is default*/
            self.preferredStyle = .alert
            
            if actions.count > 2{
                elementStackView.frame.size.height = totalScrollViewHeight
            }
            else{
                elementStackView.frame.size.height = buttonHeight
            }
            
            scrollView.contentSize = CGSize(width: alertContainer.frame.width, height: elementStackView.frame.height)
            scrollView.frame.size.height = totalScrollViewHeight <= maxScrollViewHeight ? totalScrollViewHeight : maxScrollViewHeight
    
            alertContainer.frame.size.height =  actions.count > 2 ? scrollView.frame.height + headerView.frame.size.height : elementStackView.frame.height + headerView.frame.size.height
        }
    }
    
    /** Compute the total height the scrollview should reflect*/
    private func computerTotalScrollViewHeight()->CGFloat{
        var height: CGFloat = 0
        
        /** The scrollview is not used in this case*/
        if actions.count <= 2 && preferredStyle == .alert{
            return 0
        }
        else{
        for button in buttons {
            if button != bottomButton{
                height += buttonHeight
            }
        }
        }
        
        /**
        for textField in textFields{
            height += textFieldHeight
        }
        */
        
        return height
    }
    
    /** Compute the total height of the element container's subviews given the controller style*/
    private func computeTotalContainerHeight()->CGFloat{
        var height: CGFloat = 0
        
        /** Horizontal buttons are one height*/
        if actions.count <= 2 && preferredStyle == .alert{
            height += buttonHeight
        }
        else{
        for button in buttons {
            if button != bottomButton{
                height += buttonHeight
            }
        }
        }
        
        /**
        for textField in textFields{
            height += textFieldHeight
        }
        */
        
        height += headerView.frame.height
        
        return height
    }
    
    /** Create an array of buttons using the given UIAlertActions*/
    private func createButtons(using actions: [UIAction : UIAlertAction.Style])->[UIButton]{
        var buttons: [UIButton] = []
        
        for action in orderedActions{
            /** The button style for the given action*/
            let style = actions[action]
            
            switch preferredStyle{
            case .alert:
                /** If there are only 2 actions then split these two into two equal sized side by side buttons*/
                let button = UIButton(frame: CGRect(x: 0, y: 0, width: actions.count == 2 ? alertContainer.frame.width/2 : alertContainer.frame.width, height: buttonHeight))
                
                button.setTitle("\(action.title)", for: .normal)
                button.setTitleColor(style == .destructive ? .red : fontColor, for: .normal)
                button.tintColor = style == .destructive ? .red : accentColor
                button.backgroundColor = bodyColor.withAlphaComponent(alpha)
                button.isExclusiveTouch = true
                button.layer.borderColor =  borderColor
                button.layer.borderWidth = buttonBorderWidth
                button.titleLabel?.font = font
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.adjustsFontForContentSizeCategory = true
                button.clipsToBounds = true
                button.addAction(action, for: .touchUpInside)
                
                if action == preferredAction{
                    button.titleLabel?.font = getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: true)
                }
                
                addDynamicButtonGR(button: button)
                
                buttons.append(button)
            case .actionSheet:
                let button = UIButton(frame: CGRect(x: 0, y: 0, width: actionSheetContainer.frame.width, height: buttonHeight))
                
                button.setTitle("\(action.title)", for: .normal)
                button.setTitleColor(style == .destructive ? .red : fontColor, for: .normal)
                button.tintColor = style == .destructive ? .red : accentColor
                button.backgroundColor = bodyColor.withAlphaComponent(alpha)
                button.isExclusiveTouch = true
                button.layer.borderColor =  borderColor
                button.layer.borderWidth = buttonBorderWidth
                button.titleLabel?.font = font
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.adjustsFontForContentSizeCategory = true
                button.clipsToBounds = true
                button.addAction(action, for: .touchUpInside)
                
                addDynamicButtonGR(button: button)
                
                /** Assign the bottom button to the first specified cancel button*/
                if style == .cancel && bottomButton == nil{
      
                    button.layer.cornerRadius = bodyCornerRadius
                    button.layer.borderWidth = bodyBorderWidth
                    button.backgroundColor = bottomButtonBackgroundColor.withAlphaComponent(alpha)
                    button.setTitleColor(bottomButtonFontColor, for: .normal)
                    bottomButton = button
                }
                else if (action.title.lowercased() == "Cancel".lowercased() || action.title.lowercased() == "Done".lowercased() || action.title.lowercased() == "Dismiss".lowercased()) && bottomButton == nil{
                    /** Implicitly assign a bottom button if none is available*/
                    
                    self.actions[action] = .cancel
                    
                    button.layer.cornerRadius = bodyCornerRadius
                    button.layer.borderWidth = bodyBorderWidth
                    button.backgroundColor = bottomButtonBackgroundColor.withAlphaComponent(alpha)
                    button.setTitleColor(bottomButtonFontColor, for: .normal)
                    bottomButton = button
                }
                
                buttons.append(button)
            default:
                /** Default case is an alert in the absence of a value*/
                self.preferredStyle = .alert
                
                let button = UIButton(frame: CGRect(x: 0, y: 0, width: actions.count == 2 ? alertContainer.frame.width/2 : alertContainer.frame.width, height: buttonHeight))
                
                button.setTitle("\(action.title)", for: .normal)
                button.setTitleColor(style == .destructive ? .red : fontColor, for: .normal)
                button.tintColor = style == .destructive ? .red : accentColor
                button.backgroundColor = bodyColor.withAlphaComponent(alpha)
                button.isExclusiveTouch = true
                button.layer.borderColor =  borderColor
                button.layer.borderWidth = buttonBorderWidth
                button.titleLabel?.font = font
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.adjustsFontForContentSizeCategory = true
                button.clipsToBounds = true
                button.addAction(action, for: .touchUpInside)
                
                if action == preferredAction{
                    button.titleLabel?.font = getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: true)
                }
                
                addDynamicButtonGR(button: button)
                
                buttons.append(button)
            }
        }
        
        return buttons
    }
    
    /** Removes all actions and buttons*/
    private func clearActions(){
        orderedActions.removeAll()
        actions.removeAll()
        buttons.removeAll()
    }
    
    /** Add an action to take when the user taps a button*/
    func addAction(action: UIAction, with style: UIAlertAction.Style){
        orderedActions.append(action)
        actions[action] = style
    }
    
    /** Nice little animation that triggers when the view loads*/
    private func appearAnimation(){
        guard useAppearAnimation == true else {
            return
        }
        
        /** Two button cancel ok button set up animation*/
        if actions.count <= 2 && preferredStyle == .alert{
            let originalWidth = alertContainer.frame.width
            alertContainer.frame.size.width = 0
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                alertContainer.frame.size.width = originalWidth
                alertContainer.centerInsideOf(this: self.view)
            }
        }
        else if actions.count > 2 && preferredStyle == .alert{
            let originalHeight = alertContainer.frame.height
            alertContainer.frame.size.height = 0
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                alertContainer.frame.size.height = originalHeight
                alertContainer.centerInsideOf(this: self.view)
            }
        }
        else if preferredStyle == .actionSheet{
            let originalHeight = actionSheetContainer.frame.height
            actionSheetContainer.frame.size.height = 0
            
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                actionSheetContainer.frame.size.height = originalHeight
                
                if bottomButton != nil{
                    bottomButton.alpha = 1
                }
                
                actionSheetContainer.frame.origin = CGPoint(x: self.view.frame.width/2 - actionSheetContainer.frame.width/2, y: bottomButton != nil ? bottomButton.frame.minY - (actionSheetContainer.frame.height + 10) : self.view.frame.height/2 - actionSheetContainer.frame.height/2)
            }
        }
    }
    
    /** Trigger the custom dismiss animation for the current alert controller style*/
    func dismissAnimation(){
        undimContext()
        
        guard useDismissAnimation == true else {
            self.dismiss(animated: true)
            return
        }
        
        /** Two button cancel ok button set up animation*/
        if actions.count <= 2 && preferredStyle == .alert{
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                alertContainer.frame.size.width = 0
                alertContainer.centerInsideOf(this: self.view)
            }
        }
        else if actions.count > 2 && preferredStyle == .alert{
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                alertContainer.frame.size.height = 0
                alertContainer.centerInsideOf(this: self.view)
            }
        }
        else if preferredStyle == .actionSheet{
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                actionSheetContainer.frame.size.height = 0
                
                if bottomButton != nil{
                    bottomButton.alpha = 0
                }
                
                actionSheetContainer.frame.origin = CGPoint(x: self.view.frame.width/2 - actionSheetContainer.frame.width/2, y: bottomButton != nil ? bottomButton.frame.minY - (actionSheetContainer.frame.height + 10) : self.view.frame.height/2 - actionSheetContainer.frame.height/2)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
        self.dismiss(animated: true)
        }
    }
    
    /** Recognizer for tap gesture recognizer that dismisses the VC*/
    @objc func tapGestureRecognizerTriggered(sender: UITapGestureRecognizer){
        dismissAnimation()
    }
    
    /** Adds standard gesture recognizers to button that scale the button when the user's finger enters or leaves the surface of the button*/
    private func addDynamicButtonGR(button: UIButton){
        button.addTarget(self, action: #selector(buttonTI), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonTD), for: .touchDown)
        button.addTarget(self, action: #selector(buttonDE), for: .touchDragExit)
        button.addTarget(self, action: #selector(buttonDEN), for: .touchDragEnter)
    }
    
    /** Fired when user touches inside the button, this is used to reset the scale of the button when the touch down event ends*/
    @objc func buttonTI(sender: UIButton){
        /** Dismisses the controller automatically*/
        self.dismissAnimation()
        
        UIView.animate(withDuration: 0.5, delay: 0){ [self] in
            sender.backgroundColor = sender != bottomButton ? bodyColor.withAlphaComponent(alpha) : bottomButtonBackgroundColor.withAlphaComponent(alpha)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            lightHaptic()
        }
    }
    
    /** Generic recognizer that scales the button down when the user touches their finger down on it*/
    @objc func buttonTD(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0){ [self] in
            sender.backgroundColor = sender != bottomButton ? bodyColor.darker.withAlphaComponent(alpha) : bottomButtonBackgroundColor.darker.withAlphaComponent(alpha)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            lightHaptic()
        }
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger into it*/
    @objc func buttonDEN(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0){ [self] in
            sender.backgroundColor = sender != bottomButton ? bodyColor.darker.withAlphaComponent(alpha) : bottomButtonBackgroundColor.darker.withAlphaComponent(alpha)
        }
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger out inside of it*/
    @objc func buttonDE(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0){ [self] in
            sender.backgroundColor = sender != bottomButton ? bodyColor.withAlphaComponent(alpha) : bottomButtonBackgroundColor.withAlphaComponent(alpha)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            lightHaptic()
        }
    }
    /** Button press methods*/
    
    /**
     /** Return the textfield for the given key value*/
     func getTextField(for key: String)->UITextField?{
     return textFields[key]
     }
     
     /** Add the textfield while also allowing a customization configurationHandler for the user to customize the textfield inside the closure ex.)
      alertController.addTextField { textField in
      textField.placeholder = "Password"
      textField.isSecureTextEntry = true
      }
      */
     func addTextField(configurationHandler: ((UITextField) -> Void)?){
     
     }
     */
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

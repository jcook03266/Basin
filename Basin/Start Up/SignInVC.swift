//
//  SignInVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/8/22.
//

import UIKit

public class SignInVC: UIViewController{
    lazy var statusBarHeight = getStatusBarHeight()
    /** Button used to traverse backwards in the presentation sequence*/
    var backButton = UIButton()
    /** Nil if the presenting vc isn't the home vc where onboarding occurs, else the presenting vc is as mentioned*/
    var onboardingVC: HomeVC?
    var onboardingVCPresenting = false
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        buildUI()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if onboardingVC == nil{
            onboardingVCPresenting = false
        }
        else{
            onboardingVCPresenting = true
        }
    }
    
    init(onboardingVC: HomeVC?) {
        self.onboardingVC = onboardingVC
        
        super.init(nibName: nil, bundle: nil)
    }
    
    /** Construct all elements of the user interface corresponding to this scene*/
    func buildUI(){
        self.view.backgroundColor = bgColor
        
        supplementBackButton()
    }
    
    /** Configures and adds the back button to the view hierarchy*/
    func supplementBackButton(){
        let imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        let image = UIImage(systemName: "arrow.backward", withConfiguration: imageConfiguration)
    
        backButton.frame.size.height = 40
        backButton.frame.size.width = backButton.frame.size.height
        backButton.backgroundColor = appThemeColor
        backButton.tintColor = .white
        backButton.setImage(image, for: .normal)
        backButton.layer.cornerRadius = backButton.frame.height/2
        backButton.isExclusiveTouch = true
        backButton.castDefaultShadow()
        backButton.layer.shadowColor = appThemeColor.darker.cgColor
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchDown)
        backButton.isEnabled = false
        backButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        DispatchQueue.main.async{[self] in
        backButton.frame.origin = CGPoint(x: backButton.frame.width/2, y: statusBarHeight + backButton.frame.height/2)
        }
        
        /** Scale up animation*/
        UIView.animate(withDuration: 1, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            backButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){ [self] in
            backButton.isEnabled = true
        }
        self.view.addSubview(backButton)
    }
    
    @objc func backButtonPressed(sender: UIButton){
        if onboardingVCPresenting == true{
            onboardingVC!.displayStartScreen()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){ [self] in
            onboardingVC!.setStartMenuPosition()
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func getStatusBarHeight()->CGFloat{
        return view.safeAreaInsets.top
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

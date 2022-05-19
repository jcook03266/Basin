//
//  ViewController.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/4/22.
//

import UIKit
import Lottie
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAnalytics
import FBSDKLoginKit
import GoogleSignIn
import AuthenticationServices

///NOTE: Remove comment for completion of onboarding when done testing sign in and out

/** The first view controller displayed when the app is launched*/
class HomeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UITextViewDelegate, ASAuthorizationControllerPresentationContextProviding, LoginButtonDelegate{
    lazy var statusBarHeight = getStatusBarHeight()
    /** UI Elements used for the launch screen loading animation*/
    var lottieLoadingAnimationView: AnimationView!
    /** UIView the width of the screen that animates going back and forth across the screen to symbolize 'loading'*/
    var loadingBar: UIView!
    /** Label that displays an array of entertaining 'loading' laundry pun phrases*/
    var loadingLabel: UILabel!
    var laundryLoadingPuns: [String] = ["Loading","Washing","Drying","Finished!"]
    
    /** Everything for the onboarding Note: onboarding will be disabled after the first sign in / sign up event via user defaults to avoid repetition*/
    var onboardingMissionStatements: [String] = ["Washing your clothes shouldn't feel like a prison sentence for a day. We know you have better things to do than watch suds toss and turn for hours.","At Stuy Wash N' Dry you have an extensive selection of detergents, fabric softeners, and high quality washers and dryers, all at your disposal to wash away your day.","Even if you're too busy to stop by one of our many NYC locations, you can still get the job done by scheduling a same-day contactless pickup.","You'll receive notifications about your order throughout the entire process so that you're always kept in the loop. Ease of access, security, and reliability through communication is what we thrive on.","In addition to pick up services we also offer delivery directly to you. With our services you can pay online, leave your clothes for pickup, and expect to get your clothes the next day, or even the same day!","Our motto is \"Clean laundry peace of mind\", and that's our promise to you for choosing Stuy Wash N' Dry; turning laundry day into an experience instead of an existence."]
    var onboardingSlideTitles: [String] = ["Laundry getting you down?","Let us iron out your problems","Use our drop off and pickup services","Get notified every step of the way","Oh, we also deliver too!","Now, you can finally relax again"]
    var lottieOnboardingAnimationView: AnimationView!
    var onboardingTransitionView: UIView!
    var onboardingCollectionView: UICollectionView!
    var onboardingCollectionViewCells: [UIView] = []
    /** How many items will be in the onboarding collection view*/
    var onboardingCollectionViewCount = 6
    var currentSlide = 0
    var onboardingPageControl: UIPageControl!
    
    /** Traversal buttons*/
    var onboardingNextButton: UIButton!
    var onboardingPreviousButton: UIButton!
    var onboardingSkipButton: UIButton!
    var getStartedButton: UIButton!
    /** Go backwards after pressing the sign in button*/
    var signInBackButton: UIButton!
    
    /** Used to determine whether or not the sign in UI is currently being displayed*/
    var signInUIBeingDisplayed: Bool = false
    
    /** Various UI Views used in the onboarding process*/
    /** View that contains a masked UIView with a clear background and a full height UIView below it, this gives off the illusion that the two UIViews are one view with a curved top*/
    var onboardingFinalSlideTransitionView: UIView!
    /** Masked clear view with a curved mask applied to the view's top layer*/
    var maskedHeaderView: UIView!
    /** Misc. views from the last slide after pressing the get started button that need to be cleaned up*/
    var onboardingFinalSlideMiscViews: [UIView] = []
    /** The imageview that contains the logo*/
    var onboardingLogoImageView: UIImageView!
    /** Contains the animation view and label in the last animation view, used to remove these from the superview and reveal the login and sign in UI underneath*/
    var lastSlideContentContainer: UIView!
    /** Onboarding progression: sad laundry room -> lady ironing -> guy with packages -> notification -> delivery boy -> two people engaged in activities -> Sign up / sign in*/
    
    /** Sign-in Screen UI*/
    var signInScreenSegmentedControl: UISegmentedControl!
    var usernameEmailTextfield: UITextField!
    var passwordTextField: UITextField!
    var employeeIDTextField: UITextField!
    var signInButton: UIButton!
    /** Various other sign in methods that can utilized for regular users*/
    /** Textual prompt for the user to use the sign-in methods enumerated below*/
    var signInWithLabel: UILabel!
    /** Simple line going through the middle of the sign in with label*/
    var signInWithDividingLine: UIView!
    var appleSignInButton: UIButton!
    var googleSignInButton: UIButton!
    var faceBookSignInButton: UIButton!
    /** Hidden facebook sign in button that's triggered by the custom facebook sign in button*/
    var faceBookLoginButton: FBLoginButton = FBLoginButton()
    /** Simple way to keep track of the sign in with facebook google etc buttons*/
    var signInWithButtons: [UIButton] = []
    /** Label with the title of the current sign in portal*/
    var signInPortalLabel: UILabel!
    /** To keep track of which sign in portal the user has selected via the segmented control*/
    var currentSignInPortal = 0
    let signInPortalTitles = ["Customer Portal","Business Client Portal","Driver Portal"]
    /** Switch between email, phone, and username keyboard types, 0 username, 1 email, 2 phone number*/
    var userNameFieldKeyboardType = 0
    var userNameFieldKeyboardTypes = [0,1,2]
    /** Switch between secure and non-secure password textfield types*/
    var usePasswordSecurity = true
    /** Switch between secure and non-secure employee textfield types*/
    var useEmployeeSecurity = true
    /** The selected text field and its original position in case it needs to be raised higher than the keyboard*/
    var currentlySelectedTextField: UITextField!
    var currentlySelectedTextFieldOriginalPosition = CGPoint.zero
    /** Global reference to the left view in the employee ID textfield in order to change the embedded UIButton's image to the appropriate image*/
    var employeeIDTextFieldLeftButton: UIButton!
    /** An array of views that need to be disposed of when switching between scenes*/
    var disposableViews: [UIView] = []
    var username: String!
    var password: String!
    var employeeID: String!
    /** The three types of online-only entities that can interface with the backend and frontend*/
    var customer: Customer?
    var businessClient: BusinessClient?
    var driver: Driver?
    
    /** Bool used to turn off the extra logic activated when the scroll view is swiping so that the animations in the collection view can be loaded up without the user noticing*/
    var priming = true
    
    /** Firebase interfacing*/
    var db: Firestore!
    
    /** Status bar styling variables*/
    override var preferredStatusBarStyle: UIStatusBarStyle{
        switch darkMode{
        case true:
            return .lightContent
        case false:
            return .darkContent
        }
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    /** Specify status bar display preference*/
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    /** Status bar styling variables*/
    
    /** Bool used to control the flow of the application, if a user isn't logged in then display the onboarding screen, else go to the appropriate user client*/
    var userLoggedIn: Bool = false
    var loggedInUserType: String? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        homeVCReference = self
        
        //pushWashingDataToMenuCollection()
        //pushDryCleaningDataToMenuCollection()
        
        //deleteCurrentUser()
        //signOutCurrentUser()
        
        /** Specify a maximum font size*/
        self.view.maximumContentSizeCategory = .large
        
        /** Check if the user is logged in, if not then transition to the on boarding screen*/
        if Auth.auth().currentUser != nil{
            print("A user is logged in")
            userLoggedIn = true
        }
        else{
            print("A user is not logged in")
        }
        
        checkDarkmode()
        
        addVisualSingleTapGestureRecognizer()
        triggerLoadingAnimations()
        removeLoadingAnimations()
        startNetworkMonitor()
        
        /** Don't load the animations up into memory if the onboarding screen won't be shown*/
        if didUserCompletedOnboarding() == false{
            primeTheAnimations()
        }
        
        loadCoreData()
    }
    
    /** Load various data in from storage*/
    func loadCoreData(){
        loadFavoriteLaundromatsCoreData()
    }
    
    /** Load the hardware intensive animations into memory by forcing the collectionview to render its content before the user can see it, this prevents stuttering when swiping as the animation views must render immediately when being loaded up into memory*/
    func primeTheAnimations(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2){[self] in
            guard onboardingCollectionView != nil else {
                priming = false
                return
            }
            
            onboardingCollectionView.setContentOffset(CGPoint(x: view.frame.width * CGFloat(onboardingPageControl.numberOfPages - 1), y: 0), animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.7){[self] in
            guard onboardingCollectionView != nil else {
                priming = false
                return
            }
            
            onboardingCollectionView.setContentOffset(CGPoint(x: view.frame.width * CGFloat(0), y: 0), animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                priming = false
            }
        }
    }
    
    /** Set up notifications for determining when the keyboard is shown and hidden*/
    func setUpKeyboardNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func getStatusBarHeight()->CGFloat{
        return view.safeAreaInsets.top
    }
    
    /** Triggers all the loading animations to enrich the user's launch experience*/
    func triggerLoadingAnimations(){
        displayLoadingIndicatorAnimation()
        displayLoadingBarAnimation()
        displayLoadingLabel()
    }
    
    /** Removes all loading animations once the fake loading is done*/
    func removeLoadingAnimations(){
        /** Production delay*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.25){[self] in
            transitionLoadingBarAnimation()
            removeLoadingIndicatorAnimation()
            removeLoadingLabel()
        }
    }
    
    /** Displays a punny label that entertains the user while the app 'loads'*/
    func displayLoadingLabel(){
        let labelHeight: CGFloat = lottieLoadingAnimationView.frame.height/2
        let labelWidth: CGFloat = view.frame.width/2
        
        loadingLabel = UILabel(frame: CGRect(x: view.frame.width/2 - labelWidth/2, y: lottieLoadingAnimationView.frame.maxY, width: labelWidth, height: labelHeight))
        loadingLabel.adjustsFontSizeToFitWidth = true
        
        /** Enable dynamic font sizing*/
        loadingLabel.adjustsFontForContentSizeCategory = true
        loadingLabel.font = getCustomFont(name: .Bungee_Regular, size: 38, dynamicSize: true)
        
        loadingLabel.alpha = 0
        loadingLabel.textColor = .white
        loadingLabel.text = "Basin"
        ///loadingLabel.text = laundryLoadingPuns[0]
        loadingLabel.textAlignment = .center
        loadingLabel.shadowColor = .lightGray
        
        UIView.animate(withDuration: 1, delay: 2){[self] in
            loadingLabel.alpha = 1
        }
        
        /*
        loadingLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        /** Transform the size of the animation view from 0 to 1*/
        UIView.animate(withDuration: 1, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            loadingLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** Various timers that change the text's labels to the words in the laundryLoadingPuns array alongside a comical ellipsis (...) at the end of each statement*/
        let animationDuration = 0.3
        
        appendEllipsisAnimation()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false){[self] _ in
            UIView.transition(with: loadingLabel, duration: animationDuration, options: .curveEaseIn, animations: { [self] in
                loadingLabel.text = laundryLoadingPuns[1]
            })
            appendEllipsisAnimation()
        }
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false){[self] _ in
            UIView.transition(with: loadingLabel, duration: animationDuration, options: .curveEaseIn, animations: { [self] in
                loadingLabel.text = laundryLoadingPuns[2]
            })
            appendEllipsisAnimation()
        }
        Timer.scheduledTimer(withTimeInterval: 3.25, repeats: false){[self] _ in
            UIView.transition(with: loadingLabel, duration: animationDuration, options: .curveEaseIn, animations: { [self] in
                loadingLabel.text = laundryLoadingPuns[3]
            })
        }
        
        /** Appends 3 dots to the end of the label's text to symbolize loading*/
        func appendEllipsisAnimation(){
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false){[self] _ in
                UIView.transition(with: loadingLabel, duration: animationDuration, options: .curveEaseIn, animations: {
                    loadingLabel.text = loadingLabel.text! + "."
                })
            }
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false){[self] _ in
                UIView.transition(with: loadingLabel, duration: animationDuration, options: .curveEaseIn, animations: {
                    loadingLabel.text = loadingLabel.text! + "."
                })
            }
            Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false){[self] _ in
                UIView.transition(with: loadingLabel, duration: animationDuration, options: .curveEaseIn, animations: {
                    loadingLabel.text = loadingLabel.text! + "."
                })
            }
        }
        */
        
        self.view.addSubview(loadingLabel)
    }
    
    /** Removes the loading label by scaling it down and then removing the view from the hierarchy*/
    func removeLoadingLabel(){
        /** Transform the size of the animation view from 1 to near 0*/
        UIView.animate(withDuration: 1, delay: 0.25){ [self] in
            loadingLabel.alpha = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25){[self] in
            loadingLabel.removeFromSuperview()
        }
    }
    
    /** Loading bar animation that moves horizontally across the screen*/
    func displayLoadingBarAnimation(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){ [self] in
            loadingBar = UIView(frame: CGRect(x: -view.frame.width, y: statusBarHeight, width: view.frame.width, height: 5))
            loadingBar.backgroundColor = .white
            
            /** Add shadow to the loading bar*/
            loadingBar.clipsToBounds = false
            loadingBar.layer.shadowColor = UIColor.darkGray.cgColor
            loadingBar.layer.shadowOpacity = 0.15
            loadingBar.layer.shadowRadius = 8
            loadingBar.layer.shadowPath = UIBezierPath(rect: loadingBar.bounds).cgPath
            
            /** Transform the size of the animation view from 0 to 1*/
            UIView.animate(withDuration: 1, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .repeat]){ [self] in
                loadingBar.frame.origin.x = view.frame.width
            }
            
            self.view.addSubview(loadingBar)
        }
    }
    
    /** Force the loading bar to center itself in the middle and increase its size to fit the entire screen in order to transition to a new scene in a seamless animation*/
    func transitionLoadingBarAnimation(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
            loadingBar.frame.origin.x = 0
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){ [self] in
            loadingBar.backgroundColor = bgColor
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            loadingBar.layer.removeAllAnimations()
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){ [self] in
                loadingBar.frame.size.height = view.frame.height
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .beginFromCurrentState]){[self] in
                loadingBar.frame.origin.y = 0
            }
            
            /** If a user is logged in then go to the appropriate client for that user, if not then show the onboarding screen*/
            if userLoggedIn == true{
                
                /** Determine what kind of user this is based on the collection they're found in and then push the appropriate scene*/
                loggedInUserType = getLoggedInUserType()
                
                guard getLoggedInUserType() != nil else{
                    /** Sign the current user out if their type isn't specified and continue like normal after dealing with this unusual behavior*/
                    signOutCurrentUser()
                    
                    launchScreenTransitionAnimation()
                    if didUserCompletedOnboarding() == true{
                        goToSignInSignUpScreen()
                    }
                    
                    return
                }
                
                switch loggedInUserType!{
                case "Customer":
                    presentCustomerVC()
                case "Driver":
                    presentDriverVC()
                case "Business":
                    presentBusinessVC()
                default:
                    /** Sign the current user out if their type isn't specified and continue like normal after dealing with this unusual behavior*/
                    signOutCurrentUser()
                    
                    launchScreenTransitionAnimation()
                    if didUserCompletedOnboarding() == true{
                        goToSignInSignUpScreen()
                    }
                }
            
            }
            else{
                launchScreenTransitionAnimation()
                if didUserCompletedOnboarding() == true{
                    goToSignInSignUpScreen()
                }
            }
        }
    }
    
    /** Displays a fun little washing machine porthole that animates alongside the progress view to give the user the feeling that things are loading slower in the background*/
    func displayLoadingIndicatorAnimation(){
        /** Static dimensions for this animation*/
        let width = 180
        
        lottieLoadingAnimationView = AnimationView.init(name: "Basin logo Lottie")
        lottieLoadingAnimationView.frame.size = CGSize(width: width, height: width)
        lottieLoadingAnimationView.frame.origin = CGPoint(x: view.frame.width/2 - lottieLoadingAnimationView.frame.width/2, y: view.frame.height/2 - lottieLoadingAnimationView.frame.height/2)
        
        lottieLoadingAnimationView.animationSpeed = 1
        lottieLoadingAnimationView.backgroundBehavior = .pauseAndRestore
        lottieLoadingAnimationView.isExclusiveTouch = true
        lottieLoadingAnimationView.shouldRasterizeWhenIdle = true
        lottieLoadingAnimationView.contentMode = .scaleAspectFill
        lottieLoadingAnimationView.isOpaque = false
        lottieLoadingAnimationView.clipsToBounds = true
        lottieLoadingAnimationView.backgroundColor = .clear
        lottieLoadingAnimationView.loopMode = .playOnce
        lottieLoadingAnimationView.clipsToBounds = false
        
        lottieLoadingAnimationView.play(completion: nil)
        
        self.view.addSubview(lottieLoadingAnimationView)
    }
    
    /** Removes the loading indicator animation view in an animated fashion*/
    func removeLoadingIndicatorAnimation(){
        /** Play the animation backwards*/
        lottieLoadingAnimationView.animationSpeed = 2.5
        lottieLoadingAnimationView.play(fromFrame: 100, toFrame: 0, loopMode: .playOnce, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){[self] in
            lottieLoadingAnimationView.removeFromSuperview()
        }
    }
    
    /** View animated rising from the bottom of the screen up to the top*/
    func launchScreenTransitionAnimation(){
        /** The size of each onboarding view cell stored in the collection view*/
        let onboardingViewSize = CGSize(width: view.frame.width, height: view.frame.height * 0.9)
        
        let animationViewSize = onboardingViewSize.width * 0.8
        
        onboardingPageControl = UIPageControl()
        onboardingPageControl.currentPageIndicatorTintColor = appThemeColor
        onboardingPageControl.numberOfPages = onboardingCollectionViewCount
        onboardingPageControl.backgroundStyle = .minimal
        onboardingPageControl.pageIndicatorTintColor = .lightGray
        onboardingPageControl.isUserInteractionEnabled = true
        onboardingPageControl.frame.size.height = 30
        onboardingPageControl.frame.size.width = onboardingPageControl.intrinsicContentSize.width
        onboardingPageControl.isExclusiveTouch = true
        onboardingPageControl.backgroundColor = UIColor.clear
        onboardingPageControl.alpha = 0
        onboardingPageControl.addTarget(self, action: #selector(onboardingPageControlTapped), for: .touchUpInside)
        
        var imageConfiguration = UIImage.SymbolConfiguration(weight: .bold)
        var image = UIImage(systemName: "arrow.forward", withConfiguration: imageConfiguration)
        onboardingNextButton = UIButton()
        onboardingNextButton.frame.size.height = 50
        onboardingNextButton.frame.size.width = onboardingNextButton.frame.size.height
        onboardingNextButton.backgroundColor = appThemeColor
        onboardingNextButton.tintColor = .white
        onboardingNextButton.setImage(image, for: .normal)
        onboardingNextButton.layer.cornerRadius = onboardingNextButton.frame.height/2
        onboardingNextButton.isExclusiveTouch = true
        onboardingNextButton.castDefaultShadow()
        onboardingNextButton.layer.shadowColor = appThemeColor.darker.cgColor
        onboardingNextButton.addTarget(self, action: #selector(onboardingNextButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: onboardingNextButton)
        onboardingNextButton.alpha = 0
        
        imageConfiguration = UIImage.SymbolConfiguration(weight: .bold)
        image = UIImage(systemName: "arrow.backward", withConfiguration: imageConfiguration)
        onboardingPreviousButton = UIButton()
        onboardingPreviousButton.frame.size.height = 50
        onboardingPreviousButton.frame.size.width = onboardingPreviousButton.frame.size.height
        onboardingPreviousButton.backgroundColor = appThemeColor
        onboardingPreviousButton.tintColor = .white
        onboardingPreviousButton.setImage(image, for: .normal)
        onboardingPreviousButton.layer.cornerRadius = onboardingPreviousButton.frame.height/2
        onboardingPreviousButton.isExclusiveTouch = true
        onboardingPreviousButton.castDefaultShadow()
        onboardingPreviousButton.layer.shadowColor = appThemeColor.darker.cgColor
        onboardingPreviousButton.addTarget(self, action: #selector(onboardingPreviousButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: onboardingPreviousButton)
        onboardingPreviousButton.isEnabled = false
        onboardingPreviousButton.alpha = 0
        
        imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        image = UIImage(systemName: "forward.fill", withConfiguration: imageConfiguration)
        onboardingSkipButton = UIButton()
        onboardingSkipButton.frame.size.height = 40
        onboardingSkipButton.frame.size.width = onboardingSkipButton.frame.size.height
        onboardingSkipButton.backgroundColor = appThemeColor
        onboardingSkipButton.tintColor = .white
        onboardingSkipButton.setImage(image, for: .normal)
        onboardingSkipButton.layer.cornerRadius = onboardingSkipButton.frame.height/2
        onboardingSkipButton.isExclusiveTouch = true
        onboardingSkipButton.castDefaultShadow()
        onboardingSkipButton.layer.shadowColor = appThemeColor.darker.cgColor
        onboardingSkipButton.addTarget(self, action: #selector(onboardingSkipButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: onboardingSkipButton)
        onboardingSkipButton.isEnabled = false
        
        onboardingTransitionView = UIView(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height))
        onboardingTransitionView.backgroundColor = bgColor
        
        getStartedButton = UIButton()
        getStartedButton.frame.size.height = 50
        getStartedButton.frame.size.width = view.frame.width * 0.8
        getStartedButton.backgroundColor = appThemeColor
        getStartedButton.tintColor = .white
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.layer.cornerRadius = getStartedButton.frame.height/2
        getStartedButton.isExclusiveTouch = true
        getStartedButton.castDefaultShadow()
        getStartedButton.setTitleColor(UIColor.white, for: .normal)
        getStartedButton.titleLabel?.adjustsFontForContentSizeCategory = true
        getStartedButton.titleLabel?.adjustsFontSizeToFitWidth = true
        getStartedButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 20, dynamicSize: true)
        getStartedButton.layer.shadowColor = appThemeColor.darker.cgColor
        getStartedButton.layer.shadowRadius = 3
        getStartedButton.addTarget(self, action: #selector(getStartedButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: getStartedButton)
        
        /** Cell 1*/
        let containerView_1 = UIView()
        containerView_1.frame.size = onboardingViewSize
        
        let animationView_1 = AnimationView.init(name: "89833-laundry")
        animationView_1.frame.size = CGSize(width: animationViewSize, height: animationViewSize)
        animationView_1.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - animationView_1.frame.width/2, y: onboardingTransitionView.frame.height/2 - (animationView_1.frame.height * 0.9))
        
        animationView_1.animationSpeed = 1
        animationView_1.backgroundBehavior = .pauseAndRestore
        animationView_1.isExclusiveTouch = true
        animationView_1.shouldRasterizeWhenIdle = true
        animationView_1.contentMode = .scaleAspectFill
        animationView_1.isOpaque = false
        animationView_1.clipsToBounds = true
        animationView_1.backgroundColor = .clear
        animationView_1.loopMode = .loop
        animationView_1.clipsToBounds = false
        animationView_1.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        animationView_1.play(completion: nil)
        
        /** Transform the size of the animation view from 0 to 1*/
        UIView.animate(withDuration: 1, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            animationView_1.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }
        UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            animationView_1.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** Title of the slide being presented*/
        let slideTitle_1 = UILabel(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: animationView_1.frame.maxY, width: onboardingTransitionView.frame.width * 0.9, height: 40))
        slideTitle_1.adjustsFontSizeToFitWidth = true
        slideTitle_1.adjustsFontForContentSizeCategory = true
        slideTitle_1.font = getCustomFont(name: .Ubuntu_bold, size: 25, dynamicSize: true)
        slideTitle_1.textColor = appThemeColor
        slideTitle_1.text = onboardingSlideTitles[0]
        slideTitle_1.textAlignment = .center
        slideTitle_1.shadowColor = appThemeColor.darker
        
        /** The goal of this slide*/
        let missionStatementTextView_1 = AccessibleTextView(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: slideTitle_1.frame.maxY + slideTitle_1.frame.height/4, width: onboardingTransitionView.frame.width * 0.9, height: onboardingTransitionView.frame.height * 0.2), presentingViewController: self, useContextMenu: false)
        missionStatementTextView_1.clipsToBounds = true
        missionStatementTextView_1.layer.cornerRadius = 20
        missionStatementTextView_1.backgroundColor = bgColor
        missionStatementTextView_1.showsVerticalScrollIndicator = true
        switch darkMode{
        case true:
            missionStatementTextView_1.backgroundColor = .black
            missionStatementTextView_1.indicatorStyle = .black
        case false:
            missionStatementTextView_1.indicatorStyle = .white
        }
        missionStatementTextView_1.isSelectable = false
        missionStatementTextView_1.adjustsFontForContentSizeCategory = false
        missionStatementTextView_1.attributedText = missionStatementTextView_1.attribute(this: onboardingMissionStatements[0], font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false), mainColor: fontColor, subColor: appThemeColor, subStrings: ["shouldn't","prison sentence","hours"])
        missionStatementTextView_1.setAttributedTextLineSpacing(lineSpacing: 5)
        missionStatementTextView_1.setAttributedTextAlignment(alignment: .center)
        missionStatementTextView_1.textContainerInset = UIEdgeInsets(top: 20, left: 5, bottom: 20, right: 5)
        missionStatementTextView_1.sizeToFit()
        
        let shadowView_1 = ShadowView(subview: missionStatementTextView_1, shadowColor: appThemeColor, shadowRadius: 1, shadowOpacity: 1)
        shadowView_1.setShadowOffset(shadowOffset: CGSize(width: 0, height: 2))
        shadowView_1.frame.origin.x = onboardingTransitionView.frame.width/2 - shadowView_1.frame.width/2
        missionStatementTextView_1.frame.origin = .zero
        
        containerView_1.addSubview(animationView_1)
        containerView_1.addSubview(slideTitle_1)
        containerView_1.addSubview(shadowView_1)
        /** Cell 1*/
        /** Cell 2*/
        let containerView_2 = UIView()
        containerView_2.frame.size = onboardingViewSize
        
        let animationView_2 = AnimationView.init(name: "49860-ironing-people-animation")
        animationView_2.frame.size = CGSize(width: animationViewSize, height: animationViewSize)
        animationView_2.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - animationView_2.frame.width/2, y: onboardingTransitionView.frame.height/2 - (animationView_2.frame.height * 0.9))
        
        animationView_2.animationSpeed = 1
        animationView_2.backgroundBehavior = .pauseAndRestore
        animationView_2.isExclusiveTouch = true
        animationView_2.shouldRasterizeWhenIdle = true
        animationView_2.contentMode = .scaleAspectFill
        animationView_2.isOpaque = false
        animationView_2.clipsToBounds = true
        animationView_2.backgroundColor = .clear
        animationView_2.loopMode = .loop
        animationView_2.clipsToBounds = false
        
        animationView_2.play(completion: nil)
        
        /** Title of the slide being presented*/
        let slideTitle_2 = UILabel(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: animationView_2.frame.maxY, width: onboardingTransitionView.frame.width * 0.9, height: 40))
        slideTitle_2.adjustsFontSizeToFitWidth = true
        slideTitle_2.adjustsFontForContentSizeCategory = true
        slideTitle_2.font = getCustomFont(name: .Ubuntu_bold, size: 25, dynamicSize: true)
        slideTitle_2.textColor = appThemeColor
        slideTitle_2.text = onboardingSlideTitles[1]
        slideTitle_2.textAlignment = .center
        slideTitle_2.shadowColor = appThemeColor.darker
        
        /** The goal of this slide*/
        let missionStatementTextView_2 = AccessibleTextView(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: slideTitle_2.frame.maxY + slideTitle_2.frame.height/4, width: onboardingTransitionView.frame.width * 0.9, height: onboardingTransitionView.frame.height * 0.2), presentingViewController: self, useContextMenu: false)
        missionStatementTextView_2.clipsToBounds = true
        missionStatementTextView_2.layer.cornerRadius = 20
        missionStatementTextView_2.backgroundColor = bgColor
        missionStatementTextView_2.showsVerticalScrollIndicator = true
        switch darkMode{
        case true:
            missionStatementTextView_2.backgroundColor = .black
            missionStatementTextView_2.indicatorStyle = .black
        case false:
            missionStatementTextView_2.indicatorStyle = .white
        }
        missionStatementTextView_2.isSelectable = false
        missionStatementTextView_2.adjustsFontForContentSizeCategory = false
        missionStatementTextView_2.attributedText = missionStatementTextView_2.attribute(this: onboardingMissionStatements[1], font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false), mainColor: fontColor, subColor: appThemeColor, subStrings: ["Stuy Wash N' Dry","detergents","fabric softeners","high quality"])
        missionStatementTextView_2.setAttributedTextLineSpacing(lineSpacing: 5)
        missionStatementTextView_2.setAttributedTextAlignment(alignment: .center)
        missionStatementTextView_2.textContainerInset = UIEdgeInsets(top: 20, left: 5, bottom: 20, right: 5)
        missionStatementTextView_2.sizeToFit()
        
        let shadowView_2 = ShadowView(subview: missionStatementTextView_2, shadowColor: appThemeColor, shadowRadius: 1, shadowOpacity: 1)
        shadowView_2.setShadowOffset(shadowOffset: CGSize(width: 0, height: 2))
        shadowView_2.frame.origin.x = onboardingTransitionView.frame.width/2 - shadowView_2.frame.width/2
        missionStatementTextView_2.frame.origin = .zero
        
        containerView_2.addSubview(animationView_2)
        containerView_2.addSubview(slideTitle_2)
        containerView_2.addSubview(shadowView_2)
        /** Cell 2*/
        /** Cell 3*/
        let containerView_3 = UIView()
        containerView_3.frame.size = onboardingViewSize
        
        let animationView_3 = AnimationView.init(name: "75200-packaging-for-delivery")
        animationView_3.frame.size = CGSize(width: animationViewSize, height: animationViewSize)
        animationView_3.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - animationView_3.frame.width/2, y: onboardingTransitionView.frame.height/2 - (animationView_3.frame.height * 0.9))
        
        animationView_3.animationSpeed = 1
        animationView_3.backgroundBehavior = .pauseAndRestore
        animationView_3.isExclusiveTouch = true
        animationView_3.shouldRasterizeWhenIdle = true
        animationView_3.contentMode = .scaleAspectFill
        animationView_3.isOpaque = false
        animationView_3.clipsToBounds = true
        animationView_3.backgroundColor = .clear
        animationView_3.loopMode = .loop
        animationView_3.clipsToBounds = false
        
        animationView_3.play(completion: nil)
        
        /** Title of the slide being presented*/
        let slideTitle_3 = UILabel(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: animationView_3.frame.maxY, width: onboardingTransitionView.frame.width * 0.9, height: 40))
        slideTitle_3.adjustsFontSizeToFitWidth = true
        slideTitle_3.adjustsFontForContentSizeCategory = true
        slideTitle_3.font = getCustomFont(name: .Ubuntu_bold, size: 25, dynamicSize: true)
        slideTitle_3.textColor = appThemeColor
        slideTitle_3.text = onboardingSlideTitles[2]
        slideTitle_3.textAlignment = .center
        slideTitle_3.shadowColor = appThemeColor.darker
        
        /** The goal of this slide*/
        let missionStatementTextView_3 = AccessibleTextView(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: slideTitle_3.frame.maxY + slideTitle_3.frame.height/4, width: onboardingTransitionView.frame.width * 0.9, height: onboardingTransitionView.frame.height * 0.2), presentingViewController: self, useContextMenu: false)
        missionStatementTextView_3.clipsToBounds = true
        missionStatementTextView_3.layer.cornerRadius = 20
        missionStatementTextView_3.backgroundColor = bgColor
        missionStatementTextView_3.showsVerticalScrollIndicator = true
        switch darkMode{
        case true:
            missionStatementTextView_3.backgroundColor = .black
            missionStatementTextView_3.indicatorStyle = .black
        case false:
            missionStatementTextView_3.indicatorStyle = .white
        }
        missionStatementTextView_3.isSelectable = false
        missionStatementTextView_3.adjustsFontForContentSizeCategory = false
        missionStatementTextView_3.attributedText = missionStatementTextView_3.attribute(this: onboardingMissionStatements[2], font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false), mainColor: fontColor, subColor: appThemeColor, subStrings: ["many NYC locations","same-day contactless pickup"])
        missionStatementTextView_3.setAttributedTextLineSpacing(lineSpacing: 5)
        missionStatementTextView_3.setAttributedTextAlignment(alignment: .center)
        missionStatementTextView_3.textContainerInset = UIEdgeInsets(top: 20, left: 5, bottom: 20, right: 5)
        missionStatementTextView_3.sizeToFit()
        
        let shadowView_3 = ShadowView(subview: missionStatementTextView_3, shadowColor: appThemeColor, shadowRadius: 1, shadowOpacity: 1)
        shadowView_3.setShadowOffset(shadowOffset: CGSize(width: 0, height: 2))
        shadowView_3.frame.origin.x = onboardingTransitionView.frame.width/2 - shadowView_3.frame.width/2
        missionStatementTextView_3.frame.origin = .zero
        
        containerView_3.addSubview(animationView_3)
        containerView_3.addSubview(slideTitle_3)
        containerView_3.addSubview(shadowView_3)
        /** Cell 3*/
        /** Cell 4*/
        let containerView_4 = UIView()
        containerView_4.frame.size = onboardingViewSize
        
        let animationView_4 = AnimationView.init(name: "76038-contact-mail")
        animationView_4.frame.size = CGSize(width: animationViewSize, height: animationViewSize)
        animationView_4.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - animationView_4.frame.width/2, y: onboardingTransitionView.frame.height/2 - (animationView_4.frame.height * 0.9))
        
        animationView_4.animationSpeed = 1
        animationView_4.backgroundBehavior = .pauseAndRestore
        animationView_4.isExclusiveTouch = true
        animationView_4.shouldRasterizeWhenIdle = true
        animationView_4.contentMode = .scaleAspectFill
        animationView_4.isOpaque = false
        animationView_4.clipsToBounds = true
        animationView_4.backgroundColor = .clear
        animationView_4.loopMode = .loop
        animationView_4.clipsToBounds = false
        
        animationView_4.play(completion: nil)
        
        /** Title of the slide being presented*/
        let slideTitle_4 = UILabel(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: animationView_4.frame.maxY, width: onboardingTransitionView.frame.width * 0.9, height: 40))
        slideTitle_4.adjustsFontSizeToFitWidth = true
        slideTitle_4.adjustsFontForContentSizeCategory = true
        slideTitle_4.font = getCustomFont(name: .Ubuntu_bold, size: 25, dynamicSize: true)
        slideTitle_4.textColor = appThemeColor
        slideTitle_4.text = onboardingSlideTitles[3]
        slideTitle_4.textAlignment = .center
        slideTitle_4.shadowColor = appThemeColor.darker
        
        /** The goal of this slide*/
        let missionStatementTextView_4 = AccessibleTextView(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: slideTitle_4.frame.maxY + slideTitle_4.frame.height/4, width: onboardingTransitionView.frame.width * 0.9, height: onboardingTransitionView.frame.height * 0.2), presentingViewController: self, useContextMenu: false)
        missionStatementTextView_4.clipsToBounds = true
        missionStatementTextView_4.layer.cornerRadius = 20
        missionStatementTextView_4.backgroundColor = bgColor
        missionStatementTextView_4.showsVerticalScrollIndicator = true
        switch darkMode{
        case true:
            missionStatementTextView_4.backgroundColor = .black
            missionStatementTextView_4.indicatorStyle = .black
        case false:
            missionStatementTextView_4.indicatorStyle = .white
        }
        missionStatementTextView_4.isSelectable = false
        missionStatementTextView_4.adjustsFontForContentSizeCategory = false
        missionStatementTextView_4.attributedText = missionStatementTextView_4.attribute(this: onboardingMissionStatements[3], font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false), mainColor: fontColor, subColor: appThemeColor, subStrings: ["notifications","entire process","access","security","reliability","communication"])
        missionStatementTextView_4.setAttributedTextLineSpacing(lineSpacing: 5)
        missionStatementTextView_4.setAttributedTextAlignment(alignment: .center)
        missionStatementTextView_4.textContainerInset = UIEdgeInsets(top: 20, left: 5, bottom: 20, right: 5)
        missionStatementTextView_4.sizeToFit()
        
        let shadowView_4 = ShadowView(subview: missionStatementTextView_4, shadowColor: appThemeColor, shadowRadius: 1, shadowOpacity: 1)
        shadowView_4.frame.origin.x = onboardingTransitionView.frame.width/2 - shadowView_4.frame.width/2
        shadowView_4.setShadowOffset(shadowOffset: CGSize(width: 0, height: 2))
        missionStatementTextView_4.frame.origin = .zero
        
        containerView_4.addSubview(animationView_4)
        containerView_4.addSubview(slideTitle_4)
        containerView_4.addSubview(shadowView_4)
        /** Cell 4*/
        /** Cell 5*/
        let containerView_5 = UIView()
        containerView_5.frame.size = onboardingViewSize
        
        let animationView_5 = AnimationView.init(name: "73132-delivery-boy")
        animationView_5.frame.size = CGSize(width: animationViewSize, height: animationViewSize)
        animationView_5.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - animationView_5.frame.width/2, y: onboardingTransitionView.frame.height/2 - (animationView_5.frame.height * 0.9))
        
        animationView_5.animationSpeed = 1
        animationView_5.backgroundBehavior = .pauseAndRestore
        animationView_5.isExclusiveTouch = true
        animationView_5.shouldRasterizeWhenIdle = true
        animationView_5.contentMode = .scaleAspectFit
        animationView_5.isOpaque = false
        animationView_5.clipsToBounds = true
        animationView_5.backgroundColor = .clear
        animationView_5.loopMode = .loop
        animationView_5.clipsToBounds = false
        
        animationView_5.play(completion: nil)
        
        /** Title of the slide being presented*/
        let slideTitle_5 = UILabel(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: animationView_5.frame.maxY, width: onboardingTransitionView.frame.width * 0.9, height: 40))
        slideTitle_5.adjustsFontSizeToFitWidth = true
        slideTitle_5.adjustsFontForContentSizeCategory = true
        slideTitle_5.font = getCustomFont(name: .Ubuntu_bold, size: 25, dynamicSize: true)
        slideTitle_5.textColor = appThemeColor
        slideTitle_5.text = onboardingSlideTitles[4]
        slideTitle_5.textAlignment = .center
        slideTitle_5.shadowColor = appThemeColor.darker
        
        /** The goal of this slide*/
        let missionStatementTextView_5 = AccessibleTextView(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: slideTitle_5.frame.maxY + slideTitle_5.frame.height/4, width: onboardingTransitionView.frame.width * 0.9, height: onboardingTransitionView.frame.height * 0.2), presentingViewController: self, useContextMenu: false)
        missionStatementTextView_5.clipsToBounds = true
        missionStatementTextView_5.layer.cornerRadius = 20
        missionStatementTextView_5.backgroundColor = bgColor
        missionStatementTextView_5.showsVerticalScrollIndicator = true
        switch darkMode{
        case true:
            missionStatementTextView_5.backgroundColor = .black
            missionStatementTextView_5.indicatorStyle = .black
        case false:
            missionStatementTextView_5.indicatorStyle = .white
        }
        missionStatementTextView_5.isSelectable = false
        missionStatementTextView_5.adjustsFontForContentSizeCategory = false
        missionStatementTextView_5.attributedText = missionStatementTextView_5.attribute(this: onboardingMissionStatements[4], font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false), mainColor: fontColor, subColor: appThemeColor, subStrings: ["delivery directly to you","pay online","next day","same day"])
        /** Note: including the exclamation mark in the substring causes the textview in the reader view controller to use the subcolor as its main text color*/
        missionStatementTextView_5.setAttributedTextLineSpacing(lineSpacing: 5)
        missionStatementTextView_5.setAttributedTextAlignment(alignment: .center)
        missionStatementTextView_5.textContainerInset = UIEdgeInsets(top: 20, left: 5, bottom: 20, right: 5)
        missionStatementTextView_5.sizeToFit()
        
        let shadowView_5 = ShadowView(subview: missionStatementTextView_5, shadowColor: appThemeColor, shadowRadius: 1, shadowOpacity: 1)
        shadowView_5.frame.origin.x = onboardingTransitionView.frame.width/2 - shadowView_5.frame.width/2
        shadowView_5.setShadowOffset(shadowOffset: CGSize(width: 0, height: 2))
        missionStatementTextView_5.frame.origin = .zero
        
        containerView_5.addSubview(animationView_5)
        containerView_5.addSubview(slideTitle_5)
        containerView_5.addSubview(shadowView_5)
        /** Cell 5*/
        /** Cell 6*/
        let containerView_6 = UIView()
        containerView_6.frame.size = onboardingViewSize
        containerView_6.backgroundColor = appThemeColor
        
        maskedHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: onboardingTransitionView.frame.width, height: onboardingTransitionView.frame.height * 0.25))
        maskedHeaderView.backgroundColor = UIColor.clear
        
        let maskedBodyView = UIView(frame: CGRect(x: 0, y: maskedHeaderView.frame.maxY, width: onboardingTransitionView.frame.width, height: onboardingTransitionView.frame.height))
        maskedBodyView.backgroundColor = bgColor
        
        /** View that contains a masked UIView with a clear background and a full height UIView below it, this gives off the illusion that the two UIViews are one view with a curved top*/
        onboardingFinalSlideTransitionView = UIView(frame: CGRect(x: 0, y: -maskedHeaderView.frame.height, width: onboardingTransitionView.frame.width, height: maskedBodyView.frame.height + maskedHeaderView.frame.height))
        onboardingFinalSlideTransitionView.backgroundColor = UIColor.clear
        onboardingFinalSlideTransitionView.addSubview(maskedHeaderView)
        onboardingFinalSlideTransitionView.addSubview(maskedBodyView)
        
        onboardingLogoImageView = UIImageView(frame: CGRect(x: 0, y: view.safeAreaInsets.top + 10, width: onboardingTransitionView.frame.width, height: onboardingTransitionView.frame.height * 0.15))
        onboardingLogoImageView.contentMode = .scaleAspectFit
        onboardingLogoImageView.image = UIImage(named: "Basin Logo White")
        onboardingLogoImageView.backgroundColor = appThemeColor
        onboardingLogoImageView.clipsToBounds = true
        onboardingLogoImageView.tintColor = fontColor
        
        let curvedPath = UIBezierPath()
        curvedPath.move(to: CGPoint(x: maskedHeaderView.frame.minX, y: maskedHeaderView.frame.maxY))
        curvedPath.addQuadCurve(to: CGPoint(x: maskedHeaderView.frame.maxX, y: maskedHeaderView.frame.maxY), controlPoint: CGPoint(x: maskedHeaderView.frame.width/2, y: maskedHeaderView.frame.maxY * 0.7))
        curvedPath.close()
        
        /** Curved mask displayed over the image for aesthetics*/
        let mask = CAShapeLayer()
        mask.path = curvedPath.cgPath
        mask.fillColor = bgColor.cgColor
        mask.strokeColor = bgColor.cgColor
        mask.strokeEnd = 1
        mask.shadowColor = UIColor.darkGray.cgColor
        mask.shadowRadius = 10
        mask.shadowOpacity = 1
        mask.masksToBounds = false
        mask.shadowOffset = CGSize(width: 0, height: 2)
        mask.shadowPath = curvedPath.cgPath
        
        maskedHeaderView.layer.addSublayer(mask)
        
        lastSlideContentContainer = UIView(frame: containerView_6.frame)
        lastSlideContentContainer.backgroundColor = UIColor.clear
        
        let animationView_6 = AnimationView.init(name: "92770-balcony-hang")
        animationView_6.frame.size = CGSize(width: animationViewSize, height: animationViewSize)
        animationView_6.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - animationView_6.frame.width/2, y: onboardingTransitionView.frame.height/2 - (animationView_6.frame.height * 0.9))
        
        animationView_6.animationSpeed = 1
        animationView_6.backgroundBehavior = .pauseAndRestore
        animationView_6.isExclusiveTouch = true
        animationView_6.shouldRasterizeWhenIdle = true
        animationView_6.contentMode = .scaleAspectFill
        animationView_6.isOpaque = false
        animationView_6.clipsToBounds = true
        animationView_6.backgroundColor = .clear
        animationView_6.loopMode = .loop
        animationView_6.clipsToBounds = false
        
        animationView_6.play(completion: nil)
        
        /** Title of the slide being presented*/
        let slideTitle_6 = UILabel(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: animationView_6.frame.maxY, width: onboardingTransitionView.frame.width * 0.9, height: 40))
        slideTitle_6.adjustsFontSizeToFitWidth = true
        slideTitle_6.adjustsFontForContentSizeCategory = true
        slideTitle_6.font = getCustomFont(name: .Ubuntu_bold, size: 25, dynamicSize: true)
        slideTitle_6.textColor = appThemeColor
        slideTitle_6.text = onboardingSlideTitles[5]
        slideTitle_6.textAlignment = .center
        slideTitle_6.shadowColor = appThemeColor.darker
        
        /** The goal of this slide*/
        let missionStatementTextView_6 = AccessibleTextView(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: slideTitle_6.frame.maxY + slideTitle_6.frame.height/4, width: onboardingTransitionView.frame.width * 0.9, height: onboardingTransitionView.frame.height * 0.2), presentingViewController: self, useContextMenu: false)
        missionStatementTextView_6.clipsToBounds = true
        missionStatementTextView_6.layer.cornerRadius = 20
        missionStatementTextView_6.backgroundColor = bgColor
        missionStatementTextView_6.showsVerticalScrollIndicator = true
        switch darkMode{
        case true:
            missionStatementTextView_6.backgroundColor = .black
            missionStatementTextView_6.indicatorStyle = .black
        case false:
            missionStatementTextView_6.indicatorStyle = .white
        }
        missionStatementTextView_6.isSelectable = false
        missionStatementTextView_6.adjustsFontForContentSizeCategory = false
        missionStatementTextView_6.attributedText = missionStatementTextView_6.attribute(this: onboardingMissionStatements[5], font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false), mainColor: fontColor, subColor: appThemeColor, subStrings: ["\"Clean laundry peace of mind\"","promise","experience","existence"])
        missionStatementTextView_6.setAttributedTextLineSpacing(lineSpacing: 5)
        missionStatementTextView_6.setAttributedTextAlignment(alignment: .center)
        
        missionStatementTextView_6.textContainerInset = UIEdgeInsets(top: 20, left: 5, bottom: 20, right: 5)
        missionStatementTextView_6.sizeToFit()
        
        let shadowView_6 = ShadowView(subview: missionStatementTextView_6, shadowColor: appThemeColor, shadowRadius: 1, shadowOpacity: 1)
        shadowView_6.frame.origin.x = onboardingTransitionView.frame.width/2 - shadowView_6.frame.width/2
        shadowView_6.setShadowOffset(shadowOffset: CGSize(width: 0, height: 2))
        missionStatementTextView_6.frame.origin = .zero
        
        containerView_6.addSubview(onboardingLogoImageView)
        containerView_6.addSubview(onboardingFinalSlideTransitionView)
        lastSlideContentContainer.addSubview(animationView_6)
        lastSlideContentContainer.addSubview(slideTitle_6)
        lastSlideContentContainer.addSubview(shadowView_6)
        containerView_6.addSubview(lastSlideContentContainer)
        /** Cell 6*/
        
        onboardingCollectionViewCells.append(containerView_1)
        onboardingCollectionViewCells.append(containerView_2)
        onboardingCollectionViewCells.append(containerView_3)
        onboardingCollectionViewCells.append(containerView_4)
        onboardingCollectionViewCells.append(containerView_5)
        onboardingCollectionViewCells.append(containerView_6)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        /** Specify item size in order to allow the collectionview to encompass all of them*/
        layout.itemSize = onboardingViewSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        onboardingCollectionView = UICollectionView(frame: CGRect(x: 0, y: onboardingTransitionView.frame.height/2 - (onboardingViewSize.height)/2, width: onboardingViewSize.width, height: onboardingViewSize.height), collectionViewLayout: layout)
        onboardingCollectionView.register(onboardingCollectionViewCell.self, forCellWithReuseIdentifier: onboardingCollectionViewCell.identifier)
        onboardingCollectionView.delegate = self
        onboardingCollectionView.backgroundColor = UIColor.clear
        onboardingCollectionView.isPagingEnabled = true
        onboardingCollectionView.dataSource = self
        onboardingCollectionView.frame.origin = CGPoint(x: 0, y: 0)
        onboardingCollectionView.showsVerticalScrollIndicator = false
        onboardingCollectionView.showsHorizontalScrollIndicator = false
        onboardingCollectionView.isExclusiveTouch = true
        
        onboardingCollectionView.contentSize = CGSize(width: onboardingTransitionView.frame.width * CGFloat(onboardingCollectionViewCount), height: onboardingViewSize.height)
        
        onboardingTransitionView.addSubview(onboardingCollectionView)
        self.view.addSubview(onboardingTransitionView)
        self.view.addSubview(onboardingPageControl)
        self.view.addSubview(onboardingNextButton)
        self.view.addSubview(onboardingPreviousButton)
        self.view.addSubview(onboardingSkipButton)
        self.view.addSubview(getStartedButton)
        
        /** Positioning navigation elements at the bottom of the screen*/
        onboardingPageControl.frame.origin = CGPoint(x: view.frame.width/2 - onboardingPageControl.frame.width/2, y: onboardingCollectionView.frame.maxY)
        
        onboardingSkipButton.frame.origin = CGPoint(x: onboardingSkipButton.frame.width/2, y: onboardingSkipButton.frame.height)
        onboardingSkipButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        onboardingNextButton.center.y = onboardingPageControl.center.y
        onboardingNextButton.frame.origin.x = onboardingPageControl.frame.maxX
        
        onboardingPreviousButton.center.y = onboardingPageControl.center.y
        onboardingPreviousButton.frame.origin.x = onboardingPageControl.frame.minX - onboardingPreviousButton.frame.width
        
        getStartedButton.frame.origin = CGPoint(x: view.frame.width/2 - getStartedButton.frame.width/2, y: onboardingCollectionView.frame.maxY)
        getStartedButton.alpha = 0
        getStartedButton.isEnabled = false
        
        /** Add a delay because the collection view scrolls through all the animation views before the user can see them in order to load them into memory and make a smoother experience when the user eventually views them manually, if the user has completed the onboarding process prior then speed up the transition view animation as the sign up sign in screen will be presented instead of the onboarding collection view*/
        var primingDelay: CGFloat = 1
        if didUserCompletedOnboarding() == true{
            primingDelay = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + primingDelay){[self] in
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                onboardingTransitionView.frame.origin = CGPoint(x: 0, y: 0)
                onboardingPageControl.alpha = 1
                onboardingNextButton.alpha = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                    onboardingSkipButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                    onboardingSkipButton.isEnabled = true
                }
            }
        }
    }
    
    /** Display the sign up and sign in UI when the user presses the get started button*/
    func displayStartScreen(){
        let greetingLabel = UILabel(frame: CGRect(x: onboardingTransitionView.frame.width/2 - (onboardingTransitionView.frame.width * 0.9)/2, y: maskedHeaderView.frame.maxY, width: onboardingTransitionView.frame.width * 0.9, height: onboardingTransitionView.frame.height * 0.2))
        greetingLabel.adjustsFontSizeToFitWidth = true
        greetingLabel.adjustsFontForContentSizeCategory = false
        greetingLabel.font = getCustomFont(name: .Bungee_Regular, size: 30, dynamicSize: false)
        greetingLabel.textColor = appThemeColor
        greetingLabel.text = "Basin"
        greetingLabel.textAlignment = .center
        /**
         greetingLabel.layer.shadowColor = appThemeColor.cgColor
         greetingLabel.layer.shadowRadius = 2
         greetingLabel.layer.shadowOpacity = 1.0
         greetingLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
         */
        greetingLabel.layer.masksToBounds = false
        greetingLabel.backgroundColor = .clear
        greetingLabel.sizeToFit()
        greetingLabel.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - greetingLabel.frame.width/2, y: maskedHeaderView.frame.maxY)
        
        let welcomeLottieAnimation = AnimationView.init(name: "manRelaxingOnCouch")
        welcomeLottieAnimation.frame.size = CGSize(width: view.frame.width * 0.5, height: view.frame.width * 0.5)
        welcomeLottieAnimation.animationSpeed = 1
        welcomeLottieAnimation.isExclusiveTouch = true
        welcomeLottieAnimation.shouldRasterizeWhenIdle = true
        welcomeLottieAnimation.contentMode = .scaleAspectFill
        welcomeLottieAnimation.isOpaque = false
        welcomeLottieAnimation.clipsToBounds = true
        welcomeLottieAnimation.backgroundColor = .clear
        welcomeLottieAnimation.loopMode = .loop
        welcomeLottieAnimation.backgroundBehavior = .pauseAndRestore
        welcomeLottieAnimation.clipsToBounds = false
        welcomeLottieAnimation.play(completion: nil)
        welcomeLottieAnimation.frame.origin = CGPoint(x: view.frame.width/2 - welcomeLottieAnimation.frame.width/2, y: greetingLabel.frame.maxY)
        
        /** Legal jargon*/
        let advisoryTextView = UITextView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.8, height: 40))
        advisoryTextView.backgroundColor = .clear
        advisoryTextView.adjustsFontForContentSizeCategory = false
        
        let attributedString = attribute(this: "By using this platform you agree to our \nTerms of Service", font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: false), subFont: getCustomFont(name: .Ubuntu_bold, size: 14, dynamicSize: false), mainColor: fontColor, subColor: appThemeColor, subString: "\nTerms of Service")
        /** Don't include the \n in the mutable string range because the layout engine will glitch with the preview*/
        attributedString.addAttribute(.link, value: "app://TOS", range: attributedString.mutableString.range(of: "Terms of Service"))
        advisoryTextView.attributedText = attributedString
        
        /** Disable dragging for the user*/
        advisoryTextView.textDragInteraction!.isEnabled = false
        advisoryTextView.linkTextAttributes = [.foregroundColor: appThemeColor]
        advisoryTextView.textAlignment = .center
        advisoryTextView.isSelectable = true
        advisoryTextView.isEditable = false
        advisoryTextView.isScrollEnabled = false
        advisoryTextView.delegate = self
        advisoryTextView.sizeToFit()
        advisoryTextView.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - advisoryTextView.frame.width/2, y: view.frame.maxY - (advisoryTextView.frame.height * 1.5))
        
        let signInButton = UIButton()
        signInButton.frame.size.height = 50
        signInButton.frame.size.width = onboardingTransitionView.frame.width * 0.8
        signInButton.backgroundColor = appThemeColor
        signInButton.tintColor = .white
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.layer.cornerRadius = signInButton.frame.height/2
        signInButton.isExclusiveTouch = true
        signInButton.castDefaultShadow()
        signInButton.setTitleColor(UIColor.white, for: .normal)
        signInButton.titleLabel?.adjustsFontForContentSizeCategory = true
        signInButton.titleLabel?.adjustsFontSizeToFitWidth = true
        signInButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 20, dynamicSize: true)
        signInButton.layer.shadowColor = appThemeColor.darker.cgColor
        signInButton.layer.shadowRadius = 1
        signInButton.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - signInButton.frame.width/2, y: welcomeLottieAnimation.frame.maxY)
        signInButton.addTarget(self, action: #selector(signInButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: signInButton)
        
        let signUpButton = UIButton()
        signUpButton.frame.size.height = 50
        signUpButton.frame.size.width = onboardingTransitionView.frame.width * 0.8
        switch darkMode {
        case true:
            signUpButton.backgroundColor = bgColor.darker
        case false:
            signUpButton.backgroundColor = bgColor
        }
        signUpButton.tintColor = .white
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.layer.cornerRadius = signUpButton.frame.height/2
        signUpButton.isExclusiveTouch = true
        signUpButton.castDefaultShadow()
        signUpButton.setTitleColor(appThemeColor, for: .normal)
        signUpButton.titleLabel?.adjustsFontForContentSizeCategory = true
        signUpButton.titleLabel?.adjustsFontSizeToFitWidth = true
        signUpButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 20, dynamicSize: true)
        signUpButton.layer.shadowColor = appThemeColor.darker.cgColor
        signUpButton.layer.shadowRadius = 1
        signUpButton.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - signUpButton.frame.width/2, y: signInButton.frame.maxY + signUpButton.frame.height/2)
        signUpButton.addTarget(self, action: #selector(signUpButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: signUpButton)
        
        let forgotPasswordButton = UIButton()
        forgotPasswordButton.frame.size.height = 50
        forgotPasswordButton.frame.size.width = onboardingTransitionView.frame.width * 0.8
        forgotPasswordButton.backgroundColor = UIColor.clear
        forgotPasswordButton.tintColor = .white
        forgotPasswordButton.setTitle("Forgot your password?", for: .normal)
        forgotPasswordButton.isExclusiveTouch = true
        forgotPasswordButton.setTitleColor(appThemeColor, for: .normal)
        forgotPasswordButton.titleLabel?.adjustsFontForContentSizeCategory = true
        forgotPasswordButton.titleLabel?.adjustsFontSizeToFitWidth = true
        forgotPasswordButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        forgotPasswordButton.titleLabel?.shadowColor = appThemeColor.darker
        forgotPasswordButton.frame.origin = CGPoint(x: onboardingTransitionView.frame.width/2 - forgotPasswordButton.frame.width/2, y: signUpButton.frame.maxY)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordButtonPressed), for: .touchUpInside)
        
        /** Round buttons on the side of the main buttons for aesthetics*/
        var imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        var image = UIImage(systemName: "lock.circle.fill", withConfiguration: imageConfiguration)
        let signInRoundButton = UIButton()
        signInRoundButton.frame.size.height = signInButton.frame.height * 1.25
        signInRoundButton.frame.size.width = signInRoundButton.frame.size.height
        signInRoundButton.backgroundColor = appThemeColor
        signInRoundButton.tintColor = .white
        signInRoundButton.setImage(image, for: .normal)
        signInRoundButton.imageView?.contentMode = .scaleAspectFit
        signInRoundButton.layer.cornerRadius = signInRoundButton.frame.height/2
        signInRoundButton.isExclusiveTouch = true
        signInRoundButton.castDefaultShadow()
        signInRoundButton.layer.shadowColor = appThemeColor.darker.cgColor
        signInRoundButton.isEnabled = true
        signInRoundButton.isUserInteractionEnabled = false
        signInRoundButton.frame.origin = CGPoint(x: signInButton.frame.minX, y: 0)
        signInRoundButton.center.y = signInButton.center.y
        signInRoundButton.addTarget(self, action: #selector(signInButtonPressed), for: .touchUpInside)
        
        imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        image = UIImage(systemName: "person.crop.circle.badge.plus.fill", withConfiguration: imageConfiguration)
        let signUpRoundButton = UIButton()
        signUpRoundButton.frame.size.height = signUpButton.frame.height * 1.25
        signUpRoundButton.frame.size.width = signUpRoundButton.frame.size.height
        switch darkMode {
        case true:
            signUpRoundButton.backgroundColor = bgColor.darker
        case false:
            signUpRoundButton.backgroundColor = bgColor
        }
        signUpRoundButton.tintColor = appThemeColor
        signUpRoundButton.setImage(image, for: .normal)
        signUpRoundButton.imageView?.contentMode = .scaleAspectFit
        signUpRoundButton.layer.cornerRadius = signUpRoundButton.frame.height/2
        signUpRoundButton.isExclusiveTouch = true
        signUpRoundButton.castDefaultShadow()
        signUpRoundButton.layer.shadowColor = appThemeColor.darker.cgColor
        signUpRoundButton.isEnabled = true
        signUpRoundButton.isUserInteractionEnabled = false
        signUpRoundButton.frame.origin = CGPoint(x: signUpButton.frame.minX, y: 0)
        signUpRoundButton.center.y = signUpButton.center.y
        signUpRoundButton.addTarget(self, action: #selector(signUpButtonPressed), for: .touchUpInside)
        
        /** Fancy animations*/
        welcomeLottieAnimation.transform = CGAffineTransform(translationX: -self.view.frame.width, y: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
                welcomeLottieAnimation.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }
        
        signInRoundButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        signUpRoundButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        signInButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        signUpButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        forgotPasswordButton.alpha = 0
        greetingLabel.alpha = 0
        advisoryTextView.alpha = 0
        
        UIView.animate(withDuration: 1, delay: 0.05){
            greetingLabel.alpha = 1
        }
        UIView.animate(withDuration: 1, delay: 0.3){
            forgotPasswordButton.alpha = 1
            advisoryTextView.alpha = 1
        }
        UIView.animate(withDuration: 0.5, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            signInButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            signUpButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 1, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            signInRoundButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            signUpRoundButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** Specify the frame for the imageview so that it's persistent between forward and backward traversal at this point in the onboarding process*/
        UIView.animate(withDuration: 1, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            onboardingLogoImageView.frame = CGRect(x: 0, y: view.safeAreaInsets.top + 10, width: onboardingTransitionView.frame.width, height: onboardingTransitionView.frame.height * 0.15)
        }
        
        /** Make the background match the current scene*/
        self.onboardingTransitionView.backgroundColor = appThemeColor
        
        view.addSubview(onboardingLogoImageView)
        view.addSubview(onboardingFinalSlideTransitionView)
        onboardingFinalSlideTransitionView.addSubview(greetingLabel)
        onboardingFinalSlideTransitionView.addSubview(welcomeLottieAnimation)
        onboardingFinalSlideTransitionView.addSubview(signInButton)
        onboardingFinalSlideTransitionView.addSubview(signInRoundButton)
        onboardingFinalSlideTransitionView.addSubview(signUpButton)
        onboardingFinalSlideTransitionView.addSubview(signUpRoundButton)
        onboardingFinalSlideTransitionView.addSubview(forgotPasswordButton)
        onboardingFinalSlideTransitionView.addSubview(advisoryTextView)
        
        onboardingCollectionView.removeFromSuperview()
        
        onboardingFinalSlideMiscViews.append(greetingLabel)
        onboardingFinalSlideMiscViews.append(welcomeLottieAnimation)
        onboardingFinalSlideMiscViews.append(signInButton)
        onboardingFinalSlideMiscViews.append(signInRoundButton)
        onboardingFinalSlideMiscViews.append(signUpButton)
        onboardingFinalSlideMiscViews.append(signUpRoundButton)
        onboardingFinalSlideMiscViews.append(forgotPasswordButton)
        onboardingFinalSlideMiscViews.append(advisoryTextView)
    }
    
    /** Displays the appropriate UI associated with the sign in process**/
    func displaySignInFlow(){
        /** Reset arrays*/
        signInWithButtons.removeAll()
        disposableViews.removeAll()
        
        /** Defaults*/
        usePasswordSecurity = true
        userNameFieldKeyboardType = userNameFieldKeyboardTypes[0]
        
        /** Ensure that all content is painted behind this view*/
        onboardingFinalSlideTransitionView.layer.zPosition = 2
        
        /** Hide the transitional get started UIView and remove it from the hierarchy*/
        UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            onboardingFinalSlideTransitionView.frame.origin.y = view.frame.maxY
        }
        
        /** Animate the views previously added to the screen fading out and then remove them from memory*/
        for view in onboardingFinalSlideMiscViews{
            UIView.animate(withDuration: 1, delay: 0){
                view.alpha = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                view.removeFromSuperview()
            }
        }
        onboardingFinalSlideMiscViews.removeAll()
        
        /** Enlarge the imageview and shift its position towards the centerfold to refocus the user's attention*/
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            onboardingLogoImageView.frame = CGRect(x: 0, y: view.safeAreaInsets.top + 10, width: onboardingTransitionView.frame.width, height: onboardingTransitionView.frame.height * 0.2)
        }
        
        let imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        let image = UIImage(systemName: "arrow.backward", withConfiguration: imageConfiguration)
        
        signInBackButton = UIButton()
        signInBackButton.frame.size.height = 40
        signInBackButton.frame.size.width = signInBackButton.frame.size.height
        signInBackButton.backgroundColor = .white
        signInBackButton.tintColor = appThemeColor
        signInBackButton.setImage(image, for: .normal)
        signInBackButton.layer.cornerRadius = signInBackButton.frame.height/2
        signInBackButton.isExclusiveTouch = true
        signInBackButton.castDefaultShadow()
        signInBackButton.layer.shadowColor = appThemeColor.darker.cgColor
        signInBackButton.addTarget(self, action: #selector(signInBackButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: signInBackButton)
        signInBackButton.isEnabled = false
        signInBackButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        DispatchQueue.main.async{[self] in
            signInBackButton.frame.origin = CGPoint(x: signInBackButton.frame.width/2, y: statusBarHeight + signInBackButton.frame.height/2)
        }
        
        /** Scale up animation*/
        UIView.animate(withDuration: 1, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            signInBackButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){ [self] in
            signInBackButton.isEnabled = true
        }
        
        view.addSubview(signInBackButton)
        
        /** Display the sign in UI*/
        /** Segmented control for navigating between the 3 sign in setups*/
        let scSize = CGSize(width: view.frame.width/3, height: 30)
        signInScreenSegmentedControl = UISegmentedControl(frame: CGRect(origin: CGPoint(x: view.frame.width/2 - scSize.width/2, y: onboardingLogoImageView.frame.maxY + scSize.height/2), size: scSize))
        signInScreenSegmentedControl.selectedSegmentTintColor = appThemeColor
        signInScreenSegmentedControl.tintColor = .white
        signInScreenSegmentedControl.backgroundColor = .white
        signInScreenSegmentedControl.isExclusiveTouch = true
        signInScreenSegmentedControl.layer.zPosition = 1
        
        /** Insert the segments for the 3 different portals*/
        /** The actions for the segmented controls*/
        let displayCustomerSignInPortalAction = UIAction(image: UIImage(systemName: "figure.wave.circle.fill")){ [self] action in
            displayCustomerSignInPortal(animated: true)
            
            if usernameEmailTextfield.text != "" && passwordTextField.text != "" && employeeIDTextField.text != "" && currentSignInPortal == 1 || currentSignInPortal == 2{
                enableSignInButton()
            }
            else if usernameEmailTextfield.text != "" && passwordTextField.text != "" && currentSignInPortal == 0{
                enableSignInButton()
            }
            else{
                disableSignInButton()
            }
        }
        let displayBusinessClientSignInPortalAction = UIAction(image: UIImage(systemName: "building.2.crop.circle.fill")){ [self] action in
            displayBusinessClientSignInPortal(animated: true)
            
            if usernameEmailTextfield.text != "" && passwordTextField.text != "" && employeeIDTextField.text != "" && currentSignInPortal == 1 || currentSignInPortal == 2{
                enableSignInButton()
            }
            else if usernameEmailTextfield.text != "" && passwordTextField.text != "" && currentSignInPortal == 0{
                enableSignInButton()
            }
            else{
                disableSignInButton()
            }
        }
        let displayDriverSignInPortalAction = UIAction(image: UIImage(systemName: "car.circle.fill")){ [self] action in
            displayDriverSignInPortal(animated: true)
            
            if usernameEmailTextfield.text != "" && passwordTextField.text != "" && employeeIDTextField.text != "" && currentSignInPortal == 1{
                enableSignInButton()
            }
            else if usernameEmailTextfield.text != "" && passwordTextField.text != "" && employeeIDTextField.text != "" && currentSignInPortal == 2{
                enableSignInButton()
            }
            else if usernameEmailTextfield.text != "" && passwordTextField.text != "" && currentSignInPortal == 0{
                enableSignInButton()
            }
            else{
                disableSignInButton()
            }
        }
        
        /** Customer Portal*/
        signInScreenSegmentedControl.insertSegment(action: displayCustomerSignInPortalAction, at: 0, animated: true)
        
        /** Business Portal*/
        signInScreenSegmentedControl.insertSegment(action: displayBusinessClientSignInPortalAction, at: 1, animated: true)
        
        /** Driver Portal*/
        signInScreenSegmentedControl.insertSegment(action: displayDriverSignInPortalAction, at: 2, animated: true)
        
        /** Default segment is 0, user sign in portal*/
        signInScreenSegmentedControl.selectedSegmentIndex = 0
        
        let labelSize = CGSize(width: view.frame.width * 0.8, height: 40)
        signInPortalLabel = UILabel(frame: CGRect(x: view.frame.width/2 - labelSize.width/2, y: signInScreenSegmentedControl.frame.maxY + 10, width: labelSize.width, height: labelSize.height))
        signInPortalLabel.font = getCustomFont(name: .Ubuntu_bold, size: 20, dynamicSize: true)
        signInPortalLabel.adjustsFontForContentSizeCategory = true
        signInPortalLabel.adjustsFontSizeToFitWidth = true
        signInPortalLabel.textColor = .white
        signInPortalLabel.shadowColor = .lightGray
        signInPortalLabel.shadowOffset = CGSize(width: 0, height: 2)
        signInPortalLabel.text = signInPortalTitles[0]
        signInPortalLabel.textAlignment = .center
        
        /** Username / Email Textfield used to authenticate either the username or email associated with the account credentials*/
        usernameEmailTextfield = UITextField()
        usernameEmailTextfield.toolbarPlaceholder = "Username | Email | Phone number"
        usernameEmailTextfield.textContentType = .username
        usernameEmailTextfield.frame.size.height = 50
        usernameEmailTextfield.frame.size.width = view.frame.width * 0.9
        usernameEmailTextfield.tintColor = appThemeColor
        usernameEmailTextfield.backgroundColor = .white
        usernameEmailTextfield.textColor = .black
        usernameEmailTextfield.layer.cornerRadius = usernameEmailTextfield.frame.height/2
        usernameEmailTextfield.adjustsFontForContentSizeCategory = true
        usernameEmailTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        usernameEmailTextfield.attributedPlaceholder = NSAttributedString(string:"Username, Email, or Phone Number", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        usernameEmailTextfield.frame.origin = CGPoint(x: view.frame.width/2 - usernameEmailTextfield.frame.width/2, y: signInPortalLabel.frame.maxY + 10)
        
        /** Custom overlay imageview for the textfield*/
        /** Container for the image view*/
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: usernameEmailTextfield.frame.height, height: usernameEmailTextfield.frame.height))
        
        let usernameTextFieldLeftButton = UIButton()
        usernameTextFieldLeftButton.setImage(UIImage(systemName: "person.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        
        let usernameTextFieldLeftButtonPressed = UIAction(){ [self] action in
            lightHaptic()
            
            if userNameFieldKeyboardType == userNameFieldKeyboardTypes[0]{
                UIView.transition(with: usernameTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{
                    usernameTextFieldLeftButton.setImage(UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                })
                userNameFieldKeyboardType = userNameFieldKeyboardTypes[1]
                usernameEmailTextfield.keyboardType = .emailAddress
                usernameEmailTextfield.textContentType = .emailAddress
                
                /** Refresh the keyboard while editing*/
                DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
                    usernameEmailTextfield.resignFirstResponder()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){[self] in
                    usernameEmailTextfield.becomeFirstResponder()
                }
            }else if userNameFieldKeyboardType == userNameFieldKeyboardTypes[1]{
                UIView.transition(with: usernameTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{
                    usernameTextFieldLeftButton.setImage(UIImage(systemName: "phone.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                })
                
                userNameFieldKeyboardType = userNameFieldKeyboardTypes[2]
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[self] in
                    usernameEmailTextfield.keyboardType = .phonePad
                    usernameEmailTextfield.textContentType = .telephoneNumber
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
                    usernameEmailTextfield.resignFirstResponder()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){[self] in
                    usernameEmailTextfield.becomeFirstResponder()
                }
            }else if userNameFieldKeyboardType == userNameFieldKeyboardTypes[2]{
                UIView.transition(with: usernameTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{
                    usernameTextFieldLeftButton.setImage(UIImage(systemName: "person.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                })
                
                userNameFieldKeyboardType = userNameFieldKeyboardTypes[0]
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[self] in
                    usernameEmailTextfield.keyboardType = .asciiCapable
                    usernameEmailTextfield.textContentType = .username
                }
                
                /** Refresh the keyboard while editing*/
                DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
                    usernameEmailTextfield.resignFirstResponder()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){[self] in
                    usernameEmailTextfield.becomeFirstResponder()
                }
            }
            else{
                UIView.transition(with: usernameTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{
                    usernameTextFieldLeftButton.setImage(UIImage(systemName: "person.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                })
                
                userNameFieldKeyboardType = userNameFieldKeyboardTypes[0]
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[self] in
                    usernameEmailTextfield.keyboardType = .emailAddress
                    usernameEmailTextfield.textContentType = .emailAddress
                }
                
                /** Refresh the keyboard while editing*/
                DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
                    usernameEmailTextfield.resignFirstResponder()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){[self] in
                    usernameEmailTextfield.becomeFirstResponder()
                }
            }
        }
        
        usernameTextFieldLeftButton.addAction(usernameTextFieldLeftButtonPressed, for: .touchUpInside)
        usernameTextFieldLeftButton.frame.size = CGSize(width: usernameEmailTextfield.frame.height/2, height: usernameEmailTextfield.frame.height/2)
        usernameTextFieldLeftButton.frame.origin = CGPoint(x: paddingView.frame.width/2 - usernameTextFieldLeftButton.frame.width/2, y: paddingView.frame.height/2 - usernameTextFieldLeftButton.frame.height/2)
        usernameTextFieldLeftButton.backgroundColor = .white
        usernameTextFieldLeftButton.tintColor = appThemeColor
        usernameTextFieldLeftButton.layer.cornerRadius = usernameTextFieldLeftButton.frame.height/2
        usernameTextFieldLeftButton.contentMode = .scaleAspectFit
        usernameTextFieldLeftButton.clipsToBounds = true
        
        paddingView.addSubview(usernameTextFieldLeftButton)
        
        usernameEmailTextfield.leftView = paddingView
        usernameEmailTextfield.leftViewMode = .always
        
        /** Shadow properties*/
        usernameEmailTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        usernameEmailTextfield.layer.shadowOpacity = 0.25
        usernameEmailTextfield.layer.shadowRadius = 8
        usernameEmailTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        usernameEmailTextfield.layer.shadowPath = UIBezierPath(roundedRect: usernameEmailTextfield.bounds, cornerRadius: usernameEmailTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        usernameEmailTextfield.clipsToBounds = true
        usernameEmailTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        usernameEmailTextfield.borderStyle = .none
        usernameEmailTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        usernameEmailTextfield.layer.borderWidth = 1
        
        /** Lock Keyboard to only suitable characters*/
        usernameEmailTextfield.keyboardType = .asciiCapable
        usernameEmailTextfield.returnKeyType = .done
        usernameEmailTextfield.textAlignment = .left
        usernameEmailTextfield.delegate = self
        usernameEmailTextfield.autocorrectionType = .no
        
        passwordTextField = UITextField()
        passwordTextField.textContentType = .password
        passwordTextField.toolbarPlaceholder = "Password"
        passwordTextField.frame.size.height = 50
        passwordTextField.frame.size.width = view.frame.width * 0.9
        passwordTextField.tintColor = appThemeColor
        passwordTextField.backgroundColor = .white
        passwordTextField.textColor = .black
        passwordTextField.layer.cornerRadius = passwordTextField.frame.height/2
        passwordTextField.adjustsFontForContentSizeCategory = true
        passwordTextField.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.attributedPlaceholder = NSAttributedString(string:"Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        passwordTextField.frame.origin = CGPoint(x: view.frame.width/2 - passwordTextField.frame.width/2, y: usernameEmailTextfield.frame.maxY + 10)
        
        /** Lock Keyboard to only suitable characters*/
        passwordTextField.keyboardType = .asciiCapable
        passwordTextField.returnKeyType = .done
        passwordTextField.textAlignment = .left
        passwordTextField.delegate = self
        passwordTextField.autocorrectionType = .no
        
        /** Custom overlay imageview for the textfield*/
        /** Container for the image view*/
        let paddingView_2 = UIView(frame: CGRect(x: 0, y: 0, width: passwordTextField.frame.height, height: passwordTextField.frame.height))
        
        let passwordTextFieldLeftButton = UIButton()
        passwordTextFieldLeftButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        
        let passwordTextFieldLeftButtonPressed = UIAction(){ [self] action in
            lightHaptic()
            
            if usePasswordSecurity == true{
                UIView.transition(with: passwordTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{
                    passwordTextFieldLeftButton.setImage(UIImage(systemName: "lock.open.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                })
                usePasswordSecurity = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[self] in
                    passwordTextField.isSecureTextEntry = false
                }
            }else{
                UIView.transition(with: passwordTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{
                    passwordTextFieldLeftButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                })
                usePasswordSecurity = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[self] in
                    passwordTextField.isSecureTextEntry = true
                }
            }
        }
        
        passwordTextFieldLeftButton.addAction(passwordTextFieldLeftButtonPressed, for: .touchUpInside)
        
        passwordTextFieldLeftButton.frame.size = CGSize(width: passwordTextField.frame.height/2, height: passwordTextField.frame.height/2)
        passwordTextFieldLeftButton.frame.origin = CGPoint(x: paddingView_2.frame.width/2 - passwordTextFieldLeftButton.frame.width/2, y: paddingView_2.frame.height/2 - passwordTextFieldLeftButton.frame.height/2)
        passwordTextFieldLeftButton.backgroundColor = .white
        passwordTextFieldLeftButton.tintColor = appThemeColor
        passwordTextFieldLeftButton.layer.cornerRadius = passwordTextFieldLeftButton.frame.height/2
        passwordTextFieldLeftButton.contentMode = .scaleAspectFit
        passwordTextFieldLeftButton.clipsToBounds = true
        
        paddingView_2.addSubview(passwordTextFieldLeftButton)
        
        passwordTextField.leftView = paddingView_2
        passwordTextField.leftViewMode = .always
        
        /** Shadow properties*/
        passwordTextField.layer.shadowColor = UIColor.darkGray.cgColor
        passwordTextField.layer.shadowOpacity = 0.25
        passwordTextField.layer.shadowRadius = 8
        passwordTextField.layer.shadowOffset = CGSize(width: 0, height: 2)
        passwordTextField.layer.shadowPath = UIBezierPath(roundedRect: passwordTextField.bounds, cornerRadius: passwordTextField.layer.cornerRadius).cgPath
        
        /** Border properties*/
        passwordTextField.clipsToBounds = true
        passwordTextField.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        passwordTextField.borderStyle = .none
        passwordTextField.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        passwordTextField.layer.borderWidth = 1
        
        /** Text field for entering the employee ID of business clients users or drivers*/
        employeeIDTextField = UITextField()
        employeeIDTextField.textContentType = .organizationName
        employeeIDTextField.frame.size.height = 50
        employeeIDTextField.frame.size.width = view.frame.width * 0.9
        employeeIDTextField.tintColor = appThemeColor
        employeeIDTextField.backgroundColor = .white
        employeeIDTextField.textColor = .black
        employeeIDTextField.layer.cornerRadius = employeeIDTextField.frame.height/2
        employeeIDTextField.adjustsFontForContentSizeCategory = true
        employeeIDTextField.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        employeeIDTextField.isSecureTextEntry = true
        employeeIDTextField.attributedPlaceholder = NSAttributedString(string:"Business Client ID", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        employeeIDTextField.isHidden = true
        
        employeeIDTextField.frame.origin = CGPoint(x: view.frame.width/2 - employeeIDTextField.frame.width/2, y: passwordTextField.frame.maxY + 10)
        
        employeeIDTextField.transform = CGAffineTransform(translationX: -view.frame.width, y: 0)
        
        /** Lock Keyboard to only suitable characters*/
        employeeIDTextField.keyboardType = .asciiCapable
        employeeIDTextField.returnKeyType = .done
        employeeIDTextField.textAlignment = .left
        employeeIDTextField.delegate = self
        employeeIDTextField.autocorrectionType = .no
        
        /** Custom overlay imageview for the textfield*/
        /** Container for the image view*/
        let paddingView_3 = UIView(frame: CGRect(x: 0, y: 0, width: employeeIDTextField.frame.height, height: employeeIDTextField.frame.height))
        
        employeeIDTextFieldLeftButton = UIButton()
        
        switch currentSignInPortal{
        case 0:
            employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "b.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        case 1:
            employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "b.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        case 2:
            employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "d.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        default:
            employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "b.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        }
        
        let employeeIDTextFieldLeftButtonPressed = UIAction(){ [self] action in
            lightHaptic()
            
            if useEmployeeSecurity == true{
                switch currentSignInPortal{
                case 0:
                    break
                case 1:
                    UIView.transition(with: employeeIDTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{ [self] in
                        employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "b.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                    })
                case 2:
                    UIView.transition(with: employeeIDTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{ [self] in
                        employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "d.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                    })
                default:
                    break
                }
                useEmployeeSecurity = false
                
                /** Delay this or else the keyboard will glitch out*/
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[self] in
                    employeeIDTextField.isSecureTextEntry = false
                }
            }else{
                switch currentSignInPortal{
                case 0:
                    break
                case 1:
                    UIView.transition(with: employeeIDTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{ [self] in
                        employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "b.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                    })
                case 2:
                    UIView.transition(with: employeeIDTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{ [self] in
                        employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "d.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
                    })
                default:
                    break
                }
                useEmployeeSecurity = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){[self] in
                    employeeIDTextField.isSecureTextEntry = true
                }
            }
        }
        
        employeeIDTextFieldLeftButton.addAction(employeeIDTextFieldLeftButtonPressed, for: .touchUpInside)
        
        employeeIDTextFieldLeftButton.frame.size = CGSize(width: employeeIDTextField.frame.height/2, height: employeeIDTextField.frame.height/2)
        employeeIDTextFieldLeftButton.frame.origin = CGPoint(x: paddingView_3.frame.width/2 - employeeIDTextFieldLeftButton.frame.width/2, y: paddingView_3.frame.height/2 - employeeIDTextFieldLeftButton.frame.height/2)
        employeeIDTextFieldLeftButton.backgroundColor = .white
        employeeIDTextFieldLeftButton.tintColor = appThemeColor
        employeeIDTextFieldLeftButton.layer.cornerRadius = employeeIDTextFieldLeftButton.frame.height/2
        employeeIDTextFieldLeftButton.contentMode = .scaleAspectFit
        employeeIDTextFieldLeftButton.clipsToBounds = true
        
        paddingView_3.addSubview(employeeIDTextFieldLeftButton)
        
        employeeIDTextField.leftView = paddingView_3
        employeeIDTextField.leftViewMode = .always
        
        /** Shadow properties*/
        employeeIDTextField.layer.shadowColor = UIColor.darkGray.cgColor
        employeeIDTextField.layer.shadowOpacity = 0.25
        employeeIDTextField.layer.shadowRadius = 8
        employeeIDTextField.layer.shadowOffset = CGSize(width: 0, height: 2)
        employeeIDTextField.layer.shadowPath = UIBezierPath(roundedRect: employeeIDTextField.bounds, cornerRadius: employeeIDTextField.layer.cornerRadius).cgPath
        
        /** Border properties*/
        employeeIDTextField.clipsToBounds = true
        employeeIDTextField.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        employeeIDTextField.borderStyle = .none
        employeeIDTextField.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        employeeIDTextField.layer.borderWidth = 1
        
        /** Set keyboard appearances for textfields*/
        usernameEmailTextfield.keyboardAppearance = .light
        passwordTextField.keyboardAppearance = .light
        employeeIDTextField.keyboardAppearance = .light
        
        signInButton = UIButton()
        signInButton.frame.size.height = 50
        signInButton.frame.size.width = view.frame.width * 0.7
        signInButton.backgroundColor = .white
        signInButton.alpha = 0.5
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.setTitleColor(appThemeColor, for: .normal)
        signInButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        signInButton.contentHorizontalAlignment = .center
        signInButton.titleLabel?.adjustsFontSizeToFitWidth = true
        signInButton.titleLabel?.adjustsFontForContentSizeCategory = true
        signInButton.layer.cornerRadius = signInButton.frame.height/2
        signInButton.isExclusiveTouch = true
        signInButton.isEnabled = false
        signInButton.frame.origin = CGPoint(x: view.frame.width/2 - signInButton.frame.width/2, y: UIScreen.main.bounds.maxY - (signInButton.frame.height * 1.5))
        signInButton.castDefaultShadow()
        signInButton.addTarget(self, action: #selector(submitCredentials), for: .touchUpInside)
        addDynamicButtonGR(button: signInButton)
        
        let labelSize_2 = CGSize(width: view.frame.width * 0.8, height: 40)
        signInWithLabel = UILabel(frame: CGRect(x: view.frame.width/2 - labelSize_2.width/2, y: passwordTextField.frame.maxY + 10, width: labelSize_2.width, height: labelSize_2.height))
        signInWithLabel.font = getCustomFont(name: .Ubuntu_bold, size: 14, dynamicSize: false)
        signInWithLabel.backgroundColor = appThemeColor
        signInWithLabel.adjustsFontForContentSizeCategory = false
        signInWithLabel.adjustsFontSizeToFitWidth = true
        signInWithLabel.textColor = .white
        signInWithLabel.shadowColor = .lightGray
        signInWithLabel.shadowOffset = CGSize(width: 0, height: 2)
        signInWithLabel.text = "Or Sign in with"
        signInWithLabel.textAlignment = .center
        signInWithLabel.sizeToFit()
        signInWithLabel.frame.origin = CGPoint(x: view.frame.width/2 - signInWithLabel.frame.width/2, y: passwordTextField.frame.maxY + 10)
        
        let signInWithDividingLineSize = CGSize(width: view.frame.width * 0.9, height: 2)
        signInWithDividingLine = UIView(frame: CGRect(x: view.frame.width/2 - signInWithDividingLineSize.width/2, y: signInWithLabel.frame.midY - signInWithDividingLineSize.height/2, width: signInWithDividingLineSize.width, height: signInWithDividingLineSize.height))
        signInWithDividingLine.backgroundColor = .white
        signInWithDividingLine.layer.cornerRadius = signInWithDividingLine.frame.height/2
        signInWithDividingLine.clipsToBounds = true
        
        appleSignInButton = UIButton()
        appleSignInButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        appleSignInButton.frame.size.height = 60
        appleSignInButton.frame.size.width = appleSignInButton.frame.size.height
        appleSignInButton.backgroundColor = .white
        appleSignInButton.setImage(#imageLiteral(resourceName: "apple"), for: .normal)
        appleSignInButton.imageView?.contentMode = .scaleAspectFit
        appleSignInButton.layer.cornerRadius = appleSignInButton.frame.height/2
        appleSignInButton.castDefaultShadow()
        appleSignInButton.isEnabled = true
        appleSignInButton.isExclusiveTouch = true
        appleSignInButton.addTarget(self, action: #selector(appleSignInButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: appleSignInButton)
        
        googleSignInButton = UIButton()
        googleSignInButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        googleSignInButton.frame.size.height = 60
        googleSignInButton.frame.size.width = googleSignInButton.frame.size.height
        googleSignInButton.backgroundColor = .white
        googleSignInButton.setImage(#imageLiteral(resourceName: "search"), for: .normal)
        googleSignInButton.imageView?.contentMode = .scaleAspectFit
        googleSignInButton.layer.cornerRadius = googleSignInButton.frame.height/2
        googleSignInButton.castDefaultShadow()
        googleSignInButton.isEnabled = true
        googleSignInButton.isExclusiveTouch = true
        googleSignInButton.addTarget(self, action: #selector(googleSignInButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: googleSignInButton)
        
        faceBookSignInButton = UIButton()
        faceBookSignInButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        faceBookSignInButton.frame.size.height = 60
        faceBookSignInButton.frame.size.width = faceBookSignInButton.frame.size.height
        faceBookSignInButton.backgroundColor = .white
        faceBookSignInButton.setImage(#imageLiteral(resourceName: "facebook"), for: .normal)
        faceBookSignInButton.imageView?.contentMode = .scaleAspectFit
        faceBookSignInButton.layer.cornerRadius = faceBookSignInButton.frame.height/2
        faceBookSignInButton.castDefaultShadow()
        faceBookSignInButton.isEnabled = true
        faceBookSignInButton.isExclusiveTouch = true
        faceBookSignInButton.addTarget(self, action: #selector(faceBookSignInButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: faceBookSignInButton)
        
        /** Settings for facebook login button*/
        faceBookLoginButton.loginTracking = .limited
        faceBookLoginButton.delegate = self
        ///faceBookLoginButton.permissions = ["email"]
        
        /** Positioning for the various sign in buttons*/
        googleSignInButton.frame.origin = CGPoint(x: view.frame.width/2 - googleSignInButton.frame.width/2, y: signInWithLabel.frame.maxY + 10)
        
        appleSignInButton.frame.origin = CGPoint(x: googleSignInButton.frame.minX - (appleSignInButton.frame.width + 10), y: googleSignInButton.frame.origin.y)
        
        faceBookSignInButton.frame.origin = CGPoint(x: googleSignInButton.frame.maxX + 10, y: googleSignInButton.frame.origin.y)
        
        signInWithButtons.append(appleSignInButton)
        signInWithButtons.append(googleSignInButton)
        signInWithButtons.append(faceBookSignInButton)
        
        /** Animate these buttons expanding into their full size over time in a staggered delay pattern*/
        googleSignInButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        appleSignInButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        faceBookSignInButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.5, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            googleSignInButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            appleSignInButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.5, delay: 0.45, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            faceBookSignInButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        let dividingLineSize = CGSize(width: view.frame.width * 0.9, height: 5)
        let dividingLine = UIView(frame: CGRect(x: view.frame.width/2 - dividingLineSize.width/2, y: signInScreenSegmentedControl.frame.midY - dividingLineSize.height/2, width: dividingLineSize.width, height: dividingLineSize.height))
        dividingLine.backgroundColor = .white
        dividingLine.layer.cornerRadius = dividingLine.frame.height/2
        dividingLine.clipsToBounds = true
        dividingLine.layer.zPosition = 1
        
        /** Animate this view expanding into its full size over time*/
        dividingLine.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            dividingLine.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        disposableViews.append(signInScreenSegmentedControl)
        disposableViews.append(signInPortalLabel)
        disposableViews.append(usernameEmailTextfield)
        disposableViews.append(passwordTextField)
        disposableViews.append(employeeIDTextField)
        disposableViews.append(signInButton)
        disposableViews.append(appleSignInButton)
        disposableViews.append(googleSignInButton)
        disposableViews.append(faceBookSignInButton)
        disposableViews.append(dividingLine)
        disposableViews.append(signInWithLabel)
        disposableViews.append(signInWithDividingLine)
        
        view.addSubview(dividingLine)
        view.addSubview(signInScreenSegmentedControl)
        view.addSubview(signInPortalLabel)
        view.addSubview(usernameEmailTextfield)
        view.addSubview(passwordTextField)
        view.addSubview(employeeIDTextField)
        view.addSubview(signInButton)
        view.addSubview(appleSignInButton)
        view.addSubview(googleSignInButton)
        view.addSubview(faceBookSignInButton)
        view.addSubview(signInWithDividingLine)
        view.addSubview(signInWithLabel)
    }
    
    /** Sign in with third party applications method*/
    /** Sign the user in using Apple auth*/
    @objc func appleSignInButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        forwardTraversalShake()
        
        guard internetAvailable == true else {
            globallyTransmit(this: "Apple sign-in unavailable, please connect to the internet", with: UIImage(systemName: "g.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            
            return
        }
        
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        /** The dismissal animation glitch can't be fixed, it's an issue on Apple's end*/
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    /** SIgn-in with Apple methods and extensions*/
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor(frame: UIScreen.main.bounds)
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error){
        
        /**Handle error*/
        print("Sign in with Apple errored: \(error)")
    }
    /** SIgn-in with Apple methods and extensions*/
    
    /** Allow the user to sign in using Google auth*/
    @objc func googleSignInButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        forwardTraversalShake()
        
        guard internetAvailable == true else {
            globallyTransmit(this: "Google sign-in unavailable, please connect to the internet", with: UIImage(systemName: "g.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            
            return
        }
        
        /** Sign in with google*/
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        /**Create Google Sign In configuration object*/
        let config = GIDConfiguration(clientID: clientID)
        
        /**Start the sign in flow!*/
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            
            if let error = error {
                /** User cancelled the sign-in flow */
                
                print("Google sign-in error: \(error.localizedDescription)")
                return
            }
            
            guard let authentication = user?.authentication, let idToken = authentication.idToken else{
                return
            }
            /** User signed into google successfully*/
            
            /** Create an auth account in firebase with the provided credential*/
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            
            /**Sign in with Firebase*/
            Auth.auth().signIn(with: credential){ (authResult, error) in
                if (error != nil) {
                    globallyTransmit(this: "Uh-oh, something went wrong, please try again.", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    
                    print(error!.localizedDescription)
                    return
                }
                /**User is signed in to Firebase with Google.*/
                
                fetchCustomerLoginUsingThirdParty(userEmail: Auth.auth().currentUser?.email, completion: {[self](result) in
                    if result == nil{
                        globallyTransmit(this: "Sorry, we can't find that account in our records", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        
                        disableSignInButton()
                    }
                    else{
                        print("User: \(result!.username) signed in using Google")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()){
                            globallyTransmit(this: "Welcome back \(Auth.auth().currentUser?.displayName ?? "")", with: UIImage(systemName: "heart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.white, imageBorder: .borderLessCircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        }
                        
                        setLoggedInUserType(userType: "Customer")
                        
                        /** Present Customer UI*/
                        presentCustomerVC()
                        /** If the user signs in then they don't need to be shown the onboarding again in case they log out*/
                        ///userCompletedOnboarding()
                    }
                })
            }
        }
    }
    
    /** Sign the user in using Facebook auth*/
    @objc func faceBookSignInButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        forwardTraversalShake()
        
        guard internetAvailable == true else {
            globallyTransmit(this: "Facebook sign-in unavailable, please connect to the internet", with: UIImage(systemName: "g.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            
            return
        }
        
        /** Settings for facebook login button*/
        faceBookLoginButton.loginTracking = .limited
        faceBookLoginButton.delegate = self
        ///faceBookLoginButton.permissions = ["email"]
        
        /** Trigger the login button programmatically*/
        let nonce = randomNonceString()
        currentNonce = nonce
        faceBookLoginButton.nonce = sha256(nonce)
        
        faceBookLoginButton.sendActions(for: .touchUpInside)
    }
    
    /** Facebook Login Delegate method*/
    public func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        /** User logged out of facebook*/
    }
    
    public func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let error = error {
            globallyTransmit(this: "Uh-oh, something went wrong, please try again.", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            
            /** Log the user out of the facebook auth*/
            let manager = LoginManager()
            manager.logOut()
            
            print(error.localizedDescription)
            return
        }
        
        if AuthenticationToken.current?.tokenString == nil{
            /** User cancelled login operation*/
            return
        }
        /** Login successful, now sign into firebase*/
        
        /** Initialize a Firebase credential*/
        let idTokenString = AuthenticationToken.current?.tokenString
        let nonce = currentNonce!
        let credential = OAuthProvider.credential(withProviderID: "facebook.com", idToken: idTokenString!, rawNonce: nonce)
        
            /**Sign in with Firebase*/
            Auth.auth().signIn(with: credential) { [self] (authResult, error) in
                if (error != nil) {
                    /// Error. If error.code == .MissingOrInvalidNonce, make sure
                    /// you're sending the SHA256-hashed nonce as a hex string with
                    
                    globallyTransmit(this: "Uh-oh, something went wrong, please try again.", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    
                    /** Log the user out of the facebook auth*/
                    let manager = LoginManager()
                    manager.logOut()
                    
                    print(error!.localizedDescription)
                    return
                }
                /**User is signed in to Firebase with Facebook.*/
                
                fetchCustomerLoginUsingThirdParty(userEmail: Auth.auth().currentUser?.email, completion: {[self](result) in
                    if result == nil{
                        
                        globallyTransmit(this: "Sorry, we can't find that account in our records", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        
                        disableSignInButton()
                    }
                    else{
                        print("User: \(result!.username) signed in using Facebook")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()){
                            globallyTransmit(this: "Welcome back \(Auth.auth().currentUser?.displayName ?? "")", with: UIImage(systemName: "heart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.white, imageBorder: .borderLessCircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        }
                        
                        setLoggedInUserType(userType: "Customer")
                        
                        presentCustomerVC()
                        /** If the user signs in then they don't need to be shown the onboarding again in case they log out*/
                        ///userCompletedOnboarding()
                    }
                })
                
                /** Log the user out of the facebook auth*/
                let manager = LoginManager()
                manager.logOut()
            }
        }
    /** Sign in with third party applications method*/
    
    /** Use the given user credentials and compare them with the database's index tables*/
    @objc func submitCredentials(sender: UIButton){
        /** Ensure that all the required textfields for the current sign in portal are filled*/
        guard usernameEmailTextfield.text != "" && passwordTextField.text != "" else {
            disableSignInButton()
            return
        }
        
        if currentSignInPortal == 0{
            signInUsing(input: usernameEmailTextfield.text!, password: passwordTextField.text!, employeeID: nil, collection: "Customers", completion: { [self](result) in
                if result == nil{
                    
                    globallyTransmit(this: "Sorry, we can't find that account in our records", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    
                    markTextFieldEntryAsIncorrect(textField: usernameEmailTextfield)
                    markTextFieldEntryAsIncorrect(textField: passwordTextField)
                    disableSignInButton()
                }
                else{
                    markTextFieldEntryAsCorrect(textField: usernameEmailTextfield)
                    markTextFieldEntryAsCorrect(textField: passwordTextField)
                    print(result!.user.metadata)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now()){
                        globallyTransmit(this: "Welcome back \(Auth.auth().currentUser?.displayName ?? "")", with: UIImage(systemName: "heart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.white, imageBorder: .borderLessCircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    }
                    
                    setLoggedInUserType(userType: "Customer")
                    
                    presentCustomerVC()
                    /** If the user signs in then they don't need to be shown the onboarding again in case they log out*/
                    ///userCompletedOnboarding()
                }
            })
        }
        if currentSignInPortal == 1{
            guard employeeIDTextField.text != "" else {
                disableSignInButton()
                return
            }
            signInUsing(input: usernameEmailTextfield.text!, password: passwordTextField.text!, employeeID: employeeIDTextField.text!, collection: "Business", completion: { [self](result) in
                if result == nil{
                    
                    globallyTransmit(this: "Sorry, we can't find that account in our records", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    
                    markTextFieldEntryAsIncorrect(textField: usernameEmailTextfield)
                    markTextFieldEntryAsIncorrect(textField: passwordTextField)
                    markTextFieldEntryAsIncorrect(textField: employeeIDTextField)
                    disableSignInButton()
                }
                else{
                    markTextFieldEntryAsCorrect(textField: usernameEmailTextfield)
                    markTextFieldEntryAsCorrect(textField: passwordTextField)
                    markTextFieldEntryAsCorrect(textField: employeeIDTextField)
                    print(result!.user.metadata)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now()){
                        globallyTransmit(this: "Welcome back \(Auth.auth().currentUser?.displayName ?? "")", with: UIImage(systemName: "heart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.white, imageBorder: .borderLessCircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    }
                    
                    setLoggedInUserType(userType: "Business")
                    
                    presentBusinessVC()
                    /** If the user signs in then they don't need to be shown the onboarding again in case they log out*/
                    ///userCompletedOnboarding()
                }
            })
        }
        if currentSignInPortal == 2{
            guard employeeIDTextField.text != "" else {
                disableSignInButton()
                return
            }
            signInUsing(input: usernameEmailTextfield.text!, password: passwordTextField.text!, employeeID: employeeIDTextField.text!, collection: "Driver", completion: { [self](result) in
                if result == nil{
                    
                    globallyTransmit(this: "Sorry, we can't find that account in our records", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    
                    markTextFieldEntryAsIncorrect(textField: usernameEmailTextfield)
                    markTextFieldEntryAsIncorrect(textField: passwordTextField)
                    markTextFieldEntryAsIncorrect(textField: employeeIDTextField)
                    disableSignInButton()
                }
                else{
                    markTextFieldEntryAsCorrect(textField: usernameEmailTextfield)
                    markTextFieldEntryAsCorrect(textField: passwordTextField)
                    markTextFieldEntryAsCorrect(textField: employeeIDTextField)
                    print(result!.user.metadata)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now()){
                        globallyTransmit(this: "Welcome back \(Auth.auth().currentUser?.displayName ?? "")", with: UIImage(systemName: "heart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.white, imageBorder: .borderLessCircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    }
                    
                    setLoggedInUserType(userType: "Driver")
                    
                    presentDriverVC()
                    /** If the user signs in then they don't need to be shown the onboarding again in case they log out*/
                    ///userCompletedOnboarding()
                }
            })
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        forwardTraversalShake()
    }
    
    /** Separate scene navigation*/
    /** Present Customer UI*/
    func presentCustomerVC(){
        let tabbarController = self.storyboard?.instantiateViewController(withIdentifier: "CustomerNav") as! UITabBarController

        tabbarController.modalPresentationStyle = .fullScreen
        tabbarController.modalTransitionStyle = .crossDissolve
        self.present(tabbarController, animated: true, completion: nil)
    }
    
    /** Present Driver UI*/
    func presentDriverVC(){
        let tabbarController = self.storyboard?.instantiateViewController(withIdentifier: "BusinessNav") as! UITabBarController

        tabbarController.modalPresentationStyle = .fullScreen
        tabbarController.modalTransitionStyle = .coverVertical
        self.present(tabbarController, animated: true, completion: nil)
    }
    
    /** Present Business UI*/
    func presentBusinessVC(){
        let tabbarController = self.storyboard?.instantiateViewController(withIdentifier: "DriverNav") as! UITabBarController

        tabbarController.modalPresentationStyle = .fullScreen
        tabbarController.modalTransitionStyle = .coverVertical
        self.present(tabbarController, animated: true, completion: nil)
    }
    /** Separate scene navigation*/
    
    /** If two-step auth is enabled then prompt the user to enter the code sent to their phone via a sheet view, else revoke access to the application and send them back to the sign in screen*/
    
    /** Keyboard will hide and show methods*/
    @objc func keyboardWillShow(notification: NSNotification){
        ///guard let userInfo = notification.userInfo else {return}
        ///guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        /*let keyboardFrame = keyboardSize.cgRectValue*/
        
        guard currentlySelectedTextField != nil else {
            return
        }
        
        /**
         UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
         if((view.frame.height - keyboardFrame.height - 10) <= (currentlySelectedTextField.frame.maxY)){
         currentlySelectedTextField.frame.origin = CGPoint(x: currentlySelectedTextFieldOriginalPosition.x, y: (view.frame.height - keyboardFrame.height) - (currentlySelectedTextField.frame.height + 10))
         }
         }
         */
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        guard currentlySelectedTextField != nil else {
            return
        }
        
        /**
         UIView.animate(withDuration: 0.5, delay: 0.05, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in currentlySelectedTextField.frame.origin = currentlySelectedTextFieldOriginalPosition
         }
         */
    }
    /** Keyboard will hide and show methods*/
    
    /** Dynamic styling of textfields*/
    
    /** Create a blue border around the textfield to inform the user that it's now in focus aka they're able to type in it*/
    func markTextFieldAsFocused(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderWidth = 2
            textField.layer.borderColor = appThemeColor.cgColor
        }
    }
    
    func restoreOriginalTextFieldStyling(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
        }
    }
    
    func markTextFieldEntryAsIncorrect(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.red.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
        }
    }
    
    func markTextFieldEntryAsCorrect(textField: UITextField){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderColor = UIColor.green.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
        }
    }
    /** Dynamic styling of textfields*/
    
    /** Triggered when the textfield is getting ready to begin editting*/
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool{
        
        /**
         /** Reset the position of the old selected text field (if any)*/
         if currentlySelectedTextField != nil{
         if textField != currentlySelectedTextField{
         UIView.animate(withDuration: 0.5, delay: 0.05, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in currentlySelectedTextField.frame.origin = currentlySelectedTextFieldOriginalPosition
         }
         }
         }
         */
        
        markTextFieldAsFocused(textField: textField)
        
        currentlySelectedTextField = textField
        currentlySelectedTextFieldOriginalPosition = textField.frame.origin
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            textField.layer.borderWidth = 2
            textField.layer.borderColor = appThemeColor.cgColor
        }
        
        return true
    }
    
    /** Disables the sign in button if all fields aren't filled out*/
    func disableSignInButton(){
        signInButton.isEnabled = false
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            signInButton.alpha = 0.5
        }
    }
    
    /** Allows the user the ability to use the sign in button once all fields are properly filled out*/
    func enableSignInButton(){
        signInButton.isEnabled = true
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            signInButton.alpha = 1
        }
    }
    
    /** Triggered when the textfield is getting ready to end editting*/
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool{
        restoreOriginalTextFieldStyling(textField: textField)
        
        /** If the textfields are empty then mark them as incorrect, if they're filled then mark them as correct without validation*/
        if textField == usernameEmailTextfield{
            if textField.text == ""{
                markTextFieldEntryAsIncorrect(textField: textField)
                errorShake()
            }
            else{
                markTextFieldEntryAsCorrect(textField: textField)
                mediumHaptic()
            }
        }
        if textField == passwordTextField{
            if textField.text == ""{
                markTextFieldEntryAsIncorrect(textField: textField)
                errorShake()
            }
            else{
                markTextFieldEntryAsCorrect(textField: textField)
                mediumHaptic()
            }
        }
        if textField == employeeIDTextField{
            if textField.text == ""{
                markTextFieldEntryAsIncorrect(textField: textField)
                errorShake()
            }
            else{
                markTextFieldEntryAsCorrect(textField: textField)
                mediumHaptic()
            }
        }
        
        if usernameEmailTextfield.text != "" && passwordTextField.text != "" && employeeIDTextField.text != "" && currentSignInPortal == 1{
            enableSignInButton()
        }
        else if usernameEmailTextfield.text != "" && passwordTextField.text != "" && employeeIDTextField.text != "" && currentSignInPortal == 2{
            enableSignInButton()
        }
        else if usernameEmailTextfield.text != "" && passwordTextField.text != "" && currentSignInPortal == 0{
            enableSignInButton()
        }
        else{
            disableSignInButton()
        }
        
        return true
    }
    
    /**When a user presses the return or done etc key, then simply hide the keyboard*/
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        /** If internet isn't available don't even try to do anything*/
        guard internetAvailable == true else{
            textField.resignFirstResponder()
            return true
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    /** Methods for displaying the sign in UI objects associated with each scene in the sign in flow in a static or animated fashion*/
    func displayCustomerSignInPortal(animated: Bool){
        if currentlySelectedTextField != nil{
            currentlySelectedTextField.resignFirstResponder()
        }
        
        backwardTraversalShake()
        
        currentSignInPortal = 0
        
        switch animated{
        case true:
            UIView.transition(with: signInPortalLabel!, duration: 0.5, options: .transitionFlipFromBottom, animations:{ [self] in
                signInPortalLabel.text = signInPortalTitles[0]
            })
            
            /** Animate the employee ID Textfield being brought out of the scene*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                employeeIDTextField.transform = CGAffineTransform(translationX: -view.frame.width, y: 0)
            }
            /** Deselect the employee ID Textfield as the currently selected textfield in order to prevent it from being repositioned unintentionally*/
            if currentlySelectedTextField == employeeIDTextField{
                currentlySelectedTextField = nil
            }
            
            for button in signInWithButtons{
                UIView.animate(withDuration: 0.25, delay: 0){
                    button.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            }
            
            UIView.animate(withDuration: 0.25, delay: 0){[self] in
                signInWithDividingLine.transform = CGAffineTransform(translationX: 0, y: 0)
                signInWithLabel.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
        case false:
            signInPortalLabel.text = signInPortalTitles[0]
            
            employeeIDTextField.transform = CGAffineTransform(translationX: -view.frame.width, y: 0)
            
            for button in signInWithButtons {
                button.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
            signInWithDividingLine.transform = CGAffineTransform(translationX: 0, y: 0)
            signInWithLabel.transform = CGAffineTransform(translationX: 0, y: 0)
        }
        
    }
    
    func displayBusinessClientSignInPortal(animated: Bool){
        if currentlySelectedTextField != nil{
            currentlySelectedTextField.resignFirstResponder()
        }
        
        forwardTraversalShake()
        
        currentSignInPortal = 1
        
        employeeIDTextField.isHidden = false
        
        employeeIDTextField.attributedPlaceholder = NSAttributedString(string:"Business Client ID", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        switch animated{
        case true:
            UIView.transition(with: signInPortalLabel!, duration: 0.5, options: .transitionFlipFromTop, animations:{ [self] in
                signInPortalLabel.text = signInPortalTitles[1]
            })
            
            UIView.transition(with: employeeIDTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{[self] in
                employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "b.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            })
            
            /** Animate the employee ID Textfield being brought into the scene*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                employeeIDTextField.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
            for button in signInWithButtons {
                UIView.animate(withDuration: 0.25, delay: 0){[self] in
                    button.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
                }
            }
            
            UIView.animate(withDuration: 0.25, delay: 0){[self] in
                signInWithDividingLine.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
                signInWithLabel.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
            }
            
        case false:
            signInPortalLabel.text = signInPortalTitles[1]
            
            employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "b.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            
            employeeIDTextField.transform = CGAffineTransform(translationX: 0, y: 0)
            
            for button in signInWithButtons {
                button.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
            }
            
            signInWithDividingLine.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
            signInWithLabel.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
        }
    }
    
    func displayDriverSignInPortal(animated: Bool){
        if currentlySelectedTextField != nil{
            currentlySelectedTextField.resignFirstResponder()
        }
        
        forwardTraversalShake()
        
        currentSignInPortal = 2
        
        employeeIDTextField.isHidden = false
        
        employeeIDTextField.attributedPlaceholder = NSAttributedString(string:"Driver ID", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        switch animated{
        case true:
            UIView.transition(with: signInPortalLabel!, duration: 0.5, options: .transitionFlipFromBottom, animations:{ [self] in
                signInPortalLabel.text = signInPortalTitles[2]
            })
            
            UIView.transition(with: employeeIDTextFieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{[self] in
                employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "d.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            })
            
            /** Animate the employee ID Textfield being brought into the scene*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                employeeIDTextField.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
            for button in signInWithButtons {
                UIView.animate(withDuration: 0.25, delay: 0){[self] in
                    button.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
                }
            }
            
            UIView.animate(withDuration: 0.25, delay: 0){[self] in
                signInWithDividingLine.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
                signInWithLabel.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
            }
            
        case false:
            signInPortalLabel.text = signInPortalTitles[2]
            
            employeeIDTextFieldLeftButton.setImage(UIImage(systemName: "d.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            
            employeeIDTextField.transform = CGAffineTransform(translationX: 0, y: 0)
            
            for button in signInWithButtons {
                button.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
            }
            
            signInWithDividingLine.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
            signInWithLabel.transform = CGAffineTransform(translationX: view.frame.width, y: 0)
        }
        
    }
    /** Methods for displaying the sign in UI objects associated with each scene in the sign in flow in a static or animated fashion*/
    
    @objc func signInBackButtonPressed(sender: UIButton){
        sender.isEnabled = false
        
        signInUIBeingDisplayed = false
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.alpha = 0
        }
        
        /** Remove all added views from the hierarchy*/
        for disposableView in disposableViews{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                disposableView.removeFromSuperview()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){[self] in
            setStartMenuPosition()
            displayStartScreen()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            sender.removeFromSuperview()
        }
        
        backwardTraversalShake()
    }
    
    /** Displays the appropriate UI associated with the sign up process*/
    func displaySignUpFlow(){
        /** Expand the transitional get started UIView*/
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseIn){[self] in
            onboardingFinalSlideTransitionView.frame.origin.y = -maskedHeaderView.frame.height
        }
        
        /** Animate the views previously added to the screen fading out and then remove them from memory*/
        for view in onboardingFinalSlideMiscViews{
            UIView.animate(withDuration: 1, delay: 0){
                view.alpha = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                view.removeFromSuperview()
            }
        }
        onboardingFinalSlideMiscViews.removeAll()
    }
    
    /** Sets the final slide transition view to its operational position for the user to select the appropriate buttons to move forward*/
    func setStartMenuPosition(){
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            onboardingFinalSlideTransitionView.frame.origin.y = 0
        }
    }
    
    /** Skip the onboarding flow*/
    func goToSignInSignUpScreen(){
        /** Remove the first collection view slide so that there's white space for the other view to transition without the user noticing it's different*/
        onboardingCollectionViewCells[0] = UIView()
        
        /** Remove all navigation UI*/
        onboardingPreviousButton.removeFromSuperview()
        onboardingNextButton.removeFromSuperview()
        onboardingSkipButton.removeFromSuperview()
        onboardingPageControl.removeFromSuperview()
        lastSlideContentContainer.removeFromSuperview()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){[self] in
            setStartMenuPosition()
            displayStartScreen()
        }
    }
    
    /** Button handlers*/
    /** Present the sign up and sign in buttons and remove this button*/
    @objc func getStartedButtonPressed(sender: UIButton){
        sender.isEnabled = false
        
        setStartMenuPosition()
        
        UIView.animate(withDuration: 0.25, delay: 0){[self] in
            sender.alpha = 0
            lastSlideContentContainer.alpha = 0
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            onboardingPreviousButton.transform = CGAffineTransform(scaleX: 0.000001, y: 0.000001)
        }
        
        UIView.animate(withDuration: 0.75, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            onboardingPageControl.transform = CGAffineTransform(scaleX: 0.000001, y: 0.000001)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){ [self] in
            sender.removeFromSuperview()
            onboardingPreviousButton.removeFromSuperview()
            onboardingNextButton.removeFromSuperview()
            onboardingSkipButton.removeFromSuperview()
            onboardingPageControl.removeFromSuperview()
            lastSlideContentContainer.removeFromSuperview()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){ [self] in
            displayStartScreen()
        }
        
        /** Remove all views except for the one in index 6 from the collection view to clear memory*/
        for (index, view) in onboardingCollectionViewCells.enumerated(){
            if index != onboardingCollectionViewCount-1{
                view.removeFromSuperview()
                onboardingCollectionViewCells[index] = UIView()
            }
        }
        
        onboardingCollectionView.isScrollEnabled = false
        
        successfulActionShake()
    }
    
    @objc func signInButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        signInUIBeingDisplayed = true
        
        displaySignInFlow()
        forwardTraversalShake()
    }
    
    @objc func signUpButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        let vc = SignUpVC(onboardingVC: self)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){
            self.present(vc, animated: true, completion: nil)
        }
        
        displaySignUpFlow()
        forwardTraversalShake()
    }
    
    /** Display password reset view controller*/
    @objc func forgotPasswordButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        let vc = iForgot()
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .flipHorizontal
        self.present(vc, animated: true, completion: nil)
        
        lightHaptic()
    }
    
    /** Skips ahead to the login / sign up page*/
    @objc func onboardingSkipButtonPressed(sender: UIButton){
        /** Log the press of this button in our to better gauge if users like the onboarding screen or not*/
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemName: "Onboarding Skip Button",
            AnalyticsParameterContentType: "UIButton pressed to skip the onboarding screens",
        ])
        
        /** This button should be invisible when the user is on the last page of the collection view*/
        guard onboardingPageControl.currentPage != (onboardingPageControl.numberOfPages - 1) else {
            return
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        onboardingPageControl.currentPage = onboardingPageControl.numberOfPages - 1
        onboardingCollectionView.setContentOffset(CGPoint(x: view.frame.width * CGFloat(onboardingPageControl.currentPage), y: 0), animated: true)
    }
    
    @objc func onboardingNextButtonPressed(sender: UIButton){
        /** This button should be invisible when the user is on the last page of the collection view*/
        guard onboardingPageControl.currentPage != (onboardingPageControl.numberOfPages - 1) else {
            return
        }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        forwardTraversalShake()
        moveForwards()
    }
    
    @objc func onboardingPreviousButtonPressed(sender: UIButton){
        /** This button should be invisible when the user is on the first page of the collection view*/
        guard onboardingPageControl.currentPage != 0 else {
            return
        }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        backwardTraversalShake()
        moveBackwards()
    }
    
    /** Shift the scrollview to the right*/
    func moveForwards(){
        /** Avoid overflow by respecting the upper bound of the collection view*/
        if (onboardingPageControl.currentPage) < (onboardingPageControl.numberOfPages - 1){
            onboardingPageControl.currentPage += 1
            
            onboardingCollectionView!.setContentOffset(CGPoint(x: view.frame.width * CGFloat(onboardingPageControl.currentPage), y: 0), animated: true)
        }
        else if (onboardingPageControl.currentPage) == (onboardingPageControl.numberOfPages - 1){
            onboardingPageControl.currentPage += 1
            
            onboardingCollectionView!.setContentOffset(CGPoint(x: view.frame.width * CGFloat(onboardingPageControl.currentPage), y: 0), animated: true)
        }
    }
    
    /** Shift the scrollview to the left*/
    func moveBackwards(){
        /** Avoid overflow by respecting the lower bound of the collection view*/
        if onboardingPageControl.currentPage > 1{
            onboardingPageControl.currentPage -= 1
            
            onboardingCollectionView!.setContentOffset(CGPoint(x: view.frame.width * CGFloat(onboardingPageControl.currentPage), y: 0), animated: true)
        }
        else if onboardingPageControl.currentPage == 1{
            onboardingPageControl.currentPage -= 1
            
            onboardingCollectionView.setContentOffset(CGPoint(x: view.frame.width * CGFloat(onboardingPageControl.currentPage), y: 0), animated: true)
        }
    }
    /** Button handlers*/
    
    /**Page control and scrollView Listeners*/
    /**Default listener for UIScrollview to inform the instantiated page control of a page change*/
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /** Make sure the scrollview has paging enabled*/
        if(scrollView.isPagingEnabled == true){
            guard onboardingPageControl != nil && priming == false else {
                return
            }
            
            let pageIndex = round(scrollView.contentOffset.x/self.view.frame.width)
            onboardingPageControl.currentPage = Int(pageIndex)
            
            /** Determine the direction of the scroll by comparing the previous value of the current page with the new value, and then trigger haptic feedback to correspond to the direction*/
            if currentSlide < onboardingPageControl.currentPage{
                currentSlide = onboardingPageControl.currentPage
                backwardTraversalShake()
            }
            else if currentSlide > onboardingPageControl.currentPage{
                currentSlide = onboardingPageControl.currentPage
                forwardTraversalShake()
            }
            
            if (onboardingPageControl.currentPage) == 0{
                /**Disable the previous button*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    onboardingPreviousButton.alpha = 0
                }
                onboardingPreviousButton.isEnabled = false
            }
            else if (onboardingPageControl.currentPage) == (onboardingPageControl.numberOfPages - 1){
                
                /** Disable the skip button*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    onboardingSkipButton.alpha = 0
                }
                onboardingSkipButton.isEnabled = false
                
                /** Disable the page control*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    onboardingPageControl.alpha = 0
                }
                onboardingPageControl.isEnabled = false
                
                /** Disable the next button*/
                UIView.animate(withDuration: 0.25, delay: 0){[self] in
                    onboardingNextButton.alpha = 0
                }
                onboardingNextButton.isEnabled = false
                
                /**Disable the previous button*/
                UIView.animate(withDuration: 0.25, delay: 0){[self] in
                    onboardingPreviousButton.alpha = 0
                }
                onboardingPreviousButton.isEnabled = false
                
                /** Disable the page control*/
                UIView.animate(withDuration: 0.25, delay: 0){[self] in
                    onboardingPageControl.alpha = 0
                }
                onboardingPageControl.isEnabled = false
                
                /** Show and enable these UI Elements*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    getStartedButton.alpha = 1
                }
                getStartedButton.isEnabled = true
            }
            else if (onboardingPageControl.currentPage) < (onboardingPageControl.numberOfPages - 1){
                /** Enable the skip button*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    onboardingSkipButton.alpha = 1
                }
                onboardingSkipButton.isEnabled = true
                
                /** Enable the page control*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    onboardingPageControl.alpha = 1
                }
                onboardingPageControl.isEnabled = true
                
                /** Hide and disable the get started button*/
                UIView.animate(withDuration: 0.25, delay: 0){[self] in
                    getStartedButton.alpha = 0
                }
                getStartedButton.isEnabled = false
                
                /** Enable the onboarding next button when going backwards*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    onboardingNextButton.alpha = 1
                }
                onboardingNextButton.isEnabled = true
                
                if (onboardingPageControl.currentPage) > 0{
                    /** Enable the onboarding previous button when going forwards*/
                    UIView.animate(withDuration: 0.5, delay: 0){[self] in
                        onboardingPreviousButton.alpha = 1
                    }
                    onboardingPreviousButton.isEnabled = true
                }
            }
        }
    }
    
    /** Shift the scroll view to reflect the tap action on the page control*/
    @objc func onboardingPageControlTapped(_ sender: UIPageControl){
        /** Delay update in order to allow object to update as UI changes take effect*/
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                
                onboardingCollectionView!.setContentOffset(CGPoint(x: view.frame.width * CGFloat(sender.currentPage), y: 0), animated: true)
            }
        }
        
        if (onboardingPageControl.currentPage) == 0{
            /**hide and disable this button*/
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                onboardingPreviousButton.alpha = 0
            }
            onboardingPreviousButton.isEnabled = false
        }
        if (onboardingPageControl.currentPage) == (onboardingPageControl.numberOfPages - 1){
            /** hide and disable this button*/
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                onboardingNextButton.alpha = 0
            }
            onboardingNextButton.isEnabled = false
        }
        
        if (onboardingPageControl.currentPage) < (onboardingPageControl.numberOfPages - 1){
            /** Enable the onboarding next button when going backwards*/
            onboardingNextButton.isEnabled = true
            
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                onboardingNextButton.alpha = 1
            }
        }
        if (onboardingPageControl.currentPage) > 0{
            /** Enable the onboarding previous button when going forwards*/
            onboardingPreviousButton.isEnabled = true
            
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                onboardingPreviousButton.alpha = 1
            }
        }
    }
    /** Page control and scrollView Listeners*/
    
    /** A little something extra to keep things flashy*/
    /** Adds standard gesture recognizers to button that scale the button when the user's finger enters or leaves the surface of the button*/
    func addDynamicButtonGR(button: UIButton){
        button.addTarget(self, action: #selector(buttonTI), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonTD), for: .touchDown)
        button.addTarget(self, action: #selector(buttonDE), for: .touchDragExit)
        button.addTarget(self, action: #selector(buttonDEN), for: .touchDragEnter)
    }
    
    /** Fired when user touches inside the button, this is used to reset the scale of the button when the touch down event ends*/
    @objc func buttonTI(sender: UIButton){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
        lightHaptic()
        }
    
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    /** Generic recognizer that scales the button down when the user touches their finger down on it*/
    @objc func buttonTD(sender: UIButton){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
        lightHaptic()
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger into it*/
    @objc func buttonDEN(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    /** Generic recognizer that scales the button up when the user drags their finger out inside of it*/
    @objc func buttonDE(sender: UIButton){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
        lightHaptic()
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    /** Add the gesture recognizer to this view*/
    func addVisualSingleTapGestureRecognizer(){
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(viewSingleTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        view.addGestureRecognizer(singleTap)
    }
    
    /** Show where the user taps on the screen*/
    @objc func viewSingleTapped(sender: UITapGestureRecognizer){
        /** Snapchat esque circular fade in fade out animation signals where the user has tapped*/
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.05, height: view.frame.width * 0.05))
        circleView.layer.cornerRadius = circleView.frame.height/2
        circleView.layer.borderWidth = 0.5
        circleView.layer.borderColor = appThemeColor.cgColor
        circleView.backgroundColor = UIColor.clear
        circleView.clipsToBounds = true
        circleView.center.x = sender.location(in: view).x
        circleView.center.y = sender.location(in: view).y
        circleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        let inscribedCircleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.05, height: view.frame.width * 0.05))
        inscribedCircleView.layer.cornerRadius = inscribedCircleView.frame.height/2
        switch darkMode {
        case true:
            inscribedCircleView.backgroundColor = UIColor.lightGray.lighter.withAlphaComponent(0.5)
        case false:
            inscribedCircleView.backgroundColor = UIColor.white.darker.withAlphaComponent(0.5)
        }
        inscribedCircleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        circleView.addSubview(inscribedCircleView)
        
        view.addSubview(circleView)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.transform = CGAffineTransform(scaleX: 2, y: 2)
        }
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            inscribedCircleView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            inscribedCircleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
        UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            inscribedCircleView.alpha = 0
        }
        UIView.animate(withDuration: 0.5, delay: 0.7, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            circleView.alpha = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            circleView.removeFromSuperview()
        }
    }
    /** A little something extra to keep things flashy*/
    
    /** Textview delegate method for accessing specified URLs in attributed text*/
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if URL.absoluteString == "app://TOS"{
            lightHaptic()
            
            /** Push the terms of service VC when the user taps the highlighted URL*/
            let tosVC = TermsofServiceVC()
            tosVC.modalPresentationStyle = .formSheet
            tosVC.modalTransitionStyle = .coverVertical
            self.present(tosVC, animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
    
    /** Don't allow the user to select any text*/
    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.selectedTextRange = nil
    }
    /** Non-customer users can only have the email and phone auth providers, no third-party*/
    
    /** Collection view delegate methods*/
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return onboardingCollectionViewCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: onboardingCollectionViewCell.identifier, for: indexPath) as! onboardingCollectionViewCell
        
        cell.contentView.backgroundColor = bgColor
        
        cell.setUp(with: onboardingCollectionViewCells[indexPath.row])
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height * 0.9)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    /** Collection view delegate methods*/
}

/** SIgn-in with Apple methods and extensions*/
@available(iOS 13.0, *)
extension HomeVC: ASAuthorizationControllerDelegate {
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            /**Initialize a Firebase credential*/
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
                /**Sign in with Firebase*/
                Auth.auth().signIn(with: credential) { [self] (authResult, error) in
                    if (error != nil) {
                        /// Error. If error.code == .MissingOrInvalidNonce, make sure
                        /// you're sending the SHA256-hashed nonce as a hex string with
                        /// your request to Apple.
                        
                        globallyTransmit(this: "Uh-oh, something went wrong, please try again.", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        
                        print(error!.localizedDescription)
                        return
                    }
                    /**User is signed in to Firebase with Apple.*/
                    
                    fetchCustomerLoginUsingThirdParty(userEmail: Auth.auth().currentUser?.email, completion: {[self](result) in
                        if result == nil{
                            
                            globallyTransmit(this: "Sorry, we can't find that account in our records", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            
                            disableSignInButton()
                        }
                        else{
                            print("User: \(result!.username) signed in using Apple")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now()){
                                globallyTransmit(this: "Welcome back \(Auth.auth().currentUser?.displayName ?? "")", with: UIImage(systemName: "heart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.white, imageBorder: .borderLessCircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            }
                            
                            setLoggedInUserType(userType: "Customer")
                            
                            presentCustomerVC()
                            
                            /** If the user signs in then they don't need to be shown the onboarding again in case they log out*/
                            ///userCompletedOnboarding()
                        }
                    })
                }
            }
        }
    }
/** SIgn-in with Apple methods and extensions*/

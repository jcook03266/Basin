//
//  SignUpVC.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/8/22.
//

import UIKit
import PhoneNumberKit
import FirebaseAuth
import Firebase
import FirebaseStorage
import Lottie
import AuthenticationServices
import FirebaseCore
import GoogleSignIn
import FBSDKLoginKit

/** Custom class for the phone number textfield that forces the default region to be US*/
public class USPhoneNumberTextField: PhoneNumberTextField{
    public override var defaultRegion: String{
        get{
            return "US"
        }
        set{} /**exists for backward compatibility*/
    }
}

public class SignUpVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIContextMenuInteractionDelegate, UITextFieldDelegate, CountryCodePickerDelegate, AuthUIDelegate, UITextPasteDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, LoginButtonDelegate{
    
    lazy var statusBarHeight = view.getStatusBarHeight()
    /** Button used to traverse backwards in the presentation sequence*/
    var backButton = UIButton()
    /** Nil if the presenting vc isn't the home vc where onboarding occurs, else the presenting vc is as mentioned*/
    var onboardingVC: HomeVC?
    var onboardingVCPresenting = false
    
    /** Sign up UI Components*/
    var customerButton = UIButton()
    var customerButtonLabel = PaddedLabel(withInsets: 0, 0, 5, 5)
    var businessButton = UIButton()
    var businessButtonLabel = PaddedLabel(withInsets: 0, 0, 5, 5)
    var driverButton = UIButton()
    var driverButtonLabel = PaddedLabel(withInsets: 0, 0, 5, 5)
    var collectionView: UICollectionView!
    var collectionViewCells: [UIView] = []
    var collectionViewSlideCount = 6
    var pageControl = UIPageControl()
    var topMask = CAShapeLayer()
    var bottomMask = CAShapeLayer()
    /** Track the current position of the bottom mask's y translation in order to animate it appearing and disappearing*/
    var bottomMaskCurrentYTranslation: CGFloat = 0
    /** Displays a pending verification message or welcome message depending on the path the user took*/
    var completionScreen: UIView!
    var termsOfServiceButton: UIButton!
    var termsOfServiceButtonContainer: UIView!
    var continueButton = UIButton()
    var createAccountButton = UIButton()
    /** Specify that this screen is optional for customers but mandatory for Business clients and Drivers*/
    var genderDOBScreenInstructionLabel = UILabel()
    /** The random image selected to use for the customer button*/
    var customerButtonImage: UIImage!
    
    /** Various textfields*/
    var emailTextfield = UITextField()
    var phoneTextfield = USPhoneNumberTextField()
    var phoneNumberKit = PhoneNumberKit()
    var usernameTextfield = UITextField()
    var passwordTextfield = UITextField()
    /** Switch between secure and non-secure password textfield types*/
    var usePasswordSecurity = true
    /** Button that displays a lock to inform the user that the password textfield is securely encrypted*/
    var passwordTextfieldLeftButton = UIButton()
    var firstNameTextfield = UITextField()
    var lastNameTextfield = UITextField()
    var address1Textfield = UITextField()
    var address2Textfield = UITextField()
    var boroughTextfield = UITextField()
    var boroughPickerView = UIPickerView()
    var cityTextfield = UITextField()
    var cityPickerView = UIPickerView()
    var stateTextfield = UITextField()
    var statePickerView = UIPickerView()
    var zipCodeTextfield = UITextField()
    var zipCodePickerView = UIPickerView()
    var DOBTextfield = UITextField()
    var DOBPickerView = UIDatePicker()
    var genderTextfield = UITextField()
    var genderPickerView = UIPickerView()
    
    /** Third party sign up UI*/
    var faceBookSignInButton = UIButton()
    /** Hidden facebook sign in button that's triggered by the custom facebook sign in button*/
    var faceBookLoginButton: FBLoginButton = FBLoginButton()
    var googleSignInButton = UIButton()
    var appleSignInButton = UIButton()
    var signUpWithThirdPartyLabel = PaddedLabel(withInsets: 0, 0, 5, 5)
    
    /** UI For profile picture image selection*/
    var imagePicker: UIImagePickerController = UIImagePickerController()
    var profilePictureImageView = UIImageView()
    var profilePictureImageViewAnimatedBorder = ViewWithPersistentAnimations(frame: .zero)
    var profilePictureSelectionButton = UIButton()
    
    /** OTP Verification UI*/
    /** Simple container for all of these textfields to make life simpler when translating their positions*/
    var OTPTextFieldContainer = UIView()
    var OTPTextField_1 = UITextField()
    var OTPTextField_2 = UITextField()
    var OTPTextField_3 = UITextField()
    var OTPTextField_4 = UITextField()
    var OTPTextField_5 = UITextField()
    var OTPTextField_6 = UITextField()
    var OTPTextFields: [UITextField] = []
    /** The verification code parsed from the 6 textfields*/
    var OTPCode: String = ""
    /** The ID used to identify the authentication session*/
    var verificationID: String = ""
    
    /** Stored parameters for the user profile to be pushed to the database*/
    var email: String = ""
    var phoneNumber: PhoneNumber?
    var username: String = ""
    var password: String = ""
    var name: String = ""
    var firstName: String = "" {
        didSet{
            /** Set the name variable to be a combination of the first and last names when either are assigned to a value*/
            name = "\(firstName) \(lastName)"
        }
    }
    var lastName: String = "" {
        didSet{
            name = "\(firstName) \(lastName)"
        }
    }
    var address: Address!
    var address1: String = ""
    var address2: String = ""
    var city: String = "New York"
    var borough: Borough? = .Brookyln
    var state: String = "New York"
    var zipCode: UInt? = nil
    
    /** Optional for customers, mandatory for employees and drivers*/
    /** 0 Male, 1 Female, 2 Unspecified*/
    var gender: String = genders[2]
    var DOB: Date? = nil
    var profilePicture: UIImage? = nil
    
    /** Username requirements UI*/
    var usernameRequirementsContainer = UIView()
    var usernameRequirementsTitleLabel = UILabel()
    /** Max length is 30 characters*/
    var usernameRequirement_1 = UIButton()
    /** Can't end or start with a period*/
    var usernameRequirement_2 = UIButton()
    /** Can't have sequential periods*/
    var usernameRequirement_3 = UIButton()
    /** Can contain characters a-z, and 0-9*/
    var usernameRequirement_4 = UIButton()
    
    /** Password requirements UI*/
    var passwordRequirementsContainer = UIView()
    var passwordRequirementsTitleLabel = UILabel()
    /** Minimum length is 8 characters*/
    var passwordRequirement_1 = UIButton()
    /** Must contain at least one uppercase letter (A-Z)*/
    var passwordRequirement_2 = UIButton()
    /** Must contain at least one lowercase letter (a-z)*/
    var passwordRequirement_3 = UIButton()
    /** Must contain at least one number (0-9)*/
    var passwordRequirement_4 = UIButton()
    /** Must contain at least one special character (#?!@$%^&*-)*/
    var passwordRequirement_5 = UIButton()
    
    /** Verification prompt buttons*/
    var verifyPhoneButton = UIButton()
    var resendOTPButton = UIButton()
    
    /** Bools that are toggled when the user presses the verification button and completes whatever necessary tasks*/
    var phoneNumberVerified = false
    
    /** UI for OTP count down, the user has one minute to enter the OTP or else the OTP textfields will auto hide and the code will be invalidated because they'll have to enter a new one in order to access the fields again*/
    var otpCountDownTimer = Timer()
    /** Timer that repeats every 1 second to change the time displayed by the count down label*/
    var numberTickTimer = Timer()
    var otpCountDownLabel = UILabel()
    /** The amount of time remaining in the countdown (in seconds)*/
    var countDownPosition = 60
    
    /** Keep track of the currently selected textfield*/
    var currentlySelectedTextField: UITextField?
    var currentlySelectedTextFieldOriginalPosition = CGPoint.zero
    
    /** Imageview that contains the image corresponding to the current path the user has chosen*/
    var chosenPathImageView = UIImageView()
    /** Bools that are used to determine which sign up path the user is currently on*/
    var driverPathSelected = false
    var businessPathSelected = false
    var customerPathSelected = false
    /** If the user presses one of the three choices then a path has been selected and so the back button must be used to traverse through the collectionview and also dismiss the view controller*/
    var pathSelected = false
    var backButtonOptions = ["Dismiss"]
    /** All possible back button context menu options: Dismiss, Introduction, Email, Username, Name, DOB*/
    
    /**Blurred UIView that can overlayed ontop of another view as a subview*/
    lazy var blurredView = getBlurredView()
    
    /** Boolean used to inform the sign up vc that the account creation process was completed*/
    var accountCreationComplete: Bool = false
    
    /** Sign-up flow goes like this: three buttons -> email & phone number -> username & password -> name & address -> gender & DOB & profile picture -> verification in progress prompt / welcome prompt */
    /** only customers can skip the gender & dob & profile picture questions*/
    /** If the user chooses to use google facebook or apple shortcut then the email is already verified, and the email section is omitted, but the username and password fields are kept*/
    /** Email and phone number will be verified on the spot*/
    
    /** Status bar styling variables*/
    public override var preferredStatusBarStyle: UIStatusBarStyle{
        switch darkMode{
        case true:
            return .lightContent
        case false:
            return .darkContent
        }
    }
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    /** Specify status bar display preference*/
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    /** Status bar styling variables*/
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /** Unblur the view's content*/
        blurredView.removeFromSuperview()
    }
    
    public override func viewDidDisappear(_ animated: Bool){
        
    }
    
    /** If the view controller is taken out of memory make sure to delete the temporary phone authentication user (if any), overriding the dismiss method will only break the firebase Auth UI*/
    /** Note: User auth credentials that aren't deleted remain, if they're linked then they remain linked, if the user chooses one of these linked credentials to create an account then all of the previously linked credentials will be tied to the newly created account, but if the user tries to link a previously linked credential with the current credential then an error will occur, all of this behavior is normal. If the user chooses to abuse the account system then they can still use their previously linked credentials, it's not my problem */
    private func purgeTemporaryUsersOnDismiss(){
        /** If the user doesn't complete the account creation process before leaving the view controller then delete the user that was created*/
        if accountCreationComplete == false && Auth.auth().currentUser != nil{
            ///deleteCurrentUser()
            signOutCurrentUser()
            
            ///print("Temporary user deletion triggered")
        }
        
        /** Remove any cached users if they're from the sign up screen, haven't completed the account creation yet, and the internet is unavailable for them, the auth credentials for them will remain in the auth until they try to sign up again., this is to prevent the app from recognizing the cached user as a valid one due to the user linking one of the non primary auth credentials such as phone etc.*/
        if internetAvailable == false && Auth.auth().currentUser != nil{
            signOutCurrentUser()
            
            ///print("Temporary sign up user sign out triggered")
        }
    }
    
    @objc func appMovedToBackground(){
        /** Protect the user's information by obscuring the view with a blur effect view*/
        view.addSubview(blurredView)
        
        /** Resign the current textfield to protect the user's autofill information*/
        view.endEditing(true)
        
        lockPasswordTextfield()
    }
    
    @objc func appMovedToForeground(){
        /** Unblur the view's content*/
        blurredView.removeFromSuperview()
        
        /** Start animating the dashed border because the animation is removed when the view is off screen*/
        profilePictureImageViewAnimatedBorder.animateDashedBorder()
    }
    
    /** Activates when the application regains focus*/
    @objc func appDidBecomeActive(){
        /** Unblur the view's content*/
        blurredView.removeFromSuperview()
    }
    
    /** Activates when app is fully in the background state*/
    @objc func appIsInBackground(){
    }
    
    /** Set up notifications from app delegate to know when the app goes to or from the background state*/
    func setNotificationCenter(){
        let notifCenter = NotificationCenter.default
        notifCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appIsInBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    /**Create a blurred UIView and return it back to a lazy variable to be used when it's needed*/
    func getBlurredView()->UIVisualEffectView{
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        effectView.frame = view.frame
        effectView.layer.zPosition = 2
        
        /** How to access the app's accent color aka the global tint color*/
        /**effectView.backgroundColor = self.view.tintColor*/
        
        effectView.backgroundColor = appThemeColor
        
        let logoImageView = UIImageView(frame: CGRect(x: (0), y: 0, width: view.frame.width * 0.9, height: view.frame.width * 0.9))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(named: "StuyWashNDryLogoWhite")
        logoImageView.backgroundColor = .clear
        logoImageView.clipsToBounds = true
        logoImageView.tintColor = .white
        
        logoImageView.frame.origin = CGPoint(x: effectView.frame.width/2 - logoImageView.frame.width/2, y: effectView.frame.height/2 - logoImageView.frame.height/2)
        
        effectView.contentView.addSubview(logoImageView)
        return effectView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = bgColor
        
        accountCreationInProgress = true
        
        /** Sign out the current user to avoid a persistent login with an incomplete login credential*/
        signOutCurrentUser()
        
        supplementBackButton()
        buildUI()
        addVisualSingleTapGestureRecognizer()
        setUpKeyboardNotifications()
        setNotificationCenter()
        
        /** Specify a maximum font size*/
        self.view.maximumContentSizeCategory = .large
        
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
    
    /** Set up notifications for determining when the keyboard is shown and hidden*/
    func setUpKeyboardNotifications(){
        ///NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        ///NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /** Construct all elements of the user interface corresponding to this scene*/
    func buildUI(){
        pageControl.numberOfPages = collectionViewSlideCount
        pageControl.currentPage = 0
        pageControl.isUserInteractionEnabled = false
        pageControl.backgroundColor = UIColor.clear
        pageControl.alpha = 0
        
        /** Button to progress through the collection view*/
        continueButton.frame.size.height = 50
        continueButton.frame.size.width = continueButton.frame.height
        continueButton.backgroundColor = appThemeColor
        continueButton.tintColor = .white
        continueButton.setImage(UIImage(systemName: "arrow.forward", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        continueButton.alpha = 0.5
        continueButton.contentHorizontalAlignment = .center
        continueButton.titleLabel?.adjustsFontSizeToFitWidth = true
        continueButton.titleLabel?.adjustsFontForContentSizeCategory = true
        continueButton.layer.cornerRadius = continueButton.frame.height/2
        continueButton.isExclusiveTouch = true
        continueButton.isEnabled = false
        continueButton.frame.origin = CGPoint(x: 0, y: 0)
        continueButton.castDefaultShadow()
        continueButton.layer.shadowColor = appThemeColor.darker.cgColor
        continueButton.isHidden = true
        continueButton.alpha = 0
        continueButton.layer.zPosition = 1
        continueButton.addTarget(self, action: #selector(continueButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: continueButton)
        
        /** Introductory scene with 3 buttons prompting 3 outcomes from the sign up process*/
        let introductionScreen = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        introductionScreen.clipsToBounds = true
        introductionScreen.backgroundColor = bgColor
        
        let buttonSize = CGSize(width: view.frame.width/3 - 10, height: view.frame.width/3 - 10)
        customerButton.frame.size = buttonSize
        customerButton.frame.origin = CGPoint(x: view.frame.width/2 - buttonSize.width/2, y: view.frame.height/2 - buttonSize.height/2)
        switch darkMode{
        case true:
            customerButton.backgroundColor = bgColor.darker
        case false:
            customerButton.backgroundColor = bgColor
        }
        customerButton.contentHorizontalAlignment = .center
        customerButton.layer.cornerRadius = buttonSize.height/2
        customerButton.isExclusiveTouch = true
        customerButton.isEnabled = true
        customerButton.castDefaultShadow()
        customerButton.layer.shadowColor = appThemeColor.cgColor
        customerButton.setImage(UIImage(named: ["woman","man"].randomElement()!), for: .normal)
        customerButtonImage = customerButton.image(for: .normal)
        customerButton.imageView?.contentMode = .scaleAspectFit
        customerButton.imageEdgeInsets = UIEdgeInsets(top: buttonSize.height * 0.2, left: buttonSize.height * 0.2, bottom: buttonSize.height * 0.2, right: buttonSize.height * 0.2)
        customerButton.addTarget(self, action: #selector(customerButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: customerButton)
        
        let buttonLabelSize = CGSize(width: buttonSize.width, height: 40)
        customerButtonLabel.frame.size = CGSize(width: buttonLabelSize.width, height: buttonLabelSize.height)
        customerButtonLabel.frame.origin = CGPoint(x: customerButton.frame.origin.x, y: customerButton.frame.maxY + 10)
        customerButtonLabel.font = getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: true)
        customerButtonLabel.backgroundColor = appThemeColor
        customerButtonLabel.layer.cornerRadius = customerButtonLabel.frame.height/2
        customerButtonLabel.clipsToBounds = true
        customerButtonLabel.adjustsFontForContentSizeCategory = true
        customerButtonLabel.adjustsFontSizeToFitWidth = true
        customerButtonLabel.textColor = .white
        customerButtonLabel.text = "Customer"
        customerButtonLabel.textAlignment = .center
        
        businessButton.frame.size = buttonSize
        businessButton.frame.origin = CGPoint(x: customerButton.frame.minX - (businessButton.frame.width + 10), y: view.frame.height/2 - buttonSize.height/2)
        switch darkMode{
        case true:
            businessButton.backgroundColor = bgColor.darker
        case false:
            businessButton.backgroundColor = bgColor
        }
        businessButton.contentHorizontalAlignment = .center
        businessButton.layer.cornerRadius = buttonSize.height/2
        businessButton.isExclusiveTouch = true
        businessButton.isEnabled = true
        businessButton.castDefaultShadow()
        businessButton.layer.shadowColor = appThemeColor.cgColor
        businessButton.setImage(UIImage(named: "briefcase"), for: .normal)
        businessButton.imageView?.contentMode = .scaleAspectFit
        businessButton.imageEdgeInsets = UIEdgeInsets(top: buttonSize.height * 0.2, left: buttonSize.height * 0.2, bottom: buttonSize.height * 0.2, right: buttonSize.height * 0.2)
        businessButton.addTarget(self, action: #selector(businessButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: businessButton)
        
        businessButtonLabel.frame.size = CGSize(width: buttonLabelSize.width, height: buttonLabelSize.height)
        businessButtonLabel.frame.origin = CGPoint(x: businessButton.frame.origin.x, y: businessButton.frame.maxY + 10)
        businessButtonLabel.font = getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: true)
        businessButtonLabel.backgroundColor = .clear
        businessButtonLabel.adjustsFontForContentSizeCategory = true
        businessButtonLabel.adjustsFontSizeToFitWidth = true
        businessButtonLabel.textColor = appThemeColor
        businessButtonLabel.text = "Business"
        businessButtonLabel.textAlignment = .center
        businessButtonLabel.clipsToBounds = true
        businessButtonLabel.layer.cornerRadius = businessButtonLabel.frame.height/2
        
        driverButton.frame.size = buttonSize
        driverButton.frame.origin = CGPoint(x: customerButton.frame.maxX + 10, y: view.frame.height/2 - buttonSize.height/2)
        switch darkMode{
        case true:
            driverButton.backgroundColor = bgColor.darker
        case false:
            driverButton.backgroundColor = bgColor
        }
        driverButton.contentHorizontalAlignment = .center
        driverButton.layer.cornerRadius = buttonSize.height/2
        driverButton.isExclusiveTouch = true
        driverButton.isEnabled = true
        driverButton.castDefaultShadow()
        driverButton.layer.shadowColor = appThemeColor.cgColor
        driverButton.setImage(UIImage(named: "driver"), for: .normal)
        driverButton.imageView?.contentMode = .scaleAspectFit
        driverButton.imageEdgeInsets = UIEdgeInsets(top: buttonSize.height * 0.2, left: buttonSize.height * 0.2, bottom: buttonSize.height * 0.2, right: buttonSize.height * 0.2)
        driverButton.addTarget(self, action: #selector(driverButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: driverButton)
        
        driverButtonLabel.frame.size = CGSize(width: buttonLabelSize.width, height: buttonLabelSize.height)
        driverButtonLabel.frame.origin = CGPoint(x: driverButton.frame.origin.x, y: driverButton.frame.maxY + 10)
        driverButtonLabel.font = getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: true)
        driverButtonLabel.backgroundColor = .clear
        driverButtonLabel.adjustsFontForContentSizeCategory = true
        driverButtonLabel.adjustsFontSizeToFitWidth = true
        driverButtonLabel.textColor = appThemeColor
        driverButtonLabel.text = "Driver"
        driverButtonLabel.textAlignment = .center
        driverButtonLabel.clipsToBounds = true
        driverButtonLabel.layer.cornerRadius = driverButtonLabel.frame.height/2
        
        termsOfServiceButton = UIButton()
        termsOfServiceButton.frame.size = CGSize(width: view.frame.width/2, height: 40)
        termsOfServiceButton.backgroundColor = .clear
        termsOfServiceButton.setTitle("Terms of Service", for: .normal)
        termsOfServiceButton.setTitleColor(.white, for: .normal)
        termsOfServiceButton.titleLabel?.adjustsFontForContentSizeCategory = true
        termsOfServiceButton.titleLabel?.adjustsFontSizeToFitWidth = true
        termsOfServiceButton.titleLabel?.font = getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: true)
        termsOfServiceButton.setImage(UIImage(systemName: "info.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        termsOfServiceButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        termsOfServiceButton.tintColor = .white
        termsOfServiceButton.contentHorizontalAlignment = .center
        termsOfServiceButton.isExclusiveTouch = true
        termsOfServiceButton.isEnabled = true
        termsOfServiceButton.addTarget(self, action: #selector(termsOfServiceButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: termsOfServiceButton)
        
        termsOfServiceButtonContainer = UIView(frame: CGRect(x: 0, y: view.frame.height - (termsOfServiceButton.frame.height * 1.5), width: view.frame.width, height: termsOfServiceButton.frame.height * 1.5))
        termsOfServiceButtonContainer.clipsToBounds = true
        termsOfServiceButtonContainer.backgroundColor = appThemeColor
        termsOfServiceButton.frame.origin = CGPoint(x: termsOfServiceButtonContainer.frame.width/2 - termsOfServiceButton.frame.width/2, y: termsOfServiceButtonContainer.frame.height/2 - termsOfServiceButton.frame.height/2)
        termsOfServiceButtonContainer.layer.shadowColor = appThemeColor.cgColor
        termsOfServiceButtonContainer.layer.shadowRadius = 4
        termsOfServiceButtonContainer.layer.shadowOpacity = 1
        termsOfServiceButtonContainer.layer.masksToBounds = false
        termsOfServiceButtonContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        termsOfServiceButtonContainer.layer.shadowPath = UIBezierPath(roundedRect: termsOfServiceButtonContainer.bounds, cornerRadius: termsOfServiceButtonContainer.layer.cornerRadius).cgPath
        termsOfServiceButtonContainer.layer.zPosition = 1
        termsOfServiceButtonContainer.addSubview(termsOfServiceButton)
        
        let labelSize = CGSize(width: view.frame.width * 0.8, height: 40)
        let introductionPromptLabel = UILabel(frame: CGRect(x: view.frame.width/2 - labelSize.width/2, y: customerButton.frame.minY - (labelSize.height * 2), width: labelSize.width, height: labelSize.height))
        introductionPromptLabel.font = getCustomFont(name: .Ubuntu_bold, size: 25, dynamicSize: true)
        introductionPromptLabel.adjustsFontForContentSizeCategory = true
        introductionPromptLabel.adjustsFontSizeToFitWidth = true
        introductionPromptLabel.textColor = appThemeColor
        introductionPromptLabel.text = "Which user are you?"
        introductionPromptLabel.textAlignment = .center
        
        introductionScreen.addSubview(introductionPromptLabel)
        introductionScreen.addSubview(customerButton)
        introductionScreen.addSubview(customerButtonLabel)
        introductionScreen.addSubview(businessButton)
        introductionScreen.addSubview(businessButtonLabel)
        introductionScreen.addSubview(driverButton)
        introductionScreen.addSubview(driverButtonLabel)
        
        /** Specify the dimensions of this view in order for the buttons and subviews within it to render the touches inside*/
        completionScreen =  UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        
        collectionViewCells.append(introductionScreen)
        collectionViewCells.append(getEmailPhoneAuthScreen())
        collectionViewCells.append(getUsernamePasswordScreen())
        collectionViewCells.append(getNameAddressScreen())
        collectionViewCells.append(getGenderDOBScreen())
        collectionViewCells.append(completionScreen)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        /** Specify item size in order to allow the collectionview to encompass all of them*/
        layout.itemSize = view.frame.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), collectionViewLayout: layout)
        collectionView.register(SignUpVCCollectionViewCell.self, forCellWithReuseIdentifier: SignUpVCCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.backgroundColor = bgColor
        collectionView.isScrollEnabled = false
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.frame.origin = CGPoint(x: 0, y: 0)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isExclusiveTouch = true
        
        collectionView.contentSize = CGSize(width: view.frame.width * CGFloat(collectionViewSlideCount), height: view.frame.height)
        
        /** Top rectangle + triangle shape*/
        let topMaskPath = UIBezierPath()
        
        topMask.fillColor = bgColor.cgColor
        topMask.strokeColor = appThemeColor.cgColor
        topMask.strokeEnd = 1
        topMask.zPosition = 1
        
        /** Animate the shape layer being drawn on the view*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01){[self] in
            topMaskPath.move(to: CGPoint(x: view.frame.maxX, y: 0))
            topMaskPath.addLine(to: CGPoint(x: view.frame.maxX, y: view.frame.height * 0.2))
            topMaskPath.addLine(to: CGPoint(x: view.frame.width * 0.6, y: view.getStatusBarHeight()))
            topMaskPath.addLine(to: CGPoint(x: 0, y: view.getStatusBarHeight()))
            topMaskPath.addLine(to: CGPoint(x: 0, y: 0))
            topMaskPath.close()
            
            topMask.path = topMaskPath.cgPath
            
            /*
             let topMaskDrawingAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
             topMaskDrawingAnimation.fromValue = 0
             topMaskDrawingAnimation.toValue = 1
             topMaskDrawingAnimation.duration = 1
             topMaskDrawingAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
             
             DispatchQueue.main.asyncAfter(deadline: .now() + 1){
             /**Add a fill color and shadow to the drawn shape in a delayed fashion*/
             topMask.fillColor = appThemeColor.cgColor
             topMask.shadowColor = appThemeColor.cgColor
             topMask.shadowRadius = 10
             topMask.shadowOpacity = 1
             topMask.masksToBounds = false
             topMask.shadowOffset = CGSize(width: 0, height: 2)
             topMask.shadowPath = topMaskPath.cgPath
             }
             topMask.add(topMaskDrawingAnimation, forKey: "line")
             */
            
            topMask.fillColor = appThemeColor.cgColor
            topMask.shadowColor = appThemeColor.cgColor
            topMask.shadowRadius = 4
            topMask.shadowOpacity = 1
            topMask.masksToBounds = false
            topMask.shadowOffset = CGSize(width: 0, height: 2)
            topMask.shadowPath = topMaskPath.cgPath
            
            view.layer.addSublayer(topMask)
        }
        
        /** Lower right triangle + rectangle*/
        let bottomMaskPath = UIBezierPath()
        bottomMaskPath.move(to: CGPoint(x: view.frame.width * 0.5, y: termsOfServiceButtonContainer.frame.maxY))
        bottomMaskPath.addLine(to: CGPoint(x: 0, y: view.frame.height * 0.8))
        bottomMaskPath.addLine(to: CGPoint(x: 0, y: termsOfServiceButtonContainer.frame.maxY))
        bottomMaskPath.close()
        
        bottomMask.fillColor = bgColor.cgColor
        bottomMask.strokeColor = appThemeColor.cgColor
        bottomMask.strokeEnd = 1
        bottomMask.zPosition = 1
        bottomMask.fillColor = appThemeColor.cgColor
        bottomMask.shadowColor = appThemeColor.cgColor
        bottomMask.shadowRadius = 4
        bottomMask.shadowOpacity = 1
        bottomMask.masksToBounds = false
        bottomMask.shadowOffset = CGSize(width: 0, height: 2)
        bottomMask.shadowPath = bottomMaskPath.cgPath
        bottomMask.path = bottomMaskPath.cgPath
        
        /** UIView animations*/
        businessButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        customerButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        driverButton.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        businessButton.isUserInteractionEnabled = false
        customerButton.isUserInteractionEnabled = false
        driverButton.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            customerButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            customerButton.isUserInteractionEnabled = true
        }
        UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            businessButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            businessButton.isUserInteractionEnabled = true
        }
        UIView.animate(withDuration: 0.5, delay: 0.75, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            driverButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            driverButton.isUserInteractionEnabled = true
        }
        
        businessButtonLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
        customerButtonLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
        driverButtonLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
        introductionPromptLabel.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0.25){
            introductionPromptLabel.alpha = 1
        }
        UIView.animate(withDuration: 0.5, delay: 0.25){ [self] in
            customerButtonLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.5, delay: 0.5){ [self] in
            businessButtonLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.5, delay: 0.75){ [self] in
            driverButtonLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        /** UIView animations*/
        
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            termsOfServiceButtonContainer.transform = CGAffineTransform(translationX: 0, y: termsOfServiceButtonContainer.frame.height)
            
            UIView.animate(withDuration: 1, delay: 0, options: .curveLinear){[self] in
                termsOfServiceButtonContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
            bottomMaskCurrentYTranslation = view.frame.height * 0.5
            
            /** Animations for the top and bottom masks*/
            let topMaskTransformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            topMaskTransformAnimation.fromValue = -(view.frame.height * 0.5)
            topMaskTransformAnimation.toValue = 0
            topMaskTransformAnimation.duration = 1.5
            topMaskTransformAnimation.isRemovedOnCompletion = false
            topMaskTransformAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            topMask.add(topMaskTransformAnimation, forKey: "transform.translation.y")
            
            let bottomMaskTransformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            bottomMaskTransformAnimation.fromValue = bottomMaskCurrentYTranslation
            bottomMaskTransformAnimation.toValue = 0
            bottomMaskTransformAnimation.duration = 1
            bottomMaskTransformAnimation.isRemovedOnCompletion = false
            bottomMaskTransformAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            bottomMask.add(bottomMaskTransformAnimation, forKey: "transform.translation.y")
            
            bottomMaskCurrentYTranslation = 0
        }
        
        view.addSubview(collectionView)
        view.addSubview(backButton)
        view.layer.addSublayer(bottomMask)
        view.addSubview(termsOfServiceButtonContainer)
        view.addSubview(continueButton)
    }
    
    // MARK: - Screens
    /** Various UIViews to be added to the collection view*/
    func getEmailPhoneAuthScreen()->UIView{
        let view = UIView(frame: view.frame)
        
        appleSignInButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        appleSignInButton.frame.size.height = 60
        appleSignInButton.frame.size.width = appleSignInButton.frame.size.height
        switch darkMode{
        case true:
            appleSignInButton.backgroundColor = bgColor.darker
            appleSignInButton.setImage(#imageLiteral(resourceName: "apple-white"), for: .normal)
        case false:
            appleSignInButton.backgroundColor = bgColor
            appleSignInButton.setImage(#imageLiteral(resourceName: "apple"), for: .normal)
        }
        appleSignInButton.imageView?.contentMode = .scaleAspectFit
        appleSignInButton.layer.cornerRadius = appleSignInButton.frame.height/2
        appleSignInButton.castDefaultShadow()
        appleSignInButton.isEnabled = true
        appleSignInButton.isExclusiveTouch = true
        appleSignInButton.addTarget(self, action: #selector(appleSignInButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: appleSignInButton)
        
        googleSignInButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        googleSignInButton.frame.size.height = 60
        googleSignInButton.frame.size.width = googleSignInButton.frame.size.height
        switch darkMode{
        case true:
            googleSignInButton.backgroundColor = bgColor.darker
        case false:
            googleSignInButton.backgroundColor = bgColor
        }
        googleSignInButton.setImage(#imageLiteral(resourceName: "search"), for: .normal)
        googleSignInButton.imageView?.contentMode = .scaleAspectFit
        googleSignInButton.layer.cornerRadius = googleSignInButton.frame.height/2
        googleSignInButton.castDefaultShadow()
        googleSignInButton.isEnabled = true
        googleSignInButton.isExclusiveTouch = true
        googleSignInButton.addTarget(self, action: #selector(googleSignInButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: googleSignInButton)
        
        
        faceBookSignInButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        faceBookSignInButton.frame.size.height = 60
        faceBookSignInButton.frame.size.width = faceBookSignInButton.frame.size.height
        switch darkMode{
        case true:
            faceBookSignInButton.backgroundColor = bgColor.darker
        case false:
            faceBookSignInButton.backgroundColor = bgColor
        }
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
        faceBookSignInButton.frame.origin = CGPoint(x: view.frame.maxX - (faceBookSignInButton.frame.width * 1.25), y: termsOfServiceButtonContainer.frame.minY - (googleSignInButton.frame.height * 1.25))
        
        googleSignInButton.frame.origin = CGPoint(x: faceBookSignInButton.frame.minX - (googleSignInButton.frame.width + 10), y: faceBookSignInButton.frame.origin.y)
        
        appleSignInButton.frame.origin = CGPoint(x: googleSignInButton.frame.minX - (appleSignInButton.frame.width + 10), y: faceBookSignInButton.frame.origin.y)
        
        signUpWithThirdPartyLabel.frame.size = CGSize(width: view.frame.width/2, height: 40)
        signUpWithThirdPartyLabel.font = getCustomFont(name: .Ubuntu_bold, size: 18, dynamicSize: true)
        signUpWithThirdPartyLabel.adjustsFontForContentSizeCategory = true
        signUpWithThirdPartyLabel.adjustsFontSizeToFitWidth = true
        switch darkMode{
        case true:
            signUpWithThirdPartyLabel.backgroundColor = bgColor.darker
        case false:
            signUpWithThirdPartyLabel.backgroundColor = bgColor
        }
        signUpWithThirdPartyLabel.textColor = appThemeColor
        signUpWithThirdPartyLabel.text = "Link a third-party account:"
        signUpWithThirdPartyLabel.textAlignment = .center
        signUpWithThirdPartyLabel.layer.cornerRadius = signUpWithThirdPartyLabel.frame.height/3
        signUpWithThirdPartyLabel.layer.borderWidth = 0.25
        signUpWithThirdPartyLabel.layer.borderColor = appThemeColor.cgColor
        /** Don't apply the corner curve to these two corners*/
        signUpWithThirdPartyLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        signUpWithThirdPartyLabel.clipsToBounds = true
        signUpWithThirdPartyLabel.frame.origin = .zero
        
        let shadowView = UIShadowView(subview: signUpWithThirdPartyLabel, shadowColor: appThemeColor, shadowRadius: 0, shadowOpacity: 0)
        shadowView.setShadowOffset(shadowOffset: CGSize(width: 0, height: 1))
        shadowView.frame.origin = CGPoint(x: view.frame.maxX - shadowView.frame.width, y: faceBookSignInButton.frame.minY - shadowView.frame.height * 1.25)
        shadowView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        shadowView.addSubview(signUpWithThirdPartyLabel)
        
        let labelSize = CGSize(width: view.frame.width * 0.8, height: 40)
        let instructionLabel = UILabel(frame: CGRect(x: 10, y: backButton.frame.minY + 10, width: labelSize.width, height: labelSize.height))
        instructionLabel.font = getCustomFont(name: .Ubuntu_bold, size: 20, dynamicSize: true)
        instructionLabel.adjustsFontForContentSizeCategory = true
        instructionLabel.adjustsFontSizeToFitWidth = true
        instructionLabel.numberOfLines = 2
        instructionLabel.lineBreakMode = .byClipping
        instructionLabel.textColor = appThemeColor
        instructionLabel.text = "Enter your email address and phone number"
        instructionLabel.textAlignment = .left
        instructionLabel.sizeToFit()
        
        /** Specify the email address to be verified*/
        emailTextfield.frame.size.height = 50
        emailTextfield.frame.size.width = view.frame.width * 0.9
        emailTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            emailTextfield.backgroundColor = bgColor.lighter
            emailTextfield.textColor = fontColor
        case false:
            emailTextfield.backgroundColor = bgColor
            emailTextfield.textColor = fontColor
        }
        emailTextfield.layer.cornerRadius = emailTextfield.frame.height/2
        emailTextfield.adjustsFontForContentSizeCategory = true
        emailTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        emailTextfield.attributedPlaceholder = NSAttributedString(string:"Enter your email address", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        emailTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        var clearButton = emailTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        emailTextfield.textContentType = .emailAddress
        emailTextfield.keyboardType = .emailAddress
        emailTextfield.returnKeyType = .done
        emailTextfield.textAlignment = .left
        emailTextfield.delegate = self
        emailTextfield.autocorrectionType = .no
        emailTextfield.toolbarPlaceholder = "Email address"
        emailTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        emailTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        emailTextfield.layer.shadowOpacity = 0.25
        emailTextfield.layer.shadowRadius = 2
        emailTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        emailTextfield.layer.shadowPath = UIBezierPath(roundedRect: emailTextfield.bounds, cornerRadius: emailTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        emailTextfield.clipsToBounds = true
        emailTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        emailTextfield.borderStyle = .none
        emailTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        emailTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: emailTextfield.frame.height/(1.5), height: emailTextfield.frame.height/(1.5)))
        
        /** Button with a mail system image inside to style the text field up a bit*/
        let leftButton = UIButton()
        leftButton.setImage(UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton.frame.size = CGSize(width: emailTextfield.frame.height/(1.5), height: emailTextfield.frame.height/(1.5))
        leftButton.frame.origin = CGPoint(x: paddingView.frame.width/2 - leftButton.frame.width/2, y: paddingView.frame.height/2 - leftButton.frame.height/2)
        leftButton.backgroundColor = .clear
        leftButton.tintColor = appThemeColor
        leftButton.layer.cornerRadius = leftButton.frame.height/2
        leftButton.contentMode = .scaleAspectFit
        leftButton.isUserInteractionEnabled = false
        leftButton.clipsToBounds = true
        
        paddingView.addSubview(leftButton)
        emailTextfield.leftView = paddingView
        emailTextfield.leftViewMode = .always
        
        /** Specify the phone number to be verified*/
        phoneTextfield = USPhoneNumberTextField(frame: CGRect(x: 0, y: 0, width: 50, height: view.frame.width * 0.9))
        phoneTextfield.frame.size.height = 50
        phoneTextfield.frame.size.width = view.frame.width * 0.9
        phoneTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            phoneTextfield.backgroundColor = bgColor.lighter
            phoneTextfield.textColor = fontColor
        case false:
            phoneTextfield.backgroundColor = bgColor
            phoneTextfield.textColor = fontColor
        }
        
        phoneTextfield.layer.cornerRadius = phoneTextfield.frame.height/2
        phoneTextfield.adjustsFontForContentSizeCategory = true
        phoneTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 15, dynamicSize: true)
        phoneTextfield.attributedPlaceholder = NSAttributedString(string:"Enter your phone number", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        phoneTextfield.withExamplePlaceholder = true
        phoneTextfield.numberPlaceholderColor = .lightGray
        phoneTextfield.countryCodePlaceholderColor = .darkGray
        /** Max phone digits supported by the ITU excluding country code*/
        phoneTextfield.maxDigits = 15
        
        /** Settings*/
        phoneTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = phoneTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        phoneTextfield.withFlag = true
        phoneTextfield.withPrefix = true
        phoneTextfield.textContentType = .telephoneNumber
        phoneTextfield.keyboardType = .phonePad
        phoneTextfield.returnKeyType = .done
        phoneTextfield.textAlignment = .left
        phoneTextfield.delegate = self
        phoneTextfield.autocorrectionType = .no
        phoneTextfield.toolbarPlaceholder = "Phone number"
        /** Disable the country code picker*/
        phoneTextfield.withDefaultPickerUI = false
        phoneTextfield.keyboardAppearance = .light
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(countryPickerViewTapped))
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.requiresExclusiveTouchType = true
        phoneTextfield.leftView?.addGestureRecognizer(tapGestureRecognizer)
        
        /** Shadow properties*/
        phoneTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        phoneTextfield.layer.shadowOpacity = 0.25
        phoneTextfield.layer.shadowRadius = 2
        phoneTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        phoneTextfield.layer.shadowPath = UIBezierPath(roundedRect: phoneTextfield.bounds, cornerRadius: phoneTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        phoneTextfield.clipsToBounds = true
        phoneTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        phoneTextfield.borderStyle = .none
        phoneTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        phoneTextfield.layer.borderWidth = 1
        
        verifyPhoneButton.frame.size.height = 40
        verifyPhoneButton.frame.size.width = (view.frame.width * 0.4 - 10)
        switch darkMode{
        case true:
            verifyPhoneButton.backgroundColor = bgColor.darker
        case false:
            verifyPhoneButton.backgroundColor = bgColor
        }
        verifyPhoneButton.alpha = 0.5
        verifyPhoneButton.setTitle("Verify Phone #", for: .normal)
        verifyPhoneButton.setTitleColor(appThemeColor, for: .normal)
        verifyPhoneButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        verifyPhoneButton.contentHorizontalAlignment = .center
        verifyPhoneButton.titleLabel?.adjustsFontSizeToFitWidth = true
        verifyPhoneButton.titleLabel?.adjustsFontForContentSizeCategory = true
        verifyPhoneButton.layer.cornerRadius = verifyPhoneButton.frame.height/2
        verifyPhoneButton.isExclusiveTouch = true
        verifyPhoneButton.isEnabled = false
        verifyPhoneButton.castDefaultShadow()
        verifyPhoneButton.layer.shadowColor = UIColor.lightGray.cgColor
        verifyPhoneButton.setImage(UIImage(systemName: "phone.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        verifyPhoneButton.addTarget(self, action: #selector(verifyPhoneButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: verifyPhoneButton)
        
        resendOTPButton.frame.size.height = 40
        resendOTPButton.frame.size.width = resendOTPButton.frame.height
        resendOTPButton.backgroundColor = appThemeColor
        resendOTPButton.alpha = 0
        resendOTPButton.tintColor = .white
        resendOTPButton.contentHorizontalAlignment = .center
        resendOTPButton.titleLabel?.adjustsFontSizeToFitWidth = true
        resendOTPButton.titleLabel?.adjustsFontForContentSizeCategory = true
        resendOTPButton.layer.cornerRadius = resendOTPButton.frame.height/2
        resendOTPButton.isExclusiveTouch = true
        resendOTPButton.isEnabled = false
        resendOTPButton.castDefaultShadow()
        resendOTPButton.layer.shadowColor = UIColor.lightGray.cgColor
        resendOTPButton.setImage(UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        resendOTPButton.addTarget(self, action: #selector(resendOTPButtonPressed), for: .touchUpInside)
        
        otpCountDownLabel.frame.size.height = 40
        otpCountDownLabel.frame.size.width = (view.frame.width * 0.4 - 10)
        otpCountDownLabel.backgroundColor = bgColor
        otpCountDownLabel.alpha = 0
        otpCountDownLabel.text = "1:00"
        otpCountDownLabel.textColor = appThemeColor
        otpCountDownLabel.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        otpCountDownLabel.textAlignment = .left
        otpCountDownLabel.adjustsFontSizeToFitWidth = true
        otpCountDownLabel.adjustsFontForContentSizeCategory = true
        otpCountDownLabel.sizeToFit()
        
        OTPTextFieldContainer.frame.size.height = 50
        OTPTextFieldContainer.frame.size.width = view.frame.width * 0.95
        OTPTextFieldContainer.clipsToBounds = false
        OTPTextFieldContainer.backgroundColor = .clear
        /** Hide this container and its subviews*/
        OTPTextFieldContainer.isHidden = true
        OTPTextFieldContainer.alpha = 0
        
        OTPTextFields.append(OTPTextField_1)
        OTPTextFields.append(OTPTextField_2)
        OTPTextFields.append(OTPTextField_3)
        OTPTextFields.append(OTPTextField_4)
        OTPTextFields.append(OTPTextField_5)
        OTPTextFields.append(OTPTextField_6)
        
        for textField in OTPTextFields{
            textField.frame.size.height = 50
            textField.frame.size.width = OTPTextFieldContainer.frame.width/6 - 10
            textField.tintColor = appThemeColor
            textField.backgroundColor = bgColor.darker
            textField.textColor = appThemeColor
            textField.layer.cornerRadius = textField.frame.height/4
            textField.adjustsFontForContentSizeCategory = true
            textField.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
            
            /** Settings*/
            textField.pasteDelegate = self
            textField.textContentType = .oneTimeCode
            textField.keyboardType = .numberPad
            textField.returnKeyType = .continue
            textField.textAlignment = .center
            textField.delegate = self
            textField.autocorrectionType = .no
            textField.toolbarPlaceholder = ""
            textField.keyboardAppearance = .light
            
            /** Shadow properties*/
            textField.layer.shadowColor = UIColor.lightGray.cgColor
            textField.layer.shadowOpacity = 0.25
            textField.layer.shadowRadius = 1
            textField.layer.shadowOffset = CGSize(width: 0, height: 2)
            textField.layer.shadowPath = UIBezierPath(roundedRect: textField.bounds, cornerRadius: textField.layer.cornerRadius).cgPath
            
            /** Border properties*/
            textField.clipsToBounds = true
            textField.layer.masksToBounds = false
            /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
            textField.borderStyle = .none
            textField.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
            textField.layer.borderWidth = 1
            
            OTPTextFieldContainer.addSubview(textField)
        }
        
        /** Layout these subviews*/
        instructionLabel.frame = CGRect(x: 10, y: backButton.frame.maxY + 10, width: labelSize.width, height: labelSize.height)
        
        /** Entry textfields*/
        emailTextfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: instructionLabel.frame.maxY + 20)
        phoneTextfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: emailTextfield.frame.maxY + 10)
        
        /** Verification buttons*/
        verifyPhoneButton.frame.origin = CGPoint(x: 10, y: phoneTextfield.frame.maxY + 10)
        resendOTPButton.frame.origin = CGPoint(x: verifyPhoneButton.frame.maxX + 10, y: verifyPhoneButton.frame.origin.y)
        
        otpCountDownLabel.frame.origin = CGPoint(x: 10, y: verifyPhoneButton.frame.maxY + 10)
        
        /** One time code textfields*/
        OTPTextFieldContainer.frame.origin = CGPoint(x: view.frame.width/2 - OTPTextFieldContainer.frame.width/2, y: phoneTextfield.frame.maxY + 10)
        OTPTextField_1.frame.origin = CGPoint(x: 0, y: OTPTextFieldContainer.frame.height/2 - OTPTextField_1.frame.height/2)
        OTPTextField_2.frame.origin = CGPoint(x: OTPTextField_1.frame.maxX + 10, y: OTPTextField_1.frame.origin.y)
        OTPTextField_3.frame.origin = CGPoint(x: OTPTextField_2.frame.maxX + 10, y: OTPTextField_1.frame.origin.y)
        OTPTextField_4.frame.origin = CGPoint(x: OTPTextField_3.frame.maxX + 10, y: OTPTextField_1.frame.origin.y)
        OTPTextField_5.frame.origin = CGPoint(x: OTPTextField_4.frame.maxX + 10, y: OTPTextField_1.frame.origin.y)
        OTPTextField_6.frame.origin = CGPoint(x: OTPTextField_5.frame.maxX + 10, y: OTPTextField_1.frame.origin.y)
        
        view.addSubview(googleSignInButton)
        view.addSubview(appleSignInButton)
        view.addSubview(faceBookSignInButton)
        view.addSubview(shadowView)
        view.addSubview(instructionLabel)
        view.addSubview(emailTextfield)
        view.addSubview(phoneTextfield)
        view.addSubview(verifyPhoneButton)
        view.addSubview(resendOTPButton)
        view.addSubview(otpCountDownLabel)
        view.addSubview(OTPTextFieldContainer)
        
        return view
    }
    
    /** When the user tries to change the country code, inform them that this service is only available in the U.S.*/
    @objc func countryPickerViewTapped(sender: UITapGestureRecognizer){
        sender.isEnabled = false
        
        /** Prevent frequent taps by disabling and enabling the button after 1 second*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            sender.isEnabled = true
        }
        
        globallyTransmit(this: "Sorry, our services are only available in the United States", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .none, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
        
        errorShake()
    }
    
    func getUsernamePasswordScreen()->UIView{
        let view = UIView(frame: view.frame)
        
        let labelSize = CGSize(width: view.frame.width * 0.75, height: 40)
        let instructionLabel = UILabel(frame: CGRect(x: 10, y: backButton.frame.minY + 10, width: labelSize.width, height: labelSize.height))
        instructionLabel.font = getCustomFont(name: .Ubuntu_bold, size: 20, dynamicSize: true)
        instructionLabel.adjustsFontForContentSizeCategory = true
        instructionLabel.adjustsFontSizeToFitWidth = true
        instructionLabel.numberOfLines = 2
        instructionLabel.lineBreakMode = .byClipping
        instructionLabel.textColor = appThemeColor
        instructionLabel.text = "Create your username and password"
        instructionLabel.textAlignment = .left
        instructionLabel.sizeToFit()
        
        /** Specify the new username to be verified*/
        usernameTextfield.frame.size.height = 50
        usernameTextfield.frame.size.width = view.frame.width * 0.9
        usernameTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            usernameTextfield.backgroundColor = bgColor.lighter
            usernameTextfield.textColor = fontColor
        case false:
            usernameTextfield.backgroundColor = bgColor
            usernameTextfield.textColor = fontColor
        }
        usernameTextfield.layer.cornerRadius = usernameTextfield.frame.height/2
        usernameTextfield.adjustsFontForContentSizeCategory = true
        usernameTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        usernameTextfield.attributedPlaceholder = NSAttributedString(string:"Enter a username", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        usernameTextfield.addTarget(self, action: #selector(usernameTextfieldChanged), for: .editingChanged)
        
        /** Settings*/
        usernameTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        var clearButton = usernameTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        usernameTextfield.textContentType = .username
        usernameTextfield.keyboardType = .asciiCapable
        usernameTextfield.returnKeyType = .done
        usernameTextfield.textAlignment = .left
        usernameTextfield.delegate = self
        usernameTextfield.autocorrectionType = .no
        usernameTextfield.toolbarPlaceholder = "Username"
        usernameTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        usernameTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        usernameTextfield.layer.shadowOpacity = 0.25
        usernameTextfield.layer.shadowRadius = 8
        usernameTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        usernameTextfield.layer.shadowPath = UIBezierPath(roundedRect: usernameTextfield.bounds, cornerRadius: usernameTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        usernameTextfield.clipsToBounds = true
        usernameTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        usernameTextfield.borderStyle = .none
        usernameTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        usernameTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: usernameTextfield.frame.height/(1.5), height: usernameTextfield.frame.height/(1.5)))
        
        let leftButton = UIButton()
        leftButton.setImage(UIImage(systemName: "at.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton.frame.size = CGSize(width: usernameTextfield.frame.height/(1.5), height: usernameTextfield.frame.height/(1.5))
        leftButton.frame.origin = CGPoint(x: paddingView.frame.width/2 - leftButton.frame.width/2, y: paddingView.frame.height/2 - leftButton.frame.height/2)
        leftButton.backgroundColor = .clear
        leftButton.tintColor = appThemeColor
        leftButton.layer.cornerRadius = leftButton.frame.height/2
        leftButton.contentMode = .scaleAspectFit
        leftButton.isUserInteractionEnabled = false
        leftButton.clipsToBounds = true
        
        paddingView.addSubview(leftButton)
        usernameTextfield.leftView = paddingView
        usernameTextfield.leftViewMode = .always
        
        /** Textfield for the user to enter a new password for their account*/
        passwordTextfield.frame.size.height = 50
        passwordTextfield.frame.size.width = view.frame.width * 0.9
        passwordTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            passwordTextfield.backgroundColor = bgColor.lighter
            passwordTextfield.textColor = fontColor
        case false:
            passwordTextfield.backgroundColor = bgColor
            passwordTextfield.textColor = fontColor
        }
        passwordTextfield.layer.cornerRadius = passwordTextfield.frame.height/2
        passwordTextfield.adjustsFontForContentSizeCategory = true
        passwordTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        passwordTextfield.attributedPlaceholder = NSAttributedString(string:"Create a password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        passwordTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = passwordTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        passwordTextfield.textContentType = .newPassword
        passwordTextfield.keyboardType = .asciiCapable
        passwordTextfield.returnKeyType = .done
        passwordTextfield.textAlignment = .left
        passwordTextfield.delegate = self
        passwordTextfield.autocorrectionType = .no
        passwordTextfield.toolbarPlaceholder = "Password"
        passwordTextfield.keyboardAppearance = .light
        passwordTextfield.isSecureTextEntry = true
        passwordTextfield.passwordRules = UITextInputPasswordRules(descriptor: "required: upper; required: lower; required: digit; required: [-().&@?'#,/&quot;+]; minlength: 8;")
        
        /** Shadow properties*/
        passwordTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        passwordTextfield.layer.shadowOpacity = 0.25
        passwordTextfield.layer.shadowRadius = 8
        passwordTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        passwordTextfield.layer.shadowPath = UIBezierPath(roundedRect: passwordTextfield.bounds, cornerRadius: passwordTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        passwordTextfield.clipsToBounds = true
        passwordTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        passwordTextfield.borderStyle = .none
        passwordTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        passwordTextfield.layer.borderWidth = 1
        passwordTextfield.addTarget(self, action: #selector(passwordTextfieldChanged), for: .editingChanged)
        
        /** Custom overlay button view for the textfield*/
        /** Container for the image view*/
        let paddingView_2 = UIView(frame: CGRect(x: 0, y: 0, width: passwordTextfield.frame.height/(1.5), height: passwordTextfield.frame.height/(1.5)))
        
        passwordTextfieldLeftButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        
        let passwordTextfieldLeftButtonPressed = UIAction(){ [self] action in
            lightHaptic()
            
            if usePasswordSecurity == true{
                unlockPasswordTextfield()
            }else{
                lockPasswordTextfield()
            }
        }
        
        passwordTextfieldLeftButton.addAction(passwordTextfieldLeftButtonPressed, for: .touchUpInside)
        passwordTextfieldLeftButton.frame.size = CGSize(width: passwordTextfield.frame.height/2, height: passwordTextfield.frame.height/2)
        passwordTextfieldLeftButton.frame.origin = CGPoint(x: paddingView_2.frame.width/2 - passwordTextfieldLeftButton.frame.width/2, y: paddingView_2.frame.height/2 - passwordTextfieldLeftButton.frame.height/2)
        passwordTextfieldLeftButton.backgroundColor = .clear
        passwordTextfieldLeftButton.tintColor = appThemeColor
        passwordTextfieldLeftButton.layer.cornerRadius = passwordTextfieldLeftButton.frame.height/2
        passwordTextfieldLeftButton.contentMode = .scaleAspectFit
        passwordTextfieldLeftButton.clipsToBounds = true
        
        paddingView_2.addSubview(passwordTextfieldLeftButton)
        passwordTextfield.leftView = paddingView_2
        passwordTextfield.leftViewMode = .always
        
        /** Dynamic UI describing the requirements for the username field*/
        usernameRequirementsContainer.frame.size = CGSize(width: usernameTextfield.frame.width, height: view.frame.height * 0.2)
        usernameRequirementsContainer.backgroundColor = .clear
        usernameRequirementsContainer.alpha = 0
        
        usernameRequirementsTitleLabel.frame.size = CGSize(width: usernameRequirementsContainer.frame.width, height: usernameRequirementsContainer.frame.height/5)
        usernameRequirementsTitleLabel.font = getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: true)
        usernameRequirementsTitleLabel.adjustsFontForContentSizeCategory = true
        usernameRequirementsTitleLabel.adjustsFontSizeToFitWidth = true
        usernameRequirementsTitleLabel.numberOfLines = 2
        usernameRequirementsTitleLabel.lineBreakMode = .byClipping
        usernameRequirementsTitleLabel.textColor = appThemeColor
        usernameRequirementsTitleLabel.text = "Username requirements:"
        usernameRequirementsTitleLabel.textAlignment = .left
        
        usernameRequirement_1.frame.size = CGSize(width: usernameRequirementsContainer.frame.width, height: usernameRequirementsContainer.frame.height/5 - 5)
        usernameRequirement_1.backgroundColor = .clear
        usernameRequirement_1.tintColor = .red
        usernameRequirement_1.setTitle(" Minimum length of 3 and a maximum of 30 characters", for: .normal)
        usernameRequirement_1.setTitleColor(appThemeColor, for: .normal)
        usernameRequirement_1.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        usernameRequirement_1.contentHorizontalAlignment = .left
        usernameRequirement_1.titleLabel?.adjustsFontSizeToFitWidth = true
        usernameRequirement_1.titleLabel?.adjustsFontForContentSizeCategory = true
        usernameRequirement_1.isExclusiveTouch = true
        usernameRequirement_1.isUserInteractionEnabled = false
        usernameRequirement_1.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        usernameRequirement_1.imageView?.contentMode = .scaleAspectFit
        
        usernameRequirement_2.frame.size = CGSize(width: usernameRequirementsContainer.frame.width, height: usernameRequirementsContainer.frame.height/5 - 5)
        usernameRequirement_2.backgroundColor = .clear
        usernameRequirement_2.tintColor = .red
        usernameRequirement_2.setTitle(" Can not start or end with a period (.user.)", for: .normal)
        usernameRequirement_2.setTitleColor(appThemeColor, for: .normal)
        usernameRequirement_2.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        usernameRequirement_2.contentHorizontalAlignment = .left
        usernameRequirement_2.titleLabel?.adjustsFontSizeToFitWidth = true
        usernameRequirement_2.titleLabel?.adjustsFontForContentSizeCategory = true
        usernameRequirement_2.isExclusiveTouch = true
        usernameRequirement_2.isUserInteractionEnabled = false
        usernameRequirement_2.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        usernameRequirement_2.imageView?.contentMode = .scaleAspectFit
        
        usernameRequirement_3.frame.size = CGSize(width: usernameRequirementsContainer.frame.width, height: usernameRequirementsContainer.frame.height/5 - 5)
        usernameRequirement_3.backgroundColor = .clear
        usernameRequirement_3.tintColor = .red
        usernameRequirement_3.setTitle(" Can not contain sequential (_.-) characters", for: .normal)
        usernameRequirement_3.setTitleColor(appThemeColor, for: .normal)
        usernameRequirement_3.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        usernameRequirement_3.contentHorizontalAlignment = .left
        usernameRequirement_3.titleLabel?.adjustsFontSizeToFitWidth = true
        usernameRequirement_3.titleLabel?.adjustsFontForContentSizeCategory = true
        usernameRequirement_3.isExclusiveTouch = true
        usernameRequirement_3.isUserInteractionEnabled = false
        usernameRequirement_3.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        usernameRequirement_3.imageView?.contentMode = .scaleAspectFit
        
        usernameRequirement_4.frame.size = CGSize(width: usernameRequirementsContainer.frame.width, height: usernameRequirementsContainer.frame.height/5 - 5)
        usernameRequirement_4.backgroundColor = .clear
        usernameRequirement_4.tintColor = .red
        usernameRequirement_4.setTitle(" Can only contain the characters: (a-z) (A-Z) (0-9) (_.-)", for: .normal)
        usernameRequirement_4.setTitleColor(appThemeColor, for: .normal)
        usernameRequirement_4.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        usernameRequirement_4.contentHorizontalAlignment = .left
        usernameRequirement_4.titleLabel?.adjustsFontSizeToFitWidth = true
        usernameRequirement_4.titleLabel?.adjustsFontForContentSizeCategory = true
        usernameRequirement_4.isExclusiveTouch = true
        usernameRequirement_4.isUserInteractionEnabled = false
        usernameRequirement_4.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        usernameRequirement_4.imageView?.contentMode = .scaleAspectFit
        
        usernameRequirementsContainer.addSubview(usernameRequirementsTitleLabel)
        usernameRequirementsContainer.addSubview(usernameRequirement_1)
        usernameRequirementsContainer.addSubview(usernameRequirement_2)
        usernameRequirementsContainer.addSubview(usernameRequirement_3)
        usernameRequirementsContainer.addSubview(usernameRequirement_4)
        
        /** Dynamic UI describing the requirements for the password field*/
        passwordRequirementsContainer.frame.size = CGSize(width: passwordTextfield.frame.width, height: view.frame.height * 0.2)
        passwordRequirementsContainer.backgroundColor = .clear
        passwordRequirementsContainer.alpha = 0
        
        passwordRequirementsTitleLabel.frame.size = CGSize(width: passwordRequirementsContainer.frame.width, height: passwordRequirementsContainer.frame.height/5)
        passwordRequirementsTitleLabel.font = getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: true)
        passwordRequirementsTitleLabel.adjustsFontForContentSizeCategory = true
        passwordRequirementsTitleLabel.adjustsFontSizeToFitWidth = true
        passwordRequirementsTitleLabel.numberOfLines = 2
        passwordRequirementsTitleLabel.lineBreakMode = .byClipping
        passwordRequirementsTitleLabel.textColor = appThemeColor
        passwordRequirementsTitleLabel.text = "Password requirements:"
        passwordRequirementsTitleLabel.textAlignment = .left
        
        passwordRequirement_1.frame.size = CGSize(width: passwordRequirementsContainer.frame.width, height: passwordRequirementsContainer.frame.height/6 - 5)
        passwordRequirement_1.backgroundColor = .clear
        passwordRequirement_1.tintColor = .red
        passwordRequirement_1.setTitle(" Must be at least 8 characters long", for: .normal)
        passwordRequirement_1.setTitleColor(appThemeColor, for: .normal)
        passwordRequirement_1.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        passwordRequirement_1.contentHorizontalAlignment = .left
        passwordRequirement_1.titleLabel?.adjustsFontSizeToFitWidth = true
        passwordRequirement_1.titleLabel?.adjustsFontForContentSizeCategory = true
        passwordRequirement_1.isExclusiveTouch = true
        passwordRequirement_1.isUserInteractionEnabled = false
        passwordRequirement_1.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        passwordRequirement_1.imageView?.contentMode = .scaleAspectFit
        
        passwordRequirement_2.frame.size = CGSize(width: passwordRequirementsContainer.frame.width, height: passwordRequirementsContainer.frame.height/6 - 5)
        passwordRequirement_2.backgroundColor = .clear
        passwordRequirement_2.tintColor = .red
        passwordRequirement_2.setTitle(" Must contain at least one uppercase letter (A-Z)", for: .normal)
        passwordRequirement_2.setTitleColor(appThemeColor, for: .normal)
        passwordRequirement_2.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        passwordRequirement_2.contentHorizontalAlignment = .left
        passwordRequirement_2.titleLabel?.adjustsFontSizeToFitWidth = true
        passwordRequirement_2.titleLabel?.adjustsFontForContentSizeCategory = true
        passwordRequirement_2.isExclusiveTouch = true
        passwordRequirement_2.isUserInteractionEnabled = false
        passwordRequirement_2.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        passwordRequirement_2.imageView?.contentMode = .scaleAspectFit
        
        passwordRequirement_3.frame.size = CGSize(width: passwordRequirementsContainer.frame.width, height: passwordRequirementsContainer.frame.height/6 - 5)
        passwordRequirement_3.backgroundColor = .clear
        passwordRequirement_3.tintColor = .red
        passwordRequirement_3.setTitle(" Must contain at least one lowercase letter (a-z)", for: .normal)
        passwordRequirement_3.setTitleColor(appThemeColor, for: .normal)
        passwordRequirement_3.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        passwordRequirement_3.contentHorizontalAlignment = .left
        passwordRequirement_3.titleLabel?.adjustsFontSizeToFitWidth = true
        passwordRequirement_3.titleLabel?.adjustsFontForContentSizeCategory = true
        passwordRequirement_3.isExclusiveTouch = true
        passwordRequirement_3.isUserInteractionEnabled = false
        passwordRequirement_3.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        passwordRequirement_3.imageView?.contentMode = .scaleAspectFit
        
        passwordRequirement_4.frame.size = CGSize(width: passwordRequirementsContainer.frame.width, height: passwordRequirementsContainer.frame.height/6 - 5)
        passwordRequirement_4.backgroundColor = .clear
        passwordRequirement_4.tintColor = .red
        passwordRequirement_4.setTitle(" Must contain at least one number (0-9)", for: .normal)
        passwordRequirement_4.setTitleColor(appThemeColor, for: .normal)
        passwordRequirement_4.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        passwordRequirement_4.contentHorizontalAlignment = .left
        passwordRequirement_4.titleLabel?.adjustsFontSizeToFitWidth = true
        passwordRequirement_4.titleLabel?.adjustsFontForContentSizeCategory = true
        passwordRequirement_4.isExclusiveTouch = true
        passwordRequirement_4.isUserInteractionEnabled = false
        passwordRequirement_4.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        passwordRequirement_4.imageView?.contentMode = .scaleAspectFit
        
        passwordRequirement_5.frame.size = CGSize(width: passwordRequirementsContainer.frame.width, height: passwordRequirementsContainer.frame.height/6 - 5)
        passwordRequirement_5.backgroundColor = .clear
        passwordRequirement_5.tintColor = .red
        passwordRequirement_5.setTitle(" Must contain at least one special character (#?!@$%^&*-)", for: .normal)
        passwordRequirement_5.setTitleColor(appThemeColor, for: .normal)
        passwordRequirement_5.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        passwordRequirement_5.contentHorizontalAlignment = .left
        passwordRequirement_5.titleLabel?.adjustsFontSizeToFitWidth = true
        passwordRequirement_5.titleLabel?.adjustsFontForContentSizeCategory = true
        passwordRequirement_5.isExclusiveTouch = true
        passwordRequirement_5.isUserInteractionEnabled = false
        passwordRequirement_5.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        passwordRequirement_5.imageView?.contentMode = .scaleAspectFit
        
        passwordRequirementsContainer.addSubview(passwordRequirementsTitleLabel)
        passwordRequirementsContainer.addSubview(passwordRequirement_1)
        passwordRequirementsContainer.addSubview(passwordRequirement_2)
        passwordRequirementsContainer.addSubview(passwordRequirement_3)
        passwordRequirementsContainer.addSubview(passwordRequirement_4)
        passwordRequirementsContainer.addSubview(passwordRequirement_5)
        
        /** Layout these subviews*/
        instructionLabel.frame = CGRect(x: 10, y: backButton.frame.maxY + 10, width: labelSize.width, height: labelSize.height)
        
        /** Entry textfields*/
        usernameTextfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: instructionLabel.frame.maxY + 20)
        passwordTextfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: usernameTextfield.frame.maxY + 10)
        
        /** Requirements UI*/
        usernameRequirementsContainer.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: usernameTextfield.frame.maxY + 10)
        usernameRequirementsTitleLabel.frame.origin = CGPoint(x: 0, y: 0)
        usernameRequirement_1.frame.origin = CGPoint(x: 0, y: usernameRequirementsTitleLabel.frame.maxY + 5)
        usernameRequirement_2.frame.origin = CGPoint(x: 0, y: usernameRequirement_1.frame.maxY + 5)
        usernameRequirement_3.frame.origin = CGPoint(x: 0, y: usernameRequirement_2.frame.maxY + 5)
        usernameRequirement_4.frame.origin = CGPoint(x: 0, y: usernameRequirement_3.frame.maxY + 5)
        
        passwordRequirementsContainer.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: passwordTextfield.frame.maxY + 10)
        passwordRequirementsTitleLabel.frame.origin = CGPoint(x: 0, y: 0)
        passwordRequirement_1.frame.origin = CGPoint(x: 0, y: passwordRequirementsTitleLabel.frame.maxY + 5)
        passwordRequirement_2.frame.origin = CGPoint(x: 0, y: passwordRequirement_1.frame.maxY + 5)
        passwordRequirement_3.frame.origin = CGPoint(x: 0, y: passwordRequirement_2.frame.maxY + 5)
        passwordRequirement_4.frame.origin = CGPoint(x: 0, y: passwordRequirement_3.frame.maxY + 5)
        passwordRequirement_5.frame.origin = CGPoint(x: 0, y: passwordRequirement_4.frame.maxY + 5)
        
        view.addSubview(instructionLabel)
        view.addSubview(usernameTextfield)
        view.addSubview(passwordTextfield)
        view.addSubview(usernameRequirementsContainer)
        view.addSubview(passwordRequirementsContainer)
        
        return view
    }
    
    /** Username and password textfield editing listeners*/
    /** Detect when the password textfield has been edited*/
    @objc func usernameTextfieldChanged(sender: UITextField){
        /** Look at the text field's current content after being cleared*/
        let changedString = sender.text ?? ""
        
        /** if the changed string is empty then there's nothing to verify so mark all requirements as unsatisfied*/
        if changedString == ""{
            usernameRequirement_1.tintColor = .red
            usernameRequirement_2.tintColor = .red
            usernameRequirement_3.tintColor = .red
            usernameRequirement_4.tintColor = .red
            
            return
        }
        
        /** Make sure the username has at least 3 characters and 30 maximum*/
        let eightCharactersRegEx = "^(.{3,30}$)"
        if changedString.range(of: eightCharactersRegEx, options: .regularExpression) != nil{
            /** If the password satisfies this regular expression parameter then mark its matching password requirement button as satisfied by changing the tintcolor to green*/
            usernameRequirement_1.tintColor = .green
        }
        else{
            usernameRequirement_1.tintColor = .red
        }
        
        /** Make sure the username doesn't have a period or underscore or dash at the beginning or end*/
        let periodRegEx = "^(?=.{1,})[^_.-].*[^_.-]$"
        if changedString.range(of: periodRegEx, options: .regularExpression) != nil{
            usernameRequirement_2.tintColor = .green
        }
        else{
            usernameRequirement_2.tintColor = .red
        }
        
        /** Make sure the username doesn't have sequential (2+) periods and underscores and dashes side by side*/
        let sequentialRegEx = "^(?!.*[_.-]{2}).*[^_.-]$"
        if changedString.range(of: sequentialRegEx, options: .regularExpression) != nil{
            usernameRequirement_3.tintColor = .green
        }
        else{
            usernameRequirement_3.tintColor = .red
        }
        
        /** Make sure the username only contains alphanumerical characters (numbers and letters)*/
        let alphaNumericalRegEx = "^(?=[a-zA-Z0-9._-]{1,}$)"
        if changedString.range(of: alphaNumericalRegEx, options: .regularExpression) != nil{
            usernameRequirement_4.tintColor = .green
        }
        else{
            usernameRequirement_4.tintColor = .red
        }
    }
    
    /** Detect when the password textfield has been edited*/
    @objc func passwordTextfieldChanged(sender: UITextField){
        /** Look at the text field's current content after being cleared*/
        let changedString = sender.text ?? ""
        
        /** if the changed string is empty then there's nothing to verify so mark all requirements as unsatisfied*/
        if changedString == ""{
            passwordRequirement_1.tintColor = .red
            passwordRequirement_2.tintColor = .red
            passwordRequirement_3.tintColor = .red
            passwordRequirement_4.tintColor = .red
            passwordRequirement_5.tintColor = .red
            
            return
        }
        
        /** Make sure the password has at least 8 characters and 30 maximum*/
        let eightCharactersRegEx = "^(.{8,30}$)"
        if changedString.range(of: eightCharactersRegEx, options: .regularExpression) != nil{
            /** If the password satisfies this regular expression parameter then mark its matching password requirement button as satisfied by changing the tintcolor to green*/
            passwordRequirement_1.tintColor = .green
        }
        else{
            passwordRequirement_1.tintColor = .red
        }
        
        /** Make sure the password has at least one uppercase letter*/
        let uppercaseRegEx = "(.*?[A-Z])"
        if changedString.range(of: uppercaseRegEx, options: .regularExpression) != nil{
            passwordRequirement_2.tintColor = .green
        }
        else{
            passwordRequirement_2.tintColor = .red
        }
        
        /** Make sure the password has at least one lowercase letter*/
        let lowercaseRegEx = "(.*?[a-z])"
        if changedString.range(of: lowercaseRegEx, options: .regularExpression) != nil{
            passwordRequirement_3.tintColor = .green
        }
        else{
            passwordRequirement_3.tintColor = .red
        }
        
        /** Make sure the password has at least one number*/
        let numberRegEx = "(.*?[0-9])"
        if changedString.range(of: numberRegEx, options: .regularExpression) != nil{
            passwordRequirement_4.tintColor = .green
        }
        else{
            passwordRequirement_4.tintColor = .red
        }
        
        /** Make sure the password has at least one special character*/
        let specialCharacterRegEx = "(.*?[#?!@$%^&*-])"
        if changedString.range(of: specialCharacterRegEx, options: .regularExpression) != nil{
            passwordRequirement_5.tintColor = .green
        }
        else{
            passwordRequirement_5.tintColor = .red
        }
    }
    /** Username and password textfield editing listeners*/
    
    /** Hide and show methods for the username and password textfield requirements*/
    /** Hides the requirements description for the password field*/
    func hidePasswordRequirementsUI(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            passwordRequirementsContainer.alpha = 0
        }
    }
    
    /** Reveals the requirements description for the password field*/
    func showPasswordRequirementsUI(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            passwordRequirementsContainer.alpha = 1
        }
    }
    
    /** Hides the requirements description for the username field*/
    func hideUsernameRequirementsUI(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            usernameRequirementsContainer.alpha = 0
        }
        
        UIView.animate(withDuration: 1, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            passwordTextfield.transform = CGAffineTransform(translationX: 0, y: 0)
            
            passwordRequirementsContainer.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    /** Reveals the requirements description for the username field*/
    func showUsernameRequirementsUI(){
        /** Translate these views to make room for the other views*/
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            passwordTextfield.transform = CGAffineTransform(translationX: 0, y: usernameRequirementsContainer.frame.height + 10)
            
            passwordRequirementsContainer.transform = CGAffineTransform(translationX: 0, y: usernameRequirementsContainer.frame.height + 10)
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.25){[self] in
            usernameRequirementsContainer.alpha = 1
        }
    }
    /** Hides the requirements description for the username field*/
    
    /** Locks the password textfield*/
    func lockPasswordTextfield(){
        usePasswordSecurity = true
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {[self] in
            passwordTextfield.isSecureTextEntry = true
        }
        
        UIView.transition(with: passwordTextfieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{ [self] in
            passwordTextfieldLeftButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        })
    }
    
    /** Unlocks the password textfield*/
    func unlockPasswordTextfield(){
        usePasswordSecurity = false
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {[self] in
            passwordTextfield.isSecureTextEntry = false
        }
        
        UIView.transition(with: passwordTextfieldLeftButton, duration: 0.5, options: .transitionFlipFromLeft, animations:{ [self] in
            passwordTextfieldLeftButton.setImage(UIImage(systemName: "lock.open.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        })
    }
    
    func getNameAddressScreen()->UIView{
        let view = UIView(frame: view.frame)
        
        let labelSize = CGSize(width: view.frame.width * 0.75, height: 40)
        let instructionLabel = UILabel(frame: CGRect(x: 10, y: backButton.frame.minY + 10, width: labelSize.width, height: labelSize.height))
        instructionLabel.font = getCustomFont(name: .Ubuntu_bold, size: 20, dynamicSize: true)
        instructionLabel.adjustsFontForContentSizeCategory = true
        instructionLabel.adjustsFontSizeToFitWidth = true
        instructionLabel.numberOfLines = 2
        instructionLabel.lineBreakMode = .byClipping
        instructionLabel.textColor = appThemeColor
        instructionLabel.text = "Enter your name and current address"
        instructionLabel.textAlignment = .left
        instructionLabel.sizeToFit()
        
        /** Specify a first name*/
        firstNameTextfield.frame.size.height = 50
        firstNameTextfield.frame.size.width = view.frame.width * 0.45
        firstNameTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            firstNameTextfield.backgroundColor = bgColor.lighter
            firstNameTextfield.textColor = fontColor
        case false:
            firstNameTextfield.backgroundColor = bgColor
            firstNameTextfield.textColor = fontColor
        }
        firstNameTextfield.layer.cornerRadius = firstNameTextfield.frame.height/2
        firstNameTextfield.adjustsFontForContentSizeCategory = true
        firstNameTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        firstNameTextfield.attributedPlaceholder = NSAttributedString(string:"First name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        firstNameTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        var clearButton = firstNameTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        firstNameTextfield.textContentType = .givenName
        firstNameTextfield.keyboardType = .alphabet
        firstNameTextfield.returnKeyType = .done
        firstNameTextfield.textAlignment = .left
        firstNameTextfield.delegate = self
        firstNameTextfield.autocorrectionType = .yes
        firstNameTextfield.autocapitalizationType = .words
        firstNameTextfield.toolbarPlaceholder = "First name"
        firstNameTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        firstNameTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        firstNameTextfield.layer.shadowOpacity = 0.25
        firstNameTextfield.layer.shadowRadius = 8
        firstNameTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        firstNameTextfield.layer.shadowPath = UIBezierPath(roundedRect: firstNameTextfield.bounds, cornerRadius: firstNameTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        firstNameTextfield.clipsToBounds = true
        firstNameTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        firstNameTextfield.borderStyle = .none
        firstNameTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        firstNameTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: firstNameTextfield.frame.height/(1.5), height: firstNameTextfield.frame.height/(1.5)))
        
        let leftButton = UIButton()
        leftButton.setImage(UIImage(systemName: "1.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton.frame.size = CGSize(width: firstNameTextfield.frame.height/(1.5), height: firstNameTextfield.frame.height/(1.5))
        leftButton.frame.origin = CGPoint(x: paddingView.frame.width/2 - leftButton.frame.width/2, y: paddingView.frame.height/2 - leftButton.frame.height/2)
        leftButton.backgroundColor = .clear
        leftButton.tintColor = appThemeColor
        leftButton.layer.cornerRadius = leftButton.frame.height/2
        leftButton.contentMode = .scaleAspectFit
        leftButton.isUserInteractionEnabled = false
        leftButton.clipsToBounds = true
        
        paddingView.addSubview(leftButton)
        firstNameTextfield.leftView = paddingView
        firstNameTextfield.leftViewMode = .always
        
        /** Specify a last name*/
        lastNameTextfield.frame.size.height = 50
        lastNameTextfield.frame.size.width = view.frame.width * 0.45
        lastNameTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            lastNameTextfield.backgroundColor = bgColor.lighter
            lastNameTextfield.textColor = fontColor
        case false:
            lastNameTextfield.backgroundColor = bgColor
            lastNameTextfield.textColor = fontColor
        }
        lastNameTextfield.layer.cornerRadius = lastNameTextfield.frame.height/2
        lastNameTextfield.adjustsFontForContentSizeCategory = true
        lastNameTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        lastNameTextfield.attributedPlaceholder = NSAttributedString(string:"Last name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        lastNameTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = lastNameTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        lastNameTextfield.textContentType = .familyName
        lastNameTextfield.keyboardType = .alphabet
        lastNameTextfield.returnKeyType = .done
        lastNameTextfield.textAlignment = .left
        lastNameTextfield.delegate = self
        lastNameTextfield.autocorrectionType = .yes
        lastNameTextfield.autocapitalizationType = .words
        lastNameTextfield.toolbarPlaceholder = "Last name"
        lastNameTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        lastNameTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        lastNameTextfield.layer.shadowOpacity = 0.25
        lastNameTextfield.layer.shadowRadius = 8
        lastNameTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        lastNameTextfield.layer.shadowPath = UIBezierPath(roundedRect: lastNameTextfield.bounds, cornerRadius: lastNameTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        lastNameTextfield.clipsToBounds = true
        lastNameTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        lastNameTextfield.borderStyle = .none
        lastNameTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        lastNameTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView_2 = UIView(frame: CGRect(x: 0, y: 0, width: lastNameTextfield.frame.height/(1.5), height: lastNameTextfield.frame.height/(1.5)))
        
        let leftButton_2 = UIButton()
        leftButton_2.setImage(UIImage(systemName: "2.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton_2.frame.size = CGSize(width: lastNameTextfield.frame.height/(1.5), height: lastNameTextfield.frame.height/(1.5))
        leftButton_2.frame.origin = CGPoint(x: paddingView_2.frame.width/2 - leftButton_2.frame.width/2, y: paddingView_2.frame.height/2 - leftButton_2.frame.height/2)
        leftButton_2.backgroundColor = .clear
        leftButton_2.tintColor = appThemeColor
        leftButton_2.layer.cornerRadius = leftButton_2.frame.height/2
        leftButton_2.contentMode = .scaleAspectFit
        leftButton_2.isUserInteractionEnabled = false
        leftButton_2.clipsToBounds = true
        
        paddingView_2.addSubview(leftButton_2)
        lastNameTextfield.leftView = paddingView_2
        lastNameTextfield.leftViewMode = .always
        
        /** Specify the user's physical address*/
        address1Textfield.frame.size.height = 50
        address1Textfield.frame.size.width = view.frame.width * 0.9
        address1Textfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            address1Textfield.backgroundColor = bgColor.lighter
            address1Textfield.textColor = fontColor
        case false:
            address1Textfield.backgroundColor = bgColor
            address1Textfield.textColor = fontColor
        }
        address1Textfield.layer.cornerRadius = address1Textfield.frame.height/2
        address1Textfield.adjustsFontForContentSizeCategory = true
        address1Textfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        address1Textfield.attributedPlaceholder = NSAttributedString(string:"Address (123 Main Street)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        address1Textfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = address1Textfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        address1Textfield.textContentType = .streetAddressLine1
        address1Textfield.keyboardType = .asciiCapable
        address1Textfield.returnKeyType = .done
        address1Textfield.textAlignment = .left
        address1Textfield.delegate = self
        address1Textfield.autocorrectionType = .no
        address1Textfield.toolbarPlaceholder = "Address 1"
        address1Textfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        address1Textfield.layer.shadowColor = UIColor.darkGray.cgColor
        address1Textfield.layer.shadowOpacity = 0.25
        address1Textfield.layer.shadowRadius = 8
        address1Textfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        address1Textfield.layer.shadowPath = UIBezierPath(roundedRect: address1Textfield.bounds, cornerRadius: address1Textfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        address1Textfield.clipsToBounds = true
        address1Textfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        address1Textfield.borderStyle = .none
        address1Textfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        address1Textfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView_3 = UIView(frame: CGRect(x: 0, y: 0, width: address1Textfield.frame.height/(1.5), height: address1Textfield.frame.height/(1.5)))
        
        let leftButton_3 = UIButton()
        leftButton_3.setImage(UIImage(systemName: "building.2.crop.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton_3.frame.size = CGSize(width: address1Textfield.frame.height/(1.5), height: address1Textfield.frame.height/(1.5))
        leftButton_3.frame.origin = CGPoint(x: paddingView_3.frame.width/2 - leftButton_3.frame.width/2, y: paddingView_3.frame.height/2 - leftButton_3.frame.height/2)
        leftButton_3.backgroundColor = .clear
        leftButton_3.tintColor = appThemeColor
        leftButton_3.layer.cornerRadius = leftButton_3.frame.height/2
        leftButton_3.contentMode = .scaleAspectFit
        leftButton_3.isUserInteractionEnabled = false
        leftButton_3.clipsToBounds = true
        
        paddingView_3.addSubview(leftButton_3)
        address1Textfield.leftView = paddingView_3
        address1Textfield.leftViewMode = .always
        
        /** Specify the finer details of the user's physical address (apt number etc)*/
        address2Textfield.frame.size.height = 50
        address2Textfield.frame.size.width = view.frame.width * 0.9
        address2Textfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            address2Textfield.backgroundColor = bgColor.lighter
            address2Textfield.textColor = fontColor
        case false:
            address2Textfield.backgroundColor = bgColor
            address2Textfield.textColor = fontColor
        }
        address2Textfield.layer.cornerRadius = address2Textfield.frame.height/2
        address2Textfield.adjustsFontForContentSizeCategory = true
        address2Textfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        address2Textfield.attributedPlaceholder = NSAttributedString(string:"Apartment, suite, etc. (Apt 1A)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        address2Textfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = address2Textfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        address2Textfield.textContentType = .streetAddressLine2
        address2Textfield.keyboardType = .asciiCapable
        address2Textfield.returnKeyType = .done
        address2Textfield.textAlignment = .left
        address2Textfield.delegate = self
        address2Textfield.autocorrectionType = .no
        address2Textfield.toolbarPlaceholder = "Address 2"
        address2Textfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        address2Textfield.layer.shadowColor = UIColor.darkGray.cgColor
        address2Textfield.layer.shadowOpacity = 0.25
        address2Textfield.layer.shadowRadius = 8
        address2Textfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        address2Textfield.layer.shadowPath = UIBezierPath(roundedRect: address2Textfield.bounds, cornerRadius: address2Textfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        address2Textfield.clipsToBounds = true
        address2Textfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        address2Textfield.borderStyle = .none
        address2Textfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        address2Textfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView_4 = UIView(frame: CGRect(x: 0, y: 0, width: address2Textfield.frame.height/(1.5), height: address2Textfield.frame.height/(1.5)))
        
        let leftButton_4 = UIButton()
        leftButton_4.setImage(UIImage(systemName: "123.rectangle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton_4.frame.size = CGSize(width: address2Textfield.frame.height/(1.5), height: address2Textfield.frame.height/(1.5))
        leftButton_4.frame.origin = CGPoint(x: paddingView_4.frame.width/2 - leftButton_4.frame.width/2, y: paddingView_4.frame.height/2 - leftButton_4.frame.height/2)
        leftButton_4.backgroundColor = .clear
        leftButton_4.tintColor = appThemeColor
        leftButton_4.layer.cornerRadius = leftButton_4.frame.height/2
        leftButton_4.contentMode = .scaleAspectFit
        leftButton_4.isUserInteractionEnabled = false
        leftButton_4.clipsToBounds = true
        
        paddingView_4.addSubview(leftButton_4)
        address2Textfield.leftView = paddingView_4
        address2Textfield.leftViewMode = .always
        
        /** Specify the city of the address*/
        cityTextfield.frame.size.height = 50
        cityTextfield.frame.size.width = view.frame.width * 0.45
        cityTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            cityTextfield.backgroundColor = bgColor.lighter
            cityTextfield.textColor = fontColor
        case false:
            cityTextfield.backgroundColor = bgColor
            cityTextfield.textColor = fontColor
        }
        cityTextfield.textColor = .black
        cityTextfield.layer.cornerRadius = cityTextfield.frame.height/2
        cityTextfield.adjustsFontForContentSizeCategory = true
        cityTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        cityTextfield.attributedPlaceholder = NSAttributedString(string:"City", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        cityTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = cityTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        cityTextfield.textContentType = .addressCity
        cityTextfield.keyboardType = .alphabet
        cityTextfield.returnKeyType = .done
        cityTextfield.textAlignment = .left
        cityTextfield.delegate = self
        cityTextfield.autocorrectionType = .no
        cityTextfield.toolbarPlaceholder = "City"
        cityTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        cityTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        cityTextfield.layer.shadowOpacity = 0.25
        cityTextfield.layer.shadowRadius = 8
        cityTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        cityTextfield.layer.shadowPath = UIBezierPath(roundedRect: cityTextfield.bounds, cornerRadius: cityTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        cityTextfield.clipsToBounds = true
        cityTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        cityTextfield.borderStyle = .none
        cityTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        cityTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView_5 = UIView(frame: CGRect(x: 0, y: 0, width: cityTextfield.frame.height/(1.5), height: cityTextfield.frame.height/(1.5)))
        
        /** Leave some white space on the left of the textfield so nothing spills out*/
        let spacer_1 = UIView(frame: CGRect(x: 0, y: 0, width: cityTextfield.frame.height/(3), height: cityTextfield.frame.height/(3)))
        cityTextfield.leftView = spacer_1
        cityTextfield.leftViewMode = .always
        
        let leftButton_5 = UIButton()
        leftButton_5.setImage(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton_5.frame.size = CGSize(width: cityTextfield.frame.height/(1.5), height: cityTextfield.frame.height/(1.5))
        leftButton_5.frame.origin = CGPoint(x: paddingView_5.frame.width/2 - leftButton_5.frame.width/2, y: paddingView_5.frame.height/2 - leftButton_5.frame.height/2)
        leftButton_5.backgroundColor = .clear
        leftButton_5.tintColor = appThemeColor
        leftButton_5.layer.cornerRadius = leftButton_5.frame.height/2
        leftButton_5.contentMode = .scaleAspectFit
        leftButton_5.isUserInteractionEnabled = false
        leftButton_5.clipsToBounds = true
        
        paddingView_5.addSubview(leftButton_5)
        cityTextfield.rightView = paddingView_5
        cityTextfield.rightViewMode = .always
        cityTextfield.inputView = cityPickerView
        
        /** Picker view for selecting the borough the user is currently in*/
        cityPickerView.frame = CGRect(x: 0, y: view.frame.height - (view.frame.height * 0.4), width: view.frame.width, height: view.frame.height * 0.4)
        cityTextfield.text = NYCities[0]
        markTextFieldEntryAsCorrect(textField: cityTextfield)
        cityPickerView.delegate = self
        cityPickerView.dataSource = self
        switch darkMode{
        case true:
            cityPickerView.backgroundColor = bgColor.darker
        case false:
            cityPickerView.backgroundColor = bgColor
        }
        cityPickerView.contentMode = .center
        cityPickerView.autoresizingMask = .flexibleWidth
        
        /** Specify the borough of the address*/
        boroughTextfield.frame.size.height = 50
        boroughTextfield.frame.size.width = view.frame.width * 0.45
        boroughTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            boroughTextfield.backgroundColor = bgColor.lighter
            boroughTextfield.textColor = fontColor
        case false:
            boroughTextfield.backgroundColor = bgColor
            boroughTextfield.textColor = fontColor
        }
        boroughTextfield.layer.cornerRadius = boroughTextfield.frame.height/2
        boroughTextfield.adjustsFontForContentSizeCategory = true
        boroughTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        boroughTextfield.attributedPlaceholder = NSAttributedString(string:"Borough", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        boroughTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = boroughTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        boroughTextfield.textContentType = .sublocality
        boroughTextfield.keyboardType = .alphabet
        boroughTextfield.returnKeyType = .done
        boroughTextfield.textAlignment = .left
        boroughTextfield.delegate = self
        boroughTextfield.autocorrectionType = .no
        boroughTextfield.toolbarPlaceholder = "Borough"
        boroughTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        boroughTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        boroughTextfield.layer.shadowOpacity = 0.25
        boroughTextfield.layer.shadowRadius = 8
        boroughTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        boroughTextfield.layer.shadowPath = UIBezierPath(roundedRect: boroughTextfield.bounds, cornerRadius: boroughTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        boroughTextfield.clipsToBounds = true
        boroughTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        boroughTextfield.borderStyle = .none
        boroughTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        boroughTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView_6 = UIView(frame: CGRect(x: 0, y: 0, width: boroughTextfield.frame.height/(1.5), height: boroughTextfield.frame.height/(1.5)))
        
        /** Leave some white space on the left of the textfield so nothing spills out*/
        let spacer_2 = UIView(frame: CGRect(x: 0, y: 0, width: boroughTextfield.frame.height/(3), height: boroughTextfield.frame.height/(3)))
        boroughTextfield.leftView = spacer_2
        boroughTextfield.leftViewMode = .always
        
        let leftButton_6 = UIButton()
        leftButton_6.setImage(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton_6.frame.size = CGSize(width: boroughTextfield.frame.height/(1.5), height: boroughTextfield.frame.height/(1.5))
        leftButton_6.frame.origin = CGPoint(x: paddingView_6.frame.width/2 - leftButton_6.frame.width/2, y: paddingView_6.frame.height/2 - leftButton_6.frame.height/2)
        leftButton_6.backgroundColor = .clear
        leftButton_6.tintColor = appThemeColor
        leftButton_6.layer.cornerRadius = leftButton_6.frame.height/2
        leftButton_6.contentMode = .scaleAspectFit
        leftButton_6.isUserInteractionEnabled = false
        leftButton_6.clipsToBounds = true
        
        paddingView_6.addSubview(leftButton_6)
        boroughTextfield.rightView = paddingView_6
        boroughTextfield.rightViewMode = .always
        boroughTextfield.inputView = boroughPickerView
        
        /** Picker view for selecting the borough the user is currently in*/
        boroughPickerView.frame = CGRect(x: 0, y: view.frame.height - (view.frame.height * 0.4), width: view.frame.width, height: view.frame.height * 0.4)
        boroughTextfield.text = boroughs[0]
        markTextFieldEntryAsCorrect(textField: boroughTextfield)
        boroughPickerView.delegate = self
        boroughPickerView.dataSource = self
        switch darkMode{
        case true:
            boroughPickerView.backgroundColor = bgColor.darker
        case false:
            boroughPickerView.backgroundColor = bgColor
        }
        boroughPickerView.contentMode = .center
        boroughPickerView.autoresizingMask = .flexibleWidth
        
        /** Specify the state of the address*/
        stateTextfield.frame.size.height = 50
        stateTextfield.frame.size.width = view.frame.width * 0.45
        stateTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            stateTextfield.backgroundColor = bgColor.lighter
            stateTextfield.textColor = fontColor
        case false:
            stateTextfield.backgroundColor = bgColor
            stateTextfield.textColor = fontColor
        }
        stateTextfield.layer.cornerRadius = stateTextfield.frame.height/2
        stateTextfield.adjustsFontForContentSizeCategory = true
        stateTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        stateTextfield.attributedPlaceholder = NSAttributedString(string:"State", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        stateTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = stateTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        stateTextfield.textContentType = .addressState
        stateTextfield.keyboardType = .alphabet
        stateTextfield.returnKeyType = .done
        stateTextfield.textAlignment = .left
        stateTextfield.delegate = self
        stateTextfield.autocorrectionType = .no
        stateTextfield.toolbarPlaceholder = "State"
        stateTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        stateTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        stateTextfield.layer.shadowOpacity = 0.25
        stateTextfield.layer.shadowRadius = 8
        stateTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        stateTextfield.layer.shadowPath = UIBezierPath(roundedRect: stateTextfield.bounds, cornerRadius: stateTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        stateTextfield.clipsToBounds = true
        stateTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        stateTextfield.borderStyle = .none
        stateTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        stateTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView_7 = UIView(frame: CGRect(x: 0, y: 0, width: stateTextfield.frame.height/(1.5), height: stateTextfield.frame.height/(1.5)))
        
        /** Leave some white space on the left of the textfield so nothing spills out*/
        let spacer_3 = UIView(frame: CGRect(x: 0, y: 0, width: stateTextfield.frame.height/(3), height: stateTextfield.frame.height/(3)))
        stateTextfield.leftView = spacer_3
        stateTextfield.leftViewMode = .always
        
        let leftButton_7 = UIButton()
        leftButton_7.setImage(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton_7.frame.size = CGSize(width: stateTextfield.frame.height/(1.5), height: stateTextfield.frame.height/(1.5))
        leftButton_7.frame.origin = CGPoint(x: paddingView_7.frame.width/2 - leftButton_7.frame.width/2, y: paddingView_7.frame.height/2 - leftButton_7.frame.height/2)
        leftButton_7.backgroundColor = .clear
        leftButton_7.tintColor = appThemeColor
        leftButton_7.layer.cornerRadius = leftButton_7.frame.height/2
        leftButton_7.contentMode = .scaleAspectFit
        leftButton_7.isUserInteractionEnabled = false
        leftButton_7.clipsToBounds = true
        
        paddingView_7.addSubview(leftButton_7)
        stateTextfield.rightView = paddingView_7
        stateTextfield.rightViewMode = .always
        stateTextfield.inputView = statePickerView
        
        /** Picker view for selecting the state the user is currently in*/
        statePickerView.frame = CGRect(x: 0, y: view.frame.height - (view.frame.height * 0.4), width: view.frame.width, height: view.frame.height * 0.4)
        stateTextfield.text = states[0]
        markTextFieldEntryAsCorrect(textField: stateTextfield)
        statePickerView.delegate = self
        statePickerView.dataSource = self
        switch darkMode{
        case true:
            statePickerView.backgroundColor = bgColor.darker
        case false:
            statePickerView.backgroundColor = bgColor
        }
        statePickerView.contentMode = .center
        statePickerView.autoresizingMask = .flexibleWidth
        
        /** Specify the zipcode of the address*/
        zipCodeTextfield.frame.size.height = 50
        zipCodeTextfield.frame.size.width = view.frame.width * 0.45
        zipCodeTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            zipCodeTextfield.backgroundColor = bgColor.lighter
            zipCodeTextfield.textColor = fontColor
        case false:
            zipCodeTextfield.backgroundColor = bgColor
            zipCodeTextfield.textColor = fontColor
        }
        zipCodeTextfield.layer.cornerRadius = zipCodeTextfield.frame.height/2
        zipCodeTextfield.adjustsFontForContentSizeCategory = true
        zipCodeTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        zipCodeTextfield.attributedPlaceholder = NSAttributedString(string:"Zip code (11233)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        zipCodeTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = zipCodeTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        zipCodeTextfield.textContentType = .postalCode
        zipCodeTextfield.keyboardType = .asciiCapableNumberPad
        zipCodeTextfield.returnKeyType = .done
        zipCodeTextfield.textAlignment = .left
        zipCodeTextfield.delegate = self
        zipCodeTextfield.autocorrectionType = .no
        zipCodeTextfield.toolbarPlaceholder = "Zip code"
        zipCodeTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        zipCodeTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        zipCodeTextfield.layer.shadowOpacity = 0.25
        zipCodeTextfield.layer.shadowRadius = 8
        zipCodeTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        zipCodeTextfield.layer.shadowPath = UIBezierPath(roundedRect: zipCodeTextfield.bounds, cornerRadius: zipCodeTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        zipCodeTextfield.clipsToBounds = true
        zipCodeTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        zipCodeTextfield.borderStyle = .none
        zipCodeTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        zipCodeTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView_8 = UIView(frame: CGRect(x: 0, y: 0, width: zipCodeTextfield.frame.height/(1.5), height: zipCodeTextfield.frame.height/(1.5)))
        
        /** Leave some white space on the left of the textfield so nothing spills out*/
        let spacer_4 = UIView(frame: CGRect(x: 0, y: 0, width: zipCodeTextfield.frame.height/(3), height: zipCodeTextfield.frame.height/(3)))
        zipCodeTextfield.leftView = spacer_4
        zipCodeTextfield.leftViewMode = .always
        
        let leftButton_8 = UIButton()
        leftButton_8.setImage(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton_8.frame.size = CGSize(width: zipCodeTextfield.frame.height/(1.5), height: zipCodeTextfield.frame.height/(1.5))
        leftButton_8.frame.origin = CGPoint(x: paddingView_8.frame.width/2 - leftButton_8.frame.width/2, y: paddingView_8.frame.height/2 - leftButton_8.frame.height/2)
        leftButton_8.backgroundColor = .clear
        leftButton_8.tintColor = appThemeColor
        leftButton_8.layer.cornerRadius = leftButton_8.frame.height/2
        leftButton_8.contentMode = .scaleAspectFit
        leftButton_8.isUserInteractionEnabled = false
        leftButton_8.clipsToBounds = true
        
        paddingView_8.addSubview(leftButton_8)
        zipCodeTextfield.rightView = paddingView_8
        zipCodeTextfield.rightViewMode = .always
        zipCodeTextfield.inputView = zipCodePickerView
        
        /** Picker view for selecting the state the user is currently in*/
        zipCodePickerView.frame = CGRect(x: 0, y: view.frame.height - (view.frame.height * 0.4), width: view.frame.width, height: view.frame.height * 0.4)
        zipCodeTextfield.text = nycZipCodes[0].key.description
        zipCodePickerView.delegate = self
        zipCodePickerView.dataSource = self
        switch darkMode{
        case true:
            zipCodePickerView.backgroundColor = bgColor.darker
        case false:
            zipCodePickerView.backgroundColor = bgColor
        }
        zipCodePickerView.contentMode = .center
        zipCodePickerView.autoresizingMask = .flexibleWidth
        
        /** Layout these subviews*/
        instructionLabel.frame = CGRect(x: 10, y: backButton.frame.maxY + 10, width: labelSize.width, height: labelSize.height)
        
        /** Entry textfields*/
        firstNameTextfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: instructionLabel.frame.maxY + 20)
        lastNameTextfield.frame.origin = CGPoint(x: firstNameTextfield.frame.maxX + 10, y: firstNameTextfield.frame.origin.y)
        
        address1Textfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: firstNameTextfield.frame.maxY + 10)
        address2Textfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: address1Textfield.frame.maxY + 10)
        
        cityTextfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: address2Textfield.frame.maxY + 10)
        boroughTextfield.frame.origin = CGPoint(x: cityTextfield.frame.maxX + 10, y: cityTextfield.frame.origin.y)
        
        stateTextfield.frame.origin = CGPoint(x: instructionLabel.frame.origin.x, y: cityTextfield.frame.maxY + 10)
        zipCodeTextfield.frame.origin = CGPoint(x: stateTextfield.frame.maxX + 10, y: stateTextfield.frame.origin.y)
        
        view.addSubview(instructionLabel)
        view.addSubview(firstNameTextfield)
        view.addSubview(lastNameTextfield)
        view.addSubview(address1Textfield)
        view.addSubview(address2Textfield)
        view.addSubview(cityTextfield)
        view.addSubview(boroughTextfield)
        view.addSubview(stateTextfield)
        view.addSubview(zipCodeTextfield)
        
        return view
    }
    
    func getGenderDOBScreen()->UIView{
        let view = UIView(frame: view.frame)
        
        let labelSize = CGSize(width: view.frame.width * 0.75, height: 40)
        genderDOBScreenInstructionLabel = UILabel(frame: CGRect(x: 10, y: backButton.frame.minY + 10, width: labelSize.width, height: labelSize.height))
        genderDOBScreenInstructionLabel.adjustsFontForContentSizeCategory = true
        genderDOBScreenInstructionLabel.adjustsFontSizeToFitWidth = true
        genderDOBScreenInstructionLabel.numberOfLines = 2
        genderDOBScreenInstructionLabel.lineBreakMode = .byClipping
        genderDOBScreenInstructionLabel.textColor = appThemeColor
        genderDOBScreenInstructionLabel.attributedText = attribute(this: "Enter your birth date, gender, and a profile picture (Optional)", font: getCustomFont(name: .Ubuntu_bold, size: 20, dynamicSize: true), subFont: getCustomFont(name: .Ubuntu_Regular, size: 20, dynamicSize: true), mainColor: appThemeColor, subColor: .lightGray, subString: "(Optional)")
        genderDOBScreenInstructionLabel.textAlignment = .left
        genderDOBScreenInstructionLabel.sizeToFit()
        
        /** Specify the user's DOB*/
        DOBTextfield.frame.size.height = 50
        DOBTextfield.frame.size.width = view.frame.width * 0.9
        DOBTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            DOBTextfield.backgroundColor = bgColor.lighter
            DOBTextfield.textColor = fontColor
        case false:
            DOBTextfield.backgroundColor = bgColor
            DOBTextfield.textColor = fontColor
        }
        DOBTextfield.layer.cornerRadius = DOBTextfield.frame.height/2
        DOBTextfield.adjustsFontForContentSizeCategory = true
        DOBTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        DOBTextfield.attributedPlaceholder = NSAttributedString(string:"Date of birth (01/01/1991)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        DOBTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        var clearButton = DOBTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        DOBTextfield.textContentType = .postalCode
        DOBTextfield.keyboardType = .asciiCapableNumberPad
        DOBTextfield.returnKeyType = .done
        DOBTextfield.textAlignment = .left
        DOBTextfield.delegate = self
        DOBTextfield.autocorrectionType = .no
        DOBTextfield.toolbarPlaceholder = "Date of birth"
        DOBTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        DOBTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        DOBTextfield.layer.shadowOpacity = 0.25
        DOBTextfield.layer.shadowRadius = 8
        DOBTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        DOBTextfield.layer.shadowPath = UIBezierPath(roundedRect: DOBTextfield.bounds, cornerRadius: DOBTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        DOBTextfield.clipsToBounds = true
        DOBTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        DOBTextfield.borderStyle = .none
        DOBTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        DOBTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: DOBTextfield.frame.height/(1.5), height: DOBTextfield.frame.height/(1.5)))
        
        /** Leave some white space on the left of the textfield so nothing spills out*/
        let spacer = UIView(frame: CGRect(x: 0, y: 0, width: DOBTextfield.frame.height/(1.5), height: DOBTextfield.frame.height/(1.5)))
        
        let spacerButton = UIButton()
        spacerButton.setImage(UIImage(systemName: "calendar.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        spacerButton.frame.size = CGSize(width: DOBTextfield.frame.height/(1.5), height: DOBTextfield.frame.height/(1.5))
        spacerButton.frame.origin = CGPoint(x: spacer.frame.width/2 - spacerButton.frame.width/2, y: spacer.frame.height/2 - spacerButton.frame.height/2)
        spacerButton.backgroundColor = .clear
        spacerButton.tintColor = appThemeColor
        spacerButton.layer.cornerRadius = spacerButton.frame.height/2
        spacerButton.contentMode = .scaleAspectFit
        spacerButton.isUserInteractionEnabled = false
        spacerButton.clipsToBounds = true
        
        spacer.addSubview(spacerButton)
        DOBTextfield.leftView = spacer
        DOBTextfield.leftViewMode = .always
        
        let leftButton = UIButton()
        leftButton.setImage(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton.frame.size = CGSize(width: DOBTextfield.frame.height/(1.5), height: DOBTextfield.frame.height/(1.5))
        leftButton.frame.origin = CGPoint(x: paddingView.frame.width/2 - leftButton.frame.width/2, y: paddingView.frame.height/2 - leftButton.frame.height/2)
        leftButton.backgroundColor = .clear
        leftButton.tintColor = appThemeColor
        leftButton.layer.cornerRadius = leftButton.frame.height/2
        leftButton.contentMode = .scaleAspectFit
        leftButton.isUserInteractionEnabled = false
        leftButton.clipsToBounds = true
        
        paddingView.addSubview(leftButton)
        DOBTextfield.rightView = paddingView
        DOBTextfield.rightViewMode = .always
        DOBTextfield.inputView = DOBPickerView
        
        /** Picker view for selecting the state the user is currently in*/
        DOBPickerView.frame = CGRect(x: 0, y: view.frame.height - (view.frame.height * 0.4), width: view.frame.width, height: view.frame.height * 0.4)
        DOBPickerView.datePickerMode = .date
        DOBPickerView.preferredDatePickerStyle = .wheels
        DOBPickerView.maximumDate = .now
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        DOBPickerView.minimumDate = dateFormatter.date(from: "01/01/1920")
        switch darkMode{
        case true:
            DOBPickerView.backgroundColor = bgColor.darker
        case false:
            DOBPickerView.backgroundColor = bgColor
        }
        DOBPickerView.contentMode = .center
        DOBPickerView.autoresizingMask = .flexibleWidth
        DOBPickerView.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        
        /** Specify the user's gender*/
        genderTextfield.frame.size.height = 50
        genderTextfield.frame.size.width = view.frame.width * 0.45
        genderTextfield.tintColor = appThemeColor
        switch darkMode{
        case true:
            genderTextfield.backgroundColor = bgColor.lighter
            genderTextfield.textColor = fontColor
        case false:
            genderTextfield.backgroundColor = bgColor
            genderTextfield.textColor = fontColor
        }
        genderTextfield.layer.cornerRadius = genderTextfield.frame.height/2
        genderTextfield.adjustsFontForContentSizeCategory = true
        genderTextfield.font = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: true)
        genderTextfield.attributedPlaceholder = NSAttributedString(string:"Gender", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        /** Settings*/
        genderTextfield.clearButtonMode = .whileEditing
        /** Set the clear button's tint color to the app's theme color*/
        clearButton = genderTextfield.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = appThemeColor
        genderTextfield.textContentType = .postalCode
        genderTextfield.keyboardType = .asciiCapableNumberPad
        genderTextfield.returnKeyType = .done
        genderTextfield.textAlignment = .left
        genderTextfield.delegate = self
        genderTextfield.autocorrectionType = .no
        genderTextfield.toolbarPlaceholder = "Gender"
        genderTextfield.keyboardAppearance = .light
        
        /** Shadow properties*/
        genderTextfield.layer.shadowColor = UIColor.darkGray.cgColor
        genderTextfield.layer.shadowOpacity = 0.25
        genderTextfield.layer.shadowRadius = 8
        genderTextfield.layer.shadowOffset = CGSize(width: 0, height: 2)
        genderTextfield.layer.shadowPath = UIBezierPath(roundedRect: genderTextfield.bounds, cornerRadius: genderTextfield.layer.cornerRadius).cgPath
        
        /** Border properties*/
        genderTextfield.clipsToBounds = true
        genderTextfield.layer.masksToBounds = false
        /** Set to .none, else the shadow and the rect bounds aren't rendered properly*/
        genderTextfield.borderStyle = .none
        genderTextfield.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.25).cgColor
        genderTextfield.layer.borderWidth = 1
        
        /** Padding to prevent the text in the textfield from spilling outside of its borders*/
        let paddingView_2 = UIView(frame: CGRect(x: 0, y: 0, width: genderTextfield.frame.height/(1.5), height: genderTextfield.frame.height/(1.5)))
        
        /** Leave some white space on the left of the textfield so nothing spills out*/
        let spacer_2 = UIView(frame: CGRect(x: 0, y: 0, width: genderTextfield.frame.height/(1.5), height: genderTextfield.frame.height/(1.5)))
        
        let spacerButton_2 = UIButton()
        spacerButton_2.setImage(UIImage(systemName: "figure.wave.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        spacerButton_2.frame.size = CGSize(width: genderTextfield.frame.height/(1.5), height: genderTextfield.frame.height/(1.5))
        spacerButton_2.frame.origin = CGPoint(x: spacer_2.frame.width/2 - spacerButton_2.frame.width/2, y: spacer_2.frame.height/2 - spacerButton_2.frame.height/2)
        spacerButton_2.backgroundColor = .clear
        spacerButton_2.tintColor = appThemeColor
        spacerButton_2.layer.cornerRadius = spacerButton_2.frame.height/2
        spacerButton_2.contentMode = .scaleAspectFit
        spacerButton_2.isUserInteractionEnabled = false
        spacerButton_2.clipsToBounds = true
        
        spacer_2.addSubview(spacerButton_2)
        genderTextfield.leftView = spacer_2
        genderTextfield.leftViewMode = .always
        
        let leftButton_2 = UIButton()
        leftButton_2.setImage(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        leftButton_2.frame.size = CGSize(width: genderTextfield.frame.height/(1.5), height: genderTextfield.frame.height/(1.5))
        leftButton_2.frame.origin = CGPoint(x: paddingView_2.frame.width/2 - leftButton_2.frame.width/2, y: paddingView_2.frame.height/2 - leftButton_2.frame.height/2)
        leftButton_2.backgroundColor = .clear
        leftButton_2.tintColor = appThemeColor
        leftButton_2.layer.cornerRadius = leftButton_2.frame.height/2
        leftButton_2.contentMode = .scaleAspectFit
        leftButton_2.isUserInteractionEnabled = false
        leftButton_2.clipsToBounds = true
        
        paddingView_2.addSubview(leftButton_2)
        genderTextfield.rightView = paddingView_2
        genderTextfield.rightViewMode = .always
        genderTextfield.inputView = genderPickerView
        
        /** Picker view for selecting the state the user is currently in*/
        genderPickerView.frame = CGRect(x: 0, y: view.frame.height - (view.frame.height * 0.4), width: view.frame.width, height: view.frame.height * 0.4)
        genderTextfield.text = genders[2]
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        switch darkMode{
        case true:
            genderPickerView.backgroundColor = bgColor.darker
        case false:
            genderPickerView.backgroundColor = bgColor
        }
        genderPickerView.contentMode = .center
        genderPickerView.autoresizingMask = .flexibleWidth
        /** Default value is unspecified*/
        genderPickerView.selectRow(2, inComponent: 0, animated: false)
        markTextFieldEntryAsCorrect(textField: genderTextfield)
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.sourceType = .photoLibrary
        
        profilePictureImageView.frame.size = CGSize(width: view.frame.width * 0.5, height: view.frame.width * 0.5)
        profilePictureImageView.contentMode = .scaleAspectFill
        profilePictureImageView.backgroundColor = bgColor
        profilePictureImageView.image = UIImage(named: "user")
        profilePictureImageView.tintColor = appThemeColor
        profilePictureImageView.layer.borderColor = appThemeColor.cgColor
        profilePictureImageView.layer.borderWidth = 1
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height/2
        profilePictureImageView.clipsToBounds = true
        
        profilePictureImageViewAnimatedBorder.frame.size = CGSize(width: profilePictureImageView.frame.width * 1.25, height: profilePictureImageView.frame.height * 1.25)
        profilePictureImageViewAnimatedBorder.backgroundColor = .clear
        profilePictureImageViewAnimatedBorder.clipsToBounds = true
        profilePictureImageViewAnimatedBorder.layer.cornerRadius = profilePictureImageViewAnimatedBorder.frame.height/2
        profilePictureImageViewAnimatedBorder.addDashedBorder(strokeColor: appThemeColor, fillColor: UIColor.clear, lineWidth: 5, lineDashPattern: [30,10], cornerRadius: profilePictureImageView.frame.height/2)
        profilePictureImageViewAnimatedBorder.animateDashedBorder()
        
        profilePictureSelectionButton.frame.size = CGSize(width: 50, height: 50)
        profilePictureSelectionButton.backgroundColor = bgColor
        profilePictureSelectionButton.contentHorizontalAlignment = .center
        profilePictureSelectionButton.layer.cornerRadius = profilePictureSelectionButton.frame.height/2
        profilePictureSelectionButton.isExclusiveTouch = true
        profilePictureSelectionButton.isEnabled = true
        profilePictureSelectionButton.castDefaultShadow()
        profilePictureSelectionButton.tintColor = appThemeColor
        profilePictureSelectionButton.layer.shadowColor = appThemeColor.cgColor
        profilePictureSelectionButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        profilePictureSelectionButton.imageView?.contentMode = .scaleAspectFit
        profilePictureSelectionButton.imageEdgeInsets = UIEdgeInsets(top: profilePictureSelectionButton.frame.height * 0.2, left: profilePictureSelectionButton.frame.height * 0.2, bottom: profilePictureSelectionButton.frame.height * 0.2, right: profilePictureSelectionButton.frame.height * 0.2)
        profilePictureSelectionButton.addTarget(self, action: #selector(profilePictureSelectionButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: profilePictureSelectionButton)
        
        createAccountButton.frame.size.height = 50
        createAccountButton.frame.size.width = view.frame.width * 0.8
        createAccountButton.backgroundColor = appThemeColor
        createAccountButton.tintColor = .white
        createAccountButton.setTitle("Create account", for: .normal)
        createAccountButton.layer.cornerRadius = createAccountButton.frame.height/2
        createAccountButton.isExclusiveTouch = true
        createAccountButton.castDefaultShadow()
        createAccountButton.setTitleColor(UIColor.white, for: .normal)
        createAccountButton.titleLabel?.adjustsFontForContentSizeCategory = true
        createAccountButton.titleLabel?.adjustsFontSizeToFitWidth = true
        createAccountButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        createAccountButton.layer.shadowColor = appThemeColor.darker.cgColor
        createAccountButton.layer.shadowRadius = 3
        createAccountButton.alpha = 0
        createAccountButton.isEnabled = false
        createAccountButton.addTarget(self, action: #selector(createAccountButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: createAccountButton)
        
        /** Layout these subviews*/
        genderDOBScreenInstructionLabel.frame = CGRect(x: 10, y: backButton.frame.maxY + 10, width: labelSize.width, height: labelSize.height)
        
        /** Entry textfields*/
        DOBTextfield.frame.origin = CGPoint(x: genderDOBScreenInstructionLabel.frame.origin.x, y: genderDOBScreenInstructionLabel.frame.maxY + 20)
        genderTextfield.frame.origin = CGPoint(x: genderDOBScreenInstructionLabel.frame.origin.x, y: DOBTextfield.frame.maxY + 10)
        
        /** Image view*/
        profilePictureImageViewAnimatedBorder.frame.origin = CGPoint(x: view.frame.width/2 - profilePictureImageViewAnimatedBorder.frame.width/2, y: genderTextfield.frame.maxY + 10)
        profilePictureImageView.frame.origin = CGPoint(x: profilePictureImageViewAnimatedBorder.frame.width/2 - profilePictureImageView.frame.width/2, y: profilePictureImageViewAnimatedBorder.frame.height/2 - profilePictureImageView.frame.height/2)
        
        /** Buttons*/
        profilePictureSelectionButton.frame.origin = CGPoint(x: profilePictureImageViewAnimatedBorder.frame.maxX - (profilePictureSelectionButton.frame.width * 1.25), y: profilePictureImageViewAnimatedBorder.frame.maxY - (profilePictureSelectionButton.frame.height * 1.25))
        
        createAccountButton.frame.origin = CGPoint(x: view.frame.width/2 - createAccountButton.frame.width/2, y: view.frame.maxY - createAccountButton.frame.height * 1.5)
        
        view.addSubview(genderDOBScreenInstructionLabel)
        view.addSubview(DOBTextfield)
        view.addSubview(genderTextfield)
        view.addSubview(createAccountButton)
        
        profilePictureImageViewAnimatedBorder.addSubview(profilePictureImageView)
        view.addSubview(profilePictureImageViewAnimatedBorder)
        view.addSubview(profilePictureSelectionButton)
        
        return view
    }
    
    /** Triggers the create user profile method*/
    @objc func createAccountButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** The user needs a stable internet connection in order to create an account or else everything messes up*/
        if internetAvailable == true{
            createUserProfile()
        }
        else{
            globallyTransmit(this: "Account creation currently unavailable, please connect to the internet", with: UIImage(systemName: "wifi.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
        }
        
        forwardTraversalShake()
    }
    
    /** Compile all of the collected user information and submit it to the appropriate user profile collection*/
    func createUserProfile(){
        /** Don't push anything to the database if any of these values aren't set*/
        guard username != "" && firstName != "" && lastName != "" && email != "" && password != "" && phoneNumber != nil && DOB != nil && address != nil && gender != "" else {
            return
        }
        
        var profilePictureFileName = "pfp_user_\(username)_\(Date.now.hashValue)"
        
        /** Custom file paths for each user profile image corresponding to the type of user they are*/
        if customerPathSelected == true{
            profilePictureFileName = "pfp_c_user_\(username)_\(Date.now.hashValue)"
        }
        else if businessPathSelected == true{
            profilePictureFileName = "pfp_b_user_\(username)_\(Date.now.hashValue)"
        }
        else if driverPathSelected == true{
            profilePictureFileName = "pfp_d_user_\(username)_\(Date.now.hashValue)"
        }
        
        /** If the user has provided a profile picture then upload that first and then*/
        if profilePicture != nil{
            uploadThisImage(image: profilePicture!, directory: "/Profile Pictures", fileName: profilePictureFileName, imageCompressionQuality: 0, completion: { [self](fileURL) -> Void in
                
                /** If the uploaded profile picture's URL exists then progress like normal, if it doesn't then delete the resource submitted to the bucket and submit an empty string as the URL content for the user's profile */
                if fileURL != nil{
                    /** The push customer method will change the user's id to the real userID instead of "" after the push is successful*/
                    if customerPathSelected == true{
                        let customer = Customer(profile_picture: fileURL, created: .now, updated: .now, user_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, emailVerified: false, membershipLevel: 1, addresses: [address])
                        
                        pushCustomerUserToCollection(customer: customer, completion: { [self](customer) -> Void in
                            
                            moveToThis(slide: 5)
                            
                            setLoggedInUserType(userType: "Customer")
                            
                            /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                            userCompletedOnboarding()
                            
                            accountCreationComplete = true
                            accountCreationInProgress = false
                            
                            ///print(customer)
                        })
                    }
                    else if businessPathSelected == true{
                        let businessClient = BusinessClient(created: .now, updated: .now, user_id: "", employee_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, profile_picture: fileURL, address: address)
                        
                        pushBusinessClientUserToCollection(businessClient: businessClient, completion: {(businessClient) -> Void in
                            
                            moveToThis(slide: 5)
                            
                            /** The login type for non-customer users isn't specified because those users aren't supposed to be automatically logged in when they complete the sign-up process as they have to wait for verification which will result in them being sent their employee identification number*/
                            
                            /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                            userCompletedOnboarding()
                            
                            accountCreationComplete = true
                            accountCreationInProgress = false
                            
                            ///print(businessClient)
                        })
                    }
                    else if driverPathSelected == true{
                        let driver = Driver(created: .now, updated: .now, user_id: "", employee_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, profile_picture: fileURL, vehicle_type: "", address: address)
                        
                        pushDriverUserToCollection(driver: driver, completion: {(driver) -> Void in
                            
                            moveToThis(slide: 5)
                            
                            /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                            userCompletedOnboarding()
                            
                            accountCreationComplete = true
                            accountCreationInProgress = false
                            
                            ///print(driver)
                        })
                    }
                }
                else{
                    if customerPathSelected == true{
                        let customer = Customer(profile_picture: nil, created: .now, updated: .now, user_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, emailVerified: false, membershipLevel: 1, addresses: [address])
                        
                        pushCustomerUserToCollection(customer: customer, completion: {(customer) -> Void in
                            
                            moveToThis(slide: 5)
                            
                            setLoggedInUserType(userType: "Customer")
                            
                            /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                            userCompletedOnboarding()
                            
                            accountCreationComplete = true
                            accountCreationInProgress = false
                            
                            ///print(customer)
                        })
                    }
                    else if businessPathSelected == true{
                        let businessClient = BusinessClient(created: .now, updated: .now, user_id: "", employee_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, profile_picture: nil, address: address)
                        
                        pushBusinessClientUserToCollection(businessClient: businessClient, completion: {(businessClient) -> Void in
                            
                            moveToThis(slide: 5)
                            
                            /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                            userCompletedOnboarding()
                            
                            accountCreationComplete = true
                            accountCreationInProgress = false
                            
                            ///print(businessClient)
                        })
                    }
                    else if driverPathSelected == true{
                        let driver = Driver(created: .now, updated: .now, user_id: "", employee_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, profile_picture: nil, vehicle_type: "", address: address)
                        
                        pushDriverUserToCollection(driver: driver, completion: {(driver) -> Void in
                            
                            moveToThis(slide: 5)
                            
                            /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                            userCompletedOnboarding()
                            
                            accountCreationComplete = true
                            accountCreationInProgress = false
                            
                            ///print(driver)
                        })
                    }
                }
            })
        }
        else{
            /** If the user doesn't provide a picture then just suplement an empty string for the URL when pushing the profile to the database*/
            if customerPathSelected == true{
                let customer = Customer(profile_picture: nil, created: .now, updated: .now, user_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, emailVerified: false, membershipLevel: 1, addresses: [address])
                
                pushCustomerUserToCollection(customer: customer, completion: { [self](customer) -> Void in
                    
                    moveToThis(slide: 5)
                    
                    setLoggedInUserType(userType: "Customer")
                    
                    /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                    userCompletedOnboarding()
                    
                    accountCreationComplete = true
                    accountCreationInProgress = false
                    
                    ///print(customer)
                })
            }
            else if businessPathSelected == true{
                let businessClient = BusinessClient(created: .now, updated: .now, user_id: "", employee_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, profile_picture: nil, address: address)
                
                pushBusinessClientUserToCollection(businessClient: businessClient, completion: { [self](businessClient) -> Void in
                    
                    moveToThis(slide: 5)
                    
                    /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                    userCompletedOnboarding()
                    
                    accountCreationComplete = true
                    accountCreationInProgress = false
                    
                    ///print(businessClient)
                })
            }
            else if driverPathSelected == true{
                let driver = Driver(created: .now, updated: .now, user_id: "", employee_id: "", username: username, email: email, password: password, name: name, firstName: firstName, lastName: lastName, phoneNumber: "\(phoneNumber!.countryCode),\(phoneNumber!.nationalNumber)", gender: gender, DOB: DOB!, profile_picture: nil, vehicle_type: "", address: address)
                
                pushDriverUserToCollection(driver: driver, completion: { [self](driver) -> Void in
                    
                    moveToThis(slide: 5)
                    
                    /** Save userdefault informing the app that the user has created an account successfully and doesn't need to view the onboarding screen again*/
                    userCompletedOnboarding()
                    
                    accountCreationComplete = true
                    accountCreationInProgress = false
                    
                    ///print(driver)
                })
            }
        }
    }
    
    /** Reflect the gender of the person by changing the image displayed by the chosen path image view*/
    func reflectGenderInChosenPathImageView(){
        if profilePicture == nil && customerPathSelected == true{
            /** Depending on the gender of the person, change the photo to reflect this*/
            switch self.gender{
            case genders[0]:
                if chosenPathImageView.image != UIImage(named: "man"){
                    swapChosenPathImageViewPhoto(with: UIImage(named: "man")!, animated: true)
                }
                else{
                    break
                }
            case genders[1]:
                if chosenPathImageView.image != UIImage(named: "woman"){
                    swapChosenPathImageViewPhoto(with: UIImage(named: "woman")!, animated: true)
                }
                else{
                    break
                }
            case genders[2]:
                /** The default picture is the picture on the customer button*/
                if chosenPathImageView.image != customerButtonImage && chosenPathImageView.image != nil{
                    swapChosenPathImageViewPhoto(with: customerButtonImage, animated: true)
                }
                else{
                    chosenPathImageView.image = customerButtonImage
                }
            default:
                chosenPathImageView.image = customerButtonImage
            }
        }
        else if profilePicture == nil && customerPathSelected == false{
            if driverPathSelected == true{
                if chosenPathImageView.image != UIImage(named: "driver"){
                    swapChosenPathImageViewPhoto(with: UIImage(named: "driver")!, animated: true)
                }
            }
            else if businessPathSelected == true{
                if chosenPathImageView.image != UIImage(named: "briefcase"){
                    swapChosenPathImageViewPhoto(with: UIImage(named: "briefcase")!, animated: true)
                }
            }
        }
        
        if profilePicture != nil{
            chosenPathImageView.image = profilePicture
        }
    }
    
    /** Respond to changes in the date picker*/
    @objc func datePickerChanged(sender: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        DOBTextfield.text = dateFormatter.string(from: sender.date)
    }
    
    /** Triggers the image picker options menu*/
    @objc func profilePictureSelectionButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        lightHaptic()
        
        displayImagePickerOptions()
    }
    
    /** Display an alert view controller that displays options for the user to select a photo or a take a new one to use as their profile picture*/
    func displayImagePickerOptions(){
        let alert = UIAlertController(title: "Choose a photo", message: "Use a picture from your library or take a new one using your camera", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { [weak self] (action) in
            /**Capture self to avoid retain cycles*/
            guard let self = self else{
                return
            }
            
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: {
                
            })
        })
        
        let libraryAction = UIAlertAction(title: "Library", style: .default, handler: { [weak self] (action) in
            /**Capture self to avoid retain cycles*/
            guard let self = self else{
                return
            }
            
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: {
                
            })
        })
        
        /** Remove the chosen photo if the chosen photo exists under its variable*/
        let removeAction = UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] (action) in
            /**Capture self to avoid retain cycles*/
            guard let self = self else{
                return
            }
            
            /** Set the minus to a plus to inform the user they can add an image like the default state*/
            self.profilePictureSelectionButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
            
            self.profilePicture = nil
            self.profilePictureImageView.image = UIImage(named: "user")!
            
            if self.driverPathSelected == true{
                self.swapChosenPathImageViewPhoto(with: UIImage(named: "driver")!, animated: true)
                /** The user needs to supplement a profile picture for this path*/
                self.markImageViewAsIncorrect(imageView: self.profilePictureImageView)
            }
            else if self.businessPathSelected == true{
                self.swapChosenPathImageViewPhoto(with: UIImage(named: "briefcase")!, animated: true)
                self.markImageViewAsIncorrect(imageView: self.profilePictureImageView)
            }
            else if self.customerPathSelected == true{
                
                /** Depending on the gender of the person, change the photo to reflect this*/
                switch self.gender{
                case genders[0]:
                    self.swapChosenPathImageViewPhoto(with: UIImage(named: "man")!, animated: true)
                case genders[1]:
                    self.swapChosenPathImageViewPhoto(with: UIImage(named: "woman")!, animated: true)
                case genders[2]:
                    self.swapChosenPathImageViewPhoto(with: self.customerButtonImage, animated: true)
                default:
                    self.swapChosenPathImageViewPhoto(with: self.customerButtonImage, animated: true)
                }
                
                self.restoreOriginalImageViewStyling(imageView: self.profilePictureImageView, borderColor: appThemeColor, borderWidth: 1)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        
        if profilePicture != nil{
            alert.addAction(removeAction)
        }
        
        alert.addAction(cancelAction)
        alert.preferredAction = libraryAction
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /** Swap the chose path imageview's image with the given in an animated or static fashion*/
    func swapChosenPathImageViewPhoto(with image: UIImage, animated: Bool){
        if animated == true{
            /** Move the imageview out of the screen to the right briefly, change the image being displayed, and then move it back to its original position*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                chosenPathImageView.transform = CGAffineTransform(translationX: chosenPathImageView.frame.width * 2, y: 0)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                chosenPathImageView.image = image
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                    chosenPathImageView.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            }
        }
        else{
            chosenPathImageView.image = image
        }
    }
    
    /** Create the completion screen based off of the path the user chose*/
    func setCompletionScreen(){
        /** Remove duplicates*/
        for subview in completionScreen.subviews{
            subview.removeFromSuperview()
        }
        
        let labelSize = CGSize(width: view.frame.width * 0.9, height: view.frame.height * 0.3)
        
        let completionScreenInstructionLabel = UILabel(frame: CGRect(x: 10, y: backButton.frame.minY, width: labelSize.width, height: labelSize.height))
        completionScreenInstructionLabel.adjustsFontSizeToFitWidth = true
        completionScreenInstructionLabel.adjustsFontForContentSizeCategory = false
        completionScreenInstructionLabel.textAlignment = .left
        completionScreenInstructionLabel.numberOfLines = 3
        completionScreenInstructionLabel.lineBreakMode = .byClipping
        completionScreenInstructionLabel.backgroundColor = .clear
        completionScreenInstructionLabel.attributedText = attribute(this: "Welcome to \nStuy Wash N' Dry \n\(firstName) 🥳🎉", font: getCustomFont(name: .Bungee_Regular, size: 35, dynamicSize: false), subFont: getCustomFont(name: .Bungee_Regular, size: 35, dynamicSize: false), mainColor: appThemeColor, subColor: .lightGray, subString: "\(firstName)")
        completionScreenInstructionLabel.sizeToFit()
        
        /** Label describing the next steps for the user*/
        let advisoryLabel = UILabel()
        advisoryLabel.frame.size = CGSize(width: view.frame.width * 0.85, height: 60)
        advisoryLabel.adjustsFontSizeToFitWidth = true
        advisoryLabel.adjustsFontForContentSizeCategory = false
        advisoryLabel.textAlignment = .center
        advisoryLabel.numberOfLines = 0
        advisoryLabel.lineBreakMode = .byClipping
        advisoryLabel.backgroundColor = .clear
        
        let dismissButton = UIButton()
        dismissButton.frame.size.height = 50
        dismissButton.frame.size.width = view.frame.width * 0.75
        dismissButton.backgroundColor = appThemeColor
        dismissButton.tintColor = .white
        dismissButton.layer.cornerRadius = dismissButton.frame.height/2
        dismissButton.isExclusiveTouch = true
        dismissButton.castDefaultShadow()
        dismissButton.setTitleColor(UIColor.white, for: .normal)
        dismissButton.titleLabel?.adjustsFontForContentSizeCategory = true
        dismissButton.titleLabel?.adjustsFontSizeToFitWidth = true
        dismissButton.titleLabel?.font = getCustomFont(name: .Ubuntu_Regular, size: 18, dynamicSize: true)
        dismissButton.layer.shadowColor = appThemeColor.darker.cgColor
        dismissButton.layer.shadowRadius = 3
        
        dismissButton.addTarget(self, action: #selector(dismissButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: dismissButton)
        
        /** Lottie animation related to the specific path the user has chosen*/
        var completionScreenLottieAnimation = AnimationView()
        if customerPathSelected == true{
            /** Selection of animation files to choose from when creating the user completion screen for a somewhat unique experience*/
            let animationJSONFileNames = ["manRelaxingOnCouch","72929-reading-book","45551-men-relaxing-on-working-chair"]
            
            completionScreenLottieAnimation = AnimationView.init(name: animationJSONFileNames.randomElement()!)
            
            advisoryLabel.attributedText = attribute(this: "Sit back, relax, and enjoy the ride. We're happy to serve all of your laundry needs \(firstName). \nThank you for choosing us 💙", font: getCustomFont(name: .Ubuntu_Light, size: 16, dynamicSize: false), subFont: getCustomFont(name: .Ubuntu_bold, size: 16, dynamicSize: false), mainColor: .black, subColor: appThemeColor, subString: "\nThank you for choosing us 💙")
            
            dismissButton.setTitle("Let's go!", for: .normal)
        }
        else if driverPathSelected == true || businessPathSelected == true{
            completionScreenLottieAnimation = AnimationView.init(name: "verificationBadge")
            
            advisoryLabel.attributedText = attribute(this: "Your account is pending human-verification. Please be on the look out for an email containing your employee identification number which will allow you to access your new account. \nThank you!", font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: false), mainColor: .black, subColor: appThemeColor, subString: "\nThank you!")
            
            dismissButton.setTitle("See you soon!", for: .normal)
        }
        advisoryLabel.sizeToFit()
        
        completionScreenLottieAnimation.frame.size = CGSize(width: view.frame.width * 0.7, height: view.frame.width * 0.7)
        completionScreenLottieAnimation.animationSpeed = 1
        completionScreenLottieAnimation.isExclusiveTouch = true
        completionScreenLottieAnimation.shouldRasterizeWhenIdle = true
        completionScreenLottieAnimation.contentMode = .scaleAspectFill
        completionScreenLottieAnimation.isOpaque = false
        completionScreenLottieAnimation.clipsToBounds = true
        completionScreenLottieAnimation.backgroundColor = .clear
        completionScreenLottieAnimation.loopMode = .loop
        completionScreenLottieAnimation.backgroundBehavior = .pauseAndRestore
        completionScreenLottieAnimation.clipsToBounds = false
        completionScreenLottieAnimation.play(completion: nil)
        
        let confettiLottieAnimation = AnimationView.init(name: "confettiCannons")
        confettiLottieAnimation.frame.size = CGSize(width: view.frame.width * 1, height: view.frame.height * 1)
        confettiLottieAnimation.animationSpeed = 0.75
        confettiLottieAnimation.isExclusiveTouch = true
        confettiLottieAnimation.shouldRasterizeWhenIdle = true
        confettiLottieAnimation.contentMode = .scaleAspectFill
        confettiLottieAnimation.isOpaque = false
        confettiLottieAnimation.clipsToBounds = true
        confettiLottieAnimation.backgroundColor = .clear
        confettiLottieAnimation.loopMode = .playOnce
        confettiLottieAnimation.backgroundBehavior = .pauseAndRestore
        confettiLottieAnimation.clipsToBounds = false
        confettiLottieAnimation.play(completion: nil)
        
        /** Layout these subviews*/
        confettiLottieAnimation.frame.origin = CGPoint(x: view.frame.width/2 - confettiLottieAnimation.frame.width/2, y: view.frame.height/2 - (confettiLottieAnimation.frame.height/2))
        
        completionScreenLottieAnimation.frame.origin = CGPoint(x: view.frame.width/2 - completionScreenLottieAnimation.frame.width/2, y: view.frame.height/2 - (completionScreenLottieAnimation.frame.height/2 + 10))
        
        completionScreenInstructionLabel.frame.origin = CGPoint(x: 10, y: completionScreenLottieAnimation.frame.minY - (completionScreenInstructionLabel.frame.height + 10))
        
        advisoryLabel.frame.origin = CGPoint(x: view.frame.width/2 - advisoryLabel.frame.width/2, y: completionScreenLottieAnimation.frame.maxY + 10)
        
        dismissButton.frame.origin = CGPoint(x: view.frame.width/2 - dismissButton.frame.width/2, y: view.frame.maxY - dismissButton.frame.height * 1.5)
        
        completionScreen.addSubview(completionScreenInstructionLabel)
        completionScreen.addSubview(completionScreenLottieAnimation)
        completionScreen.addSubview(advisoryLabel)
        completionScreen.addSubview(confettiLottieAnimation)
        completionScreen.addSubview(dismissButton)
    }
    
    /** Dismiss the view controller, present the customer client vc for new customers after they sign up*/
    @objc func dismissButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    
        if customerPathSelected == true{
            /** Present Customer UI*/
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let tabbarController = storyboard.instantiateViewController(withIdentifier: "CustomerNav") as! UITabBarController

            tabbarController.modalPresentationStyle = .fullScreen
            tabbarController.modalTransitionStyle = .coverVertical
            self.present(tabbarController, animated: true, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now()){
                globallyTransmit(this: "Welcome \(Auth.auth().currentUser?.displayName ?? "")!", with: UIImage(systemName: "heart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            }
        }
        else if driverPathSelected == true || businessPathSelected == true{
            self.dismiss(animated: true, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now()){
                globallyTransmit(this: "See you soon \(Auth.auth().currentUser?.displayName ?? "")", with: UIImage(systemName: "heart.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            }
            
            /** Sign out the driver and business clients because they aren't authorized to continue without logging in with their provided ID number*/
            signOutCurrentUser()
        }
        
        forwardTraversalShake()
    }
    
    // MARK: - Screens
    
    /** Chose an image and display it in the top right corner*/
    func displayChosenPathImageView(){
        chosenPathImageView.frame.size = CGSize(width: (view.frame.height * 0.1), height: (view.frame.height * 0.1))
        chosenPathImageView.frame.origin = CGPoint(x: view.frame.width, y: (view.frame.height * 0.2)/2 - chosenPathImageView.frame.height/2)
        chosenPathImageView.isUserInteractionEnabled = false
        chosenPathImageView.layer.zPosition = 1
        chosenPathImageView.contentMode = .scaleAspectFill
        chosenPathImageView.backgroundColor = .clear
        chosenPathImageView.tintColor = appThemeColor
        chosenPathImageView.layer.borderColor = UIColor.white.cgColor
        chosenPathImageView.layer.borderWidth = 1
        chosenPathImageView.layer.cornerRadius = chosenPathImageView.frame.height/2
        chosenPathImageView.clipsToBounds = true
        
        if driverPathSelected == true{
            chosenPathImageView.image = UIImage(named: "driver")
            genderDOBScreenInstructionLabel.attributedText = attribute(this: "Please enter your birth date, gender, and a profile picture", font: getCustomFont(name: .Ubuntu_bold, size: 20, dynamicSize: true), mainColor: appThemeColor, subColor: .lightGray, subString: "")
        }
        else if businessPathSelected == true{
            chosenPathImageView.image = UIImage(named: "briefcase")
            genderDOBScreenInstructionLabel.attributedText = attribute(this: "Please enter your birth date, gender, and a profile picture", font: getCustomFont(name: .Ubuntu_bold, size: 20, dynamicSize: true), mainColor: appThemeColor, subColor: .lightGray, subString: "")
        }
        else if customerPathSelected == true{
            
            /** Depending on the gender of the person, change the photo to reflect this*/
            switch self.gender{
            case genders[0]:
                if chosenPathImageView.image != UIImage(named: "man"){
                    chosenPathImageView.image = UIImage(named: "man")!
                }
                else{
                    break
                }
            case genders[1]:
                if chosenPathImageView.image != UIImage(named: "woman"){
                    chosenPathImageView.image = UIImage(named: "woman")!
                }
                else{
                    break
                }
            case genders[2]:
                /** The default picture is the picture on the customer button*/
                if chosenPathImageView.image != customerButtonImage && chosenPathImageView.image != nil{
                    chosenPathImageView.image = customerButtonImage
                }
                else{
                    chosenPathImageView.image = customerButtonImage
                }
            default:
                chosenPathImageView.image = customerButtonImage
            }
            
            genderDOBScreenInstructionLabel.attributedText = attribute(this: "Enter your birth date, gender, and a profile picture (Optional)", font: getCustomFont(name: .Ubuntu_bold, size: 20, dynamicSize: true), subFont: getCustomFont(name: .Ubuntu_Regular, size: 20, dynamicSize: true), mainColor: appThemeColor, subColor: .lightGray, subString: "(Optional)")
        }
        
        /** If the user has taken their profile picture then display it instead*/
        if profilePicture != nil{
            chosenPathImageView.image = profilePicture
        }
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
            chosenPathImageView.frame.origin = CGPoint(x: view.frame.width - chosenPathImageView.frame.width * 1.25, y: (view.frame.height * 0.2)/2 - chosenPathImageView.frame.height/2)
        }
        
        view.addSubview(chosenPathImageView)
    }
    
    /** Hide the chosen path imageview in an animated or static manner*/
    func hideChosenPathImageView(animated: Bool){
        if animated == true{
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                chosenPathImageView.frame.origin = CGPoint(x: view.frame.width, y: (view.frame.height * 0.2)/2 - chosenPathImageView.frame.height/2)
            }
        }
        else{
            chosenPathImageView.frame.origin = CGPoint(x: view.frame.width, y: (view.frame.height * 0.2)/2 - chosenPathImageView.frame.height/2)
        }
    }
    
    /** Button Pressed Methods*/
    /** Present the terms of service view controller*/
    @objc func termsOfServiceButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        lightHaptic()
        
        let tosVC = TermsofServiceVC()
        tosVC.modalPresentationStyle = .formSheet
        tosVC.modalTransitionStyle = .coverVertical
        self.present(tosVC, animated: true, completion: nil)
    }
    
    /** Move forward in the sign up process*/
    @objc func continueButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        forwardTraversalShake()
        
        moveForwards()
    }
    
    /** Show and hide methods for the continue button*/
    func showContinueButton(animated: Bool, at location: CGPoint){
        continueButton.frame.origin = location
        
        /*** If the screen's height is smaller than or equal to 600 pixels override the given position and force the continue button to be adjacent to the back button*/
        if UIScreen.main.bounds.height <= 600{
            continueButton.frame.origin = CGPoint(x: backButton.frame.maxX + 10, y: backButton.frame.origin.y)
        }
        
        continueButton.isEnabled = true
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                continueButton.isHidden = false
                continueButton.alpha = 1
            }
        }else{
            continueButton.isHidden = false
            continueButton.alpha = 1
        }
    }
    
    func showDisabledContinueButton(animated: Bool, at location: CGPoint){
        continueButton.frame.origin = location
        
        /*** If the screen's height is smaller than or equal to 600 pixels override the given position and force the continue button to be adjacent to the back button*/
        if UIScreen.main.bounds.height <= 600{
            continueButton.frame.origin = CGPoint(x: backButton.frame.maxX + 10, y: backButton.frame.origin.y)
        }
        
        continueButton.isEnabled = false
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                continueButton.isHidden = false
                continueButton.alpha = 0.5
            }
        }else{
            continueButton.isHidden = false
            continueButton.alpha = 0.5
        }
    }
    
    func hideContinueButton(animated: Bool, at location: CGPoint){
        continueButton.frame.origin = location
        
        /*** If the screen's height is smaller than or equal to 600 pixels override the given position and force the continue button to be adjacent to the back button*/
        if UIScreen.main.bounds.height <= 600{
            continueButton.frame.origin = CGPoint(x: backButton.frame.maxX + 10, y: backButton.frame.origin.y)
        }
        
        continueButton.isEnabled = false
        if animated{
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                continueButton.alpha = 0
            }
        }else{
            continueButton.alpha = 0
        }
    }
    /** Show and hide methods for the continue button*/
    
    /** Methods for displaying the otpCountDownLabel*/
    func hideOTPCountDownLabel(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            otpCountDownLabel.alpha = 0
        }
    }
    
    func showOTPCountDownLabel(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            otpCountDownLabel.alpha = 1
        }
    }
    
    /** Stops the count down immediately*/
    func stopOTPCountDown(){
        otpCountDownTimer.invalidate()
        numberTickTimer.invalidate()
    }
    
    /** Start the timer that counts down the amount of time the user has left to fill out the OTP fields*/
    func startOTPCountDown(){
        /** Reset the countdown position*/
        countDownPosition = 60
        otpCountDownLabel.text = "1:00"
        
        numberTickTimer.invalidate()
        numberTickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block:{ [self]_ in
            
            if countDownPosition > 0{
                countDownPosition -= 1
            }
            
            UIView.transition(with: otpCountDownLabel, duration: 1, options: .curveEaseIn, animations:{ [self] in
                otpCountDownLabel.text = convertToCountDown(duration: UInt(countDownPosition))
            })
        })
        
        otpCountDownTimer.invalidate()
        otpCountDownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block:{ [self]_ in
            numberTickTimer.invalidate()
            hideOTPTextFieldUI()
            hideOTPCountDownLabel()
            
            /** Reset the code*/
            OTPCode = ""
            
            /** Resign the textfield*/
            view.endEditing(true)
            
            /** Allow the user to use the verify phone button again*/
            verifyPhoneButton.isEnabled = true
            verifyPhoneButton.alpha = 1
        })
    }
    /** Methods for displaying the otpCountDownLabel*/
    
    /** Methods for displaying the resendOTPButton*/
    func hideResendOTPButton(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            resendOTPButton.isEnabled = false
            resendOTPButton.alpha = 0
        }
    }
    
    func disableResendOTPButton(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            resendOTPButton.isEnabled = false
            resendOTPButton.alpha = 0.5
        }
    }
    
    func showResendOTPButton(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            resendOTPButton.isEnabled = true
            resendOTPButton.alpha = 1
        }
    }
    /** Methods for displaying the resendOTPButton*/
    
    /** Resend the OTP SMS to the user ONCE*/
    @objc func resendOTPButtonPressed(sender: UIButton){
        /** Disable this button*/
        disableResendOTPButton()
        
        verifyPhoneButtonPressed(sender: verifyPhoneButton)
        
        mediumHaptic()
    }
    
    /** Send an SMS to the user and verify the SMS OTP with the client's OTP*/
    @objc func verifyPhoneButtonPressed(sender: UIButton){
        mediumHaptic()
        
        /** Shut it down*/
        guard phoneNumber != nil else {
            sender.alpha = 0.5
            sender.isEnabled = false
            
            return
        }
        
        /** Don't progress if there's no internet connection*/
        guard internetAvailable == true else{
            globallyTransmit(this: "SMS verification code cannot be sent, please connect to the internet", with: UIImage(systemName: "message.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 3, selfDismiss: true)
            return
        }
        
        /** Disable this button after it's pressed*/
        sender.alpha = 0.5
        sender.isEnabled = false
        
        /** Use the phone number string to send the SMS*/
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(("+\(phoneNumber!.countryCode) \(phoneNumber!.nationalNumber)"), uiDelegate: self){ [self] verificationID, error in
                if let error = error{
                    print(error.localizedDescription)
                    /** Error happened*/
                    globallyTransmit(this: "SMS verification code could not be sent, please try again", with: UIImage(systemName: "message.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 3, selfDismiss: true)
                    
                    /** Enable this button*/
                    sender.alpha = 1
                    sender.isEnabled = true
                    
                    errorShake()
                    
                    return
                }
                
                self.verificationID =  verificationID!
                
                /** Inform user to look out for SMS message*/
                globallyTransmit(this: "SMS verification code successfully sent", with: UIImage(systemName: "message.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 3, selfDismiss: true)
                
                /** Everything is fine, proceed!*/
                /**Sign in using the verificationID and the code sent to the user*/
                showOTPTextFieldUI()
                
                /** If the resend button is hidden then show it because this means it hasn't been activated yet*/
                if resendOTPButton.alpha == 0{
                    showResendOTPButton()
                }
                
                showOTPCountDownLabel()
                startOTPCountDown()
                
                forwardTraversalShake()
            }
    }
    
    /** Function called after the OTP is set, meaning the user has finished entering the provided OTP or a number into the corresponding OTP UI*/
    func authPhoneNumber(){
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: OTPCode
        )
        
        /** If a current user already exists then simply link the credential with that user instead of signing in*/
        if let user = Auth.auth().currentUser, Auth.auth().currentUser != nil{
            user.link(with: credential, completion: { [self] authResult, error in
                
                if let error = error{
                    /** Error happened*/
                    print(error.localizedDescription)
                    
                    for OTPTextField in OTPTextFields{
                        markTextFieldEntryAsIncorrect(textField: OTPTextField)
                    }
                    
                    globallyTransmit(this: "SMS verification code invalid, please try again. Tap the button once to receive another code", with: UIImage(systemName: "message.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 3, selfDismiss: true)
                    
                    return
                }
                
                /** Sign in successful*/
                for OTPTextField in OTPTextFields {
                    markTextFieldEntryAsCorrect(textField: OTPTextField)
                }
                disableResendOTPButton()
                
                /** A full code has been entered so the phone number will be verified*/
                phoneNumberVerified = true
                
                if email != "" && phoneNumber != nil && phoneNumberVerified == true{
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                    
                    /** Automatically press the continue button*/
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [self] _ in
                        continueButtonPressed(sender: continueButton)
                    })
                }
                
                ///print("Signed In!")
            })
        }
        else{
            Auth.auth().signIn(with: credential) { [self] authResult, error in
                if let error = error{
                    /** Error happened*/
                    print(error.localizedDescription)
                    
                    for OTPTextField in OTPTextFields{
                        markTextFieldEntryAsIncorrect(textField: OTPTextField)
                    }
                    
                    globallyTransmit(this: "SMS verification code invalid, please try again. Tap the button once to receive another code", with: UIImage(systemName: "message.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: UIColor.red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .coverStatusBar, animated: true, duration: 3, selfDismiss: true)
                    
                    return
                }
                
                /** Sign in successful*/
                for OTPTextField in OTPTextFields {
                    markTextFieldEntryAsCorrect(textField: OTPTextField)
                }
                disableResendOTPButton()
                
                /** A full code has been entered so the phone number will be verified*/
                phoneNumberVerified = true
                
                if email != "" && phoneNumber != nil && phoneNumberVerified == true{
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                    
                    /** Automatically press the continue button*/
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [self] _ in
                        continueButtonPressed(sender: continueButton)
                    })
                }
                
                ///print("Signed In!")
            }
        }
    }
    
    /** Hides the OTP Textfields*/
    func hideOTPTextFieldUI(){
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            OTPTextFieldContainer.alpha = 0
        }
        UIView.animate(withDuration: 1, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            verifyPhoneButton.transform = CGAffineTransform(translationX: 0, y: 0)
            resendOTPButton.transform = CGAffineTransform(translationX: 0, y: 0)
            otpCountDownLabel.transform = CGAffineTransform(translationX: 0, y: 0)
        }
        
        hideResendOTPButton()
    }
    
    /** Shows the OTP Textfields*/
    func showOTPTextFieldUI(){
        /** Erase the textfields*/
        for OTPTextField in OTPTextFields {
            OTPTextField.text = ""
        }
        
        /** Present the keyboard*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            OTPTextField_1.becomeFirstResponder()
        }
        
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            OTPTextFieldContainer.isHidden = false
            OTPTextFieldContainer.alpha = 1
        }
        
        /** Translate these views to make room for the other views*/
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            verifyPhoneButton.transform = CGAffineTransform(translationX: 0, y: (OTPTextFieldContainer.frame.height * 1.25))
            resendOTPButton.transform = CGAffineTransform(translationX: 0, y: (OTPTextFieldContainer.frame.height * 1.25))
            otpCountDownLabel.transform = CGAffineTransform(translationX: 0, y: (OTPTextFieldContainer.frame.height * 1.25))
        }
    }
    
    /** Sign in with third party applications method*/
    @objc func appleSignInButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** Require an internet connection before proceeding*/
        if internetAvailable == true{
            startSignInWithAppleFlow()
        }
        else{
            globallyTransmit(this: "Apple sign-in unavailable, please connect to the internet", with: UIImage(systemName: "applelogo", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
        }
        
        forwardTraversalShake()
    }
    
    @objc func googleSignInButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** Require an internet connection before proceeding*/
        if internetAvailable == true{
            startSignInWithGoogleFlow()
        }
        else{
            globallyTransmit(this: "Google sign-in unavailable, please connect to the internet", with: UIImage(systemName: "g.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
        }
        
        forwardTraversalShake()
    }
    
    @objc func faceBookSignInButtonPressed(sender: FBLoginButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        /** Require an internet connection before proceeding*/
        if internetAvailable == true{
            /** Trigger the login button programmatically*/
            let nonce = randomNonceString()
            currentNonce = nonce
            faceBookLoginButton.nonce = sha256(nonce)
            
            faceBookLoginButton.sendActions(for: .touchUpInside)
        }
        else{
            globallyTransmit(this: "Facebook sign-in unavailable, please connect to the internet", with: UIImage(systemName: "f.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
        }
        
        forwardTraversalShake()
    }
    /** Sign in with third party applications method*/
    
    @objc func businessButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        pathSelected = true
        
        customerPathSelected = false
        businessPathSelected = true
        driverPathSelected = false
        
        /** Disable the other paths permanently to prevent the user from trying to link unauthorized third party accounts*/
        customerButton.isEnabled = false
        driverButton.isEnabled = false
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            customerButton.alpha = 0.5
            driverButton.alpha = 0.5
            customerButtonLabel.backgroundColor = .clear
            driverButtonLabel.backgroundColor = .clear
            driverButtonLabel.textColor = appThemeColor.withAlphaComponent(0.5)
            customerButtonLabel.textColor = appThemeColor.withAlphaComponent(0.5)
            
            businessButtonLabel.backgroundColor = appThemeColor
            businessButtonLabel.textColor = .white
        }
        
        /** Disable the third party sign up UI for non-customers*/
        signUpWithThirdPartyLabel.alpha = 0
        appleSignInButton.alpha = 0
        googleSignInButton.alpha = 0
        faceBookSignInButton.alpha = 0
        
        forwardTraversalShake()
        moveForwards()
        displayChosenPathImageView()
    }
    @objc func customerButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        pathSelected = true
        
        customerPathSelected = true
        businessPathSelected = false
        driverPathSelected = false
        
        /** Disable the other paths permanently to prevent the user from trying to link unauthorized third party accounts*/
        businessButton.isEnabled = false
        driverButton.isEnabled = false
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            businessButton.alpha = 0.5
            driverButton.alpha = 0.5
            businessButtonLabel.backgroundColor = .clear
            driverButtonLabel.backgroundColor = .clear
            driverButtonLabel.textColor = appThemeColor.withAlphaComponent(0.5)
            businessButtonLabel.textColor = appThemeColor.withAlphaComponent(0.5)
            
            customerButtonLabel.backgroundColor = appThemeColor
            customerButtonLabel.textColor = .white
        }
        
        /** Enable the third party sign up UI for customers if they haven't used them prior to clicking on the button*/
        if appleSignInButton.isEnabled != false{
            appleSignInButton.alpha = 1
        }
        if googleSignInButton.isEnabled != false{
            googleSignInButton.alpha = 1
        }
        if faceBookSignInButton.isEnabled != false{
            faceBookSignInButton.alpha = 1
        }
        if appleSignInButton.isEnabled != false || googleSignInButton.isEnabled != false || faceBookSignInButton.isEnabled != false{
            signUpWithThirdPartyLabel.alpha = 1
        }
        
        forwardTraversalShake()
        moveForwards()
        displayChosenPathImageView()
    }
    @objc func driverButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        pathSelected = true
        
        customerPathSelected = false
        businessPathSelected = false
        driverPathSelected = true
        
        /** Disable the other paths permanently to prevent the user from trying to link unauthorized third party accounts*/
        customerButton.isEnabled = false
        businessButton.isEnabled = false
        UIView.animate(withDuration: 0.5, delay: 0){[self] in
            businessButton.alpha = 0.5
            customerButton.alpha = 0.5
            businessButtonLabel.backgroundColor = .clear
            customerButtonLabel.backgroundColor = .clear
            customerButtonLabel.textColor = appThemeColor.withAlphaComponent(0.5)
            businessButtonLabel.textColor = appThemeColor.withAlphaComponent(0.5)
            
            driverButtonLabel.backgroundColor = appThemeColor
            driverButtonLabel.textColor = .white
        }
        
        /** Disable the third party sign up UI for non-customers*/
        signUpWithThirdPartyLabel.alpha = 0
        appleSignInButton.alpha = 0
        googleSignInButton.alpha = 0
        faceBookSignInButton.alpha = 0
        
        forwardTraversalShake()
        moveForwards()
        displayChosenPathImageView()
    }
    /** Button Pressed Methods*/
    
    /** Shift the scrollview to the right*/
    func moveForwards(){
        /** Avoid overflow by respecting the upper bound of the collection view*/
        if (pageControl.currentPage) < (pageControl.numberOfPages - 1){
            pageControl.currentPage += 1
            
            moveToThis(slide: pageControl.currentPage)
        }
        else if (pageControl.currentPage) == (pageControl.numberOfPages - 1){
            pageControl.currentPage += 1
            
            moveToThis(slide: pageControl.currentPage)
        }
    }
    
    /** Move the collection view to this specific view*/
    func moveToThis(slide: Int){
        /** Dismiss the keyboard if any*/
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            view.endEditing(true)
        }
        
        /** Avoid going out of bounds*/
        guard slide <= (pageControl.numberOfPages - 1) && slide >= 0 else{
            return
        }
        
        pageControl.currentPage = slide
        
        collectionView.setContentOffset(CGPoint(x: view.frame.width * CGFloat(pageControl.currentPage), y: 0), animated: true)
        
        switch pageControl.currentPage{
        case 0:
            hideChosenPathImageView(animated: true)
            
            /** Once you go back to the introduction screen you go back to selecting the path you want to chose, therrefore you can't skip it*/
            hideContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            
            /** Restore the original position of the TOS UI and the bottom mask*/
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear){[self] in
                termsOfServiceButtonContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
            let bottomMaskTransformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            bottomMaskTransformAnimation.fromValue = bottomMaskCurrentYTranslation
            bottomMaskTransformAnimation.toValue = 0
            bottomMaskTransformAnimation.duration = 1
            bottomMaskTransformAnimation.isRemovedOnCompletion = false
            bottomMaskTransformAnimation.isAdditive = true
            bottomMaskTransformAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            bottomMask.add(bottomMaskTransformAnimation, forKey: "transform.translation.y")
            
            bottomMaskCurrentYTranslation = 0
            
            /** Just in case a person tries a different path, deselects a picture and selects the customer path*/
            if profilePicture == nil{
                restoreOriginalImageViewStyling(imageView: profilePictureImageView, borderColor: appThemeColor, borderWidth: 1)
            }
            
            backButtonOptions.removeAll()
            backButtonOptions.append("Dismiss")
        case 1:
            currentlySelectedTextField = emailTextfield
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                emailTextfield.becomeFirstResponder()
            }
            
            /** Enable the continue button if all appropriate fields are already filled out*/
            if phoneNumberVerified == true && email != "" && phoneNumber != nil{
                showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            }
            else{
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            }
            
            /** Restore the original position of the TOS UI and the bottom mask*/
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear){[self] in
                termsOfServiceButtonContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
            let bottomMaskTransformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            bottomMaskTransformAnimation.fromValue = bottomMaskCurrentYTranslation
            bottomMaskTransformAnimation.toValue = 0
            bottomMaskTransformAnimation.duration = 1
            bottomMaskTransformAnimation.isRemovedOnCompletion = false
            bottomMaskTransformAnimation.isAdditive = true
            bottomMaskTransformAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            bottomMask.add(bottomMaskTransformAnimation, forKey: "transform.translation.y")
            
            bottomMaskCurrentYTranslation = 0
            
            backButtonOptions.removeAll()
            backButtonOptions.append("Dismiss")
            backButtonOptions.append("Introduction")
        case 2:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                usernameTextfield.becomeFirstResponder()
            }
            
            /** Enable the continue button if all appropriate fields are already filled out*/
            if username != "" && password != ""{
                showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            }
            else{
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            }
            
            /** Restore the original position of the TOS UI and the bottom mask*/
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear){[self] in
                termsOfServiceButtonContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
            let bottomMaskTransformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            bottomMaskTransformAnimation.fromValue = bottomMaskCurrentYTranslation
            bottomMaskTransformAnimation.toValue = 0
            bottomMaskTransformAnimation.duration = 1
            bottomMaskTransformAnimation.isRemovedOnCompletion = false
            bottomMaskTransformAnimation.isAdditive = true
            bottomMaskTransformAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            bottomMask.add(bottomMaskTransformAnimation, forKey: "transform.translation.y")
            
            bottomMaskCurrentYTranslation = 0
            
            backButtonOptions.removeAll()
            backButtonOptions.append("Dismiss")
            backButtonOptions.append("Introduction")
            backButtonOptions.append("Email")
        case 3:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                firstNameTextfield.becomeFirstResponder()
            }
            /** Enable the continue button if all appropriate fields are already filled out*/
            if firstName != "" && lastName != "" && address != nil{
                showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            }
            else{
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            }
            
            /** Restore the original position of the TOS UI and the bottom mask*/
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear){[self] in
                termsOfServiceButtonContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            
            let bottomMaskTransformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            bottomMaskTransformAnimation.fromValue = bottomMaskCurrentYTranslation
            bottomMaskTransformAnimation.toValue = 0
            bottomMaskTransformAnimation.duration = 1
            bottomMaskTransformAnimation.isRemovedOnCompletion = false
            bottomMaskTransformAnimation.isAdditive = true
            bottomMaskTransformAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            bottomMask.add(bottomMaskTransformAnimation, forKey: "transform.translation.y")
            
            bottomMaskCurrentYTranslation = 0
            
            backButtonOptions.removeAll()
            backButtonOptions.append("Dismiss")
            backButtonOptions.append("Introduction")
            backButtonOptions.append("Email")
            backButtonOptions.append("Username")
        case 4:
            /** No more continue button*/
            hideContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            
            /** Hide this button first, then animate it appearing (if applicable)*/
            createAccountButton.alpha = 0
            
            if driverPathSelected == true{
                /** Enable the create account button if all appropriate fields are already filled out*/
                if DOB != nil && genders.contains(gender) == true && profilePicture != nil{
                    UIView.animate(withDuration: 0.5, delay: 1){[self] in
                        createAccountButton.alpha = 1
                        createAccountButton.isEnabled = true
                    }
                }
                else{
                    UIView.animate(withDuration: 0.5, delay: 1){[self] in
                        createAccountButton.alpha = 0
                        createAccountButton.isEnabled = false
                    }
                }
            }
            else if businessPathSelected == true{
                /** Enable the create account button if all appropriate fields are already filled out*/
                if DOB != nil && genders.contains(gender) == true && profilePicture != nil{
                    UIView.animate(withDuration: 0.5, delay: 1){[self] in
                        createAccountButton.alpha = 1
                        createAccountButton.isEnabled = true
                    }
                }
                else{
                    UIView.animate(withDuration: 0.5, delay: 1){[self] in
                        createAccountButton.alpha = 0
                        createAccountButton.isEnabled = false
                    }
                }
            }
            else if customerPathSelected == true{
                UIView.animate(withDuration: 0.5, delay: 1){[self] in
                    createAccountButton.alpha = 1
                    createAccountButton.isEnabled = true
                }
            }
            
            /** Get rid of the bottom mask and tos button on the bottom so that it doesn't cover up the create an account button on super small devices*/
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear){[self] in
                termsOfServiceButtonContainer.transform = CGAffineTransform(translationX: 0, y: termsOfServiceButtonContainer.frame.height)
            }
            let bottomMaskTransformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            bottomMaskTransformAnimation.fromValue = bottomMaskCurrentYTranslation
            bottomMaskTransformAnimation.toValue = (view.frame.height * 0.5)
            bottomMaskTransformAnimation.duration = 1
            bottomMaskTransformAnimation.fillMode = .forwards
            bottomMaskTransformAnimation.isAdditive = true
            bottomMaskTransformAnimation.isRemovedOnCompletion = false
            bottomMaskTransformAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            bottomMask.add(bottomMaskTransformAnimation, forKey: "transform.translation.y")
            
            bottomMaskCurrentYTranslation = view.frame.height * 0.5
            
            /** Start animating the dashed border because the animation is removed when the view is off screen*/
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){[self] in
                profilePictureImageViewAnimatedBorder.animateDashedBorder()
            }
            
            backButtonOptions.removeAll()
            backButtonOptions.append("Dismiss")
            backButtonOptions.append("Introduction")
            backButtonOptions.append("Email")
            backButtonOptions.append("Username")
            backButtonOptions.append("Name")
        case 5:
            setCompletionScreen()
            
            hideContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear){[self] in
                termsOfServiceButtonContainer.transform = CGAffineTransform(translationX: 0, y: termsOfServiceButtonContainer.frame.height)
            }
            
            let bottomMaskTransformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            bottomMaskTransformAnimation.fromValue = bottomMaskCurrentYTranslation
            bottomMaskTransformAnimation.toValue = (view.frame.height * 0.5)
            bottomMaskTransformAnimation.duration = 1
            /** Don't reset the layer's position when this animation is completed*/
            bottomMaskTransformAnimation.fillMode = .forwards
            /** Smooth out the animation if it's switches to from another animation suddenly*/
            bottomMaskTransformAnimation.isAdditive = true
            bottomMaskTransformAnimation.isRemovedOnCompletion = false
            bottomMaskTransformAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            bottomMask.add(bottomMaskTransformAnimation, forKey: "transform.translation.y")
            
            bottomMaskCurrentYTranslation = view.frame.height * 0.5
            
            disposeOfBackButton(animated: true)
            
            backButtonOptions.removeAll()
            backButtonOptions.append("Dismiss")
            backButtonOptions.append("Introduction")
            backButtonOptions.append("Email")
            backButtonOptions.append("Username")
            backButtonOptions.append("Name")
            backButtonOptions.append("DOB")
        default:
            break
        }
    }
    
    /** Back button hide, disposal, and show methods*/
    /** Hide the back button in an animated or static fashion*/
    func hideBackButton(animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                backButton.alpha = 0
            }
        case false:
            backButton.alpha = 0
        }
    }
    
    /** Display the back button in an animated or static fashion*/
    func showBackButton(animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                backButton.alpha = 1
            }
        case false:
            backButton.alpha = 1
        }
    }
    
    /** Remove the back button from the view hierarchy in an animated or static fashion*/
    func disposeOfBackButton(animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0){ [self] in
                backButton.alpha = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                backButton.removeFromSuperview()
            }
        case false:
            backButton.alpha = 0
            backButton.removeFromSuperview()
        }
    }
    /** Back button hide, disposal, and show methods*/
    
    /** Configures and adds the back button to the view hierarchy*/
    func supplementBackButton(){
        let imageConfiguration = UIImage.SymbolConfiguration(weight: .regular)
        let image = UIImage(systemName: "arrow.backward", withConfiguration: imageConfiguration)
        
        backButton.frame.size.height = 50
        backButton.frame.size.width = backButton.frame.size.height
        backButton.backgroundColor = appThemeColor
        backButton.tintColor = .white
        backButton.setImage(image, for: .normal)
        backButton.layer.cornerRadius = backButton.frame.height/2
        backButton.isExclusiveTouch = true
        backButton.castDefaultShadow()
        backButton.layer.shadowColor = appThemeColor.darker.cgColor
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        addDynamicButtonGR(button: backButton)
        backButton.alpha = 0
        backButton.isEnabled = false
        
        backButton.addInteraction(UIContextMenuInteraction(delegate: self))
        
        /** Everything else depends on this button's position so make sure this is positioned correctly*/
        backButton.frame.origin = CGPoint(x: 10, y: view.getStatusBarHeight() + 15)
        
        /** Scale up animation*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            backButton.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            UIView.animate(withDuration: 1, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){ [self] in
                backButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                backButton.alpha = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
            backButton.isEnabled = true
        }
    }
    
    @objc func backButtonPressed(sender: UIButton){
        backwardTraversalShake()
        
        /** Dismiss the keyboard if any*/
        view.endEditing(true)
        
        
        if pathSelected == false{
            if onboardingVCPresenting == true{
                onboardingVC!.displayStartScreen()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){ [self] in
                    onboardingVC!.setStartMenuPosition()
                }
            }
            
            self.dismiss(animated: true, completion: nil)
            purgeTemporaryUsersOnDismiss()
        }
        else{
            /** Dismiss when the button is pressed when the user returns to the first slide*/
            if pageControl.currentPage - 1 == 0{
                pathSelected = false
            }
            moveToThis(slide: pageControl.currentPage - 1)
        }
    }
    
    /** Collection view delegate methods*/
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionViewSlideCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SignUpVCCollectionViewCell.identifier, for: indexPath) as! SignUpVCCollectionViewCell
        
        cell.contentView.backgroundColor = bgColor
        
        cell.setUp(with: collectionViewCells[indexPath.row])
        
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
    
    /*** Keyboard will hide and show methods
     @objc func keyboardWillShow(notification: NSNotification){
     guard let userInfo = notification.userInfo else {return}
     guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
     let keyboardFrame = keyboardSize.cgRectValue
     
     guard currentlySelectedTextField != nil else {
     return
     }
     
     }
     
     @objc func keyboardWillHide(notification: NSNotification){
     guard currentlySelectedTextField != nil else {
     return
     }
     
     }
     Keyboard will hide and show methods*/
    
    /** Triggered when the textfield is getting ready to begin editting*/
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool{
        
        markTextFieldAsFocused(textField: textField)
        
        currentlySelectedTextField = textField
        currentlySelectedTextFieldOriginalPosition = textField.frame.origin
        
        /** Move the password field down to reveal the username requirements*/
        if textField == usernameTextfield{
            showUsernameRequirementsUI()
            hidePasswordRequirementsUI()
        }
        
        /** Move the password field back to its original position when the user switches to the password field*/
        if textField == passwordTextfield{
            hideUsernameRequirementsUI()
            showPasswordRequirementsUI()
        }
        
        return true
    }
    
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
    
    /** Triggered when the user changes characters in the current first responder text field*/
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        /** Only execute the following code if the textfield isn't an OTP text field*/
        var isOTPTextfield = false
        for OTPTextField in OTPTextFields {
            if textField == OTPTextField{
                isOTPTextfield = true
            }
        }
        
        guard isOTPTextfield == true else{
            return true
        }
        
        /** Make sure the string's length is 1 character maximum to prevent a user from pasting a long string into the texfield*/
        guard string.count <= 1 else{
            return false
        }
        
        phoneNumberVerified = false
        showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
        
        /** The maximum string length for these textfields is 1, when the user enters a digit then move to the next textfield*/
        if (string.count == 1){
            if textField == OTPTextField_1{
                OTPTextField_2.becomeFirstResponder()
            }
            if textField == OTPTextField_2{
                OTPTextField_3.becomeFirstResponder()
            }
            if textField == OTPTextField_3{
                OTPTextField_4.becomeFirstResponder()
            }
            if textField == OTPTextField_4{
                OTPTextField_5.becomeFirstResponder()
            }
            if textField == OTPTextField_5{
                OTPTextField_6.becomeFirstResponder()
            }
            if textField ==  OTPTextField_6{
                OTPTextField_6.resignFirstResponder()
                OTPTextField_6.text = string
                
                OTPCode = ""
                OTPCode += OTPTextField_1.text!
                OTPCode += OTPTextField_2.text!
                OTPCode += OTPTextField_3.text!
                OTPCode += OTPTextField_4.text!
                OTPCode += OTPTextField_5.text!
                OTPCode += OTPTextField_6.text!
                
                authPhoneNumber()
                
                /**print(OTPCode)*/
                
                /** User has entered the OTP code so stop the timer and hide the label*/
                hideOTPCountDownLabel()
                stopOTPCountDown()
            }
            textField.text? = string
            return false
        }
        else{
            /** If the user back spaces then make the previous textfield the first responder*/
            if textField == OTPTextField_1{
                OTPTextField_1.becomeFirstResponder()
            }
            if textField == OTPTextField_2{
                OTPTextField_1.becomeFirstResponder()
            }
            if textField == OTPTextField_3{
                OTPTextField_2.becomeFirstResponder()
            }
            if textField == OTPTextField_4{
                OTPTextField_3.becomeFirstResponder()
            }
            if textField == OTPTextField_5{
                OTPTextField_4.becomeFirstResponder()
            }
            if textField ==  OTPTextField_6{
                OTPTextField_5.becomeFirstResponder()
            }
            
            textField.text? = string
            return false
        }
    }
    
    /** Triggered when the textfield is getting ready to end editing*/
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool{
        restoreOriginalTextFieldStyling(textField: textField)
        
        /** Validate the email address*/
        if textField == emailTextfield && textField.text != ""{
            switch isEmailValid(textField.text!){
            case true:
                /** If the email  hasn't changed then don't reenable the verification button*/
                guard email != emailTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Clear the value of this var and set it after verification has been done*/
                email = ""
                
                /** Check to see if the given email already exists for another user*/
                if internetAvailable == true{
                    
                    /** Inform the user that a network sensitive operation is being performed*/
                    displayLoadingIndicator(at: CGPoint(x: 10, y: view.frame.maxY - (view.frame.width * 0.2 + 10)), duration: 0.5, size: view.frame.width * 0.2)
                    
                    checkIfEmailExistsInDatabase(email: textField.text!, completion: { [self](result) -> Void in
                        if result == true{
                            
                            globallyTransmit(this: "This email is already in use, please use another one", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            
                            /** Reset the email textfield and variable*/
                            email = ""
                            UIView.transition(with: textField, duration: 1, options: .curveEaseIn, animations: {
                                textField.text = ""
                            })
                            
                            markTextFieldEntryAsIncorrect(textField: textField)
                            
                            errorShake()
                        }
                        else{
                            globallyTransmit(this: "This email is available for use", with: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            
                            markTextFieldEntryAsCorrect(textField: textField)
                            
                            /** Set the var for the email string to the textfield's current value*/
                            email = textField.text!
                            
                            successfulActionShake()
                        }
                        
                        /** Networking sensitive operation done*/
                        removeLoadingIndicator()
                    })
                }
                else{
                    globallyTransmit(this: "This email can't be verified right now, please connect to the internet", with: UIImage(systemName: "message.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                    
                    /** Reset the email textfield and variable*/
                    email = ""
                    UIView.transition(with: textField, duration: 1, options: .curveEaseIn, animations: {
                        textField.text = ""
                    })
                    
                    markTextFieldEntryAsIncorrect(textField: textField)
                    errorShake()
                }
            case false:
                /** The email doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Clear the value of the email*/
                email = ""
                
                errorShake()
            }
        }
        else if textField == emailTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            
            /** Clear the value of the email*/
            email = ""
        }
        
        /** Validate the phone number*/
        if textField == phoneTextfield{
            
            /** The phone number's country code will be stored in the table and parsed into a phoneNumber object up retrieval, when logging in the user just has to specify the national number and not the whole country code bit too*/
            switch phoneTextfield.isValidNumber{
            case true:
                
                /** If the phone number hasn't changed then don't reenable the verification button*/
                guard phoneNumber != phoneTextfield.phoneNumber else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                /** Reset everything and await verification*/
                hideOTPTextFieldUI()
                
                /** Disable this button*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    verifyPhoneButton.isEnabled = false
                    verifyPhoneButton.alpha = 0.5
                }
                
                phoneNumberVerified = false
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Clear the value of this var and set it after verification has been done*/
                phoneNumber = nil
                
                /** Check to see if the given phone number already exists for another user*/
                if internetAvailable == true{
                    
                    /** Inform the user that a network sensitive operation is being performed*/
                    displayLoadingIndicator(at: CGPoint(x: 10, y: view.frame.maxY - (view.frame.width * 0.2 + 10)), duration: 0.5, size: view.frame.width * 0.2)
                    
                    checkIfPhoneNumberExistsInDatabase(phoneNumber: phoneTextfield.phoneNumber!, completion: { [self](result) -> Void in
                        if result == true{
                            
                            globallyTransmit(this: "This phone number is already in use, please use another one", with: UIImage(systemName: "phone.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            
                            UIView.transition(with: textField, duration: 1, options: .curveEaseIn, animations: {
                                textField.text = ""
                            })
                            
                            /** This phone number is invalid*/
                            markTextFieldEntryAsIncorrect(textField: textField)
                            
                            /** Reset the phone number textfield and variable*/
                            phoneNumber = nil
                            
                            errorShake()
                        }
                        else{
                            globallyTransmit(this: "This phone number is available for use", with: UIImage(systemName: "phone.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            
                            markTextFieldEntryAsCorrect(textField: textField)
                            
                            /** Enable this button*/
                            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                                verifyPhoneButton.isEnabled = true
                                verifyPhoneButton.alpha = 1
                            }
                            
                            /** Set the phone number to the phone textfield's current phone number*/
                            phoneNumber = phoneTextfield.phoneNumber
                            
                            successfulActionShake()
                        }
                        
                        /** Networking sensitive operation done*/
                        removeLoadingIndicator()
                    })
                }
                else{
                    globallyTransmit(this: "This phone number can't be verified right now, please connect to the internet", with: UIImage(systemName: "phone.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                    
                    /** This phone number is invalid*/
                    markTextFieldEntryAsIncorrect(textField: textField)
                    
                    /** Reset the phone number textfield and variable*/
                    phoneNumber = nil
                    
                    errorShake()
                }
            case false:
                /** This phone number is invalid*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                /** Reset the phone number textfield and variable*/
                phoneNumber = nil
                
                /** Disable this button*/
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    verifyPhoneButton.isEnabled = false
                    verifyPhoneButton.alpha = 0.5
                }
                
                phoneNumberVerified = false
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                errorShake()
            }
            
            /** Store the phone number in the following CSV format when pushing to remote or storage*/
            /** CountryCode,NationalNumber ex.) "1,3471234567"*/
        }
        
        /** Validate the username*/
        if textField == usernameTextfield && textField.text != ""{
            switch isUsernameValid(textField.text!){
            case true:
                /** If the username hasn't changed then don't verify the username*/
                guard username != usernameTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Clear the value of this var and set it after verification has been done*/
                username = ""
                
                /** Check to see if the given username already exists for another user*/
                if internetAvailable == true{
                    
                    /** Inform the user that a network sensitive operation is being performed*/
                    displayLoadingIndicator(at: CGPoint(x: 10, y: view.frame.maxY - (view.frame.width * 0.2 + 10)), duration: 0.5, size: view.frame.width * 0.2)
                    
                    checkIfUsernameExistsInDatabase(username: textField.text!, completion: { [self](result) -> Void in
                        if result == true{
                            
                            globallyTransmit(this: "This username is already in use, please choose another one", with: UIImage(systemName: "at.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            
                            /** Reset the username textfield and variable*/
                            username = ""
                            UIView.transition(with: textField, duration: 1, options: .curveEaseIn, animations: {
                                textField.text = ""
                            })
                            
                            markTextFieldEntryAsIncorrect(textField: textField)
                            
                            errorShake()
                        }
                        else{
                            globallyTransmit(this: "This username is available for use", with: UIImage(systemName: "at.badge.plus", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .green, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                            
                            markTextFieldEntryAsCorrect(textField: textField)
                            
                            /** Set the var for the username string to the textfield's current value*/
                            username = textField.text!
                            
                            /** Enable the continue button if both the username and password are valid and available*/
                            if username != "" && password != ""{
                                showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                            }
                            
                            successfulActionShake()
                        }
                        
                        /** Networking sensitive operation done*/
                        removeLoadingIndicator()
                    })
                }
                else{
                    globallyTransmit(this: "This username can't be verified right now, please connect to the internet", with: UIImage(systemName: "at.badge.minus", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: .clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 3, selfDismiss: true)
                    
                    /** Reset the username textfield and variable*/
                    username = ""
                    UIView.transition(with: textField, duration: 1, options: .curveEaseIn, animations: {
                        textField.text = ""
                    })
                    
                    markTextFieldEntryAsIncorrect(textField: textField)
                    errorShake()
                }
            case false:
                /** The username doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Clear the value of the username*/
                username = ""
                
                errorShake()
            }
        }
        else if textField == usernameTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            
            /** Clear the value of the username*/
            username = ""
        }
        
        /** Validate the password*/
        if textField == passwordTextfield && textField.text != ""{
            switch isPasswordValid(textField.text!){
            case true:
                /** If the password hasn't changed then don't verify the password*/
                guard password != passwordTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set the var for the password string to the textfield's current value*/
                password = textField.text!
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if both the username and password are valid and available*/
                if username != "" && password != ""{
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The password doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Clear the value of the password*/
                password = ""
                
                errorShake()
            }
        }
        else if textField == passwordTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            
            /** Clear the value of the password*/
            password = ""
        }
        
        /** Validate the user's first name*/
        if textField == firstNameTextfield && textField.text != ""{
            switch isNameValid(textField.text!){
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard firstName != firstNameTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set this var to the textfield's current value*/
                firstName = textField.text!
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                    
                    /** The state, city, and country are all let constants*/
                    address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                    
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Clear the value*/
                firstName = ""
                
                errorShake()
            }
        }
        else if textField == firstNameTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            
            /** Clear the value*/
            firstName = ""
        }
        
        /** Validate the user's last name*/
        if textField == lastNameTextfield && textField.text != ""{
            switch isNameValid(textField.text!){
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard lastName != lastNameTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set this var to the textfield's current value*/
                lastName = textField.text!
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                    
                    /** The state, city, and country are all let constants*/
                    address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                    
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Clear the value*/
                lastName = ""
                
                errorShake()
            }
        }
        else if textField == lastNameTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            
            /** Clear the value*/
            lastName = ""
        }
        
        /** Validate the user's address 1*/
        if textField == address1Textfield && textField.text != ""{
            switch isAddressValid(textField.text!){
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard address1 != address1Textfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set this var to the textfield's current value*/
                address1 = textField.text!.removeEmptyLastChar()
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                    
                    /** The state, city, and country are all let constants*/
                    address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                    
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                /** Clear the value*/
                address1 = ""
                
                errorShake()
            }
        }
        else if textField == address1Textfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            /** Invalidate the previous address typed (if any)*/
            address = nil
            
            /** Clear the value*/
            address1 = ""
        }
        
        /** Validate the user's address 2*/
        if textField == address2Textfield && textField.text != ""{
            switch isAddressValid(textField.text!){
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard address2 != address2Textfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set this var to the textfield's current value*/
                address2 = textField.text!.removeEmptyLastChar()
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                    
                    /** The state, city, and country are all let constants*/
                    address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                    
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                /** Clear the value*/
                address2 = ""
                
                errorShake()
            }
        }
        else if textField == address2Textfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            /** Invalidate the previous address typed (if any)*/
            address = nil
            
            /** Clear the value*/
            address2 = ""
        }
        
        /** Validate the user's city*/
        if textField == cityTextfield && textField.text != ""{
            switch isCityValid(textField.text!) && textField.text!.removeEmptyLastChar() == "New York"{
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard city != cityTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    
                    /** Enable the continue button if all the required inputs are valid and available*/
                    if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                        
                        /** The state, city, and country are all let constants*/
                        address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                        
                        showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                    }
                    
                    break
                }
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set this var to the textfield's current value*/
                city = textField.text!.removeEmptyLastChar()
                cityTextfield.text = city
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                    
                    /** The state, city, and country are all let constants*/
                    address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                    
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                /** Reset the value*/
                city = "New York"
                cityTextfield.text = city
                
                errorShake()
            }
        }
        else if textField == cityTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            /** Invalidate the previous address typed (if any)*/
            address = nil
            
            /** Reset the value*/
            city = "New York"
            cityTextfield.text = city
        }
        
        /** Validate the user's state*/
        if textField == stateTextfield && textField.text != ""{
            switch isStateValid(textField.text!) && states.contains(textField.text!.removeEmptyLastChar()) && textField.text!.removeEmptyLastChar() == "New York"{
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard state != stateTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    
                    /** Enable the continue button if all the required inputs are valid and available*/
                    if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                        
                        /** The state, city, and country are all let constants*/
                        address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                        
                        showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                    }
                    
                    break
                }
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set this var to the textfield's current value*/
                state = textField.text!.removeEmptyLastChar()
                stateTextfield.text = state
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                    
                    /** The state, city, and country are all let constants*/
                    address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                    
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required REGEX criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                /** Reset the value*/
                state = "New York"
                stateTextfield.text = state
                
                errorShake()
            }
        }
        else if textField == stateTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            /** Invalidate the previous address typed (if any)*/
            address = nil
            
            /** Reset the value*/
            state = "New York"
            stateTextfield.text = state
        }
        
        /** Validate the user's borough*/
        if textField == boroughTextfield && textField.text != ""{
            switch boroughs.contains(textField.text!.removeEmptyLastChar()) && textField.text!.removeEmptyLastChar() == "Brooklyn"{
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard borough!.rawValue != boroughTextfield.text!.removeEmptyLastChar() else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    
                    /** Enable the continue button if all the required inputs are valid and available*/
                    if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                        
                        /** The state, city, and country are all let constants*/
                        address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                        
                        showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                    }
                    
                    break
                }
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set this var to the textfield's current value*/
                borough = .Brookyln
                boroughTextfield.text = borough!.rawValue
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                    
                    /** The state, city, and country are all let constants*/
                    address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                    
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                /** Reset the value*/
                borough = .Brookyln
                boroughTextfield.text = borough!.rawValue
                
                errorShake()
            }
        }
        else if textField == boroughTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            /** Invalidate the previous address typed (if any)*/
            address = nil
            
            /** Clear the value*/
            borough = .Brookyln
            boroughTextfield.text = borough!.rawValue
        }
        
        /** Validate the user's zipcode*/
        if textField == zipCodeTextfield && textField.text != ""{
            switch getBoroughFor(this: Int(zipCodeTextfield.text!) ?? 0) == Borough.Brookyln{
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard zipCode?.description != zipCodeTextfield.text else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                
                /** Set this var to the textfield's current value*/
                zipCode = UInt(textField.text!)
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if firstName != "" && lastName != "" && address1 != "" && city != "" && borough != nil && state != "" && zipCode != nil{
                    
                    /** The state, city, and country are all let constants*/
                    address = Address(borough: self.borough!, zipCode: UInt(zipCode!), alias: "Home", streetAddress1: address1, streetAddress2: address2, specialInstructions: "", addressType: .home)
                    
                    showContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
                /** Invalidate the previous address typed (if any)*/
                address = nil
                
                /** Clear the value*/
                zipCode = nil
                zipCodeTextfield.text = ""
                
                errorShake()
            }
        }
        else if textField == zipCodeTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the continue button until it's filled in with a valid input*/
            showDisabledContinueButton(animated: true, at: CGPoint(x: 10, y: view.frame.height * 0.8 - continueButton.frame.height))
            /** Invalidate the previous address typed (if any)*/
            address = nil
            
            /** Clear the value*/
            zipCode = nil
        }
        
        /** Validate the user's DOB*/
        if textField == DOBTextfield && textField.text != ""{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/YYYY"
            
            switch dateFormatter.date(from: textField.text!) != nil{
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard DOB != dateFormatter.date(from: textField.text!) else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    createAccountButton.alpha = 0
                    createAccountButton.isEnabled = false
                }
                
                /** Set this var to the textfield's current value*/
                DOB = DOBPickerView.date
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if DOB != nil && gender != "" && customerPathSelected == false{
                    
                    UIView.animate(withDuration: 0.5, delay: 0){[self] in
                        createAccountButton.alpha = 1
                        createAccountButton.isEnabled = true
                    }
                }
                else if customerPathSelected == true{
                    
                    UIView.animate(withDuration: 0.5, delay: 0){[self] in
                        createAccountButton.alpha = 1
                        createAccountButton.isEnabled = true
                    }
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    createAccountButton.alpha = 0
                    createAccountButton.isEnabled = false
                }
                
                /** Enable the continue button regardless for customers*/
                if customerPathSelected == true{
                    
                    UIView.animate(withDuration: 0.5, delay: 0){[self] in
                        createAccountButton.alpha = 1
                        createAccountButton.isEnabled = true
                    }
                }
                
                /** Clear the value*/
                DOB = nil
                DOBTextfield.text = ""
                
                errorShake()
            }
        }
        else if textField == DOBTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the create account button until it's filled in with a valid input*/
            
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                createAccountButton.alpha = 0
                createAccountButton.isEnabled = false
            }
            
            /** Enable the continue button regardless for customers*/
            if customerPathSelected == true{
                
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    createAccountButton.alpha = 1
                    createAccountButton.isEnabled = true
                }
            }
            
            /** Clear the value*/
            DOB = nil
        }
        
        /** Validate the user's gender*/
        if textField == genderTextfield && textField.text != ""{
            switch genders.contains(textField.text!){
            case true:
                /** If the input hasn't changed then don't verify it*/
                guard gender != textField.text! else {
                    markTextFieldEntryAsCorrect(textField: textField)
                    break
                }
                
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    createAccountButton.alpha = 0
                    createAccountButton.isEnabled = false
                }
                
                /** Set this var to the textfield's current value*/
                gender = textField.text!
                
                reflectGenderInChosenPathImageView()
                
                markTextFieldEntryAsCorrect(textField: textField)
                
                /** Enable the continue button if all the required inputs are valid and available*/
                if DOB != nil && gender != "" && customerPathSelected == false{
                    
                    UIView.animate(withDuration: 0.5, delay: 0){[self] in
                        createAccountButton.alpha = 1
                        createAccountButton.isEnabled = true
                    }
                }
                else if customerPathSelected == true{
                    
                    UIView.animate(withDuration: 0.5, delay: 0){[self] in
                        createAccountButton.alpha = 1
                        createAccountButton.isEnabled = true
                    }
                }
                
                successfulActionShake()
            case false:
                /** The input doesn't meet the required criteria*/
                markTextFieldEntryAsIncorrect(textField: textField)
                
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    createAccountButton.alpha = 0
                    createAccountButton.isEnabled = false
                }
                
                /** Enable the continue button regardless for customers*/
                if customerPathSelected == true{
                    
                    UIView.animate(withDuration: 0.5, delay: 0){[self] in
                        createAccountButton.alpha = 1
                        createAccountButton.isEnabled = true
                    }
                }
                
                /** Reset the value*/
                gender = genders[2]
                genderTextfield.text = genders[2]
                genderPickerView.selectRow(2, inComponent: 0, animated: false)
                
                errorShake()
            }
        }
        else if textField == genderTextfield && textField.text == ""{
            /** The textfield shouldn't be empty so disable the create account button until it's filled in with a valid input*/
            
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                createAccountButton.alpha = 0
                createAccountButton.isEnabled = false
            }
            
            /** Enable the continue button regardless for customers*/
            if customerPathSelected == true{
                
                UIView.animate(withDuration: 0.5, delay: 0){[self] in
                    createAccountButton.alpha = 1
                    createAccountButton.isEnabled = true
                }
            }
            
            /** Reset the value*/
            gender = genders[2]
            genderTextfield.text = genders[2]
            genderPickerView.selectRow(2, inComponent: 0, animated: false)
            
            reflectGenderInChosenPathImageView()
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
    
    /** Make the background of the context menu origin view clear instead of black*/
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?{
        let previewTarget = UIPreviewTarget(container: self.view, center: interaction.view!.center)
        let previewParams = UIPreviewParameters()
        previewParams.backgroundColor = .clear
        
        return UITargetedPreview(view: interaction.view!, parameters: previewParams, target: previewTarget)
    }
    
    /** Context menu for this object that allows a user to copy the contents of the spreadsheet*/
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        var children: [UIMenuElement] = []
        
        for option in backButtonOptions{
            switch option{
            case "Introduction":
                let backToIntroduction = UIAction(title: "Introduction", image: UIImage(systemName: "1.circle.fill")){ [self] action in
                    backwardTraversalShake()
                    
                    moveToThis(slide: 0)
                }
                children.append(backToIntroduction)
            case "Email":
                let backToIntroduction = UIAction(title: "Email", image: UIImage(systemName: "2.circle.fill")){ [self] action in
                    backwardTraversalShake()
                    
                    moveToThis(slide: 1)
                }
                children.append(backToIntroduction)
            case "Username":
                let backToIntroduction = UIAction(title: "Username", image: UIImage(systemName: "3.circle.fill")){ [self] action in
                    backwardTraversalShake()
                    
                    moveToThis(slide: 2)
                }
                children.append(backToIntroduction)
            case "Name":
                let backToIntroduction = UIAction(title: "Name", image: UIImage(systemName: "4.circle.fill")){ [self] action in
                    backwardTraversalShake()
                    
                    moveToThis(slide: 3)
                }
                children.append(backToIntroduction)
            case "DOB":
                let backToIntroduction = UIAction(title: "DOB & Gender", image: UIImage(systemName: "5.circle.fill")){ [self] action in
                    backwardTraversalShake()
                    
                    moveToThis(slide: 4)
                }
                children.append(backToIntroduction)
            default:
                break
            }
        }
        
        let dismiss = UIAction(title: "Dismiss", image: UIImage(systemName: "backward.fill")){ [self] action in
            backwardTraversalShake()
            
            if onboardingVCPresenting == true{
                onboardingVC!.displayStartScreen()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){ [self] in
                    onboardingVC!.setStartMenuPosition()
                }
            }
            
            self.dismiss(animated: true, completion: nil)
            purgeTemporaryUsersOnDismiss()
        }
        
        let slideOptions = UIMenu(title: "Slides", image: UIImage(systemName: "person.crop.rectangle.stack.fill"), children: children)
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil){ _ in
            UIMenu(title: "Navigation Options", children: [dismiss, slideOptions])
        }
    }
    
    /** Picker view delegate methods*/
    /** Describes how many sections (components) there are to the picker view*/
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /** Enumerates the number of rows for the target component*/
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var count = 0
        if pickerView == boroughPickerView{
            count = boroughs.count
        }
        if pickerView == cityPickerView{
            count = NYCities.count
        }
        if pickerView == statePickerView{
            count = states.count
        }
        if pickerView == zipCodePickerView{
            count = nycZipCodes.count
        }
        if pickerView == genderPickerView{
            count = genders.count
        }
        
        return count
    }
    
    /** Data source: Provides the title string data to insert into the row at the given index*/
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title = ""
        if pickerView == boroughPickerView{
            title = boroughs[row]
        }
        if pickerView == cityPickerView{
            title = NYCities[row]
        }
        if pickerView == statePickerView{
            title = states[row]
        }
        if pickerView == zipCodePickerView{
            title = nycZipCodes[row].key.description
        }
        if pickerView == genderPickerView{
            title = genders[row]
        }
        
        return title
    }
    
    /** Provides an attributed string for the row's label*/
    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var attributedString = NSAttributedString(string: "", attributes: [.foregroundColor: appThemeColor, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
        
        if pickerView == boroughPickerView{
            attributedString = NSAttributedString(string: boroughs[row], attributes: [.foregroundColor: appThemeColor, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            
            /** Service only available in Brooklyn for now, grey out all the other options*/
            if boroughs[row] != boroughs[0]{
                attributedString = NSAttributedString(string: boroughs[row], attributes: [.foregroundColor: UIColor.lightGray, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            }
        }
        
        if pickerView == cityPickerView{
            attributedString = NSAttributedString(string: NYCities[row], attributes: [.foregroundColor: appThemeColor, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            
            /** Service only available in NY, grey out all the other options*/
            if NYCities[row] != NYCities[0]{
                attributedString = NSAttributedString(string: NYCities[row], attributes: [.foregroundColor: UIColor.lightGray, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            }
        }
        
        if pickerView == statePickerView{
            attributedString = NSAttributedString(string: states[row], attributes: [.foregroundColor: appThemeColor, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            
            /** Service only available in NYS, grey out all the other options*/
            if states[row] != states[0]{
                attributedString = NSAttributedString(string: states[row], attributes: [.foregroundColor: UIColor.lightGray, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            }
        }
        
        if pickerView == zipCodePickerView{
            attributedString = NSAttributedString(string: nycZipCodes[row].key.description, attributes: [.foregroundColor: appThemeColor, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            
            /** Service only available in Brooklyn for now, grey out all the other options*/
            if getBoroughFor(this: nycZipCodes[row].key)!.rawValue != Borough.Brookyln.rawValue{
                attributedString = NSAttributedString(string: nycZipCodes[row].key.description, attributes: [.foregroundColor: UIColor.lightGray, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            }
        }
        if pickerView == genderPickerView{
            /** Highlight only the selected choice*/
            if pickerView.selectedRow(inComponent: 0) == row{
                attributedString = NSAttributedString(string: genders[row], attributes: [.foregroundColor: appThemeColor, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            }
            else{
                attributedString = NSAttributedString(string: genders[row], attributes: [.foregroundColor: UIColor.lightGray, .font: getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)])
            }
        }
        
        return attributedString
    }
    
    /** Called when user selects a specific row*/
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        if pickerView == boroughPickerView{
            boroughTextfield.text = boroughs[row]
            
            /** Service only available in Brooklyn for now*/
            if boroughs[row] != boroughs[0]{
                globallyTransmit(this: "Sorry, our services are only available in Brooklyn for now", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .none, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                
                boroughTextfield.text = boroughs[0]
                pickerView.selectRow(0, inComponent: 0, animated: true)
            }
        }
        
        if pickerView == cityPickerView{
            cityTextfield.text = NYCities[0]
            
            /** Service only available in New York City*/
            if NYCities[row] != NYCities[0]{
                globallyTransmit(this: "Sorry, our services are only available in New York City", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .none, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                
                cityTextfield.text = NYCities[0]
                pickerView.selectRow(0, inComponent: 0, animated: true)
            }
        }
        
        if pickerView == statePickerView{
            stateTextfield.text = states[0]
            
            /** Service only available in New York State*/
            if states[row] != states[0]{
                globallyTransmit(this: "Sorry, our services are only available in New York State", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .none, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                
                stateTextfield.text = states[0]
                pickerView.selectRow(0, inComponent: 0, animated: true)
            }
        }
        
        if pickerView == zipCodePickerView{
            zipCodeTextfield.text = nycZipCodes[row].key.description
            
            /** Service only available in Brooklyn, if this zipcode isn't in Brooklyn then reject it*/
            if getBoroughFor(this: nycZipCodes[row].key)!.rawValue != Borough.Brookyln.rawValue{
                globallyTransmit(this: "Sorry, our services are only available in Brooklyn for now", with: UIImage(systemName: "tshirt.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .none, blurEffect: true, accentColor: appThemeColor, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                
                zipCodeTextfield.text = ""
                pickerView.selectRow(0, inComponent: 0, animated: true)
            }
        }
        
        if pickerView == genderPickerView{
            /** Refresh to change the color of the currently selected row in order to visually highlight the fact that it's now selected*/
            pickerView.reloadAllComponents()
            
            genderTextfield.text = genders[row]
        }
    }
    /** Picker View delegate methods*/
    
    /** Image picker delegate methods*/
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        
        /** Ensure that the given image is valid and not too large*/
        let imageData = image.jpegData(compressionQuality: 0)
        guard imageData != nil else {
            /** Given image is invalid, use another image!*/
            globallyTransmit(this: "That image is can't be used right now, please try again or select another one to use", with: UIImage(systemName: "photo.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            
            picker.dismiss(animated: true, completion: nil)
            
            return
        }
        
        /** Image must be less than 2 megabyte aka 2 million bytes*/
        guard imageData!.count <= 2000000 else {
            /** The given image is too large, choose another image!*/
            globallyTransmit(this: "That image is too large, choose another one or even take one right now. The maximum file size is 2MB", with: UIImage(systemName: "photo.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .none, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
            
            picker.dismiss(animated: true, completion: nil)
            
            return
        }
        /** Image is valid therefore use it*/
        profilePicture = image
        profilePictureImageView.image = image
        
        /** Change the plus to a minus to inform the user that they can remove the image*/
        profilePictureSelectionButton.setImage(UIImage(systemName: "minus", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), for: .normal)
        
        swapChosenPathImageViewPhoto(with: profilePicture!, animated: true)
        markImageViewAsCorrect(imageView: profilePictureImageView)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    /** Change the border of the image view for the profile picture to green to indicate it has been filled properly*/
    func markImageViewAsCorrect(imageView: UIImageView){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            imageView.layer.borderColor = UIColor.green.cgColor
            imageView.layer.borderWidth = 1
        }
    }
    
    /** Change the border of the image view for the profile picture to red to indicate it hasn't been filled properly*/
    func markImageViewAsIncorrect(imageView: UIImageView){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            imageView.layer.borderColor = UIColor.red.cgColor
            imageView.layer.borderWidth = 1
        }
    }
    
    /** Restores the border of the imageview to its original styling*/
    func restoreOriginalImageViewStyling(imageView: UIImageView, borderColor: UIColor, borderWidth: CGFloat){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){
            imageView.layer.borderColor = borderColor.cgColor
            imageView.layer.borderWidth = borderWidth
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    /** Image picker delegate methods*/
    
    /** Country code picker delegate methods*/
    public func countryCodePickerViewControllerDidPickCountry(_ country: CountryCodePickerViewController.Country) {
        ///print("User picked \(country)")
    }
    /** Country code picker delegate methods*/
    
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
    
    /** Third-party sign up/ sign-in methods*/
    /** Facebook Login Delegate method*/
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
        
        /** If a current user already exists then simply link the credential with that user instead of signing in*/
        if let user = Auth.auth().currentUser, Auth.auth().currentUser != nil{
            user.link(with: credential, completion: {[self] (authResult, error) in
                if (error != nil) {
                    /// Error. If error.code == .MissingOrInvalidNonce, make sure
                    /// you're sending the SHA256-hashed nonce as a hex string with
                    
                    globallyTransmit(this: "Uh-oh, something went wrong, please try again. You might've already linked that account previously", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    
                    /** Log the user out of the facebook auth*/
                    let manager = LoginManager()
                    manager.logOut()
                    
                    print(error!.localizedDescription)
                    return
                }
                
                /**User is signed in to Firebase with Facebook.*/
                faceBookSignInButton.isEnabled = false
                UIView.animate(withDuration: 0.25, delay: 0){[self] in
                    faceBookSignInButton.alpha = 0
                }
                
                /** Move the other buttons down the line when one goes away*/
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                    appleSignInButton.frame.origin = googleSignInButton.frame.origin
                    googleSignInButton.frame.origin = faceBookSignInButton.frame.origin
                    
                    /** Last button is now in the first position*/
                    if googleSignInButton.isEnabled == false{
                    appleSignInButton.frame.origin = faceBookSignInButton.frame.origin
                    }
                }
                
                /** If all three third party auth methods were used then remove the label*/
                if appleSignInButton.isEnabled == false && faceBookSignInButton.isEnabled == false && googleSignInButton.isEnabled == false{
                    
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                        signUpWithThirdPartyLabel.transform = CGAffineTransform(translationX: signUpWithThirdPartyLabel.frame.width, y: 0)
                    }
                    
                    UIView.animate(withDuration: 0.5, delay: 0.5){[self] in
                        signUpWithThirdPartyLabel.alpha = 0
                    }
                }
                
                /** Specify the Facebook Auth credential to link to the main login after the user creates an account*/
                tempFacebookAuthCredential = credential
                
                /** Log the user out of the facebook auth*/
                let manager = LoginManager()
                manager.logOut()
            })
        }
        else{
            /**Sign in with Firebase*/
            Auth.auth().signIn(with: credential) { [self] (authResult, error) in
                if (error != nil) {
                    /// Error. If error.code == .MissingOrInvalidNonce, make sure
                    /// you're sending the SHA256-hashed nonce as a hex string with
                    
                    globallyTransmit(this: "Uh-oh, something went wrong, please try again. You might've already linked that account previously", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                    
                    /** Log the user out of the facebook auth*/
                    let manager = LoginManager()
                    manager.logOut()
                    
                    print(error!.localizedDescription)
                    return
                }
                
                /**User is signed in to Firebase with Facebook.*/
                faceBookSignInButton.isEnabled = false
                UIView.animate(withDuration: 0.25, delay: 0){[self] in
                    faceBookSignInButton.alpha = 0
                }
                
                /** Move the other buttons down the line when one goes away*/
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                    appleSignInButton.frame.origin = googleSignInButton.frame.origin
                    googleSignInButton.frame.origin = faceBookSignInButton.frame.origin
                    
                    /** Last button is now in the first position*/
                    if googleSignInButton.isEnabled == false{
                    appleSignInButton.frame.origin = faceBookSignInButton.frame.origin
                    }
                }
                
                /** If all three third party auth methods were used then remove the label*/
                if appleSignInButton.isEnabled == false && faceBookSignInButton.isEnabled == false && googleSignInButton.isEnabled == false{
                    
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                        signUpWithThirdPartyLabel.transform = CGAffineTransform(translationX: signUpWithThirdPartyLabel.frame.width, y: 0)
                    }
                    
                    UIView.animate(withDuration: 0.5, delay: 0.5){[self] in
                        signUpWithThirdPartyLabel.alpha = 0
                    }
                }
                
                /** Specify the Facebook Auth credential to link to the main login after the user creates an account*/
                tempFacebookAuthCredential = credential
                
                /** Log the user out of the facebook auth*/
                let manager = LoginManager()
                manager.logOut()
            }
        }
    }
    
    public func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        /** User logged out of facebook*/
    }
    /** Facebook Login Delegate method*/
    
    /** Google Auth sign in flow*/
    func startSignInWithGoogleFlow(){
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
            
            /** If a current user already exists then simply link the credential with that user instead of signing in*/
            if let user = Auth.auth().currentUser, Auth.auth().currentUser != nil{
                user.link(with: credential, completion: { [self] (authResult, error) in
                    if (error != nil) {
                        globallyTransmit(this: "Uh-oh, something went wrong, please try again. You might've already linked that account previously", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        
                        print(error!.localizedDescription)
                        return
                    }
                    /**User is signed in to Firebase with Google.*/
                    googleSignInButton.isEnabled = false
                    UIView.animate(withDuration: 0.25, delay: 0){[self] in
                        googleSignInButton.alpha = 0
                    }
                    
                    /** Move the other buttons down the line when one goes away*/
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                        appleSignInButton.frame.origin = googleSignInButton.frame.origin
                    }
                    
                    /** If all three third party auth methods were used then remove the label*/
                    if appleSignInButton.isEnabled == false && faceBookSignInButton.isEnabled == false && googleSignInButton.isEnabled == false{
                        
                        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                            signUpWithThirdPartyLabel.transform = CGAffineTransform(translationX: signUpWithThirdPartyLabel.frame.width, y: 0)
                        }
                        
                        UIView.animate(withDuration: 0.5, delay: 0.5){[self] in
                            signUpWithThirdPartyLabel.alpha = 0
                        }
                    }
                    
                    tempGoogleAuthCredential = credential
                })
            }
            else{
                /**Sign in with Firebase*/
                Auth.auth().signIn(with: credential){ [self] (authResult, error) in
                    if (error != nil) {
                        globallyTransmit(this: "Uh-oh, something went wrong, please try again. You might've already linked that account previously", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        
                        print(error!.localizedDescription)
                        return
                    }
                    /**User is signed in to Firebase with Google.*/
                    googleSignInButton.isEnabled = false
                    UIView.animate(withDuration: 0.25, delay: 0){[self] in
                        googleSignInButton.alpha = 0
                    }
                    
                    /** Move the other buttons down the line when one goes away*/
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                        appleSignInButton.frame.origin = googleSignInButton.frame.origin
                    }
                    
                    /** If all three third party auth methods were used then remove the label*/
                    if appleSignInButton.isEnabled == false && faceBookSignInButton.isEnabled == false && googleSignInButton.isEnabled == false{
                        
                        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                            signUpWithThirdPartyLabel.transform = CGAffineTransform(translationX: signUpWithThirdPartyLabel.frame.width, y: 0)
                        }
                        
                        UIView.animate(withDuration: 0.5, delay: 0.5){[self] in
                            signUpWithThirdPartyLabel.alpha = 0
                        }
                    }
                    
                    tempGoogleAuthCredential = credential
                }
            }
        }
    }
    /** Google Auth sign in flow*/
    
    /** Start the sign in flow for Apple Auth*/
    @available(iOS 13, *)
    func startSignInWithAppleFlow(){
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
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor(frame: UIScreen.main.bounds)
    }
    /** Third-party sign up/ sign-in methods*/
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.0, *)
extension SignUpVC: ASAuthorizationControllerDelegate {
    
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
            
            /** If a current user already exists then simply link the credential with that user instead of signing in*/
            if let user = Auth.auth().currentUser, Auth.auth().currentUser != nil{
                user.link(with: credential, completion: { [self] (authResult, error) in
                    if (error != nil) {
                        /// Error. If error.code == .MissingOrInvalidNonce, make sure
                        /// you're sending the SHA256-hashed nonce as a hex string with
                        /// your request to Apple.
                        
                        globallyTransmit(this: "Uh-oh, something went wrong, please try again. You might've already linked that account previously", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        
                        print(error!.localizedDescription)
                        return
                    }
                    
                    /**User is signed in to Firebase with Apple.*/
                    appleSignInButton.isEnabled = false
                    UIView.animate(withDuration: 0.25, delay: 0){[self] in
                        appleSignInButton.alpha = 0
                    }
                    
                    /** If all three third party auth methods were used then remove the label*/
                    if appleSignInButton.isEnabled == false && faceBookSignInButton.isEnabled == false && googleSignInButton.isEnabled == false{
                        
                        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                            signUpWithThirdPartyLabel.transform = CGAffineTransform(translationX: signUpWithThirdPartyLabel.frame.width, y: 0)
                        }
                        
                        UIView.animate(withDuration: 0.5, delay: 0.5){[self] in
                            signUpWithThirdPartyLabel.alpha = 0
                        }
                    }
                    
                    tempAppleAuthCredential = credential
                })
            }
            else{
                /**Sign in with Firebase*/
                Auth.auth().signIn(with: credential) { [self] (authResult, error) in
                    if (error != nil) {
                        /// Error. If error.code == .MissingOrInvalidNonce, make sure
                        /// you're sending the SHA256-hashed nonce as a hex string with
                        /// your request to Apple.
                        
                        globallyTransmit(this: "Uh-oh, something went wrong, please try again. You might've already linked that account previously", with: UIImage(systemName: "checkmark.circle.trianglebadge.exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight: .light)), backgroundColor: bgColor, imageBackgroundColor: UIColor.clear, imageBorder: .borderlessSquircle, blurEffect: true, accentColor: .red, fontColor: fontColor, font: getCustomFont(name: .Ubuntu_Light, size: 14, dynamicSize: true), using: .centerStrip, animated: true, duration: 4, selfDismiss: true)
                        
                        print(error!.localizedDescription)
                        return
                    }
                    
                    /**User is signed in to Firebase with Apple.*/
                    appleSignInButton.isEnabled = false
                    UIView.animate(withDuration: 0.25, delay: 0){[self] in
                        appleSignInButton.alpha = 0
                    }
                    
                    /** If all three third party auth methods were used then remove the label*/
                    if appleSignInButton.isEnabled == false && faceBookSignInButton.isEnabled == false && googleSignInButton.isEnabled == false{
                        
                        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
                            signUpWithThirdPartyLabel.transform = CGAffineTransform(translationX: signUpWithThirdPartyLabel.frame.width, y: 0)
                        }
                        
                        UIView.animate(withDuration: 0.5, delay: 0.5){[self] in
                            signUpWithThirdPartyLabel.alpha = 0
                        }
                    }
                    
                    tempAppleAuthCredential = credential
                }
            }
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error){
        
        /**Handle error*/
        print("Sign in with Apple errored: \(error)")
    }
    
}

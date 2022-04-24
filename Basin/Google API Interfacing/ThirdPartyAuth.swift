//
//  ThirdPartyAuth.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/8/22.
//

import Foundation
import CryptoKit
import UIKit
import AuthenticationServices
import Firebase

/** Various methods for sign up and sign in with third party authentication providers such as Apple, Google, and Facebook*/

/** For every sign-in request, generate a random string—a "nonce"—which you will use to make sure the ID token you get was granted specifically in response to your app's authentication request. This step is important to prevent replay attacks. A nonce is cryptographically generated with SecRandomCopyBytes*/
/// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
public func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

/** A SHA256 hash of the nonce with the sign-in request will be sent, which Apple will pass unchanged in the response. Firebase validates the response by hashing the original nonce and comparing it to the value passed by Apple.*/
@available(iOS 13, *)
public func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

/**Unhashed nonce*/
var currentNonce: String?

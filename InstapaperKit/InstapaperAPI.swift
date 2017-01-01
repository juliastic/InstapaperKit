//
//  Instapaper.swift
//  Demo
//
//  Created by Julia Grill on 29/12/2016.
//  Copyright © 2016 Marcel Voss. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

/// Possible response errors from Instapaper's servers
public enum ResponseError: Error {
    /// Invalid account information
    case ConnectionInvalid
    case ConnectionTimedOut
    case ConnectionFailed
    case SavingFailed
    case NotSignedIn
    case AlreadySignedIn
}

class InstapaperAPI: NSObject {
    static private let instapaperURL = URL(string: "https://www.instapaper.com/api/")
    static private let authenticate = "authenticate"
    static private let bookmarksURI = "/1/bookmarks"
    static private let add = "add"
    
    private var password: String? {
        get {
            return KeychainWrapper.standard.string(forKey: "password")
        } set {
            if let newPassword = newValue {
                KeychainWrapper.standard.set(newPassword, forKey: "password")
            }
        }
    }
    
    class func logIn(_ user: String, withPassword password: String, closure: @escaping (_ authorized: Bool, _ error: Error?) -> Void) {
        if KeychainWrapper.standard.string(forKey: "username") == nil {
            let parameters = ["username": user.trimmingCharacters(in: .whitespacesAndNewlines), "password": password.trimmingCharacters(in: .whitespacesAndNewlines)]
            Networking.GET(url: instapaperURL?.appendingPathComponent(authenticate), parameters: parameters) { (error, result, response) in
                if let response = response {
                    switch response.statusCode {
                    case 200:
                        if error == nil {
                            let usernameSaveSuccesful = KeychainWrapper.standard.set(user, forKey: "username")
                            let passwordSaveSuccesful = KeychainWrapper.standard.set(password, forKey: "password")
                            if !usernameSaveSuccesful || !passwordSaveSuccesful {
                                closure(true, ResponseError.SavingFailed)
                            } else {
                                closure(true, nil)
                            }
                        }
                        break
                    case 403:
                        closure(false, ResponseError.ConnectionInvalid)
                        break
                    default:
                        closure(false, ResponseError.ConnectionTimedOut)
                    }
                } else {
                    closure(false, ResponseError.ConnectionFailed)
                }
            }
        } else {
            closure(false, ResponseError.AlreadySignedIn)
        }
    }
    
    class func add(_ url: URL, withTitle title: String?, selection: String?, closure: @escaping (_ sent: Bool, _ error: Error?) -> Void) {
        if let retrievedUsername = KeychainWrapper.standard.string(forKey: "username"), let retrievedPassword = KeychainWrapper.standard.string(forKey: "password") {
            let parameters = ["username": retrievedUsername, "password": retrievedPassword, "url": url.absoluteString, "title": title ?? "", "selection": selection ?? ""] as [String : String]
            Networking.POST(url: instapaperURL?.appendingPathComponent(bookmarksURI + add), parameters: parameters) { (error, result, response) in
                if let response = response {
                    switch response.statusCode {
                    case 201:
                        closure(true, nil)
                        break
                    case 400, 403:
                        closure(false, ResponseError.ConnectionInvalid)
                        break
                    default:
                        closure(false, ResponseError.ConnectionFailed)
                    }
                }
            }
        } else {
            closure(false, ResponseError.NotSignedIn)
        }
    }
    
}

//
//  Instapaper.swift
//  Demo
//
//  Created by Julia Grill on 29/12/2016.
//  Copyright © 2016 Marcel Voss. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

enum ResponseError: Error {
    case ConnectionInvalid
    case ConnectionTimedOut
    case ConnectionFailed
    case SavingFailed
    case NotSignedIn
}

class InstapaperAPI: NSObject {
    static let instapaperURL = URL(string: "http://www.instapaper.com/api/")
    static let authenticate = "authenticate"
    static let bookmarksURI = "/1/bookmarks"
    static let add = "add"
    
    class func logIn(_ user: String, withPassword password: String, closure: @escaping (_ authorized: Bool, _ error: Error?) -> Void) {
        if KeychainWrapper.standard.string(forKey: "user") == nil {
            let parameters = ["username": user.trimmingCharacters(in: .whitespacesAndNewlines), "password": password.trimmingCharacters(in: .whitespacesAndNewlines)]
            Networking.GET(url: instapaperURL?.appendingPathComponent(authenticate), parameters: parameters) { (error, result, response) in
                if let response = response {
                    switch response.statusCode {
                    case 200, 201, 202:
                        if error == nil {
                            let usernameSaveSuccesful = KeychainWrapper.standard.set(user, forKey: "user")
                            let passwordSaveSuccesful = KeychainWrapper.standard.set(password, forKey: "password")
                            if !usernameSaveSuccesful || !passwordSaveSuccesful {
                                closure(true, ResponseError.SavingFailed)
                            } else {
                                closure(true, nil)
                            }
                        }
                    case 408:
                        closure(false, ResponseError.ConnectionTimedOut)
                        break
                    default:
                        closure(false, ResponseError.ConnectionInvalid)
                    }
                }
            }
        }
    }
    
    class func add(_ url: URL, withTitle title: String?, description: String?, resolve_final_url: Int?, closure: @escaping (_ sent: Bool, _ error: Error?) -> Void) {
        if let retrievedUsername = KeychainWrapper.standard.string(forKey: "user"), let retrievedPassword = KeychainWrapper.standard.string(forKey: "password") {
            let parameters = ["username": retrievedUsername, "password": retrievedPassword, "url": url.absoluteString, "title": title ?? "", "description": description ?? "", "folder_id": "unread", "resolve_final_url": "\(resolve_final_url)"] as [String : String]
            Networking.POST(url: instapaperURL?.appendingPathComponent(bookmarksURI + add), parameters: parameters) { (error, result, response) in
                if let response = response {
                    switch response.statusCode {
                    case 200, 201, 202:
                        closure(true, nil)
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

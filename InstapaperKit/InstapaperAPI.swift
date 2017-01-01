//
//  Instapaper.swift
//  Demo
//
//  Created by Julia Grill on 29/12/2016.
//  Copyright © 2016 Marcel Voss. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import ReachabilitySwift


/// Possible response errors from Instapaper's servers
/// This enum provides custom errors when connecting with Instapaper's servers
///
/// - ConnectionInvalid: Invalid account information
/// - ConnectionTimedOut: Connection to Instapaper's servers timed out
/// - ConnectionFailed: Connection to Instapper's servers failed
/// - NotSignedIn: Not yet signed in
/// - AlreadySignedIn: Already signed in
public enum ResponseError: Error {
    /// Invalid account information
    case ConnectionInvalid
    case ConnectionTimedOut
    case ConnectionFailed
    case NotSignedIn
    case AlreadySignedIn
}

class InstapaperAPI: NSObject {
    static private let defaults = UserDefaults.standard
    
    static private let instapaperURL = "https://www.instapaper.com"
    static private let queuedURLsKey = "queuedURLs"
    static private var queuedURLs = [URLInfo]()
    private typealias URLInfo = (URL, String, String)

    static private let instapaperAPIURL = URL(string: "https://www.instapaper.com/api/")
    static private let authenticate = "authenticate"
    static private let add = "add"
    
    static private var username: String?
    static private var password: String? {
        get {
            return KeychainWrapper.standard.string(forKey: "password")
        } set {
            if let newPassword = newValue {
                KeychainWrapper.standard.set(newPassword, forKey: "password")
            }
        }
    }
    
    class func logIn(_ username: String, withPassword password: String, closure: @escaping (_ authorized: Bool, _ error: Error?) -> Void) {
        if self.username == nil {
            let parameters = ["username": username.trimmingCharacters(in: .whitespacesAndNewlines), "password": password.trimmingCharacters(in: .whitespacesAndNewlines)]
            Networking.GET(url: instapaperAPIURL?.appendingPathComponent(authenticate), parameters: parameters) { (error, result, response) in
                if let response = response {
                    switch response.statusCode {
                    case 200:
                        self.username = username
                        self.password = password
                        closure(true, nil)
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
        if let username = self.username {
            let parameters = ["username": username, "password": password ?? "", "url": url.absoluteString, "title": title ?? "", "selection": selection ?? ""] as [String : String]
            if !(Reachability.init(hostname: instapaperURL)?.isReachable)! {
                if (defaults.object(forKey: queuedURLsKey) != nil) && queuedURLs.isEmpty {
                    if let queuedURLs = defaults.array(forKey: queuedURLsKey) as? [InstapaperAPI.URLInfo] {
                        self.queuedURLs = queuedURLs
                    }
                }
                let info = (url, title ?? "", selection ?? "")
                queueURLInfo(info)
                closure(false, ResponseError.ConnectionFailed)
                return
            } else if let queuedURLs = defaults.array(forKey: queuedURLsKey) as? [InstapaperAPI.URLInfo] {
                if queuedURLs.count > 0 {
                    addQueudedLinksToInstapaper()
                }
            }
            
            Networking.POST(url: instapaperAPIURL?.appendingPathComponent(add), parameters: parameters) { (error, result, response) in
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
    
    private class func queueURLInfo(_ info: URLInfo) {
        if !queuedURLs.contains(where: { info == $0 }) {
            queuedURLs.append(info)
            let data = NSKeyedArchiver.archivedData(withRootObject: queuedURLs)
            defaults.set(data, forKey: queuedURLsKey)
            defaults.synchronize()
        }
    }
    
    private class func dequeURL(_ info: URLInfo) {
        queuedURLs = queuedURLs.filter({ info != $0 })
        if queuedURLs.count == 0 {
            defaults.removeObject(forKey: queuedURLsKey)
        } else {
            let data = NSKeyedArchiver.archivedData(withRootObject: queuedURLs)
            defaults.set(data, forKey: queuedURLsKey)
        }
        defaults.synchronize()
    }
    
    private class func addQueudedLinksToInstapaper() {
        for info in queuedURLs {
            add(info.0, withTitle: info.1, selection: info.2, closure: { (successful, error) in
                if successful {
                    dequeURL(info)
                }
            })
        }
    }
    
}

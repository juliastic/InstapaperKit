//
// Instapaper.swift
//
// Copyright (c) 2016 Julia Grill and Marcel Voss
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import UIKit
import SwiftKeychainWrapper
import ReachabilitySwift


/// Possible response errors from Instapaper's servers.
/// This enum provides custom errors when connecting with Instapaper's servers.
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
    private typealias URLInfo = (URL, String, String)

    static private let instapaperURL = "https://www.instapaper.com"
    static private let queuedURLsKey = "queuedURLs"
    static private var queuedURLs = [URLInfo]()
    static private let baseURL = URL(string: "https://www.instapaper.com/api/")
    
    /// Computed property that sets and retrieves usernames from the device's keychain.
    static private var username: String? {
        get {
            return defaults.string(forKey: "kInstapaperUsername")
        } set {
            if let username = newValue {
                defaults.set(username, forKey: "kInstapaperUsername")
            }
            
        }
    }
    
    /// Computed property that sets and retrieves passwords from the device's keychain.
    static private var password: String? {
        get {
            return KeychainWrapper.standard.string(forKey: "password")
        } set {
            if let newPassword = newValue {
                KeychainWrapper.standard.set(newPassword, forKey: "password")
            }
        }
    }
    
    /// Logs user into Instapaper
    ///
    /// - Parameters:
    ///   - username: Username of account
    ///   - password: Password of account, may be empty
    ///   - closure: If succesfully logged in closure's parameters are set to true, nil, if error occured parameters are set to false, ResponseError
    class func logIn(_ username: String, withPassword password: String, closure: @escaping (_ authorized: Bool, _ error: Error?) -> Void) {
        if self.username == nil {
            let parameters = ["username": username.trimmingCharacters(in: .whitespacesAndNewlines), "password": password.trimmingCharacters(in: .whitespacesAndNewlines)]
            Networking.GET(url: baseURL?.appendingPathComponent("authenticate"), parameters: parameters) { (error, result, response) in
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
    
    /// Adds given URL to stored Instapaper account
    ///
    /// - Parameters:
    ///   - url: URL to be added
    ///   - title: Title of URL
    ///   - selection: Selection of URL
    ///   - closure: If succesfully added closure's parameters are set to true, nil, if error occured parameters are set to false, ResponseError
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
                self.queuedURLs = queuedURLs
                if self.queuedURLs.count > 0 {
                    addQueudedLinksToInstapaper()
                }
            }
            
            Networking.POST(url: baseURL?.appendingPathComponent("add"), parameters: parameters) { (error, result, response) in
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
    
    // MARK: - Private
    
    /// Queues a URLInfo object to queuedURLs
    ///
    /// - Parameter info: URLInfo to be added
    private class func queueURLInfo(_ info: URLInfo) {
        if !queuedURLs.contains(where: { info == $0 }) {
            queuedURLs.append(info)
            let data = NSKeyedArchiver.archivedData(withRootObject: queuedURLs)
            defaults.set(data, forKey: queuedURLsKey)
            defaults.synchronize()
        }
    }
    
    /// Deques a URLInfo object from queuedURLs
    ///
    /// - Parameter info: URLInfo to be removed
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
    
    /// Tries to add queuded links to Instapaper
    private class func addQueudedLinksToInstapaper() {
        for info in queuedURLs {
            add(info.0, withTitle: info.1, selection: info.2, closure: { (succesful, error) in
                if succesful {
                    dequeURL(info)
                }
            })
        }
    }
    
}

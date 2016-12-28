//
//  Networking.swift
//  Demo
//
//  Created by Marcel Voß on 28/12/2016.
//  Copyright © 2016 Marcel Voss. All rights reserved.
//

import UIKit

class Networking: NSObject {
    
    class func GET(url: URL?, parameters: [String: String]?, headers: [String: String]? = nil, completionHandler:(Error?, Data?) -> Void) {
        if let bindedURL = url {
            var request = URLRequest(url: bindedURL)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                
            })
        }
    }
    
    class func POST(url: URL?, parameters: [String: String]?, headers: [String: String]? = nil, completionHandler:@escaping (Error?, [String: Any]?, HTTPURLResponse?) -> Void) {
        guard url != nil else {
            completionHandler(nil, nil, nil)
            return
        }
        
        let configuration = URLSessionConfiguration.default
        
        var queryURL = url
        if let parameterDict = parameters {
            queryURL = encode(url: queryURL!, queries: parameterDict)
        }
        
        var request = URLRequest(url: queryURL!)
        request.httpMethod = "POST"
        
        if let headerDictionary = headers {
            for header in headerDictionary {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession(configuration: configuration)
        session.dataTask(with: request) { (data, response, error) in
            let serverResponse = response as? HTTPURLResponse
            
            if let receivedData = data {
                do {
                    let results = try JSONSerialization.jsonObject(with: receivedData, options: []) as? [String: Any]
                    completionHandler(nil, results, serverResponse)
                } catch let error {
                    completionHandler(error, nil, serverResponse)
                }
            }
            completionHandler(error, nil, serverResponse)
            
            }.resume()
    }
    
    class private func encode(url: URL, queries:[String: String]) -> URL? {
        var temporaryQueryItems = [URLQueryItem]()
        for parameter in queries {
            temporaryQueryItems.append(URLQueryItem(name: parameter.key, value: parameter.value))
        }
        
        var compontents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        compontents?.queryItems = temporaryQueryItems
        return compontents?.url
    }

}

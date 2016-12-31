//
//  NewsTableViewController.swift
//  Demo
//
//  Created by Marcel Voß on 30/12/2016.
//  Copyright © 2016 Marcel Voss. All rights reserved.
//

import UIKit

class NewsTableViewController: UITableViewController, XMLParserDelegate, UIGestureRecognizerDelegate {
    
    var articles = [Article]()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let refresher = UIRefreshControl()
    var elementStack = [String]()
    
    var currentElement: String? {
        return elementStack.last
    }
    
    var lastElement: String? {
        let index = elementStack.count - 2
        return elementStack[index]
    }
    
    
    struct Article {
        var title = ""
        var url: URL?
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "News"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log In", style: .plain, target: self, action: #selector(signInPressed))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        refresher.addTarget(self, action: #selector(refreshEntries), for: .valueChanged)
        tableView.refreshControl = refresher
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        longPress.delegate = self
        tableView.addGestureRecognizer(longPress)
        
        refreshEntries()
    }
    
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let point = gestureRecognizer.location(in: tableView)
    
        if let indexPath = tableView.indexPathForRow(at: point) {
            let article = articles[indexPath.row]
            
            if gestureRecognizer.state == .began {
                UIApplication.shared.open(article.url!, options: [:], completionHandler: nil)
            }
        }
    }
    
    func refreshEntries() {
        if let appleURL = URL(string: "http://www.apple.com/pr/feeds/pr.rss") {
            let request = URLRequest(url: appleURL)
            
            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                
                if error == nil && data != nil {
                    let parser = XMLParser(data: data!)
                    parser.delegate = self
                    parser.parse()
                } else {
                    print("Error: \(error?.localizedDescription)")
                }
                
            }).resume()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func signInPressed() {
        // TODO: Add
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        }
        
        let article = articles[indexPath.row]
        print(article)

        
        cell?.detailTextLabel?.text = article.url?.absoluteString
        cell?.textLabel?.text = article.title
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: Add item to Instapaper; if not signed in, ask user to sign in first
        let selectedArticle = articles[indexPath.row]
        
    }
    
    // MARK: - XMLParserDelegate
    
    func parserDidStartDocument(_ parser: XMLParser) {
        DispatchQueue.main.sync {
            activityIndicator.startAnimating()
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        // Add element to elementStack in order to keep track of them
        elementStack.append(elementName)
        
        if elementName == "item" {
            // Add new Article for each item
            articles.append(Article())
        }
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        let decodedData = NSString(data: CDATABlock, encoding: String.Encoding.utf8.rawValue)

        if lastElement == "item" {
            var article = articles.removeLast()
            
            if currentElement == "title" {
                article.title = decodedData as! String
            } else if currentElement == "link" {
                article.url = URL(string: decodedData as! String)
            }
            articles.append(article)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        elementStack.removeLast()
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.sync {
            tableView.reloadData()
            refresher.endRefreshing()
            activityIndicator.stopAnimating()
        }
    }
}

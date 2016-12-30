//
//  NewsTableViewController.swift
//  Demo
//
//  Created by Marcel Voß on 30/12/2016.
//  Copyright © 2016 Marcel Voss. All rights reserved.
//

import UIKit

class NewsTableViewController: UITableViewController, XMLParserDelegate {
    
    var articles = [Article]()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    var currentElement = ""
    let refresher = UIRefreshControl()
    
    var elementStack = [String]()
    
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
        
        refreshEntries()
        
    }
    
    func refreshEntries() {
        if let vergeURL = URL(string: "https://www.theverge.com/rss/index.xml") {
            let request = URLRequest(url: vergeURL)
            
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
        print(article.title)
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
        
        print(elementName)
        
        elementStack.append(elementName)
        
        if elementName == "entry" {
            articles.append(Article())
        }
        
        if elementName == "title" {
            //print(elementName)
        }
        
        currentElement = elementName
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        var article = articles.last
        if articles.count > 0 {
            articles.removeLast()
        }
        
        if currentElement == "title" {
            article?.title = string
            print(article?.title)
            
            //print(string)
            
            
        } else if currentElement == "id" {
            // article?.url = URL(string: string)
        }
        
        if article != nil {
            articles.append(article!)
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "entry" {
            
        }
        
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

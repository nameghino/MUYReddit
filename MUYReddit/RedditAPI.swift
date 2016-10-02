//
//  RedditAPI.swift
//  MUYReddit
//
//  Created by Nicolas Ameghino on 9/6/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import Foundation

public enum MUYRedditError : Error {
    case generic(String)
    case wrapped(Error)
    case cocoa(NSError)
}

struct RedditListingAPIResponse : Resource {
    
    let posts: [RedditPost]
    let continueToken: String
    
    init(container: [String : AnyObject]) {
        do {
            let data: [String : AnyObject] = try "data" <- container
            let children: [[String : AnyObject]] = try "children" <- data

            self.continueToken = try "after" <- data

            self.posts = children.flatMap { item -> RedditPost? in
                guard let itemData: [String : AnyObject] = try? "data" <- item else { return nil }
                return RedditPost(container: itemData)
            }
            
        } catch (let error) {
            fatalError("\(error)")
        }
    }
}

struct RedditPost : Resource {
    let author: String
    let content: Either<String, URL>
    let title: String
    let name: String
    let thumbnailURL: URL?
    let upvotes: Int
    let downvotes: Int
    let commentCount: Int
    let domain: String
    
    init(container: [String : AnyObject]) {
        do {
            name = try "name" <- container
            title = try "title" <- container
            author = try "author" <- container
            
            thumbnailURL = URL(string: try "thumbnail" <- container)
            domain = try "domain" <- container
            
            upvotes = try "ups" <- container
            downvotes = try "downs" <- container
            commentCount = try "num_comments" <- container
            
            content = { (Void) -> Either<String, URL> in
                if let selftext: String = (try? "selftext" <- container) { return .left(selftext) }
                if let urlString: String = (try? "url" <- container), let url = URL(string: urlString) { return .right(url) }
                print(container)
                fatalError("should not be here")
            }()
            
        } catch (let error) {
            fatalError("\(error)")
        }
    }
}

extension RedditPost : CustomDebugStringConvertible {
    var debugDescription: String {
        var s = "\"\(title)\" by \(author)"
        if case .right(let url) = content {
            s += " links to [\(url.absoluteString)]"
        }
        return s
    }
}

class RedditAPI : Networking {
    enum Order : String {
        case top = "top"
        case hot = "hot"
        case new = "new"
    }
    
    private static let Endpoint = URL(string: "https://www.reddit.com/r/")!
    private var inflight = [TaskIdentifier : URLSessionTask]()
    
    func fetchListingFor(
        subreddit: String,
        order: RedditAPI.Order = .new,
        count: Int = 20,
        continueToken: String? = nil,
        callback: @escaping (Result<RedditListingAPIResponse>) -> Void) -> TaskIdentifier {
        
        let identifier = UUID().uuidString
        let target = RedditAPI.Endpoint.appendingPathComponent(subreddit).appendingPathComponent(order.rawValue).appendingPathComponent(".json")
        
        guard var components = URLComponents(url: target, resolvingAgainstBaseURL: false) else { fatalError("something's up with the target url") }
        components.queryItems = [
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "raw_json", value: "1")
        ]

        if let after = continueToken {
            components.queryItems?.append(URLQueryItem(name: "after", value: after))
        }

        let request = URLRequest(url: components.url!)
        let task = self.request(request: request, fireImmediately: false, callback: callback)
        inflight[identifier] = task
        task.resume()
        return identifier
        
    }
}

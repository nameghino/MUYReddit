//
//  RedditPost.swift
//  MUYReddit
//
//  Created by Nico Ameghino on 11/7/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import Foundation

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

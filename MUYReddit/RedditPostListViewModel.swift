//
//  RedditPostListViewModel.swift
//  MUYReddit
//
//  Created by Nico Ameghino on 11/7/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import Foundation
import UIKit

class RedditPostListViewModel : NSObject {
    private(set) var posts: [RedditPostViewModel] = []

    var subreddit: String = "argentina" {
        didSet {
            subredditChanged = true
        }
    }

    var subredditChanged: Bool = true


    var count: Int { return posts.count }

    private let service = RedditAPI()

    private var continueToken: String? = nil

    init(subreddit: String) {
        self.subreddit = subreddit
    }

    func fetch(callback: @escaping (Void) -> Void) {
        _ = service.fetchListingFor(subreddit: subreddit, continueToken: continueToken) { [weak self] result in
            defer {
                callback()
                self?.subredditChanged = false
            }
            guard let sself = self else { return }
            switch result {
            case .error(let error):
                fatalError("\(error)")
            case .success(let data):
                sself.continueToken = data.continueToken
                sself.posts += data.posts.map { RedditPostViewModel(post: $0) }
            }
        }
    }

    subscript(i: Int) -> RedditPostViewModel {
        return posts[i]
    }
}

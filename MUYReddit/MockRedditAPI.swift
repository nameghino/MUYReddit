//
//  MockRedditAPI.swift
//  MUYReddit
//
//  Created by Nico Ameghino on 11/10/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import Foundation

class MockRedditAPI: RedditAPIProtocol {
    func fetchListingFor(
        subreddit: String,
        order: RedditAPI.Order,
        count: Int,
        continueToken: String?,
        callback: @escaping (Result<RedditListingAPIResponse>) -> Void) -> TaskIdentifier {
        let url = Bundle.main.url(forResource: "posts_response", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let container = try! JSONSerialization.jsonObject(with: data, options: []) as! [String : AnyObject]
        let response = RedditListingAPIResponse(container: container)
        callback(Result.success(response))
        let identifier = UUID().uuidString
        return identifier
    }
}

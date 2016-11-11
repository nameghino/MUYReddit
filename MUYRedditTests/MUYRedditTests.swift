//
//  MUYRedditTests.swift
//  MUYRedditTests
//
//  Created by Nicolas Ameghino on 9/7/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import XCTest

class MUYRedditTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testMockListing() {
        let e = expectation(description: "testing mock listings")
        let postsViewModel = RedditPostListViewModel(redditService: MockRedditAPI(), subreddit: "")
        postsViewModel.fetch {
            XCTAssert(postsViewModel.count == 20)
            e.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRealListing() {
        let e = expectation(description: "fetch hot posts from r/argentina :-)")
        let postsViewModel = RedditPostListViewModel(redditService: RedditAPI(), subreddit: "argentina")
        postsViewModel.fetch {
            XCTAssert(postsViewModel.count == 20)
            e.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}

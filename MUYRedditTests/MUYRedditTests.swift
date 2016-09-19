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
    
    func testListing() {
        let e = expectation(description: "fetch hot posts from r/argentina :-)")
        
        let api = RedditAPI()
        let taskIdentifier = api.fetchListingFor(subreddit: "argentina", order: .hot) { result in
            defer { e.fulfill() }
            switch result {
            case .error(let error):
                XCTFail("\(error)")
            case .success(let r):
                for p in r.posts {
                    print(p)
                }
                let post = r.posts.first
                XCTAssert(post != nil)
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

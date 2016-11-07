//
//  RedditPostViewModel.swift
//  MUYReddit
//
//  Created by Nico Ameghino on 11/7/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import Foundation
import UIKit

class RedditPostViewModel : NSObject {
    private static let backgroundQueue = DispatchQueue(label: "viewmodel")
    private let post: RedditPost

    init(post: RedditPost) {
        self.post = post
    }

    var title: String { return post.title }
    var subtitle: NSAttributedString {
        let subtitle = NSMutableAttributedString()
        let attribution = NSAttributedString(string: "por \(post.author)", attributes: [NSForegroundColorAttributeName : UIColor.black])
        let source = NSAttributedString(string: " - via \(post.domain)", attributes: [NSForegroundColorAttributeName : UIColor.gray])
        subtitle.append(attribution)
        subtitle.append(source)
        return subtitle
    }

    private var cachedResult: Result<UIImage>? = nil
    private var inflightThumbnailTask: DispatchWorkItem? = nil

    func fetchThumbnail(callback: @escaping (Result<UIImage>) -> Void) {

        if let result = cachedResult {
            callback(result)
            return
        }

        inflightThumbnailTask = DispatchWorkItem(qos: .userInitiated, flags: []) { [weak self] in
            guard let sself = self else { return }
            do {
                guard let url = sself.post.thumbnailURL else {
                    let domainError = MUYRedditError.generic("post has no thumbnail")
                    callback(.error(domainError))
                    return
                }
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else {
                    let domainError = MUYRedditError.generic("downloaded data has no image")
                    callback(.error(domainError))
                    return
                }
                let result = Result<UIImage>.success(image)
                self?.cachedResult = result
                callback(result)
            } catch (let error) {
                let domainError = MUYRedditError.wrapped(error)
                callback(.error(domainError))
            }
        }
        RedditPostViewModel.backgroundQueue.async(execute: inflightThumbnailTask!)
    }

    func cancelThumbnailFetch() {
        inflightThumbnailTask?.cancel()
    }
}

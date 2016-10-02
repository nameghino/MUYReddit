//
//  ViewController.swift
//  MUYReddit
//
//  Created by Nicolas Ameghino on 9/6/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

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
        let attribution = NSAttributedString(string: "by \(post.author)", attributes: [NSForegroundColorAttributeName : UIColor.black])
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

class RedditPostListViewModel : NSObject {
    private(set) var posts: [RedditPostViewModel] = []

    var subreddit: String = "argentina"
    var count: Int { return posts.count }
    
    private let service = RedditAPI()
    
    func fetch(callback: @escaping (Void) -> Void) {
        _ = service.fetchListingFor(subreddit: subreddit) { [weak self] result in
            defer { callback() }
            guard let sself = self else { return }
            switch result {
            case .error(let error):
                fatalError("\(error)")
            case .success(let data):
                sself.posts = data.posts.map { RedditPostViewModel(post: $0) }
            }
        }
    }
    
    subscript(i: Int) -> RedditPostViewModel {
        return posts[i]
    }
}

class RedditPostListViewController: UIViewController {
    
    fileprivate static let ReuseIdentifier = "RedditPostCell"
    
    var postList: RedditPostListViewModel = RedditPostListViewModel() {
        didSet {
            update()
        }
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.estimatedRowHeight = 44.0
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        update()
    }
}

extension RedditPostListViewController {
    fileprivate func update() {
        navigationItem.title = "r/\(postList.subreddit)"
        postList.fetch { [unowned self] in
            DispatchQueue.main.async(execute: self.tableView.reloadData)
        }
    }

}

extension RedditPostListViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RedditPostListViewController.ReuseIdentifier, for: indexPath)
        cell.selectionStyle = .none
        let vm = postList[indexPath.row]
        set(content: vm, forCell: cell)
        return cell
    }
    
    private func set(content: RedditPostViewModel, forCell cell: UITableViewCell) {
        cell.textLabel?.text = content.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.attributedText = content.subtitle
    }
    
    @objc(tableView:didEndDisplayingCell:forRowAtIndexPath:) func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        postList[indexPath.row].cancelThumbnailFetch()
    }
}

extension RedditPostListViewController : UITableViewDelegate {
    
}


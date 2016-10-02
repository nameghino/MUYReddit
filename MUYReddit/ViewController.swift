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

class RedditPostListViewModel : NSObject {
    private(set) var posts: [RedditPostViewModel] = []

    var subreddit: String = "argentina"
    var count: Int { return posts.count }

    private let service = RedditAPI()

    private var continueToken: String? = nil

    init(subreddit: String) {
        self.subreddit = subreddit
    }

    func fetch(callback: @escaping (Void) -> Void) {
        _ = service.fetchListingFor(subreddit: subreddit, continueToken: continueToken) { [weak self] result in
            defer { callback() }
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

private enum PostListSection: Int {
    case posts
    case loadMore

    static let NumberOfSections = 2
}

class RedditPostListViewController: UIViewController {

    fileprivate static let PostCellReuseIdentifier = "RedditPostCell"
    fileprivate static let PagingCellReuseIdentifier = "PagingCell"

    var postList: RedditPostListViewModel = RedditPostListViewModel(subreddit: "argentina") {
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

    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "Cargando..."

        let tgr = UITapGestureRecognizer(target: self, action: #selector(showSubredditSelector))
        tgr.numberOfTapsRequired = 1
        tgr.numberOfTouchesRequired = 1

        navigationController?.navigationBar.addGestureRecognizer(tgr)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.gestureRecognizers?.forEach { navigationItem.titleView?.removeGestureRecognizer($0) }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension RedditPostListViewController {
    fileprivate func update() {
        navigationItem.title = "r/\(postList.subreddit)"
        postList.fetch { [unowned self] in
            DispatchQueue.main.async(execute: self.tableView.reloadData)
        }
    }

    @objc
    fileprivate func showSubredditSelector() {
        let alertController = UIAlertController(title: "Subreddit?", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))

        let acceptAction = UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
            guard let sself = self else { return }
            guard let text = alertController.textFields?.first?.text else { fatalError("alert controller has no textfields!") }

            let subreddit: String = {
                if text.hasPrefix("r/"), let subreddit = text.components(separatedBy: "r/").last {
                    return subreddit
                } else {
                    return text
                }
            }()

            sself.postList = RedditPostListViewModel(subreddit: subreddit)
        }

        alertController.addAction(acceptAction)

        present(alertController, animated: true, completion: nil)
    }
}

extension RedditPostListViewController : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return PostListSection.NumberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = PostListSection(rawValue: section) else { fatalError("unknown section!") }
        switch section {
        case .posts:
            return postList.count
        case .loadMore:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = PostListSection(rawValue: indexPath.section) else { fatalError("unknown section!") }
        switch section {
        case .posts:
            let cell = tableView.dequeueReusableCell(withIdentifier: RedditPostListViewController.PostCellReuseIdentifier, for: indexPath)
            cell.selectionStyle = .none
            let vm = postList[indexPath.row]
            set(content: vm, forCell: cell)
            return cell
        case .loadMore:
            let cell = tableView.dequeueReusableCell(withIdentifier: RedditPostListViewController.PagingCellReuseIdentifier, for: indexPath)
            cell.selectionStyle = .none
            cell.textLabel?.text = "Cargando..."
            return cell
        }
    }

    private func set(content: RedditPostViewModel, forCell cell: UITableViewCell) {
        cell.textLabel?.text = content.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.attributedText = content.subtitle
    }

    @objc(tableView:willDisplayCell:forRowAtIndexPath:)
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let section = PostListSection(rawValue: indexPath.section), section == .loadMore else { return }
        update()
    }

    @objc(tableView:didEndDisplayingCell:forRowAtIndexPath:)
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        postList[indexPath.row].cancelThumbnailFetch()
    }
}

extension RedditPostListViewController : UITableViewDelegate {
}


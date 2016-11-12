//
//  ViewController.swift
//  MUYReddit
//
//  Created by Nicolas Ameghino on 9/6/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import UIKit
import SafariServices

private enum PostListSection: Int {
    case posts
    case loadMore

    static let NumberOfSections = 2
}

extension RedditPostViewModel {
    var targetDetailViewController: UIViewController {
        if let webLinkURL = webLinkURL {
            return SFSafariViewController(url: webLinkURL)
        }
        fatalError()
    }
}

class RedditPostListViewController: UIViewController {

    fileprivate static let PostCellReuseIdentifier = "RedditPostCell"
    fileprivate static let PagingCellReuseIdentifier = "PagingCell"

    var postList: RedditPostListViewModel = RedditPostListViewModel(subreddit: "swift") {
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
        navigationItem.title = "Cargando..."
    }

    override func viewWillAppear(_ animated: Bool) {
        let tgr = UITapGestureRecognizer(target: self, action: #selector(showSubredditSelector))
        tgr.numberOfTapsRequired = 1
        tgr.numberOfTouchesRequired = 1
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "r/", style: .plain, target: self, action: #selector(showSubredditSelector))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}

extension RedditPostListViewController {
    fileprivate func update() {
        navigationItem.title = "r/\(postList.subreddit)"
        postList.fetch { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
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
        cell.textLabel?.textColor = content.titleColor
        cell.contentView.backgroundColor = content.backgroundColor
        cell.textLabel?.text = content.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.attributedText = content.subtitle
    }

    @objc(tableView:willDisplayCell:forRowAtIndexPath:)
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let section = PostListSection(rawValue: indexPath.section), section == .loadMore else { return }
        update()
    }
}

extension RedditPostListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = self.postList[indexPath.row]
        present(post.targetDetailViewController, animated: true, completion: nil)
    }
}


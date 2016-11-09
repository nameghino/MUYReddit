//
//  ViewController.swift
//  MUYReddit
//
//  Created by Nicolas Ameghino on 9/6/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import UIKit

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
//            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
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

    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "Cargando..."

        let tgr = UITapGestureRecognizer(target: self, action: #selector(showSubredditSelector))
        tgr.numberOfTapsRequired = 1
        tgr.numberOfTouchesRequired = 1

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "r/", style: .plain, target: self, action: #selector(showSubredditSelector))
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.gestureRecognizers?.forEach { navigationItem.titleView?.removeGestureRecognizer($0) }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let cell = sender as? UITableViewCell,
            let destination = segue.destination as? RedditPostViewController,
            let indexPath = tableView.indexPath(for: cell)
        else { return }
        let post = self.postList[indexPath.row]
        destination.viewModel = post
    }
}

extension RedditPostListViewController {
    fileprivate func update() {
        navigationItem.title = "r/\(postList.subreddit)"
        postList.fetch { [weak self] in
            DispatchQueue.main.async { self?.tableView.reloadData() }
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

            sself.tableView.scrollToRow(at: IndexPath(row: 0, section:0), at: .top, animated: false)
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
//        cell.contentView.backgroundColor = content.titleColor
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
}


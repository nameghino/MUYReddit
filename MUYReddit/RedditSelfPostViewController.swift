//
//  RedditSelfPostViewController.swift
//  MUYReddit
//
//  Created by Nico Ameghino on 11/8/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import UIKit

extension UIView {
    func addSubviewExpandingToFill(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        addConstraints([
            NSLayoutConstraint(item: subview,
                               attribute: .leading,
                               relatedBy: .equal,
                               toItem: self, attribute: .leading,
                               multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: subview,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self, attribute: .bottom,
                               multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: subview,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self, attribute: .top,
                               multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: subview,
                               attribute: .trailing,
                               relatedBy: .equal,
                               toItem: self, attribute: .trailing,
                               multiplier: 1.0, constant: 0),
        ])
    }
}

private enum RedditSelfPostViewControllerSections: Int {
    case post, comments
    static let Count = 2
}

class RedditSelfPostViewController: UIViewController {

    var viewModel: RedditPostViewModel {
        didSet {
            dump(viewModel)
        }
    }

    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var commentsButton: UIButton!

    init(viewModel: RedditPostViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("boo!")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView = UITableView()
        view.addSubviewExpandingToFill(subview: tableView)
    }
}

extension RedditSelfPostViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return RedditSelfPostViewControllerSections.Count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = RedditSelfPostViewControllerSections(rawValue: section) else { return 0 }
        switch sectionType {
        case .comments:
            return 0
        case .post:
            return 2
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let temporaryIdentifier = "AnIdentifier"
        guard let section = RedditSelfPostViewControllerSections(rawValue: indexPath.section) else { fatalError("unknown section") }
        let cell = tableView.dequeueReusableCell(withIdentifier: temporaryIdentifier, for: indexPath)
        return cell
    }
}
extension RedditSelfPostViewController: UITableViewDelegate { }

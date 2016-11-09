//
//  RedditPostViewController.swift
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

class RedditPostViewController: UIViewController {

    var viewModel: RedditPostViewModel! {
        didSet {
            dump(viewModel)
        }
    }

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var commentsButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

//        let contentViewController = viewModel.contentViewController
//        addChildViewController(contentViewController)
//        contentView.addSubview(contentViewController.view)
    }
}

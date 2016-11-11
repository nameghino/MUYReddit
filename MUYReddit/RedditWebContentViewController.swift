//
//  RedditWebContentViewController.swift
//  MUYReddit
//
//  Created by Nico Ameghino on 11/8/16.
//  Copyright © 2016 Nicolas Ameghino. All rights reserved.
//

import UIKit
import WebKit

protocol RedditContentDisplayer {
    var viewModel: RedditPostViewModel! { get set }
}

class RedditWebContentViewController: UIViewController, RedditContentDisplayer {

    private let webView = WKWebView()
    var viewModel: RedditPostViewModel!

    override func loadView() {
        view = webView
    }

    override func viewWillAppear(_ animated: Bool) {
        let request = URLRequest(url: viewModel.webLinkURL)
        webView.load(request)
    }

}

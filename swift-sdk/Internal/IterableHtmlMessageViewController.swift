//
//  Created by Tapash Majumder on 3/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit
import WebKit

enum IterableMessageLocation: Int {
    case full
    case top
    case center
    case bottom
}

class IterableHtmlMessageViewController: UIViewController {
    struct Parameters {
        let html: String
        let padding: UIEdgeInsets
        let messageMetadata: IterableInAppMessageMetadata?
        let isModal: Bool
        
        let inboxSessionId: String?
        
        init(html: String,
             padding: UIEdgeInsets = .zero,
             messageMetadata: IterableInAppMessageMetadata? = nil,
             isModal: Bool,
             inboxSessionId: String? = nil) {
            self.html = html
            self.padding = IterableHtmlMessageViewController.padding(fromPadding: padding)
            self.messageMetadata = messageMetadata
            self.isModal = isModal
            self.inboxSessionId = inboxSessionId
        }
    }
    
    init(parameters: Parameters) {
        self.parameters = parameters
        futureClickedURL = Promise<URL, IterableError>()
        super.init(nibName: nil, bundle: nil)
    }
    
    struct CreateResult {
        let viewController: IterableHtmlMessageViewController
        let futureClickedURL: Future<URL, IterableError>
    }
    
    static func create(parameters: Parameters) -> CreateResult {
        let viewController = IterableHtmlMessageViewController(parameters: parameters)
        return CreateResult(viewController: viewController, futureClickedURL: viewController.futureClickedURL)
    }
    
    override var prefersStatusBarHidden: Bool { return parameters.isModal }

    
    /**
     Loads the view and sets up the webView
     */
    override func loadView() {
        ITBInfo()
        super.loadView()
        
        location = HtmlContentParser.location(fromPadding: parameters.padding)
        if parameters.isModal {
            view.backgroundColor = UIColor.clear
        } else {
            if #available(iOS 13, *) {
                view.backgroundColor = UIColor.systemBackground
            } else {
                view.backgroundColor = UIColor.white
            }
        }
        
       /// 若在全屏的webview上展示 在iphont X上上下会有留白 在8 Plus这样的正常屏幕上状态栏会有留白 故修改frame
        let webView = WKWebView(frame: CGRect(x: 0, y: -DeviceTool.statusBarHeight, width: view.bounds.width, height: view.bounds.height + DeviceTool.statusBarHeight + DeviceTool.bottom ))

        webView.loadHTMLString(parameters.html, baseURL: URL(string: ""))
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.navigationDelegate = self
        
        view.addSubview(webView)
        self.webView = webView
    }
    
    /**
     Tracks an inApp open and layouts the webview
     */
    override func viewDidLoad() {
        ITBInfo()
        super.viewDidLoad()
        
        if let messageMetadata = parameters.messageMetadata {
            IterableAPI.internalImplementation?.trackInAppOpen(messageMetadata.message,
                                                               location: messageMetadata.location,
                                                               inboxSessionId: parameters.inboxSessionId)
        }
        
        webView?.layoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let webView = self.webView else {
            return
        }
        resizeWebView(webView)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let messageMetadata = parameters.messageMetadata else {
            return
        }
        
        if let _ = navigationController, linkClicked == false {
            IterableAPI.internalImplementation?.trackInAppClose(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
                                                                source: InAppCloseSource.back,
                                                                clickedUrl: nil)
        } else {
            IterableAPI.internalImplementation?.trackInAppClose(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
                                                                source: InAppCloseSource.back,
                                                                clickedUrl: clickedLink)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        parameters = aDecoder.decodeObject(forKey: "input") as? Parameters ?? Parameters(html: "", isModal: false)
        futureClickedURL = Promise<URL, IterableError>()
        super.init(coder: aDecoder)
    }
    
    private var parameters: Parameters
    private let futureClickedURL: Promise<URL, IterableError>
    private var webView: WKWebView?
    private var location: IterableMessageLocation = .full
    private var linkClicked = false
    private var clickedLink: String?
    
    /**
     Resizes the webview based upon the insetPadding if the html is finished loading
     
     - parameter: aWebView the webview
     */
    private func resizeWebView(_ aWebView: WKWebView) {
        guard location != .full else {
          /// 若在全屏的webview上展示 在iphont X上上下会有留白 在8 Plus这样的正常屏幕上状态栏会有留白 故修改frame
          webView?.frame =  CGRect(x: 0, y: -DeviceTool.statusBarHeight, width: view.frame.width, height: view.frame.height + DeviceTool.statusBarHeight + DeviceTool.bottom )
          return
        }
        
        aWebView.evaluateJavaScript("document.body.offsetHeight", completionHandler: { height, _ in
            guard let floatHeight = height as? CGFloat, floatHeight >= 20 else {
                ITBError("unable to get height")
                return
            }
            self.resize(webView: aWebView, withHeight: floatHeight)
        })
    }
    
    private func resize(webView: WKWebView, withHeight height: CGFloat) {
        ITBInfo("height: \(height)")
        // set the height
        webView.frame.size.height = height
        
        // now set the width
        let notificationWidth = 100 - (parameters.padding.left + parameters.padding.right)
        let screenWidth = view.bounds.width
        webView.frame.size.width = screenWidth * notificationWidth / 100
        
        // Position webview
        var center = view.center
        
        // set center x
        center.x = screenWidth * (parameters.padding.left + notificationWidth / 2) / 100
        
        // set center y
        let halfWebViewHeight = webView.frame.height / 2
        switch location {
        case .top:
            if #available(iOS 11, *) {
                center.y = halfWebViewHeight + view.safeAreaInsets.top
            } else {
                center.y = halfWebViewHeight
            }
        case .bottom:
            if #available(iOS 11, *) {
                center.y = view.frame.height - halfWebViewHeight - view.safeAreaInsets.bottom
            } else {
                center.y = view.frame.height - halfWebViewHeight
            }
        default: break
        }
        
        webView.center = center
    }
    
    private static func padding(fromPadding padding: UIEdgeInsets) -> UIEdgeInsets {
        var insetPadding = padding
        if insetPadding.left + insetPadding.right >= 100 {
            ITBError("Can't display an in-app with padding > 100%. Defaulting to 0 for padding left/right")
            insetPadding.left = 0
            insetPadding.right = 0
        }
        
        return insetPadding
    }
}

extension IterableHtmlMessageViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        if let myWebview = self.webView {
            resizeWebView(myWebview)
        }
    }
    
    fileprivate func trackInAppClick(destinationUrl: String) {
        if let messageMetadata = parameters.messageMetadata {
            IterableAPI.internalImplementation?.trackInAppClick(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
                                                                clickedUrl: destinationUrl)
        }
    }
    
    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        guard let parsed = InAppHelper.parse(inAppUrl: url) else {
            decisionHandler(.allow)
            return
        }
        
        let destinationUrl: String
        if case let InAppHelper.InAppClickedUrl.localResource(name) = parsed {
            destinationUrl = name
        } else {
            destinationUrl = url.absoluteString
        }
        
        linkClicked = true
        clickedLink = destinationUrl
        
        if parameters.isModal {
            dismiss(animated: true) { [weak self, destinationUrl] in
                self?.futureClickedURL.resolve(with: url)
                self?.trackInAppClick(destinationUrl: destinationUrl)
            }
        } else {
            futureClickedURL.resolve(with: url)
            trackInAppClick(destinationUrl: destinationUrl)
            
            navigationController?.popViewController(animated: true)
        }
        
        decisionHandler(.cancel)
    }
}


struct DeviceTool {
  static var isEntirelyScreen:Bool{ UIApplication.shared.statusBarFrame.height > 20 ? true : false}
  static var statusBarHeight = UIApplication.shared.statusBarFrame.height
  static var bottom:CGFloat =  isEntirelyScreen ? 34 : 0
}


//以下html代码 若在全屏的webview上展示 在iphont X上上下会有留白 在8 Plus这样的正常屏幕上状态栏会有留白 暂时未找到通过修改html代码而解决问题的办法
// 故未解决此问题 修改webview的frame
/*
<html>
  <head>
    <meta data-n-head="true" name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <title></title>
    <style type="text/css">body{
      margin:0;
      padding:0;
      }
      .panel {
        margin:0;
        padding:0;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.6);
      }
      .fresh {
        max-width: 60%;
      }
      .fresh-action {
        display: flex;
        justify-content: center;
        align-items: center;
      }
      .button-close {
        display: flex;
        justify-content: center;
        align-items: center;
      }
      .close {
        margin-top: 50px;
        max-width: 40%;
      }
    </style>
  </head>
  <body>
    <div class="panel"><a class="fresh-action" href="https://m.yamibuy.com/zh/freshlist?track=display-popup&amp;utm_source=iterable&amp;utm_medium=popup&amp;utm_campaign=POP_Fresh&amp;campaign_id=1209249&amp;template_id=1687171"><img alt="" class="fresh" src="https://cdn.yamibuy.net/mkpl/c45af24da8d07ca4d1906b0e09aa13ce_0x0.png" /></a> <a class="button-close" href="action://"> <img alt="" class="close" src="https://d2axdqolvqmdvx.cloudfront.net/5dc76691-5aea-4faf-8fb5-44995ccaa7c5/dialog_button_close3x.png" /> </a> &nbsp;
    </div>
  </body>
</html>
*/

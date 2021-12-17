//
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
        let padding: Padding
        let messageMetadata: IterableInAppMessageMetadata?
        let isModal: Bool
        
        let inboxSessionId: String?
        let animationDuration = 0.67

        init(html: String,
             padding: Padding = .zero,
             messageMetadata: IterableInAppMessageMetadata? = nil,
             isModal: Bool,
             inboxSessionId: String? = nil) {
            ITBInfo()
            self.html = html
            self.padding = padding.adjusted()
            self.messageMetadata = messageMetadata
            self.isModal = isModal
            self.inboxSessionId = inboxSessionId
        }
        
        var shouldAnimate: Bool {
            messageMetadata
                .flatMap { $0.message.content as? IterableHtmlInAppContent }
                .map { $0.shouldAnimate } ?? false
        }
        
        var backgroundColor: UIColor? {
            messageMetadata
                .flatMap { $0.message.content as? IterableHtmlInAppContent }
                .flatMap { $0.backgroundColor }
        }
        
        var location: IterableMessageLocation {
            HtmlContentParser.InAppDisplaySettingsParser.PaddingParser.location(fromPadding: padding)
        }
    }
    
    weak var presenter: InAppPresenter?
    
    init(parameters: Parameters,
         internalAPIProvider: @escaping @autoclosure () -> InternalIterableAPI? = IterableAPI.internalImplementation,
         webViewProvider: @escaping @autoclosure () -> WebViewProtocol = IterableHtmlMessageViewController.createWebView()) {
        ITBInfo()
        self.internalAPIProvider = internalAPIProvider
        self.webViewProvider = webViewProvider
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
    
//<<<<<<< HEAD
    override var prefersStatusBarHidden: Bool { parameters.isModal }
//=======
//    override var prefersStatusBarHidden: Bool { return parameters.isModal }
//
//>>>>>>> falcon
    
    override func loadView() {
        ITBInfo()
        
        super.loadView()
        
        location = parameters.location

        view.backgroundColor = InAppCalculations.initialViewBackgroundColor(isModal: parameters.isModal)
        
//<<<<<<< HEAD
        webView.set(position: ViewPosition(width: view.frame.width, height: view.frame.height, center: view.center))
//=======
       /// 若在全屏的webview上展示 在iphont X上上下会有留白 在8 Plus这样的正常屏幕上状态栏会有留白 故修改frame
//        let webView = WKWebView(frame: CGRect(x: 0, y: -DeviceTool.statusBarHeight, width: view.bounds.width, height: view.bounds.height + DeviceTool.statusBarHeight + DeviceTool.bottom ))
      

//>>>>>>> falcon
        webView.loadHTMLString(parameters.html, baseURL: URL(string: ""))
        webView.set(navigationDelegate: self)
        
        view.addSubview(webView.view)
    }
    
    override func viewDidLoad() {
        ITBInfo()
        
        super.viewDidLoad()
        
        // Tracks an in-app open and layouts the webview
        if let messageMetadata = parameters.messageMetadata {
            internalAPI?.trackInAppOpen(messageMetadata.message,
                                        location: messageMetadata.location,
                                        inboxSessionId: parameters.inboxSessionId)
        }
        
        webView.layoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//<<<<<<< HEAD
    
        resizeWebView(animate: false)
//=======
        
//        guard let webView = self.webView else {
//            return
//        }
//        resizeWebView(webView)
//
//>>>>>>> falcon
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let messageMetadata = parameters.messageMetadata else {
            return
        }
        
        if let _ = navigationController, linkClicked == false {
            internalAPI?.trackInAppClose(messageMetadata.message,
                                         location: messageMetadata.location,
                                         inboxSessionId: parameters.inboxSessionId,
                                         source: InAppCloseSource.back,
                                         clickedUrl: nil)
        } else {
            internalAPI?.trackInAppClose(messageMetadata.message,
                                         location: messageMetadata.location,
                                         inboxSessionId: parameters.inboxSessionId,
                                         source: InAppCloseSource.link,
                                         clickedUrl: clickedLink)
        }
      
    }
    
    required init?(coder _: NSCoder) {
        fatalError("IterableHtmlMessageViewController cannot be instantiated from Storyboard")
    }
    
    deinit {
        ITBInfo()
    }
    
    private var internalAPIProvider: () -> InternalIterableAPI?
    private var webViewProvider: () -> WebViewProtocol
    private var parameters: Parameters
    private let futureClickedURL: Promise<URL, IterableError>
    private var location: IterableMessageLocation = .full
    private var linkClicked = false
    private var clickedLink: String?
    
//<<<<<<< HEAD
    private lazy var webView = webViewProvider()
    private var internalAPI: InternalIterableAPI? {
        internalAPIProvider()
    }
//=======
    /**
     Resizes the webview based upon the insetPadding if the html is finished loading
     
     - parameter: aWebView the webview
     */
//    private func resizeWebView(_ aWebView: WKWebView) {
//        guard location != .full else {
//          /// 若在全屏的webview上展示 在iphont X上上下会有留白 在8 Plus这样的正常屏幕上状态栏会有留白 故修改frame
//          webView?.frame =  CGRect(x: 0, y: -DeviceTool.statusBarHeight, width: view.frame.width, height: view.frame.height + DeviceTool.statusBarHeight + DeviceTool.bottom )
//          return
//        }
//
//        aWebView.evaluateJavaScript("document.body.offsetHeight", completionHandler: { height, _ in
//            guard let floatHeight = height as? CGFloat, floatHeight >= 20 else {
//                ITBError("unable to get height")
//                return
//            }
//            self.resize(webView: aWebView, withHeight: floatHeight)
//        })
//>>>>>>> falcon
//    }
    
    private static func createWebView() -> WebViewProtocol {
        let webView = WKWebView(frame: .zero)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView as WebViewProtocol
    }
    
    /// Resizes the webview based upon the insetPadding, height etc
    private func resizeWebView(animate: Bool) {
        let parentPosition = ViewPosition(width: view.bounds.width,
                                          height: view.bounds.height,
                                          center: view.center)
        IterableHtmlMessageViewController.calculateWebViewPosition(webView: webView,
                                                                   safeAreaInsets: InAppCalculations.safeAreaInsets(for: view),
                                                                   parentPosition: parentPosition,
                                                                   paddingLeft: CGFloat(parameters.padding.left),
                                                                   paddingRight: CGFloat(parameters.padding.right),
                                                                   location: location)
            .onSuccess { [weak self] position in
                if animate {
                    self?.animateWhileEntering(position)
                } else {
                    self?.webView.set(position: position)
                }
            }
    }
    
    private func animateWhileEntering(_ position: ViewPosition) {
        ITBInfo()
        createAnimationDetail(withPosition: position).map { applyAnimation(animationDetail: $0) } ?? (webView.set(position: position))
    }

    private func animateWhileLeaving(_ position: ViewPosition) {
        let animation = createAnimationDetail(withPosition: position).map(InAppCalculations.swapAnimation(animationDetail:))
        let dismisser = InAppCalculations.createDismisser(for: self,
                                                          isModal: parameters.isModal,
                                                          isInboxMessage: parameters.messageMetadata?.location == .inbox)
        animation.map { applyAnimation(animationDetail: $0, completion: dismisser) } ?? (dismisser())
    }

    private func createAnimationDetail(withPosition position: ViewPosition) -> InAppCalculations.AnimationDetail? {
        let input = InAppCalculations.AnimationInput(position: position,
                                                     isModal: parameters.isModal,
                                                     shouldAnimate: parameters.shouldAnimate,
                                                     location: location,
                                                     safeAreaInsets: InAppCalculations.safeAreaInsets(for: view),
                                                     backgroundColor: parameters.backgroundColor)
        return InAppCalculations.calculateAnimationDetail(animationInput: input)
    }
    
    private func applyAnimation(animationDetail: InAppCalculations.AnimationDetail, completion: (() -> Void)? = nil) {
        Self.animate(duration: parameters.animationDuration) { [weak self] in
            self?.webView.set(position: animationDetail.initial.position)
            self?.webView.view.alpha = animationDetail.initial.alpha
            self?.view.backgroundColor = animationDetail.initial.bgColor
        } finalValues: { [weak self] in
            self?.webView.set(position: animationDetail.final.position)
            self?.webView.view.alpha = animationDetail.final.alpha
            self?.view.backgroundColor = animationDetail.final.bgColor
        } completion: {
            completion?()
        }
    }
    
    static func animate(duration: TimeInterval,
                        initialValues: @escaping () -> Void,
                        finalValues: @escaping () -> Void,
                        completion: (() -> Void)? = nil) {
        ITBInfo()
        initialValues()
        UIView.animate(withDuration: duration) {
            finalValues()
        } completion: { _ in
            completion?()
        }
    }

    static func calculateWebViewPosition(webView: WebViewProtocol,
                                         safeAreaInsets: UIEdgeInsets,
                                         parentPosition: ViewPosition,
                                         paddingLeft: CGFloat,
                                         paddingRight: CGFloat,
                                         location: IterableMessageLocation) -> Future<ViewPosition, IterableError> {
        guard location != .full else {
            return Promise(value: parentPosition)
        }
        
        return webView.calculateHeight().map { height in
            ITBInfo("height: \(height)")
            return InAppCalculations.calculateWebViewPosition(safeAreaInsets: safeAreaInsets,
                                                              parentPosition: parentPosition,
                                                              paddingLeft: paddingLeft,
                                                              paddingRight: paddingRight,
                                                              location: location,
                                                              inAppHeight: height)
        }
    }
}

extension IterableHtmlMessageViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didFinish _: WKNavigation!) {
//<<<<<<< HEAD
        ITBInfo()
        resizeWebView(animate: true)
        presenter?.webViewDidFinish()
//=======
//        if let myWebview = self.webView {
//            resizeWebView(myWebview)
//        }
        if let message = self.parameters.messageMetadata?.message{
            IterableAPI.internalImplementation?.inAppWebviewUIDelegate?.eventCallBack(event: .displayed(message))
        }
    }
    
    fileprivate func trackInAppClick(destinationUrl: String) {
        if let messageMetadata = parameters.messageMetadata {
            IterableAPI.internalImplementation?.trackInAppClick(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
                                                                clickedUrl: destinationUrl)
        }
//>>>>>>> falcon
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
//<<<<<<< HEAD

        Self.trackClickOnDismiss(internalAPI: internalAPI,
                                 params: parameters,
                                 futureClickedURL: futureClickedURL,
                                 withURL: url,
                                 andDestinationURL: destinationUrl)

        animateWhileLeaving(webView.position)
/*
=======
        
        if parameters.isModal {
            dismiss(animated: true) { [weak self, destinationUrl] in
                self?.futureClickedURL.resolve(with: url)
                self?.trackInAppClick(destinationUrl: destinationUrl)
                if let message = self?.parameters.messageMetadata?.message{
                  IterableAPI.internalImplementation?.inAppWebviewUIDelegate?.eventCallBack(event: .linkTappedAndFinishShow(destinationUrl, message))
                }
            }
        } else {
            futureClickedURL.resolve(with: url)
            trackInAppClick(destinationUrl: destinationUrl)
            navigationController?.popViewController(animated: true)
            if let message = self.parameters.messageMetadata?.message{
              IterableAPI.internalImplementation?.inAppWebviewUIDelegate?.eventCallBack(event: .linkTappedAndFinishShow(destinationUrl, message))
            }
        }
        
>>>>>>> falcon
 */
        decisionHandler(.cancel)
    }

    private static func trackClickOnDismiss(internalAPI: InternalIterableAPI?,
                                            params: Parameters,
                                            futureClickedURL: Promise<URL, IterableError>,
                                            withURL url: URL,
                                            andDestinationURL destinationURL: String) {
        ITBInfo()
        futureClickedURL.resolve(with: url)
        if let messageMetadata = params.messageMetadata {
            internalAPI?.trackInAppClick(messageMetadata.message,
                                         location: messageMetadata.location,
                                         inboxSessionId: params.inboxSessionId,
                                         clickedUrl: destinationURL)
          let message = messageMetadata.message
            IterableAPI.internalImplementation?.inAppWebviewUIDelegate?.eventCallBack(event: .linkTappedAndFinishShow(destinationURL, message))
//          }
          
          
          
        }
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

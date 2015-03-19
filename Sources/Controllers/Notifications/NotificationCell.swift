//
//  NotificationCell.swift
//  Ello
//
//  Created by Colin Gray on 2/12/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import UIKit

@objc
protocol NotificationDelegate {
    func userTapped(user: User)
    func commentTapped(comment: Comment)
    func postTapped(post: Post)
}

class NotificationCell : UICollectionViewCell, UIWebViewDelegate {

    struct Size {
        static let sideMargins = CGFloat(15)
        static let avatarSide = CGFloat(30)
        static let leftTextMargin = CGFloat(10)
        static let imageWidth = CGFloat(87)
        static let topBottomMargins = CGFloat(30)
        static let innerTextMargin = CGFloat(10)
        static let createdAtHeight = CGFloat(12)

        // height of created at and title labels
        static func topBottomFixedHeight() -> CGFloat {
            let createdAtHeight = CGFloat(12)
            let innerMargin = self.innerTextMargin
            return createdAtHeight + innerMargin
        }

        static func messageHtmlWidth(#forCellWidth: CGFloat, hasImage: Bool) -> CGFloat {
            let messageLeftMargin : CGFloat = 55
            var messageRightMargin : CGFloat = 107
            if !hasImage {
                messageRightMargin = messageRightMargin - CGFloat(10) - self.imageWidth
            }
            return forCellWidth - messageLeftMargin - messageRightMargin
        }

        static func imageHeight(#imageRegion: ImageRegion?) -> CGFloat {
            if let imageRegion = imageRegion {
                var aspectRatio = StreamCellItemParser.aspectRatioForImageBlock(imageRegion)
                return self.imageWidth * aspectRatio
            }
            else {
                return 0
            }
        }
    }

    var webLinkDelegate: WebLinkDelegate?
    var delegate: NotificationDelegate?

    var avatarButton : AvatarButton!
    var titleTextView : ElloTextView!
    var createdAtLabel : UILabel!
    var messageWebView : UIWebView!
    var notificationImageView : UIImageView!
    var aspectRatio:CGFloat = 4.0/3.0

    var messageHtml : String? {
        willSet(newValue) {
            messageWebView.alpha = 0.0
            if newValue != messageHtml {
                if let value = newValue {
                    messageWebView.loadHTMLString(StreamTextCellHTML.postHTML(newValue!), baseURL: NSURL(string: "/"))
                }
                else {
                    messageWebView.loadHTMLString("", baseURL: NSURL(string: "/"))
                }
            }
        }
    }

    var imageURL : NSURL? {
        willSet(newValue) {
            self.notificationImageView.sd_setImageWithURL(newValue, completed: { (image, error, type, url) in
                self.setNeedsLayout()
            })
        }
    }

    var title: NSAttributedString? {
        willSet(newValue) {
            titleTextView.attributedText = newValue
        }
    }

    var createdAt: NSDate? {
        willSet(newValue) {
            if let date = newValue {
                createdAtLabel.text = NSDate().distanceOfTimeInWords(date)
            }
            else {
                createdAtLabel.text = ""
            }
        }
    }

    var avatarURL: NSURL? {
        willSet(newValue) {
            if let url = newValue {
                avatarButton.setAvatarURL(url)
            }
            else {
                avatarButton.setImage(nil, forState: .Normal)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        avatarButton = AvatarButton()
        titleTextView = ElloTextView(frame: CGRectZero, textContainer: nil)
        titleTextView.textViewDelegate = self

        notificationImageView = UIImageView()
        messageWebView = UIWebView()
        createdAtLabel = UILabel()

        messageWebView.delegate = self

        createdAtLabel.textColor = UIColor.greyA()
        createdAtLabel.font = UIFont.typewriterFont(12)
        createdAtLabel.text = ""

        for view in [avatarButton, titleTextView, notificationImageView, messageWebView, createdAtLabel] {
            self.contentView.addSubview(view)
        }
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let outerFrame = self.contentView.bounds.inset(all: Size.sideMargins)
        let titleWidth = Size.messageHtmlWidth(forCellWidth: self.frame.width, hasImage: imageURL != nil)

        avatarButton.frame = outerFrame.withSize(CGSize(width: Size.avatarSide, height: Size.avatarSide))

        if imageURL == nil {
            notificationImageView.frame = CGRectZero
        }
        else {
            notificationImageView.frame = outerFrame.fromRight()
                .growLeft(Size.imageWidth)
                .withHeight(Size.imageWidth / aspectRatio)
        }

        titleTextView.frame = avatarButton.frame.fromRight()
            .shiftRight(Size.innerTextMargin)
            .withWidth(titleWidth)
        titleTextView.sizeToFit()

        let createdAtHeight = Size.createdAtHeight
        createdAtLabel.frame = avatarButton.frame.fromRight()
            .shiftRight(Size.innerTextMargin)
            .atY(outerFrame.maxY - createdAtHeight)
            .withSize(CGSize(width: titleWidth, height: createdAtHeight))

        if messageHtml == nil {
            messageWebView.frame = CGRectZero
        }
        else {
            let remainingHeight = outerFrame.height - Size.innerTextMargin - titleTextView.frame.height
            messageWebView.frame = titleTextView.frame.fromBottom()
                .shiftDown(Size.innerTextMargin)
                .withHeight(remainingHeight)
        }
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return ElloWebViewHelper.handleRequest(request, webLinkDelegate: webLinkDelegate)
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        webView.stringByEvaluatingJavaScriptFromString("document.documentElement.style.webkitUserSelect='none';")
        webView.stringByEvaluatingJavaScriptFromString("document.documentElement.style.webkitTouchCallout='none';")
        UIView.animateWithDuration(0.15, animations: {
            self.messageWebView.alpha = 1.0
        })
    }
}

extension NotificationCell: ElloTextViewDelegate {
    func textViewTapped(link: String, object: AnyObject?) {
        switch link {
        case "post":
            delegate?.postTapped(object as Post)
        case "comment":
            let comment = object as Comment
            println("comment: \(comment)")
            if let post = comment.parentPost {
                println("post: \(post)")
            }
        case "user":
            let user = object as User
            println("user: \(user)")
            delegate?.userTapped(user)
        default: break
        }
    }
}
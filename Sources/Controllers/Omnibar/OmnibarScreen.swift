//
//  OmnibarScreen.swift
//  Ello
//
//  Created by Colin Gray on 2/26/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import UIKit


@objc
protocol OmnibarScreenDelegate {
    func omnibarCanceled()
    func omnibarPresentPicker(controller : UIViewController)
    func omnibarDismissPicker(controller : UIViewController)
    func omnibarSubmitted(text : String)
}


class OmnibarScreen : UIView, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    struct Size {
        static let margins = CGFloat(10)
        static let textMargins = CGFloat(9)
        static let labelCorrection = CGFloat(8.5)
        static let innerTextMargin = CGFloat(11)
        static let bottomTextMargin = CGFloat(1)
        static let toolbarHeight = CGFloat(60)
        static let buttonWidth = CGFloat(70)
        static let buttonRightMargin = CGFloat(5)
    }

    weak var delegate : OmnibarScreenDelegate?

    var scrollView : UIScrollView!

    var avatarView : UIImageView!
    var cameraButton : UIButton!
    var imageSelectedButton : UIButton!
    var imageSelectedOverlay : UIImageView!
    var cancelButton : UIButton!
    var submitButton : UIButton!
    var buttonContainer : ElloEquallySpacedLayout!

    var sayElloOverlay : UIControl!
    var sayElloLabel : UILabel!

    var textContainer : UIView!
    var textView : UITextView!

    var currentText : NSAttributedString?
    var currentImage : UIImage?

    var undoText : NSAttributedString?
    var undoImage : UIImage?

    override init(frame: CGRect) {
        scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.whiteColor()

        avatarView = UIImageView(frame: CGRectZero)
        avatarView.backgroundColor = UIColor.blackColor()
        avatarView.clipsToBounds = true

        textContainer = UIView()
        textContainer.backgroundColor = UIColor.greyE5()
        buttonContainer = ElloEquallySpacedLayout()

        sayElloOverlay = UIControl()
        sayElloLabel = UILabel()
        sayElloLabel.text = "Say Ello…"
        sayElloLabel.textColor = UIColor.greyA()
        sayElloLabel.font = UIFont.typewriterFont(12)

        cameraButton = UIButton()
        cameraButton.setImage(ElloDrawable.imageOfCameraIcon, forState: .Normal)

        // this rect will be adjusted by ElloEquallySpacedLayout, but I need it
        // set to *something* so that autoresizingMask is calculated correctly
        imageSelectedButton = UIButton(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        imageSelectedOverlay = UIImageView()
        imageSelectedOverlay.contentMode = .Center
        imageSelectedOverlay.layer.cornerRadius = 13
        imageSelectedOverlay.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        imageSelectedOverlay.image = ElloDrawable.imageOfTrashIconSelected
        imageSelectedOverlay.frame = CGRect.at(x: imageSelectedButton.frame.width / 2, y: imageSelectedButton.frame.height / 2).grow(all: imageSelectedOverlay.layer.cornerRadius)
        imageSelectedOverlay.autoresizingMask = .FlexibleBottomMargin | .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleRightMargin
        imageSelectedButton.addSubview(imageSelectedOverlay)

        cancelButton = UIButton()
        cancelButton.setImage(ElloDrawable.imageOfCancelIcon, forState: .Normal)

        submitButton = UIButton()
        submitButton.setImage(ElloDrawable.imageOfSubmitIcon, forState: .Normal)

        textView = UITextView()
        textView.editable = true
        textView.allowsEditingTextAttributes = true
        textView.selectable = true
        textView.textColor = UIColor.blackColor()
        textView.font = UIFont.typewriterFont(12)
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = UIColor.greyE5()

        super.init(frame: frame)

        self.addSubview(scrollView)
        for view in [avatarView, buttonContainer, textContainer, sayElloOverlay] as [UIView] {
            scrollView.addSubview(view)
        }

        for view in [cameraButton, cancelButton, submitButton] as [UIView] {
            buttonContainer.addSubview(view)
        }
        submitButton.addTarget(self, action: Selector("submitAction"), forControlEvents: .TouchUpInside)
        cameraButton.addTarget(self, action: Selector("cameraAction"), forControlEvents: .TouchUpInside)
        cancelButton.addTarget(self, action: Selector("cancelEditingAction"), forControlEvents: .TouchUpInside)
        imageSelectedButton.addTarget(self, action: Selector("removeButtonAction"), forControlEvents: .TouchUpInside)

        sayElloOverlay.addSubview(sayElloLabel)
        sayElloOverlay.addTarget(self, action: Selector("startEditingAction"), forControlEvents: .TouchUpInside)

        textView.delegate = self
        textView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        textContainer.addSubview(textView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var avatarURL : NSURL? {
        willSet(newValue) {
            if self.avatarURL != newValue {
                if let avatarURL = newValue {
                    self.avatarView.sd_setImageWithURL(avatarURL)
                }
                else {
                    // TODO: Ello default
                    self.avatarView.image = nil
                }
            }
        }
    }

// MARK: Layout and update views

    override func layoutSubviews() {
        super.layoutSubviews()

        scrollView.frame = self.bounds
        avatarView.frame = CGRect(x: Size.margins, y: Size.margins, width: Size.toolbarHeight, height: Size.toolbarHeight)
        avatarView.layer.cornerRadius = Size.toolbarHeight / CGFloat(2)

        let buttonContainerWidth = Size.buttonWidth * CGFloat(buttonContainer.subviews.count)
        buttonContainer.frame = CGRect(x: self.bounds.width - Size.buttonRightMargin, y: Size.margins, width: 0, height: Size.toolbarHeight)
            .growLeft(buttonContainerWidth)

        // make sure the textContainer is above the keboard, with a 1pt line
        // margin at the bottom.
        // size the textContainer and sayElloOverlay to be identical.
        let kbdHeight = Keyboard.shared().height
        let window : UIView = self.window ?? self
        let bottom = self.convertPoint(CGPoint(x: 0, y: self.bounds.height), toView: window).y
        let bottomHeight = self.window!.frame.height - bottom
        var localKbdHeight = kbdHeight - bottomHeight
        if localKbdHeight < 0 {
            localKbdHeight = 0
        }
        else {
            localKbdHeight += Size.bottomTextMargin
        }
        textContainer.frame = CGRect.make(x: Size.margins, y: avatarView.frame.maxY + Size.innerTextMargin,
            right: self.bounds.size.width - Size.margins, bottom: self.bounds.size.height - localKbdHeight)
        sayElloOverlay.frame = textContainer.frame
        sayElloLabel.frame = CGRect(x: Size.textMargins, y: Size.textMargins + Size.labelCorrection, width: 0, height: 0)
        sayElloLabel.sizeToFit()

        // size so that it is offset from the textContainer
        textView.frame = textContainer.bounds.inset(top: 0, left: Size.textMargins, bottom: 0, right: 0)
        textView.contentInset = UIEdgeInsets(top: Size.textMargins, left: 0, bottom: Size.textMargins, right: 0)

        // size according to the bottom of the text view
        // this scrollview is current pointless... need to double check on smaller devices whether it's necessary
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: textContainer.frame.maxY)
        let scrollInsets = UIEdgeInsets(top: 0, left: 0, bottom: localKbdHeight, right: 0)
        scrollView.contentInset = scrollInsets
        scrollView.scrollIndicatorInsets = scrollInsets
    }

    func resetEditor() {
        sayElloOverlay.hidden = false
        textView.resignFirstResponder()
        textView.text = ""
        currentText = nil
        setCurrentImage(nil)
    }

    func updateUndoState() {
        if canUndo() {
            cancelButton.setImage(ElloDrawable.imageOfUndoIcon, forState: .Normal)
            cancelButton.removeTarget(self, action: Selector("cancelEditingAction"), forControlEvents: .TouchUpInside)
            cancelButton.addTarget(self, action: Selector("undoCancelAction"), forControlEvents: .TouchUpInside)
        }
        else {
            cancelButton.setImage(ElloDrawable.imageOfCancelIcon, forState: .Normal)
            cancelButton.removeTarget(self, action: Selector("undoCancelAction"), forControlEvents: .TouchUpInside)
            cancelButton.addTarget(self, action: Selector("cancelEditingAction"), forControlEvents: .TouchUpInside)
        }
    }

// MARK: Keyboard events - animate layout update in conjunction with keyboard animation

    func keyboardWillShow() {
        self.setNeedsLayout()
        UIView.animateWithDuration(Keyboard.shared().duration,
            delay: 0.0,
            options: Keyboard.shared().options,
            animations: {
                self.layoutIfNeeded()
        },
        completion: nil)
    }

    func keyboardWillHide() {
        self.setNeedsLayout()
        UIView.animateWithDuration(Keyboard.shared().duration,
            delay: 0.0,
            options: Keyboard.shared().options,
            animations: {
                self.layoutIfNeeded()
            },
            completion: nil)
    }

// MARK: Button Actions

    func startEditingAction() {
        sayElloOverlay.hidden = true
        textView.becomeFirstResponder()
    }

    func cancelEditingAction() {
        takeUndoSnapshot()
        resetEditor()
        updateUndoState()
    }

    func undoCancelAction() {
        currentText = undoText
        textView.attributedText = undoText
        setCurrentImage(undoImage)
        if currentTextIsPresent() {
            startEditingAction()
        }

        undoText = nil
        undoImage = nil
        updateUndoState()
    }

    func submitAction() {
        let text = textView.text
        delegate?.omnibarSubmitted(text)
    }

    func removeButtonAction() {
        userSetCurrentImage(nil)
    }

// MARK: Undo logic

    private func currentTextIsPresent() -> Bool {
        return currentText != nil && countElements(currentText!.string) > 0
    }

    private func currentImageIsPresent() -> Bool {
        return currentImage != nil
    }

    private func undoTextIsPresent() -> Bool {
        return undoText != nil && countElements(undoText!.string) > 0
    }

    private func undoImageIsPresent() -> Bool {
        return undoImage != nil
    }

    private func canUndo() -> Bool {
        if currentTextIsPresent() || currentImageIsPresent() {
            return false
        }

        if undoTextIsPresent() || undoImageIsPresent() {
            return true
        }

        return false
    }

    private func takeUndoSnapshot() {
        undoText = currentText
        undoImage = currentImage
    }

// MARK: Images

    // this action has side effects; disabling undo for example
    func userSetCurrentImage(image : UIImage?) {
        undoImage = nil
        setCurrentImage(image)
    }

    // this updates the currentImage and buttons, but doesn't mess with undo
    func setCurrentImage(image : UIImage?) {
        currentImage = image

        if let image = image {
            cameraButton.removeFromSuperview()
            imageSelectedButton.setBackgroundImage(image, forState: .Normal)
            self.imageSelectedButton.transform = CGAffineTransformIdentity
            imageSelectedButton.alpha = 1
            buttonContainer.insertSubview(imageSelectedButton, atIndex: 0)
        }
        else {
            if imageSelectedButton.superview != nil {
                imageSelectedButton.removeFromSuperview()
                let convertedFrame = convertRect(imageSelectedButton.frame, fromView: buttonContainer)
                imageSelectedButton.frame = convertedFrame
                addSubview(imageSelectedButton)
                UIView.animateWithDuration(0.3) {
                    self.imageSelectedButton.transform = CGAffineTransformMakeScale(0.1, 0.1)
                }
                UIView.animateWithDuration(0.2) {
                    self.imageSelectedButton.alpha = 0
                }
            }
            buttonContainer.insertSubview(cameraButton, atIndex: 0)
        }

        updateUndoState()
        setNeedsLayout()
    }

// MARK: Camera / Image Picker

    func cameraAction() {
        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) {
            let controller = UIImagePickerController()
            controller.sourceType = .SavedPhotosAlbum
            controller.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.SavedPhotosAlbum)!
            controller.allowsEditing = false
            controller.delegate = self
            controller.modalPresentationStyle = .FullScreen
            delegate?.omnibarPresentPicker(controller)
        }
    }

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
    }

    func imagePickerController(controller: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as String
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            userSetCurrentImage(image)
        }
        delegate?.omnibarDismissPicker(controller)
    }

    func imagePickerControllerDidCancel(controller: UIImagePickerController) {
        delegate?.omnibarDismissPicker(controller)
    }

// MARK: Text View editing

    func textViewShouldBeginEditing(textView : UITextView) -> Bool {
        return true
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText: String) -> Bool {
        let newText = NSString(string: textView.text).stringByReplacingCharactersInRange(range, withString: replacementText)
        self.currentText = ElloAttributedString.style(newText)

        updateUndoState()

        return true
    }

}

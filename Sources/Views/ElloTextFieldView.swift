//
//  ElloTextFieldView.swift
//  Ello
//
//  Created by Tony DiPasquale on 3/25/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Foundation

private let ElloTextFieldViewHeight: CGFloat = 89.0

public class ElloTextFieldView: UIView {
    @IBOutlet public weak var label: ElloToggleLabel!
    @IBOutlet public weak var textField: ElloTextField!
    @IBOutlet public weak var errorLabel: ElloErrorLabel!
    @IBOutlet public weak var messageLabel: ElloLabel!

    @IBOutlet private var errorLabelHeight: NSLayoutConstraint!
    @IBOutlet private var messageLabelHeight: NSLayoutConstraint!
    @IBOutlet private var errorAndMessageMarginConstraint: NSLayoutConstraint!
    @IBOutlet private var errorAndBottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet private var errorAndNoMarginConstraint: NSLayoutConstraint!

    public var textFieldDidChange: (String -> ())? {
        didSet {
            textField.addTarget(self, action: "valueChanged", forControlEvents: .EditingChanged)
        }
    }

    var height: CGFloat {
        var height = ElloTextFieldViewHeight
        if hasError {
            height += errorHeight
            if hasMessage {
                height += 20
            }
            else {
                height += 8
            }
        }
        if hasMessage {
            height += messageHeight + 8
        }
        return height
    }

    public var hasError: Bool { return !(errorLabel.text?.isEmpty ?? true) }
    public var hasMessage: Bool { return !(messageLabel.text?.isEmpty ?? true) }
    var errorHeight: CGFloat { return errorLabel.sizeThatFits(CGSize(width: errorLabel.frame.width, height: 0)).height }
    var messageHeight: CGFloat { return messageLabel.sizeThatFits(CGSize(width: messageLabel.frame.width, height: 0)).height }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        let view: UIView = loadFromNib()
        view.frame = bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        addSubview(view)
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let view: UIView = loadFromNib()
        view.frame = bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        addSubview(view)
    }

    override public func updateConstraints() {
        updateErrorConstraints()
        super.updateConstraints()
    }

    func setState(state: ValidationState) {
        textField.setValidationState(state)
    }

    func valueChanged() {
        setNeedsUpdateConstraints()
        textFieldDidChange?(textField.text)
    }

    func setErrorMessage(message: String) {
        errorLabel.setLabelText(message)
        setNeedsUpdateConstraints()
        self.invalidateIntrinsicContentSize()
    }

    func setMessage(message: String) {
        messageLabel.setLabelText(message)
        messageLabel.textColor = UIColor.blackColor()
        setNeedsUpdateConstraints()
        self.invalidateIntrinsicContentSize()
    }

    override public func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.label.layoutIfNeeded()
        self.textField.layoutIfNeeded()
        self.messageLabel.layoutIfNeeded()
        self.errorLabel.layoutIfNeeded()
    }

    override public func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: height)
    }

    private func updateErrorConstraints() {
        errorAndMessageMarginConstraint.active = false
        errorAndBottomMarginConstraint.active = false
        errorAndNoMarginConstraint.active = false

        if hasMessage {
            errorAndMessageMarginConstraint.active = true
        }
        else if hasError {
            errorAndBottomMarginConstraint.active = true
        }
        else {
            errorAndNoMarginConstraint.active = true
        }

        errorLabelHeight.constant = errorHeight
        messageLabelHeight.constant = messageHeight
    }

    func clearState() {
        textField.setValidationState(.None)
        setErrorMessage("")
        setMessage("")
    }
}


public extension ElloTextFieldView {

    class func styleAsUsername(usernameView: ElloTextFieldView) {
        usernameView.label.setLabelText(NSLocalizedString("Username", comment: "username key"))
        usernameView.textField.text = ""
        usernameView.textField.autocapitalizationType = .None
        usernameView.textField.autocorrectionType = .No
        usernameView.textField.spellCheckingType = .No
        usernameView.textField.keyboardAppearance = .Dark
        usernameView.textField.enablesReturnKeyAutomatically = true
        usernameView.textField.returnKeyType = .Next
        usernameView.textField.keyboardType = .ASCIICapable
    }

    class func styleAsEmail(emailView: ElloTextFieldView) {
        emailView.label.setLabelText(NSLocalizedString("Email", comment: "email key"))
        emailView.textField.text = ""
        emailView.textField.autocapitalizationType = .None
        emailView.textField.autocorrectionType = .No
        emailView.textField.spellCheckingType = .No
        emailView.textField.keyboardAppearance = .Dark
        emailView.textField.enablesReturnKeyAutomatically = true
        emailView.textField.returnKeyType = .Next
        emailView.textField.keyboardType = .EmailAddress
    }

    class func styleAsPassword(passwordView: ElloTextFieldView) {
        passwordView.label.setLabelText(NSLocalizedString("Password", comment: "password key"))
        passwordView.textField.autocapitalizationType = .None
        passwordView.textField.autocorrectionType = .No
        passwordView.textField.spellCheckingType = .No
        passwordView.textField.keyboardAppearance = .Dark
        passwordView.textField.enablesReturnKeyAutomatically = true
        passwordView.textField.returnKeyType = .Default
        passwordView.textField.keyboardType = .Default
        passwordView.textField.secureTextEntry = true
    }

}

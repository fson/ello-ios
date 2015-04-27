//
//  SettingsViewController.swift
//  Ello
//
//  Created by Tony DiPasquale on 3/19/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Foundation

public enum SettingsRow: Int {
    case CoverImage
    case AvatarImage
    case ProfileDescription
    case CredentialSettings
    case Name
    case Bio
    case Links
    case PreferenceSettings
    case Unknown
}


public class SettingsContainerViewController: BaseElloViewController {
    @IBOutlet weak public var elloNavBar: ElloNavigationBar!
    @IBOutlet weak public var containerView: UIView!
    @IBOutlet weak var navigationBarTopConstraint: NSLayoutConstraint!
    public var navBarsVisible: Bool = true

    func showNavBars() {
        navigationBarTopConstraint.constant = 0
        self.view.layoutIfNeeded()
    }

    func hideNavBars() {
        navigationBarTopConstraint.constant = -elloNavBar.frame.height - 1
        self.view.layoutIfNeeded()
    }

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SettingsContainerSegue" {
            let settings = segue.destinationViewController as! SettingsViewController
            if navBarsVisible {
                showNavBars()
            }
            else {
                hideNavBars()
            }
            elloNavBar.items = [settings.navigationItem]
            settings.currentUser = currentUser
            settings.scrollLogic.isShowing = navBarsVisible
        }
    }
}


public class SettingsViewController: UITableViewController, ControllerThatMightHaveTheCurrentUser {

    @IBOutlet weak public var avatarImageView: UIView!
    @IBOutlet weak public var profileDescription: ElloLabel!
    @IBOutlet weak public var coverImage: UIImageView!
    @IBOutlet weak public var avatarImage: UIImageView!
    var scrollLogic: ElloScrollLogic!

    @IBOutlet weak var nameTextFieldView: ElloTextFieldView!
    @IBOutlet weak var linksTextFieldView: ElloTextFieldView!

    public var currentUser: User? {
        didSet {
            credentialSettingsViewController?.currentUser = currentUser
            dynamicSettingsViewController?.currentUser = currentUser
        }
    }

    var credentialSettingsViewController: CredentialSettingsViewController?
    var dynamicSettingsViewController: DynamicSettingsViewController?
    var photoSaveCallback: (UIImage -> ())?

    override public func awakeFromNib() {
        super.awakeFromNib()
        setupNavigationBar()
        scrollLogic = ElloScrollLogic(
            onShow: self.showNavBars,
            onHide: self.hideNavBars
        )
    }

    var elloTabBarController: ElloTabBarController? {
        return findViewController { vc in vc is ElloTabBarController } as! ElloTabBarController?
    }
    var containerController: SettingsContainerViewController? {
        return findViewController { vc in vc is SettingsContainerViewController } as! SettingsContainerViewController?
    }

    func showNavBars(scrollToBottom : Bool) {
        if let tabBarController = self.elloTabBarController {
            tabBarController.setTabBarHidden(false, animated: true)
        }

        containerController?.showNavBars()
        self.view.layoutIfNeeded()
    }

    func hideNavBars() {
        if let tabBarController = self.elloTabBarController {
            tabBarController.setTabBarHidden(true, animated: true)
        }

        containerController?.hideNavBars()
        self.view.layoutIfNeeded()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        containerController?.showNavBars()
        setupProfileDescription()
        setupDefaultValues()
    }

    private func setupProfileDescription() {
        let text = NSMutableAttributedString(attributedString: profileDescription.attributedText)

        text.addAttribute(NSForegroundColorAttributeName, value: UIColor.greyA(), range: NSRange(location: 0, length: text.length))
        profileDescription.attributedText = text
    }

    private func setupNavigationBar() {
        let backItem = UIBarButtonItem.backChevronWithTarget(self, action: "backAction")
        navigationItem.leftBarButtonItem = backItem
        navigationItem.title = NSLocalizedString("Settings", comment: "settings title")
        navigationItem.fixNavBarItemPadding()
    }

    private func setupDefaultValues() {
        currentUser?.coverImageURL.map(coverImage.sd_setImageWithURL)
        (currentUser?.avatar?.large?.url).map(avatarImage.sd_setImageWithURL)
        nameTextFieldView.label.setLabelText("Name")
        nameTextFieldView.textField.text = currentUser?.name

        let updateNameFunction = Functional.debounce(0.5) {
            let name = self.nameTextFieldView.textField.text
            ProfileService().updateUserProfile(["name": name], success: { user, responseConfig in
                if let nav = self.navigationController as? ElloNavigationController {
                    nav.setProfileData(user, responseConfig: responseConfig)
                    self.nameTextFieldView.setState(.OK)
                } else {
                    self.nameTextFieldView.setState(.Error)
                }
            }) { _, _ in
                self.nameTextFieldView.setState(.Error)
            }
        }

        nameTextFieldView.textFieldDidChange = { _ in
            self.nameTextFieldView.setState(.Loading)
            updateNameFunction()
        }

        linksTextFieldView.label.setLabelText("Links")
        linksTextFieldView.textField.text = (currentUser?.profile?.externalLinksList).map { " ".join($0) }

        let updateLinksFunction = Functional.debounce(0.5) {
            let links = self.linksTextFieldView.textField.text
            ProfileService().updateUserProfile(["external_links": links], success: { user, responseConfig in
                if let nav = self.navigationController as? ElloNavigationController {
                    nav.setProfileData(user, responseConfig: responseConfig)
                    self.linksTextFieldView.setState(.OK)
                } else {
                    self.linksTextFieldView.setState(.Error)
                }
            }) { _, _ in
                self.linksTextFieldView.setState(.Error)
            }
        }

        linksTextFieldView.textFieldDidChange = { _ in
            self.linksTextFieldView.setState(.Loading)
            updateLinksFunction()
        }
    }

    func backAction() {
        navigationController?.popViewControllerAnimated(true)
    }

    override public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch SettingsRow(rawValue: indexPath.row) ?? .Unknown {
        case .CoverImage: return 200
        case .AvatarImage: return 250
        case .ProfileDescription: return 130
        case .CredentialSettings: return credentialSettingsViewController?.height ?? 0
        case .Name: return 97
        case .Bio: return 200
        case .Links: return 97
        case .PreferenceSettings: return dynamicSettingsViewController?.height ?? 0
        case .Unknown: return 0
        }
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "" {
        case "CredentialSettingsSegue":
            credentialSettingsViewController = segue.destinationViewController as? CredentialSettingsViewController
            credentialSettingsViewController?.currentUser = currentUser
            credentialSettingsViewController?.delegate = self

        case "DynamicSettingsSegue":
            dynamicSettingsViewController = segue.destinationViewController as? DynamicSettingsViewController
            dynamicSettingsViewController?.currentUser = currentUser

        default: break
        }
    }

    @IBAction func logOutTapped(sender: ElloTextButton) {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.UserLoggedOut.rawValue, object: nil)
    }

    @IBAction func coverImageTapped() {
        photoSaveCallback = { image in
            ElloHUD.showLoadingHud()
            ProfileService().updateUserCoverImage(image, success: { _, _ in
                ElloHUD.hideLoadingHud()
                self.alertUserOfImageProcessing()
            }) { _, _ in
                ElloHUD.hideLoadingHud()
            }
        }
        openImagePicker()
    }

    @IBAction func avatarImageTapped() {
        photoSaveCallback = { image in
            ElloHUD.showLoadingHud()
            ProfileService().updateUserAvatarImage(image, success: { user, responseConfig in
                ElloHUD.hideLoadingHud()
                self.alertUserOfImageProcessing()
            }) { _, _ in
                ElloHUD.hideLoadingHud()
            }
        }
        openImagePicker()
    }

    private func openImagePicker() {
        let alertViewController = alertControllerForImagePicker { imagePicker in
            imagePicker.delegate = self
            self.presentViewController(imagePicker, animated: true, completion: .None)
        }

        if let alertViewController = alertViewController {
            self.presentViewController(alertViewController, animated: true, completion: .None)
        }
    }

    private func alertUserOfImageProcessing() {
        let message = NSLocalizedString("Copy needed to explain caching of old avatar", comment: "Copy needed to explain caching of old avatar")
        let alert = AlertViewController(message: message, textAlignment: .Center, dismissable: true, type: .Normal)
        let action = AlertAction(title: NSLocalizedString("OK", comment: "ok"), style: .Light, handler: .None)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: .None)
    }
}

extension SettingsViewController: CredentialSettingsDelegate {
    public func credentialSettingsDidUpdate() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let oriented = image.copyWithCorrectOrientation()
            self.photoSaveCallback?(oriented)
        }
        self.dismissViewControllerAnimated(true, completion: .None)
    }
    
    public func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: .None)
    }
}

public extension SettingsViewController {
    class func instantiateFromStoryboard() -> SettingsViewController {
        return UIStoryboard(name: "Settings", bundle: NSBundle(forClass: AppDelegate.self)).instantiateInitialViewController() as! SettingsViewController
    }
}


// strangely, we have to "override" these delegate methods, but the parent class
// UITableViewController doesn't implement them.
extension SettingsViewController: UIScrollViewDelegate {

    public override func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollLogic.scrollViewDidScroll(scrollView)
    }

    public override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollLogic.scrollViewWillBeginDragging(scrollView)
    }

    public override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate: Bool) {
        scrollLogic.scrollViewDidEndDragging(scrollView, willDecelerate: willDecelerate)
    }

}

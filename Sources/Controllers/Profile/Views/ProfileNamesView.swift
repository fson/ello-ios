////
///  ProfileNamesView.swift
//

public class ProfileNamesView: ProfileBaseView {
    public struct Size {
        static let horizNameMargin: CGFloat = 10
        static let vertNameMargin: CGFloat = 5
        static let outerMargins = UIEdgeInsets(tops: 20, sides: 10)
    }
    static let nameFont = UIFont.defaultFont(18)
    static let usernameFont = UIFont.defaultFont()

    static public func preferredHeight(nameSize nameSize: CGSize, usernameSize: CGSize, maxWidth: CGFloat) -> (CGFloat, isVertical: Bool) {
        let bothNamesWidth = nameSize.width + usernameSize.width + Size.horizNameMargin
        let maxAllowedWidth = maxWidth - Size.outerMargins.left - Size.outerMargins.right
        if bothNamesWidth > maxAllowedWidth {
            let height = nameSize.height + usernameSize.height + Size.vertNameMargin
            return (height, isVertical: true)
        }
        else {
            let height = max(nameSize.height, usernameSize.height)
            return (height, isVertical: false)
        }
    }

    public var name: String {
        get { return nameLabel.text ?? "" }
        set {
            nameLabel.text = newValue
            nameLabel.sizeToFit()
            nameLabel.frame.size.height = 24
            setNeedsLayout()
        }
    }
    public var username: String {
        get { return usernameLabel.text ?? "" }
        set {
            usernameLabel.text = newValue
            usernameLabel.sizeToFit()
            usernameLabel.frame.size.height = 20
            setNeedsLayout()
        }
    }

    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
}

extension ProfileNamesView {

    override func style() {
        nameLabel.font = ProfileNamesView.nameFont
        nameLabel.textColor = .blackColor()
        usernameLabel.font = ProfileNamesView.usernameFont
        usernameLabel.textColor = .greyA()
    }

    override func arrange() {
        addSubview(nameLabel)
        addSubview(usernameLabel)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.frame.origin.y = Size.outerMargins.top

        let (_, isVertical) = ProfileNamesView.preferredHeight(nameSize: nameLabel.frame.size, usernameSize: usernameLabel.frame.size, maxWidth: frame.width)
        if isVertical {
            nameLabel.frame.origin.x = (frame.width - nameLabel.frame.width) / 2
            usernameLabel.frame.origin = CGPoint(
                x: (frame.width - usernameLabel.frame.width) / 2,
                y: nameLabel.frame.maxY + Size.vertNameMargin
                )
        }
        else {
            nameLabel.frame.origin.x = (frame.width - nameLabel.frame.width - usernameLabel.frame.width - Size.horizNameMargin) / 2
            usernameLabel.frame.origin = CGPoint(
                x: nameLabel.frame.maxX + Size.horizNameMargin,
                y: nameLabel.frame.maxY - usernameLabel.frame.height - 1
                )
        }
    }
}

extension ProfileNamesView: ProfileViewProtocol {}
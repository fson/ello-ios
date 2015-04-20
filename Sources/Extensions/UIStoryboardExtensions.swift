//
//  UIStoryboardExtensions.swift
//  Ello
//
//  Created by Sean Dougherty on 11/21/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

import UIKit

public extension UIStoryboard {

    class func storyboardWithId(identifier:StoryboardIdentifier) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: NSBundle(forClass: AppDelegate.self)).instantiateViewControllerWithIdentifier(identifier.rawValue) as! UIViewController
    }
}

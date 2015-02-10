//
//  ElloTabBarController.swift
//  Ello
//
//  Created by Sean Dougherty on 11/22/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

import UIKit

class ElloTabBarController: UITabBarController {

    var currentUser : User? {
        didSet { assignCurrentUser() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = 2
        modalTransitionStyle = .CrossDissolve
    }

    func assignCurrentUser() {
        for controller in self.childViewControllers {
            if let controller = controller as? BaseElloViewController {
                controller.currentUser = self.currentUser
            }
            else if let controller = controller as? ElloNavigationController {
                controller.currentUser = self.currentUser
            }
        }
    }

    class func instantiateFromStoryboard(storyboard: UIStoryboard = UIStoryboard.iPhone()) -> ElloTabBarController {
        return storyboard.controllerWithID(.ElloTabBar) as ElloTabBarController
    }
}

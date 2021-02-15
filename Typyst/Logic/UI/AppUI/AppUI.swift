//
//  AppUI.swift
//  Typyst
//
//  Created by Sean Wolford on 2/1/20.
//  Copyright © 2020 wickedPropeller. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class AppUI {
    var alerts = Alerts()
    var appMenu: AppMenu?
    var appMenuBar: AppMenuBar?

    init() {

    }

    func setup() {
        appMenu = AppMenu()
        appMenu?.constructMenu()
        if let menu = appMenu?.menu {
            NSApp.mainMenu = menu
            appMenuBar = AppMenuBar(menu: menu)
        }
    }
}

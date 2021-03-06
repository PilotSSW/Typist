//
//  SettingsMenu.swift
//  Typyst
//
//  Created by Sean Wolford on 3/8/21.
//  Copyright © 2021 wickedPropeller. All rights reserved.
//

import SwiftUI

struct SettingsMenu: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer(minLength: 8)
            SettingsMenuHeader()
            SettingsCard()
            Spacer(minLength: 8)
        }
        .asParentCard(withColor: AppColor.primaryBackground)
    }
}

struct SettingsMenu_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMenu()
            .frame(width: 400.0)
    }
}

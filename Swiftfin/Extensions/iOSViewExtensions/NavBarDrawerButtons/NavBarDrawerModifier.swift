//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavBarDrawerModifier<Drawer: View>: ViewModifier {

    let drawer: () -> Drawer

    init(@ViewBuilder drawer: @escaping () -> Drawer) {
        self.drawer = drawer
    }

    func body(content: Content) -> some View {
        NavBarDrawerView {
            drawer()
                .ignoresSafeArea()
        } content: {
            content
        }
        .ignoresSafeArea()
    }
}

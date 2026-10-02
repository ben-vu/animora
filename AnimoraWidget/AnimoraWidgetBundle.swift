//
//  AnimoraWidgetBundle.swift
//  AnimoraWidget
//
//  Created by Benjamin Vu on 30/9/2026.
//

import WidgetKit
import SwiftUI

/// Every widget Animora offers. There is only one for now, but a bundle means another
/// can be added later without touching this one.
@main
struct AnimoraWidgetBundle: WidgetBundle {
    var body: some Widget {
        UpNextWidget()
    }
}

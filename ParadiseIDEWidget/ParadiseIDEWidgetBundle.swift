import SwiftUI
import WidgetKit

@main
struct ParadiseIDEWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.2, *) {
            ParadiseIDELiveActivity()
        }
    }
}

import AppKit
import SwiftUI

struct FloatingWindowConfigurator: NSViewRepresentable {
    var keepOnTop = false
    var movableByBackground = false
    var transparentBackground = false

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            if keepOnTop {
                window.level = .floating
            }
            window.isMovableByWindowBackground = movableByBackground
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.styleMask.remove(.resizable)
            if transparentBackground {
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = false
            }
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {

    }
}

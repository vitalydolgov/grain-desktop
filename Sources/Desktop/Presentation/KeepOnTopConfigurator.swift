import AppKit
import SwiftUI

struct KeepOnTopConfigurator: NSViewRepresentable {
    var movableByBackground = false

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.level = .floating
            window.isMovableByWindowBackground = movableByBackground
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.styleMask.remove(.resizable)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

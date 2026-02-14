import AppKit

final class FnHotkeyMonitor {
    var onFnDown: (() -> Void)?
    var onFnUp: (() -> Void)?

    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var fnPressed = false

    func start() {
        stop()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event: event)
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event: event)
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        fnPressed = false
    }

    deinit {
        stop()
    }

    private func handle(event: NSEvent) {
        let isFnPressedNow = event.modifierFlags.contains(.function)
        if isFnPressedNow == fnPressed { return }
        fnPressed = isFnPressedNow

        if isFnPressedNow {
            onFnDown?()
        } else {
            onFnUp?()
        }
    }
}

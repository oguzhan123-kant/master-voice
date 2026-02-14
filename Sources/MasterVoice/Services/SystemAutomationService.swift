import Foundation
import AppKit
import AVFoundation
import MasterVoiceCore

final class SystemAutomationService {
    private let speechSynthesizer = AVSpeechSynthesizer()

    func switchToApp(named appName: String) -> Bool {
        let normalizedTarget = appName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedTarget.isEmpty else { return false }

        if let running = NSWorkspace.shared.runningApplications.first(where: {
            ($0.localizedName ?? "").lowercased() == normalizedTarget
        }) {
            return running.activate(options: [.activateIgnoringOtherApps])
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appName]
        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    func typeText(_ text: String) -> Bool {
        guard !text.isEmpty else { return true }
        let pasteboard = NSPasteboard.general
        let backup = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let pasted = sendKeystroke(keyCode: 9, flags: .maskCommand) // Cmd+V

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let backup {
                pasteboard.clearContents()
                pasteboard.setString(backup, forType: .string)
            }
        }
        return pasted
    }

    func sendMessage(frontmostApp: String) -> Bool {
        let binding = sendBinding(for: frontmostApp)
        switch binding {
        case .enter:
            return sendKeystroke(keyCode: 36)
        case .commandEnter:
            return sendKeystroke(keyCode: 36, flags: .maskCommand)
        }
    }

    func captureSelectedText() async -> String? {
        let pasteboard = NSPasteboard.general
        let backup = pasteboard.string(forType: .string)
        _ = sendKeystroke(keyCode: 8, flags: .maskCommand) // Cmd+C

        try? await Task.sleep(nanoseconds: 180_000_000)
        let selected = pasteboard.string(forType: .string)

        if let backup {
            pasteboard.clearContents()
            pasteboard.setString(backup, forType: .string)
        }

        guard let selected, !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return selected
    }

    func summarize(_ text: String) -> String {
        let clean = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        guard clean.count > 220 else { return clean }
        let prefix = clean.prefix(220)
        return "\(prefix)..."
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        speechSynthesizer.speak(utterance)
    }

    private func sendBinding(for app: String) -> SendKeyBinding {
        switch app.lowercased() {
        case "slack":
            return .enter
        default:
            return .enter
        }
    }

    @discardableResult
    private func sendKeystroke(keyCode: CGKeyCode, flags: CGEventFlags = []) -> Bool {
        guard
            let source = CGEventSource(stateID: .combinedSessionState),
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else {
            return false
        }

        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}

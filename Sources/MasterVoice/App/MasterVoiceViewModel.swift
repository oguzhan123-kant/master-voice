import Foundation
import AppKit
import MasterVoiceCore

@MainActor
final class MasterVoiceViewModel: ObservableObject {
    @Published var mode: VoiceMode = .idle
    @Published var isListening = false
    @Published var liveTranscript = ""
    @Published var statusLine = "Booting..."
    @Published var lastIntentLine = "-"
    @Published var frontmostAppName = "-"
    @Published var permissions = PermissionStatus.empty

    private let parser = IntentParser()
    private var modeController = ModeController()
    private let permissionService = PermissionService()
    private let speechService = SpeechRecognizerService()
    private let hotkeyMonitor = FnHotkeyMonitor()
    private let systemAutomation = SystemAutomationService()
    private let actionEngine = ActionEngine(sendBindings: [
        "Slack": .enter,
        "Codex": .enter,
        "ChatGPT": .enter
    ])

    private var didStart = false
    private var sessionTranscript = ""
    private var processedTranscriptInSession = false

    func startup() async {
        guard !didStart else { return }
        didStart = true

        hotkeyMonitor.onFnDown = { [weak self] in
            Task { @MainActor in
                self?.handleFnDown()
            }
        }
        hotkeyMonitor.onFnUp = { [weak self] in
            Task { @MainActor in
                self?.handleFnUp()
            }
        }
        hotkeyMonitor.start()

        speechService.onTranscript = { [weak self] transcript, isFinal in
            Task { @MainActor in
                self?.handleTranscript(transcript, isFinal: isFinal)
            }
        }

        permissions = permissionService.currentStatus()
        refreshFrontmostApp()
        statusLine = "Ready. Press Fn to start/stop listening."
    }

    func requestPermissions() async {
        let result = await permissionService.requestAndRefresh()
        permissions = result.status

        if let note = result.note {
            statusLine = note
            permissionService.openPrivacySettings()
            return
        }

        if permissions.allRequiredGranted {
            statusLine = "Permissions granted."
        } else {
            statusLine = "Grant missing permissions, then retry."
        }
    }

    func setMode(_ newMode: VoiceMode) {
        modeController.transition(to: newMode)
        mode = newMode
        statusLine = "Mode switched to \(newMode.rawValue)."
    }

    func resetIdle() {
        modeController.transition(to: .idle)
        mode = .idle
        statusLine = "Mode reset to idle."
    }

    func forceStartListening() {
        startListeningSession(trigger: "manual")
    }

    func forceStopListening() {
        stopListeningSession(trigger: "manual")
    }

    private func handleFnDown() {
        if isListening {
            stopListeningSession(trigger: "fn-toggle")
        } else {
            startListeningSession(trigger: "fn-toggle")
        }
    }

    private func handleFnUp() {
        // Fn release no-op in toggle mode.
    }

    private func startListeningSession(trigger: String) {
        if isListening { return }
        refreshFrontmostApp()
        permissions = permissionService.currentStatus()

        guard permissions.microphone && permissions.speech else {
            statusLine = "Microphone + Speech permission required before listening."
            return
        }

        if modeController.mode == .idle {
            modeController.transition(to: .dictation)
        }

        do {
            try speechService.startListening()
            isListening = true
            mode = modeController.mode
            sessionTranscript = ""
            processedTranscriptInSession = false
            statusLine = "Listening (\(mode.rawValue)) via \(trigger)."
        } catch {
            statusLine = "Listening failed: \(error.localizedDescription)"
        }
    }

    private func stopListeningSession(trigger: String) {
        guard isListening else { return }
        speechService.stopListening()
        isListening = false

        let fallback = sessionTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !processedTranscriptInSession && !fallback.isEmpty {
            processAndMarkTranscript(fallback)
        } else {
            statusLine = "Stopped listening via \(trigger)."
        }
    }

    private func handleTranscript(_ transcript: String, isFinal: Bool) {
        liveTranscript = transcript
        sessionTranscript = transcript
        guard isFinal else { return }
        processAndMarkTranscript(transcript)
    }

    private func processAndMarkTranscript(_ transcript: String) {
        processedTranscriptInSession = true
        processTranscript(transcript)
    }

    private func processTranscript(_ transcript: String) {
        let cleaned = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            lastIntentLine = "-"
            statusLine = "No speech detected."
            return
        }

        let parsingMode: VoiceMode = modeController.mode == .idle ? .dictation : modeController.mode
        let intent = parser.parse(input: cleaned, mode: parsingMode)
        lastIntentLine = intent.description
        execute(intent: intent)
    }

    private func execute(intent: Intent) {
        switch intent {
        case .switchMode(let newMode):
            modeController.transition(to: newMode)
            mode = newMode
            statusLine = "Mode switched to \(newMode.rawValue)."

        case .switchApp(let appName):
            let result = systemAutomation.switchToApp(named: appName)
            statusLine = result ? "Switched to \(appName)." : "App not found: \(appName)"
            refreshFrontmostApp()

        case .send:
            refreshFrontmostApp()
            let plan = actionEngine.plan(for: .send, frontmostApp: frontmostAppName)
            let success = systemAutomation.sendMessage(frontmostApp: frontmostAppName)
            statusLine = success ? plan.description : "Send failed. Check Accessibility/Input Monitoring."

        case .cancel:
            speechService.stopListening()
            isListening = false
            modeController.transition(to: .idle)
            mode = .idle
            statusLine = "Cancelled. Back to idle."

        case .readSelection:
            Task {
                if let selected = await systemAutomation.captureSelectedText() {
                    systemAutomation.speak(selected)
                    await MainActor.run {
                        self.statusLine = "Read selection (\(selected.count) chars)."
                    }
                } else {
                    await MainActor.run {
                        self.statusLine = "No selected text found."
                    }
                }
            }

        case .summarizeSelection:
            Task {
                if let selected = await systemAutomation.captureSelectedText() {
                    let summary = systemAutomation.summarize(selected)
                    systemAutomation.speak(summary)
                    await MainActor.run {
                        self.statusLine = "Summary: \(summary)"
                    }
                } else {
                    await MainActor.run {
                        self.statusLine = "No selected text to summarize."
                    }
                }
            }

        case .dictate(let text):
            let ok = systemAutomation.typeText(text)
            statusLine = ok ? "Typed text (\(text.count) chars)." : "Typing failed."

        case .unknown(let raw):
            statusLine = "Unknown command: \(raw). Try: gonder, slack'e gec, komut modu, dikte modu."
        }
    }

    private func refreshFrontmostApp() {
        frontmostAppName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }
}

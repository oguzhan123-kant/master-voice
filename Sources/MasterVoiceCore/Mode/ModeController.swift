public struct ModeController {
    public private(set) var mode: VoiceMode = .idle

    public init(mode: VoiceMode = .idle) {
        self.mode = mode
    }

    public mutating func transition(to newMode: VoiceMode) {
        mode = newMode
    }

    public mutating func onFnPress() {
        if mode == .idle {
            mode = .dictation
        }
    }

    public mutating func onFnRelease() {
        if mode == .dictation {
            mode = .idle
        }
    }
}

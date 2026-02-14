public enum Intent: Equatable, CustomStringConvertible {
    case switchMode(VoiceMode)
    case switchApp(name: String)
    case send
    case cancel
    case readSelection
    case summarizeSelection
    case dictate(text: String)
    case unknown(raw: String)

    public var description: String {
        switch self {
        case .switchMode(let mode):
            return "switchMode(\(mode.rawValue))"
        case .switchApp(let name):
            return "switchApp(\(name))"
        case .send:
            return "send"
        case .cancel:
            return "cancel"
        case .readSelection:
            return "readSelection"
        case .summarizeSelection:
            return "summarizeSelection"
        case .dictate(let text):
            return "dictate(\(text))"
        case .unknown(let raw):
            return "unknown(\(raw))"
        }
    }
}

public enum SendKeyBinding: String, Equatable {
    case enter
    case commandEnter
}

public struct ActionPlan: Equatable {
    public let description: String
    public init(description: String) {
        self.description = description
    }
}

public struct ActionEngine {
    private let sendBindings: [String: SendKeyBinding]

    public init(sendBindings: [String: SendKeyBinding]) {
        self.sendBindings = sendBindings
    }

    public func plan(for intent: Intent, frontmostApp: String?) -> ActionPlan {
        switch intent {
        case .send:
            let app = frontmostApp ?? "Generic"
            let binding = sendBindings[app] ?? .enter
            return ActionPlan(description: "Send via \(binding.rawValue) in \(app)")
        case .switchApp(let name):
            return ActionPlan(description: "Switch app to \(name)")
        case .readSelection:
            return ActionPlan(description: "Read selected text")
        case .summarizeSelection:
            return ActionPlan(description: "Summarize selected text")
        case .cancel:
            return ActionPlan(description: "Cancel current flow")
        case .switchMode(let mode):
            return ActionPlan(description: "Switch mode to \(mode.rawValue)")
        case .dictate(let text):
            return ActionPlan(description: "Type dictated text (\(text.count) chars)")
        case .unknown(let raw):
            return ActionPlan(description: "No action for unknown input: \(raw)")
        }
    }
}

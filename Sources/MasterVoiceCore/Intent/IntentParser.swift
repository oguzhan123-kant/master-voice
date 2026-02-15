import Foundation

public struct IntentParser {
    public init() {}

    public func parse(input: String, mode: VoiceMode) -> Intent {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInput.isEmpty {
            return .unknown(raw: input)
        }

        let normalized = normalize(trimmedInput)

        switch normalized {
        case "komut modu", "command mode", "komut", "command":
            return .switchMode(.command)
        case "dikte modu", "dictation mode", "dictate mode", "yazma modu":
            return .switchMode(.dictation)
        case "okuma modu", "read mode", "reading mode":
            return .switchMode(.read)
        case "iptal", "cancel", "stop", "vazgec":
            return .cancel
        case "gonder", "mesaji gonder", "send", "send message", "submit":
            return .send
        case "bunu oku", "secili metni oku", "read this", "read selection", "read selected text":
            return .readSelection
        case "ozetle", "secili metni ozetle", "summarize", "summarize this", "summarize selection":
            return .summarizeSelection
        default:
            break
        }

        if normalized.hasPrefix("yaz:") {
            let text = String(trimmedInput.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                return .dictate(text: text)
            }
        }

        if normalized.hasPrefix("write:") {
            let text = String(trimmedInput.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                return .dictate(text: text)
            }
        }

        if let appName = extractAppSwitchName(from: trimmedInput) {
            return .switchApp(name: appName)
        }

        if mode == .dictation {
            return .dictate(text: trimmedInput)
        }

        return .unknown(raw: input)
    }

    private func extractAppSwitchName(from input: String) -> String? {
        let normalized = normalize(input)

        if let app = extractByPrefix(normalized, prefix: "open ") {
            return app
        }
        if let app = extractByPrefix(normalized, prefix: "switch to ") {
            return app
        }
        if let app = extractByPrefix(normalized, prefix: "go to ") {
            return app
        }
        if let app = extractByPrefix(normalized, prefix: "ac ") {
            return app
        }

        for suffix in ["e gec", "a gec", "e git", "a git"] {
            if let app = extractBySuffix(normalized, suffix: suffix) {
                return app
            }
        }

        return nil
    }

    private func extractByPrefix(_ normalized: String, prefix: String) -> String? {
        guard normalized.hasPrefix(prefix) else { return nil }
        let raw = String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        return canonicalAppName(raw)
    }

    private func extractBySuffix(_ normalized: String, suffix: String) -> String? {
        guard normalized.hasSuffix(suffix) else { return nil }
        let cut = normalized.count - suffix.count
        let base = String(normalized.prefix(cut)).trimmingCharacters(in: .whitespaces)
        return canonicalAppName(base)
    }

    private func canonicalAppName(_ raw: String) -> String? {
        let app = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if app.isEmpty { return nil }
        let blocked = Set([
            "komut", "command", "mode", "modu", "dikte", "dictation", "okuma", "read",
            "gonder", "send", "iptal", "cancel"
        ])
        if blocked.contains(app) { return nil }
        return app
    }

    private func normalize(_ text: String) -> String {
        let mapped = text
            .replacingOccurrences(of: "İ", with: "i")
            .replacingOccurrences(of: "I", with: "i")
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "Ş", with: "s")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "Ğ", with: "g")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "Ü", with: "u")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "Ö", with: "o")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "Ç", with: "c")
            .replacingOccurrences(of: "ç", with: "c")

        let text = mapped
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "'", with: "")
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "tr_TR"))

        let allowed = text.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || CharacterSet.whitespaces.contains(scalar) || scalar == ":" {
                return Character(scalar)
            }
            return " "
        }

        return String(allowed)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }
}

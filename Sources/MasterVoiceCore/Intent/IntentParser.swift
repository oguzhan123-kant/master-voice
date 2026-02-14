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
        case "komut modu":
            return .switchMode(.command)
        case "dikte modu":
            return .switchMode(.dictation)
        case "okuma modu":
            return .switchMode(.read)
        case "iptal":
            return .cancel
        case "gonder", "mesaji gonder":
            return .send
        case "bunu oku", "secili metni oku":
            return .readSelection
        case "ozetle", "secili metni ozetle":
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

        if let appName = extractAppSwitchName(from: trimmedInput) {
            return .switchApp(name: appName)
        }

        if mode == .dictation {
            return .dictate(text: trimmedInput)
        }

        return .unknown(raw: input)
    }

    private func extractAppSwitchName(from input: String) -> String? {
        let lower = normalize(input)

        if lower.hasSuffix("e gec") {
            return recoverAppName(from: input, suffix: "e geç")
        }

        if lower.hasSuffix("a gec") {
            return recoverAppName(from: input, suffix: "a geç")
        }

        if lower.hasSuffix("gec") {
            let parts = input.split(separator: " ")
            guard parts.count >= 2 else { return nil }
            let appName = parts.dropLast().joined(separator: " ").trimmingCharacters(in: .whitespaces)
            return appName.isEmpty ? nil : appName
        }

        return nil
    }

    private func recoverAppName(from original: String, suffix: String) -> String? {
        let cleaned = original
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.lowercased().hasSuffix(suffix) else { return nil }
        let endIndex = cleaned.index(cleaned.endIndex, offsetBy: -suffix.count)
        var base = String(cleaned[..<endIndex]).trimmingCharacters(in: .whitespaces)
        if base.hasSuffix("'") {
            base.removeLast()
        }
        return base.isEmpty ? nil : base
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

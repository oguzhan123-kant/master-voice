import Foundation
import AVFoundation
import Speech
import ApplicationServices
import AppKit

struct PermissionStatus {
    let microphone: Bool
    let speech: Bool
    let accessibility: Bool

    static let empty = PermissionStatus(microphone: false, speech: false, accessibility: false)

    var allRequiredGranted: Bool {
        microphone && speech && accessibility
    }
}

struct PermissionRefreshResult {
    let status: PermissionStatus
    let note: String?
}

final class PermissionService {
    func currentStatus() -> PermissionStatus {
        PermissionStatus(
            microphone: AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
            speech: SFSpeechRecognizer.authorizationStatus() == .authorized,
            accessibility: AXIsProcessTrusted()
        )
    }

    func requestAndRefresh() async -> PermissionRefreshResult {
        let readiness = promptReadiness()

        // Some launch contexts (especially swift-run executables) can fail hard on TCC requests.
        // If usage strings / bundle metadata are not visible to the process, skip risky APIs.
        guard readiness.isSafeToPrompt else {
            let status = currentStatus()
            return PermissionRefreshResult(
                status: status,
                note: "Runtime permission prompts are not safe in this launch context (\(readiness.reason)). Open Privacy settings and grant access manually."
            )
        }

        // Safe path for app-bundle execution.
        let mic = await requestMicrophone()
        let speech = await requestSpeech()
        let accessibility = requestAccessibility(prompt: true)
        let status = PermissionStatus(
            microphone: mic,
            speech: speech,
            accessibility: accessibility
        )
        return PermissionRefreshResult(
            status: status,
            note: nil
        )
    }

    private func requestMicrophone() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeech() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestAccessibility(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openPrivacySettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]

        for raw in urls {
            if let url = URL(string: raw) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func promptReadiness() -> (isSafeToPrompt: Bool, reason: String) {
        if Bundle.main.bundleURL.pathExtension.lowercased() != "app" {
            return (false, "process is not running as .app bundle")
        }

        let micUsage = (Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let speechUsage = (Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let bundleIdentifier = Bundle.main.bundleIdentifier?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if micUsage?.isEmpty != false {
            return (false, "missing NSMicrophoneUsageDescription")
        }
        if speechUsage?.isEmpty != false {
            return (false, "missing NSSpeechRecognitionUsageDescription")
        }
        if bundleIdentifier?.isEmpty != false {
            return (false, "missing bundle identifier")
        }
        return (true, "ok")
    }
}

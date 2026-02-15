import SwiftUI
import MasterVoiceCore

struct ContentView: View {
    @ObservedObject var viewModel: MasterVoiceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            permissionPanel
            transcriptPanel
            logPanel
            controls
            Spacer()
        }
        .padding(16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Master Voice")
                .font(.title.bold())
            Text("Press Fn to start/stop listening. Modes: dictation / command / read.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                label(title: "Mode", value: viewModel.mode.rawValue)
                label(title: "Listening", value: viewModel.isListening ? "yes" : "no")
                label(title: "Front app", value: viewModel.frontmostAppName)
                label(title: "Last intent", value: viewModel.lastIntentLine)
            }
        }
    }

    private var permissionPanel: some View {
        GroupBox("Permissions") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Microphone: \(viewModel.permissions.microphone ? "granted" : "missing")")
                Text("Speech: \(viewModel.permissions.speech ? "granted" : "missing")")
                Text("Accessibility: \(viewModel.permissions.accessibility ? "granted" : "missing")")
                Text("Input Monitoring: grant manually in System Settings if key events fail.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Request / Refresh Permissions") {
                    Task { await viewModel.requestPermissions() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var transcriptPanel: some View {
        GroupBox("Live Transcript") {
            Text(viewModel.liveTranscript.isEmpty ? "No speech yet." : viewModel.liveTranscript)
                .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
        }
    }

    private var logPanel: some View {
        GroupBox("Status") {
            Text(viewModel.statusLine)
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button("Force Start Listening") {
                viewModel.forceStartListening()
            }
            Button("Force Stop Listening") {
                viewModel.forceStopListening()
            }
            Button("Set Dictation") {
                viewModel.setMode(.dictation)
            }
            Button("Set Command") {
                viewModel.setMode(.command)
            }
            Button("Reset Idle") {
                viewModel.resetIdle()
            }
        }
    }

    private func label(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(title):")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospaced())
        }
    }
}

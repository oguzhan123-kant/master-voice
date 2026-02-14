import Foundation
import MasterVoiceCore

let parser = IntentParser()
var modeController = ModeController()

print("Master Voice CLI ready.")
print("Type input (or 'exit'). Current mode: \(modeController.mode.rawValue)")

while let line = readLine() {
    if line.lowercased() == "exit" {
        break
    }

    let intent = parser.parse(input: line, mode: modeController.mode)
    if case .switchMode(let newMode) = intent {
        modeController.transition(to: newMode)
    }

    print("Intent: \(intent)")
    print("Mode: \(modeController.mode.rawValue)")
}

import Foundation
import AVFoundation
import Speech

final class SpeechRecognizerService {
    var onTranscript: ((String, Bool) -> Void)?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR")) ?? SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var tapInstalled = false

    func startListening() throws {
        stopListening()

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw NSError(
                domain: "MasterVoice.Speech",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable."]
            )
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        self.recognitionRequest = recognitionRequest

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        tapInstalled = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.onTranscript?(result.bestTranscription.formattedString, result.isFinal)
            }
            if error != nil {
                self.stopListening()
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    deinit {
        stopListening()
    }
}

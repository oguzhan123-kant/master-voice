import XCTest
@testable import MasterVoiceCore

final class IntentParserTests: XCTestCase {
    private let parser = IntentParser()

    func testModeSwitchCommand() {
        let intent = parser.parse(input: "komut modu", mode: .dictation)
        XCTAssertEqual(intent, .switchMode(.command))
    }

    func testSendCommandWithTurkishCharacter() {
        let intent = parser.parse(input: "mesajı gönder", mode: .command)
        XCTAssertEqual(intent, .send)
    }

    func testDictationFallbackInDictationMode() {
        let intent = parser.parse(input: "yarın 10'da görüşelim", mode: .dictation)
        XCTAssertEqual(intent, .dictate(text: "yarın 10'da görüşelim"))
    }

    func testUnknownInCommandMode() {
        let intent = parser.parse(input: "yarın 10'da görüşelim", mode: .command)
        XCTAssertEqual(intent, .unknown(raw: "yarın 10'da görüşelim"))
    }

    func testSwitchAppParsing() {
        let intent = parser.parse(input: "Slack'e geç", mode: .command)
        XCTAssertEqual(intent, .switchApp(name: "Slack"))
    }
}

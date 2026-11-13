import AVFoundation

struct AudioInputRoute: Identifiable, Equatable {
    let port: AVAudioSessionPortDescription
    var id: String { port.uid }
    var name: String { port.portName }
    var type: String { port.portType.rawValue.replacingOccurrences(of: "AVAudioSessionPort", with: "") }
}

enum SoundLevel: String {
    case green = "Quiet"
    case yellow = "Elevated"
    case red = "Loud"

    static func from(decibels: Double) -> SoundLevel {
        switch decibels {
        case ..<55: .green
        case ..<75: .yellow
        default: .red
        }
    }
}

enum OperatingMode: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case jailbreakCompanion = "Jailbreak Companion"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .normal:
            return "Uses only standard iOS app audio APIs for level measurement and route selection."
        case .jailbreakCompanion:
            return "Uses the optional rootless companion when installed. It does not promise true ANC."
        }
    }
}

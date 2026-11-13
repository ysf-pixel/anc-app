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

import AVFoundation
import Combine

@MainActor
final class AudioController: NSObject, ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var permissionMessage = "Microphone permission is required."
    @Published private(set) var routeMessage = "No active route"
    @Published private(set) var inputs: [AudioInputRoute] = []
    @Published var selectedInputID: String?
    @Published var useSpeaker = false
    @Published private(set) var decibels: Double = -80
    @Published private(set) var experimentalPeak: Float = 0
    @Published var processorStrength = 0.5

    private let session = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine()
    private var tapInstalled = false

    override init() {
        super.init()
        observeAudioSession()
        refreshRoutes()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    var level: SoundLevel { SoundLevel.from(decibels: decibels) }

    func requestAndStart() async {
        let granted: Bool
        if session.recordPermission == .undetermined {
            granted = await withCheckedContinuation { continuation in
                session.requestRecordPermission { continuation.resume(returning: $0) }
            }
        } else {
            granted = session.recordPermission == .granted
        }
        guard granted else {
            permissionMessage = "Microphone permission was denied. Enable it in Settings > Privacy & Security > Microphone."
            return
        }
        do {
            try configureSession()
            installTapIfNeeded()
            engine.prepare()
            try engine.start()
            isRunning = true
            permissionMessage = "Listening for level measurements."
        } catch {
            permissionMessage = "Audio could not start: \(error.localizedDescription)"
            isRunning = false
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
        permissionMessage = "Level meter stopped."
    }

    func selectInput(_ id: String?) {
        selectedInputID = id
        do {
            let input = session.availableInputs?.first(where: { $0.uid == id })
            try session.setPreferredInput(input)
            refreshRoutes()
        } catch {
            permissionMessage = "Could not select input: \(error.localizedDescription)"
        }
    }

    func setSpeaker(_ enabled: Bool) {
        useSpeaker = enabled
        do {
            try session.overrideOutputAudioPort(enabled ? .speaker : .none)
            refreshRoutes()
        } catch {
            permissionMessage = "Could not change output: \(error.localizedDescription)"
        }
    }

    private func configureSession() throws {
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetoothHFP, .allowBluetoothA2DP, .defaultToSpeaker])
        try session.setActive(true, options: [])
        refreshRoutes()
    }

    private func installTapIfNeeded() {
        guard !tapInstalled else { return }
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)
            let samples = UnsafeBufferPointer(start: channel, count: count)
            let meanSquare = samples.reduce(Float.zero) { $0 + ($1 * $1) } / Float(max(count, 1))
            let db = max(-80, 20 * log10(max(sqrt(meanSquare), 0.0001)))
            let peak = ExperimentalProcessor(strength: self?.processorStrength ?? 0.5).invertedPeak(for: samples)
            Task { @MainActor [weak self] in
                self?.decibels = Double(db)
                self?.experimentalPeak = peak
            }
        }
        tapInstalled = true
    }

    private func refreshRoutes() {
        inputs = (session.availableInputs ?? []).map(AudioInputRoute.init(port:))
        selectedInputID = session.preferredInput?.uid ?? session.currentRoute.inputs.first?.uid
        let inputNames = session.currentRoute.inputs.map(\.portName).joined(separator: ", ")
        let outputNames = session.currentRoute.outputs.map(\.portName).joined(separator: ", ")
        routeMessage = "Input: \(inputNames.isEmpty ? "None" : inputNames) • Output: \(outputNames.isEmpty ? "None" : outputNames)"
    }

    private func observeAudioSession() {
        let center = NotificationCenter.default
        center.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshRoutes() }
        }
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] note in
            guard let typeValue = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            Task { @MainActor in
                if type == .began { self?.stop() }
                else { self?.permissionMessage = "Audio interruption ended. Tap Start to resume." }
            }
        }
    }
}

import Foundation

/// Calculates experimental values only. It intentionally never feeds microphone samples to output.
/// True ANC needs calibrated hardware, a latency budget far below ordinary app audio I/O, and a closed-loop
/// acoustic model; none are available through a standard iOS app sandbox.
struct ExperimentalProcessor {
    var strength: Double = 0.5

    func invertedPeak(for samples: UnsafeBufferPointer<Float>) -> Float {
        guard let peak = samples.map({ abs($0) }).max() else { return 0 }
        return -peak * Float(strength)
    }
}

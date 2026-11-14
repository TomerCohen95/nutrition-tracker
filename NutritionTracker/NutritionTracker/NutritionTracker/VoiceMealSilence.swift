import Foundation

struct VoiceMealSilence {
    enum Decision: Equatable {
        case keepRecording, finish, noSpeech
    }

    private var lastVoice: TimeInterval?
    private var activeSamples = 0
    private var noiseFloor: Float = -56

    mutating func update(level: Float, elapsed: TimeInterval) -> Decision {
        let threshold = min(-26, max(-49, noiseFloor + 10))
        if level > threshold {
            activeSamples += 1
            if activeSamples >= 2 { lastVoice = elapsed }
        } else {
            activeSamples = 0
            noiseFloor = noiseFloor * 0.92 + max(-75, level) * 0.08
        }

        if let lastVoice {
            return elapsed - lastVoice >= 2.4 || elapsed >= 120 ? .finish : .keepRecording
        }
        return elapsed >= 10 ? .noSpeech : .keepRecording
    }
}

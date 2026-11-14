import AVFoundation

@MainActor
final class VoiceMealRecorder: ObservableObject {
    @Published private(set) var isRecording = false

    private var recorder: AVAudioRecorder?
    private var file: URL?

    func start() throws {
        discard()
        let session = AVAudioSession.sharedInstance()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        file = url
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
            let recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 24_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 48_000,
            ])
            recorder.isMeteringEnabled = true
            guard recorder.record(forDuration: 121) else {
                throw VoiceMealService.Error.message("Could not start recording.")
            }
            self.recorder = recorder
            isRecording = true
        } catch {
            discard()
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            throw error
        }
    }

    func level() -> Float? {
        guard let recorder, recorder.isRecording else { return nil }
        recorder.updateMeters()
        return recorder.averagePower(forChannel: 0)
    }

    func finish() throws -> Data {
        stop()
        defer { discard() }
        guard let file else { throw VoiceMealService.Error.message("No recording was captured.") }
        return try Data(contentsOf: file)
    }

    func discard() {
        stop()
        if let file { try? FileManager.default.removeItem(at: file) }
        file = nil
    }

    private func stop() {
        if let recorder {
            recorder.stop()
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        recorder = nil
        isRecording = false
    }
}

import SwiftUI
import AVFoundation

@MainActor
final class LocalAudio: ObservableObject {
    static let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    @Published var title = "Import an audio file"
    @Published var loaded = false
    @Published var playing = false
    @Published var message: String?
    @Published var gains: [Float] {
        didSet {
            for index in gains.indices { equalizer.bands[index].gain = gains[index] }
            UserDefaults.standard.set(gains.map(Double.init), forKey: "timbre.gains")
        }
    }
    @Published var enabled = true { didSet { equalizer.bypass = !enabled } }
    @Published var preamp: Float = -6 {
        didSet { equalizer.globalGain = preamp }
    }
    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 10)
    private var audioFile: AVAudioFile?
    private var importedURL: URL?
    private var needsSchedule = true
    private var scheduleID = UUID()

    init() {
        let stored = UserDefaults.standard.array(forKey: "timbre.gains") as? [Double]
        gains = stored?.count == 10 ? stored!.map { Float(max(-12, min(12, $0))) } : Array(repeating: 0, count: 10)
        engine.attach(node)
        engine.attach(equalizer)
        for index in gains.indices {
            let band = equalizer.bands[index]
            band.filterType = .parametric
            band.frequency = Self.frequencies[index]
            band.bandwidth = 1
            band.gain = gains[index]
            band.bypass = false
        }
        equalizer.globalGain = preamp
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
            object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.pause() }
        }
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification,
            object: nil, queue: .main) { [weak self] notification in
            let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                Task { @MainActor in self?.pause() }
            }
        }
    }

    func importFile(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
            try FileManager.default.copyItem(at: url, to: destination)
            do {
                let file = try AVAudioFile(forReading: destination)
                stop()
                if let previous = importedURL { try? FileManager.default.removeItem(at: previous) }
                importedURL = destination
                audioFile = file
                engine.disconnectNodeOutput(node)
                engine.disconnectNodeOutput(equalizer)
                engine.connect(node, to: equalizer, format: file.processingFormat)
                engine.connect(equalizer, to: engine.mainMixerNode, format: file.processingFormat)
                title = url.deletingPathExtension().lastPathComponent
                loaded = true
            } catch {
                try? FileManager.default.removeItem(at: destination)
                throw error
            }
        } catch { message = "Could not open this audio file: \(error.localizedDescription)" }
    }

    func play() {
        guard let file = audioFile else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            if !engine.isRunning { try engine.start() }
            if needsSchedule {
                let id = UUID()
                scheduleID = id
                node.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                    Task { @MainActor in
                        guard let self, self.scheduleID == id else { return }
                        self.playing = false
                        self.needsSchedule = true
                    }
                }
                needsSchedule = false
            }
            node.play()
            playing = true
        } catch { message = "Audio: \(error.localizedDescription)"; playing = false }
    }

    func pause() { node.pause(); playing = false }
    func stop() {
        scheduleID = UUID()
        node.stop()
        engine.stop()
        needsSchedule = true
        playing = false
    }
    func reset() { gains = Array(repeating: 0, count: 10); preamp = -6 }
}

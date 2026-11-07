import AVFoundation
import MusicKit
import SwiftUI

/// Native MusicKit is a playback alternative to Gecko previews. MusicKit owns
/// the protected audio path; it does not provide decoded PCM to Timbre.
@MainActor
final class NativeMusicPlaybackState: ObservableObject {
    @Published var authorization = MusicAuthorization.currentStatus
    @Published var subscription = "Not checked"
    @Published var searchText = ""
    @Published var songs: [Song] = []
    @Published var stations: [Station] = []
    @Published var status = "Connect Apple Music to test native playback."
    @Published var errorMessage: String?
    @Published var busy = false
    @Published var currentTitle = "Nothing playing"

    let player = ApplicationMusicPlayer.shared
    private var hasLoadedStations = false

    func connect() async {
        authorization = await MusicAuthorization.request()
        await refresh()
    }

    func refresh() async {
        authorization = MusicAuthorization.currentStatus
        guard authorization == .authorized else {
            subscription = "Music access not authorized"
            status = "Allow Apple Music access to check native playback."
            return
        }
        do {
            let canPlay = try await MusicSubscription.current.canPlayCatalogContent
            subscription = canPlay ? "Catalog subscription available" : "Catalog subscription unavailable"
            status = canPlay ? "Native playback is available to test. No Timbre DSP on protected audio." :
                "Try free radio or your purchased music. Catalog tracks may require a subscription."
        } catch {
            subscription = "Status request failed"
            errorMessage = "MusicKit subscription check: \(error.localizedDescription)"
        }
        await loadStations()
    }

    func loadStations() async {
        guard authorization == .authorized, !hasLoadedStations else { return }
        do {
            var request = MusicCatalogSearchRequest(term: "Apple Music", types: [Station.self])
            request.limit = 25
            stations = Array(try await request.response().stations)
                .sorted { $0.isLive && !$1.isLive }
            hasLoadedStations = true
        } catch {
            errorMessage = "Station lookup: \(error.localizedDescription)"
        }
    }

    func search() async {
        guard authorization == .authorized else {
            errorMessage = "Connect Apple Music first."
            return
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { songs = []; return }
        busy = true
        defer { busy = false }
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self, Station.self])
            request.limit = 25
            let response = try await request.response()
            songs = Array(response.songs)
            stations = Array(response.stations)
        } catch {
            errorMessage = "MusicKit search: \(error.localizedDescription)"
        }
    }

    func play(_ song: Song) async {
        do {
            player.queue = ApplicationMusicPlayer.Queue(for: [song])
            try await player.play()
            currentTitle = song.title
            status = "MusicKit is playing \(song.title). Timbre cannot read MusicKit's protected PCM."
        } catch { errorMessage = "Native track playback: \(error.localizedDescription)" }
    }

    func play(_ station: Station) async {
        do {
            player.queue = ApplicationMusicPlayer.Queue(for: [station])
            try await player.play()
            currentTitle = station.name
            status = "MusicKit station \(station.name) selected. Timbre DSP is unavailable on this stream."
        } catch { errorMessage = "Native radio playback: \(error.localizedDescription)" }
    }

    func togglePlay() async {
        if player.state.playbackStatus == .playing {
            player.pause()
        } else {
            do { try await player.play() }
            catch { errorMessage = "Native playback: \(error.localizedDescription)" }
        }
    }
}

struct NativeMusicPlaybackView: View {
    @ObservedObject var music: NativeMusicPlaybackState
    let section: MusicSection

    var body: some View {
        NavigationStack {
            List {
                Section("Native audio") {
                    Label(music.authorization == .authorized ? "MusicKit authorized" : "MusicKit access required",
                          systemImage: music.authorization == .authorized ? "checkmark.shield" : "lock")
                    Text(music.subscription).font(.subheadline)
                    if music.authorization != .authorized {
                        Button("Connect Apple Music") { Task { await music.connect() } }
                    } else {
                        Button("Refresh account and stations") { Task { await music.refresh() } }
                    }
                    Text("Apple's native player supports subscription playback when your account and signing capabilities permit. It does not expose protected PCM to the Timbre EQ.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Search") {
                    HStack {
                        TextField("Song, artist or radio station", text: $music.searchText)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .onSubmit { Task { await music.search() } }
                        Button { Task { await music.search() } } label: { Image(systemName: "magnifyingglass") }
                    }
                    if music.busy { ProgressView("Searching Apple Music") }
                    ForEach(music.songs) { song in
                        Button { Task { await music.play(song) } } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(song.title).foregroundStyle(.primary)
                                Text(song.artistName).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section(section == .radio ? "Live and featured radio" : "Radio stations") {
                    if music.stations.isEmpty {
                        Text("Connect Apple Music and refresh to discover stations.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(music.stations) { station in
                        Button { Task { await music.play(station) } } label: {
                            HStack {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                VStack(alignment: .leading) {
                                    Text(station.name).foregroundStyle(.primary)
                                    Text(station.isLive ? "Live radio" : "Station")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "play.fill")
                            }
                        }
                    }
                }
                Section("Now Playing") {
                    Text(music.currentTitle).font(.headline)
                    HStack {
                        Button("Play / Pause") { Task { await music.togglePlay() } }
                        Spacer()
                        Text("Native MusicKit").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(music.status).font(.footnote).foregroundStyle(.secondary)
                }
                Section("Playback diagnostics") {
                    let session = AVAudioSession.sharedInstance()
                    LabeledContent("Audio route", value: session.currentRoute.outputs.first?.portType.rawValue ?? "Unknown")
                    LabeledContent("Audio session", value: "\(Int(session.sampleRate)) Hz")
                    Text("These values describe the device output, not a PCM capture. A nonzero sample rate does not mean Timbre can process MusicKit audio.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Native Apple Music")
            .task { await music.refresh() }
            .alert("MusicKit", isPresented: Binding(
                get: { music.errorMessage != nil },
                set: { if !$0 { music.errorMessage = nil } })) {
                    Button("OK") { music.errorMessage = nil }
                } message: { Text(music.errorMessage ?? "") }
        }
    }
}

import SwiftUI
import MusicKit

@MainActor
final class MusicModel: ObservableObject {
    @Published var authorization = MusicAuthorization.currentStatus
    @Published var canPlay = false
    @Published var songs: [Song] = []
    @Published var stations: [Station] = []
    @Published var searchAlbums: [Album] = []
    @Published var searchPlaylists: [Playlist] = []
    @Published var library: [Song] = []
    @Published var message: String?
    @Published var busy = false
    @Published var nowPlaying = "Choose a song"
    @Published var artist = "Apple Music"
    @Published var searchText = ""
    private var searchGeneration = 0
    let player = ApplicationMusicPlayer.shared

    func connect() async {
        authorization = await MusicAuthorization.request()
        await refreshAccount()
    }

    func refreshAccount() async {
        authorization = MusicAuthorization.currentStatus
        guard authorization == .authorized else { canPlay = false; return }
        do {
            canPlay = try await MusicSubscription.current.canPlayCatalogContent
            var request = MusicLibraryRequest<Song>()
            request.limit = 100
            let response = try await request.response()
            library = Array(response.items)
        } catch { message = "Apple Music: \(error.localizedDescription)" }
    }

    func search() async {
        searchGeneration += 1
        let generation = searchGeneration
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { songs = []; stations = []; searchAlbums = []; searchPlaylists = []; return }
        guard authorization == .authorized else {
            message = "Connect your Apple Music account first."
            return
        }
        busy = true
        defer { if generation == searchGeneration { busy = false } }
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self, Station.self, Album.self, Playlist.self])
            request.limit = 25
            let response = try await request.response()
            guard generation == searchGeneration else { return }
            songs = Array(response.songs)
            stations = Array(response.stations)
            searchAlbums = Array(response.albums)
            searchPlaylists = Array(response.playlists)
        } catch {
            guard generation == searchGeneration else { return }
            message = "Search: \(error.localizedDescription)"
        }
    }

    func play(_ song: Song) async {
        do {
            player.queue = ApplicationMusicPlayer.Queue(for: [song])
            try await player.play()
            nowPlaying = song.title
            artist = song.artistName
        } catch { message = "Playback: \(error.localizedDescription)" }
    }

    func play(_ station: Station) async {
        do {
            player.queue = ApplicationMusicPlayer.Queue(for: [station])
            try await player.play()
            nowPlaying = station.name
            artist = station.stationProviderName ?? "Apple Music Radio"
        } catch { message = "Radio playback: \(error.localizedDescription)" }
    }

    func togglePlayback() async {
        guard player.queue.currentEntry != nil else { return }
        if player.state.playbackStatus == .playing { player.pause() }
        else {
            do { try await player.play() }
            catch { message = "Playback: \(error.localizedDescription)" }
        }
    }

    func playTracks(_ tracks: [Track]) async {
        guard let first = tracks.first else { return }
        do {
            player.queue = ApplicationMusicPlayer.Queue(for: tracks)
            try await player.play()
            nowPlaying = first.title
            artist = first.artistName
        } catch { message = "Playback: \(error.localizedDescription)" }
    }
    func skip(next: Bool) async {
        do {
            if next { try await player.skipToNextEntry() }
            else { try await player.skipToPreviousEntry() }
        } catch { message = error.localizedDescription }
    }
}

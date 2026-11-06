import SwiftUI
import MusicKit

@MainActor
final class Catalog: ObservableObject {
    @Published var albums: [Album] = []
    @Published var playlists: [Playlist] = []
    @Published var songs: [Song] = []
    @Published var radio: [Station] = []
    @Published var recommendations: [MusicPersonalRecommendation] = []
    @Published var loading = false
    @Published var errors: [String] = []

    func load() async {
        guard !loading else { return }
        loading = true
        errors = []
        defer { loading = false }
        do {
            var request = MusicCatalogChartsRequest(kinds: [.mostPlayed], types: [Album.self, Playlist.self, Song.self])
            request.limit = 20
            let response = try await request.response()
            albums = Array(response.albumCharts.first?.items ?? [])
            playlists = Array(response.playlistCharts.first?.items ?? [])
            songs = Array(response.songCharts.first?.items ?? [])
        } catch { errors.append("Browse: \(error.localizedDescription)") }
        do {
            var request = MusicCatalogSearchRequest(term: "Apple Music", types: [Station.self])
            request.limit = 25
            radio = Array(try await request.response().stations).sorted { $0.isLive && !$1.isLive }
        } catch { errors.append("Radio: \(error.localizedDescription)") }
        if MusicAuthorization.currentStatus == .authorized {
            do {
                recommendations = Array(try await MusicPersonalRecommendationsRequest().response().recommendations)
            } catch { errors.append("For You: \(error.localizedDescription)") }
        }
    }
}

struct Cover: View {
    let artwork: Artwork?
    var size: CGFloat = 150
    var body: some View {
        Group {
            if let artwork { ArtworkImage(artwork, width: size, height: size) }
            else { Image(systemName: "music.note").font(.largeTitle).frame(width: size, height: size).background(.quaternary) }
        }.clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DiscoveryView: View {
    @ObservedObject var catalog: Catalog
    @ObservedObject var music: MusicModel
    let mode: String
    let prepare: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if catalog.loading { ProgressView("Loading Apple Music…").frame(maxWidth: .infinity) }
                if !catalog.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(catalog.errors, id: \.self) { Text($0).font(.footnote).foregroundStyle(.secondary) }
                        Button("Try again") { Task { await catalog.load() } }
                    }.padding().background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                }
                if mode == "Home" {
                    if music.authorization != .authorized {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Make it yours").font(.title2.bold())
                            Text("Connect Apple Music for your library and personal recommendations.").foregroundStyle(.secondary)
                            Button("Connect Apple Music") { Task { await music.connect(); await catalog.load() } }.buttonStyle(.borderedProminent)
                        }.padding().background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
                    }
                    ForEach(catalog.recommendations) { recommendation in
                        albumShelf(recommendation.title ?? "For You", Array(recommendation.albums))
                        playlistShelf(recommendation.title ?? "Made for you", Array(recommendation.playlists))
                        radioShelf(recommendation.title ?? "Your stations", Array(recommendation.stations))
                    }
                    if catalog.recommendations.isEmpty {
                        Text("Discover Apple Music").font(.title2.bold())
                        Text("Personal recommendations depend on your account and subscription. Browse the charts and available radio below.").foregroundStyle(.secondary)
                    }
                }
                if mode != "Radio" {
                    albumShelf("Top albums", catalog.albums)
                    playlistShelf("Popular playlists", catalog.playlists)
                    if !catalog.songs.isEmpty {
                        Text("Top songs").font(.title2.bold())
                        ForEach(catalog.songs) { song in
                            Button { prepare(); Task { await music.play(song) } } label: {
                                HStack { Cover(artwork: song.artwork, size: 52); VStack(alignment: .leading) { Text(song.title).foregroundStyle(.primary); Text(song.artistName).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "play.fill") }
                            }
                        }
                    }
                }
                radioShelf(mode == "Radio" ? "Live and featured stations" : "Radio", catalog.radio)
                if mode == "Radio" {
                    Text("Station access varies by account and region. A station appearing here does not guarantee free playback through MusicKit.").font(.footnote).foregroundStyle(.secondary)
                    if catalog.radio.isEmpty && !catalog.loading { ContentUnavailableView("No stations loaded", systemImage: "dot.radiowaves.left.and.right", description: Text("Retry above or search for a station in Search.")) }
                }
            }.padding()
        }.navigationTitle(mode).refreshable { await catalog.load() }
    }

    @ViewBuilder private func albumShelf(_ title: String, _ items: [Album]) -> some View {
        if !items.isEmpty {
            Text(title).font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(items) { album in
                        NavigationLink { CollectionDetail(album: album, playlist: nil, music: music, prepare: prepare) } label: {
                            VStack(alignment: .leading) { Cover(artwork: album.artwork); Text(album.title).lineLimit(2); Text(album.artistName).font(.caption).foregroundStyle(.secondary).lineLimit(1) }.frame(width: 150, alignment: .leading)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }
    @ViewBuilder private func playlistShelf(_ title: String, _ items: [Playlist]) -> some View {
        if !items.isEmpty {
            Text(title).font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(items) { playlist in
                        NavigationLink { CollectionDetail(album: nil, playlist: playlist, music: music, prepare: prepare) } label: {
                            VStack(alignment: .leading) { Cover(artwork: playlist.artwork); Text(playlist.name).lineLimit(2); Text(playlist.curatorName ?? "Apple Music").font(.caption).foregroundStyle(.secondary).lineLimit(1) }.frame(width: 150, alignment: .leading)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }
    @ViewBuilder private func radioShelf(_ title: String, _ items: [Station]) -> some View {
        if !items.isEmpty {
            Text(title).font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(items) { station in
                        Button { prepare(); Task { await music.play(station) } } label: {
                            VStack(alignment: .leading) { Cover(artwork: station.artwork); Text(station.name).lineLimit(2); Label(station.isLive ? "Live" : "Station", systemImage: "dot.radiowaves.left.and.right").font(.caption).foregroundStyle(.secondary) }.frame(width: 150, alignment: .leading)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct CollectionDetail: View {
    let album: Album?
    let playlist: Playlist?
    @ObservedObject var music: MusicModel
    let prepare: () -> Void
    @State private var tracks: [Track] = []
    @State private var error: String?
    @State private var loading = true
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Cover(artwork: album?.artwork ?? playlist?.artwork, size: 240)
                    Text(album?.title ?? playlist?.name ?? "Collection").font(.title2.bold()).multilineTextAlignment(.center)
                    Text(album?.artistName ?? playlist?.curatorName ?? "Apple Music").foregroundStyle(.secondary)
                    HStack {
                        Button("Play", systemImage: "play.fill") { play(tracks) }
                        Button("Shuffle", systemImage: "shuffle") { play(tracks.shuffled()) }
                    }.buttonStyle(.borderedProminent).disabled(tracks.isEmpty)
                }.frame(maxWidth: .infinity).padding(.vertical)
            }
            if loading { ProgressView("Loading tracks…") }
            if let error { Text(error).foregroundStyle(.secondary) }
            ForEach(tracks) { track in
                Button { play(Array(tracks.drop(while: { $0.id != track.id }))) } label: {
                    HStack { Text(track.title).foregroundStyle(.primary); Spacer(); Text(track.artistName).font(.caption).foregroundStyle(.secondary) }
                }
            }
        }.navigationTitle(album == nil ? "Playlist" : "Album").navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                if let album { tracks = Array(try await album.with([.tracks]).tracks ?? []) }
                if let playlist { tracks = Array(try await playlist.with([.tracks]).tracks ?? []) }
            } catch { self.error = error.localizedDescription }
            loading = false
        }
    }
    private func play(_ items: [Track]) { prepare(); Task { await music.playTracks(items) } }
}

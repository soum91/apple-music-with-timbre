import SwiftUI
import MusicKit
import UniformTypeIdentifiers

private let timbreTint = Color(red: 99/255, green: 102/255, blue: 241/255)

@main
struct AppleMusicTimbreApp: App {
    var body: some Scene { WindowGroup { ContentView().tint(timbreTint) } }
}

struct ContentView: View {
    @StateObject private var music = MusicModel()
    @StateObject private var audio = LocalAudio()
    @StateObject private var catalog = Catalog()
    @ObservedObject private var queue = ApplicationMusicPlayer.shared.queue
    @ObservedObject private var playerState = ApplicationMusicPlayer.shared.state
    @Environment(\.scenePhase) private var phase
    @State private var importing = false
    @State private var showingEQ = false
    @State private var localSource = false
    @State private var showPlayer = false

    var body: some View {
        TabView {
            NavigationStack { DiscoveryView(catalog: catalog, music: music, mode: "Home", prepare: prepareMusic) }
                .tabItem { Label("Home", systemImage: "house") }
            NavigationStack { DiscoveryView(catalog: catalog, music: music, mode: "Browse", prepare: prepareMusic) }
                .tabItem { Label("Browse", systemImage: "square.grid.2x2") }
            NavigationStack { DiscoveryView(catalog: catalog, music: music, mode: "Radio", prepare: prepareMusic) }
                .tabItem { Label("Radio", systemImage: "dot.radiowaves.left.and.right") }
            NavigationStack {
                List {
                    Section {
                        Label("Apple Music + Timbre", systemImage: "waveform")
                            .font(.title2.bold()).foregroundStyle(timbreTint)
                        Text("Your music, your space.").foregroundStyle(.secondary)
                        accountControls
                    }
                    Section("Your library") {
                        if music.library.isEmpty {
                            Text("Connect Apple Music to load up to 100 library songs.")
                                .foregroundStyle(.secondary)
                        }
                        songRows(music.library)
                    }
                }
                .navigationTitle("Library")
                .refreshable { await music.refreshAccount() }
            }.tabItem { Label("Library", systemImage: "music.note.list") }

            NavigationStack {
                List {
                    if music.busy { ProgressView("Searching Apple Music…") }
                    if music.songs.isEmpty && music.stations.isEmpty && !music.busy {
                        ContentUnavailableView("Find your next song", systemImage: "magnifyingglass",
                            description: Text("Search Apple Music by song or artist."))
                    }
                    if !music.stations.isEmpty {
                        Section("Radio") { stationRows(music.stations) }
                    }
                    Section("Albums") {
                        ForEach(music.searchAlbums) { album in
                            NavigationLink { CollectionDetail(album: album, playlist: nil, music: music, prepare: prepareMusic) } label: {
                                HStack { Cover(artwork: album.artwork, size: 48); VStack(alignment: .leading) { Text(album.title); Text(album.artistName).font(.caption).foregroundStyle(.secondary) } }
                            }
                        }
                    }
                    Section("Playlists") {
                        ForEach(music.searchPlaylists) { playlist in
                            NavigationLink { CollectionDetail(album: nil, playlist: playlist, music: music, prepare: prepareMusic) } label: {
                                HStack { Cover(artwork: playlist.artwork, size: 48); Text(playlist.name) }
                            }
                        }
                    }
                    songRows(music.songs)
                }
                .navigationTitle("Search")
                .searchable(text: $music.searchText, prompt: "Songs and artists")
                .onSubmit(of: .search) { Task { await music.search() } }
            }.tabItem { Label("Search", systemImage: "magnifyingglass") }

            NavigationStack {
                List {
                    Section("Your audio") {
                        Button { importing = true } label: { Label("Import audio", systemImage: "folder.badge.plus") }
                        Text(audio.title).font(.headline)
                        if audio.loaded {
                            Button(audio.playing ? "Pause" : "Play with Timbre") {
                                if audio.playing { audio.pause() }
                                else {
                                    music.player.pause()
                                    localSource = true
                                    audio.play()
                                }
                            }
                        }
                    }
                    Section("Sound") {
                        Button { showingEQ = true } label: { Label("Timbre equalizer", systemImage: "slider.horizontal.3") }
                        Text("Custom EQ applies to imported audio files. Apple Music subscription tracks play through MusicKit; custom EQ is unavailable for that source.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }.navigationTitle("Timbre")
            }.tabItem { Label("Timbre", systemImage: "waveform") }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
        .sheet(isPresented: $showPlayer) { fullPlayer }
        .sheet(isPresented: $showingEQ) { EqualizerView(audio: audio) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url): audio.importFile(url)
            case .failure(let error): audio.message = error.localizedDescription
            }
        }
        .alert("Apple Music", isPresented: Binding(get: { music.message != nil },
            set: { if !$0 { music.message = nil } })) {
                Button("OK") { music.message = nil }
            } message: { Text(music.message ?? "") }
        .alert("Timbre", isPresented: Binding(get: { audio.message != nil },
            set: { if !$0 { audio.message = nil } })) {
                Button("OK") { audio.message = nil }
            } message: { Text(audio.message ?? "") }
        .task { await music.refreshAccount(); await catalog.load() }
        .onChange(of: phase) { _, phase in
            if phase == .active { Task { await music.refreshAccount() } }
        }
    }

    private var accountControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            if music.authorization == .authorized {
                Label(music.canPlay ? "Apple Music subscription active" : "Connected · no catalog subscription", systemImage: "checkmark.circle")
                    .font(.subheadline)
            } else {
                Button("Connect Apple Music") { Task { await music.connect() } }
                if music.authorization == .denied || music.authorization == .restricted {
                    Text("Allow Music access in Settings to connect.").font(.footnote)
                    Link("Open Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        }
    }

    private func songRows(_ songs: [Song]) -> some View {
        ForEach(songs) { song in
            Button {
                audio.pause()
                localSource = false
                Task { await music.play(song) }
            } label: {
                HStack(spacing: 12) {
                    if let artwork = song.artwork { ArtworkImage(artwork, width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 8)) }
                    else { Image(systemName: "music.note").frame(width: 48, height: 48).background(.quaternary).clipShape(RoundedRectangle(cornerRadius: 8)) }
                    VStack(alignment: .leading) {
                        Text(song.title).foregroundStyle(.primary).lineLimit(1)
                        Text(song.artistName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "play.fill").foregroundStyle(timbreTint)
                }
            }
        }
    }

    private func stationRows(_ stations: [Station]) -> some View {
        ForEach(stations) { station in
            Button {
                audio.pause()
                localSource = false
                Task { await music.play(station) }
            } label: {
                HStack(spacing: 12) {
                    if let artwork = station.artwork { ArtworkImage(artwork, width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 8)) }
                    else { Image(systemName: "dot.radiowaves.left.and.right").frame(width: 48, height: 48).background(.quaternary).clipShape(RoundedRectangle(cornerRadius: 8)) }
                    VStack(alignment: .leading) {
                        Text(station.name).foregroundStyle(.primary).lineLimit(1)
                        Text(station.stationProviderName ?? "Apple Music Radio").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "dot.radiowaves.left.and.right").foregroundStyle(timbreTint)
                }
            }
        }
    }

    private var miniPlayer: some View {
        HStack(spacing: 12) {
            Image(systemName: localSource ? "waveform" : "music.note").foregroundStyle(timbreTint)
            VStack(alignment: .leading, spacing: 3) {
                Text(localSource ? audio.title : (queue.currentEntry?.title ?? music.nowPlaying)).font(.subheadline.bold()).lineLimit(1)
                Text(localSource ? "Timbre EQ \(audio.enabled ? "active" : "bypassed")" : "\(music.artist) · MusicKit playback")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Button {
                if localSource {
                    if audio.playing { audio.pause() } else { audio.play() }
                } else { Task { await music.togglePlayback() } }
            } label: {
                Image(systemName: (localSource ? audio.playing : playerState.playbackStatus == .playing) ? "pause.fill" : "play.fill")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel((localSource ? audio.playing : playerState.playbackStatus == .playing) ? "Pause" : "Play")
        }
        .padding(.horizontal).padding(.vertical, 8).background(.regularMaterial)
        .onTapGesture { showPlayer = true }
    }

    private func prepareMusic() { audio.pause(); localSource = false }

    private var fullPlayer: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Cover(artwork: localSource ? nil : queue.currentEntry?.artwork, size: 280)
                    Text(localSource ? audio.title : (queue.currentEntry?.title ?? music.nowPlaying)).font(.title2.bold()).multilineTextAlignment(.center)
                    Text(localSource ? "Timbre local audio" : "Apple Music").foregroundStyle(.secondary)
                    if !localSource {
                        HStack(spacing: 40) {
                            Button { Task { await music.skip(next: false) } } label: { Image(systemName: "backward.fill") }
                            Button { Task { await music.togglePlayback() } } label: { Image(systemName: playerState.playbackStatus == .playing ? "pause.fill" : "play.fill") }
                            Button { Task { await music.skip(next: true) } } label: { Image(systemName: "forward.fill") }
                        }.font(.largeTitle)
                        HStack(spacing: 40) {
                            Button { music.player.state.shuffleMode = playerState.shuffleMode == .songs ? .off : .songs } label: { Image(systemName: "shuffle").opacity(playerState.shuffleMode == .songs ? 1 : 0.4) }
                            Button { music.player.state.repeatMode = playerState.repeatMode == .all ? .none : .all } label: { Image(systemName: "repeat").opacity(playerState.repeatMode == .all ? 1 : 0.4) }
                        }
                        Text("Up Next").font(.title2.bold()).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(Array(queue.entries)) { entry in
                            Text(entry.title).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                        }
                    } else {
                        Button(audio.playing ? "Pause" : "Play") { if audio.playing { audio.pause() } else { audio.play() } }.buttonStyle(.borderedProminent)
                    }
                }.padding()
            }.navigationTitle("Now Playing").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showPlayer = false } } }
        }
    }
}

struct EqualizerView: View {
    @ObservedObject var audio: LocalAudio
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Timbre EQ", isOn: $audio.enabled)
                    Text("For imported audio files").font(.caption).foregroundStyle(.secondary)
                }
                Section("Preamp") {
                    Text(String(format: "%.1f dB", audio.preamp)).monospacedDigit()
                    Slider(value: $audio.preamp, in: -18...0, step: 0.5)
                }
                Section("10 band equalizer") {
                    ForEach(0..<LocalAudio.frequencies.count, id: \.self) { index in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("\(Int(LocalAudio.frequencies[index])) Hz")
                                Spacer()
                                Text(String(format: "%+.1f dB", audio.gains[index])).monospacedDigit()
                            }.font(.caption)
                            Slider(value: $audio.gains[index], in: -12...12, step: 0.5)
                                .accessibilityLabel("\(Int(LocalAudio.frequencies[index])) hertz gain")
                        }
                    }
                }.disabled(!audio.enabled)
                Button("Reset equalizer") { audio.reset() }
            }
            .navigationTitle("Timbre")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

import SwiftUI
import UIKit
import WebKit
import MusicKit
@preconcurrency import GeckoView

private let indigo = Color(red: 99 / 255, green: 102 / 255, blue: 241 / 255)
private enum PlayerMode: String, CaseIterable {
    case gecko = "Gecko + Timbre"
    case native = "Native MusicKit"
    case webkit = "WebKit comparison"
    var symbol: String {
        switch self {
        case .gecko: "flame"
        case .native: "music.note"
        case .webkit: "globe"
        }
    }
}

private struct DRMBundleReport: Decodable {
    let containsWidevineCDM: Bool
    let containsFairPlayCDM: Bool
    static var installed: DRMBundleReport? {
        guard let url = Bundle.main.url(forResource: "drm-capabilities", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}
enum MusicSection: String, CaseIterable, Identifiable {
    case home = "Home", new = "New", radio = "Radio", search = "Search", library = "Library"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .new: "sparkles"
        case .radio: "dot.radiowaves.left.and.right"
        case .search: "magnifyingglass"
        case .library: "music.note.list"
        }
    }
    var url: String {
        switch self {
        case .home: "https://music.apple.com/ca/home"
        case .new: "https://music.apple.com/ca/new"
        case .radio: "https://music.apple.com/ca/radio"
        case .search: "https://music.apple.com/ca/search"
        case .library: "https://music.apple.com/ca/library"
        }
    }
}

@MainActor
final class GeckoMusicState: ObservableObject {
    @Published var status = "Ready"
    @Published var errorMessage: String?
    @Published var eqPopupURL: String?
    private(set) var session: GeckoSession
    private var started = false

    init() {
        let version = GeckoRuntime.version.split(whereSeparator: { !$0.isNumber }).first.map(String.init) ?? "159"
        let website = WebsiteModeSetting(
            userAgentOverride: "Mozilla/5.0 (Android 15; Mobile; rv:\(version).0) Gecko/\(version).0 Firefox/\(version).0",
            platformOverride: "Linux armv81",
            appVersionOverride: "5.0 (Android 15)",
            oscpuOverride: "Linux armv81",
            buildIDOverride: nil,
            userAgentMode: 0,
            viewportMode: 0)
        session = GeckoSession(settings: GeckoSessionSettings(
            websiteMode: website, pageZoom: .default,
            language: LanguageSetting(codes: Locale.preferredLanguages.isEmpty ? ["en"] : Locale.preferredLanguages)),
            isPrivateMode: false)
    }

    func start() {
        guard !started else { return }
        started = true
        session.open()
        session.setActive(true)
        session.setAddonTabActive(true)
        session.setFocused(true)
        session.load(MusicSection.home.url)
        status = "Apple Music loaded in Gecko. Timbre is available on supported playback."
        Task { await registerTimbre() }
    }

    func reload() { session.reload(flags: 0) }
    func showProtectedMediaTest() {
        guard let url = Bundle.main.url(forResource: "drm-diagnostic", withExtension: "html") else {
            errorMessage = "The embedded Gecko DRM diagnostic is missing from this build."
            return
        }
        session.load(url.absoluteString)
        status = "Running the embedded Gecko EME, Widevine and FairPlay checks. Local file origins can restrict EME."
    }
    func navigate(to section: MusicSection) {
        session.load(section.url)
    }
    func back() { session.goBack() }
    func forward() { session.goForward() }
    func setVisible(_ visible: Bool) {
        guard started else { return }
        session.setActive(visible)
        session.setAddonTabActive(visible)
        session.setFocused(visible)
    }

    func registerTimbre() async {
        for attempt in 1...6 {
            do {
                _ = try await AddonRuntime.shared.ensureBuiltIn(
                    location: "resource://app/extensions/timbre/", id: "timbre@soum91")
                _ = try await AddonRuntime.shared.list()
                if let addon = AddonRuntime.shared.installedAddons.first(where: { $0.id == "timbre@soum91" }),
                   addon.metaData.enabled {
                    status = "Timbre loaded. EQ affects Gecko preview playback; full protected tracks and Radio are not working yet."
                    return
                }
            } catch {
                if attempt == 6 { status = "Timbre registration failed: \(error.localizedDescription)" }
            }
            try? await Task.sleep(nanoseconds: UInt64(attempt) * 350_000_000)
        }
    }

    func openEQ() async {
        if !AddonRuntime.shared.installedAddons.contains(where: { $0.id == "timbre@soum91" }) {
            await registerTimbre()
        }
        do { _ = try await AddonRuntime.shared.list() }
        catch { errorMessage = "Cannot load add-ons: \(error.localizedDescription)"; return }
        guard let addon = AddonRuntime.shared.installedAddons.first(where: { $0.id == "timbre@soum91" }),
              addon.metaData.enabled,
              let base = URLComponents(string: addon.metaData.baseURL),
              base.scheme == "moz-extension", base.host?.isEmpty == false else {
            errorMessage = "Gecko has not activated Timbre yet. Reload the page and try again."
            return
        }
        var components = base
        components.path = "/popup/popup.html"
        components.query = nil
        components.fragment = nil
        eqPopupURL = components.url?.absoluteString
    }
}

struct GeckoViewSurface: UIViewRepresentable {
    @ObservedObject var state: GeckoMusicState
    func makeUIView(context: Context) -> GeckoView {
        let view = GeckoView(frame: .zero)
        view.backgroundColor = .black
        view.session = state.session
        return view
    }
    func updateUIView(_ view: GeckoView, context: Context) {}
}

struct TimbrePopupSurface: UIViewRepresentable {
    let url: String
    func makeUIView(context: Context) -> GeckoView {
        let view = GeckoView(frame: .zero)
        let session = GeckoSession(settings: GeckoSessionSettings(
            websiteMode: WebsiteModeSetting(
                userAgentOverride: nil, platformOverride: nil,
                appVersionOverride: nil, oscpuOverride: nil,
                buildIDOverride: nil, userAgentMode: 0, viewportMode: 0),
            pageZoom: .default, language: LanguageSetting(codes: ["en"])),
            isPrivateMode: false)
        session.open()
        session.setActive(true)
        session.setAddonTabActive(true)
        session.setFocused(true)
        session.load(url)
        view.session = session
        return view
    }
    func updateUIView(_ view: GeckoView, context: Context) {}
}

struct AppleMusicTimbreGeckoView: View {
    @StateObject private var gecko = GeckoMusicState()
    @StateObject private var native = NativeMusicPlaybackState()
    @State private var playerMode: PlayerMode = .gecko
    @State private var section: MusicSection = .home
    @State private var showAbout = false
    @State private var showEQ = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.path").foregroundStyle(indigo)
                Text("Apple Music + Timbre").font(.headline)
                Spacer()
                Menu {
                    ForEach(PlayerMode.allCases, id: \.self) { mode in
                        Button {
                            playerMode = mode
                        } label: {
                            Label(mode.rawValue, systemImage: mode.symbol)
                        }
                    }
                } label: {
                    Label(playerMode.rawValue, systemImage: playerMode.symbol)
                        .labelStyle(.iconOnly)
                }.accessibilityLabel("Playback engine: \(playerMode.rawValue)")
                Button { showAbout = true } label: { Image(systemName: "info.circle") }
            }.padding(.horizontal, 14).frame(height: 46)

            if playerMode == .webkit {
                // WebKit has native FairPlay/HLS support; whether its protected
                // samples are accessible to Timbre is an independent question.
                Text("WebKit comparison only. Timbre EQ is not attached to this player.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 12)
                WebKitRadioFallback(section: section)
            } else if playerMode == .native {
                NativeMusicPlaybackView(music: native, section: section)
            } else {
                GeckoViewSurface(state: gecko)
            }

            if playerMode == .gecko {
                HStack(spacing: 12) {
                    Button { gecko.back() } label: { Image(systemName: "chevron.left") }
                    Button { gecko.forward() } label: { Image(systemName: "chevron.right") }
                    Button { gecko.reload() } label: { Image(systemName: "arrow.clockwise") }
                    Spacer()
                    Button {
                        Task { await gecko.openEQ(); showEQ = gecko.eqPopupURL != nil }
                    } label: { Label("Timbre", systemImage: "slider.horizontal.3") }
                        .buttonStyle(.borderedProminent)
                }.padding(.horizontal).frame(height: 52).background(.regularMaterial)
            }
            HStack(spacing: 0) {
                ForEach(MusicSection.allCases) { destination in
                    Button {
                        section = destination
                        if playerMode == .gecko { gecko.navigate(to: destination) }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: destination.symbol).font(.system(size: 19))
                            Text(destination.rawValue).font(.system(size: 10))
                        }
                        .foregroundStyle(section == destination ? indigo : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    }.buttonStyle(.plain)
                }
            }.background(.regularMaterial)
        }
        .onAppear { gecko.start() }
        .onChange(of: playerMode) { _, mode in
            gecko.setVisible(mode == .gecko)
            if mode == .native { Task { await native.refresh() } }
        }
        .tint(indigo)
        .sheet(isPresented: $showEQ) {
            NavigationStack {
                Group {
                    if let url = gecko.eqPopupURL { TimbrePopupSurface(url: url) }
                    else { ContentUnavailableView("Timbre unavailable", systemImage: "waveform") }
                }.navigationTitle("Timbre EQ").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showEQ = false } } }
            }.presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                Form {
                    Section("Playback") {
                        Text("Safari plays full subscription tracks on the test iPhone. Our custom Gecko build currently receives Apple Music previews of approximately 90 seconds, even with an active subscription.")
                        Text("Timbre EQ affects Gecko's preview audio, but full protected-track processing is not confirmed. Radio also remains unavailable in Gecko.")
                        Text("Choose Native MusicKit using the engine menu to test authenticated subscription tracks and radio. Neither MusicKit nor WebKit exposes protected PCM to Timbre. Native playback is not a DRM bypass.")
                    }
                    Section("Protected-media check") {
                        Text("This build's embedded media-module inventory and the Gecko web API test are separate checks. They do not prove that Apple Music will authorize a full track.")
                        if let report = DRMBundleReport.installed {
                            LabeledContent("Bundled Widevine module", value: report.containsWidevineCDM ? "Present" : "Absent")
                            LabeledContent("Bundled FairPlay module", value: report.containsFairPlayCDM ? "Present" : "Absent")
                        } else {
                            Text("Bundled DRM inventory unavailable.")
                        }
                        Button("Run in-app Gecko DRM test") {
                            gecko.showProtectedMediaTest()
                            playerMode = .gecko
                            showAbout = false
                        }
                        Text("The embedded page displays EME, Widevine, FairPlay and media capability results. Its local-file origin can restrict EME, so an 'unavailable' result is not definitive for HTTPS sites.")
                        Button("Open independent Shaka browser test") {
                            gecko.session.load("https://shaka-project.github.io/shaka-player/demo/")
                            playerMode = .gecko
                            showAbout = false
                        }
                    }
                    Section("Native pipeline") {
                        LabeledContent("Music access", value: native.authorization == .authorized ? "Authorized" : "Not authorized")
                        LabeledContent("Catalog subscription", value: native.subscription)
                        Text("Apple's ApplicationMusicPlayer runs independently of the browser. Successful playback proves native access, not custom DSP access. No audio taps into protected MusicKit playback are used.")
                        Button("Open native playback") { playerMode = .native; showAbout = false }
                    }
                    Section("Safari Extension") {
                        Text("This app also installs Timbre EQ for Safari. In Safari, open the Extensions menu, enable Timbre EQ, and allow access to music.apple.com. The Safari extension has its own presets and settings.")
                        Button("Open Apple Music in Safari") {
                            if let url = URL(string: "https://music.apple.com") {
                                UIApplication.shared.open(url)
                            }
                        }
                        Text("Safari can play your subscribed tracks, but FairPlay-protected audio may not expose samples to the Web Audio EQ. Check the Timbre extension popup for its actual playback status.")
                    }
                    Section("Engine") {
                        Text(gecko.status)
                        Text("Gecko \(GeckoRuntime.version)")
                    }
                    Section("About") {
                        Text("Installed version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                    }
                }.navigationTitle("Apple Music + Timbre")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showAbout = false } } }
            }
        }
        .alert("Apple Music + Timbre", isPresented: Binding(
            get: { gecko.errorMessage != nil },
            set: { if !$0 { gecko.errorMessage = nil } })) {
                Button("OK") { gecko.errorMessage = nil }
            } message: { Text(gecko.errorMessage ?? "") }
    }
}

struct WebKitRadioFallback: UIViewRepresentable {
    let section: MusicSection
    final class Coordinator {
        var section: MusicSection
        init(section: MusicSection) { self.section = section }
    }
    func makeCoordinator() -> Coordinator { Coordinator(section: section) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.load(URLRequest(url: URL(string: section.url)!))
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.section != section else { return }
        context.coordinator.section = section
        view.load(URLRequest(url: URL(string: section.url)!))
    }
}

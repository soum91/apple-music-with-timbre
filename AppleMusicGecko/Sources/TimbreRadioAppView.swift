import SwiftUI
import UIKit
import WebKit
@preconcurrency import GeckoView

private let indigo = Color(red: 99 / 255, green: 102 / 255, blue: 241 / 255)
private let radioURL = "https://music.apple.com/ca/radio"

@MainActor
final class GeckoRadioState: ObservableObject {
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
        session.load(radioURL)
        status = "Apple Music Radio loaded in Gecko. Sign in to your Apple Account to play free live stations."
        Task { await registerTimbre() }
    }

    func reload() { session.reload(flags: 0) }
    func home() { session.load(radioURL) }
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
                    status = "Timbre loaded. Radio playback and DSP still require on-device testing."
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
    @ObservedObject var state: GeckoRadioState
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

struct TimbreRadioAppView: View {
    @StateObject private var gecko = GeckoRadioState()
    @State private var webFallback = false
    @State private var showAbout = false
    @State private var showEQ = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.path").foregroundStyle(indigo)
                Text("Timbre Radio").font(.headline)
                Spacer()
                Button { webFallback.toggle() } label: {
                    Image(systemName: webFallback ? "globe" : "flame")
                }.accessibilityLabel(webFallback ? "Use Gecko" : "Try WebKit for Radio")
                Button { showAbout = true } label: { Image(systemName: "info.circle") }
            }.padding(.horizontal, 14).frame(height: 46)

            if webFallback {
                // WebKit has native FairPlay/HLS support; whether its protected
                // samples are accessible to Timbre is an independent question.
                Text("WebKit comparison only. Timbre EQ is not attached to this player.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 12)
                WebKitRadioFallback()
            } else {
                GeckoViewSurface(state: gecko)
            }

            HStack(spacing: 12) {
                Button { gecko.back() } label: { Image(systemName: "chevron.left") }.disabled(webFallback)
                Button { gecko.forward() } label: { Image(systemName: "chevron.right") }.disabled(webFallback)
                Button { gecko.home() } label: { Image(systemName: "dot.radiowaves.left.and.right") }.disabled(webFallback)
                Button { gecko.reload() } label: { Image(systemName: "arrow.clockwise") }.disabled(webFallback)
                Spacer()
                Button {
                    Task { await gecko.openEQ(); showEQ = gecko.eqPopupURL != nil }
                } label: { Label("Timbre", systemImage: "slider.horizontal.3") }
                    .buttonStyle(.borderedProminent)
                    .disabled(webFallback)
            }.padding(.horizontal).frame(height: 52).background(.regularMaterial)
        }
        .onAppear { gecko.start() }
        .onChange(of: webFallback) { _, fallback in gecko.setVisible(!fallback) }
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
                        Text("Free Apple Music live radio requires an Apple Account sign-in, not a paid subscription.")
                        Text("Gecko + Timbre work on some web audio. Protected Radio playback and audible EQ are not verified.")
                    }
                    Section("Engine") {
                        Text(gecko.status)
                        Text("Gecko \(GeckoRuntime.version)")
                    }
                    Section("About") {
                        Text("Installed version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                    }
                }.navigationTitle("Timbre Radio")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showAbout = false } } }
            }
        }
        .alert("Timbre Radio", isPresented: Binding(
            get: { gecko.errorMessage != nil },
            set: { if !$0 { gecko.errorMessage = nil } })) {
                Button("OK") { gecko.errorMessage = nil }
            } message: { Text(gecko.errorMessage ?? "") }
    }
}

struct WebKitRadioFallback: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.load(URLRequest(url: URL(string: radioURL)!))
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {}
}

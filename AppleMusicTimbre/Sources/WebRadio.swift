import SwiftUI
import WebKit

// Apple serves its own catalog, sign-in and radio player. This view does not
// extract streams or attempt to alter protected media.
@MainActor
final class WebRadioSession: ObservableObject {
    @Published var pageTitle = "Apple Music Radio"
    @Published var address = "music.apple.com"
    @Published var loading = false
    @Published var status = "Start a free radio station, then test Timbre access."
    @Published var eqAvailable = false
    weak var webView: WKWebView?

    func back() { if webView?.canGoBack == true { webView?.goBack() } }
    func forward() { if webView?.canGoForward == true { webView?.goForward() } }
    func reload() {
        eqAvailable = false
        status = "Page reloaded. Start a station before testing Timbre."
        webView?.reload()
    }
    func openSafari() {
        UIApplication.shared.open(webView?.url ?? URL(string: "https://music.apple.com/ca/radio")!)
    }
    func setGain(_ band: Int, _ value: Double) {
        guard eqAvailable, (0..<10).contains(band) else { return }
        webView?.evaluateJavaScript("window.__timbreWeb?.setGain(\(band),\(value));", completionHandler: nil)
    }

    func probe() {
        guard let webView else { return }
        eqAvailable = false
        status = "Testing the audio currently playing on this page…"
        webView.evaluateJavaScript(Self.probeScript) { [weak self] value, error in
            Task { @MainActor in
                if let error { self?.status = "Web audio test failed: \(error.localizedDescription)" }
                else if let value = value as? String { self?.status = value }
            }
        }
    }

    // Use a user-initiated probe. A media element can be routed through Web
    // Audio only when the browser permits it; a zero signal never enables EQ.
    // Reload restores the site's original media routing after a failed probe.
    private static let probeScript = #"""
    (() => {
      if (window.__timbreWeb) return 'Timbre is already connected. Reload to retest.';
      const media = [...document.querySelectorAll('audio,video')]
        .find(el => !el.paused && el.readyState >= 2);
      if (!media) return 'No playing media element is accessible here. Start a station first; the player may be isolated in a frame.';
      if (media.mediaKeys) return 'Protected media detected. Timbre cannot process this player.';
      const Audio = window.AudioContext || window.webkitAudioContext;
      if (!Audio || !Audio.prototype.createMediaElementSource)
        return 'This WebKit player does not expose a Web Audio media source.';
      try {
        const ctx = new Audio();
        const source = ctx.createMediaElementSource(media);
        const frequencies = [32,64,125,250,500,1000,2000,4000,8000,16000];
        const bands = frequencies.map((frequency, index) => {
          const filter = ctx.createBiquadFilter();
          filter.type = index === 0 ? 'lowshelf' : index === 9 ? 'highshelf' : 'peaking';
          filter.frequency.value = frequency;
          filter.Q.value = 1.0;
          return filter;
        });
        const preamp = ctx.createGain();
        preamp.gain.value = 0.5;
        const analyser = ctx.createAnalyser();
        analyser.fftSize = 2048;
        source.connect(bands[0]);
        for (let i = 0; i < bands.length - 1; i++) bands[i].connect(bands[i + 1]);
        bands[bands.length - 1].connect(preamp);
        preamp.connect(analyser);
        analyser.connect(ctx.destination);
        ctx.resume();
        const samples = new Uint8Array(analyser.fftSize);
        let peak = 0;
        let checks = 0;
        const timer = setInterval(() => {
          analyser.getByteTimeDomainData(samples);
          let amplitude = 0;
          for (const sample of samples) amplitude = Math.max(amplitude, Math.abs(sample - 128));
          peak = Math.max(peak, amplitude);
          if (++checks < 12) return;
          clearInterval(timer);
          const accessible = peak > 2 && ctx.state === 'running';
          if (accessible) {
            window.__timbreWeb = {
              setGain: (i, value) => { if (bands[i]) bands[i].gain.value = Math.max(-12, Math.min(12, value)); }
            };
          }
          window.webkit.messageHandlers.timbreProbe.postMessage({
            accessible,
            message: accessible
              ? 'Audio samples detected. Timbre controls are connected to this web player. Compare a large band cut by ear.'
              : (ctx.state !== 'running'
                ? 'Web Audio is suspended. Resume playback and retry after reloading.'
                : 'No audio samples reached Web Audio. This station cannot be equalized through this page. Reload to restore playback.')
          });
        }, 150);
        return 'Checking whether audio samples reach Timbre…';
      } catch (error) {
        return 'Web Audio could not attach: ' + String(error?.message || error) + '. Reload if playback stopped.';
      }
    })();
    """#
}

struct AppleMusicWebsite: UIViewRepresentable {
    @ObservedObject var session: WebRadioSession
    func makeCoordinator() -> Coordinator { Coordinator(session: session) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(context.coordinator, name: "timbreProbe")
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .never
        session.webView = view
        view.load(URLRequest(url: URL(string: "https://music.apple.com/ca/radio")!))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let session: WebRadioSession
        init(session: WebRadioSession) { self.session = session }
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            session.loading = true
            session.eqAvailable = false
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            session.loading = false
            session.address = webView.url?.host ?? "Apple Music"
            session.pageTitle = webView.title ?? "Apple Music"
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            session.loading = false
            session.status = "Page failed: \(error.localizedDescription). Open in Safari to compare."
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            session.loading = false
            session.status = "Page failed: \(error.localizedDescription)."
        }
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url { webView.load(URLRequest(url: url)) }
            return nil
        }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "timbreProbe", let result = message.body as? [String: Any] else { return }
            session.eqAvailable = result["accessible"] as? Bool ?? false
            session.status = result["message"] as? String ?? "No result from audio test."
        }
    }
}

struct WebRadioView: View {
    @StateObject private var session = WebRadioSession()
    @State private var showingEQ = false
    @State private var gains = Array(repeating: 0.0, count: 10)
    private let frequencies = [32,64,125,250,500,1000,2000,4000,8000,16000]
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "waveform").foregroundStyle(Color(red: 99/255, green: 102/255, blue: 241/255))
                Text("Apple Music + Timbre").font(.headline)
                Spacer()
                if session.loading { ProgressView() }
                Button { session.reload() } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Reload Apple Music")
            }.padding(.horizontal).frame(height: 46)
            AppleMusicWebsite(session: session)
            VStack(alignment: .leading, spacing: 8) {
                Text(session.status).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Test Timbre access") { session.probe() }.buttonStyle(.bordered)
                    Button("EQ") { showingEQ = true }.buttonStyle(.borderedProminent).disabled(!session.eqAvailable)
                    Spacer()
                    Button { session.openSafari() } label: { Image(systemName: "safari") }.accessibilityLabel("Open in Safari")
                }
                HStack {
                    Button { session.back() } label: { Image(systemName: "chevron.left") }
                    Button { session.forward() } label: { Image(systemName: "chevron.right") }
                    Text(session.address).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Spacer()
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }.padding(10).background(.regularMaterial)
        }
        .sheet(isPresented: $showingEQ) {
            NavigationStack {
                Form {
                    Section {
                        Text("These controls work only if the access test detects web audio samples. Confirm an audible difference on your device.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Section("Timbre web EQ") {
                        ForEach(0..<frequencies.count, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Text("\(frequencies[index]) Hz  \(Int(gains[index])) dB")
                                Slider(value: $gains[index], in: -12...12, step: 1)
                                    .onChange(of: gains[index]) { _, value in session.setGain(index, value) }
                            }
                        }
                    }
                }.navigationTitle("Timbre")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingEQ = false } } }
            }
        }
    }
}

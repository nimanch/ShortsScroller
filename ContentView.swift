import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var viewModel = ShortsViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ShortsWebView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Overlay controls
            VStack {
                Spacer()
                
                ControlBar(viewModel: viewModel)
                    .padding(.bottom, 30)
            }
        }
        .statusBarHidden(viewModel.isScrolling)
    }
}

struct ControlBar: View {
    @ObservedObject var viewModel: ShortsViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            // Timer selector
            Menu {
                ForEach([3, 5, 8, 10, 15, 20, 30], id: \.self) { seconds in
                    Button("\(seconds)s") {
                        viewModel.scrollInterval = Double(seconds)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text("\(Int(viewModel.scrollInterval))s")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
            }
            
            // Play / Pause toggle
            Button {
                viewModel.toggleScrolling()
            } label: {
                Image(systemName: viewModel.isScrolling ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(viewModel.isScrolling ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                    )
            }
            
            // Progress ring (countdown)
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: viewModel.progress)
                
                Text("\(viewModel.remainingSeconds)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

class ShortsViewModel: ObservableObject {
    @Published var isScrolling = false
    @Published var scrollInterval: Double = 8 {
        didSet {
            if isScrolling {
                restartTimer()
            }
        }
    }
    @Published var progress: Double = 0
    @Published var remainingSeconds: Int = 0
    
    var webView: WKWebView?
    private var scrollTimer: Timer?
    private var countdownTimer: Timer?
    private var elapsed: Double = 0
    
    func toggleScrolling() {
        isScrolling.toggle()
        if isScrolling {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    private func startTimer() {
        elapsed = 0
        remainingSeconds = Int(scrollInterval)
        progress = 0
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsed += 0.1
            self.progress = self.elapsed / self.scrollInterval
            self.remainingSeconds = max(0, Int(ceil(self.scrollInterval - self.elapsed)))
            
            if self.elapsed >= self.scrollInterval {
                self.scrollToNext()
                self.elapsed = 0
                self.progress = 0
                self.remainingSeconds = Int(self.scrollInterval)
            }
        }
    }
    
    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        progress = 0
        remainingSeconds = 0
    }
    
    private func restartTimer() {
        stopTimer()
        startTimer()
    }
    
    func scrollToNext() {
        // Simulate a swipe-up gesture via JS to go to next Short
        let js = """
        (function() {
            // Method 1: Find and click the "next" navigation
            var downBtn = document.querySelector('button[aria-label="Next video"]') ||
                          document.querySelector('#navigation-button-down button');
            if (downBtn) {
                downBtn.click();
                return 'clicked_nav';
            }
            
            // Method 2: Simulate keyboard shortcut (down arrow / j key)
            document.dispatchEvent(new KeyboardEvent('keydown', {key: 'j', code: 'KeyJ', keyCode: 74, bubbles: true}));
            
            // Method 3: Scroll the shorts container
            var container = document.querySelector('ytd-shorts') ||
                            document.querySelector('#shorts-container') ||
                            document.querySelector('ytd-reel-video-renderer');
            if (container) {
                container.scrollBy({top: window.innerHeight, behavior: 'smooth'});
                return 'scrolled';
            }
            
            // Method 4: For mobile web, touch-simulate swipe up
            var el = document.elementFromPoint(window.innerWidth/2, window.innerHeight/2);
            if (el) {
                var startY = window.innerHeight * 0.8;
                var endY = window.innerHeight * 0.2;
                var touchStart = new Touch({identifier: 1, target: el, clientX: window.innerWidth/2, clientY: startY});
                var touchEnd = new Touch({identifier: 1, target: el, clientX: window.innerWidth/2, clientY: endY});
                el.dispatchEvent(new TouchEvent('touchstart', {touches: [touchStart], changedTouches: [touchStart], bubbles: true}));
                setTimeout(function() {
                    el.dispatchEvent(new TouchEvent('touchmove', {touches: [touchEnd], changedTouches: [touchEnd], bubbles: true}));
                    el.dispatchEvent(new TouchEvent('touchend', {touches: [], changedTouches: [touchEnd], bubbles: true}));
                }, 100);
                return 'swiped';
            }
            return 'no_method';
        })()
        """
        webView?.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("Scroll JS error: \(error)")
            } else {
                print("Scroll result: \(String(describing: result))")
            }
        }
    }
}

struct ShortsWebView: UIViewRepresentable {
    @ObservedObject var viewModel: ShortsViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Pretend to be mobile Safari so YouTube serves mobile Shorts UI
        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = userAgent
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator
        
        viewModel.webView = webView
        
        let url = URL(string: "https://m.youtube.com/shorts")!
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let viewModel: ShortsViewModel
        
        init(viewModel: ShortsViewModel) {
            self.viewModel = viewModel
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Inject CSS to hide YouTube's own UI chrome for cleaner experience
            let css = """
            (function() {
                var style = document.createElement('style');
                style.textContent = `
                    ytm-mobile-topbar-renderer,
                    .mobile-topbar-header,
                    ytm-pivot-bar-renderer,
                    .pivot-bar { display: none !important; }
                    body { background: black !important; }
                `;
                document.head.appendChild(style);
            })()
            """
            webView.evaluateJavaScript(css, completionHandler: nil)
        }
    }
}

#Preview {
    ContentView()
}

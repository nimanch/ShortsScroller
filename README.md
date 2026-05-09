# ShortsScroller

Auto-scroll YouTube Shorts on a timer. No YouTube API needed.

## How It Works
- Loads YouTube Shorts in a built-in mobile web view
- Auto-advances to the next Short on a configurable timer (3-30 seconds)
- Shows a countdown ring + play/pause control at the bottom
- Hides YouTube's top/bottom bars for full-screen experience

## Setup
1. Open `ShortsScroller.xcodeproj` in Xcode
2. Set your Development Team in Signing & Capabilities
3. Build & run on your iPhone (or simulator)

## Usage
- App opens directly to YouTube Shorts
- Tap the **green play button** to start auto-scrolling
- Use the **timer menu** (left) to change interval: 3s, 5s, 8s, 10s, 15s, 20s, 30s
- The **countdown ring** (right) shows time until next scroll
- Tap the **red pause button** to stop

## Notes
- Uses WKWebView with mobile Safari user-agent
- YouTube may require sign-in for personalized Shorts feed
- The app won't auto-scroll when backgrounded (iOS suspends timers) — it scrolls while the app is on screen
- Requires iOS 17.0+

## Files
```
ShortsScroller/
├── ShortsScrollerApp.swift    # App entry point
├── ContentView.swift          # UI + WebView + auto-scroll logic
├── Assets.xcassets/           # App icon & assets
└── ShortsScroller.xcodeproj/  # Xcode project
```

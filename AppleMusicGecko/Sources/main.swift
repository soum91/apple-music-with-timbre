import Foundation
import UIKit
@preconcurrency import GeckoView

// Gecko must own the process entry point. A normal SwiftUI @main app never
// starts XRE_main, so its web view cannot render real Gecko pages.
private func configurePersistentProfile() {
    guard let support = FileManager.default.urls(for: .applicationSupportDirectory,
        in: .userDomainMask).first else { return }
    let home = support.appendingPathComponent("TimbreRadioGecko", isDirectory: true)
    let profile = home.appendingPathComponent("Profile", isDirectory: true)
    try? FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
    setenv("HOME", home.path, 1)
    setenv("MOZ_APP_DATA", profile.path, 1)
    setenv("MOZ_LOCAL_APP_DATA", profile.path, 1)
}

configurePersistentProfile()
GeckoRuntime.main(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)

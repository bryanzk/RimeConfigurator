import Foundation

struct AppBundleDescriptor: Equatable {
    let bundleID: String
    let displayName: String

    init?(appURL: URL) {
        guard appURL.pathExtension == "app",
              let bundle = Bundle(url: appURL),
              let bundleID = bundle.bundleIdentifier,
              !bundleID.isEmpty else {
            return nil
        }

        let displayName =
            bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ??
            appURL.deletingPathExtension().lastPathComponent

        self.bundleID = bundleID
        self.displayName = displayName
    }
}

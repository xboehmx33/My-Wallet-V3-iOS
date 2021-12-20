import Foundation

public protocol URLOpener {

    func open(_ url: URL, completionHandler: @escaping (Bool) -> Void)
}

extension URLOpener {

    public func open(_ url: URL) {
        open(url) { _ in }
    }
}

public protocol ExternalAppOpener: URLOpener {

    func openMailApp(completionHandler: @escaping (Bool) -> Void)
    func openSettingsApp(completionHandler: @escaping (Bool) -> Void)
}

public struct ToLogAppOpener: ExternalAppOpener {

    public init() {}

    func log(_ message: Any...) {
        print("📲", "open", message)
    }

    public func open(_ url: URL, completionHandler: @escaping (Bool) -> Void) {
        log(url)
    }

    public func openMailApp(completionHandler: @escaping (Bool) -> Void) {
        log("Mail.app")
    }

    public func openSettingsApp(completionHandler: @escaping (Bool) -> Void) {
        log("Settings.app")
    }
}

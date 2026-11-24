import SwiftUI
import Shared

// The app opens the screen written in Kotlin and hands it the links and the files the system opens the app with.
@main
struct SumizuriApp: App {
    var body: some Scene {
        WindowGroup {
            ComposeView()
                .ignoresSafeArea()
                .onOpenURL { url in
                    if url.isFileURL {
                        openFile(url)
                    } else {
                        IosApp.shared.open(link: url.absoluteString)
                    }
                }
        }
    }

    // A file opened with the app, such as a .sumizuri file from Files or a chat, is copied where the app may read it later, then goes to the import page.
    private func openFile(_ url: URL) {
        let allowed = url.startAccessingSecurityScopedResource()
        defer { if allowed { url.stopAccessingSecurityScopedResource() } }
        let target = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: target)
        guard (try? FileManager.default.copyItem(at: url, to: target)) != nil else { return }
        IosApp.shared.openFile(path: target.path)
    }
}

struct ComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        IosAppKt.MainViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

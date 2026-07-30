import SwiftUI

/// App entry point.
///
/// Builds the macOS menu bar (File / Settings / Help — matching the
/// original `main-frame%`), hosts the three-pane main window, and bootstraps
/// the AppStore on first appear.
@main
struct TasklyApp: App {
  // Brings the app to the foreground on launch. SPM-built executables aren't
  // .app bundles, so the SwiftUI WindowGroup won't steal focus by default and
  // the window can be created hidden; this delegate forces activation.
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  @State private var store = AppStore()

  // Menu-presented sheets.
  @State private var newDbSheet = false
  @State private var aboutSheet = false

  var body: some Scene {
    WindowGroup(L10n.t(.appName)) {
      MainFrameView()
        .environment(store)
        .frame(minWidth: 850, minHeight: 650)
        .task { store.bootstrap() }
        .sheet(isPresented: $newDbSheet) { NewDatabaseSheet() .environment(store) }
        .sheet(isPresented: $aboutSheet) { AboutDialog() .environment(store) }
        // Edit a task: presented when store.editTaskTarget becomes non-nil.
        .sheet(item: Binding(
          get: { store.editTaskTarget },
          set: { store.editTaskTarget = $0 })) { task in
            EditTaskDialog(task: task) .environment(store)
          }
        // Delete confirmation alert.
        .alert(
          L10n.t(.confirmDelete),
          isPresented: Binding(
            get: { store.deleteTaskTarget != nil },
            set: { if !$0 { store.deleteTaskTarget = nil } })
        ) {
          Button(L10n.t(.yes), role: .destructive) {
            if let t = store.deleteTaskTarget { Task { await store.deleteTask(t.id) } }
            store.deleteTaskTarget = nil
          }
          Button(L10n.t(.no), role: .cancel) { store.deleteTaskTarget = nil }
        } message: {
          if let t = store.deleteTaskTarget {
            Text(L10n.t(.confirmDeleteTask, t.text))
          }
        }
    }
    .windowResizability(.contentMinSize)
    .commands {
      // File menu
      CommandGroup(replacing: .newItem) {
        Button(L10n.t(.newDatabase)) { newDbSheet = true }
          .keyboardShortcut("n", modifiers: .command)
        Button(L10n.t(.openDatabase)) { openDatabase() }
          .keyboardShortcut("o", modifiers: .command)
        Button(L10n.t(.closeDatabase)) { Task { await store.disconnectDatabase() } }
          .disabled(!store.isDbConnected)
        Divider()
        Button(L10n.t(.exitApp)) { NSApplication.shared.terminate(nil) }
          .keyboardShortcut("q", modifiers: .command)
      }
      // Settings → Language submenu
      CommandGroup(after: .appSettings) {
        Menu(L10n.t(.language)) {
          Button(L10n.t(.chinese)) { store.setLanguage(.zh) }
          Button(L10n.t(.english)) { store.setLanguage(.en) }
        }
      }
      // Help → About
      CommandGroup(replacing: .help) {
        Button(L10n.t(.about)) { aboutSheet = true }
      }
    }
  }

  /// File → Open Database: native open panel, then connect.
  private func openDatabase() {
    let panel = NSOpenPanel()
    panel.title = L10n.t(.selectDbFile)
    panel.allowedContentTypes = [.data]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    if panel.runModal() == .OK, let url = panel.url {
      Task { await store.connectToDatabase(path: url.path) }
    }
  }
}

/// Forces the app to the foreground on launch (see TasklyApp header).
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.activate(ignoringOtherApps: true)
  }
}

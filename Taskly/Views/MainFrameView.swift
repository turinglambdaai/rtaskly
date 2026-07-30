import SwiftUI

/// The main window: sidebar | divider | task panel, with a status bar
/// underneath. Mirrors the layout of rtaskly's `main-frame%` (a horizontal
/// main-panel holding the sidebar, a 1px divider, and the task panel, over a
/// bottom status bar), styled with the Taskly design system.
struct MainFrameView: View {
  @Environment(AppStore.self) private var store

  var body: some View {
    // Touch languageRevision so localized labels refresh on language change.
    let _ = store.languageRevision

    VStack(spacing: 0) {
      HStack(spacing: 0) {
        SidebarView()
          .frame(minWidth: 240, idealWidth: 256, maxWidth: 320)
          .background(DS.sidebarBackground)
        Divider().opacity(0.6)
        TaskPanelView()
      }
      StatusBar()
    }
    .background(DS.contentBackground)
    .navigationTitle(store.windowTitle)
    .navigationSubtitle(subtitle)
  }

  /// A subtle subtitle under the window title: task count for the current view.
  private var subtitle: String {
    guard store.isDbConnected else { return "" }
    let n = store.tasks.count
    switch store.currentView {
    case "completed": return n == 0 ? "" : "\(n) 完成"
    case "today":     return n == 0 ? "" : "\(n) 今天"
    default:          return n == 0 ? "" : "\(n) 项"
    }
  }
}

/// Bottom status bar. Shows `store.statusMessage`, which auto-resets to
/// "Ready" after 3s (see AppStore.setStatus), matching the original.
struct StatusBar: View {
  @Environment(AppStore.self) private var store

  var body: some View {
    HStack(spacing: DS.Spacing.s) {
      Circle()
        .fill(statusColor)
        .frame(width: 6, height: 6)
      Text(store.statusMessage.isEmpty ? L10n.t(.ready) : store.statusMessage)
        .font(DS.caption())
        .foregroundStyle(DS.secondaryText)
      Spacer()
      if store.isDbConnected {
        Text(store.currentDbPath?.components(separatedBy: "/").last ?? "")
          .font(DS.caption())
          .foregroundStyle(DS.tertiaryText)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, DS.Spacing.xl)
    .padding(.vertical, DS.Spacing.s)
    .background(.bar)
    .overlay(alignment: .top) { Divider().opacity(0.6) }
  }

  private var statusColor: Color {
    store.isDbConnected ? Color.green.opacity(0.8) : DS.tertiaryText
  }
}

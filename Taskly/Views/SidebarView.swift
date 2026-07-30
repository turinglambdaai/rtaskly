import SwiftUI

/// Left sidebar, modeled on macOS Reminders.
///
/// Top section: built-in Smart Lists with their fixed system colors and
/// glyphs — Today (red/orange calendar), Scheduled (blue clock), All (gray),
/// Completed (gray check). (We omit Flagged since rtaskly had no flag field.)
/// Bottom section: "My Lists", each row prefixed with a colored list swatch.
///
/// Selection is a filled rounded rect in the accent tint. The +/- list buttons
/// are present but, like the original rtaskly, left as no-ops (list add/delete
/// via UI was unreachable there; the backend functions exist and are tested).
struct SidebarView: View {
  @Environment(AppStore.self) private var store

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: DS.Spacing.xxl) {
        smartLists
        myLists
      }
      .padding(.vertical, DS.Spacing.xl)
      .padding(.horizontal, DS.Spacing.s)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .task { await store.refreshLists() }
  }

  // MARK: - Smart lists

  private var smartLists: some View {
    VStack(spacing: 2) {
      smartRow(.today, view: "today",
               glyph: "calendar.circle.fill", tint: Color(red: 0.91, green: 0.30, blue: 0.24))
      smartRow(.planned, view: "planned",
               glyph: "clock.fill", tint: Color(red: 0.22, green: 0.50, blue: 0.92))
      smartRow(.all, view: "all",
               glyph: "tray.full.fill", tint: Color(red: 0.55, green: 0.55, blue: 0.58))
      smartRow(.completed, view: "completed",
               glyph: "checkmark.circle.fill", tint: Color(red: 0.30, green: 0.74, blue: 0.40))
    }
  }

  private func smartRow(_ key: LocalizedKey, view: String, glyph: String, tint: Color) -> some View {
    let selected = store.currentView == view
    return Button {
      Task { await store.selectView(view) }
    } label: {
      HStack(spacing: DS.Spacing.m) {
        Image(systemName: glyph)
          .font(.system(size: 14))
          .foregroundStyle(.white)
          .frame(width: 22, height: 22)
          .background(tint, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        Text(L10n.t(key))
          .font(DS.body())
          .foregroundStyle(selected ? DS.primaryText : DS.primaryText)
        Spacer()
        if selected {
          Circle().fill(DS.accent).frame(width: 5, height: 5)
        }
      }
      .contentShape(Rectangle())
      .padding(.vertical, 5)
      .padding(.horizontal, DS.Spacing.m)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        selected ? DS.accent.opacity(0.14) : Color.clear,
        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  // MARK: - My lists

  private var myLists: some View {
    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
      sectionHeader(L10n.t(.myLists))
      ForEach(store.lists, id: \.id) { list in
        listRow(list)
      }
    }
  }

  private func sectionHeader(_ title: String) -> some View {
    HStack {
      Text(title)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(DS.tertiaryText)
      Spacer()
      // Present but no-op, matching the original (see file header).
      Button { /* list add: not wired in original */ } label: {
        Image(systemName: "plus.circle")
          .font(.system(size: 13))
          .foregroundStyle(DS.tertiaryText)
      }
      .buttonStyle(.plain)
      .help(L10n.t(.addNewList))
    }
    .padding(.horizontal, DS.Spacing.m)
    .padding(.bottom, 2)
  }

  private func listRow(_ list: TodoList) -> some View {
    let selected = store.currentView == "list" && store.currentListId == list.id
    // Deterministic per-list color from its name, so each list gets a stable swatch.
    let swatch = listColor(for: list.name)
    return Button {
      Task { await store.selectView("list", listId: list.id, listName: list.name) }
    } label: {
      HStack(spacing: DS.Spacing.m) {
        Image(systemName: "list.bullet")
          .font(.system(size: 12))
          .foregroundStyle(.white)
          .frame(width: 22, height: 22)
          .background(swatch, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        Text(list.name)
          .font(DS.body())
          .foregroundStyle(DS.primaryText)
          .lineLimit(1)
        Spacer()
        if selected {
          Circle().fill(DS.accent).frame(width: 5, height: 5)
        }
      }
      .contentShape(Rectangle())
      .padding(.vertical, 5)
      .padding(.horizontal, DS.Spacing.m)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        selected ? DS.accent.opacity(0.14) : Color.clear,
        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  /// Stable color for a list name (Reminders lets you pick; we derive one so
  /// each list has a distinct swatch without extra UI).
  private func listColor(for name: String) -> Color {
    let palette: [Color] = [
      Color(red: 0.96, green: 0.62, blue: 0.24), // orange
      Color(red: 0.30, green: 0.74, blue: 0.40), // green
      Color(red: 0.34, green: 0.62, blue: 0.92), // blue
      Color(red: 0.78, green: 0.40, blue: 0.74), // purple
      Color(red: 0.88, green: 0.45, blue: 0.40), // red
      Color(red: 0.42, green: 0.74, blue: 0.74), // teal
    ]
    var hash = 0
    for u in name.unicodeScalars { hash = (hash &* 31) &+ Int(u.value) }
    return palette[abs(hash) % palette.count]
  }
}

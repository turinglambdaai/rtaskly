import SwiftUI

/// The reminder list pane, modeled on macOS Reminders.
///
/// Unlike a card list, Reminders uses flat, borderless rows separated by hair
/// lines: a circular checkbox on the left, the reminder text (strikethrough +
/// dimmed when done), an inline colored due-date chip, and actions on hover.
/// The quick-add lives as a subtle + row at the bottom of the list.
struct TaskPanelView: View {
  @Environment(AppStore.self) private var store

  @State private var quickInput: String = ""
  @FocusState private var inputFocused: Bool

  var body: some View {
    let _ = store.languageRevision
    VStack(spacing: 0) {
      if store.showWelcome || !store.isDbConnected {
        ScrollView { welcomeView }
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            header
              .padding(.horizontal, DS.Spacing.xl)
                              .padding(.top, DS.Spacing.xl)
                              .padding(.bottom, DS.Spacing.l)
            taskList
            quickAddRow
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.contentBackground)
    .task { await store.refreshTasks() }
  }

  // MARK: - Header

  private var header: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(panelTitle)
        .font(DS.largeTitle())
        .foregroundStyle(DS.primaryText)
      if !store.tasks.isEmpty {
        Text("\(store.tasks.count)")
          .font(DS.subheadline())
          .foregroundStyle(DS.tertiaryText)
      }
    }
  }

  private var panelTitle: String {
    if store.currentView == "search", let kw = store.currentSearchKeyword {
      return L10n.t(.searchResultsOf, kw)
    }
    switch store.currentView {
    case "today":     return L10n.t(.today)
    case "planned":   return L10n.t(.planned)
    case "all":       return L10n.t(.all)
    case "completed": return L10n.t(.completed)
    case "search":    return L10n.t(.searchResults)
    default:          return store.currentListName.isEmpty ? L10n.t(.all) : store.currentListName
    }
  }

  // MARK: - Task list (flat rows + hairline separators)

  private var taskList: some View {
    VStack(spacing: 0) {
      if store.tasks.isEmpty {
        emptyState
      } else {
        ForEach(Array(store.tasks.enumerated()), id: \.element.id) { idx, task in
          TaskRow(task: task)
          if idx < store.tasks.count - 1 {
            Divider().padding(.leading, 44).opacity(0.5)
          }
        }
      }
    }
  }

  private var emptyState: some View {
    Text(L10n.t(.newTaskPlaceholder))
      .font(DS.body())
      .foregroundStyle(DS.tertiaryText)
      .frame(maxWidth: .infinity)
      .padding(.vertical, DS.Spacing.xxl)
  }

  // MARK: - Quick add (Reminders-style bottom + row)

  private var quickAddRow: some View {
    HStack(spacing: DS.Spacing.m) {
      Image(systemName: inputFocused ? "plus.circle.fill" : "plus.circle")
        .font(.system(size: 18))
        .foregroundStyle(inputFocused ? DS.accent : DS.tertiaryText)
      TextField(L10n.t(.newTaskPlaceholder), text: $quickInput, axis: .vertical)
        .textFieldStyle(.plain)
        .font(DS.body())
        .focused($inputFocused)
        .onSubmit(submit)
    }
    .padding(.horizontal, DS.Spacing.xl)
    .padding(.vertical, DS.Spacing.m)
    .background(
      inputFocused ? DS.accent.opacity(0.05) : Color.clear)
    .overlay(alignment: .top) { Divider().opacity(0.4) }
  }

  private func submit() {
    guard !quickInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
    let snapshot = quickInput
    quickInput = ""
    Task { await store.quickAddTask(text: snapshot) }
  }

  // MARK: - Welcome

  private var welcomeView: some View {
    VStack(spacing: DS.Spacing.l) {
      Image(systemName: "checklist")
        .font(.system(size: 44, weight: .light))
        .foregroundStyle(DS.accent.opacity(0.8))
      Text(L10n.t(.welcomeTitle))
        .font(DS.largeTitle())
        .foregroundStyle(DS.primaryText)
      Text(L10n.t(.createOrOpenHint))
        .font(DS.body())
        .foregroundStyle(DS.secondaryText)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .multilineTextAlignment(.center)
    .padding(DS.Spacing.xxl)
  }
}

/// A single flat reminder row: circular checkbox, text (struck + dimmed when
/// done), inline due chip, hover actions. Matches Reminders' row treatment.
struct TaskRow: View {
  @Environment(AppStore.self) private var store
  let task: TaskItem

  @State private var isHovering = false

  var body: some View {
    let _ = store.tasksRevision
    HStack(alignment: .top, spacing: DS.Spacing.m) {
      Button {
        Task { await store.toggleTask(task.id) }
      } label: {
        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 17, weight: .regular))
          .foregroundStyle(task.completed ? DS.accent : DS.tertiaryText)
      }
      .buttonStyle(.plain)
      .padding(.top, 1)

      VStack(alignment: .leading, spacing: 3) {
        Text(task.text)
          .font(DS.body())
          .foregroundStyle(task.completed ? DS.completedText : DS.primaryText)
          .strikethrough(task.completed)
          .fixedSize(horizontal: false, vertical: true)
        if let due = task.dueDate, !due.isEmpty {
          DueChip(due: due, completed: task.completed)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      HStack(spacing: DS.Spacing.xs) {
        Button { store.editTaskTarget = task } label: {
          Image(systemName: "info.circle")
            .font(.system(size: 13))
            .foregroundStyle(DS.secondaryText)
        }
        .buttonStyle(.plain)
        .help(L10n.t(.edit))
        Button { store.deleteTaskTarget = task } label: {
          Image(systemName: "trash")
            .font(.system(size: 13))
            .foregroundStyle(DS.secondaryText)
        }
        .buttonStyle(.plain)
        .help(L10n.t(.delete))
      }
      .opacity(isHovering ? 1 : 0)
      .padding(.top, 2)
    }
    .padding(.horizontal, DS.Spacing.xl)
    .padding(.vertical, DS.Spacing.m)
    .contentShape(Rectangle())
    .background(isHovering ? DS.primaryText.opacity(0.04) : Color.clear)
    .onHover { isHovering = $0 }
    .onTapGesture(count: 2) { store.editTaskTarget = task }
  }
}

/// Inline due-date chip: small pill with a calendar glyph. Red if overdue,
/// accent if today, secondary otherwise. (Reminders shows due dates as small
/// colored text/chips inline with the reminder.)
struct DueChip: View {
  let due: String
  let completed: Bool

  var body: some View {
    HStack(spacing: 3) {
      Image(systemName: "calendar")
        .font(.system(size: 9))
      Text(formatted)
        .font(DS.monoCaption())
    }
    .foregroundStyle(chipColor)
  }

  private var chipColor: Color {
    if completed { return DS.tertiaryText }
    if isToday { return DS.accent }
    if isPast { return Color(red: 0.91, green: 0.30, blue: 0.24) } // Reminders overdue red
    return DS.secondaryText
  }

  private var formatted: String {
    if due.contains(" ") {
      let parts = due.split(separator: " ")
      let d = String(parts[0]).split(separator: "-")
      guard d.count == 3,
            let y = Int(d[0]), let m = Int(d[1]), let day = Int(d[2]) else { return due }
      let t = parts.count > 1 ? String(parts[1]) : ""
      return String(format: "%04d/%02d/%02d %@", y, m, day, t)
    } else {
      let d = due.split(separator: "-")
      guard d.count == 3,
            let y = Int(d[0]), let m = Int(d[1]), let day = Int(d[2]) else { return due }
      return String(format: "%04d/%02d/%02d", y, m, day)
    }
  }

  private var isToday: Bool { due.hasPrefix(Self.todayString()) }
  private var isPast: Bool { due < Self.todayString() }

  private static func todayString() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: Date())
  }
}

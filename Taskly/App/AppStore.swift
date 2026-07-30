import Foundation
import Observation

/// Central app state, mirroring the fields of rtaskly's `main-frame%`.
///
/// All mutations go through the Noise backend (async). The view layer
/// observes this via `@Observable` and re-renders as `tasks`/`lists`
/// change. UI-facing strings are localized through `L10n`.
@MainActor
@Observable
final class AppStore {

  // --- view state (matches the original parameters) ---
  /// "today" | "planned" | "all" | "completed" | "list" | "search"
  var currentView: String = "list"
  var currentListId: UInt64?
  var currentListName: String = ""
  var currentSearchKeyword: String?

  // --- connection state ---
  var isDbConnected: Bool = false
  var currentDbPath: String?

  // --- data ---
  var tasks: [TaskItem] = []
  var lists: [TodoList] = []

  // --- transient UI ---
  /// One-shot status message; resets to "Ready" after `statusResetSeconds`.
  var statusMessage: String = ""
  var showWelcome: Bool = true

  /// Task currently being edited (non-nil => present the edit sheet).
  var editTaskTarget: TaskItem?
  /// Task awaiting delete confirmation (non-nil => present the alert).
  var deleteTaskTarget: TaskItem?

  /// Bumped whenever tasks change so views can react even when the array
  /// identity is unchanged (e.g. after a toggle).
  var tasksRevision: Int = 0

  /// Bumped on language change so menu/label views re-render (L10n is a
  /// plain enum, not observable, so views reading it need a nudge).
  var languageRevision: Int = 0

  private let appVersion = "0.0.31"
  private let statusResetSeconds: TimeInterval = 3

  // MARK: - Lifecycle

  /// Called once at launch. Loads the saved language, then either reopens
  /// the last DB or leaves the welcome screen showing.
  func bootstrap() {
    if let saved = AppConfig.shared.get("language") {
      L10n.setLanguage(AppLanguage(rawValue: saved) ?? .systemDefault)
    } else {
      L10n.setLanguage(.systemDefault)
    }

    if let last = AppConfig.shared.get("last-db-path"),
       FileManager.default.fileExists(atPath: last) {
      Task { await connectToDatabase(path: last) }
    } else {
      statusMessage = L10n.t(.ready)
    }
  }

  // MARK: - Database

  func connectToDatabase(path: String) async {
    do {
      let ok = try await Backend.shared.connectToDatabase(atPath: path)
      if ok {
        isDbConnected = true
        currentDbPath = path
        AppConfig.shared.set("last-db-path", path)
        await refreshLists()
        await refreshTasks()
        showWelcome = false
        setStatus(L10n.t(.dbConnected))
      } else {
        setStatus(L10n.t(.dbClosed))
      }
    } catch {
      setStatus("\(error)")
    }
  }

  func disconnectDatabase() async {
    guard isDbConnected else { return }
    do {
      try await Backend.shared.closeDatabase()
    } catch {
      setStatus("\(error)")
    }
    isDbConnected = false
    currentDbPath = nil
    tasks = []
    lists = []
    showWelcome = true
    setStatus(L10n.t(.dbClosed))
  }

  // MARK: - Lists

  func refreshLists() async {
    guard isDbConnected else { lists = []; return }
    do {
      lists = try await Backend.shared.getAllLists()
    } catch {
      setStatus("\(error)")
      lists = []
    }
  }

  /// The default list to file a quick-add under when no list is selected.
  /// Mirrors the original's "current-list-id or default-list or first-list".
  func resolveQuickAddListId() async -> UInt64? {
    if let id = currentListId { return id }
    do {
      if let def = try await Backend.shared.getDefaultList() { return def.id }
    } catch { /* fall through */ }
    return lists.first?.id
  }

  // MARK: - Tasks

  func refreshTasks() async {
    guard isDbConnected else { tasks = []; return }
    do {
      tasks = try await Backend.shared.getTasksByView(
        forView: currentView,
        inList: currentListId,
        matching: currentSearchKeyword)
      tasksRevision &+= 1
    } catch {
      setStatus("\(error)")
      tasks = []
    }
  }

  /// Switch the active view (sidebar selection). Persists the selected
  /// list id like the original.
  func selectView(_ view: String, listId: UInt64? = nil, listName: String = "") async {
    currentView = view
    currentListId = listId
    currentListName = listName
    currentSearchKeyword = nil
    if view == "list", let id = listId {
      AppConfig.shared.set("last-selected-list-id", "\(id)")
    }
    await refreshTasks()
    setStatus(L10n.t(.switchedToView, listName))
  }

  /// Quick-add from the top input box. Parses `+Nunit` / `@time` shortcuts
  /// via the backend's parse-date-string RPC (same parser as the original).
  func quickAddTask(text raw: String) async {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    // Split "task text  +modifier" / "task text @modifier" exactly like the
    // original parse-task-input: the modifier is the last ` +...`/` @...` run.
    let (taskText, rawModifier) = parseTaskInput(trimmed)
    guard !taskText.isEmpty else { return }
    // Resolve the modifier through the backend parser (may return nil).
    var dueDate: String? = nil
    if let mod = rawModifier {
      do { dueDate = try await Backend.shared.parseDateString(for: mod) }
      catch { dueDate = nil }
    }
    guard let listId = await resolveQuickAddListId() else {
      setStatus(L10n.t(.dbClosed))
      return
    }
    do {
      let ok = try await Backend.shared.addTask(
        inList: listId, withText: taskText, dueOn: dueDate)
      if ok {
        await refreshLists()
        await refreshTasks()
      }
    } catch {
      setStatus("\(error)")
    }
  }

  func toggleTask(_ id: UInt64) async {
    do {
      _ = try await Backend.shared.toggleTaskCompleted(forId: id)
      await refreshTasks()
    } catch {
      setStatus("\(error)")
    }
  }

  func deleteTask(_ id: UInt64) async {
    do {
      _ = try await Backend.shared.deleteTask(forId: id)
      await refreshTasks()
    } catch {
      setStatus("\(error)")
    }
  }

  func editTask(id: UInt64, listId: UInt64, text: String, dueDate: String?) async {
    do {
      _ = try await Backend.shared.editTask(
        forId: id, inList: listId, withText: text, dueOn: dueDate)
      await refreshTasks()
    } catch {
      setStatus("\(error)")
    }
  }

  // MARK: - Status bar

  nonisolated func setStatus(_ msg: String) {
    Task { @MainActor in
      statusMessage = msg
      let reset = L10n.t(.ready)
      let delay = statusResetSeconds
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        if statusMessage == msg { statusMessage = reset }
      }
    }
  }

  var windowTitle: String {
    if let path = currentDbPath {
      let name = (path as NSString).lastPathComponent
      return "\(name) (\(path)) - Taskly"
    }
    return "Taskly"
  }

  var version: String { appVersion }

  // MARK: - Language

  /// Switch language, persist it, and force all L10n-driven views to refresh.
  func setLanguage(_ lang: AppLanguage) {
    L10n.setLanguage(lang)
    AppConfig.shared.set("language", lang.rawValue)
    languageRevision &+= 1
    setStatus(L10n.t(.ready))
  }

  // MARK: - Task input parsing (mirrors src/gui/task-panel.rkt parse-task-input)

  /// Splits "task text +1d" / "task text @10am" into (text, modifier).
  /// Returns the raw modifier string (or nil); the caller resolves it to a
  /// date through the backend's parse-date-string RPC (same parser as the
  /// original, so `+1d`/`@10am tomorrow`/ISO dates all work identically).
  private func parseTaskInput(_ s: String) -> (String, String?) {
    // Prefer a space-prefixed modifier, else a leading modifier — same
    // regex order as the original.
    if let m = s.range(of: #"\s[+@][0-9]+"#, options: .regularExpression),
       m.lowerBound != s.startIndex {
      let textPart = String(s[..<m.lowerBound]).trimmingCharacters(in: .whitespaces)
      let modifier = String(s[m.lowerBound...]).trimmingCharacters(in: .whitespaces)
      return (textPart, modifier)
    }
    if let m = s.range(of: #"[+@][0-9]+"#, options: .regularExpression) {
      // the modifier run extends from here to the next space (or end)
      let rest = s[m.lowerBound...]
      let endIdx = rest.range(of: " ")?.lowerBound ?? rest.endIndex
      let modifier = String(rest[..<endIdx])
      if modifier == String(s[m.lowerBound...]) {
        let textPart = String(s[..<m.lowerBound]).trimmingCharacters(in: .whitespaces)
        return (textPart, modifier)
      }
    }
    return (s.trimmingCharacters(in: .whitespaces), nil)
  }
}

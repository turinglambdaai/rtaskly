import Foundation

/// Bilingual (zh/en) string catalog.
///
/// Ported from rtaskly's src/gui/language.rkt. The original stored
/// translations keyed by the Chinese string and fell back to the key
/// itself when a translation was missing; here we key by a stable
/// enum case so refactoring display text doesn't break lookups, but the
/// set of strings and their zh/en values match the original 1:1.
///
/// The original app shipped with a couple of fallthrough bugs (e.g. the
/// status bar and the task-input placeholder passed a Chinese key that
/// existed in the table, so behavior was correct there); those strings
/// are included here and resolved the same way.

enum AppLanguage: String, CaseIterable, Codable {
  case zh
  case en

  /// Detect the system language the way the original macOS path did
  /// (match `$LANG` against `^zh`), then fall back to the current locale.
  static var systemDefault: AppLanguage {
    if let lang = ProcessInfo.processInfo.environment["LANG"],
       lang.hasPrefix("zh") {
      return .zh
    }
    return Locale.preferredLanguages.first?.hasPrefix("zh") == true ? .zh : .en
  }
}

/// Resolves a localized string for the current language, with optional
/// positional `~a`-style arguments (mirroring the original `translate`).
///
/// `current` is MainActor-isolated because it is only ever read/written on the
/// main thread (the AppStore that owns language switching is @MainActor).
@MainActor
enum L10n {
  /// The active language. Persisted to ~/.taskly/config.ini as `language`.
  static var current: AppLanguage = .systemDefault

  static func setLanguage(_ lang: AppLanguage) {
    current = lang
  }

  /// Look up `key` for the current language, substituting `args` into any
  /// `~a` placeholders (Racket-style, single-positional). Mirrors the
  /// original `(translate key . args)` fallthrough: an unknown key returns
  /// the key itself.
  static func t(_ key: LocalizedKey, _ args: CVarArg...) -> String {
    var s = key.text(for: current)
    if args.isEmpty { return s }
    for arg in args {
      if let r = s.range(of: "~a") {
        s.replaceSubrange(r, with: "\(arg)")
      }
    }
    return s
  }
}

/// A localizable key. Carries both zh and en text (see the extension
/// below for the per-case mapping).
enum LocalizedKey {
  // Main frame / menus
  case appName, fileMenu, newDatabase, openDatabase, closeDatabase, exitApp
  case helpMenu, about, ready, switchedToView, dbConnected, dbClosed, appInit
  // New database dialog
  case newDbFile, enterDbPath, browse, saveDbFile, ok, cancel
  // Open database dialog
  case selectDbFile
  // About dialog
  case aboutTitle, versionLabel, tagline1, tagline2
  // Sidebar
  case today, planned, all, completed, myLists, addNewList, listNameLabel
  case deleteList, selectListToDelete, confirmDelete, confirmDeleteList
  case yes, no, delete
  // Task panel
  case welcomeTitle, welcomeHeading, selectOrCreateDb, createOrOpenHint
  case quickStartGuide, guide1, guide2, searchResultsOf, searchResults
  case edit, confirmDeleteTask
  // Add/edit task dialog
  case addNewTask, editTask, taskDescLabel, dueDateOptional, taskListLabel
  case invalidDateFmt, invalidDateHint, newTaskPlaceholder
  // Settings menu
  case settings, language, chinese, english
}

extension LocalizedKey {
  /// zh/en text for this key.
  func text(for lang: AppLanguage) -> String {
    switch self {
    // --- main frame / menus ---
    case .appName:            return "Taskly"
    case .fileMenu:           return lang == .zh ? "文件" : "File"
    case .newDatabase:        return lang == .zh ? "新建数据库" : "New Database"
    case .openDatabase:       return lang == .zh ? "打开数据库" : "Open Database"
    case .closeDatabase:      return lang == .zh ? "关闭数据库" : "Close Database"
    case .exitApp:            return lang == .zh ? "退出" : "Exit"
    case .helpMenu:           return lang == .zh ? "帮助" : "Help"
    case .about:              return lang == .zh ? "关于" : "About"
    case .ready:              return lang == .zh ? "就绪" : "Ready"
    case .switchedToView:     return lang == .zh ? "已切换到\"~a\"视图" : "Switched to \"~a\" view"
    case .dbConnected:        return lang == .zh ? "数据库连接成功" : "Database connected successfully"
    case .dbClosed:           return lang == .zh ? "数据库已关闭" : "Database closed"
    case .appInit:            return lang == .zh ? "应用初始化成功" : "Application initialized successfully"
    // --- new database dialog ---
    case .newDbFile:          return lang == .zh ? "新建数据库文件" : "New Database File"
    case .enterDbPath:        return lang == .zh ? "请输入新数据库文件的路径和名称。" : "Please enter the path and name for the new database file."
    case .browse:             return lang == .zh ? "浏览..." : "Browse..."
    case .saveDbFile:         return lang == .zh ? "保存数据库文件" : "Save Database File"
    case .ok:                 return lang == .zh ? "确定" : "OK"
    case .cancel:             return lang == .zh ? "取消" : "Cancel"
    // --- open database dialog ---
    case .selectDbFile:       return lang == .zh ? "选择数据库文件" : "Select Database File"
    // --- about dialog ---
    case .aboutTitle:         return lang == .zh ? "关于 Taskly" : "About Taskly"
    case .versionLabel:       return "V~a"
    case .tagline1:           return lang == .zh ? "极简本地任务管理工具" : "Minimalist Local Task Management Tool"
    case .tagline2:           return lang == .zh ? "完全本地化，用户掌控数据" : "Fully Localized, User Controls Data"
    // --- sidebar ---
    case .today:              return lang == .zh ? "今天" : "Today"
    case .planned:            return lang == .zh ? "计划" : "Planned"
    case .all:                return lang == .zh ? "全部" : "All"
    case .completed:          return lang == .zh ? "完成" : "Completed"
    case .myLists:            return lang == .zh ? "我的列表" : "My Lists"
    case .addNewList:         return lang == .zh ? "添加新列表" : "Add New List"
    case .listNameLabel:      return lang == .zh ? "列表名称:" : "List Name:"
    case .deleteList:         return lang == .zh ? "删除列表" : "Delete List"
    case .selectListToDelete: return lang == .zh ? "选择要删除的列表:" : "Select a list to delete:"
    case .confirmDelete:      return lang == .zh ? "确认删除" : "Confirm Delete"
    case .confirmDeleteList:  return lang == .zh ? "确定要删除列表\"~a\"及其所有任务吗？" : "Are you sure you want to delete the list \"~a\" and all its tasks?"
    case .yes:                return lang == .zh ? "是" : "Yes"
    case .no:                 return lang == .zh ? "否" : "No"
    case .delete:             return lang == .zh ? "删除" : "Delete"
    // --- task panel ---
    case .welcomeTitle:       return lang == .zh ? "欢迎使用 Taskly！" : "Welcome to Taskly!"
    case .welcomeHeading:     return lang == .zh ? "欢迎来到 Taskly" : "Welcome to Taskly"
    case .selectOrCreateDb:   return lang == .zh ? "请选择或创建任务数据库" : "Please select or create a task database"
    case .createOrOpenHint:   return lang == .zh ? "请创建或打开数据库文件以开始使用" : "Please create or open a database file to get started"
    case .quickStartGuide:    return lang == .zh ? "操作指南：" : "Quick Start Guide:"
    case .guide1:             return lang == .zh ? "1. 点击  文件 → 新建数据库  创建新的任务数据库" : "1. Click File → New Database to create a new task database"
    case .guide2:             return lang == .zh ? "2. 或点击  文件 → 打开数据库  使用现有数据库" : "2. Or click File → Open Database to use an existing database"
    case .searchResultsOf:    return lang == .zh ? "搜索结果: \"~a\"" : "Search Results: \"~a\""
    case .searchResults:      return lang == .zh ? "搜索结果" : "Search Results"
    case .edit:               return lang == .zh ? "编辑" : "Edit"
    case .confirmDeleteTask:  return lang == .zh ? "确定要删除任务\"~a\"吗？" : "Are you sure you want to delete the task \"~a\"?"
    // --- add/edit task dialog ---
    case .addNewTask:         return lang == .zh ? "添加新任务" : "Add New Task"
    case .editTask:           return lang == .zh ? "编辑任务" : "Edit Task"
    case .taskDescLabel:      return lang == .zh ? "任务描述:" : "Task Description:"
    case .dueDateOptional:    return lang == .zh ? "截止日期 (可选):" : "Due Date (Optional):"
    case .taskListLabel:      return lang == .zh ? "任务列表:" : "Task List:"
    case .invalidDateFmt:     return lang == .zh ? "日期格式错误" : "Invalid Date Format"
    case .invalidDateHint:    return lang == .zh ? "请输入正确的日期格式，例如: +1d, @10am, 2025-08-07" : "Please enter a valid date format, e.g.: +1d, @10am, 2025-08-07"
    case .newTaskPlaceholder: return lang == .zh ? "添加新任务..." : "Add new task..."
    // --- settings menu ---
    case .settings:           return lang == .zh ? "设置" : "Settings"
    case .language:           return lang == .zh ? "语言" : "Language"
    case .chinese:            return "中文"
    case .english:            return "English"
    }
  }
}

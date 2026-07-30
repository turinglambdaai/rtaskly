import SwiftUI

/// "New Database File" sheet. Enter a path (defaulted to ~/.taskly/tasks.db),
/// optionally Browse, auto-append .db if missing, then connect.
///
/// Mirrors rtaskly's show-new-database-dialog: a path field pre-filled with
/// get-default-db-path, a Browse... button, and OK/Cancel. OK auto-appends
/// `.db` if the path has no extension.
struct NewDatabaseSheet: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  @State private var path: String = AppConfig.defaultDbPath

  var body: some View {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
      HStack(spacing: DS.Spacing.m) {
        Image(systemName: "cylinder.split.1x2")
          .font(.system(size: 20))
          .foregroundStyle(DS.accent)
        Text(L10n.t(.newDbFile))
          .font(DS.title())
          .foregroundStyle(DS.primaryText)
      }
      Text(L10n.t(.enterDbPath))
        .font(DS.body())
        .foregroundStyle(DS.secondaryText)

      HStack(spacing: DS.Spacing.s) {
        Image(systemName: "folder")
          .foregroundStyle(DS.tertiaryText)
        TextField("", text: $path)
          .textFieldStyle(.plain)
          .font(DS.monoCaption())
      }
      .padding(.horizontal, DS.Spacing.m)
      .padding(.vertical, DS.Spacing.s)
      .background(DS.cardBackground, in: RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
          .stroke(DS.separator, lineWidth: 0.5))

      HStack(spacing: DS.Spacing.s) {
        Button(L10n.t(.browse)) { browse() }
        Spacer()
        Button(L10n.t(.cancel), role: .cancel) { dismiss() }
          .keyboardShortcut(.cancelAction)
        Button(L10n.t(.ok)) { confirm() }
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.borderedProminent)
          .disabled(path.trimmingCharacters(in: .whitespaces).isEmpty)
      }
    }
    .padding(DS.Spacing.xxl)
    .frame(width: 480)
  }

  private func browse() {
    let panel = NSSavePanel()
    panel.title = L10n.t(.saveDbFile)
    panel.allowedContentTypes = [.data]
    if panel.runModal() == .OK, let url = panel.url {
      path = ensureDbExtension(url.path)
    }
  }

  private func confirm() {
    let final = ensureDbExtension(path.trimmingCharacters(in: .whitespaces))
    dismiss()
    Task { await store.connectToDatabase(path: final) }
  }

  /// Append ".db" when the path has no extension (matches path-add-extension).
  private func ensureDbExtension(_ p: String) -> String {
    let name = (p as NSString).lastPathComponent
    if name.contains(".") { return p }
    return p + ".db"
  }
}

/// "About Taskly" sheet. App icon, name, version, two taglines.
struct AboutDialog: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: DS.Spacing.l) {
      Image(systemName: "checklist")
        .font(.system(size: 40, weight: .light))
        .foregroundStyle(DS.accent)
      Text(L10n.t(.appName))
        .font(DS.largeTitle())
        .foregroundStyle(DS.primaryText)
      Text("V\(store.version)")
        .font(DS.subheadline())
        .foregroundStyle(DS.tertiaryText)
      VStack(spacing: DS.Spacing.xs) {
        Text(L10n.t(.tagline1))
        Text(L10n.t(.tagline2))
      }
      .font(DS.body())
      .foregroundStyle(DS.secondaryText)
      Button(L10n.t(.ok)) { dismiss() }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .padding(.top, DS.Spacing.s)
    }
    .padding(DS.Spacing.xxl)
    .frame(width: 320)
  }
}

/// "Edit Task" sheet. Fields: description (multi-line), due date (optional,
/// parsed via the backend's +Nunit / @time / ISO forms), and the owning
/// list (dropdown). Mirrors rtaskly's show-edit-task-dialog.
///
/// On save, if a date was entered but doesn't parse, show an error (the
/// original's "Invalid Date Format" message-box) and stay open.
struct EditTaskDialog: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  let task: TaskItem

  @State private var text: String = ""
  @State private var dueDate: String = ""
  @State private var listId: UInt64 = 0
  @State private var showError: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
      HStack(spacing: DS.Spacing.m) {
        Image(systemName: "pencil.line")
          .font(.system(size: 18))
          .foregroundStyle(DS.accent)
        Text(L10n.t(.editTask))
          .font(DS.title())
          .foregroundStyle(DS.primaryText)
      }

      fieldLabel(L10n.t(.taskDescLabel))
      TextEditor(text: $text)
        .font(DS.body())
        .scrollContentBackground(.hidden)
        .background(DS.cardBackground)
        .frame(minHeight: 88)
        .overlay(
          RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
            .stroke(DS.separator, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous))

      fieldLabel(L10n.t(.dueDateOptional))
      HStack(spacing: DS.Spacing.s) {
        Image(systemName: "calendar")
          .foregroundStyle(DS.tertiaryText)
        TextField("+1d, @10am, 2025-08-07", text: $dueDate)
          .textFieldStyle(.plain)
          .font(DS.monoCaption())
      }
      .padding(.horizontal, DS.Spacing.m)
      .padding(.vertical, DS.Spacing.s)
      .background(DS.cardBackground, in: RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
          .stroke(DS.separator, lineWidth: 0.5))

      fieldLabel(L10n.t(.taskListLabel))
      Picker("", selection: $listId) {
        ForEach(store.lists, id: \.id) { l in
          Text(l.name).tag(l.id)
        }
      }
      .labelsHidden()

      if showError {
        HStack(spacing: DS.Spacing.xs) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.orange)
          VStack(alignment: .leading, spacing: 2) {
            Text(L10n.t(.invalidDateFmt)).font(DS.headline()).foregroundStyle(.orange)
            Text(L10n.t(.invalidDateHint)).font(DS.caption()).foregroundStyle(DS.secondaryText)
          }
        }
      }

      HStack {
        Spacer()
        Button(L10n.t(.cancel), role: .cancel) { dismiss() }
        Button(L10n.t(.ok)) { save() }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(DS.Spacing.xxl)
    .frame(width: 460)
    .onAppear { populate() }
  }

  private func fieldLabel(_ s: String) -> some View {
    Text(s).font(DS.headline()).foregroundStyle(DS.secondaryText)
  }

  private func populate() {
    text = task.text
    dueDate = task.dueDate ?? ""
    listId = task.listId
  }

  private func save() {
    let trimmedDue = dueDate.trimmingCharacters(in: .whitespaces)
    Task {
      // If a date was entered, validate it via the backend parser first:
      // parse-date-string returns nil when the input can't be parsed, and
      // that's the original's "Invalid Date Format" case.
      if !trimmedDue.isEmpty {
        let parsed = try? await Backend.shared.parseDateString(for: trimmedDue)
        if let due = parsed {
          await commit(due: due)
        } else {
          showError = true
        }
      } else {
        await commit(due: nil)
      }
    }
  }

  private func commit(due: String?) async {
    await store.editTask(id: task.id, listId: listId, text: text, dueDate: due)
    dismiss()
  }
}

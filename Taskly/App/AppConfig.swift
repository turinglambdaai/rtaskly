import Foundation

/// Reads/writes ~/.taskly/config.ini.
///
/// Mirrors rtaskly's src/utils/path.rkt INI store so config is shared with
/// the original app: one `key=value` per line, `;` comments. Used here for
/// `last-db-path` (remember the last DB between launches) and `language`.
struct AppConfig {
  static let shared = AppConfig()

  private let url: URL = {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let dir = home.appendingPathComponent(".taskly")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("config.ini")
  }()

  /// Default DB location: ~/.taskly/tasks.db (matches the backend's
  /// get-default-db-path RPC and the original app).
  static var defaultDbPath: String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent(".taskly/tasks.db").path
  }

  func get(_ key: String, default fallback: String? = nil) -> String? {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return fallback }
    for raw in text.split(separator: "\n", omittingEmptySubsequences: true) {
      let line = raw.trimmingCharacters(in: .whitespaces)
      if line.isEmpty || line.hasPrefix(";") { continue }
      guard let eq = line.firstIndex(of: "=") else { continue }
      let k = line[..<eq].trimmingCharacters(in: .whitespaces)
      let v = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
      if k == key { return v }
    }
    return fallback
  }

  func set(_ key: String, _ value: String) {
    var pairs = readAll()
    pairs[key] = value
    let body = pairs.sorted(by: { $0.key < $1.key })
      .map { "\($0.key)=\($0.value)" }
      .joined(separator: "\n")
    try? (body + "\n").write(to: url, atomically: true, encoding: .utf8)
  }

  private func readAll() -> [String: String] {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
    var out: [String: String] = [:]
    for raw in text.split(separator: "\n", omittingEmptySubsequences: true) {
      let line = raw.trimmingCharacters(in: .whitespaces)
      if line.isEmpty || line.hasPrefix(";") { continue }
      guard let eq = line.firstIndex(of: "=") else { continue }
      let k = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
      let v = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
      out[k] = v
    }
    return out
  }
}

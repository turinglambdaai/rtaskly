import Foundation

/// App-wide Noise backend singleton.
///
/// Points the generated `Backend` client at the bundled `res/core.zo`
/// module bundle and tells it to run the `main` procedure in the `main`
/// module (see taskly-core/main.rkt). The Racket server boots on a
/// background thread inside `NoiseBackend.Backend` and the Swift side
/// talks to it over a pair of pipes.
///
/// **Finding core.zo.** An SPM `executableTarget` is *not* an `.app`
/// bundle: `Bundle.main` points at the executable file itself, which does
/// not carry the `.copy("res")` resources. Those land in the module's
/// resource bundle (reachable via `Bundle.module`). So we look, in order:
///   1. `Bundle.module` → "res/core.zo" (the normal SPM case)
///   2. the executable's own directory (running from `.build/debug`)
///   3. `Taskly/res/core.zo` next to the executable (dev layout)
extension Backend {
  static let shared: Backend = {
    let zo = findCoreZo()
    return Backend(withZo: zo, andMod: "main", andProc: "main")
  }()

  /// Resolves the embedded Racket bundle URL, with fallbacks for the various
  /// ways the app may be launched (SPM executable, dev tree, bundled .app).
  private static func findCoreZo() -> URL {
    // 1. SPM module resource bundle.
    if let url = Bundle.module.url(forResource: "res/core", withExtension: "zo") {
      return url
    }
    // 2. Bundle.main (a real .app bundle, when packaged for distribution).
    if let url = Bundle.main.url(forResource: "res/core", withExtension: "zo") {
      return url
    }
    // 3. The executable's own directory — SPM runs leave the module bundle a
    //    couple of levels up, but core.zo may be reachable via the build dir.
    let execDir = Bundle.main.bundleURL
    let candidates: [URL] = [
      execDir.appendingPathComponent("res/core.zo"),
      execDir.appendingPathComponent("Taskly/res/core.zo"),
      // .build/debug/Taskly  ->  ../arm64-apple-macosx/debug/Taskly_Taskly.bundle/res/core.zo
      execDir
        .deletingLastPathComponent()
        .appendingPathComponent("arm64-apple-macosx/debug/Taskly_Taskly.bundle/res/core.zo"),
    ]
    for c in candidates where FileManager.default.fileExists(atPath: c.path) {
      return c
    }
    // Last resort: a clear message instead of a nil-unwrap crash.
    fatalError("""
      res/core.zo not found. Build it first with `make`, then `swift build`.
      Looked in Bundle.module, Bundle.main, and: \(candidates.map(\.path))
      """)
  }
}

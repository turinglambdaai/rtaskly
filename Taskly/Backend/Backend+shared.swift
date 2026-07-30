import Foundation

/// App-wide Noise backend singleton.
///
/// Points the generated `Backend` client at the bundled `res/core.zo`
/// module bundle and tells it to run the `main` procedure in the `main`
/// module (see taskly-core/main.rkt). The Racket server boots on a
/// background thread inside `NoiseBackend.Backend` and the Swift side
/// talks to it over a pair of pipes.
///
/// For noise-serde-lib 0.10 the runtime + all compiled modules (including
/// `db`/sqlite3) are baked into `core.zo`, so no external collects dir or
/// boot-argument configuration is needed on macOS — only the system
/// libsqlite3.dylib (shipped with macOS).
extension Backend {
  static let shared = Backend(
    withZo: Bundle.main.url(forResource: "res/core", withExtension: "zo")!,
    andMod: "main",
    andProc: "main")
}

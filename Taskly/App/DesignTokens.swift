import SwiftUI

/// Design system for Taskly.
///
/// Centralizes color, typography, spacing, corner-radius and shadow tokens so
/// every view draws from one palette and the look stays consistent. Colors are
/// adaptive (light/dark) via `Color(nsColor:)` + semantic assets, so the app
/// follows the system appearance automatically.
enum DS {

  // MARK: - Color

  /// Window content background (slightly off-white in light, near-black in dark).
  static let contentBackground = Color(nsColor: .windowBackgroundColor)

  /// Sidebar background — a touch lighter/darker than content for separation.
  static let sidebarBackground = Color(nsColor: .controlBackgroundColor)

  /// Card / row surface that sits on top of contentBackground.
  static let cardBackground = Color(nsColor: .textBackgroundColor)

  /// Subtle separators and borders.
  static let separator = Color(nsColor: .separatorColor)

  /// Primary accent (selections, focus rings, the "→" marker).
  static let accent = Color.accentColor

  // MARK: - Text

  static let primaryText = Color(nsColor: .labelColor)
  static let secondaryText = Color(nsColor: .secondaryLabelColor)
  static let tertiaryText = Color(nsColor: .tertiaryLabelColor)

  /// Completed-task text — muted, slightly grayer than secondary.
  static let completedText = Color(nsColor: .tertiaryLabelColor)

  // MARK: - Typography

  /// Font choices. Uses the system font so it picks up SF Pro + Dynamic Type.
  static func largeTitle() -> Font { .system(size: 26, weight: .bold) }
  static func title() -> Font { .system(size: 19, weight: .semibold) }
  static func headline() -> Font { .system(size: 13, weight: .semibold) }
  static func body() -> Font { .system(size: 13, weight: .regular) }
  static func subheadline() -> Font { .system(size: 12, weight: .regular) }
  static func caption() -> Font { .system(size: 11, weight: .regular) }
  static func monoCaption() -> Font { .system(size: 11, weight: .regular, design: .monospaced) }

  // MARK: - Spacing

  enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 6
    static let m: CGFloat = 8
    static let l: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
  }

  // MARK: - Radii

  static let cardRadius: CGFloat = 10
  static let controlRadius: CGFloat = 7
  static let badgeRadius: CGFloat = 5

  // MARK: - Shadow

  /// A soft shadow used under cards / the quick-add field.
  static let softShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
    color: Color.black.opacity(0.06),
    radius: 6,
    x: 0,
    y: 2
  )
}

/// Convenience view modifiers built on the tokens.
extension View {
  /// Card surface: rounded rect on cardBackground with a soft shadow + border.
  func dsCard(padding: CGFloat = DS.Spacing.l) -> some View {
    self
      .padding(padding)
      .background(DS.cardBackground, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
          .stroke(DS.separator, lineWidth: 0.5))
      .shadow(color: DS.softShadow.color, radius: DS.softShadow.radius, x: DS.softShadow.x, y: DS.softShadow.y)
  }
}

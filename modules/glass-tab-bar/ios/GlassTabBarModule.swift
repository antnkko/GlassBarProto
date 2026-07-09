import ExpoModulesCore

public class GlassTabBarModule: Module {
  public func definition() -> ModuleDefinition {
    Name("GlassTabBar")

    // First view stays the module default; the toolbar registers as a named
    // view (SwiftUI views are exported under their class name).
    View(GlassTabBarExpoView.self)
    View(GlassToolbarExpoView.self)
  }
}

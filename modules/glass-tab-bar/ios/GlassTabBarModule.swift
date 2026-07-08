import ExpoModulesCore

public class GlassTabBarModule: Module {
  public func definition() -> ModuleDefinition {
    Name("GlassTabBar")

    View(GlassTabBarExpoView.self)
  }
}

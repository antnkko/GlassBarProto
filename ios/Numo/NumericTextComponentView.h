#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Fabric leaf for a single line of text rendered with SwiftUI's real
/// `.contentTransition(.numericText())` (Apple's per-glyph roll + blur). Lives
/// in the APP target: the generated provider resolves it by class name, and
/// the Obviously fonts live in the main bundle.
@interface NumericTextComponentView : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END

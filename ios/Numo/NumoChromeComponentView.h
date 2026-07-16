#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Fabric leaf for the redesigned screen's top chrome (Stage 50): the
/// ✕ + publicity/tags pill ⇄ Clear + ✓ Liquid Glass clusters and the centered
/// "When" title, hosted SwiftUI. The cluster swap animates internally on the
/// native springs when `pickerOpen` flips; the RN flow animates only this
/// leaf's container (entrance drop / close crop). Lives in the APP target —
/// the generated provider resolves it by class name, and the GlassButton /
/// PublicityTagsPill sources live here.
@interface NumoChromeComponentView : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END

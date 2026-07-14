#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Fabric shell for the braindump flow overlay (SwiftUI screens from the
/// NumoPrototype donor, hosted transparently over the RN screen). Lives in
/// the APP target: the generated provider resolves it by class name.
@interface NumoFlowComponentView : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END

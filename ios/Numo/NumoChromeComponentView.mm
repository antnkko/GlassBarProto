#import "NumoChromeComponentView.h"

#import <React/RCTConversions.h>
#import <react/renderer/components/GlassBarSpec/ComponentDescriptors.h>
#import <react/renderer/components/GlassBarSpec/EventEmitters.h>
#import <react/renderer/components/GlassBarSpec/Props.h>
#import <react/renderer/components/GlassBarSpec/RCTComponentViewHelpers.h>

// Deliberately NOT importing GlassBarProto-Swift.h (drags in Expo AppDelegate
// superclasses ObjC++ can't resolve) — a minimal local declaration of the
// Swift host is enough; the class itself lives in the app binary.
@interface NumoChromeHostView : UIView
@property (nonatomic, copy, nullable) void (^onChromePress)(NSString *_Nonnull);
- (void)updateWithPickerOpen:(BOOL)pickerOpen
                 pickerTitle:(NSString *_Nonnull)pickerTitle
                         tag:(NSString *_Nonnull)tag
                 useSafeArea:(BOOL)useSafeArea
               shadowOpacity:(double)shadowOpacity
                shadowRadius:(double)shadowRadius;
@end

using namespace facebook::react;

@interface NumoChromeComponentView () <RCTNumoChromeViewProtocol>
@end

@implementation NumoChromeComponentView {
  NumoChromeHostView *_hostView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<NumoChromeComponentDescriptor>();
}

// The SwiftUI tree owns animated swap state — never recycle.
+ (BOOL)shouldBeRecycled
{
  return NO;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const NumoChromeProps>();
    _props = defaultProps;

    _hostView = [[NumoChromeHostView alloc] initWithFrame:self.bounds];

    __weak __typeof(self) weakSelf = self;
    _hostView.onChromePress = ^(NSString *element) {
      __typeof(self) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      if (auto emitter = std::static_pointer_cast<const NumoChromeEventEmitter>(strongSelf->_eventEmitter)) {
        emitter->onChromePress({.element = std::string([element UTF8String])});
      }
    };

    self.contentView = _hostView;
  }
  return self;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<const NumoChromeProps>(props);

  [_hostView updateWithPickerOpen:newProps.pickerOpen
                      pickerTitle:RCTNSStringFromString(newProps.pickerTitle)
                              tag:RCTNSStringFromString(newProps.tag)
                      useSafeArea:newProps.useSafeArea
                    shadowOpacity:newProps.shadowOpacity
                     shadowRadius:newProps.shadowRadius];

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> NumoChromeCls(void)
{
  return NumoChromeComponentView.class;
}

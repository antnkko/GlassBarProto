#import "NumoFlowComponentView.h"

#import <React/RCTConversions.h>
#import <react/renderer/components/GlassBarSpec/ComponentDescriptors.h>
#import <react/renderer/components/GlassBarSpec/EventEmitters.h>
#import <react/renderer/components/GlassBarSpec/Props.h>
#import <react/renderer/components/GlassBarSpec/RCTComponentViewHelpers.h>

// Deliberately NOT importing GlassBarProto-Swift.h: the app-wide generated
// header drags in the Expo AppDelegate superclasses, which ObjC++ (no clang
// modules) cannot resolve. A minimal local declaration of the Swift host is
// enough — the class itself lives in the app binary.
@interface NumoFlowHostView : UIView
@property (nonatomic, copy, nullable) void (^onFlowEvent)(NSString *_Nonnull);
- (void)updateWithMode:(NSString *_Nonnull)mode
                   seq:(NSInteger)seq
         shadowOpacity:(double)shadowOpacity
          shadowRadius:(double)shadowRadius
           rnBottomBar:(BOOL)rnBottomBar
        whenPickerOpen:(BOOL)whenPickerOpen;
- (void)tearDown;
@end

using namespace facebook::react;

@interface NumoFlowComponentView () <RCTNumoFlowViewProtocol>
@end

@implementation NumoFlowComponentView {
  NumoFlowHostView *_hostView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<NumoFlowComponentDescriptor>();
}

// The SwiftUI tree owns the flow coordinator state — never recycle.
+ (BOOL)shouldBeRecycled
{
  return NO;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const NumoFlowProps>();
    _props = defaultProps;

    _hostView = [[NumoFlowHostView alloc] initWithFrame:self.bounds];

    __weak __typeof(self) weakSelf = self;
    _hostView.onFlowEvent = ^(NSString *type) {
      __typeof(self) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      if (auto emitter = std::static_pointer_cast<const NumoFlowEventEmitter>(strongSelf->_eventEmitter)) {
        emitter->onFlowEvent({.type = std::string([type UTF8String])});
      }
    };

    self.contentView = _hostView;
  }
  return self;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<const NumoFlowProps>(props);

  [_hostView updateWithMode:RCTNSStringFromString(newProps.mode)
                        seq:newProps.seq
              shadowOpacity:newProps.shadowOpacity
               shadowRadius:newProps.shadowRadius
                rnBottomBar:newProps.rnBottomBar
             whenPickerOpen:newProps.whenPickerOpen];

  [super updateProps:props oldProps:oldProps];
}

- (void)prepareForRecycle
{
  [_hostView tearDown];
  [super prepareForRecycle];
}

@end

Class<RCTComponentViewProtocol> NumoFlowCls(void)
{
  return NumoFlowComponentView.class;
}

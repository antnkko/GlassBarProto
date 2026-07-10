#import "GlassToolbarComponentView.h"

#import <React/RCTConversions.h>
#import <react/renderer/components/GlassBarSpec/ComponentDescriptors.h>
#import <react/renderer/components/GlassBarSpec/EventEmitters.h>
#import <react/renderer/components/GlassBarSpec/Props.h>
#import <react/renderer/components/GlassBarSpec/RCTComponentViewHelpers.h>

#import "GlassTabBar-Swift.h"

using namespace facebook::react;

@interface GlassToolbarComponentView () <RCTGlassToolbarViewProtocol>
@end

@implementation GlassToolbarComponentView {
  GlassToolbarHostView *_hostView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<GlassToolbarComponentDescriptor>();
}

+ (BOOL)shouldBeRecycled
{
  return NO;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const GlassToolbarProps>();
    _props = defaultProps;

    _hostView = [[GlassToolbarHostView alloc] initWithFrame:self.bounds];

    __weak __typeof(self) weakSelf = self;
    _hostView.onToolbarPress = ^(NSString *element, NSInteger seq) {
      __typeof(self) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      if (auto emitter = std::static_pointer_cast<const GlassToolbarEventEmitter>(strongSelf->_eventEmitter)) {
        emitter->onToolbarPress({.element = std::string([element UTF8String]), .seq = static_cast<int>(seq)});
      }
    };

    self.contentView = _hostView;
  }
  return self;
}

static NSDictionary *GlassToolbarConfigDict(const GlassToolbarConfigStruct &c)
{
  return @{
    @"milkOpacity" : @(c.milkOpacity),
    @"accentHex" : RCTNSStringFromString(c.accentHex),
    @"lightHex" : RCTNSStringFromString(c.lightHex),
    @"midHex" : RCTNSStringFromString(c.midHex),
    @"highlightBlend" : RCTNSStringFromString(c.highlightBlend),
    @"highlightOpacity" : @(c.highlightOpacity),
    @"appearance" : RCTNSStringFromString(c.appearance),
    @"containerSpacing" : @(c.containerSpacing),
    @"springDuration" : @(c.springDuration),
    @"springBounce" : @(c.springBounce),
    @"pillWidth" : @(c.pillWidth),
    @"pillHeight" : @(c.pillHeight),
    @"innerPadding" : @(c.innerPadding),
    @"gap" : @(c.gap),
    @"hPadding" : @(c.hPadding),
    @"subTabSpacing" : @(c.subTabSpacing),
    @"iconSize" : @(c.iconSize),
    @"plusIconSize" : @(c.plusIconSize),
    @"strokeMode" : RCTNSStringFromString(c.strokeMode),
  };
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<const GlassToolbarProps>(props);

  [_hostView updateWithOption:newProps.option config:GlassToolbarConfigDict(newProps.config)];

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> GlassToolbarCls(void)
{
  return GlassToolbarComponentView.class;
}

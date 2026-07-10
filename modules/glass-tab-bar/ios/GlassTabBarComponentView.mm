#import "GlassTabBarComponentView.h"

#import <React/RCTConversions.h>
#import <react/renderer/components/GlassBarSpec/ComponentDescriptors.h>
#import <react/renderer/components/GlassBarSpec/EventEmitters.h>
#import <react/renderer/components/GlassBarSpec/Props.h>
#import <react/renderer/components/GlassBarSpec/RCTComponentViewHelpers.h>

#import "GlassTabBar-Swift.h"

using namespace facebook::react;

@interface GlassTabBarComponentView () <RCTGlassTabBarViewProtocol>
@end

@implementation GlassTabBarComponentView {
  GlassTabBarHostView *_hostView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<GlassTabBarComponentDescriptor>();
}

// The SwiftUI tree inside is stateful (glass namespaces, optimistic seq
// state) — recycling a mounted instance across screens would leak it.
+ (BOOL)shouldBeRecycled
{
  return NO;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const GlassTabBarProps>();
    _props = defaultProps;

    _hostView = [[GlassTabBarHostView alloc] initWithFrame:self.bounds];

    __weak __typeof(self) weakSelf = self;
    _hostView.onTabPress = ^(NSString *tab, NSInteger seq) {
      __typeof(self) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      if (auto emitter = std::static_pointer_cast<const GlassTabBarEventEmitter>(strongSelf->_eventEmitter)) {
        emitter->onTabPress({.tab = std::string([tab UTF8String]), .seq = static_cast<int>(seq)});
      }
    };
    _hostView.onSubTabPress = ^(NSString *tab, NSInteger seq) {
      __typeof(self) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      if (auto emitter = std::static_pointer_cast<const GlassTabBarEventEmitter>(strongSelf->_eventEmitter)) {
        emitter->onSubTabPress({.tab = std::string([tab UTF8String]), .seq = static_cast<int>(seq)});
      }
    };
    _hostView.onExpandChange = ^(BOOL expanded, NSInteger seq) {
      __typeof(self) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      if (auto emitter = std::static_pointer_cast<const GlassTabBarEventEmitter>(strongSelf->_eventEmitter)) {
        emitter->onExpandChange({.expanded = static_cast<bool>(expanded), .seq = static_cast<int>(seq)});
      }
    };

    self.contentView = _hostView;
  }
  return self;
}

static NSDictionary *GlassTabBarConfigDict(const GlassTabBarConfigStruct &c)
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
    @"glassVariant" : RCTNSStringFromString(c.glassVariant),
    @"glassInteractive" : @(c.glassInteractive),
    @"shadowMode" : RCTNSStringFromString(c.shadowMode),
    @"shadowOpacityScale" : @(c.shadowOpacityScale),
    @"shadowRadiusScale" : @(c.shadowRadiusScale),
  };
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<const GlassTabBarProps>(props);

  [_hostView updateWithExpanded:newProps.expanded
                      activeTab:RCTNSStringFromString(newProps.activeTab)
                        lastSeq:newProps.lastSeq
                      collapsed:newProps.collapsed
                         config:GlassTabBarConfigDict(newProps.config)];

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> GlassTabBarCls(void)
{
  return GlassTabBarComponentView.class;
}

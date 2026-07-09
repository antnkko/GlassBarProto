#import "GlassEdgeComponentView.h"

#import <React/RCTConversions.h>
#import <react/renderer/components/GlassBarSpec/ComponentDescriptors.h>
#import <react/renderer/components/GlassBarSpec/Props.h>
#import <react/renderer/components/GlassBarSpec/RCTComponentViewHelpers.h>

#import "GlassTabBar-Swift.h"

using namespace facebook::react;

@interface GlassEdgeComponentView () <RCTGlassEdgeViewProtocol>
@end

@implementation GlassEdgeComponentView {
  GlassEdgeHostView *_hostView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<GlassEdgeComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const GlassEdgeProps>();
    _props = defaultProps;

    _hostView = [[GlassEdgeHostView alloc] initWithFrame:self.bounds];
    self.contentView = _hostView;
  }
  return self;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<const GlassEdgeProps>(props);

  [_hostView updateWithEdge:RCTNSStringFromString(newProps.edge)
                 appearance:RCTNSStringFromString(newProps.appearance)
                   material:RCTNSStringFromString(newProps.material)
                  fadeStart:newProps.fadeStart
                      curve:newProps.curve
                  intensity:newProps.intensity];

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> GlassEdgeCls(void)
{
  return GlassEdgeComponentView.class;
}

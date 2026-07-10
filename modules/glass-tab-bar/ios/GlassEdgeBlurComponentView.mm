#import "GlassEdgeBlurComponentView.h"

#import <React/RCTConversions.h>
#import <react/renderer/components/GlassBarSpec/ComponentDescriptors.h>
#import <react/renderer/components/GlassBarSpec/Props.h>
#import <react/renderer/components/GlassBarSpec/RCTComponentViewHelpers.h>

#import "GlassTabBar-Swift.h"

using namespace facebook::react;

@interface GlassEdgeBlurComponentView () <RCTGlassEdgeBlurViewProtocol>
@end

@implementation GlassEdgeBlurComponentView {
  GlassEdgeBlurHostView *_hostView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<GlassEdgeBlurComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const GlassEdgeBlurProps>();
    _props = defaultProps;

    _hostView = [[GlassEdgeBlurHostView alloc] initWithFrame:self.bounds];
    self.contentView = _hostView;
  }
  return self;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<const GlassEdgeBlurProps>(props);

  [_hostView updateWithEdge:RCTNSStringFromString(newProps.edge)
                  maxRadius:newProps.maxRadius
                 smoothness:newProps.smoothness];

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> GlassEdgeBlurCls(void)
{
  return GlassEdgeBlurComponentView.class;
}

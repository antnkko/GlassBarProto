#import "NumericTextComponentView.h"

#import <React/RCTConversions.h>
#import <react/renderer/components/GlassBarSpec/ComponentDescriptors.h>
#import <react/renderer/components/GlassBarSpec/EventEmitters.h>
#import <react/renderer/components/GlassBarSpec/Props.h>
#import <react/renderer/components/GlassBarSpec/RCTComponentViewHelpers.h>

// Deliberately NOT importing GlassBarProto-Swift.h (drags in Expo AppDelegate
// superclasses ObjC++ can't resolve) — a minimal local declaration of the
// Swift host is enough; the class itself lives in the app binary.
@interface NumericTextHostView : UIView
- (void)updateWithText:(NSString *_Nonnull)text
              fontSize:(double)fontSize
            fontFamily:(NSString *_Nonnull)fontFamily
              colorHex:(NSString *_Nonnull)colorHex
              tracking:(double)tracking
                 label:(NSString *_Nonnull)label
         labelFontSize:(double)labelFontSize
       labelFontFamily:(NSString *_Nonnull)labelFontFamily
         labelColorHex:(NSString *_Nonnull)labelColorHex
               textGap:(double)textGap;
@end

using namespace facebook::react;

@interface NumericTextComponentView () <RCTNumericTextViewProtocol>
@end

@implementation NumericTextComponentView {
  NumericTextHostView *_hostView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<NumericTextComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const NumericTextProps>();
    _props = defaultProps;
    _hostView = [[NumericTextHostView alloc] initWithFrame:self.bounds];
    self.contentView = _hostView;
  }
  return self;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<const NumericTextProps>(props);

  [_hostView updateWithText:RCTNSStringFromString(newProps.text)
                   fontSize:newProps.fontSize
                 fontFamily:RCTNSStringFromString(newProps.fontFamily)
                   colorHex:RCTNSStringFromString(newProps.colorHex)
                   tracking:newProps.tracking
                      label:RCTNSStringFromString(newProps.label)
              labelFontSize:newProps.labelFontSize
            labelFontFamily:RCTNSStringFromString(newProps.labelFontFamily)
              labelColorHex:RCTNSStringFromString(newProps.labelColorHex)
                    textGap:newProps.textGap];

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> NumericTextCls(void)
{
  return NumericTextComponentView.class;
}

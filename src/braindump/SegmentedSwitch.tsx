/**
 * RN port of the native segmented "pill switch" (SegmentedSwitch.swift,
 * Figma 1112:8687): a grayAlmost track with ONE absolutely-positioned white
 * thumb under equal flex segments. Like the SwiftUI matchedGeometryEffect
 * original, a single animated selection float (selF) drives BOTH the thumb
 * slide and the label color cross-fade on the same spring — segSpring is the
 * repo's conversion of `.snappy(duration: 0.35, extraBounce: 0.12)`.
 */
import React, {useEffect} from 'react';
import {Pressable, View} from 'react-native';
import Animated, {
  interpolateColor,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  type SharedValue,
} from 'react-native-reanimated';

import {color, font, seg} from './tokens';
import {segSpring} from './motion';

type Props = {
  labels: string[];
  selectedIndex: number;
  onSelect: (index: number) => void;
};

function SegmentLabel({label, index, selF}: {label: string; index: number; selF: SharedValue<number>}) {
  // ink at the label's own index, grayNight a full segment away — the
  // cross-fade rides the same spring as the thumb (SwiftUI foregroundStyle
  // change inside withAnimation).
  const colorStyle = useAnimatedStyle(() => ({
    color: interpolateColor(
      selF.value,
      [index - 1, index, index + 1],
      [color.grayNight, color.ink, color.grayNight],
    ),
  }));
  return (
    <Animated.Text
      style={[
        {
          fontFamily: font.semibold,
          fontSize: seg.fontSize,
          lineHeight: seg.lineHeight,
        },
        colorStyle,
      ]}>
      {label}
    </Animated.Text>
  );
}

export function SegmentedSwitch({labels, selectedIndex, onSelect}: Props) {
  const trackW = useSharedValue(0);
  // Animated selection index — initialized in place so the first layout
  // paints the thumb at rest (no slide-in from segment 0).
  const selF = useSharedValue<number>(selectedIndex);

  useEffect(() => {
    selF.value = withSpring(selectedIndex, segSpring);
  }, [selectedIndex, selF]);

  const segCount = labels.length;
  const thumbStyle = useAnimatedStyle(() => {
    const segW = trackW.value > 0 ? (trackW.value - seg.pad * 2) / segCount : 0;
    return {
      opacity: segW > 0 ? 1 : 0,
      width: segW,
      left: seg.pad + selF.value * segW,
    };
  });

  return (
    <View
      onLayout={e => {
        trackW.value = e.nativeEvent.layout.width;
      }}
      style={{
        height: seg.thumbHeight + seg.pad * 2,
        borderRadius: seg.radius,
        backgroundColor: color.grayAlmost,
        flexDirection: 'row',
        padding: seg.pad,
      }}>
      <Animated.View
        style={[
          {
            position: 'absolute',
            top: seg.pad,
            height: seg.thumbHeight,
            borderRadius: seg.radius,
            backgroundColor: color.white,
            shadowColor: '#000',
            shadowOpacity: seg.thumbShadowOpacity,
            shadowRadius: seg.thumbShadowRadius,
            shadowOffset: {width: 0, height: 0},
          },
          thumbStyle,
        ]}
      />
      {labels.map((label, i) => (
        <Pressable key={label} onPress={() => onSelect(i)} style={{flex: 1}}>
          <View
            style={{
              flex: 1,
              alignItems: 'center',
              justifyContent: 'center',
              paddingBottom: seg.textLift,
            }}>
            <SegmentLabel label={label} index={i} selF={selF} />
          </View>
        </Pressable>
      ))}
    </View>
  );
}

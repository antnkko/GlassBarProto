/**
 * Stage 41/42 — the "When" picker card (WhenPicker.swift): an accordion of a
 * Date row (expands the week strip) and a Time row (expands the wheel).
 *
 * Stage 42 restructure — the native COVER pattern, not height-clipping:
 * the base (Date row + week strip) is ALWAYS laid out; an opaque white
 * Time-section block slides OVER the days (translateY on sectionResize), so
 * the hiding content physically disappears BEHIND the section, exactly like
 * the native slide. Blur: RN's `filter: blur` doesn't exist on iOS
 * (Android-only), so the native `.blurReplace`/covered-blur is reproduced
 * with expo-blur BlurView OVERLAYS (real backdrop blur of the content under
 * them) whose `intensity` animates via Reanimated `useAnimatedProps`:
 * the days blur as the cover slides over them (native coveredBlur 9pt) and
 * the wheel blurs-in on appear.
 *
 * Block heights are deterministic: dateBlock = sep2 + strip(12+64+12) = 90,
 * timeBlock = sep2 + wheel(6+190+6) = 204. Row heights are measured.
 */
import React from 'react';
import {Image, StyleSheet, Text, View} from 'react-native';
import {BlurView} from 'expo-blur';
import Animated, {
  SharedValue,
  useAnimatedProps,
  useAnimatedStyle,
  useSharedValue,
} from 'react-native-reanimated';

import {NumericLabel} from './NumericLabel';
import {PressFade} from './PressFade';
import {WeekStrip} from './WeekStrip';
import {WheelTimePicker, WheelTime, formatWheelTime} from './WheelTimePicker';
import {color, font, row, strip, wheel, wheelHeight} from './tokens';

export type WhenSection = 'date' | 'time';

export const DATE_BLOCK_H = row.sepThickness + strip.pad * 2 + strip.cellHeight; // 90
export const TIME_BLOCK_H = row.sepThickness + wheel.padV * 2 + wheelHeight; // 204

/** Covered-days blur: native 9pt ≈ BlurView intensity ~25. */
export const COVER_BLUR_INTENSITY = 25;

const AnimatedBlurView = Animated.createAnimatedComponent(BlurView);

export function Separator() {
  return (
    <View
      style={{
        height: row.sepThickness,
        marginLeft: row.leading,
        backgroundColor: color.grayAlmost,
        opacity: row.sepOpacity,
      }}
    />
  );
}

function PickerRow({
  icon,
  label,
  value,
  expanded,
  onPress,
  onLayout,
}: {
  icon: string;
  label: string;
  value: string;
  expanded: boolean;
  onPress: () => void;
  onLayout?: (h: number) => void;
}) {
  // PressFade — the same dip the Routine/When chip zones use (Stage 42).
  return (
    <PressFade onPress={onPress}>
      <View
        onLayout={onLayout ? e => onLayout(e.nativeEvent.layout.height) : undefined}
        style={{
          flexDirection: 'row',
          alignItems: 'center',
          gap: row.gap,
          paddingLeft: row.leading,
          paddingRight: row.trailing,
          paddingVertical: row.padV,
        }}>
        <Image
          source={{uri: icon}}
          style={{width: row.icon, height: row.icon, tintColor: color.grayNormal}}
          resizeMode="contain"
        />
        <View style={{flex: 1}}>
          {/* Label AND value render inside ONE SwiftUI leaf (native VStack
              with rowTextGap) — a single font-metric system, so they can't
              drift/overlap (Stage 47). Value rolls per-glyph on change via
              the real .contentTransition(.numericText()). */}
          <NumericLabel
            label={label}
            labelFontSize={row.labelSize}
            labelFontFamily={font.medium}
            labelColor={color.grayNight}
            textGap={row.textGap}
            text={value}
            fontSize={row.valueSize}
            fontFamily={font.semibold}
            color={color.neutralDark}
            height={44}
          />
        </View>
        <Image
          source={{uri: 'picker_chevron'}}
          style={{
            width: row.chevron,
            height: row.chevron,
            tintColor: color.grayNormal,
            opacity: expanded ? 0 : 1,
          }}
          resizeMode="contain"
        />
      </View>
    </PressFade>
  );
}

function dayValueText(selectedDay: Date | null): string {
  if (!selectedDay) return 'Today';
  const today = new Date();
  if (
    selectedDay.getFullYear() === today.getFullYear() &&
    selectedDay.getMonth() === today.getMonth() &&
    selectedDay.getDate() === today.getDate()
  ) {
    return 'Today';
  }
  const wd = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][selectedDay.getDay()];
  return `${wd} ${selectedDay.getDate()}`;
}

type Props = {
  section: WhenSection;
  /** 0 = time open, 1 = date open — animated on sectionResize by the parent. */
  sectionP: SharedValue<number>;
  selectedDay: Date | null;
  time: WheelTime;
  /** Wheel remount key: bump when the time is reset (Clear) to re-center. */
  wheelKey: number;
  onSectionChange: (s: WhenSection) => void;
  onSelectDay: (d: Date) => void;
  onTimeChange: (t: Partial<WheelTime>) => void;
  /**
   * The natural Time-section-open card height, reported from the JS row
   * measurements (NOT from onLayout of the animated card — Reanimated height
   * updates don't fire onLayout, which left the shell opening cropped).
   */
  onNaturalHeight?: (h: number) => void;
};

export function WhenPickerCard({
  section,
  sectionP,
  selectedDay,
  time,
  wheelKey,
  onSectionChange,
  onSelectDay,
  onTimeChange,
  onNaturalHeight,
}: Props) {
  // Measured row heights (fonts decide them); defaults keep the first frame
  // sane until onLayout lands (same frame in practice).
  const dateRowH = useSharedValue(59);
  const timeRowH = useSharedValue(59);
  // Same measurements on the JS side so the natural (time-open) height can be
  // reported UP deterministically — the shell can't read it off the animated
  // card height (Reanimated bypasses onLayout).
  const dateRowJS = React.useRef(0);
  const timeRowJS = React.useRef(0);
  const reportHeight = React.useCallback(() => {
    if (dateRowJS.current > 0 && timeRowJS.current > 0) {
      onNaturalHeight?.(dateRowJS.current + row.sepThickness + timeRowJS.current + TIME_BLOCK_H);
    }
  }, [onNaturalHeight]);

  // COVER position: right under the Date row (time open, days covered) ↔
  // below the days (date open, days revealed).
  const coverStyle = useAnimatedStyle(() => ({
    top: dateRowH.value + sectionP.value * DATE_BLOCK_H,
  }));
  // The wheel block collapses inside the cover as the days open.
  const timeBlockStyle = useAnimatedStyle(() => ({
    height: (1 - sectionP.value) * TIME_BLOCK_H,
    opacity: Math.min(1, (1 - sectionP.value) * 2),
  }));
  // Explicit card height (the cover is absolute): base rows + open block.
  const cardStyle = useAnimatedStyle(() => ({
    height:
      dateRowH.value +
      sectionP.value * DATE_BLOCK_H +
      row.sepThickness +
      timeRowH.value +
      (1 - sectionP.value) * TIME_BLOCK_H,
  }));

  // Blur overlays (see header comment): days blur under the cover; the wheel
  // blurs-in as it appears.
  const daysBlurProps = useAnimatedProps(() => ({
    intensity: (1 - sectionP.value) * COVER_BLUR_INTENSITY,
  }));
  const wheelBlurProps = useAnimatedProps(() => ({
    intensity: sectionP.value * COVER_BLUR_INTENSITY,
  }));

  return (
    <Animated.View style={[{overflow: 'hidden'}, cardStyle]}>
      {/* BASE — Date row + days, always laid out (the cover slides over). */}
      <PickerRow
        icon="picker_calendar"
        label="Date"
        value={dayValueText(selectedDay)}
        expanded={section === 'date'}
        onPress={() => onSectionChange('date')}
        onLayout={h => {
          dateRowH.value = h;
          dateRowJS.current = h;
          reportHeight();
        }}
      />
      <View style={{height: DATE_BLOCK_H}}>
        <Separator />
        <WeekStrip selectedDay={selectedDay} onSelect={onSelectDay} />
        <AnimatedBlurView
          pointerEvents="none"
          tint="light"
          animatedProps={daysBlurProps}
          style={StyleSheet.absoluteFill}
        />
      </View>

      {/* COVER — opaque white Time section sliding over/off the days. */}
      <Animated.View
        style={[
          {position: 'absolute', left: 0, right: 0, backgroundColor: color.white},
          coverStyle,
        ]}>
        <Separator />
        <PickerRow
          icon="picker_clock"
          label="Time"
          value={formatWheelTime(time)}
          expanded={section === 'time'}
          onPress={() => onSectionChange('time')}
          onLayout={h => {
            timeRowH.value = h;
            timeRowJS.current = h;
            reportHeight();
          }}
        />
        <Animated.View style={[{overflow: 'hidden'}, timeBlockStyle]}>
          <View style={{height: TIME_BLOCK_H}}>
            <Separator />
            <View style={{paddingVertical: wheel.padV}}>
              <WheelTimePicker key={wheelKey} initial={time} onChange={onTimeChange} />
            </View>
            <AnimatedBlurView
              pointerEvents="none"
              tint="light"
              animatedProps={wheelBlurProps}
              style={StyleSheet.absoluteFill}
            />
          </View>
        </Animated.View>
      </Animated.View>
    </Animated.View>
  );
}

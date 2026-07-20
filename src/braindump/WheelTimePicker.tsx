/**
 * Stage 41 — the wheel time picker in RN (counterpart of WheelTimePicker.swift):
 * three snapping columns (hour 1–12 · minute 0–55/5 · AM/PM) over one shared
 * selection band. Row look = the native scrollTransition ramp: scale 18→14pt,
 * opacity 1→0.4, digit color accent-at-center. RN owns the scroll offset, so
 * the picker opens dead-centered on the current time with accent digits on
 * the first frame (no SwiftUI scrollPosition write-back clobber to fight).
 */
import React, {useCallback, useMemo} from 'react';
import {NativeScrollEvent, NativeSyntheticEvent, View} from 'react-native';
import Animated, {
  interpolateColor,
  SharedValue,
  useAnimatedScrollHandler,
  useAnimatedStyle,
  useSharedValue,
} from 'react-native-reanimated';

import {color, font, wheel, wheelHeight, wheelPadCenter} from './tokens';

export type WheelTime = {hour: number; minute: number; pm: boolean};

export function formatWheelTime(t: WheelTime): string {
  const mm = t.minute.toString().padStart(2, '0');
  return `${t.hour}:${mm}${t.pm ? 'pm' : 'am'}`;
}

/** Snap a Date to the wheel's domain (nearest 5-minute step, 12h clock). */
export function wheelTimeFromDate(d: Date): WheelTime {
  let minute = Math.round(d.getMinutes() / wheel.minuteStep) * wheel.minuteStep;
  let hours24 = d.getHours();
  if (minute === 60) {
    minute = 0;
    hours24 = (hours24 + 1) % 24;
  }
  const pm = hours24 >= 12;
  const hour = hours24 % 12 === 0 ? 12 : hours24 % 12;
  return {hour, minute, pm};
}

const farScale = wheel.fontFar / wheel.fontCenter;

function WheelRow({index, offsetY, label}: {index: number; offsetY: SharedValue<number>; label: string}) {
  const anim = useAnimatedStyle(() => {
    const rows = (index * wheel.rowHeight - offsetY.value) / wheel.rowHeight;
    const d = Math.min(1, Math.abs(rows) / wheel.rampRows);
    return {
      transform: [{scale: 1 - (1 - farScale) * d}],
      opacity: 1 - (1 - wheel.opacityFar) * d,
      color: interpolateColor(Math.abs(rows), [0.35, 0.65], [color.vibrant, color.grayNight]),
    };
  });
  return (
    <View style={{height: wheel.rowHeight, alignItems: 'center', justifyContent: 'center'}}>
      <Animated.Text style={[{fontFamily: font.medium, fontSize: wheel.fontCenter}, anim]}>
        {label}
      </Animated.Text>
    </View>
  );
}

function WheelColumn({
  labels,
  initialIndex,
  onCommit,
}: {
  labels: string[];
  initialIndex: number;
  onCommit: (index: number) => void;
}) {
  const offsetY = useSharedValue(initialIndex * wheel.rowHeight);
  const onScroll = useAnimatedScrollHandler(e => {
    offsetY.value = e.contentOffset.y;
  });
  const commit = useCallback(
    (e: NativeSyntheticEvent<NativeScrollEvent>) => {
      const i = Math.round(e.nativeEvent.contentOffset.y / wheel.rowHeight);
      onCommit(Math.max(0, Math.min(labels.length - 1, i)));
    },
    [labels.length, onCommit],
  );
  return (
    <Animated.ScrollView
      // flexGrow 0: RN ScrollView's BASE style is flexGrow 1, which stretches
      // the three columns across the row — that's why the wheel spread wide
      // (Stage 42 fix; native columns are a shrink-wrapped 44pt each).
      style={{width: wheel.colWidth, height: wheelHeight, flexGrow: 0, flexShrink: 0}}
      contentContainerStyle={{paddingVertical: wheelPadCenter}}
      contentOffset={{x: 0, y: initialIndex * wheel.rowHeight}}
      snapToInterval={wheel.rowHeight}
      decelerationRate="fast"
      showsVerticalScrollIndicator={false}
      onScroll={onScroll}
      scrollEventThrottle={16}
      onMomentumScrollEnd={commit}
      onScrollEndDrag={e => {
        // No momentum (finger stopped dead): the snap still settles via
        // momentum-end in most cases; commit here as a fallback.
        if (Math.abs(e.nativeEvent.velocity?.y ?? 0) < 0.05) commit(e);
      }}>
      {labels.map((label, i) => (
        <WheelRow key={i} index={i} offsetY={offsetY} label={label} />
      ))}
    </Animated.ScrollView>
  );
}

const HOURS = Array.from({length: 12}, (_, i) => i + 1);
const MINUTES = Array.from({length: 60 / wheel.minuteStep}, (_, i) => i * wheel.minuteStep);

type Props = {
  /** The intended time at mount — the wheel opens centered on it. */
  initial: WheelTime;
  onChange: (t: Partial<WheelTime>) => void;
};

export function WheelTimePicker({initial, onChange}: Props) {
  const hourLabels = useMemo(() => HOURS.map(String), []);
  const minuteLabels = useMemo(() => MINUTES.map(m => m.toString().padStart(2, '0')), []);
  const meridiemLabels = useMemo(() => ['AM', 'PM'], []);

  return (
    <View style={{height: wheelHeight, justifyContent: 'center'}}>
      {/* Shared selection band behind all three columns. */}
      <View
        pointerEvents="none"
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: (wheelHeight - wheel.rowHeight) / 2,
          height: wheel.rowHeight,
          borderRadius: wheel.rowHeight / 2,
          borderCurve: 'continuous',
          backgroundColor: color.vibrantLight,
          opacity: wheel.bandOpacity,
        }}
      />
      {/* Shrink-wrapped, centered as ONE unit — the native HStack(spacing 28)
          of three 44pt columns (total 188pt). */}
      <View style={{flexDirection: 'row', alignSelf: 'center', gap: wheel.colGap}}>
        <WheelColumn
          labels={hourLabels}
          initialIndex={initial.hour - 1}
          onCommit={i => onChange({hour: HOURS[i]})}
        />
        <WheelColumn
          labels={minuteLabels}
          initialIndex={initial.minute / wheel.minuteStep}
          onCommit={i => onChange({minute: MINUTES[i]})}
        />
        <WheelColumn
          labels={meridiemLabels}
          initialIndex={initial.pm ? 1 : 0}
          onCommit={i => onChange({pm: i === 1})}
        />
      </View>
    </View>
  );
}

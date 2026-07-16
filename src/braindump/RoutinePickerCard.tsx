/**
 * The Routine picker card (Figma 1122:11791 "Routines", accents mapped to the
 * vibrant orange family): top mode switch (Daily | Weekly | Monthly) over a
 * mode-specific date section (none / week strip / month grid), the
 * "Repeat every <n unit>" row, and the repeat-count switch.
 *
 * Mode swaps use the house blur+opacity crossfade (native placeholderSwap /
 * .blurReplace): both date layers stay ALWAYS MOUNTED, the outgoing one fades
 * on fadeOut120, the incoming one arrives on the same sectionResize spring
 * that drives the block height and the shell height (fired in the same JS
 * frame from onSelect), with a blur veil pulsing over the block. The repeat
 * value rides the NumericText leaf's own per-glyph roll; the bottom switch is
 * two always-mounted layers (1|2|3|4 and 1|3|6|12) crossfading only across
 * the monthly boundary — within daily↔weekly its thumb just springs.
 */
import React, {useEffect, useRef, useState} from 'react';
import {StyleSheet, Text, View} from 'react-native';
import {BlurView} from 'expo-blur';
import Animated, {
  useAnimatedProps,
  useAnimatedStyle,
  useSharedValue,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

import {MonthGrid} from './MonthGrid';
import {NumericLabel} from './NumericLabel';
import {SegmentedSwitch} from './SegmentedSwitch';
import {WeekStrip} from './WeekStrip';
import {COVER_BLUR_INTENSITY, Separator} from './WhenPickerCard';
import {color, font, routine, row, seg, strip} from './tokens';
import {fadeOut120, fadeOut160, sectionResize} from './motion';

export type RoutineMode = 'daily' | 'weekly' | 'monthly';

const MODES: RoutineMode[] = ['daily', 'weekly', 'monthly'];
const MODE_LABELS = ['Daily', 'Weekly', 'Monthly'];
/** daily+weekly share one label set — crossfade only across the monthly boundary. */
const DW_REPEAT_LABELS = ['1', '2', '3', '4'];
const MO_REPEAT_LABELS = ['1', '3', '6', '12'];
const UNIT: Record<RoutineMode, string> = {daily: 'day', weekly: 'week', monthly: 'month'};

const AnimatedBlurView = Animated.createAnimatedComponent(BlurView);

const TRACK_H = seg.thumbHeight + seg.pad * 2; // 44
const SWITCH_BLOCK_H = TRACK_H + routine.switchPadV * 2; // 84
const SEP_H = row.sepThickness; // 2
const STRIP_BLOCK_H = strip.cellHeight + routine.stripPadV * 2; // 92
const REPEAT_ROW_H = 22; // "Repeat every" text + numeric twin (lineHeight 22)
const REPEAT_BLOCK_H = routine.repeatPadTop + REPEAT_ROW_H + routine.repeatPadBottom; // 54
const BOTTOM_SWITCH_BLOCK_H = TRACK_H + routine.bottomSwitchPadBottom; // 62
/** Monthly viewport: the Figma card is a fixed 360pt — the grid scrolls in the remainder. */
const GRID_VIEWPORT_H =
  360 - (SWITCH_BLOCK_H + SEP_H + SEP_H + REPEAT_BLOCK_H + BOTTOM_SWITCH_BLOCK_H); // 156

/** Everything that is NOT the mode-specific date block. */
const FIXED_CHROME_H = SWITCH_BLOCK_H + SEP_H + REPEAT_BLOCK_H + BOTTOM_SWITCH_BLOCK_H; // 202
/** The animated date block per mode (each layer includes its trailing separator). */
const BLOCK_H: Record<RoutineMode, number> = {
  daily: 0,
  weekly: STRIP_BLOCK_H + SEP_H, // 94
  monthly: GRID_VIEWPORT_H + SEP_H, // 158
};

/** Deterministic card heights — the shell's spring targets per mode.
 *  Invariant: ROUTINE_CARD_H[m] === FIXED_CHROME_H + BLOCK_H[m]. */
export const ROUTINE_CARD_H: Record<RoutineMode, number> = {
  daily: FIXED_CHROME_H + BLOCK_H.daily, // 202
  weekly: FIXED_CHROME_H + BLOCK_H.weekly, // 296
  monthly: FIXED_CHROME_H + BLOCK_H.monthly, // 360
};

function RepeatRow({mode, count}: {mode: RoutineMode; count: number}) {
  const value = `${count} ${UNIT[mode]}${count > 1 ? 's' : ''}`;
  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        gap: routine.repeatGap,
        paddingTop: routine.repeatPadTop,
        paddingBottom: routine.repeatPadBottom,
        paddingLeft: routine.repeatPadLeft,
      }}>
      <Text
        style={{
          fontFamily: font.semibold,
          fontSize: routine.repeatLabelSize,
          lineHeight: 22,
          color: color.neutralDark,
        }}>
        Repeat every
      </Text>
      {/* Invisible twin sizes the box; the SwiftUI leaf paints (and rolls). */}
      <View style={{height: 22, justifyContent: 'center'}}>
        <Text
          style={{
            fontFamily: font.semibold,
            fontSize: routine.repeatLabelSize,
            lineHeight: 22,
            opacity: 0,
          }}>
          {value}
        </Text>
        {/* SwiftUI centers the value's layout bounds in the 22pt frame while
            the RN label sits on its own baseline within the lineHeight box —
            nudge the leaf up so the two baselines coincide. */}
        <View
          style={[
            StyleSheet.absoluteFill,
            {transform: [{translateY: routine.repeatValueNudge}]},
          ]}>
          <NumericLabel
            text={value}
            fontSize={routine.repeatLabelSize}
            fontFamily={font.semibold}
            color={color.vibrant}
            height={22}
          />
        </View>
      </View>
    </View>
  );
}

type Props = {
  mode: RoutineMode;
  onModeChange: (mode: RoutineMode) => void;
  /** Weekly checklist — several days of the week may be selected. */
  selectedWeekDays: Date[];
  onToggleWeekDay: (day: Date) => void;
  /** Monthly — a single day of the month. */
  selectedMonthDay: Date | null;
  onSelectMonthDay: (day: Date) => void;
};

export function RoutinePickerCard({
  mode,
  onModeChange,
  selectedWeekDays,
  onToggleWeekDay,
  selectedMonthDay,
  onSelectMonthDay,
}: Props) {
  // Repeat count per mode (the bottom switch); remount (key) resets on Clear.
  const [repeatIndex, setRepeatIndex] = useState<Record<RoutineMode, number>>({
    daily: 0,
    weekly: 0,
    monthly: 0,
  });

  // Swap choreography state — initialized from the mode prop (Clear remounts
  // the card via routineKey, so the resting pose is always consistent).
  const blockH = useSharedValue(BLOCK_H[mode]);
  const stripO = useSharedValue(mode === 'weekly' ? 1 : 0);
  const gridO = useSharedValue(mode === 'monthly' ? 1 : 0);
  const dwSwitchO = useSharedValue(mode === 'monthly' ? 0 : 1);
  const moSwitchO = useSharedValue(mode === 'monthly' ? 1 : 0);
  const veil = useSharedValue(0);
  const modeRef = useRef(mode);

  const swapTo = (next: RoutineMode) => {
    if (modeRef.current === next) return;
    const prev = modeRef.current;
    const wasMonthly = prev === 'monthly';
    modeRef.current = next;
    // Height and incoming content ride the SAME spring the shell height uses
    // (onModeChange fires shellH synchronously in this same frame).
    blockH.value = withSpring(BLOCK_H[next], sectionResize);
    stripO.value =
      next === 'weekly' ? withSpring(1, sectionResize) : withTiming(0, fadeOut120);
    gridO.value =
      next === 'monthly' ? withSpring(1, sectionResize) : withTiming(0, fadeOut120);
    // Bottom switch layers crossfade only across the monthly boundary.
    if ((next === 'monthly') !== wasMonthly) {
      dwSwitchO.value =
        next === 'monthly' ? withTiming(0, fadeOut120) : withSpring(1, sectionResize);
      moSwitchO.value =
        next === 'monthly' ? withSpring(1, sectionResize) : withTiming(0, fadeOut120);
    }
    // Blur veil pulse over the date block (.blurReplace feel); skip when the
    // block is/becomes empty — a blur over nothing reads as a smudge.
    if (prev !== 'daily' && next !== 'daily') {
      veil.value = withSequence(
        withTiming(COVER_BLUR_INTENSITY, fadeOut120),
        withTiming(0, fadeOut160),
      );
    }
    onModeChange(next);
  };

  // Belt-and-braces: external mode changes (without swapTo) snap to rest.
  useEffect(() => {
    if (modeRef.current === mode) return;
    modeRef.current = mode;
    blockH.value = BLOCK_H[mode];
    stripO.value = mode === 'weekly' ? 1 : 0;
    gridO.value = mode === 'monthly' ? 1 : 0;
    dwSwitchO.value = mode === 'monthly' ? 0 : 1;
    moSwitchO.value = mode === 'monthly' ? 1 : 0;
  }, [mode, blockH, stripO, gridO, dwSwitchO, moSwitchO]);

  const cardStyle = useAnimatedStyle(() => ({height: FIXED_CHROME_H + blockH.value}));
  const blockStyle = useAnimatedStyle(() => ({height: blockH.value}));
  const stripStyle = useAnimatedStyle(() => ({opacity: stripO.value}));
  const gridStyle = useAnimatedStyle(() => ({opacity: gridO.value}));
  const dwStyle = useAnimatedStyle(() => ({opacity: dwSwitchO.value}));
  const moStyle = useAnimatedStyle(() => ({opacity: moSwitchO.value}));
  const veilProps = useAnimatedProps(() => ({intensity: veil.value}));

  const count = Number(
    (mode === 'monthly' ? MO_REPEAT_LABELS : DW_REPEAT_LABELS)[repeatIndex[mode]],
  );

  return (
    <Animated.View style={[{overflow: 'hidden'}, cardStyle]}>
      <View
        style={{
          paddingHorizontal: routine.switchPadH,
          paddingVertical: routine.switchPadV,
        }}>
        <SegmentedSwitch
          labels={MODE_LABELS}
          selectedIndex={MODES.indexOf(mode)}
          onSelect={i => swapTo(MODES[i])}
        />
      </View>
      <Separator />

      {/* Date block — both layers always mounted (top-aligned, fixed natural
          heights, no reflow); the animated clip reveals/covers them while the
          crossfade swaps which one is visible. */}
      <Animated.View style={[{overflow: 'hidden'}, blockStyle]}>
        <Animated.View
          style={[styles.blockLayer, {height: BLOCK_H.weekly}, stripStyle]}
          pointerEvents={mode === 'weekly' ? 'auto' : 'none'}>
          <WeekStrip variant="routine" selectedDays={selectedWeekDays} onToggle={onToggleWeekDay} />
          <Separator />
        </Animated.View>
        <Animated.View
          style={[styles.blockLayer, {height: BLOCK_H.monthly}, gridStyle]}
          pointerEvents={mode === 'monthly' ? 'auto' : 'none'}>
          <MonthGrid
            height={GRID_VIEWPORT_H}
            selectedDay={selectedMonthDay}
            onSelect={onSelectMonthDay}
          />
          <Separator />
        </Animated.View>
        <AnimatedBlurView
          pointerEvents="none"
          tint="light"
          animatedProps={veilProps}
          style={StyleSheet.absoluteFill}
        />
      </Animated.View>

      <RepeatRow mode={mode} count={count} />

      {/* Bottom switch — two always-mounted layers (placeholderSwap idiom):
          daily+weekly share 1|2|3|4 (the thumb springs between their indices),
          monthly gets 1|3|6|12; crossfade only across the monthly boundary. */}
      <View
        style={{
          height: TRACK_H,
          marginHorizontal: routine.switchPadH,
          marginBottom: routine.bottomSwitchPadBottom,
        }}>
        <Animated.View
          style={[StyleSheet.absoluteFill, dwStyle]}
          pointerEvents={mode === 'monthly' ? 'none' : 'auto'}>
          <SegmentedSwitch
            labels={DW_REPEAT_LABELS}
            selectedIndex={repeatIndex[mode === 'monthly' ? 'weekly' : mode]}
            onSelect={i => setRepeatIndex(prev => ({...prev, [modeRef.current]: i}))}
          />
        </Animated.View>
        <Animated.View
          style={[StyleSheet.absoluteFill, moStyle]}
          pointerEvents={mode === 'monthly' ? 'auto' : 'none'}>
          <SegmentedSwitch
            labels={MO_REPEAT_LABELS}
            selectedIndex={repeatIndex.monthly}
            onSelect={i => setRepeatIndex(prev => ({...prev, monthly: i}))}
          />
        </Animated.View>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  blockLayer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
});

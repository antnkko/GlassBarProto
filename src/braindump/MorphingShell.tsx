/**
 * Stage 41 — the ONE morphing glass shell (RedesignedScreen.bottomBar): the
 * chip card (Routine|When) and the open picker are the same continuous
 * Liquid Glass surface animating its height (82 ↔ picker height), trailing
 * inset (voice slot 131 → 0) and corner radius (20 ↔ 24) together on the
 * native open/close springs. Both children stay mounted (the wheel never
 * instantiates mid-animation); they swap via opacity — chip on the fast
 * chromeFadeOut, picker riding the open spring (out: fast fade leads the
 * collapse). The voice button sits BEHIND the shell and fades with the chip.
 *
 * Stage 48 — the shell hosts TWO pickers behind one set of morph drivers:
 * `openPicker` ('none' | 'when' | 'routine') picks which card the same
 * open/close springs reveal. Both cards stay mounted; the inactive one is
 * opacity-0 (swaps only happen while closed). `activeKind` latches on open
 * and survives the close so the collapsing card stays visible.
 */
import React, {useCallback, useEffect, useRef, useState} from 'react';
import {StyleSheet, useWindowDimensions, View} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

import {GlassSurface} from './GlassSurface';
import {RoutinePickerCard, RoutineMode, ROUTINE_CARD_H} from './RoutinePickerCard';
import {RoutineWhenChip} from './RoutineWhenChip';
import {VoiceButton} from './VoiceButton';
import {sameDay} from './WeekStrip';
import {WhenPickerCard, WhenSection, DATE_BLOCK_H, TIME_BLOCK_H} from './WhenPickerCard';
import {WheelTime, wheelTimeFromDate} from './WheelTimePicker';
import {bar, shell, voice} from './tokens';
import {closeSpring, contentScaleFrom, fadeOut120, openSpring, sectionResize} from './motion';

const VOICE_SLOT = voice.width + bar.gap; // 131

export type PickerKind = 'none' | 'when' | 'routine';
type CardKind = Exclude<PickerKind, 'none'>;

export type MorphingShellHandle = {
  /** Clear: reset day/time to now, re-center the wheel, reset the routine card. */
  reset: () => void;
};

type Props = {
  openPicker: PickerKind;
  onOpenPickerChange: (picker: PickerKind) => void;
  onVoiceTap?: () => void;
  voiceGlow?: {radius: number; opacity: number};
  /** The active picker's open height (for the symmetric-gap lift). */
  onOpenHeight?: (h: number) => void;
  shellRef?: React.MutableRefObject<MorphingShellHandle | null>;
};

export function MorphingShell({
  openPicker,
  onOpenPickerChange,
  onVoiceTap,
  voiceGlow,
  onOpenHeight,
  shellRef,
}: Props) {
  const {width: screenW} = useWindowDimensions();
  const pickerWidth = screenW - bar.padH * 2; // pickers lay out at FINAL width
  const isOpen = openPicker !== 'none';

  // When-picker state — RN-owned (the native screen no longer consumes it).
  // The current section lives in a ref + the sectionP shared value ONLY: a
  // React section state re-rendered the whole card mid-swap (Stage 55).
  const [selectedDay, setSelectedDay] = useState<Date | null>(null);
  const [time, setTime] = useState<WheelTime>(() => wheelTimeFromDate(new Date()));
  const [wheelKey, setWheelKey] = useState(0);

  // Routine-picker state (Stage 48). Weekly is a CHECKLIST (several days of
  // the week), monthly a single day-of-month — separate selections. Remount
  // key resets the card's inner repeat-count state on Clear.
  const [routineMode, setRoutineMode] = useState<RoutineMode>('weekly');
  const [routineWeekDays, setRoutineWeekDays] = useState<Date[]>([]);
  const [routineMonthDay, setRoutineMonthDay] = useState<Date | null>(null);
  const [routineKey, setRoutineKey] = useState(0);

  // Checklist toggle; an empty set falls back to "today selected", and the
  // LAST selected day cannot be untoggled (a routine needs at least one day).
  const toggleRoutineWeekDay = useCallback((day: Date) => {
    setRoutineWeekDays(prev => {
      const effective = prev.length
        ? prev
        : [(d => (d.setHours(0, 0, 0, 0), d))(new Date())]; // fallback = today
      const without = effective.filter(d => !sameDay(d, day));
      if (without.length === effective.length) return [...effective, day];
      return without.length ? without : effective; // never drop the last day
    });
  }, []);

  // Which card the shell reveals; latched on open, survives the close.
  const [activeKind, setActiveKind] = useState<CardKind>('when');

  // Morph drivers (picker-agnostic).
  const openP = useSharedValue(0); // radius + trailing inset + picker scale
  const shellH = useSharedValue<number>(shell.heightClosed);
  const chipVoice = useSharedValue(1); // chip labels + voice opacity
  const contentOpacity = useSharedValue(0); // picker content
  const sectionP = useSharedValue(0); // When-only: 0 = time open, 1 = date open

  // Natural When-picker height with the TIME section open. Reported from the
  // card's JS row measurements (onNaturalHeight) — NOT measured off the
  // animated card via onLayout, because Reanimated height updates don't fire
  // onLayout, which left `pickerHTime` stuck at ~0 and the shell cropped.
  const pickerHTime = useRef(0);
  const sectionRef = useRef<WhenSection>('time');
  const routineModeRef = useRef<RoutineMode>('weekly');
  const openRef = useRef(false);
  const activeKindRef = useRef<CardKind>('when');

  const pickerHeightFor = useCallback((s: WhenSection) => {
    const base = pickerHTime.current || shell.heightClosed;
    return s === 'time' ? base : base - TIME_BLOCK_H + DATE_BLOCK_H;
  }, []);

  const openTargetFor = useCallback(
    (kind: CardKind) =>
      Math.max(
        kind === 'when'
          ? pickerHeightFor(sectionRef.current)
          : ROUTINE_CARD_H[routineModeRef.current],
        shell.heightClosed,
      ),
    [pickerHeightFor],
  );

  const animateOpen = useCallback(
    (open: boolean, kind: CardKind) => {
      if (openRef.current === open && (!open || activeKindRef.current === kind)) return;
      openRef.current = open;
      if (open) {
        activeKindRef.current = kind;
        setActiveKind(kind);
        onOpenHeight?.(openTargetFor(kind));
      }
      chipVoice.value = withTiming(open ? 0 : 1, fadeOut120);
      if (open) {
        openP.value = withSpring(1, openSpring);
        contentOpacity.value = withSpring(1, openSpring);
        shellH.value = withSpring(openTargetFor(kind), openSpring);
      } else {
        contentOpacity.value = withTiming(0, fadeOut120); // content leads out
        openP.value = withSpring(0, closeSpring);
        shellH.value = withSpring(shell.heightClosed, closeSpring);
      }
    },
    [chipVoice, contentOpacity, onOpenHeight, openP, openTargetFor, shellH],
  );

  // Opens/closes arriving from outside (native header ✓/Clear, backdrop tap).
  useEffect(() => {
    if (openPicker === 'none') {
      animateOpen(false, activeKindRef.current);
    } else {
      animateOpen(true, openPicker);
    }
  }, [openPicker, animateOpen]);

  const swapSection = useCallback(
    (s: WhenSection) => {
      if (sectionRef.current === s) return;
      sectionRef.current = s;
      sectionP.value = withSpring(s === 'date' ? 1 : 0, sectionResize);
      shellH.value = withSpring(pickerHeightFor(s), sectionResize);
    },
    [pickerHeightFor, sectionP, shellH],
  );

  // Routine mode swap: the card runs its own crossfade+blur choreography
  // (RoutinePickerCard.swapTo) and calls this synchronously in the same frame,
  // so the shell height rides the SAME sectionResize spring as the card block.
  const swapRoutineMode = useCallback(
    (mode: RoutineMode) => {
      if (routineModeRef.current === mode) return;
      routineModeRef.current = mode;
      setRoutineMode(mode);
      const target = Math.max(ROUTINE_CARD_H[mode], shell.heightClosed);
      shellH.value = withSpring(target, sectionResize);
      onOpenHeight?.(target);
    },
    [onOpenHeight, shellH],
  );

  if (shellRef) {
    shellRef.current = {
      reset: () => {
        setSelectedDay(null);
        setTime(wheelTimeFromDate(new Date()));
        setWheelKey(k => k + 1); // re-center the wheel on "now"
        routineModeRef.current = 'weekly';
        setRoutineMode('weekly');
        setRoutineWeekDays([]);
        setRoutineMonthDay(null);
        setRoutineKey(k => k + 1); // reset the repeat-count switches
      },
    };
  }

  const shellStyle = useAnimatedStyle(() => ({
    height: shellH.value,
    marginRight: VOICE_SLOT * (1 - openP.value),
  }));
  const glassRadius = useAnimatedStyle(() => ({
    borderRadius: shell.radiusClosed + (shell.radiusOpen - shell.radiusClosed) * openP.value,
  }));
  const chipStyle = useAnimatedStyle(() => ({opacity: chipVoice.value}));
  const voiceStyle = useAnimatedStyle(() => ({opacity: chipVoice.value}));
  const pickerStyle = useAnimatedStyle(() => ({
    opacity: contentOpacity.value,
    transform: [{scale: contentScaleFrom + (1 - contentScaleFrom) * openP.value}],
  }));

  return (
    <View>
      {/* Voice CTA behind the shell: the expanding picker covers it. */}
      <Animated.View
        style={[{position: 'absolute', right: 0, bottom: 0}, voiceStyle]}
        pointerEvents={isOpen ? 'none' : 'auto'}>
        <VoiceButton onPress={onVoiceTap} glow={voiceGlow} />
      </Animated.View>

      <GlassSurface radius={shell.radiusClosed} style={shellStyle} glassStyle={glassRadius}>
        {/* Chip layer — fades out fast as the picker arrives. FIXED closed-
            state geometry (not absoluteFill): sizing it off the resizing
            shell re-laid the chip rows on every frame of the morph
            (Stage 55); it only shows closed, so it never needs to stretch. */}
        <Animated.View
          style={[
            {
              position: 'absolute',
              left: 0,
              bottom: 0,
              width: pickerWidth - VOICE_SLOT,
              height: shell.heightClosed,
            },
            chipStyle,
          ]}
          pointerEvents={isOpen ? 'none' : 'auto'}>
          <RoutineWhenChip
            onWhenTap={() => {
              // Fire the springs NOW (same frame as the tap) — the React state
              // round-trip only informs the native header, which runs its own
              // crossfade and can afford a frame of latency.
              animateOpen(true, 'when');
              onOpenPickerChange('when');
            }}
            onRoutineTap={() => {
              animateOpen(true, 'routine');
              onOpenPickerChange('routine');
            }}
          />
        </Animated.View>

        {/* Picker layer — both cards always mounted, laid out at FINAL width
            and pinned to the bottom so the shell's growing clip reveals the
            active one upward; the inactive card hides on plain opacity. */}
        <Animated.View
          style={[
            {
              position: 'absolute',
              left: 0,
              bottom: 0,
              width: pickerWidth,
              transformOrigin: '50% 100%',
            },
            pickerStyle,
          ]}
          pointerEvents={isOpen ? 'auto' : 'none'}>
          <View
            style={activeKind === 'when' ? undefined : styles.hiddenCard}
            pointerEvents={activeKind === 'when' ? 'auto' : 'none'}>
            <WhenPickerCard
              sectionP={sectionP}
              selectedDay={selectedDay}
              time={time}
              wheelKey={wheelKey}
              onSectionChange={swapSection}
              onSelectDay={setSelectedDay}
              onTimeChange={t => setTime(prev => ({...prev, ...t}))}
              onNaturalHeight={h => {
                pickerHTime.current = h;
                if (activeKindRef.current === 'when') {
                  onOpenHeight?.(pickerHeightFor(sectionRef.current));
                }
                // If the picker is already open when the measurement lands (or
                // settles bigger), grow the shell to the corrected height.
                if (openRef.current && activeKindRef.current === 'when') {
                  shellH.value = withSpring(
                    Math.max(pickerHeightFor(sectionRef.current), shell.heightClosed),
                    openSpring,
                  );
                }
              }}
            />
          </View>
          <View
            style={activeKind === 'routine' ? undefined : styles.hiddenCard}
            pointerEvents={activeKind === 'routine' ? 'auto' : 'none'}>
            <RoutinePickerCard
              key={routineKey}
              mode={routineMode}
              onModeChange={swapRoutineMode}
              selectedWeekDays={routineWeekDays}
              onToggleWeekDay={toggleRoutineWeekDay}
              selectedMonthDay={routineMonthDay}
              onSelectMonthDay={setRoutineMonthDay}
            />
          </View>
        </Animated.View>
      </GlassSurface>
    </View>
  );
}

const styles = StyleSheet.create({
  hiddenCard: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    opacity: 0,
  },
});

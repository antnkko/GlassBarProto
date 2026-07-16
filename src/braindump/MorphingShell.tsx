/**
 * Stage 41 — the ONE morphing glass shell (RedesignedScreen.bottomBar): the
 * chip card (Routine|When) and the open When-picker are the same continuous
 * Liquid Glass surface animating its height (82 ↔ measured picker height),
 * trailing inset (voice slot 131 → 0) and corner radius (20 ↔ 24) together on
 * the native open/close springs. Both children stay mounted (the wheel never
 * instantiates mid-animation); they swap via opacity — chip on the fast
 * chromeFadeOut, picker riding the open spring (out: fast fade leads the
 * collapse). The voice button sits BEHIND the shell and fades with the chip.
 */
import React, {useCallback, useEffect, useRef, useState} from 'react';
import {useWindowDimensions, View} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

import {GlassSurface} from './GlassSurface';
import {RoutineWhenChip} from './RoutineWhenChip';
import {VoiceButton} from './VoiceButton';
import {WhenPickerCard, WhenSection, DATE_BLOCK_H, TIME_BLOCK_H} from './WhenPickerCard';
import {WheelTime, wheelTimeFromDate} from './WheelTimePicker';
import {bar, shell, voice} from './tokens';
import {closeSpring, contentScaleFrom, fadeOut120, openSpring, sectionResize} from './motion';

const VOICE_SLOT = voice.width + bar.gap; // 131

export type MorphingShellHandle = {
  /** Clear: reset day/time to now and re-center the wheel. */
  reset: () => void;
};

type Props = {
  whenOpen: boolean;
  onWhenOpenChange: (open: boolean) => void;
  onVoiceTap?: () => void;
  voiceGlow?: {radius: number; opacity: number};
  /** The measured time-open picker height (for the symmetric-gap lift). */
  onOpenHeight?: (h: number) => void;
  shellRef?: React.MutableRefObject<MorphingShellHandle | null>;
};

export function MorphingShell({
  whenOpen,
  onWhenOpenChange,
  onVoiceTap,
  voiceGlow,
  onOpenHeight,
  shellRef,
}: Props) {
  const {width: screenW} = useWindowDimensions();
  const pickerWidth = screenW - bar.padH * 2; // picker lays out at FINAL width

  // Picker state — RN-owned (the native screen no longer consumes it).
  // The current section lives in a ref + the sectionP shared value ONLY: a
  // React section state re-rendered the whole card mid-swap (Stage 55).
  const [selectedDay, setSelectedDay] = useState<Date | null>(null);
  const [time, setTime] = useState<WheelTime>(() => wheelTimeFromDate(new Date()));
  const [wheelKey, setWheelKey] = useState(0);

  // Morph drivers.
  const openP = useSharedValue(0); // radius + trailing inset + picker scale
  const shellH = useSharedValue<number>(shell.heightClosed);
  const chipVoice = useSharedValue(1); // chip labels + voice opacity
  const contentOpacity = useSharedValue(0); // picker content
  const sectionP = useSharedValue(0); // 0 = time open, 1 = date open

  // Natural picker height with the TIME section open. Reported from the card's
  // JS row measurements (onNaturalHeight) — NOT measured off the animated card
  // via onLayout, because Reanimated height updates don't fire onLayout, which
  // left `pickerHTime` stuck at ~0 and the shell opening cropped.
  const pickerHTime = useRef(0);
  const sectionRef = useRef<WhenSection>('time');
  const openRef = useRef(false);

  const pickerHeightFor = useCallback((s: WhenSection) => {
    const base = pickerHTime.current || shell.heightClosed;
    return s === 'time' ? base : base - TIME_BLOCK_H + DATE_BLOCK_H;
  }, []);

  const animateOpen = useCallback(
    (open: boolean) => {
      if (openRef.current === open) return;
      openRef.current = open;
      chipVoice.value = withTiming(open ? 0 : 1, fadeOut120);
      if (open) {
        openP.value = withSpring(1, openSpring);
        contentOpacity.value = withSpring(1, openSpring);
        shellH.value = withSpring(Math.max(pickerHeightFor(sectionRef.current), shell.heightClosed), openSpring);
      } else {
        contentOpacity.value = withTiming(0, fadeOut120); // content leads out
        openP.value = withSpring(0, closeSpring);
        shellH.value = withSpring(shell.heightClosed, closeSpring);
      }
    },
    [chipVoice, contentOpacity, openP, pickerHeightFor, shellH],
  );

  // Opens/closes arriving from outside (native header ✓/Clear, backdrop tap).
  useEffect(() => {
    animateOpen(whenOpen);
  }, [whenOpen, animateOpen]);

  const swapSection = useCallback(
    (s: WhenSection) => {
      if (sectionRef.current === s) return;
      sectionRef.current = s;
      sectionP.value = withSpring(s === 'date' ? 1 : 0, sectionResize);
      shellH.value = withSpring(pickerHeightFor(s), sectionResize);
    },
    [pickerHeightFor, sectionP, shellH],
  );

  if (shellRef) {
    shellRef.current = {
      reset: () => {
        setSelectedDay(null);
        setTime(wheelTimeFromDate(new Date()));
        setWheelKey(k => k + 1); // re-center the wheel on "now"
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
        pointerEvents={whenOpen ? 'none' : 'auto'}>
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
          pointerEvents={whenOpen ? 'none' : 'auto'}>
          <RoutineWhenChip
            onWhenTap={() => {
              // Fire the springs NOW (same frame as the tap) — the React state
              // round-trip only informs the native header, which runs its own
              // 0.45s crossfade and can afford a frame of latency.
              animateOpen(true);
              onWhenOpenChange(true);
            }}
          />
        </Animated.View>

        {/* Picker layer — always mounted, laid out at FINAL width and pinned
            to the bottom so the shell's growing clip reveals it upward. */}
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
          pointerEvents={whenOpen ? 'auto' : 'none'}>
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
              onOpenHeight?.(h);
              // If the picker is already open when the measurement lands (or
              // settles bigger), grow the shell to the corrected height.
              if (openRef.current) {
                shellH.value = withSpring(Math.max(pickerHeightFor(sectionRef.current), shell.heightClosed), openSpring);
              }
            }}
          />
        </Animated.View>
      </GlassSurface>
    </View>
  );
}

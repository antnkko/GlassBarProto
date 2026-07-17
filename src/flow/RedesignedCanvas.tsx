/**
 * Stage 50 — the redesigned task-entry screen's sheet CONTENT, rebuilt in RN
 * (mirrors `RedesignedScreen.sheet()`): the native Fabric chrome leaf
 * (✕ + publicity ⇄ Clear + ✓), the natural-language input with the custom
 * placeholder, and the frosted backdrop while the When-picker is open.
 * The parent (BraindumpFlow) owns the sheet's position/clip and the timelines.
 */
import React, {useCallback, useEffect, useRef, useState} from 'react';
import {Pressable, StyleSheet, TextInput, View} from 'react-native';
import {BlurView} from 'expo-blur';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  type SharedValue,
} from 'react-native-reanimated';

import {NumoChromeView} from '../../modules/glass-tab-bar';
import type {PickerKind} from '../braindump/MorphingShell';
import {openSpring, closeSpring} from '../braindump/motion';
import {color, font} from '../braindump/tokens';
import {OLD_PLACEHOLDER, Stage1Header} from './BrainDumpList';
import {MorphChoreo} from './choreo';

// Native geometry (Metrics.Redesign / Metrics.WhenPicker).
const HEADER_PAD_V = 20;
const CLOSE_SIZE = 48;
export const CHROME_HEIGHT = HEADER_PAD_V * 2 + CLOSE_SIZE; // 88
const INPUT_PAD_H = 24;
const INPUT_TRACKING = 0.8;
const INPUT_LINE_HEIGHT = 46; // ObviouslyNarrow-Bold 40
const BACKDROP_DIM = 0.55;
const BACKDROP_BLUR_INTENSITY = 8; // ≈ native backdropBlur 4pt radius

const NEW_HEADER_DROP = -28; // MorphChoreo.newHeaderDrop (the 'pop' drop)
/** 'clip' spawn park: fully above the sheet's overflow-hidden top edge
 *  (chrome 88 + glass shadow bleed) — hidden with alpha untouched. */
const CHROME_PARK = 120;

const NEW_PLACEHOLDER = 'Type naturally: e.g.\n"meds 9am daily"';

const SAMPLE_TAGS = ['House 01', 'Work', 'Ideas', 'Groceries', 'Trip'];

type Props = {
  /** Which picker is open ('none' | 'when' | 'routine') — drives the native
   *  chrome swap; the header title latches on open (native pickerTitle). */
  openPicker: PickerKind;
  /** ✕ tapped — the parent runs the close timeline. */
  onCloseTap: () => void;
  /** Clear tapped — reset the picker selection and close it. */
  onClearTap: () => void;
  /** ✓ tapped — confirm and close the picker. */
  onConfirmTap: () => void;
  /** Tap on the dimmed input zone while the picker is open. */
  onBackdropTap: () => void;
  /** Glass shadow knobs (dev-panel). */
  shadow: {opacity: number; radius: number};
  /** Chrome entrance progress (0 = out at −28/transparent, 1 = landed). */
  chromeIn: SharedValue<number>;
  /** The sheet's close translate — the chrome counter-translates by −closeY
   *  so it stays screen-pinned and the descending sheet edge CROPS it. */
  closeY: SharedValue<number>;
  /** Stage 57: transform-only chrome spawn (alpha over UIGlassEffect renders
   *  broken/black on device — the old opacity fade caused the black blobs at
   *  the canvas top + the dirty dark shadow during the entrance). */
  glassSpawn: 'clip' | 'pop';
  /** Morph (viaMorph) reconstruction (Stage 54): the ghost Stage-1 header
   *  flies up (0→1 on the rise spring) and the placeholder cross-fades
   *  old→new with tracking 0.2→0.8 (0→1 on placeholderSwap). */
  morph?: {ghost: SharedValue<number>; placeholderP: SharedValue<number>};
  inputRef?: React.RefObject<TextInput | null>;
};

export function RedesignedCanvas({
  openPicker,
  onCloseTap,
  onClearTap,
  onConfirmTap,
  onBackdropTap,
  shadow,
  chromeIn,
  closeY,
  glassSpawn,
  morph,
  inputRef,
}: Props) {
  const [text, setText] = useState('');
  // Auto-detected tag demo: 0.5s after the last keystroke a random tag appears
  // in the publicity pill (one tag max); clearing the text retires it.
  const [tag, setTag] = useState('');
  const tagToken = useRef(0);

  // Frosted backdrop over the input while the picker is open — a FIXED
  // intensity blur cross-faded via opacity (never animate blur intensity
  // per frame — the previous port's biggest jank source).
  const pickerShown = openPicker !== 'none';
  // Header title latches on open and survives the close (native pickerTitle).
  const titleRef = useRef('When');
  if (pickerShown) {
    titleRef.current = openPicker === 'routine' ? 'Routine' : 'When';
  }
  const backdrop = useSharedValue(0);
  useEffect(() => {
    backdrop.value = withSpring(pickerShown ? 1 : 0, pickerShown ? openSpring : closeSpring);
  }, [pickerShown, backdrop]);
  const backdropStyle = useAnimatedStyle(() => ({opacity: backdrop.value}));

  const onTextChange = useCallback((next: string) => {
    setText(next);
    tagToken.current += 1;
    if (next === '') {
      setTag('');
      return;
    }
    const token = tagToken.current;
    setTimeout(() => {
      if (tagToken.current !== token) {
        return;
      }
      setTag(prev => (prev === '' ? SAMPLE_TAGS[Math.floor(Math.random() * SAMPLE_TAGS.length)] : prev));
    }, 500);
  }, []);

  // Entrance (chromeIn 0→1 on newHeaderSpring) — TRANSFORM-ONLY, the glass
  // never leaves alpha 1 (Stage 57): 'clip' slides down from above the
  // sheet's clip edge; 'pop' scale-pops 0.9→1 with the native −28 drop
  // (hidden pre-beat via scale 0, not alpha). The close CROP counter-translate
  // (−closeY, chrome screen-pinned while the sheet edge eats it) is unchanged.
  const chromeStyle = useAnimatedStyle(() => {
    const p = chromeIn.value;
    if (glassSpawn === 'pop' && p > 0) {
      // Scale NEVER reaches 0 — a degenerate transform matrix permanently
      // broke the hosted SwiftUI image rendering (the ✕ glyph vanished).
      return {
        transform: [
          {translateY: (1 - p) * NEW_HEADER_DROP - closeY.value},
          {scale: 0.9 + 0.1 * p},
        ],
      };
    }
    // Pre-beat (both modes) + the whole 'clip' entrance: parked above the
    // sheet's overflow-hidden top edge, alpha untouched.
    return {
      transform: [{translateY: (1 - p) * -CHROME_PARK - closeY.value}],
    };
  });

  // Morph reconstruction (fallback shared value keeps the hooks unconditional;
  // the morph prop is stable for the life of the mount).
  const settled = useSharedValue(1);
  const ghostSV = morph?.ghost ?? settled;
  const placeSV = morph?.placeholderP ?? settled;
  const ghostStyle = useAnimatedStyle(() => ({
    opacity: 1 - ghostSV.value,
    transform: [{translateY: -MorphChoreo.ghostRise * ghostSV.value}],
  }));
  const oldPlaceholderStyle = useAnimatedStyle(() => ({opacity: 1 - placeSV.value}));
  const newPlaceholderStyle = useAnimatedStyle(() => ({
    opacity: placeSV.value,
    // Native placeholderSwap animates tracking 0.2 → 0.8 with the cross-fade.
    letterSpacing: 0.2 + (INPUT_TRACKING - 0.2) * placeSV.value,
  }));

  return (
    <View style={styles.fill} pointerEvents="box-none">
      {/* Top chrome — the native Fabric leaf; the cluster swap runs on native
          springs, the container animates on the RN timelines (worklets). */}
      <Animated.View style={[styles.chrome, chromeStyle]}>
        <NumoChromeView
          style={styles.fill}
          pickerOpen={pickerShown}
          pickerTitle={titleRef.current}
          tag={tag}
          shadowOpacity={shadow.opacity}
          shadowRadius={shadow.radius}
          onChromePress={e => {
            const el = e.nativeEvent.element;
            if (el === 'close') {
              onCloseTap();
            } else if (el === 'clear') {
              onClearTap();
            } else if (el === 'confirm') {
              onConfirmTap();
            }
          }}
        />
      </Animated.View>

      {/* Input zone with the custom placeholder (exact 46pt line height). */}
      <View style={styles.inputZone}>
        {text === '' && morph && (
          <Animated.Text
            style={[styles.placeholder, styles.oldTracking, oldPlaceholderStyle]}
            pointerEvents="none">
            {OLD_PLACEHOLDER}
          </Animated.Text>
        )}
        {text === '' && (
          <Animated.Text
            style={[styles.placeholder, morph ? newPlaceholderStyle : null]}
            pointerEvents="none">
            {NEW_PLACEHOLDER}
          </Animated.Text>
        )}
        <TextInput
          ref={inputRef}
          style={styles.input}
          value={text}
          onChangeText={onTextChange}
          multiline
          cursorColor={color.highlight}
          selectionColor={color.highlight}
          keyboardAppearance="light"
        />
        {/* Frosted backdrop (Figma panel: backdrop-blur + white@55%) — sits
            over the input only; fades on the picker springs. */}
        <Animated.View
          style={[StyleSheet.absoluteFill, backdropStyle]}
          pointerEvents={pickerShown ? 'auto' : 'none'}>
          <BlurView intensity={BACKDROP_BLUR_INTENSITY} tint="light" style={styles.fill} />
          <View style={[StyleSheet.absoluteFill, styles.backdropDim]} />
          <Pressable style={StyleSheet.absoluteFill} onPress={onBackdropTap} />
        </Animated.View>
      </View>

      {/* Ghost Stage-1 header (viaMorph): reconstructs the stretched console's
          back + Public pill so nothing vanishes at the swap; flies up + fades
          during the rise, cropped by the sheet's clipped top. */}
      {morph && (
        <Animated.View style={[styles.ghostHeader, ghostStyle]} pointerEvents="none">
          <Stage1Header />
        </Animated.View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  fill: {flex: 1},
  chrome: {height: CHROME_HEIGHT, alignSelf: 'stretch'},
  inputZone: {flex: 1},
  placeholder: {
    position: 'absolute',
    top: 0,
    left: INPUT_PAD_H,
    right: INPUT_PAD_H,
    fontFamily: font.narrowBold,
    fontSize: 40,
    lineHeight: INPUT_LINE_HEIGHT,
    letterSpacing: INPUT_TRACKING,
    color: color.grayNormal,
  },
  input: {
    paddingHorizontal: INPUT_PAD_H,
    paddingTop: 0,
    paddingBottom: 0,
    textAlignVertical: 'top',
    fontFamily: font.narrowBold,
    fontSize: 40,
    lineHeight: INPUT_LINE_HEIGHT,
    letterSpacing: INPUT_TRACKING,
    color: color.ink,
  },
  backdropDim: {backgroundColor: `rgba(255,255,255,${BACKDROP_DIM})`},
  oldTracking: {letterSpacing: 0.2}, // Metrics.inputTracking (Stage-1 console)
  ghostHeader: {position: 'absolute', top: 0, left: 0, right: 0, height: 88},
});

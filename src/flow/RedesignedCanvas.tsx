/**
 * Stage 50 — the redesigned task-entry screen's sheet CONTENT, rebuilt in RN
 * (mirrors `RedesignedScreen.sheet()`): the native Fabric chrome leaf
 * (✕ + publicity ⇄ Clear + ✓), the natural-language input with the custom
 * placeholder, and the frosted backdrop while the When-picker is open.
 * The parent (BraindumpFlow) owns the sheet's position/clip and the timelines.
 */
import React, {useCallback, useEffect, useRef, useState} from 'react';
import {Pressable, StyleSheet, Text, TextInput, View} from 'react-native';
import {BlurView} from 'expo-blur';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  type SharedValue,
} from 'react-native-reanimated';

import {NumoChromeView} from '../../modules/glass-tab-bar';
import {openSpring, closeSpring} from '../braindump/motion';
import {color, font} from '../braindump/tokens';

// Native geometry (Metrics.Redesign / Metrics.WhenPicker).
const HEADER_PAD_V = 20;
const CLOSE_SIZE = 48;
export const CHROME_HEIGHT = HEADER_PAD_V * 2 + CLOSE_SIZE; // 88
const INPUT_PAD_H = 24;
const INPUT_TRACKING = 0.8;
const INPUT_LINE_HEIGHT = 46; // ObviouslyNarrow-Bold 40
const BACKDROP_DIM = 0.55;
const BACKDROP_BLUR_INTENSITY = 8; // ≈ native backdropBlur 4pt radius

const NEW_HEADER_DROP = -28; // MorphChoreo.newHeaderDrop

const NEW_PLACEHOLDER = 'Type naturally: e.g.\n"meds 9am daily"';

const SAMPLE_TAGS = ['House 01', 'Work', 'Ideas', 'Groceries', 'Trip'];

type Props = {
  whenOpen: boolean;
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
  inputRef?: React.RefObject<TextInput | null>;
};

export function RedesignedCanvas({
  whenOpen,
  onCloseTap,
  onClearTap,
  onConfirmTap,
  onBackdropTap,
  shadow,
  chromeIn,
  closeY,
  inputRef,
}: Props) {
  const [text, setText] = useState('');
  // Auto-detected tag demo: 2s after the last keystroke a random tag appears
  // in the publicity pill (one tag max); clearing the text retires it.
  const [tag, setTag] = useState('');
  const tagToken = useRef(0);

  // Frosted backdrop over the input while the picker is open — a FIXED
  // intensity blur cross-faded via opacity (never animate blur intensity
  // per frame — the previous port's biggest jank source).
  const backdrop = useSharedValue(0);
  useEffect(() => {
    backdrop.value = withSpring(whenOpen ? 1 : 0, whenOpen ? openSpring : closeSpring);
  }, [whenOpen, backdrop]);
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
    }, 2000);
  }, []);

  // Entrance drop (−28 → 0 + fade, newHeaderSpring drives chromeIn) and the
  // close CROP: the chrome counter-translates by −closeY so it stays
  // screen-pinned while the sheet's descending top edge eats it top-down.
  const chromeStyle = useAnimatedStyle(() => ({
    opacity: chromeIn.value,
    transform: [{translateY: (1 - chromeIn.value) * NEW_HEADER_DROP - closeY.value}],
  }));

  return (
    <View style={styles.fill} pointerEvents="box-none">
      {/* Top chrome — the native Fabric leaf; the cluster swap runs on native
          springs, the container animates on the RN timelines (worklets). */}
      <Animated.View style={[styles.chrome, chromeStyle]}>
        <NumoChromeView
          style={styles.fill}
          pickerOpen={whenOpen}
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
        {text === '' && (
          <Text style={styles.placeholder} pointerEvents="none">
            {NEW_PLACEHOLDER}
          </Text>
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
          pointerEvents={whenOpen ? 'auto' : 'none'}>
          <BlurView intensity={BACKDROP_BLUR_INTENSITY} tint="light" style={styles.fill} />
          <View style={[StyleSheet.absoluteFill, styles.backdropDim]} />
          <Pressable style={StyleSheet.absoluteFill} onPress={onBackdropTap} />
        </Animated.View>
      </View>
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
});

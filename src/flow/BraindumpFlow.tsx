/**
 * Stage 49 — the RN braindump flow root (the NumoFlowView replacement behind
 * the debug toggle). This stage mounts only the static resting canvas
 * skeleton so the toggle visibly switches implementations; Stages 50–54 build
 * the real screens + timelines (see tasks/todo.md).
 */
import React from 'react';
import {Image, Pressable, StyleSheet, Text, View, useWindowDimensions} from 'react-native';
import {useSafeAreaInsets} from 'react-native-safe-area-context';

interface Props {
  /** The flow finished closing — unmount the overlay. */
  onClosed: () => void;
}

const SHEET_TOP_RADIUS = 48;

export function BraindumpFlow({onClosed}: Props) {
  const insets = useSafeAreaInsets();
  const {height: windowH} = useWindowDimensions();

  return (
    <View style={styles.root} pointerEvents="box-none">
      <Image
        source={require('../assets/redesign_bg.jpg')}
        style={[styles.bg, {height: windowH}]}
        resizeMode="cover"
      />
      <View style={[styles.sheet, {top: insets.top}]}>
        <Text style={styles.wip}>RN flow — Stage 50 WIP</Text>
        {/* Temporary close hatch until the native chrome lands (Stage 50). */}
        <Pressable style={styles.closeHatch} onPress={onClosed} hitSlop={16} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {position: 'absolute', top: 0, left: 0, right: 0, bottom: 0},
  bg: {position: 'absolute', top: 0, left: 0, right: 0},
  sheet: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: SHEET_TOP_RADIUS,
    borderTopRightRadius: SHEET_TOP_RADIUS,
  },
  wip: {marginTop: 96, textAlign: 'center', fontSize: 14, color: '#9A9CA1'},
  closeHatch: {position: 'absolute', top: 24, left: 24, width: 44, height: 44},
});

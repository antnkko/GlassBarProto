import {useScrollEdgeEffectRef} from '@bsky.app/expo-scroll-edge-effect';
import React, {useRef} from 'react';
import {ScrollView, StyleSheet, Text, View} from 'react-native';

// Busy, colorful scrollable content so the glass has something to sample.
const CARD_PALETTES: Record<string, string[]> = {
  home: ['#FFD9C2', '#FFB58A', '#F65D00', '#B84500', '#FFF2ED', '#6B3B1F'],
  squad: ['#C9E4FF', '#7FBFFF', '#2E86E0', '#134A82', '#EAF4FF', '#1F3B5C'],
  chat: ['#D8F5D0', '#A3E28F', '#57B93C', '#2C6B1C', '#F0FBEC', '#2C4A22'],
  play: ['#F0D9FF', '#D3A3FF', '#9A4DE0', '#5C2391', '#FAF0FF', '#3D2455'],
};

// Same hues, re-toned for the dark background (#121316): pastels become deep
// shades, one vivid per palette stays as the accent pop.
const CARD_PALETTES_DARK: Record<string, string[]> = {
  home: ['#3A2519', '#5C3212', '#F65D00', '#9E3F05', '#2A1C13', '#7A4526'],
  squad: ['#16283D', '#1E3F63', '#2E86E0', '#0F3A6B', '#131C26', '#2A5486'],
  chat: ['#1C2E18', '#2B4A20', '#57B93C', '#1F5715', '#161F13', '#3B6B2C'],
  play: ['#2B1D38', '#43265C', '#9A4DE0', '#4E1E7E', '#1E1626', '#5C3A80'],
};

interface Props {
  tab: string;
  title: string;
  dark?: boolean;
  /** Instagram-style bar minimize: fires true on scroll down, false on scroll up / near top. */
  onCollapseChange?: (collapsed: boolean) => void;
}

export default function DemoScreen({tab, title, dark = false, onCollapseChange}: Props) {
  const palettes = dark ? CARD_PALETTES_DARK : CARD_PALETTES;
  const palette = palettes[tab] ?? palettes.home;
  // Lets the native scroll-edge effects (progressive blur) attach to this scroll view.
  const scrollEdgeRef = useScrollEdgeEffectRef();
  const lastY = useRef(0);
  const collapsed = useRef(false);
  return (
    <View style={[styles.root, dark && styles.rootDark]}>
      <ScrollView
        ref={scrollEdgeRef}
        // The native scroll edge effects render inside the scroll view's
        // adjusted-inset region. RN defaults to "never", which leaves that
        // region zero-height — the system then has nowhere to draw the top
        // pocket. "automatic" restores the native safe-area context.
        contentInsetAdjustmentBehavior="automatic"
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
        scrollEventThrottle={16}
        onScroll={e => {
          // With automatic insets the offset at rest is -inset.top — normalize.
          const y = e.nativeEvent.contentOffset.y + (e.nativeEvent.contentInset?.top ?? 0);
          const dy = y - lastY.current;
          lastY.current = y;
          let next: boolean | null = null;
          if (y < 24) {
            next = false;
          } else if (dy > 4) {
            next = true;
          } else if (dy < -4) {
            next = false;
          }
          if (next !== null && next !== collapsed.current) {
            collapsed.current = next;
            onCollapseChange?.(next);
          }
        }}>
        <Text style={[styles.title, dark && styles.titleDark]}>{title}</Text>
        {Array.from({length: 14}, (_, i) => (
          <View
            key={i}
            style={[
              styles.card,
              {backgroundColor: palette[i % palette.length]},
              i % 3 === 0 && styles.cardTall,
            ]}>
            <Text style={[styles.cardLabel, dark && styles.cardLabelDark]}>
              {title} · block {i + 1}
            </Text>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: '#FFFFFF'},
  rootDark: {backgroundColor: '#121316'},
  titleDark: {color: '#F5F5F7'},
  cardLabelDark: {color: 'rgba(255,255,255,0.6)'},
  // Top padding is smaller now: the automatic content inset already adds the
  // safe-area height above the content.
  content: {paddingTop: 20, paddingHorizontal: 20, paddingBottom: 220, gap: 14},
  title: {fontSize: 34, fontWeight: '700', color: '#1B1D21', marginBottom: 6},
  card: {
    height: 96,
    borderRadius: 24,
    justifyContent: 'flex-end',
    padding: 16,
  },
  cardTall: {height: 180},
  cardLabel: {color: 'rgba(0,0,0,0.45)', fontWeight: '600'},
});

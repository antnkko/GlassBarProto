import SegmentedControl from '@react-native-segmented-control/segmented-control';
import React from 'react';
import {Pressable, ScrollView, StyleSheet, Text, View} from 'react-native';

import type {ToolbarOption} from '../../modules/glass-tab-bar';
import type {AppConfig} from './configSchema';

interface Props {
  config: AppConfig;
  dark?: boolean;
  onChange: (patch: Partial<AppConfig>) => void;
  onClose: () => void;
  /** Opens a native braindump-flow mode (NumoPrototype merge). */
  onFlowAction?: (mode: 'braindump' | 'dumped' | 'switch' | 'reset') => void;
}

// Figma dev-spec toolbar rows; index === ToolbarOption, 0 = off.
const TOOLBAR_LABELS = ['Off', '1', '2', '3', '4', '5', '6', '7', '8'];

interface Palette {
  bg: string;
  text: string;
  sub: string;
  chip: string;
}

const LIGHT_PALETTE: Palette = {bg: '#FFFFFF', text: '#1B1D21', sub: '#9A9CA1', chip: '#F2F2F4'};
const DARK_PALETTE: Palette = {bg: '#1B1D21', text: '#F5F5F7', sub: '#8A8D93', chip: '#2A2D33'};

export default function DebugPanel({config, dark = false, onChange, onClose, onFlowAction}: Props) {
  const pal = dark ? DARK_PALETTE : LIGHT_PALETTE;
  const [didReset, setDidReset] = React.useState(false);

  return (
    <>
      <Pressable style={s.backdrop} onPress={onClose} />
      <View style={[s.panel, {backgroundColor: pal.bg}]}>
        <View style={s.header}>
          <Text style={[s.title, {color: pal.text}]}>Glass tuner</Text>
          <Pressable onPress={onClose} hitSlop={12} style={[s.closeBtn, {backgroundColor: pal.chip}]}>
            <Text style={[s.closeTxt, {color: pal.text}]}>✕</Text>
          </Pressable>
        </View>

        <ScrollView style={s.scroll} contentContainerStyle={s.scrollContent} showsVerticalScrollIndicator={false}>
          <Section pal={pal} title="Тулбар">
            <SegmentedControl
              appearance={dark ? 'dark' : 'light'}
              values={TOOLBAR_LABELS}
              selectedIndex={config.toolbarOption}
              onChange={e =>
                onChange({toolbarOption: e.nativeEvent.selectedSegmentIndex as ToolbarOption})
              }
            />
            <Text style={[s.hint, {color: pal.sub}]}>{toolbarHint(config.toolbarOption)}</Text>
          </Section>

          <Section pal={pal} title="Appearance">
            <SegmentedControl
              appearance={dark ? 'dark' : 'light'}
              values={['Light', 'Dark']}
              selectedIndex={config.appearance === 'dark' ? 1 : 0}
              onChange={e => onChange({appearance: e.nativeEvent.selectedSegmentIndex === 1 ? 'dark' : 'light'})}
            />
          </Section>

          <Section pal={pal} title="Braindump">
            <ActionRow
              pal={pal}
              label={didReset ? 'Onboarding reset ✓' : 'Reset onboarding'}
              hint="Наступний плюс програє онбординг і морф заново"
              onPress={() => {
                setDidReset(true);
                onFlowAction?.('reset');
              }}
            />
            <ActionRow
              pal={pal}
              label="Confirmation animation"
              hint="Екран підтвердження голосового дампу (letter bounce)"
              onPress={() => onFlowAction?.('dumped')}
            />
            <ActionRow
              pal={pal}
              label="Switch demo"
              hint="Анімація сегментованого світчера"
              onPress={() => onFlowAction?.('switch')}
            />
          </Section>

          {/* Material, motion, scrim, stroke and shadow are all frozen at the
              final design look. */}
        </ScrollView>
      </View>
    </>
  );
}

function toolbarHint(option: ToolbarOption): string {
  const hints = [
    'Без тулбара',
    'Аватар',
    'Back · тайтл + сабтайтл · аватар',
    'Back · тайтл + акцент-сабтайтл · translate',
    'Тільки back',
    'Settings · close',
    'Back · група Aa | ⋯',
    'Back · прогрес',
    'Back · CTA-кнопка',
  ];
  return hints[option] ?? '';
}

// ---- primitives ----

function ActionRow({
  label,
  hint,
  pal,
  onPress,
}: {
  label: string;
  hint: string;
  pal: Palette;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({pressed}) => [s.actionRow, {backgroundColor: pal.chip}, pressed && {opacity: 0.6}]}>
      <Text style={[s.actionLabel, {color: pal.text}]}>{label}</Text>
      <Text style={[s.hint, {color: pal.sub, textAlign: 'left'}]}>{hint}</Text>
    </Pressable>
  );
}

function Section({title, pal, children}: {title: string; pal: Palette; children: React.ReactNode}) {
  return (
    <View style={s.section}>
      <Text style={[s.sectionTitle, {color: pal.sub}]}>{title}</Text>
      {children}
    </View>
  );
}



const s = StyleSheet.create({
  backdrop: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  panel: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    maxHeight: '62%',
    backgroundColor: '#FFFFFF',
    borderBottomLeftRadius: 28,
    borderBottomRightRadius: 28,
    paddingTop: 64,
    shadowColor: '#000',
    shadowOpacity: 0.18,
    shadowRadius: 24,
    shadowOffset: {width: 0, height: 8},
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingBottom: 8,
  },
  title: {fontSize: 20, fontWeight: '700', color: '#1B1D21'},
  closeBtn: {width: 32, height: 32, borderRadius: 16, backgroundColor: '#F2F2F4', alignItems: 'center', justifyContent: 'center'},
  closeTxt: {fontSize: 14, color: '#1B1D21'},
  scroll: {flexGrow: 0},
  scrollContent: {paddingHorizontal: 20, paddingBottom: 30},
  section: {marginTop: 14, gap: 10},
  sectionTitle: {fontSize: 12, fontWeight: '700', color: '#9A9CA1', textTransform: 'uppercase', letterSpacing: 0.6},
  row: {gap: 0},
  rowHead: {flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center'},
  rowLabel: {fontSize: 14, color: '#1B1D21'},
  rowValue: {
    fontSize: 14,
    fontVariant: ['tabular-nums'],
    color: '#1B1D21',
    minWidth: 44,
    textAlign: 'center',
  },
  slider: {width: '100%', height: 36},
  stepper: {flexDirection: 'row', alignItems: 'center', gap: 2},
  stepBtn: {
    width: 28,
    height: 28,
    borderRadius: 8,
    backgroundColor: '#F2F2F4',
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepBtnTxt: {fontSize: 16, color: '#1B1D21', lineHeight: 18},
  toggleRow: {flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center'},
  swatches: {flexDirection: 'row', justifyContent: 'space-between'},
  swatchWrap: {alignItems: 'center', gap: 4, width: 78},
  swatchRing: {
    width: 44,
    height: 44,
    borderRadius: 22,
    borderWidth: 2.5,
    borderColor: 'transparent',
    alignItems: 'center',
    justifyContent: 'center',
  },
  swatch: {width: 32, height: 32, borderRadius: 16},
  swatchLabel: {fontSize: 11, color: '#9A9CA1'},
  hint: {fontSize: 12, color: '#9A9CA1', textAlign: 'center'},
  actionRow: {borderRadius: 12, paddingHorizontal: 14, paddingVertical: 10, gap: 2},
  actionLabel: {fontSize: 14, fontWeight: '600'},
});

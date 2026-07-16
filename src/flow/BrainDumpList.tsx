/**
 * Stage 52 — Stage-1 brain-dump screen rebuilt in RN (BrainDumpScreen.swift +
 * Sections/*, geometry 1:1 from Metrics.swift): vibrant canvas, voice banner →
 * console card → section cards, with the RN-original entrance cascade — all
 * blocks release SIMULTANEOUSLY one frame after mount; the cascade look comes
 * purely from the different start offsets (banner/console 30, subtasks 50,
 * effort+settings 70, time+order+tags+notes 90), one spring, transform-only.
 *
 * Stage 53 wires the morph Act I stretch into the same component: banner +
 * console pull down 30 and the console GROWS by 700 — implemented as a
 * transform of the sections block + a console bg extension leaf, never a
 * per-frame layout of the card subtree.
 */
import React, {useEffect} from 'react';
import {Image, ScrollView, StyleSheet, Text, TextInput, View} from 'react-native';
import {useSafeAreaInsets} from 'react-native-safe-area-context';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  type SharedValue,
} from 'react-native-reanimated';

import {PressFade} from '../braindump/PressFade';
import {color, font} from '../braindump/tokens';
import {Entrance, MorphChoreo} from './choreo';

// ── Metrics.swift (Stage-1 block), 1:1 ──────────────────────────────────────
const M = {
  cardRadius: 36,
  cardPadding: 32,
  cardMinHeight: 92,
  cardTopMargin: 3,
  headerInset: 20,
  backSize: 48,
  backIcon: 28,
  pillPadLeading: 16,
  pillPadV: 10,
  pillPadTrailing: 12,
  pillIcon: 28,
  pillChevron: 20,
  pillGap: 8,
  pillTextChevronGap: 2,
  inputTopMargin: 64,
  inputBottomMargin: 36,
  inputMinHeight: 120,
  inputTracking: 0.2,
  inputMaxLength: 60,
  sectionGap: 3,
  sectionGapNotes: 4,
  headerIconGap: 8,
  headerBottom: 20,
  headerBottomTight: 16,
  controlCircle: 56,
  toggleRadius: 24,
  toggleBorder: 3,
  togglePadLeading: 24,
  togglePadTop: 20,
  togglePadBottom: 24,
  toggleGap: 8,
  whenOptionsTop: 24,
  whenRowGap: 8,
  whenContentGap: 16,
  orderPadV: 18,
  tagsIndent: 16,
  chipHeight: 44,
  chipRadius: 12,
  chipPadH: 16,
  chipBorder: 1,
  chipGap: 22,
  manageTop: 14,
  dividerThickness: 1.5,
  dividerBottom: 20,
  notesIndent: 36,
  notesMinHeight: 124,
  notesHeaderBottom: 4,
  bannerHeight: 128,
  bannerOverlap: 64,
  bannerPadH: 32,
  bannerPadTop: 22,
  bannerPadBottom: 20,
  fabClearance: 120,
  inputLineHeight: 46, // ObviouslyNarrow-Bold 40 (UILabel lineHeightMultiple 0.78)
} as const;

const grayDarkish = '#4E4E4E'; // NumoColor.grayDarkish (back chevron)

// ── Shared bits ─────────────────────────────────────────────────────────────

function Icon({name, size = 28, tint}: {name: string; size?: number; tint: string}) {
  return (
    <Image
      source={{uri: name}}
      style={{width: size, height: size, tintColor: tint}}
      resizeMode="contain"
    />
  );
}

function SectionCard({
  children,
  paddingV = M.cardPadding,
}: {
  children: React.ReactNode;
  paddingV?: number;
}) {
  return (
    <View
      style={[
        styles.sectionCard,
        {paddingVertical: paddingV},
      ]}>
      {children}
    </View>
  );
}

function SectionHeader({icon, title}: {icon: string; title: string}) {
  return (
    <View style={styles.sectionHeader}>
      <Icon name={icon} tint={color.vibrant} />
      <Text style={styles.sectionTitle}>{title}</Text>
    </View>
  );
}

// ── Sections (Sections/*.swift, collapsed defaults) ─────────────────────────

function VoiceBanner() {
  return (
    <View style={styles.banner}>
      <Image source={{uri: 'welcome_bg'}} style={styles.bannerBg} resizeMode="cover" />
      <View style={styles.bannerRow}>
        <Text style={styles.bannerLabel}>Switch to Ai voice mode</Text>
        <Icon name="micro_28" tint={color.white} />
      </View>
    </View>
  );
}

/** The Stage-1 console header (back + Public pill) — also reused by the
 *  redesign's morph reconstruction as the "ghost" header (Stage 54). */
export function Stage1Header({onBack}: {onBack?: () => void}) {
  return (
    <View style={styles.consoleHeader} pointerEvents="box-none">
      <PressFade onPress={onBack ?? (() => {})}>
        <View style={styles.backBtn}>
          <Icon name="back" tint={grayDarkish} />
        </View>
      </PressFade>
      <View style={styles.pill}>
        <Icon name="announcement" tint={color.vibrant} />
        <View style={styles.pillTextRow}>
          <Text style={styles.pillLabel}>Public</Text>
          <Icon name="downchevron" size={M.pillChevron} tint={color.vibrant} />
        </View>
      </View>
    </View>
  );
}

/** Old console placeholder copy — the morph reconstruction cross-fades it
 *  into the redesign's placeholder (Stage 54). */
export const OLD_PLACEHOLDER = 'Brain dump your\ntasks…';

function ConsoleCard({
  text,
  onChangeText,
  onBack,
  stretchP,
}: {
  text: string;
  onChangeText: (t: string) => void;
  onBack: () => void;
  /** Morph Act I progress — grows the white card downward by consoleGrowth
   *  via an absolute childless LEAF (its layout touches nothing else). */
  stretchP: SharedValue<number>;
}) {
  const extensionStyle = useAnimatedStyle(() => ({
    // 36 tucks under the card's own rounded corners at rest (invisible); the
    // rounded bottom edge travels down with the growth, exactly like the
    // native card's shape growing.
    height: 36 + MorphChoreo.consoleGrowth * stretchP.value,
  }));
  return (
    <View style={styles.console}>
      {/* Growth extension — first child, drawn under the card content. */}
      <Animated.View style={[styles.consoleExtension, extensionStyle]} />
      <View style={styles.consoleInputZone}>
        {text === '' && (
          <Text style={styles.consolePlaceholder} pointerEvents="none">
            {OLD_PLACEHOLDER}
          </Text>
        )}
        <TextInput
          style={styles.consoleInput}
          value={text}
          onChangeText={onChangeText}
          multiline
          maxLength={M.inputMaxLength}
          cursorColor={color.vibrant}
          selectionColor={color.vibrant}
          keyboardAppearance="light"
        />
      </View>
      {/* Header — absolute top 20 / sides 20, over the card. */}
      <Stage1Header onBack={onBack} />
    </View>
  );
}

function SubtasksSection() {
  return (
    <SectionCard>
      <SectionHeader icon="subtasks_arrows" title="Add subtasks" />
    </SectionCard>
  );
}

function EffortSection() {
  return (
    <SectionCard>
      <SectionHeader icon="difficulty_28" title="Estimated effort" />
      <View style={[styles.rowBetween, {paddingTop: M.headerBottom}]}>
        {['S', 'M', 'L', 'XL'].map(level => (
          <View key={level} style={styles.effortCircle}>
            <Text style={styles.sectionTitle}>{level}</Text>
          </View>
        ))}
      </View>
    </SectionCard>
  );
}

function TaskTypeToggle({icon, label, selected}: {icon: string; label: string; selected: boolean}) {
  return (
    <View
      style={[
        styles.toggle,
        selected
          ? {backgroundColor: color.vibrant, borderColor: color.vibrant}
          : {backgroundColor: 'transparent', borderColor: color.grayAlmost},
      ]}>
      <Icon name={icon} tint={selected ? color.white : color.grayNormal} />
      <Text style={[styles.toggleLabel, {color: selected ? color.white : color.ink}]}>
        {label}
      </Text>
    </View>
  );
}

function WhenOptionRow({icon, label, selected}: {icon: string; label: string; selected: boolean}) {
  return (
    <View style={styles.whenRow}>
      <View
        style={[
          styles.whenCircle,
          {backgroundColor: selected ? color.vibrant : color.skinLight},
        ]}>
        <Icon name={icon} tint={selected ? color.white : color.vibrant} />
      </View>
      <View style={[styles.rowCenter, {paddingLeft: M.whenContentGap, gap: M.headerIconGap}]}>
        <Text style={[styles.sectionTitle, !selected && {color: color.ink}]}>{label}</Text>
        {selected && <Icon name="check_icon" tint={color.vibrant} />}
      </View>
    </View>
  );
}

function SettingsSection() {
  return (
    <SectionCard>
      <View style={[styles.rowCenter, {gap: M.toggleGap, alignSelf: 'stretch'}]}>
        <TaskTypeToggle icon="task_big" label="Task" selected />
        <TaskTypeToggle icon="repeat_icon" label="Routine" selected={false} />
      </View>
      <View style={{paddingTop: M.whenOptionsTop, gap: M.whenRowGap, alignSelf: 'stretch'}}>
        <WhenOptionRow icon="star_calendar" label="Today" selected />
        <WhenOptionRow icon="calendar_icon" label="Tomorrow" selected={false} />
        <WhenOptionRow icon="arrows_right" label="Select date" selected={false} />
        <WhenOptionRow icon="backlog_icon" label="Someday / Backlog" selected={false} />
      </View>
    </SectionCard>
  );
}

function TimeSection() {
  return (
    <SectionCard>
      <SectionHeader icon="clock_icon" title="Add time" />
    </SectionCard>
  );
}

function OrderSection() {
  return (
    <SectionCard paddingV={M.orderPadV}>
      <View style={styles.rowCenter}>
        <View style={[styles.whenCircle, {backgroundColor: color.skinLight}]}>
          <Icon name="arrow_up_28" tint={color.vibrant} />
        </View>
        <Text style={[styles.pillLabel, {paddingLeft: M.whenContentGap}]}>
          Task will insert at top
        </Text>
      </View>
    </SectionCard>
  );
}

function TagsSection() {
  return (
    <SectionCard>
      <SectionHeader icon="promo_bold" title="Tags" />
      <View style={[styles.rowCenter, styles.tagsRow]}>
        {['Work', 'Personal', 'Health'].map(tag => (
          <View key={tag} style={styles.tagChip}>
            <Text style={styles.tagLabel}>{tag}</Text>
          </View>
        ))}
      </View>
      <View style={{paddingTop: M.manageTop, alignSelf: 'stretch'}}>
        <View style={styles.tagsDivider} />
        <SectionHeader icon="settings_bold" title="Manage" />
      </View>
    </SectionCard>
  );
}

function NotesSection() {
  return (
    <SectionCard>
      <SectionHeader icon="note_icon" title="Private note" />
      <Text style={styles.notesPlaceholder}>
        Leave yourself a note or comment about the task
      </Text>
    </SectionCard>
  );
}

// ── The screen ──────────────────────────────────────────────────────────────

type Props = {
  /** Console back button — leaves the flow. */
  onBack: () => void;
  /** Fired when the entrance release begins (the overlay reveal is timed off it). */
  onEntranceStart?: () => void;
  /** Morph Act I progress (0→1 on the drawDown spring) — banner+console pull
   *  down by consolePull, the console grows by consoleGrowth pushing all
   *  sections down as ONE block. Owned by the flow. */
  stretchP: SharedValue<number>;
  /** Scroll is disabled for the stretch (flipped once at Act I start). */
  scrollEnabled?: boolean;
};

export function BrainDumpList({onBack, onEntranceStart, stretchP, scrollEnabled = true}: Props) {
  const insets = useSafeAreaInsets();
  const [text, setText] = React.useState('');
  // ONE spring drives every block; the cascade comes from the offsets.
  const enterP = useSharedValue(0);

  useEffect(() => {
    // Defer one frame so the offset state renders first and the spring
    // actually animates (the native onAppear runloop-defer idiom).
    const id = requestAnimationFrame(() => {
      enterP.value = withSpring(1, Entrance.spring);
      onEntranceStart?.();
    });
    return () => cancelAnimationFrame(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Entrance offset + the Act-I stretch terms, combined in one worklet:
  // banner/console ride the 30pt pull; the sections ride the 700pt growth.
  const useSlide = (offset: number, pull: number, growth: number) =>
    useAnimatedStyle(() => ({
      transform: [
        {
          translateY:
            (1 - enterP.value) * offset +
            pull * stretchP.value +
            growth * stretchP.value,
        },
      ],
    }));
  const bannerSlide = useSlide(Entrance.banner, MorphChoreo.consolePull, 0);
  const consoleSlide = useSlide(Entrance.console, MorphChoreo.consolePull, 0);
  const subtasksSlide = useSlide(Entrance.subtasks, 0, MorphChoreo.consoleGrowth);
  const settingsSlide = useSlide(Entrance.settings, 0, MorphChoreo.consoleGrowth);
  const timeSlide = useSlide(Entrance.time, 0, MorphChoreo.consoleGrowth);

  return (
    <View style={styles.root}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        keyboardDismissMode="interactive"
        scrollEnabled={scrollEnabled}
        contentContainerStyle={{paddingTop: insets.top, paddingBottom: M.fabClearance}}>
        {/* The banner overlaps the console by 64; the console (a LATER
            sibling) draws on top, exactly like the SwiftUI VStack order. */}
        <Animated.View style={[{marginBottom: -M.bannerOverlap}, bannerSlide]}>
          <VoiceBanner />
        </Animated.View>
        <Animated.View style={[{marginTop: M.cardTopMargin}, consoleSlide]}>
          <ConsoleCard text={text} onChangeText={setText} onBack={onBack} stretchP={stretchP} />
        </Animated.View>
        <Animated.View style={[{marginTop: M.sectionGap}, subtasksSlide]}>
          <SubtasksSection />
        </Animated.View>
        <Animated.View style={settingsSlide}>
          <View style={{marginTop: M.sectionGap}}>
            <EffortSection />
          </View>
          <View style={{marginTop: M.sectionGap}}>
            <SettingsSection />
          </View>
        </Animated.View>
        <Animated.View style={timeSlide}>
          <View style={{marginTop: M.sectionGap}}>
            <TimeSection />
          </View>
          <View style={{marginTop: M.sectionGap}}>
            <OrderSection />
          </View>
          <View style={{marginTop: M.sectionGap}}>
            <TagsSection />
          </View>
          <View style={{marginTop: M.sectionGapNotes}}>
            <NotesSection />
          </View>
        </Animated.View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: color.vibrant},

  banner: {
    height: M.bannerHeight,
    borderTopLeftRadius: M.cardRadius,
    borderTopRightRadius: M.cardRadius,
    overflow: 'hidden',
  },
  bannerBg: {position: 'absolute', top: 0, left: 0, right: 0, bottom: 0},
  bannerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: M.bannerPadH,
    paddingTop: M.bannerPadTop,
  },
  bannerLabel: {
    flex: 1,
    fontFamily: font.semibold,
    fontSize: 16,
    color: color.white,
  },

  console: {
    backgroundColor: color.white,
    borderRadius: M.cardRadius,
    borderCurve: 'continuous',
    padding: M.cardPadding,
    minHeight: M.cardMinHeight,
  },
  consoleExtension: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: '100%',
    marginTop: -36,
    backgroundColor: color.white,
    borderBottomLeftRadius: M.cardRadius,
    borderBottomRightRadius: M.cardRadius,
    borderCurve: 'continuous',
  },
  consoleInputZone: {
    marginTop: M.inputTopMargin,
    marginBottom: M.inputBottomMargin,
    minHeight: M.inputMinHeight,
  },
  consolePlaceholder: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    fontFamily: font.narrowBold,
    fontSize: 40,
    lineHeight: M.inputLineHeight,
    letterSpacing: M.inputTracking,
    color: color.grayNormal,
  },
  consoleInput: {
    paddingTop: 0,
    paddingBottom: 0,
    paddingHorizontal: 0,
    textAlignVertical: 'top',
    fontFamily: font.narrowBold,
    fontSize: 40,
    lineHeight: M.inputLineHeight,
    letterSpacing: M.inputTracking,
    color: color.ink,
  },
  consoleHeader: {
    position: 'absolute',
    top: M.headerInset,
    left: M.headerInset,
    right: M.headerInset,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  backBtn: {
    width: M.backSize,
    height: M.backSize,
    borderRadius: M.backSize / 2,
    borderCurve: 'continuous',
    backgroundColor: color.grayAlmost,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingLeft: M.pillPadLeading,
    paddingRight: M.pillPadTrailing,
    paddingVertical: M.pillPadV,
    borderRadius: 999,
    backgroundColor: color.skinLight,
  },
  pillTextRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: M.pillTextChevronGap,
    paddingLeft: M.pillGap,
  },
  pillLabel: {
    fontFamily: font.semibold,
    fontSize: 16,
    color: color.vibrant,
  },

  sectionCard: {
    backgroundColor: color.white,
    borderRadius: M.cardRadius,
    borderCurve: 'continuous',
    paddingHorizontal: M.cardPadding,
    minHeight: M.cardMinHeight,
    justifyContent: 'center',
    alignItems: 'flex-start',
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: M.headerIconGap,
  },
  sectionTitle: {
    fontFamily: font.semibold,
    fontSize: 18,
    color: color.vibrant,
  },

  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignSelf: 'stretch',
  },
  rowCenter: {flexDirection: 'row', alignItems: 'center'},

  effortCircle: {
    width: M.controlCircle,
    height: M.controlCircle,
    borderRadius: M.controlCircle / 2,
    backgroundColor: color.skinLight,
    alignItems: 'center',
    justifyContent: 'center',
  },

  toggle: {
    flex: 1,
    borderRadius: M.toggleRadius,
    borderCurve: 'continuous',
    borderWidth: M.toggleBorder,
    paddingLeft: M.togglePadLeading,
    paddingTop: M.togglePadTop,
    paddingBottom: M.togglePadBottom,
  },
  toggleLabel: {
    fontFamily: font.narrowBold,
    fontSize: 28,
    paddingTop: 2,
  },

  whenRow: {flexDirection: 'row', alignItems: 'center', alignSelf: 'stretch'},
  whenCircle: {
    width: M.controlCircle,
    height: M.controlCircle,
    borderRadius: M.controlCircle / 2,
    alignItems: 'center',
    justifyContent: 'center',
  },

  tagsRow: {
    gap: M.chipGap,
    paddingLeft: M.tagsIndent,
    paddingTop: M.headerBottomTight,
    flexWrap: 'wrap',
  },
  tagChip: {
    height: M.chipHeight,
    borderRadius: M.chipRadius,
    borderCurve: 'continuous',
    borderWidth: M.chipBorder,
    borderColor: color.grayAlmost,
    paddingHorizontal: M.chipPadH,
    justifyContent: 'center',
  },
  tagLabel: {
    fontFamily: font.medium,
    fontSize: 16,
    color: color.ink,
  },
  tagsDivider: {
    alignSelf: 'stretch',
    height: M.dividerThickness,
    borderRadius: M.dividerThickness / 2,
    backgroundColor: color.grayAlmost,
    marginBottom: M.dividerBottom,
  },

  notesPlaceholder: {
    paddingLeft: M.notesIndent,
    paddingTop: M.notesHeaderBottom,
    minHeight: M.notesMinHeight,
    fontFamily: font.medium,
    fontSize: 16,
    color: color.grayNormal,
  },
});

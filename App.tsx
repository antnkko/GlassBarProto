import React, {useCallback, useEffect, useReducer, useRef, useState} from 'react';
import {Animated, Linking, LogBox, Pressable, StatusBar, StyleSheet, Text, View} from 'react-native';
import {SafeAreaProvider, useSafeAreaInsets} from 'react-native-safe-area-context';

// Prototype: silence the dev warning toast so it doesn't cover the bottom bar.
LogBox.ignoreAllLogs(true);

import {GlassEdgeBlurView, GlassTabBarView, GlassToolbarView, NumoFlowView} from './modules/glass-tab-bar';
import {BraindumpBottomBar} from './src/braindump/BraindumpBottomBar';
import type {PickerKind} from './src/braindump/MorphingShell';
import {createFlowBus} from './src/braindump/flowEvents';
import EdgeScrim from './src/components/EdgeScrim';
import DebugPanel from './src/debug/DebugPanel';
import {defaultConfig, toNativeConfig, type AppConfig} from './src/debug/configSchema';
import {loadConfig, saveConfigDebounced} from './src/debug/persist';
import {BraindumpFlow} from './src/flow/BraindumpFlow';
import {hasSeenOnboarding, resetOnboarding} from './src/flow/flowState';
import DemoScreen from './src/screens/DemoScreen';
import {initialTabState, tabReducer} from './src/state/tabState';
import {bar} from './src/theme/tokens';

const SCREEN_TITLES: Record<string, string> = {
  home: 'Home',
  squad: 'Squad',
  chat: 'Chat',
  play: 'Play',
};

/** Native braindump overlay modes (NumoFlow Fabric component). */
export type FlowMode = 'none' | 'braindump' | 'dumped' | 'switch' | 'reset';

// Native strip height for the toolbar overlay: tall enough for the CTA pill
// (60pt) in configuration 8, elements center vertically inside.
const TOOLBAR_HEIGHT = 64;

// Dev-only: cycle the bar states on a timer so the morph can be recorded
// headlessly (no tapping / no openurl confirm dialog). Keep false otherwise.
const DEV_AUTOPLAY = false;

// Dev-only (Stage 51): auto-play the RN braindump open → close once after
// launch so the slide timelines can be recorded headlessly (same reason as
// DEV_AUTOPLAY — simctl openurl pops a confirm dialog). Keep false otherwise.
const DEV_FLOW_AUTOPLAY = false;

function AppContent() {
  const insets = useSafeAreaInsets();
  const [state, dispatch] = useReducer(tabReducer, initialTabState);
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [panelOpen, setPanelOpen] = useState(false);
  // The braindump overlay: one immutable mode per mount (key includes seq so
  // every open is a fresh native mount with a fresh flow coordinator).
  const [flowMode, setFlowMode] = useState<FlowMode>('none');
  const [flowSeq, setFlowSeq] = useState(0);
  // Dev hook (glassbar://closeflow): bumping this runs the RN close timeline.
  const [closeSeq, setCloseSeq] = useState(0);
  // Stage 41/48: RN owns the braindump bottom-bar cluster. `openPicker` is
  // which picker is open ('none' | 'when' | 'routine'), mirrored into the
  // native header via the whenPickerOpen/routinePickerOpen props; the bus
  // relays native beats (entry/exit, Clear/✓/backdrop).
  const [openPicker, setOpenPicker] = useState<PickerKind>('none');
  const flowBus = useRef(createFlowBus()).current;
  const [barCollapsed, setBarCollapsed] = useState(false);
  const [scrolledTop, setScrolledTop] = useState(false);
  // The top scrim exists only once content scrolls under it, and it arrives
  // with a fade — a plain RN layer, so animating opacity is safe.
  const topScrimOpacity = useRef(new Animated.Value(0)).current;

  // Switching tabs restores the full-size bar and the resting (no-scrim) top.
  useEffect(() => {
    setBarCollapsed(false);
    setScrolledTop(false);
  }, [state.activeTab]);

  useEffect(() => {
    Animated.timing(topScrimOpacity, {
      toValue: scrolledTop ? 1 : 0,
      duration: 240,
      useNativeDriver: true,
    }).start();
  }, [scrolledTop, topScrimOpacity]);

  // Hydrate persisted config before the first render of the bar,
  // so a stored config doesn't visually snap in after mount.
  useEffect(() => {
    loadConfig().then(setConfig);
  }, []);

  // Stage 52: the RN flow's onboarding flag (native keeps its own in
  // UserDefaults). Loaded once; reset/completion update it in place.
  const [seenOnboarding, setSeenOnboarding] = useState(true);
  useEffect(() => {
    hasSeenOnboarding().then(setSeenOnboarding);
  }, []);

  const patchConfig = useCallback((patch: Partial<AppConfig>) => {
    setConfig(prev => {
      if (!prev) {
        return prev;
      }
      const next = {...prev, ...patch};
      saveConfigDebounced(next);
      return next;
    });
  }, []);

  // Opens the braindump overlay (or one of its demo modes). Each open
  // remounts the component (key below), so the flow always starts fresh.
  const lastOpenAt = useRef(0);
  const openFlow = useCallback((mode: FlowMode) => {
    lastOpenAt.current = Date.now();
    setPanelOpen(false);
    setOpenPicker('none');
    setFlowSeq(prev => prev + 1);
    setFlowMode(mode);
    // Stage 49: the RN flow keeps its own onboarding flag — the debug reset
    // clears both worlds (the native mode:'reset' mount clears UserDefaults).
    if (mode === 'reset') {
      resetOnboarding();
      setSeenOnboarding(false);
    }
  }, []);

  // Dev hook: drive the bar from outside for scripted testing —
  //   xcrun simctl openurl booted "glassbar://expand" | "glassbar://collapse" |
  //   "glassbar://sub/chat" | "glassbar://toolbar/5"
  //   Stage 51: "glassbar://plus" (open braindump) | "glassbar://closeflow"
  //   (run the RN close timeline) | "glassbar://flow/rn" | "glassbar://flow/native"
  // Exercises the RN-controlled-props path (native applies them once lastSeq catches up).
  useEffect(() => {
    const handleUrl = ({url}: {url: string}) => {
      if (url.includes('plus')) {
        openFlow('braindump');
      } else if (url.includes('closeflow')) {
        setCloseSeq(prev => prev + 1);
      } else if (url.includes('flow/rn')) {
        patchConfig({rnFlow: true});
      } else if (url.includes('flow/native')) {
        patchConfig({rnFlow: false});
      } else if (url.includes('expand')) {
        dispatch({type: 'forceExpand'});
      } else if (url.includes('collapse')) {
        dispatch({type: 'forceCollapse'});
      } else if (url.includes('sub/')) {
        const tab = url.split('sub/')[1]?.replace(/\W/g, '');
        if (tab === 'squad' || tab === 'chat' || tab === 'play') {
          dispatch({type: 'forceSubTab', tab});
        }
      } else if (url.includes('toolbar/')) {
        const option = Number(url.split('toolbar/')[1]?.replace(/\D/g, ''));
        if (option >= 0 && option <= 8) {
          patchConfig({toolbarOption: option as AppConfig['toolbarOption']});
        }
      }
    };
    const sub = Linking.addEventListener('url', handleUrl);
    return () => sub.remove();
  }, [openFlow, patchConfig]);

  useEffect(() => {
    if (!DEV_FLOW_AUTOPLAY || !config) {
      return;
    }
    patchConfig({rnFlow: true});
    // Always replay the full onboarding (reset the seen flag), then exercise
    // the picker + close. Timings leave room for the morph (~4.8s).
    resetOnboarding();
    setSeenOnboarding(false);
    const timers = [
      setTimeout(() => openFlow('braindump'), 2000),
      setTimeout(() => setOpenPicker('when'), 12000), // picker morph open
      setTimeout(() => setOpenPicker('none'), 13800), // picker morph close
      setTimeout(() => setCloseSeq(prev => prev + 1), 15000),
    ];
    return () => timers.forEach(clearTimeout);
    // Run once after config hydration.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [config !== null]);

  useEffect(() => {
    if (!DEV_AUTOPLAY) {
      return;
    }
    // Cycle the bar states and toolbar options so morphs can be recorded
    // headlessly (simctl openurl pops a confirm dialog on this sim).
    let step = 0;
    const id = setInterval(() => {
      const barScript = [
        () => dispatch({type: 'forceExpand'}),
        () => dispatch({type: 'forceSubTab', tab: 'chat'}),
        () => dispatch({type: 'forceSubTab', tab: 'play'}),
        () => dispatch({type: 'forceCollapse'}),
      ] as const;
      barScript[step % barScript.length]();
      patchConfig({toolbarOption: ((step + 1) % 9) as AppConfig['toolbarOption']});
      step += 1;
    }, 1600);
    return () => clearInterval(id);
  }, [patchConfig]);

  // Toolbar taps: settings opens the dev panel, back folds the expanded bar
  // (the natural "leave this screen" reflex); the rest just log to Metro.
  const handleToolbarPress = useCallback((element: string) => {
    console.log(`[toolbar] ${element}`);
    if (element === 'settings') {
      setPanelOpen(true);
    } else if (element === 'back') {
      dispatch({type: 'forceCollapse'});
    }
  }, []);

  if (!config) {
    return <View style={styles.root} />;
  }

  const dark = config.appearance === 'dark';
  const toolbarShown = config.toolbarOption > 0;

  return (
    <View style={[styles.root, dark && styles.rootDark]}>
      {/* The braindump overlay owns the vibrant/dark canvas — force light. */}
      <StatusBar barStyle={flowMode !== 'none' ? 'light-content' : dark ? 'light-content' : 'dark-content'} />

      <DemoScreen
        tab={state.activeTab}
        title={SCREEN_TITLES[state.activeTab] ?? state.activeTab}
        dark={dark}
        topExtra={toolbarShown ? TOOLBAR_HEIGHT : 0}
        onCollapseChange={setBarCollapsed}
        onScrolledChange={setScrolledTop}
      />

      {/* Design scrims (Figma 320:2512): plain eased gradients, no backdrop
          effects — the glass pills sample clean content underneath. */}
      {config.edgeBlur && (
        <EdgeScrim
          edge="bottom"
          dark={dark}
          smoothness={config.scrimSmoothness}
          style={[styles.bottomBlur, {height: config.scrimBottomHeight}]}
        />
      )}

      <View style={[styles.bar, {bottom: insets.bottom + bar.bottomInsetExtra}]}>
        <GlassTabBarView
          style={styles.barFill}
          expanded={state.expanded}
          activeTab={state.activeTab}
          lastSeq={state.lastSeq}
          collapsed={barCollapsed}
          config={toNativeConfig(config)}
          onTabPress={e => {
            // Plus is an action button, not a tab — it opens the braindump
            // overlay and must not enter the tab reducer.
            if (e.nativeEvent.tab === 'plus') {
              openFlow('braindump');
              return;
            }
            dispatch({type: 'tabPress', tab: e.nativeEvent.tab, seq: e.nativeEvent.seq});
          }}
          onSubTabPress={e => dispatch({type: 'subTabPress', tab: e.nativeEvent.tab, seq: e.nativeEvent.seq})}
          onExpandChange={e =>
            dispatch({type: 'expandChange', expanded: e.nativeEvent.expanded, seq: e.nativeEvent.seq})
          }
        />
      </View>

      {config.edgeBlur && (
        <Animated.View
          pointerEvents="none"
          style={[styles.topBlur, {height: config.toolbarEdgeHeight, opacity: topScrimOpacity}]}>
          {/* Real progressive blur (top only — a backdrop effect under the
              tab bar would poison the pills' glass sampling), the design
              scrim tint above it. Both follow the same master curve. */}
          {config.edgeBlurMax > 0 && (
            <GlassEdgeBlurView
              edge="top"
              maxRadius={config.edgeBlurMax}
              smoothness={config.scrimSmoothness}
              pointerEvents="none"
              style={StyleSheet.absoluteFill}
            />
          )}
          <EdgeScrim
            edge="top"
            dark={dark}
            smoothness={config.scrimSmoothness}
            style={styles.fill}
          />
        </Animated.View>
      )}

      {toolbarShown && (
        <GlassToolbarView
          style={[styles.toolbar, {top: insets.top}]}
          option={config.toolbarOption}
          config={toNativeConfig(config)}
          onToolbarPress={e => handleToolbarPress(e.nativeEvent.element)}
        />
      )}

      {/* The dev panel opens only from the toolbar's settings icon (option 5).
          Invisible long-press escape lives in the status-bar zone ABOVE the
          toolbar (0..insets.top) so it never overlaps the toolbar buttons and
          steals their taps — it's a hidden reach-hatch, not a visible button. */}
      {!panelOpen && (
        <Pressable
          style={[styles.escape, {height: insets.top}]}
          onLongPress={() => setPanelOpen(true)}
          delayLongPress={500}
        />
      )}

      {panelOpen && (
        <DebugPanel
          config={config}
          dark={dark}
          onChange={patchConfig}
          onClose={() => setPanelOpen(false)}
          onFlowAction={openFlow}
        />
      )}

      {/* Stage 49: the RN Reanimated flow (debug toggle) — replaces the native
          overlay for the "+" braindump only; the dev-panel demo modes
          (dumped/switch/reset) always run native. */}
      {flowMode === 'braindump' && config.rnFlow && (
        <BraindumpFlow
          key={`rnflow:${flowSeq}`}
          onboarding={!seenOnboarding}
          onOnboardingComplete={() => setSeenOnboarding(true)}
          autoMorphAfterMs={DEV_FLOW_AUTOPLAY ? 2500 : undefined}
          glassSpawn={config.glassSpawn}
          openPicker={openPicker}
          onOpenPickerChange={setOpenPicker}
          closeSeq={closeSeq}
          shadow={{opacity: config.whiteShadowOpacity, radius: config.whiteShadowRadius}}
          voiceGlow={{radius: config.voiceGlowRadius, opacity: config.voiceGlowOpacity}}
          onClosed={() => {
            setFlowMode('none');
            setOpenPicker('none');
          }}
        />
      )}

      {/* Native braindump overlay (NumoPrototype merge): transparent host over
          the whole app — the slide-up rise reveals the RN screen behind it.
          key forces a fresh mount (fresh flow coordinator) per open. */}
      {flowMode !== 'none' && !(flowMode === 'braindump' && config.rnFlow) && (
        <NumoFlowView
          key={`${flowMode}:${flowSeq}`}
          style={StyleSheet.absoluteFill}
          mode={flowMode}
          seq={flowSeq}
          shadowOpacity={config.whiteShadowOpacity}
          shadowRadius={config.whiteShadowRadius}
          rnBottomBar={flowMode === 'braindump'}
          whenPickerOpen={openPicker === 'when'}
          routinePickerOpen={openPicker === 'routine'}
          onFlowEvent={e => {
            const type = e.nativeEvent.type;
            if (type === 'closed') {
              // Ignore a stale close from the previous instance landing just
              // after a fast reopen — a legit close can't happen this soon
              // after opening (the open animation alone is ~0.5s).
              if (Date.now() - lastOpenAt.current < 500) {
                return;
              }
              setFlowMode('none');
              setOpenPicker('none');
              return;
            }
            // Picker intents from the native header/backdrop close whichever
            // picker is open (Clear also resets it — handled in the cluster).
            if (type === 'clearWhen' || type === 'confirmWhen' || type === 'backdropTap') {
              setOpenPicker('none');
            }
            flowBus.emit(type);
          }}
        />
      )}

      {/* Stage 41: the RN-owned bottom-bar cluster — a sibling AFTER the
          NumoFlow overlay, so it paints above the transparent native canvas
          and receives its own touches. Fresh mount per open (same key).
          Native path only — the RN flow mounts its own cluster (Stage 50). */}
      {flowMode === 'braindump' && !config.rnFlow && (
        <BraindumpBottomBar
          key={`bar:${flowSeq}`}
          openPicker={openPicker}
          onOpenPickerChange={setOpenPicker}
          flowBus={flowBus}
          voiceGlow={{radius: config.voiceGlowRadius, opacity: config.voiceGlowOpacity}}
          glassSpawn={config.glassSpawn}
        />
      )}

      {DEV_AUTOPLAY && (
        <View style={styles.optBadge} pointerEvents="none">
          <Text style={styles.optBadgeTxt}>{config.toolbarOption}</Text>
        </View>
      )}
    </View>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <AppContent />
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: '#FFFFFF'},
  rootDark: {backgroundColor: '#121316'},
  topBlur: {position: 'absolute', top: 0, left: 0, right: 0},
  bottomBlur: {position: 'absolute', bottom: 0, left: 0, right: 0},
  fill: {flex: 1},
  toolbar: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: TOOLBAR_HEIGHT,
  },
  bar: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: bar.stripHeight,
  },
  barFill: {flex: 1},
  escape: {position: 'absolute', top: 0, left: 0, width: 44},
  optBadge: {
    position: 'absolute',
    left: 8,
    bottom: 120,
    width: 30,
    height: 30,
    borderRadius: 8,
    backgroundColor: '#1B1D21',
    alignItems: 'center',
    justifyContent: 'center',
  },
  optBadgeTxt: {color: '#FFF', fontSize: 16, fontWeight: '700'},
});

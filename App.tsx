import React, {useCallback, useEffect, useReducer, useRef, useState} from 'react';
import {Animated, Linking, LogBox, Pressable, StatusBar, StyleSheet, Text, View} from 'react-native';
import {SafeAreaProvider, useSafeAreaInsets} from 'react-native-safe-area-context';

// Prototype: silence the dev warning toast so it doesn't cover the bottom bar.
LogBox.ignoreAllLogs(true);

import {GlassEdgeBlurView, GlassTabBarView, GlassToolbarView, NumoFlowView} from './modules/glass-tab-bar';
import {BraindumpBottomBar} from './src/braindump/BraindumpBottomBar';
import {createFlowBus} from './src/braindump/flowEvents';
import EdgeScrim from './src/components/EdgeScrim';
import DebugPanel from './src/debug/DebugPanel';
import {defaultConfig, toNativeConfig, type AppConfig} from './src/debug/configSchema';
import {loadConfig, saveConfigDebounced} from './src/debug/persist';
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

function AppContent() {
  const insets = useSafeAreaInsets();
  const [state, dispatch] = useReducer(tabReducer, initialTabState);
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [panelOpen, setPanelOpen] = useState(false);
  // The braindump overlay: one immutable mode per mount (key includes seq so
  // every open is a fresh native mount with a fresh flow coordinator).
  const [flowMode, setFlowMode] = useState<FlowMode>('none');
  const [flowSeq, setFlowSeq] = useState(0);
  // Stage 41: RN owns the braindump bottom-bar cluster. `whenOpen` is the
  // picker state (mirrored into the native header via the whenPickerOpen
  // prop); the bus relays native beats (entry/exit, Clear/✓/backdrop).
  const [whenOpen, setWhenOpen] = useState(false);
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

  // Dev hook: drive the bar from outside for scripted testing —
  //   xcrun simctl openurl booted "glassbar://expand" | "glassbar://collapse" |
  //   "glassbar://sub/chat" | "glassbar://toolbar/5"
  // Exercises the RN-controlled-props path (native applies them once lastSeq catches up).
  useEffect(() => {
    const handleUrl = ({url}: {url: string}) => {
      if (url.includes('expand')) {
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
  }, [patchConfig]);

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

  // Opens the native braindump overlay (or one of its demo modes). Each open
  // remounts the component (key below), so the flow always starts fresh.
  const lastOpenAt = useRef(0);
  const openFlow = useCallback((mode: FlowMode) => {
    lastOpenAt.current = Date.now();
    setPanelOpen(false);
    setWhenOpen(false);
    setFlowSeq(prev => prev + 1);
    setFlowMode(mode);
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

      {/* Native braindump overlay (NumoPrototype merge): transparent host over
          the whole app — the slide-up rise reveals the RN screen behind it.
          key forces a fresh mount (fresh flow coordinator) per open. */}
      {flowMode !== 'none' && (
        <NumoFlowView
          key={`${flowMode}:${flowSeq}`}
          style={StyleSheet.absoluteFill}
          mode={flowMode}
          seq={flowSeq}
          shadowOpacity={config.whiteShadowOpacity}
          shadowRadius={config.whiteShadowRadius}
          rnBottomBar={flowMode === 'braindump'}
          whenPickerOpen={whenOpen}
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
              setWhenOpen(false);
              return;
            }
            // Picker intents from the native header/backdrop close the
            // RN-owned picker (Clear also resets it — handled in the cluster).
            if (type === 'clearWhen' || type === 'confirmWhen' || type === 'backdropTap') {
              setWhenOpen(false);
            }
            flowBus.emit(type);
          }}
        />
      )}

      {/* Stage 41: the RN-owned bottom-bar cluster — a sibling AFTER the
          NumoFlow overlay, so it paints above the transparent native canvas
          and receives its own touches. Fresh mount per open (same key). */}
      {flowMode === 'braindump' && (
        <BraindumpBottomBar
          key={`bar:${flowSeq}`}
          whenOpen={whenOpen}
          onWhenOpenChange={setWhenOpen}
          flowBus={flowBus}
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

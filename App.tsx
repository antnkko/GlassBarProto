import {ScrollEdgeEffect, ScrollEdgeEffectProvider} from '@bsky.app/expo-scroll-edge-effect';
import React, {useCallback, useEffect, useReducer, useState} from 'react';
import {Linking, LogBox, Pressable, StatusBar, StyleSheet, Text, View} from 'react-native';
import {SafeAreaProvider, useSafeAreaInsets} from 'react-native-safe-area-context';

// Prototype: silence the dev warning toast so it doesn't cover the bottom bar.
LogBox.ignoreAllLogs(true);

import {GlassTabBarView} from './modules/glass-tab-bar';
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

// Dev-only: cycle the bar states on a timer so the morph can be recorded
// headlessly (no tapping / no openurl confirm dialog). Keep false otherwise.
const DEV_AUTOPLAY = false;

function AppContent() {
  const insets = useSafeAreaInsets();
  const [state, dispatch] = useReducer(tabReducer, initialTabState);
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [panelOpen, setPanelOpen] = useState(false);
  const [barCollapsed, setBarCollapsed] = useState(false);

  // Switching tabs restores the full-size bar.
  useEffect(() => {
    setBarCollapsed(false);
  }, [state.activeTab]);

  // Hydrate persisted config before the first render of the bar,
  // so a stored config doesn't visually snap in after mount.
  useEffect(() => {
    loadConfig().then(setConfig);
  }, []);

  // Dev hook: drive the bar from outside for scripted testing —
  //   xcrun simctl openurl booted "glassbar://expand" | "glassbar://collapse" | "glassbar://sub/chat"
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
      }
    };
    const sub = Linking.addEventListener('url', handleUrl);
    return () => sub.remove();
  }, []);

  useEffect(() => {
    if (!DEV_AUTOPLAY) {
      return;
    }
    const script: Array<() => void> = [
      () => dispatch({type: 'forceExpand'}),
      () => dispatch({type: 'forceSubTab', tab: 'chat'}),
      () => dispatch({type: 'forceSubTab', tab: 'play'}),
      () => dispatch({type: 'forceCollapse'}),
    ];
    let i = 0;
    const id = setInterval(() => {
      script[i % script.length]();
      i += 1;
    }, 1400);
    return () => clearInterval(id);
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

  if (!config) {
    return <View style={styles.root} />;
  }

  const dark = config.appearance === 'dark';

  return (
    <View style={[styles.root, dark && styles.rootDark]}>
      <StatusBar barStyle={dark ? 'light-content' : 'dark-content'} />

      <DemoScreen
        tab={state.activeTab}
        title={SCREEN_TITLES[state.activeTab] ?? state.activeTab}
        dark={dark}
        onCollapseChange={setBarCollapsed}
      />

      <ScrollEdgeEffect
        edge="bottom"
        effect={config.edgeBlur ? 'soft' : 'hidden'}
        style={[styles.bar, {bottom: insets.bottom + bar.bottomInsetExtra}]}>
        <GlassTabBarView
          style={styles.barFill}
          expanded={state.expanded}
          activeTab={state.activeTab}
          lastSeq={state.lastSeq}
          collapsed={barCollapsed}
          config={toNativeConfig(config)}
          onTabPress={e => dispatch({type: 'tabPress', tab: e.nativeEvent.tab, seq: e.nativeEvent.seq})}
          onSubTabPress={e => dispatch({type: 'subTabPress', tab: e.nativeEvent.tab, seq: e.nativeEvent.seq})}
          onExpandChange={e =>
            dispatch({type: 'expandChange', expanded: e.nativeEvent.expanded, seq: e.nativeEvent.seq})
          }
        />
      </ScrollEdgeEffect>

      {/* Top scroll edge: the same native progressive blur pocket that nav
          bars get — appears once content scrolls under the top edge. */}
      <ScrollEdgeEffect
        edge="top"
        effect={config.edgeBlur ? 'soft' : 'hidden'}
        pointerEvents="box-none"
        style={[styles.topEdge, {height: insets.top + 56}]}>
        {/* The gear is the real overlay element the top blur pocket shapes
            around — a full-width invisible shaper produced a ghost container
            instead. The diffuse under-status-bar blur comes from the scroll
            view's own soft top edge effect (automatic content insets). */}
        {!panelOpen && (
          <Pressable
            style={[styles.gear, dark && styles.gearDark, {top: insets.top + 8}]}
            onPress={() => setPanelOpen(true)}
            hitSlop={8}>
            <Text style={[styles.gearTxt, dark && styles.gearTxtDark]}>⚙︎</Text>
          </Pressable>
        )}
      </ScrollEdgeEffect>

      {panelOpen && (
        <DebugPanel config={config} dark={dark} onChange={patchConfig} onClose={() => setPanelOpen(false)} />
      )}
    </View>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <ScrollEdgeEffectProvider>
        <AppContent />
      </ScrollEdgeEffectProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: '#FFFFFF'},
  rootDark: {backgroundColor: '#121316'},
  topEdge: {position: 'absolute', top: 0, left: 0, right: 0},
  bar: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: bar.stripHeight,
  },
  barFill: {flex: 1},
  gear: {
    position: 'absolute',
    right: 20,
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(27,29,33,0.85)',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOpacity: 0.2,
    shadowRadius: 8,
    shadowOffset: {width: 0, height: 2},
  },
  gearTxt: {color: '#FFF', fontSize: 20},
  gearDark: {backgroundColor: 'rgba(245,245,247,0.9)'},
  gearTxtDark: {color: '#1B1D21'},
});

/**
 * Stage 49 — RN flow state: the AppFlowCoordinator equivalents + the
 * onboarding-seen flag. Mirrors `ios/Numo/Flow/AppFlowCoordinator.swift`:
 *   AppStage  { current, onboarding, redesigned }
 *   MorphPhase{ idle, stretching, released }
 * The native side persists via UserDefaults "numo.hasSeenOnboarding"; the RN
 * flow keeps its own AsyncStorage flag (the debug "Reset onboarding" clears
 * both — see DebugPanel/App wiring).
 */
import AsyncStorage from '@react-native-async-storage/async-storage';

/** Which screen the braindump flow shows (native `AppStage`). */
export type FlowStage = 'current' | 'onboarding' | 'redesigned';

/** The three-act morph's coarse phase (native `MorphPhase`). */
export type MorphPhase = 'idle' | 'stretching' | 'released';

const SEEN_KEY = 'numo.hasSeenOnboarding';

export async function hasSeenOnboarding(): Promise<boolean> {
  try {
    return (await AsyncStorage.getItem(SEEN_KEY)) === '1';
  } catch {
    return false;
  }
}

export function setSeenOnboarding() {
  AsyncStorage.setItem(SEEN_KEY, '1').catch(() => {});
}

export function resetOnboarding() {
  AsyncStorage.removeItem(SEEN_KEY).catch(() => {});
}

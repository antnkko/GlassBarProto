import AsyncStorage from '@react-native-async-storage/async-storage';

import {defaultConfig, type AppConfig} from './configSchema';

const STORAGE_KEY = 'glass-bar-config.v9';

export async function loadConfig(): Promise<AppConfig> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) {
      return defaultConfig;
    }
    // Merge over defaults so newly added fields keep their default values.
    return {...defaultConfig, ...JSON.parse(raw)};
  } catch {
    return defaultConfig;
  }
}

let timer: ReturnType<typeof setTimeout> | null = null;

export function saveConfigDebounced(config: AppConfig, delayMs = 400) {
  if (timer) {
    clearTimeout(timer);
  }
  timer = setTimeout(() => {
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(config)).catch(() => {});
  }, delayMs);
}

export async function clearConfig() {
  await AsyncStorage.removeItem(STORAGE_KEY).catch(() => {});
}

import type {ActiveTab} from '../../modules/glass-tab-bar';

export interface TabState {
  expanded: boolean;
  activeTab: ActiveTab;
  /** Echo of the last native seq we processed; the native side ignores our controlled props until it catches up. */
  lastSeq: number;
}

export const initialTabState: TabState = {
  expanded: false,
  activeTab: 'home',
  lastSeq: 0,
};

export type TabAction =
  | {type: 'tabPress'; tab: string; seq: number}
  | {type: 'subTabPress'; tab: ActiveTab; seq: number}
  | {type: 'expandChange'; expanded: boolean; seq: number}
  | {type: 'forceCollapse'}
  | {type: 'forceExpand'}
  | {type: 'forceSubTab'; tab: ActiveTab};

export function tabReducer(state: TabState, action: TabAction): TabState {
  switch (action.type) {
    case 'tabPress': {
      if (action.tab === 'plus') {
        // The plus button fires an event but doesn't change tab state.
        return {...state, lastSeq: action.seq};
      }
      return {
        ...state,
        activeTab: action.tab === 'home' ? 'home' : 'squad',
        expanded: action.tab !== 'home',
        lastSeq: action.seq,
      };
    }
    case 'subTabPress':
      return {...state, activeTab: action.tab, expanded: true, lastSeq: action.seq};
    case 'expandChange':
      return {...state, expanded: action.expanded, lastSeq: action.seq};
    case 'forceCollapse':
      // Imperative RN-driven changes (debug panel / dev deep links): native applies
      // them because lastSeq has caught up with its local seq by then.
      return {...state, expanded: false, activeTab: 'home'};
    case 'forceExpand':
      return {...state, expanded: true, activeTab: 'squad'};
    case 'forceSubTab':
      return {...state, expanded: true, activeTab: action.tab};
    default:
      return state;
  }
}

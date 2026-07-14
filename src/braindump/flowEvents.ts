/**
 * Stage 41 — a tiny event bus carrying NumoFlow's native beats (entry/exit,
 * picker intents) from App's onFlowEvent handler into the RN bottom-bar
 * cluster without prop-identity churn.
 */
type Listener = (type: string) => void;

export type FlowBus = {
  emit: (type: string) => void;
  on: (l: Listener) => () => void;
};

export function createFlowBus(): FlowBus {
  const listeners = new Set<Listener>();
  return {
    emit: type => listeners.forEach(l => l(type)),
    on: l => {
      listeners.add(l);
      return () => {
        listeners.delete(l);
      };
    },
  };
}

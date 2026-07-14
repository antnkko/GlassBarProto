/**
 * Stage 41 — SwiftUI → Reanimated motion mapping (MorphChoreo.PickerMorph +
 * GlassButton feedback). Conversion for `.spring(response, dampingFraction)`
 * with mass 1: stiffness = (2π/response)², damping = df · 2·√stiffness.
 * `.spring(duration, bounce)` maps to Reanimated's duration-based spring:
 * dampingRatio ≈ 1 − bounce.
 */
import {Easing} from 'react-native-reanimated';
import type {WithSpringConfig, WithTimingConfig} from 'react-native-reanimated';

/** PickerMorph.openSpring — .spring(response 0.40, dampingFraction 0.82). */
export const openSpring: WithSpringConfig = {mass: 1, stiffness: 246.74, damping: 25.76};

/** PickerMorph.closeSpring — .spring(response 0.40, dampingFraction 0.90). */
export const closeSpring: WithSpringConfig = {mass: 1, stiffness: 246.74, damping: 28.27};

/** PickerMorph.sectionResize — .smooth(duration 0.3) (critically damped). */
export const sectionResize: WithSpringConfig = {mass: 1, stiffness: 438.65, damping: 41.89};

/** PressFadeStyle — .spring(response 0.3, dampingFraction 0.66). */
export const pressSpring: WithSpringConfig = {mass: 1, stiffness: 438.65, damping: 27.65};

/** MorphChoreo.bottomBarSpring — .spring(duration 0.55, bounce 0.22). */
export const entrySpring: WithSpringConfig = {duration: 550, dampingRatio: 0.78};

/** PickerMorph.chromeFadeOut / contentFadeOut — easeOut 0.12. */
export const fadeOut120: WithTimingConfig = {duration: 120, easing: Easing.out(Easing.quad)};

/** PickerMorph.sectionDisappear — easeOut 0.16. */
export const fadeOut160: WithTimingConfig = {duration: 160, easing: Easing.out(Easing.quad)};

/** GlassButton decor hide — easeInOut 0.12. */
export const decorHide: WithTimingConfig = {duration: 120, easing: Easing.inOut(Easing.ease)};

/** GlassButton decor return — easeInOut 0.25 (fired 180ms after release). */
export const decorReturn: WithTimingConfig = {duration: 250, easing: Easing.inOut(Easing.ease)};
export const decorReturnDelay = 180;

/** Glass ring show — easeOut 0.4, delay 0.1, scale 0.94→1. */
export const ringShow: WithTimingConfig = {duration: 400, easing: Easing.out(Easing.quad)};
export const ringShowDelay = 100;
export const ringShowScaleFrom = 0.94;

/** Picker content grows from this bottom-anchored scale. */
export const contentScaleFrom = 0.96;

/** UIKit keyboard curve approximation. */
export const keyboardEasing = Easing.bezier(0.17, 0.59, 0.4, 0.77);

/**
 * The DumpedScreen title's `.contentTransition(.numericText())` spring —
 * .spring(response 0.4, dampingFraction 0.6) (DumpedEntrance.titleResponse/
 * titleDamping). Bouncy: chars roll in with a visible overshoot.
 */
export const numericSpring: WithSpringConfig = {mass: 1, stiffness: 246.74, damping: 18.85};

/**
 * Stage 41 — the week strip (WeekStrip/WeekStripDay.swift): one Sun–Sat week
 * containing today, 7 flex cells (uppercase 2-letter weekday over the day
 * number). The selected-day tile (fill + border + inner white glow) is shared
 * across every date component via SelectedDayTile. Empty selection ⇒ today
 * reads as selected (fallback). The today dot shows ONLY once the user has
 * moved the selection off today.
 */
import React, {useMemo} from 'react';
import {StyleSheet, Text, View, ViewStyle} from 'react-native';

import {PressFade} from './PressFade';
import {color, font, rgba, routine, strip} from './tokens';

const WEEKDAY_2 = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];

export function sameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function currentWeek(): Date[] {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const start = new Date(today);
  start.setDate(today.getDate() - today.getDay()); // back to Sunday
  return Array.from({length: 7}, (_, i) => {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    return d;
  });
}

/**
 * The ONE selected-day treatment (Figma routine tile, user-approved for every
 * picker): vibrantLight@0.15 fill, 2px vibrantLight@0.25 border and the inset
 * white glow. Position/size via `style` (absolute within the cell).
 */
export function SelectedDayTile({radius, style}: {radius: number; style: ViewStyle}) {
  return (
    <View
      style={[
        {
          position: 'absolute',
          borderRadius: radius,
          borderCurve: 'continuous',
          borderWidth: routine.tileBorder,
          borderColor: rgba(color.vibrantLight, routine.tileBorderOpacity),
          backgroundColor: rgba(color.vibrantLight, strip.pillBgOpacity),
        },
        style,
      ]}>
      {/* Static stand-in for the Figma inset white glow. */}
      <View
        style={[
          StyleSheet.absoluteFill,
          {
            borderRadius: radius - routine.tileBorder,
            borderCurve: 'continuous',
                        borderWidth: 2,
            borderColor: 'rgba(255,255,255,0.5)',
          },
        ]}
      />
    </View>
  );
}

type Props = {
  /** 'when' variant: single selection. */
  selectedDay?: Date | null;
  onSelect?: (day: Date) => void;
  /** 'routine' variant: checklist — several (or all) days can be selected. */
  selectedDays?: Date[];
  onToggle?: (day: Date) => void;
  /**
   * 'routine' — the Routine picker's strip (Figma 1122:10624): px12/py14 row,
   * fixed 48×64 selected tile, today dot at −2, multi-select. Default 'when'
   * keeps the When picker single-select.
   */
  variant?: 'when' | 'routine';
};

export function WeekStrip({selectedDay, onSelect, selectedDays, onToggle, variant = 'when'}: Props) {
  const days = useMemo(currentWeek, []);
  const today = new Date();
  const isRoutine = variant === 'routine';

  const isDaySelected = (day: Date): boolean => {
    if (isRoutine) {
      const set = selectedDays ?? [];
      return set.length ? set.some(d => sameDay(d, day)) : sameDay(day, today);
    }
    return selectedDay ? sameDay(day, selectedDay) : sameDay(day, today);
  };
  // The dot marks today ONLY once the selection has moved off it — with the
  // empty-selection fallback today reads as selected, so no dot.
  const todayIsSelected = isDaySelected(today);

  return (
    <View
      style={
        isRoutine
          ? {
              flexDirection: 'row',
              paddingHorizontal: routine.stripPadH,
              paddingVertical: routine.stripPadV,
            }
          : {flexDirection: 'row', padding: strip.pad}
      }>
      {days.map((day, i) => {
        const isToday = sameDay(day, today);
        const isSelected = isDaySelected(day);
        return (
          <PressFade
            key={i}
            onPress={() => (isRoutine ? onToggle?.(day) : onSelect?.(day))}
            style={{flex: 1}}>
            <View style={{height: strip.cellHeight, alignItems: 'center', justifyContent: 'center'}}>
              {isSelected &&
                (isRoutine ? (
                  <SelectedDayTile
                    radius={routine.tileRadius}
                    style={{
                      top: 0,
                      width: routine.tileW,
                      height: routine.tileH,
                      alignSelf: 'center',
                    }}
                  />
                ) : (
                  <SelectedDayTile
                    radius={strip.pillRadius}
                    style={{
                      top: 0,
                      bottom: 0,
                      width: '100%',
                      maxWidth: strip.pillMaxWidth,
                      alignSelf: 'center',
                    }}
                  />
                ))}
              <Text
                style={{
                  fontFamily: font.semibold,
                  fontSize: strip.weekdaySize,
                  letterSpacing: strip.weekdayTracking,
                  color: isSelected ? color.vibrantLight : color.grayNight,
                  opacity: isSelected ? 1 : strip.weekdayOpacity,
                }}>
                {WEEKDAY_2[day.getDay()]}
              </Text>
              <Text
                style={{
                  fontFamily: font.semibold,
                  fontSize: strip.daySize,
                  color: isSelected ? color.vibrant : color.neutralDark,
                }}>
                {day.getDate()}
              </Text>
              {isToday && !todayIsSelected && (
                <View
                  style={{
                    position: 'absolute',
                    bottom: isRoutine ? -routine.dotOffset : -strip.todayDotOffset,
                    width: strip.todayDot,
                    height: strip.todayDot,
                    borderRadius: strip.todayDot / 2,
                    backgroundColor: color.vibrant,
                  }}
                />
              )}
            </View>
          </PressFade>
        );
      })}
    </View>
  );
}

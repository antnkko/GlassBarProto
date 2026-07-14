/**
 * Stage 41 — the week strip (WeekStrip/WeekStripDay.swift): one Sun–Sat week
 * containing today, 7 flex cells (uppercase 2-letter weekday over the day
 * number), selection pill ≤48pt r14 vibrantLight@0.15, today dot below.
 * `selectedDay: null` ⇒ today highlighted.
 */
import React, {useMemo} from 'react';
import {Text, View} from 'react-native';

import {PressFade} from './PressFade';
import {color, font, strip} from './tokens';

const WEEKDAY_2 = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];

function sameDay(a: Date, b: Date): boolean {
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

type Props = {
  selectedDay: Date | null;
  onSelect: (day: Date) => void;
};

export function WeekStrip({selectedDay, onSelect}: Props) {
  const days = useMemo(currentWeek, []);
  const today = new Date();

  return (
    <View style={{flexDirection: 'row', padding: strip.pad}}>
      {days.map((day, i) => {
        const isToday = sameDay(day, today);
        const isSelected = selectedDay ? sameDay(day, selectedDay) : isToday;
        return (
          <PressFade key={i} onPress={() => onSelect(day)} style={{flex: 1}}>
            <View style={{height: strip.cellHeight, alignItems: 'center', justifyContent: 'center'}}>
              {isSelected && (
                <View
                  style={{
                    position: 'absolute',
                    top: 0,
                    bottom: 0,
                    width: '100%',
                    maxWidth: strip.pillMaxWidth,
                    alignSelf: 'center',
                    borderRadius: strip.pillRadius,
                    borderCurve: 'continuous',
                    backgroundColor: color.vibrantLight,
                    opacity: strip.pillBgOpacity,
                  }}
                />
              )}
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
              {isToday && (
                <View
                  style={{
                    position: 'absolute',
                    bottom: -strip.todayDotOffset,
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

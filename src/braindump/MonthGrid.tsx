/**
 * The Routine picker's Monthly calendar (Figma 1122:10865): a 7-column grid
 * of the current month inside a fixed-height viewport. The Figma card is a
 * fixed 360pt with the grid as a fading scrollable strip (the "Calendar
 * scrolled" artboard is this same grid mid-scroll) — so the grid scrolls
 * vertically and the alpha fade mask is approximated with white edge
 * gradients over the card's white ground. Leading/trailing empty slots are
 * invisible cells so justify-space-between keeps the 7-column geometry exact.
 */
import React, {useMemo} from 'react';
import {ScrollView, Text, View} from 'react-native';
import {LinearGradient} from 'expo-linear-gradient';

import {PressFade} from './PressFade';
import {SelectedDayTile, sameDay} from './WeekStrip';
import {color, font, routine} from './tokens';

const ROW_H = routine.gridCell + routine.gridRowGap;
/** Edge fade depth of the scroll viewport (mask approximation). */
const FADE_H = 16;

/** The current month as Sunday-aligned rows of `Date | null` (null = slot). */
function monthWeeks(): (Date | null)[][] {
  const today = new Date();
  const first = new Date(today.getFullYear(), today.getMonth(), 1);
  const daysInMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
  const cells: (Date | null)[] = Array.from({length: first.getDay()}, () => null);
  for (let d = 1; d <= daysInMonth; d++) {
    cells.push(new Date(today.getFullYear(), today.getMonth(), d));
  }
  while (cells.length % 7 !== 0) cells.push(null);
  return Array.from({length: cells.length / 7}, (_, w) => cells.slice(w * 7, w * 7 + 7));
}

type Props = {
  selectedDay: Date | null;
  onSelect: (day: Date) => void;
  /** Viewport height (the card is fixed-height; the grid scrolls inside). */
  height: number;
};

export function MonthGrid({selectedDay, onSelect, height}: Props) {
  const weeks = useMemo(monthWeeks, []);
  const today = new Date();
  // Dot rule (shared with the strips): today carries the dot only once the
  // selection has moved off it; empty selection ⇒ today reads as selected.
  const todayIsSelected = selectedDay ? sameDay(today, selectedDay) : true;

  // Start with the selected row vertically centered in the viewport.
  const selected = selectedDay ?? today;
  const selectedRow = weeks.findIndex(w => w.some(d => d && sameDay(d, selected)));
  const initialY = Math.max(
    0,
    Math.min(
      routine.gridPadV + selectedRow * ROW_H - (height - routine.gridCell) / 2,
      routine.gridPadV * 2 + weeks.length * ROW_H - routine.gridRowGap - height,
    ),
  );

  return (
    <View style={{height}}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentOffset={{x: 0, y: initialY}}
        contentContainerStyle={{
          paddingVertical: routine.gridPadV,
          gap: routine.gridRowGap,
        }}>
        {weeks.map((week, w) => (
          <View
            key={w}
            style={{
              flexDirection: 'row',
              justifyContent: 'space-between',
              paddingHorizontal: routine.gridRowPadH,
            }}>
            {week.map((day, i) => {
              if (!day) {
                return <View key={i} style={{width: routine.gridCell, height: routine.gridCell}} />;
              }
              const isToday = sameDay(day, today);
              const isSelected = selectedDay ? sameDay(day, selectedDay) : isToday;
              return (
                <PressFade key={i} onPress={() => onSelect(day)}>
                  <View
                    style={{
                      width: routine.gridCell,
                      height: routine.gridCell,
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}>
                    {isSelected && (
                      <SelectedDayTile
                        radius={routine.gridCellRadius}
                        style={{top: 0, left: 0, right: 0, bottom: 0}}
                      />
                    )}
                    <Text
                      style={{
                        fontFamily: isSelected ? font.semibold : font.medium,
                        fontSize: routine.gridDaySize,
                        letterSpacing: routine.gridDayTracking,
                        paddingBottom: routine.gridDayPadBottom,
                        color: isSelected ? color.vibrant : color.ink,
                      }}>
                      {day.getDate()}
                    </Text>
                    {isToday && !todayIsSelected && (
                      <View
                        style={{
                          position: 'absolute',
                          bottom: routine.dotOffset,
                          width: routine.dotSize,
                          height: routine.dotSize,
                          borderRadius: routine.dotSize / 2,
                          backgroundColor: color.vibrant,
                        }}
                      />
                    )}
                  </View>
                </PressFade>
              );
            })}
          </View>
        ))}
      </ScrollView>
      {/* Edge fades — the Figma alpha mask over the card's white ground. */}
      <LinearGradient
        pointerEvents="none"
        colors={[color.white, 'rgba(255,255,255,0)']}
        style={{position: 'absolute', top: 0, left: 0, right: 0, height: FADE_H}}
      />
      <LinearGradient
        pointerEvents="none"
        colors={['rgba(255,255,255,0)', color.white]}
        style={{position: 'absolute', bottom: 0, left: 0, right: 0, height: FADE_H}}
      />
    </View>
  );
}

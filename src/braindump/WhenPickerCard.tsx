/**
 * Stage 41 — the "When" picker card (WhenPicker.swift): an accordion of a
 * Date row (expands the week strip) and a Time row (expands the wheel). One
 * section open at a time; the swap glides on the native sectionResize spring.
 *
 * The native version slides an opaque white cover over the days; here the
 * same read comes from height-collapsing containers (overflow hidden): the
 * closing block clips its static content while the opening one reveals it —
 * both driven by ONE `sectionP` progress so they move together. Disappearing
 * content fades fast (sectionDisappear 160ms), like the native wheel.
 * Block heights are deterministic: dateBlock = sep2 + strip(12+64+12) = 90,
 * timeBlock = sep2 + wheel(6+190+6) = 204.
 */
import React from 'react';
import {Image, Pressable, Text, View} from 'react-native';
import Animated, {SharedValue, useAnimatedStyle} from 'react-native-reanimated';

import {WeekStrip} from './WeekStrip';
import {WheelTimePicker, WheelTime, formatWheelTime} from './WheelTimePicker';
import {color, font, row, strip, wheel, wheelHeight} from './tokens';

export type WhenSection = 'date' | 'time';

export const DATE_BLOCK_H = row.sepThickness + strip.pad * 2 + strip.cellHeight; // 90
export const TIME_BLOCK_H = row.sepThickness + wheel.padV * 2 + wheelHeight; // 204

function Separator() {
  return (
    <View
      style={{
        height: row.sepThickness,
        marginLeft: row.leading,
        backgroundColor: color.grayAlmost,
        opacity: row.sepOpacity,
      }}
    />
  );
}

function PickerRow({
  icon,
  label,
  value,
  expanded,
  onPress,
}: {
  icon: string;
  label: string;
  value: string;
  expanded: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress}>
      <View
        style={{
          flexDirection: 'row',
          alignItems: 'center',
          gap: row.gap,
          paddingLeft: row.leading,
          paddingRight: row.trailing,
          paddingVertical: row.padV,
        }}>
        <Image
          source={{uri: icon}}
          style={{width: row.icon, height: row.icon, tintColor: color.grayNormal}}
          resizeMode="contain"
        />
        <View style={{flex: 1}}>
          <Text style={{fontFamily: font.medium, fontSize: row.labelSize, color: color.grayNight}}>
            {label}
          </Text>
          <Text
            style={{
              marginTop: row.textGap,
              fontFamily: font.semibold,
              fontSize: row.valueSize,
              color: color.neutralDark,
            }}>
            {value}
          </Text>
        </View>
        <Image
          source={{uri: 'picker_chevron'}}
          style={{
            width: row.chevron,
            height: row.chevron,
            tintColor: color.grayNormal,
            opacity: expanded ? 0 : 1,
          }}
          resizeMode="contain"
        />
      </View>
    </Pressable>
  );
}

function dayValueText(selectedDay: Date | null): string {
  if (!selectedDay) return 'Today';
  const today = new Date();
  if (
    selectedDay.getFullYear() === today.getFullYear() &&
    selectedDay.getMonth() === today.getMonth() &&
    selectedDay.getDate() === today.getDate()
  ) {
    return 'Today';
  }
  const wd = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][selectedDay.getDay()];
  return `${wd} ${selectedDay.getDate()}`;
}

type Props = {
  section: WhenSection;
  /** 0 = time open, 1 = date open — animated on sectionResize by the parent. */
  sectionP: SharedValue<number>;
  selectedDay: Date | null;
  time: WheelTime;
  /** Wheel remount key: bump when the time is reset (Clear) to re-center. */
  wheelKey: number;
  onSectionChange: (s: WhenSection) => void;
  onSelectDay: (d: Date) => void;
  onTimeChange: (t: Partial<WheelTime>) => void;
};

export function WhenPickerCard({
  section,
  sectionP,
  selectedDay,
  time,
  wheelKey,
  onSectionChange,
  onSelectDay,
  onTimeChange,
}: Props) {
  // Height-collapse + quick fade of the block being covered/revealed.
  const dateBlockStyle = useAnimatedStyle(() => ({
    height: sectionP.value * DATE_BLOCK_H,
    opacity: Math.min(1, sectionP.value * 2),
  }));
  const timeBlockStyle = useAnimatedStyle(() => ({
    height: (1 - sectionP.value) * TIME_BLOCK_H,
    opacity: Math.min(1, (1 - sectionP.value) * 2),
  }));

  return (
    <View>
      <PickerRow
        icon="picker_calendar"
        label="Date"
        value={dayValueText(selectedDay)}
        expanded={section === 'date'}
        onPress={() => onSectionChange('date')}
      />
      <Animated.View style={[{overflow: 'hidden'}, dateBlockStyle]}>
        <View style={{height: DATE_BLOCK_H}}>
          <Separator />
          <WeekStrip selectedDay={selectedDay} onSelect={onSelectDay} />
        </View>
      </Animated.View>
      <Separator />
      <PickerRow
        icon="picker_clock"
        label="Time"
        value={formatWheelTime(time)}
        expanded={section === 'time'}
        onPress={() => onSectionChange('time')}
      />
      <Animated.View style={[{overflow: 'hidden'}, timeBlockStyle]}>
        <View style={{height: TIME_BLOCK_H}}>
          <Separator />
          <View style={{paddingVertical: wheel.padV}}>
            <WheelTimePicker key={wheelKey} initial={time} onChange={onTimeChange} />
          </View>
        </View>
      </Animated.View>
    </View>
  );
}

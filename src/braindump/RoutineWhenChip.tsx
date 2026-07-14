/**
 * Stage 41 — the closed-state chip content (RoutineTimeCard.swift): two equal
 * Routine | When zones (icon over label) split by a 2×32 capsule divider.
 * Icons come from the app's xcassets (template SVG imagesets) via UIImage
 * name resolution; tinted grayNight like the native card.
 */
import React from 'react';
import {Image, Text, View} from 'react-native';

import {PressFade} from './PressFade';
import {chip, color, font} from './tokens';

type Props = {
  onRoutineTap?: () => void;
  onWhenTap?: () => void;
};

function Zone({icon, label, onPress}: {icon: string; label: string; onPress?: () => void}) {
  return (
    <PressFade onPress={onPress} style={{flex: 1}}>
      <View style={{flex: 1, alignItems: 'center', justifyContent: 'center'}}>
        <Image
          source={{uri: icon}}
          style={{width: chip.icon, height: chip.icon, tintColor: color.grayNight}}
          resizeMode="contain"
        />
        <Text
          style={{
            marginTop: chip.iconLabelGap,
            fontFamily: font.medium,
            fontSize: chip.labelSize,
            color: color.ink,
          }}>
          {label}
        </Text>
      </View>
    </PressFade>
  );
}

export function RoutineWhenChip({onRoutineTap, onWhenTap}: Props) {
  return (
    <View style={{flex: 1, flexDirection: 'row', alignItems: 'center'}}>
      <Zone icon="repeat_icon" label="Routine" onPress={onRoutineTap} />
      <View
        style={{
          width: chip.dividerWidth,
          height: chip.dividerHeight,
          borderRadius: chip.dividerWidth / 2,
          backgroundColor: color.grayAlmost,
        }}
      />
      <Zone icon="clock_icon" label="When" onPress={onWhenTap} />
    </View>
  );
}

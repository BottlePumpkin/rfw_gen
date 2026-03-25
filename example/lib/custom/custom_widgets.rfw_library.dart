// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_gen_example/custom/custom_widget_classes.dart';

/// Auto-generated [LocalWidgetBuilder] map.
Map<String, LocalWidgetBuilder> get generatedLocalWidgetBuilders =>
    <String, LocalWidgetBuilder>{
  'CustomText': (BuildContext context, DataSource source) {
    return CustomText(
      text: source.v<String>(['text']) ?? '',
      fontType: source.v<String>(['fontType']) ?? 'body',
      color: source.v<int>(['color']) ?? 0xFF000000,
      maxLines: source.v<int>(['maxLines']),
    );
  },
  'CustomBounceTapper': (BuildContext context, DataSource source) {
    return CustomBounceTapper(
      onTap: source.voidHandler(['onTap']),
      child: source.optionalChild(['child']),
    );
  },
  'NullConditionalWidget': (BuildContext context, DataSource source) {
    return NullConditionalWidget(
      child: source.optionalChild(['child']),
      nullChild: source.optionalChild(['nullChild']),
    );
  },
  'CustomButton': (BuildContext context, DataSource source) {
    return CustomButton(
      child: source.child(['child']),
      onPressed: source.voidHandler(['onPressed']),
      onLongPress: source.voidHandler(['onLongPress']),
    );
  },
  'CustomBadge': (BuildContext context, DataSource source) {
    return CustomBadge(
      label: source.v<String>(['label']) ?? '',
      count: source.v<int>(['count']) ?? 0,
      backgroundColor: source.v<int>(['backgroundColor']) ?? 0xFF9E9E9E,
    );
  },
  'CustomProgressBar': (BuildContext context, DataSource source) {
    return CustomProgressBar(
      value: source.v<double>(['value']) ?? 0.0,
      color: source.v<int>(['color']) ?? 0xFF2196F3,
      shape: source.v<String>(['shape']) ?? 'rounded',
      height: source.v<double>(['height']) ?? 4.0,
    );
  },
  'CustomColumn': (BuildContext context, DataSource source) {
    final children = <Widget>[];
    for (var i = 0; i < source.length(['children']); i++) {
      children.add(source.child(['children', i]));
    }
    return CustomColumn(
      spacing: source.v<double>(['spacing']) ?? 0.0,
      dividerColor: source.v<int>(['dividerColor']) ?? 0x00000000,
      children: children,
    );
  },
  'SkeletonContainer': (BuildContext context, DataSource source) {
    return SkeletonContainer(
      isLoading: source.v<bool>(['isLoading']) ?? false,
      child: source.optionalChild(['child']),
    );
  },
  'CompareWidget': (BuildContext context, DataSource source) {
    return CompareWidget(
      child: source.optionalChild(['child']),
      trueChild: source.optionalChild(['trueChild']),
      falseChild: source.optionalChild(['falseChild']),
    );
  },
  'PvContainer': (BuildContext context, DataSource source) {
    return PvContainer(
      onPv: source.voidHandler(['onPv']),
      child: source.optionalChild(['child']),
    );
  },
  'CustomCard': (BuildContext context, DataSource source) {
    return CustomCard(
      child: source.child(['child']),
      elevation: source.v<double>(['elevation']) ?? 1.0,
      borderRadius: source.v<double>(['borderRadius']) ?? 8.0,
      onTap: source.voidHandler(['onTap']),
    );
  },
  'CustomTile': (BuildContext context, DataSource source) {
    return CustomTile(
      leading: source.optionalChild(['leading']),
      title: source.optionalChild(['title']),
      subtitle: source.optionalChild(['subtitle']),
      trailing: source.optionalChild(['trailing']),
      onTap: source.voidHandler(['onTap']),
    );
  },
  'CustomAppBar': (BuildContext context, DataSource source) {
    final actions = <Widget>[];
    for (var i = 0; i < source.length(['actions']); i++) {
      actions.add(source.child(['actions', i]));
    }
    return CustomAppBar(
      title: source.optionalChild(['title']),
      actions: actions,
    );
  },
};

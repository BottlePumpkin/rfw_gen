import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';

/// Custom widget library name used in rfwtxt imports.
const customWidgetsLibraryName = LibraryName(<String>['custom', 'widgets']);

/// All custom widget [LocalWidgetBuilder]s for the example app.
///
/// Shared between the app runtime ([main.dart]) and test helpers
/// ([golden_test_helper.dart]) to avoid duplication.
final Map<String, LocalWidgetBuilder> customWidgetBuilders =
    <String, LocalWidgetBuilder>{
  'CustomText': (BuildContext context, DataSource source) {
    final text = source.v<String>(['text']) ?? '';
    final fontType = source.v<String>(['fontType']) ?? 'body';
    final color = Color(source.v<int>(['color']) ?? 0xFF000000);
    final maxLines = source.v<int>(['maxLines']);
    final style = switch (fontType) {
      'heading' => TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: color),
      'button' => TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: color),
      'caption' => TextStyle(fontSize: 12, color: color),
      _ => TextStyle(fontSize: 14, color: color),
    };
    return Text(text, style: style, maxLines: maxLines);
  },
  'CustomBounceTapper': (BuildContext context, DataSource source) {
    return GestureDetector(
      onTap: source.voidHandler(['onTap']),
      child: source.optionalChild(['child']),
    );
  },
  'NullConditionalWidget': (BuildContext context, DataSource source) {
    final child = source.optionalChild(['child']);
    final nullChild = source.optionalChild(['nullChild']);
    return child ?? nullChild ?? const SizedBox.shrink();
  },
  'CustomButton': (BuildContext context, DataSource source) {
    return ElevatedButton(
      onPressed: source.voidHandler(['onPressed']),
      onLongPress: source.voidHandler(['onLongPress']),
      child: source.child(['child']),
    );
  },
  'CustomBadge': (BuildContext context, DataSource source) {
    final label = source.v<String>(['label']) ?? '';
    final count = source.v<int>(['count']) ?? 0;
    final bg = Color(source.v<int>(['backgroundColor']) ?? 0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text('$label${count > 0 ? ' ($count)' : ''}',
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  },
  'CustomProgressBar': (BuildContext context, DataSource source) {
    final value = source.v<double>(['value']) ?? 0.0;
    final color = Color(source.v<int>(['color']) ?? 0xFF2196F3);
    final shape = source.v<String>(['shape']) ?? 'rounded';
    final height = source.v<double>(['height']) ?? 4.0;
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(shape == 'rounded' ? height / 2 : 0),
      child: LinearProgressIndicator(
          value: value, color: color, minHeight: height),
    );
  },
  'CustomColumn': (BuildContext context, DataSource source) {
    final spacing = source.v<double>(['spacing']) ?? 0.0;
    final dividerColor =
        Color(source.v<int>(['dividerColor']) ?? 0x00000000);
    final children = <Widget>[];
    for (var i = 0; i < source.length(['children']); i++) {
      if (i > 0) {
        if (spacing > 0) children.add(SizedBox(height: spacing));
        if (dividerColor.a > 0) {
          children.add(Divider(color: dividerColor, height: 1));
        }
      }
      children.add(source.child(['children', i]));
    }
    return Column(children: children);
  },
  'SkeletonContainer': (BuildContext context, DataSource source) {
    final isLoading = source.v<bool>(['isLoading']) ?? false;
    final child = source.optionalChild(['child']);
    if (isLoading) {
      return Container(
        height: 48,
        color: Colors.grey[300],
        child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return child ?? const SizedBox.shrink();
  },
  'CompareWidget': (BuildContext context, DataSource source) {
    final child = source.optionalChild(['child']);
    final trueChild = source.optionalChild(['trueChild']);
    final falseChild = source.optionalChild(['falseChild']);
    return Column(children: [
      if (child != null) child,
      if (trueChild != null) trueChild,
      if (falseChild != null) falseChild,
    ]);
  },
  'PvContainer': (BuildContext context, DataSource source) {
    final onPv = source.voidHandler(['onPv']);
    WidgetsBinding.instance.addPostFrameCallback((_) => onPv?.call());
    return source.optionalChild(['child']) ?? const SizedBox.shrink();
  },
  'CustomCard': (BuildContext context, DataSource source) {
    final elevation = source.v<double>(['elevation']) ?? 1.0;
    final borderRadius = source.v<double>(['borderRadius']) ?? 8.0;
    return GestureDetector(
      onTap: source.voidHandler(['onTap']),
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: source.child(['child']),
      ),
    );
  },
  'CustomTile': (BuildContext context, DataSource source) {
    return ListTile(
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
    return AppBar(
      title: source.optionalChild(['title']),
      actions: actions.isEmpty ? null : actions,
      backgroundColor: const Color(0xFF2196F3),
    );
  },
};

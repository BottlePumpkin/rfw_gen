// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_gen_playground/widgets/code_block.dart' show CodeBlock;
import 'package:rfw_gen_playground/widgets/doc_table.dart' show DocTable;
import 'package:rfw_gen_playground/widgets/gallery/mystique_badge.dart' show MystiqueBadge;

/// Auto-generated [LocalWidgetBuilder] map.
Map<String, LocalWidgetBuilder> get generatedLocalWidgetBuilders =>
    <String, LocalWidgetBuilder>{
  'MystiqueBadge': (BuildContext context, DataSource source) {
    return MystiqueBadge(
      type: source.v<String>(['type']) ?? 'dot',
      title: source.v<String>(['title']),
      color: source.v<int>(['color']),
    );
  },
  'DocTable': (BuildContext context, DataSource source) {
    return DocTable(
      headers: source.v<dynamic>(['headers']),
      rows: source.v<dynamic>(['rows']),
    );
  },
  'CodeBlock': (BuildContext context, DataSource source) {
    return CodeBlock(
      code: source.v<String>(['code']) ?? '',
      language: source.v<String>(['language']),
    );
  },
};

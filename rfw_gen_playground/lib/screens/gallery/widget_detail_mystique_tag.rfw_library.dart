// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_gen_playground/widgets/code_block.dart' show CodeBlock;
import 'package:rfw_gen_playground/widgets/doc_table.dart' show DocTable;
import 'package:rfw_gen_playground/widgets/gallery/mystique_tag.dart' show MystiqueTag;

/// Auto-generated [LocalWidgetBuilder] map.
Map<String, LocalWidgetBuilder> get generatedLocalWidgetBuilders =>
    <String, LocalWidgetBuilder>{
  'MystiqueTag': (BuildContext context, DataSource source) {
    return MystiqueTag(
      title: source.v<String>(['title']) ?? '',
      type: source.v<String>(['type']) ?? 'primary',
      size: source.v<String>(['size']) ?? 'medium',
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

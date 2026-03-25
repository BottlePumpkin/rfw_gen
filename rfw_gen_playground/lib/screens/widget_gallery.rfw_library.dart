// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_gen_playground/widgets/doc_table.dart' show DocTable;
import 'package:rfw_gen_playground/widgets/link_text.dart' show LinkText;

/// Auto-generated [LocalWidgetBuilder] map.
Map<String, LocalWidgetBuilder> get generatedLocalWidgetBuilders =>
    <String, LocalWidgetBuilder>{
  'DocTable': (BuildContext context, DataSource source) {
    return DocTable(
      headers: source.v<dynamic>(['headers']),
      rows: source.v<dynamic>(['rows']),
    );
  },
  'LinkText': (BuildContext context, DataSource source) {
    return LinkText(
      text: source.v<String>(['text']) ?? '',
      page: source.v<String>(['page']) ?? '',
      onNavigate: source.v<dynamic>(['onNavigate']),
    );
  },
};

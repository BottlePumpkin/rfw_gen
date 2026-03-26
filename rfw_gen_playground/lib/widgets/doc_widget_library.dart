import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';

import 'code_block.dart';
import 'doc_table.dart';
import 'link_text.dart';
import 'rich_text_row.dart';
import 'gallery/conditional_widget.dart';
import 'gallery/mystique_badge.dart';
import 'gallery/mystique_box_button.dart';
import 'gallery/mystique_spinner.dart';
import 'gallery/mystique_tag.dart';

/// Library name matching the rfwtxt import: `import rfw_gen_playground;`
const docWidgetsLibraryName = LibraryName(<String>['rfw_gen_playground']);

/// All doc widget builders for LocalWidgetLibrary registration.
Map<String, LocalWidgetBuilder> get docWidgetBuilders => {
      'CodeBlock': _buildCodeBlock,
      'RichTextRow': _buildRichTextRow,
      'DocTable': _buildDocTable,
      'LinkText': _buildLinkText,
      'MystiqueBoxButton': _buildMystiqueBoxButton,
      'MystiqueTag': _buildMystiqueTag,
      'MystiqueBadge': _buildMystiqueBadge,
      'MystiqueSpinner': _buildMystiqueSpinner,
      'ConditionalWidget': _buildConditionalWidget,
    };

Widget _buildCodeBlock(BuildContext context, DataSource source) {
  final code = (source.v<String>(['code']) ?? '').replaceAll(r'\n', '\n');
  return CodeBlock(
    code: code,
    language: source.v<String>(['language']),
  );
}

Widget _buildRichTextRow(BuildContext context, DataSource source) {
  final length = source.length(['segments']);
  final segments = <TextSegment>[];
  for (var i = 0; i < length; i++) {
    segments.add(TextSegment(
      text: source.v<String>(['segments', i, 'text']) ?? '',
      bold: source.v<bool>(['segments', i, 'bold']) ?? false,
      italic: source.v<bool>(['segments', i, 'italic']) ?? false,
      color: _colorFromInt(source.v<int>(['segments', i, 'color'])),
      link: source.v<String>(['segments', i, 'link']),
    ));
  }
  return RichTextRow(segments: segments);
}

Widget _buildDocTable(BuildContext context, DataSource source) {
  final headerLength = source.length(['headers']);
  final headers = <String>[
    for (var i = 0; i < headerLength; i++)
      source.v<String>(['headers', i]) ?? '',
  ];
  final rowLength = source.length(['rows']);
  final rows = <List<String>>[
    for (var i = 0; i < rowLength; i++)
      <String>[
        for (var j = 0; j < headerLength; j++)
          source.v<String>(['rows', i, j]) ?? '',
      ],
  ];
  return DocTable(headers: headers, rows: rows);
}

Widget _buildLinkText(BuildContext context, DataSource source) {
  final page = source.v<String>(['page']) ?? '';
  return LinkText(
    text: source.v<String>(['text']) ?? '',
    page: page,
    onNavigate: (_) {
      source.voidHandler(['onTap'])?.call();
    },
  );
}

Widget _buildMystiqueBoxButton(BuildContext context, DataSource source) {
  return MystiqueBoxButton(
    text: source.v<String>(['text']) ?? '',
    type: source.v<String>(['type']) ?? 'primary',
    size: source.v<String>(['size']) ?? 'l',
    onPressed: source.voidHandler(['onPressed']),
  );
}

Widget _buildMystiqueTag(BuildContext context, DataSource source) {
  return MystiqueTag(
    title: source.v<String>(['title']) ?? '',
    type: source.v<String>(['type']) ?? 'primary',
    size: source.v<String>(['size']) ?? 'medium',
  );
}

Widget _buildMystiqueBadge(BuildContext context, DataSource source) {
  return MystiqueBadge(
    type: source.v<String>(['type']) ?? 'dot',
    title: source.v<String>(['title']),
    color: source.v<int>(['color']),
  );
}

Widget _buildMystiqueSpinner(BuildContext context, DataSource source) {
  return MystiqueSpinner(
    size: source.v<String>(['size']) ?? 'medium',
  );
}

Widget _buildConditionalWidget(BuildContext context, DataSource source) {
  return ConditionalWidget(
    condition: source.v<bool>(['condition']) ?? false,
    childIfTrue: source.child(['childIfTrue']),
    childIfFalse: source.child(['childIfFalse']),
  );
}

Color? _colorFromInt(int? value) {
  if (value == null) return null;
  return Color(value);
}

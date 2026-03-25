import 'dart:convert';

import 'package:rfw_gen_builder/src/local_widget_builder_generator.dart';
import 'package:rfw_gen_builder/src/widget_resolver.dart';
import 'package:test/test.dart';

/// Matcher that checks a [Map] contains the given key.
Matcher mapContainsKey(Object? key) => predicate<Map>(
      (m) => m.containsKey(key),
      'map containing key $key',
    );

void main() {
  late LocalWidgetBuilderGenerator gen;

  setUp(() {
    gen = LocalWidgetBuilderGenerator();
  });

  // ---------------------------------------------------------------------------
  // Helper factories
  // ---------------------------------------------------------------------------

  ResolvedWidget makeWidget({
    required String className,
    String dartImport = 'package:mystique/widgets/coupon_card.dart',
    List<ResolvedParam> params = const [],
  }) =>
      ResolvedWidget(
        className: className,
        dartImport: dartImport,
        params: params,
      );

  ResolvedParam param(
    String name,
    ResolvedParamType type, {
    bool isRequired = true,
    bool isNullable = false,
    String? defaultValue,
  }) =>
      ResolvedParam(
        name: name,
        type: type,
        isRequired: isRequired,
        isNullable: isNullable,
        defaultValue: defaultValue,
      );

  // ---------------------------------------------------------------------------
  // generate() — Dart output
  // ---------------------------------------------------------------------------

  group('generate()', () {
    test('output starts with generated code header', () {
      final output = gen.generate({});
      expect(output, startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND'));
    });

    test('output includes flutter and rfw imports', () {
      final output = gen.generate({});
      expect(output, contains("import 'package:flutter/material.dart';"));
      expect(output, contains("import 'package:rfw/rfw.dart';"));
    });

    test('includes source dartImport with show directive in output', () {
      final widget = makeWidget(
        className: 'CouponCard',
        dartImport: 'package:mystique/widgets/coupon_card.dart',
      );
      final output = gen.generate({'CouponCard': widget});
      expect(
        output,
        contains(
            "import 'package:mystique/widgets/coupon_card.dart' show CouponCard;"),
      );
    });

    test('deduplicates imports when multiple widgets share same file', () {
      final sharedImport = 'package:myapp/shared.dart';
      final w1 = makeWidget(className: 'WidgetA', dartImport: sharedImport);
      final w2 = makeWidget(className: 'WidgetB', dartImport: sharedImport);
      final output = gen.generate({'WidgetA': w1, 'WidgetB': w2});

      // Single import line with both names in show clause
      final count = 'import \'$sharedImport\''.allMatches(output).length;
      expect(count, equals(1));
      expect(
        output,
        contains(
            "import 'package:myapp/shared.dart' show WidgetA, WidgetB;"),
      );
    });

    test('output contains generatedLocalWidgetBuilders getter', () {
      final output = gen.generate({});
      expect(output, contains('generatedLocalWidgetBuilders'));
      expect(output, contains('Map<String, LocalWidgetBuilder>'));
    });

    // --- Primitive types ---

    test('String required param → source.v<String> with empty string fallback',
        () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('title', ResolvedParamType.string)],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("title: source.v<String>(['title']) ?? ''"));
    });

    test('String param with default → source.v<String> with default fallback',
        () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('label', ResolvedParamType.string,
              isRequired: false, defaultValue: "'Hello'")
        ],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("label: source.v<String>(['label']) ?? 'Hello'"));
    });

    test('int required param → source.v<int> with 0 fallback', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('count', ResolvedParamType.int)],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("count: source.v<int>(['count']) ?? 0"));
    });

    test('int param with color default → source.v<int> with hex fallback', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('color', ResolvedParamType.int,
              isRequired: false, defaultValue: '0xFF000000')
        ],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("color: source.v<int>(['color']) ?? 0xFF000000"));
    });

    test('double required param → source.v<double> with 0.0 fallback', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('ratio', ResolvedParamType.double)],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("ratio: source.v<double>(['ratio']) ?? 0.0"));
    });

    test('double param with default → preserves default value', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('elevation', ResolvedParamType.double,
              isRequired: false, defaultValue: '4.0')
        ],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output,
          contains("elevation: source.v<double>(['elevation']) ?? 4.0"));
    });

    test('bool required param → source.v<bool> with false fallback', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('enabled', ResolvedParamType.bool)],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("enabled: source.v<bool>(['enabled']) ?? false"));
    });

    test('bool param with true default → source.v<bool> with true fallback',
        () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('visible', ResolvedParamType.bool,
              isRequired: false, defaultValue: 'true')
        ],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("visible: source.v<bool>(['visible']) ?? true"));
    });

    test('optional primitive without default → no fallback suffix', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('tag', ResolvedParamType.string,
              isRequired: false, isNullable: true)
        ],
      );
      final output = gen.generate({'MyWidget': widget});
      // Should have the call but no ?? suffix
      expect(output, contains("tag: source.v<String>(['tag'])"));
      expect(output, isNot(contains("?? ''")));
    });

    // --- Widget types ---

    test('widget param → source.child()', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('child', ResolvedParamType.widget)],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("child: source.child(['child'])"));
    });

    test('optionalWidget param → source.optionalChild()', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('child', ResolvedParamType.optionalWidget,
              isRequired: false, isNullable: true)
        ],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("child: source.optionalChild(['child'])"));
    });

    test('widgetList param → loop with source.length and source.child', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('children', ResolvedParamType.widgetList)],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains('final children = <Widget>[];'));
      expect(output, contains("source.length(['children'])"));
      expect(output, contains("source.child(['children', i])"));
      // The local variable should be passed directly
      expect(output, contains('children: children,'));
    });

    // --- Callback types ---

    test('voidCallback param → source.voidHandler()', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('onTap', ResolvedParamType.voidCallback,
              isRequired: false, isNullable: true)
        ],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("onTap: source.voidHandler(['onTap'])"));
    });

    // --- Named slots ---

    test('named widget slots → source.optionalChild() for each', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('leading', ResolvedParamType.optionalWidget,
              isRequired: false, isNullable: true),
          param('trailing', ResolvedParamType.optionalWidget,
              isRequired: false, isNullable: true),
        ],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("leading: source.optionalChild(['leading'])"));
      expect(output, contains("trailing: source.optionalChild(['trailing'])"));
    });

    // --- Other type ---

    test('other type → source.v<dynamic>()', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('data', ResolvedParamType.other)],
      );
      final output = gen.generate({'MyWidget': widget});
      expect(output, contains("data: source.v<dynamic>(['data'])"));
    });

    // --- Multiple widgets ---

    test('multiple widgets → all present in map', () {
      final w1 = makeWidget(
          className: 'WidgetA',
          dartImport: 'package:app/a.dart',
          params: [param('x', ResolvedParamType.string)]);
      final w2 = makeWidget(
          className: 'WidgetB',
          dartImport: 'package:app/b.dart',
          params: [param('y', ResolvedParamType.int)]);

      final output = gen.generate({'WidgetA': w1, 'WidgetB': w2});
      expect(output, contains("'WidgetA'"));
      expect(output, contains("'WidgetB'"));
      expect(output, contains("x: source.v<String>(['x'])"));
      expect(output, contains("y: source.v<int>(['y'])"));
    });

    // --- Show directive ---

    test('show directive lists multiple widgets from same import', () {
      final sharedImport = 'package:myapp/shared.dart';
      final w1 = makeWidget(className: 'Zebra', dartImport: sharedImport);
      final w2 = makeWidget(className: 'Alpha', dartImport: sharedImport);
      final output = gen.generate({'Zebra': w1, 'Alpha': w2});

      // Names should be sorted alphabetically
      expect(
        output,
        contains("import 'package:myapp/shared.dart' show Alpha, Zebra;"),
      );
    });

    // --- Complex widget with mixed params ---

    test('complex widget: string + widget child + voidCallback', () {
      final widget = makeWidget(
        className: 'CouponCard',
        dartImport: 'package:mystique/widgets/coupon_card.dart',
        params: [
          param('title', ResolvedParamType.string),
          param('onTap', ResolvedParamType.voidCallback,
              isRequired: false, isNullable: true),
          param('child', ResolvedParamType.widget),
        ],
      );
      final output = gen.generate({'CouponCard': widget});
      expect(output, contains("title: source.v<String>(['title']) ?? ''"));
      expect(output, contains("onTap: source.voidHandler(['onTap'])"));
      expect(output, contains("child: source.child(['child'])"));
    });
  });

  // ---------------------------------------------------------------------------
  // generateMeta() — JSON output
  // ---------------------------------------------------------------------------

  group('generateMeta()', () {
    test('produces valid JSON', () {
      final widget = makeWidget(
        className: 'CouponCard',
        dartImport: 'package:mystique/widgets/coupon_card.dart',
        params: [
          param('title', ResolvedParamType.string),
          param('onTap', ResolvedParamType.voidCallback,
              isRequired: false, isNullable: true),
        ],
      );
      final meta = gen.generateMeta({'CouponCard': widget});
      // Should not throw
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      expect(decoded, mapContainsKey('widgets'));
    });

    test('widget entry contains import package name', () {
      final widget = makeWidget(
        className: 'CouponCard',
        dartImport: 'package:mystique/widgets/coupon_card.dart',
      );
      final meta = gen.generateMeta({'CouponCard': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final coupon = (decoded['widgets'] as Map<String, dynamic>)['CouponCard']!
          as Map<String, dynamic>;
      expect(coupon['import'], equals('mystique'));
    });

    test('handlers list contains callback param names', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('onTap', ResolvedParamType.voidCallback,
              isRequired: false, isNullable: true),
          param('onLongPress', ResolvedParamType.voidCallback,
              isRequired: false, isNullable: true),
        ],
      );
      final meta = gen.generateMeta({'MyWidget': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final w = (decoded['widgets'] as Map<String, dynamic>)['MyWidget']!
          as Map<String, dynamic>;
      expect(w['handlers'], containsAll(['onTap', 'onLongPress']));
    });

    test('childType is "child" when widget has required Widget child', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('child', ResolvedParamType.widget)],
      );
      final meta = gen.generateMeta({'MyWidget': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final w = (decoded['widgets'] as Map<String, dynamic>)['MyWidget']!
          as Map<String, dynamic>;
      expect(w['childType'], equals('child'));
    });

    test('childType is "optionalChild" when widget has Widget? child', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('child', ResolvedParamType.optionalWidget,
              isRequired: false, isNullable: true)
        ],
      );
      final meta = gen.generateMeta({'MyWidget': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final w = (decoded['widgets'] as Map<String, dynamic>)['MyWidget']!
          as Map<String, dynamic>;
      expect(w['childType'], equals('optionalChild'));
    });

    test('childType is "childList" when widget has List<Widget> children', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('children', ResolvedParamType.widgetList)],
      );
      final meta = gen.generateMeta({'MyWidget': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final w = (decoded['widgets'] as Map<String, dynamic>)['MyWidget']!
          as Map<String, dynamic>;
      expect(w['childType'], equals('childList'));
    });

    test('childType is "none" for widget with no child params', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [param('title', ResolvedParamType.string)],
      );
      final meta = gen.generateMeta({'MyWidget': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final w = (decoded['widgets'] as Map<String, dynamic>)['MyWidget']!
          as Map<String, dynamic>;
      expect(w['childType'], equals('none'));
    });

    test('params list excludes widget and callback params', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('title', ResolvedParamType.string),
          param('onTap', ResolvedParamType.voidCallback,
              isRequired: false, isNullable: true),
          param('child', ResolvedParamType.widget),
        ],
      );
      final meta = gen.generateMeta({'MyWidget': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final w = (decoded['widgets'] as Map<String, dynamic>)['MyWidget']!
          as Map<String, dynamic>;
      final params = w['params'] as List<dynamic>;

      final names = params.map((p) => (p as Map)['name']).toList();
      expect(names, contains('title'));
      expect(names, isNot(contains('onTap')));
      expect(names, isNot(contains('child')));
    });

    test('params have correct required flag', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('title', ResolvedParamType.string, isRequired: true),
          param('subtitle', ResolvedParamType.string,
              isRequired: false, isNullable: true),
        ],
      );
      final meta = gen.generateMeta({'MyWidget': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final w = (decoded['widgets'] as Map<String, dynamic>)['MyWidget']!
          as Map<String, dynamic>;
      final params =
          (w['params'] as List<dynamic>).cast<Map<String, dynamic>>();

      final titleParam = params.firstWhere((p) => p['name'] == 'title');
      final subtitleParam = params.firstWhere((p) => p['name'] == 'subtitle');
      expect(titleParam['required'], isTrue);
      expect(subtitleParam['required'], isFalse);
    });

    test('params have correct type strings', () {
      final widget = makeWidget(
        className: 'MyWidget',
        params: [
          param('name', ResolvedParamType.string),
          param('count', ResolvedParamType.int),
          param('ratio', ResolvedParamType.double),
          param('enabled', ResolvedParamType.bool),
        ],
      );
      final meta = gen.generateMeta({'MyWidget': widget});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final w = (decoded['widgets'] as Map<String, dynamic>)['MyWidget']!
          as Map<String, dynamic>;
      final params =
          (w['params'] as List<dynamic>).cast<Map<String, dynamic>>();

      final typeMap = {for (final p in params) p['name'] as String: p['type']};
      expect(typeMap['name'], equals('String'));
      expect(typeMap['count'], equals('int'));
      expect(typeMap['ratio'], equals('double'));
      expect(typeMap['enabled'], equals('bool'));
    });

    test('multiple widgets → all entries in JSON', () {
      final w1 =
          makeWidget(className: 'WidgetA', dartImport: 'package:app/a.dart');
      final w2 =
          makeWidget(className: 'WidgetB', dartImport: 'package:app/b.dart');

      final meta = gen.generateMeta({'WidgetA': w1, 'WidgetB': w2});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      final widgets = decoded['widgets'] as Map<String, dynamic>;
      expect(widgets, mapContainsKey('WidgetA'));
      expect(widgets, mapContainsKey('WidgetB'));
    });

    test('empty widgets map → valid JSON with empty widgets object', () {
      final meta = gen.generateMeta({});
      final decoded = jsonDecode(meta) as Map<String, dynamic>;
      expect(decoded['widgets'], isEmpty);
    });
  });
}

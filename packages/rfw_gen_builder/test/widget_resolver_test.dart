// ignore_for_file: deprecated_member_use

/// Tests for WidgetResolver — verifies constructor analysis → WidgetMapping
/// using the analyzer directly (same approach as resolver_spike_test.dart).
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:rfw_gen_builder/src/widget_registry.dart';
import 'package:rfw_gen_builder/src/widget_resolver.dart';
import 'package:test/test.dart';

/// Helper: get LibraryElement from a resolved library path.
Future<LibraryElement> resolveLibrary(
  AnalysisContextCollection collection,
  String filePath,
) async {
  final ctx = collection.contexts.first;
  final result = await ctx.currentSession.getResolvedLibrary(filePath);
  expect(result, isA<ResolvedLibraryResult>());
  return (result as ResolvedLibraryResult).element;
}

/// Helper: find an imported library by URI substring.
LibraryElement findImport(LibraryElement lib, String uriSubstring) {
  final imports = lib.firstFragment.importedLibraries;
  return imports.firstWhere(
    (imported) => imported.uri.toString().contains(uriSubstring),
    orElse: () =>
        throw StateError('No import matching "$uriSubstring" in ${lib.uri}'),
  );
}

/// Creates a temporary package layout with various widget types for testing.
Directory createTestPackages() {
  final root = Directory.systemTemp.createTempSync('widget_resolver_test_');

  // Package 'widgets_pkg': external widget package
  _writeFile(root, 'widgets_pkg/pubspec.yaml', '''
name: widgets_pkg
environment:
  sdk: ^3.6.0
''');

  _writeFile(root, 'widgets_pkg/lib/framework.dart', '''
class Key {}
class BuildContext {}
abstract class Widget {}
abstract class StatelessWidget extends Widget {
  const StatelessWidget({Key? key});
  Widget build(BuildContext context);
}
abstract class StatefulWidget extends Widget {
  const StatefulWidget({Key? key});
}
typedef VoidCallback = void Function();
''');

  // Widget with primitives only → ChildType.none
  _writeFile(root, 'widgets_pkg/lib/primitive_widget.dart', '''
import 'framework.dart';

class PrimitiveWidget extends StatelessWidget {
  final String title;
  final int count;
  final double ratio;
  final bool enabled;

  const PrimitiveWidget({
    super.key,
    required this.title,
    this.count = 0,
    this.ratio = 1.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => this;
}
''');

  // Widget with required Widget child → ChildType.child
  _writeFile(root, 'widgets_pkg/lib/child_widget.dart', '''
import 'framework.dart';

class ChildWidget extends StatelessWidget {
  final Widget child;

  const ChildWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}
''');

  // Widget with Widget? child only → ChildType.optionalChild
  _writeFile(root, 'widgets_pkg/lib/optional_child_widget.dart', '''
import 'framework.dart';

class OptionalChildWidget extends StatelessWidget {
  final Widget? child;
  final String label;

  const OptionalChildWidget({
    super.key,
    this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => this;
}
''');

  // Widget with List<Widget> children → ChildType.childList
  _writeFile(root, 'widgets_pkg/lib/list_children_widget.dart', '''
import 'framework.dart';

class ListChildrenWidget extends StatelessWidget {
  final List<Widget> children;
  final String direction;

  const ListChildrenWidget({
    super.key,
    required this.children,
    this.direction = 'vertical',
  });

  @override
  Widget build(BuildContext context) => this;
}
''');

  // Widget with multiple Widget? params → ChildType.namedSlots
  _writeFile(root, 'widgets_pkg/lib/named_slots_widget.dart', '''
import 'framework.dart';

class NamedSlotsWidget extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final bool dense;

  const NamedSlotsWidget({
    super.key,
    this.leading,
    this.title,
    this.trailing,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) => this;
}
''');

  // Widget with VoidCallback? → extracted as handler
  _writeFile(root, 'widgets_pkg/lib/handler_widget.dart', '''
import 'framework.dart';

class HandlerWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String label;

  const HandlerWidget({
    super.key,
    this.onPressed,
    this.onLongPress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => this;
}
''');

  // Mixed: Widget child + Widget? leading → ChildType.child + namedSlots
  _writeFile(root, 'widgets_pkg/lib/mixed_widget.dart', '''
import 'framework.dart';

class MixedWidget extends StatelessWidget {
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final String title;

  const MixedWidget({
    super.key,
    required this.child,
    this.leading,
    this.trailing,
    required this.title,
  });

  @override
  Widget build(BuildContext context) => child;
}
''');

  // Empty constructor widget
  _writeFile(root, 'widgets_pkg/lib/empty_widget.dart', '''
import 'framework.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({super.key});

  @override
  Widget build(BuildContext context) => this;
}
''');

  // Non-widget class
  _writeFile(root, 'widgets_pkg/lib/non_widget.dart', '''
class NotAWidget {
  final String value;
  const NotAWidget({required this.value});
}
''');

  // Abstract class
  _writeFile(root, 'widgets_pkg/lib/abstract_widget.dart', '''
import 'framework.dart';

abstract class AbstractWidget extends StatelessWidget {
  const AbstractWidget({super.key});
}
''');

  // Widget with void Function() (not typedef) handler
  _writeFile(root, 'widgets_pkg/lib/raw_callback_widget.dart', '''
import 'framework.dart';

class RawCallbackWidget extends StatelessWidget {
  final void Function()? onTap;
  final String text;

  const RawCallbackWidget({
    super.key,
    this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => this;
}
''');

  // Consumer package
  _writeFile(root, 'consumer/pubspec.yaml', '''
name: consumer
environment:
  sdk: ^3.6.0
dependencies:
  widgets_pkg:
    path: ../widgets_pkg
''');

  _writeFile(root, 'consumer/lib/use_all.dart', '''
import 'package:widgets_pkg/primitive_widget.dart';
import 'package:widgets_pkg/child_widget.dart';
import 'package:widgets_pkg/optional_child_widget.dart';
import 'package:widgets_pkg/list_children_widget.dart';
import 'package:widgets_pkg/named_slots_widget.dart';
import 'package:widgets_pkg/handler_widget.dart';
import 'package:widgets_pkg/mixed_widget.dart';
import 'package:widgets_pkg/empty_widget.dart';
import 'package:widgets_pkg/non_widget.dart';
import 'package:widgets_pkg/abstract_widget.dart';
import 'package:widgets_pkg/raw_callback_widget.dart';

void useAll() {
  PrimitiveWidget(title: 'test');
  ChildWidget(child: EmptyWidget());
  OptionalChildWidget(label: 'test');
  ListChildrenWidget(children: []);
  NamedSlotsWidget();
  HandlerWidget(label: 'test');
  MixedWidget(child: EmptyWidget(), title: 'test');
  EmptyWidget();
  NotAWidget(value: 'test');
  RawCallbackWidget(text: 'test');
}
''');

  // Package config for consumer
  _writeFile(root, 'consumer/.dart_tool/package_config.json', '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "widgets_pkg",
      "rootUri": "../../widgets_pkg",
      "packageUri": "lib/"
    },
    {
      "name": "consumer",
      "rootUri": "..",
      "packageUri": "lib/"
    }
  ]
}
''');

  return root;
}

void _writeFile(Directory root, String path, String content) {
  final file = File('${root.path}/$path');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _findDartSdkPath() {
  final dartExec = Platform.resolvedExecutable;
  return Directory(dartExec).parent.parent.path;
}

void main() {
  late Directory testRoot;
  late AnalysisContextCollection contextCollection;
  late WidgetResolver resolver;

  setUpAll(() {
    testRoot = createTestPackages();
    contextCollection = AnalysisContextCollection(
      includedPaths: ['${testRoot.path}/consumer/lib'],
      sdkPath: _findDartSdkPath(),
    );
    resolver = WidgetResolver();
  });

  tearDownAll(() {
    testRoot.deleteSync(recursive: true);
  });

  /// Helper to resolve the consumer library and find the imported library
  /// containing the target class.
  Future<LibraryElement> getWidgetLibrary(String importSubstring) async {
    final consumerLib = await resolveLibrary(
      contextCollection,
      '${testRoot.path}/consumer/lib/use_all.dart',
    );
    return findImport(consumerLib, importSubstring);
  }

  group('WidgetResolver', () {
    test('primitives only → ChildType.none', () async {
      final lib = await getWidgetLibrary('package:widgets_pkg/primitive_widget');
      final result = resolver.resolveFromLibrary(lib, 'PrimitiveWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.childType, ChildType.none);
      expect(mapping.params, contains('title'));
      expect(mapping.params, contains('count'));
      expect(mapping.params, contains('ratio'));
      expect(mapping.params, contains('enabled'));
      // Key should be skipped
      expect(mapping.params, isNot(contains('key')));

      // Check resolved widget params
      final rw = result.resolvedWidget;
      expect(rw.className, 'PrimitiveWidget');
      final titleParam =
          rw.params.firstWhere((p) => p.name == 'title');
      expect(titleParam.type, ResolvedParamType.string);
      expect(titleParam.isRequired, isTrue);

      final countParam =
          rw.params.firstWhere((p) => p.name == 'count');
      expect(countParam.type, ResolvedParamType.int);
      expect(countParam.isRequired, isFalse);
    });

    test('required Widget child → ChildType.child', () async {
      final lib = await getWidgetLibrary('package:widgets_pkg/child_widget');
      final result = resolver.resolveFromLibrary(lib, 'ChildWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.childType, ChildType.child);
      expect(mapping.childParam, 'child');
      // 'child' should not be in params (it's the child slot)
      expect(mapping.params, isNot(contains('child')));
    });

    test('Widget? child only → ChildType.optionalChild', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/optional_child_widget');
      final result = resolver.resolveFromLibrary(lib, 'OptionalChildWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.childType, ChildType.optionalChild);
      expect(mapping.childParam, 'child');
      expect(mapping.params, contains('label'));
      expect(mapping.params, isNot(contains('child')));
    });

    test('List<Widget> children → ChildType.childList', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/list_children_widget');
      final result = resolver.resolveFromLibrary(lib, 'ListChildrenWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.childType, ChildType.childList);
      expect(mapping.childParam, 'children');
      expect(mapping.params, contains('direction'));
      expect(mapping.params, isNot(contains('children')));
    });

    test('multiple Widget? params → ChildType.namedSlots', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/named_slots_widget');
      final result = resolver.resolveFromLibrary(lib, 'NamedSlotsWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.childType, ChildType.namedSlots);
      expect(mapping.namedChildSlots, contains('leading'));
      expect(mapping.namedChildSlots, contains('title'));
      expect(mapping.namedChildSlots, contains('trailing'));
      // All are single slots (not list)
      expect(mapping.namedChildSlots['leading'], isFalse);
      expect(mapping.params, contains('dense'));
      expect(mapping.params, isNot(contains('leading')));
    });

    test('VoidCallback? → extracted as handler', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/handler_widget');
      final result = resolver.resolveFromLibrary(lib, 'HandlerWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.handlerParams, contains('onPressed'));
      expect(mapping.handlerParams, contains('onLongPress'));
      expect(mapping.params, contains('label'));
      // Handlers should not be in params
      expect(mapping.params, isNot(contains('onPressed')));
      expect(mapping.params, isNot(contains('onLongPress')));

      // Check resolved param types
      final rw = result.resolvedWidget;
      final onPressedParam =
          rw.params.firstWhere((p) => p.name == 'onPressed');
      expect(onPressedParam.type, ResolvedParamType.voidCallback);
      expect(onPressedParam.isNullable, isTrue);
    });

    test('mixed: Widget child + Widget? named slots → ChildType.child + namedSlots',
        () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/mixed_widget');
      final result = resolver.resolveFromLibrary(lib, 'MixedWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.childType, ChildType.child);
      expect(mapping.childParam, 'child');
      expect(mapping.namedChildSlots, contains('leading'));
      expect(mapping.namedChildSlots, contains('trailing'));
      expect(mapping.params, contains('title'));
      // child, leading, trailing should not be in params
      expect(mapping.params, isNot(contains('child')));
      expect(mapping.params, isNot(contains('leading')));
      expect(mapping.params, isNot(contains('trailing')));
    });

    test('Key / super.key → skipped', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/primitive_widget');
      final result = resolver.resolveFromLibrary(lib, 'PrimitiveWidget');

      expect(result, isNotNull);
      expect(result!.widgetMapping.params, isNot(contains('key')));
      // Also check ResolvedWidget params
      expect(
        result.resolvedWidget.params.where((p) => p.name == 'key'),
        isEmpty,
      );
    });

    test('empty constructor → ChildType.none, no params', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/empty_widget');
      final result = resolver.resolveFromLibrary(lib, 'EmptyWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.childType, ChildType.none);
      expect(mapping.params, isEmpty);
      expect(mapping.handlerParams, isEmpty);
    });

    test('non-widget class → returns null', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/non_widget');
      final result = resolver.resolveFromLibrary(lib, 'NotAWidget');

      expect(result, isNull);
    });

    test('abstract class → returns null', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/abstract_widget');
      final result = resolver.resolveFromLibrary(lib, 'AbstractWidget');

      expect(result, isNull);
    });

    test('package name extraction from library URI', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/primitive_widget');
      final result = resolver.resolveFromLibrary(lib, 'PrimitiveWidget');

      expect(result, isNotNull);
      expect(result!.resolvedWidget.dartImport,
          contains('package:widgets_pkg/'));
    });

    test('void Function()? (raw, not typedef) → extracted as handler',
        () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/raw_callback_widget');
      final result = resolver.resolveFromLibrary(lib, 'RawCallbackWidget');

      expect(result, isNotNull);
      final mapping = result!.widgetMapping;
      expect(mapping.handlerParams, contains('onTap'));
      expect(mapping.params, contains('text'));
      expect(mapping.params, isNot(contains('onTap')));
    });

    test('batchResolve resolves multiple widgets', () async {
      final lib =
          await getWidgetLibrary('package:widgets_pkg/primitive_widget');
      // PrimitiveWidget is in this library, EmptyWidget is not
      final results = resolver.batchResolve(
        lib,
        {'PrimitiveWidget', 'NonExistentWidget'},
      );

      expect(results, contains('PrimitiveWidget'));
      expect(results, isNot(contains('NonExistentWidget')));
      expect(results['PrimitiveWidget']!.widgetMapping.childType,
          ChildType.none);
    });
  });
}

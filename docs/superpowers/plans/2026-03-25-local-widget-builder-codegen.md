# LocalWidgetBuilder Auto-Generation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Auto-generate `LocalWidgetBuilder` maps from `@rfwLocalWidget`-annotated Flutter classes, eliminating manual boilerplate.

**Architecture:** New `@rfwLocalWidget` annotation + AST-based builder in rfw_gen_builder. Builder parses class constructors, maps parameter types to DataSource API calls, and generates `.rfw_library.dart` files. No Resolver needed — AST parsing is sufficient for type name extraction.

**Tech Stack:** Dart analyzer (parseString), build_runner, build_test

**Known trade-off:** Moving render logic from manual builders INTO widget classes adds one extra StatelessWidget layer per custom widget in the widget tree. Visual output is identical, but widget tree structure changes. **Golden tests will need regeneration** after this migration (Linux CI only).

---

## File Structure

### Create
- `example/lib/custom/custom_widget_classes.dart` — 13 real Flutter widget classes (move logic from manual builders)
- `packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart` — AST → LocalWidgetBuilder code generation
- `packages/rfw_gen_builder/test/local_widget_builder_test.dart` — unit tests for generator

### Modify
- `packages/rfw_gen/lib/src/annotations.dart` — add `@rfwLocalWidget` annotation
- `packages/rfw_gen/lib/rfw_gen.dart` — export still works (same file)
- `packages/rfw_gen_builder/lib/builder.dart` — add `rfwLocalWidgetBuilder` factory
- `packages/rfw_gen_builder/build.yaml` — register new builder
- `example/lib/custom/custom_widgets.dart` — remove `ignore_for_file`, import real classes
- `example/lib/custom/custom_widget_builders.dart` — replace manual builders with re-export of generated file (preserves import compatibility for 4 consumers: `main.dart`, `golden_test_helper.dart`, `preview_page.dart`, `preview_app.dart`)

## Type Mapping Reference

Widget classes use RFW-compatible types (int for colors, not Color). Builder maps:

| Constructor Type | Generated DataSource Call |
|---|---|
| `String` (required) | `source.v<String>(['name']) ?? ''` |
| `String` (optional/default) | `source.v<String>(['name']) ?? 'default'` |
| `int` (required) | `source.v<int>(['name']) ?? 0` |
| `int` (optional) | `source.v<int>(['name'])` |
| `double` (required) | `source.v<double>(['name']) ?? 0.0` |
| `double` (optional) | `source.v<double>(['name'])` |
| `bool` (required) | `source.v<bool>(['name']) ?? false` |
| `bool` (optional) | `source.v<bool>(['name'])` |
| `Widget` (required) | `source.child(['name'])` |
| `Widget?` | `source.optionalChild(['name'])` |
| `List<Widget>` | loop: `source.length` + `source.child` |
| `VoidCallback?` | `source.voidHandler(['name'])` |
| `Key?` | skip (Flutter internal) |

---

### Task 1: Add `@rfwLocalWidget` annotation

**Files:**
- Modify: `packages/rfw_gen/lib/src/annotations.dart`

- [ ] **Step 1: Write the annotation class**

Add to the end of `packages/rfw_gen/lib/src/annotations.dart`:

```dart
/// Marks a widget class for [LocalWidgetBuilder] code generation.
///
/// The builder analyzes the class constructor and generates a
/// `LocalWidgetBuilder` function that bridges RFW [DataSource] to
/// the constructor parameters.
///
/// ```dart
/// @rfwLocalWidget
/// class CustomText extends StatelessWidget {
///   final String text;
///   const CustomText({super.key, required this.text});
///   // ...
/// }
/// ```
const rfwLocalWidget = RfwLocalWidget();

/// Annotation class for [rfwLocalWidget].
class RfwLocalWidget {
  /// Creates an [RfwLocalWidget] annotation.
  const RfwLocalWidget();
}
```

- [ ] **Step 2: Verify annotation is exported**

Run: `grep -n 'RfwLocalWidget\|rfwLocalWidget' packages/rfw_gen/lib/rfw_gen.dart packages/rfw_gen/lib/src/annotations.dart`

The barrel `rfw_gen.dart` already exports `src/annotations.dart`, so `@rfwLocalWidget` is automatically available.

- [ ] **Step 3: Run analyzer**

Run: `cd packages/rfw_gen && dart analyze`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add packages/rfw_gen/lib/src/annotations.dart
git commit -m "feat(rfw_gen): add @rfwLocalWidget annotation for builder codegen"
```

---

### Task 2: Create real Flutter widget classes

**Files:**
- Create: `example/lib/custom/custom_widget_classes.dart`

Move render logic from `custom_widget_builders.dart` into real StatelessWidget classes. Each class uses RFW-compatible types (int for colors) and contains the full render logic.

- [ ] **Step 1: Create the widget classes file**

Create `example/lib/custom/custom_widget_classes.dart` with all 13 widget classes.

Key patterns to follow:
- Use `int` for color params (RFW encodes colors as 0xAARRGGBB integers)
- Use `Widget`/`Widget?` for child params
- Use `VoidCallback?` for handler params
- Use `List<Widget>` for child lists
- Always include `Key? key` in constructor with `super.key`
- Annotate each class with `@rfwLocalWidget`

```dart
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@rfwLocalWidget
class CustomText extends StatelessWidget {
  final String text;
  final String fontType;
  final int color;
  final int? maxLines;

  const CustomText({
    super.key,
    required this.text,
    this.fontType = 'body',
    this.color = 0xFF000000,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    final style = switch (fontType) {
      'heading' =>
        TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c),
      'button' =>
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c),
      'caption' => TextStyle(fontSize: 12, color: c),
      _ => TextStyle(fontSize: 14, color: c),
    };
    return Text(text, style: style, maxLines: maxLines);
  }
}

@rfwLocalWidget
class CustomBounceTapper extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? child;

  const CustomBounceTapper({super.key, this.onTap, this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: child);
  }
}

@rfwLocalWidget
class NullConditionalWidget extends StatelessWidget {
  final Widget? child;
  final Widget? nullChild;

  const NullConditionalWidget({super.key, this.child, this.nullChild});

  @override
  Widget build(BuildContext context) {
    return child ?? nullChild ?? const SizedBox.shrink();
  }
}

@rfwLocalWidget
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;

  const CustomButton({
    super.key,
    this.onPressed,
    this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

@rfwLocalWidget
class CustomBadge extends StatelessWidget {
  final String label;
  final int count;
  final int backgroundColor;

  const CustomBadge({
    super.key,
    required this.label,
    this.count = 0,
    this.backgroundColor = 0xFF9E9E9E,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(backgroundColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label${count > 0 ? ' ($count)' : ''}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

@rfwLocalWidget
class CustomProgressBar extends StatelessWidget {
  final double value;
  final int color;
  final String shape;
  final double height;

  const CustomProgressBar({
    super.key,
    this.value = 0.0,
    this.color = 0xFF2196F3,
    this.shape = 'rounded',
    this.height = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(shape == 'rounded' ? height / 2 : 0),
      child: LinearProgressIndicator(
        value: value,
        color: Color(color),
        minHeight: height,
      ),
    );
  }
}

@rfwLocalWidget
class CustomColumn extends StatelessWidget {
  final double spacing;
  final int dividerColor;
  final List<Widget> children;

  const CustomColumn({
    super.key,
    this.spacing = 0.0,
    this.dividerColor = 0x00000000,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    final dc = Color(dividerColor);
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        if (spacing > 0) items.add(SizedBox(height: spacing));
        if (dc.a > 0) items.add(Divider(color: dc, height: 1));
      }
      items.add(children[i]);
    }
    return Column(children: items);
  }
}

@rfwLocalWidget
class SkeletonContainer extends StatelessWidget {
  final bool isLoading;
  final Widget? child;

  const SkeletonContainer({
    super.key,
    this.isLoading = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 48,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return child ?? const SizedBox.shrink();
  }
}

@rfwLocalWidget
class CompareWidget extends StatelessWidget {
  final Widget? child;
  final Widget? trueChild;
  final Widget? falseChild;

  const CompareWidget({super.key, this.child, this.trueChild, this.falseChild});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (child != null) child!,
      if (trueChild != null) trueChild!,
      if (falseChild != null) falseChild!,
    ]);
  }
}

@rfwLocalWidget
class PvContainer extends StatelessWidget {
  final VoidCallback? onPv;
  final Widget? child;

  const PvContainer({super.key, this.onPv, this.child});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onPv?.call());
    return child ?? const SizedBox.shrink();
  }
}

@rfwLocalWidget
class CustomCard extends StatelessWidget {
  final VoidCallback? onTap;
  final double elevation;
  final double borderRadius;
  final Widget child;

  const CustomCard({
    super.key,
    this.onTap,
    this.elevation = 1.0,
    this.borderRadius = 8.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

@rfwLocalWidget
class CustomTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CustomTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

@rfwLocalWidget
class CustomAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget> actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions.isEmpty ? null : actions,
      backgroundColor: const Color(0xFF2196F3),
    );
  }
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd example && dart analyze lib/custom/custom_widget_classes.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add example/lib/custom/custom_widget_classes.dart
git commit -m "feat(example): create real Flutter widget classes for 13 custom widgets"
```

---

### Task 3: Update custom_widgets.dart to use real classes

**Files:**
- Modify: `example/lib/custom/custom_widgets.dart`

- [ ] **Step 1: Replace ignore_for_file with import**

In `example/lib/custom/custom_widgets.dart`, replace line 1:

```dart
// OLD:
// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class, undefined_named_parameter, not_enough_positional_arguments

// NEW:
import 'custom_widget_classes.dart';
```

Keep the existing `import 'package:flutter/material.dart';` and `import 'package:rfw_gen/rfw_gen.dart';`.

- [ ] **Step 2: Verify existing @RfwWidget functions still work**

Run: `cd example && dart analyze lib/custom/custom_widgets.dart`
Expected: No errors (real classes now provide the types)

- [ ] **Step 3: Run build_runner to verify rfwtxt generation still works**

Run: `cd example && dart run build_runner build --delete-conflicting-outputs`
Expected: `custom_widgets.rfwtxt` and `custom_widgets.rfw` generated successfully

- [ ] **Step 4: Commit**

```bash
git add example/lib/custom/custom_widgets.dart
git commit -m "refactor(example): import real widget classes, remove ignore_for_file"
```

---

### Task 4: Create LocalWidgetBuilder generator

**Files:**
- Create: `packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart`

This is the core code generation logic. It parses annotated classes via AST and generates LocalWidgetBuilder Dart code.

- [ ] **Step 1: Write the failing test**

Create `packages/rfw_gen_builder/test/local_widget_builder_test.dart`:

```dart
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';

import 'package:rfw_gen_builder/src/local_widget_builder_generator.dart';

void main() {
  group('LocalWidgetBuilderGenerator', () {
    test('generates builder for simple widget with primitives', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class MyWidget extends StatelessWidget {
  final String text;
  final int count;

  const MyWidget({super.key, required this.text, this.count = 0});

  @override
  Widget build(BuildContext context) => Text(text);
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, isNotNull);
      expect(output, contains("'MyWidget'"));
      expect(output, contains("source.v<String>(['text'])"));
      expect(output, contains("source.v<int>(['count'])"));
    });

    test('generates builder with Widget child params', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class MyCard extends StatelessWidget {
  final Widget child;
  final Widget? leading;

  const MyCard({super.key, required this.child, this.leading});

  @override
  Widget build(BuildContext context) => child;
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, contains("source.child(['child'])"));
      expect(output, contains("source.optionalChild(['leading'])"));
    });

    test('generates builder with VoidCallback handlers', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class MyButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const MyButton({super.key, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, contains("source.voidHandler(['onTap'])"));
    });

    test('generates builder with List<Widget> children', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class MyList extends StatelessWidget {
  final List<Widget> children;

  const MyList({super.key, this.children = const []});

  @override
  Widget build(BuildContext context) => Column(children: children);
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, contains("source.length(['children'])"));
      expect(output, contains("source.child(['children', i])"));
    });

    test('skips Key parameter', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class MyWidget extends StatelessWidget {
  final String text;

  const MyWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Text(text);
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, isNot(contains("'key'")));
    });

    test('returns null for file without annotations', () {
      final source = '''
class NotAnnotated extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox();
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, isNull);
    });

    test('skips Key? as regular parameter (not super.key)', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class MyWidget extends StatelessWidget {
  final String text;

  const MyWidget({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) => Text(text);
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, isNot(contains("'key'")));
      expect(output, contains("source.v<String>(['text'])"));
    });

    test('handles widget with no fields (empty constructor)', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class EmptyWidget extends StatelessWidget {
  const EmptyWidget({super.key});

  @override
  Widget build(BuildContext context) => SizedBox();
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, isNotNull);
      expect(output, contains("'EmptyWidget'"));
      expect(output, contains('return EmptyWidget('));
    });

    test('handles multiple annotated classes in one file', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class WidgetA extends StatelessWidget {
  final String text;
  const WidgetA({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Text(text);
}

@rfwLocalWidget
class WidgetB extends StatelessWidget {
  final int count;
  const WidgetB({super.key, this.count = 0});
  @override
  Widget build(BuildContext context) => Text('\$count');
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, contains("'WidgetA'"));
      expect(output, contains("'WidgetB'"));
    });

    test('handles various default value types', () {
      final source = '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class Defaults extends StatelessWidget {
  final String label;
  final double size;
  final int color;
  final bool active;

  const Defaults({
    super.key,
    this.label = 'hello',
    this.size = 16.0,
    this.color = 0xFF000000,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) => SizedBox();
}
''';
      final result = parseString(content: source);
      final generator = LocalWidgetBuilderGenerator();
      final output = generator.generate(result.unit, source: source);

      expect(output, contains("?? 'hello'"));
      expect(output, contains('?? 16.0'));
      expect(output, contains('?? 0xFF000000'));
      expect(output, contains('?? true'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/rfw_gen_builder && dart test test/local_widget_builder_test.dart`
Expected: FAIL — `local_widget_builder_generator.dart` doesn't exist yet

- [ ] **Step 3: Implement the generator**

Create `packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart`:

```dart
import 'package:analyzer/dart/ast/ast.dart';

/// Generates `LocalWidgetBuilder` map code from `@rfwLocalWidget`-annotated classes.
///
/// Parses class constructors via AST and maps parameter types to
/// RFW [DataSource] API calls.
class LocalWidgetBuilderGenerator {
  /// Generates a Dart source string containing a `Map<String, LocalWidgetBuilder>`
  /// for all `@rfwLocalWidget`-annotated classes in [unit].
  ///
  /// Returns `null` if no annotated classes are found.
  String? generate(CompilationUnit unit, {required String source}) {
    final annotatedClasses = unit.declarations
        .whereType<ClassDeclaration>()
        .where(
          (c) => c.metadata.any(
            (a) =>
                a.name.name == 'rfwLocalWidget' ||
                a.name.name == 'RfwLocalWidget',
          ),
        )
        .toList();

    if (annotatedClasses.isEmpty) return null;

    final entries = <String>[];

    for (final classDecl in annotatedClasses) {
      final className = classDecl.name.lexeme;
      final constructor = _findConstructor(classDecl);
      if (constructor == null) continue;

      final params = _extractParams(constructor);
      final bodyLines = _generateBuilderBody(className, params);
      entries.add(bodyLines);
    }

    if (entries.isEmpty) return null;

    final buffer = StringBuffer();
    buffer.writeln(
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
    );
    buffer.writeln();
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:rfw/rfw.dart';");
    buffer.writeln();
    buffer.writeln(
      '/// Auto-generated [LocalWidgetBuilder] map.',
    );
    buffer.writeln(
      'Map<String, LocalWidgetBuilder> get generatedLocalWidgetBuilders => <String, LocalWidgetBuilder>{',
    );
    for (final entry in entries) {
      buffer.writeln(entry);
    }
    buffer.writeln('};');

    return buffer.toString();
  }

  ConstructorDeclaration? _findConstructor(ClassDeclaration classDecl) {
    // Prefer unnamed constructor
    for (final member in classDecl.members) {
      if (member is ConstructorDeclaration && member.name == null) {
        return member;
      }
    }
    // Fallback to first constructor
    for (final member in classDecl.members) {
      if (member is ConstructorDeclaration) {
        return member;
      }
    }
    return null;
  }

  List<_ParamInfo> _extractParams(ConstructorDeclaration constructor) {
    final params = <_ParamInfo>[];

    for (final param in constructor.parameters.parameters) {
      final normalParam = param is DefaultFormalParameter ? param.parameter : param;

      // Skip super.key
      if (normalParam is SuperFormalParameter) continue;

      String? name;
      String? typeName;
      bool isRequired = false;
      bool isNullable = false;
      String? defaultValue;

      if (normalParam is SimpleFormalParameter) {
        name = normalParam.name?.lexeme;
        final typeAnnotation = normalParam.type;
        if (typeAnnotation is NamedType) {
          typeName = typeAnnotation.name2.lexeme;
          isNullable = typeAnnotation.question != null;
          // Handle List<Widget>
          final typeArgs = typeAnnotation.typeArguments;
          if (typeName == 'List' && typeArgs != null) {
            final innerType = typeArgs.arguments.firstOrNull;
            if (innerType is NamedType) {
              typeName = 'List<${innerType.name2.lexeme}>';
            }
          }
        }
      }

      if (param is DefaultFormalParameter) {
        isRequired = param.isRequired;
        if (param.defaultValue != null) {
          defaultValue = param.defaultValue.toString();
        }
      } else {
        // Positional required params
        isRequired = true;
      }

      if (name == null || typeName == null) continue;
      if (name == 'key') continue;

      params.add(_ParamInfo(
        name: name,
        typeName: typeName,
        isRequired: isRequired,
        isNullable: isNullable,
        defaultValue: defaultValue,
      ));
    }

    return params;
  }

  String _generateBuilderBody(String className, List<_ParamInfo> params) {
    final buffer = StringBuffer();
    buffer.writeln("  '$className': (BuildContext context, DataSource source) {");

    // Generate variable declarations for List<Widget> params
    final listParams = params.where((p) => p.typeName == 'List<Widget>');
    for (final p in listParams) {
      buffer.writeln("    final ${p.name} = <Widget>[];");
      buffer.writeln(
        "    for (var i = 0; i < source.length(['${p.name}']); i++) {",
      );
      buffer.writeln(
        "      ${p.name}.add(source.child(['${p.name}', i]));",
      );
      buffer.writeln('    }');
    }

    buffer.writeln('    return $className(');

    for (final p in params) {
      final accessor = _paramAccessor(p);
      buffer.writeln('      ${p.name}: $accessor,');
    }

    buffer.writeln('    );');
    buffer.writeln('  },');

    return buffer.toString();
  }

  String _paramAccessor(_ParamInfo p) {
    return switch (p.typeName) {
      'Widget' when !p.isNullable => "source.child(['${p.name}'])",
      'Widget' => "source.optionalChild(['${p.name}'])",
      'List<Widget>' => p.name, // already declared as local variable
      'VoidCallback' => "source.voidHandler(['${p.name}'])",
      'String' when p.isRequired && p.defaultValue == null =>
        "source.v<String>(['${p.name}']) ?? ''",
      'String' when p.defaultValue != null =>
        "source.v<String>(['${p.name}']) ?? ${p.defaultValue}",
      'String' => "source.v<String>(['${p.name}'])",
      'int' when p.isRequired && p.defaultValue == null =>
        "source.v<int>(['${p.name}']) ?? 0",
      'int' when p.defaultValue != null =>
        "source.v<int>(['${p.name}']) ?? ${p.defaultValue}",
      'int' => "source.v<int>(['${p.name}'])",
      'double' when p.isRequired && p.defaultValue == null =>
        "source.v<double>(['${p.name}']) ?? 0.0",
      'double' when p.defaultValue != null =>
        "source.v<double>(['${p.name}']) ?? ${p.defaultValue}",
      'double' => "source.v<double>(['${p.name}'])",
      'bool' when p.isRequired && p.defaultValue == null =>
        "source.v<bool>(['${p.name}']) ?? false",
      'bool' when p.defaultValue != null =>
        "source.v<bool>(['${p.name}']) ?? ${p.defaultValue}",
      'bool' => "source.v<bool>(['${p.name}'])",
      _ => "source.v<${p.typeName}>(['${p.name}'])",
    };
  }
}

class _ParamInfo {
  final String name;
  final String typeName;
  final bool isRequired;
  final bool isNullable;
  final String? defaultValue;

  _ParamInfo({
    required this.name,
    required this.typeName,
    required this.isRequired,
    required this.isNullable,
    this.defaultValue,
  });
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/rfw_gen_builder && dart test test/local_widget_builder_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart
git add packages/rfw_gen_builder/test/local_widget_builder_test.dart
git commit -m "feat(rfw_gen_builder): add LocalWidgetBuilder generator with AST-based type mapping"
```

---

### Task 5: Create the Builder class and register it

**Files:**
- Create: `packages/rfw_gen_builder/lib/src/local_widget_builder_builder.dart`
- Modify: `packages/rfw_gen_builder/lib/builder.dart`
- Modify: `packages/rfw_gen_builder/build.yaml`

- [ ] **Step 1: Create builder class and register factory first (tests depend on these)**

Create `packages/rfw_gen_builder/lib/src/local_widget_builder_builder.dart` and add factory to `builder.dart` and `build.yaml` (see Steps 2-4 below), then write the integration test.

- [ ] **Step 2: Write the builder integration test**

Add to `packages/rfw_gen_builder/test/local_widget_builder_test.dart` (add these imports at the top of the file):

```dart
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:rfw_gen_builder/builder.dart';

// ... add to existing file's main():

  group('LocalWidgetBuilderBuilder (build_runner)', () {
    test('generates .rfw_library.dart from annotated class', () async {
      final result = await testBuilder(
        rfwLocalWidgetBuilder(BuilderOptions.empty),
        {
          'a|lib/widgets.dart': '''
import 'package:flutter/material.dart';

@rfwLocalWidget
class MyText extends StatelessWidget {
  final String text;

  const MyText({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Text(text);
}
''',
        },
        outputs: {
          'a|lib/widgets.rfw_library.dart': decodedMatches(
            allOf(
              contains('GENERATED CODE'),
              contains("'MyText'"),
              contains("source.v<String>(['text'])"),
              contains('generatedLocalWidgetBuilders'),
            ),
          ),
        },
      );
      expect(result.succeeded, isTrue);
    });

    test('skips files without @rfwLocalWidget', () async {
      final result = await testBuilder(
        rfwLocalWidgetBuilder(BuilderOptions.empty),
        {
          'a|lib/plain.dart': '''
class NotAnnotated extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox();
}
''',
        },
        outputs: {},
      );
      expect(result.succeeded, isTrue);
    });
  });
```

- [ ] **Step 3: Create the builder class**

Create `packages/rfw_gen_builder/lib/src/local_widget_builder_builder.dart`:

```dart
import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:build/build.dart';

import 'local_widget_builder_generator.dart';

/// A [Builder] that finds `@rfwLocalWidget`-annotated classes and
/// generates `.rfw_library.dart` files with [LocalWidgetBuilder] maps.
class LocalWidgetBuilderBuilder implements Builder {
  /// The build_runner options.
  final BuilderOptions options;

  /// Creates a builder for LocalWidgetBuilder generation.
  LocalWidgetBuilderBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.rfw_library.dart'],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final source = await buildStep.readAsString(buildStep.inputId);

    // Quick check: skip files that don't mention the annotation.
    if (!source.contains('rfwLocalWidget') &&
        !source.contains('RfwLocalWidget')) {
      return;
    }

    final parseResult = parseString(content: source);
    final generator = LocalWidgetBuilderGenerator();
    final output = generator.generate(parseResult.unit, source: source);

    if (output == null) return;

    // Prepend the relative import to the source file.
    final sourceFileName = buildStep.inputId.pathSegments.last;
    final fullOutput = output.replaceFirst(
      "import 'package:rfw/rfw.dart';",
      "import 'package:rfw/rfw.dart';\nimport '$sourceFileName';",
    );

    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfw_library.dart'),
      fullOutput,
    );
  }
}
```

- [ ] **Step 4: Register the builder factory**

Add to `packages/rfw_gen_builder/lib/builder.dart`:

```dart
import 'src/local_widget_builder_builder.dart';

/// Factory for the `@rfwLocalWidget` → `.rfw_library.dart` builder.
Builder rfwLocalWidgetBuilder(BuilderOptions options) =>
    LocalWidgetBuilderBuilder(options);
```

- [ ] **Step 5: Register in build.yaml**

Add to `packages/rfw_gen_builder/build.yaml`:

```yaml
  rfw_local_widget_builder:
    import: "package:rfw_gen_builder/builder.dart"
    builder_factories: ["rfwLocalWidgetBuilder"]
    build_extensions: {".dart": [".rfw_library.dart"]}
    auto_apply: dependents
    build_to: source
```

- [ ] **Step 6: Run the builder test**

Run: `cd packages/rfw_gen_builder && dart test test/local_widget_builder_test.dart`
Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
git add packages/rfw_gen_builder/lib/src/local_widget_builder_builder.dart
git add packages/rfw_gen_builder/lib/builder.dart
git add packages/rfw_gen_builder/build.yaml
git add packages/rfw_gen_builder/test/local_widget_builder_test.dart
git commit -m "feat(rfw_gen_builder): add LocalWidgetBuilder builder with build.yaml registration"
```

---

### Task 6: Run build_runner on example and verify

**Files:**
- Verify: `example/lib/custom/custom_widget_classes.rfw_library.dart` (auto-generated)

- [ ] **Step 1: Run build_runner**

Run: `cd example && dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `custom_widget_classes.rfw_library.dart` alongside existing outputs

- [ ] **Step 2: Verify generated file content**

Run: `cat example/lib/custom/custom_widget_classes.rfw_library.dart`
Expected: Contains all 13 widgets with correct DataSource mappings

- [ ] **Step 3: Verify generated file compiles**

Run: `cd example && dart analyze lib/custom/custom_widget_classes.rfw_library.dart`
Expected: No errors

- [ ] **Step 4: Commit generated file**

```bash
git add example/lib/custom/custom_widget_classes.rfw_library.dart
git commit -m "chore(example): add generated LocalWidgetBuilder file"
```

---

### Task 7: Wire up example app to use generated builders

**Files:**
- Modify: `example/lib/custom/custom_widget_builders.dart` — update to re-export generated
- Modify: `example/lib/main.dart` — verify imports still work
- Modify: `example/test/helpers/golden_test_helper.dart` — verify imports still work

Strategy: Replace the manual builders content with a re-export of the generated file. This preserves the existing import in `main.dart` and `golden_test_helper.dart`.

- [ ] **Step 1: Replace manual builders with generated re-export**

Replace entire content of `example/lib/custom/custom_widget_builders.dart`:

```dart
import 'package:rfw/rfw.dart';

import 'custom_widget_classes.rfw_library.dart';

/// Custom widget library name used in rfwtxt imports.
const customWidgetsLibraryName = LibraryName(<String>['custom', 'widgets']);

/// All custom widget [LocalWidgetBuilder]s for the example app.
///
/// Auto-generated from `@rfwLocalWidget`-annotated classes in
/// `custom_widget_classes.dart`.
final Map<String, LocalWidgetBuilder> customWidgetBuilders =
    generatedLocalWidgetBuilders;
```

- [ ] **Step 2: Verify the app compiles**

Run: `cd example && dart analyze`
Expected: No errors

- [ ] **Step 3: Run existing tests**

Run: `cd example && flutter test --exclude-tags golden`
Expected: All tests pass

- [ ] **Step 4: Verify all consumers compile**

All 4 files that import `custom_widget_builders.dart` must still work:
- `example/lib/main.dart`
- `example/lib/preview/preview_page.dart`
- `example/lib/preview/preview_app.dart`
- `example/test/helpers/golden_test_helper.dart`

Run: `cd example && dart analyze`
Expected: No errors across all files

- [ ] **Step 5: Note about golden tests**

The widget tree now has an extra StatelessWidget layer per custom widget (e.g., `CustomText` → `Text` instead of direct `Text`). Visual output is identical but golden test images will differ in pixel-level rendering. **Golden tests must be regenerated on Linux CI** — do NOT update golden images locally.

- [ ] **Step 6: Commit**

```bash
git add example/lib/custom/custom_widget_builders.dart
git commit -m "refactor(example): replace manual LocalWidgetBuilders with generated code"
```

---

### Task 8: Run all tests and final verification

- [ ] **Step 1: Run rfw_gen_builder tests**

Run: `cd packages/rfw_gen_builder && dart test`
Expected: All tests pass

- [ ] **Step 2: Run example tests**

Run: `cd example && flutter test --exclude-tags golden`
Expected: All tests pass

- [ ] **Step 3: Run analyzer on all packages**

Run: `dart analyze`
Expected: No errors

- [ ] **Step 4: Final commit with cleanup**

If any fixups needed, commit them.

```bash
git commit -m "test: verify all tests pass with generated LocalWidgetBuilders"
```

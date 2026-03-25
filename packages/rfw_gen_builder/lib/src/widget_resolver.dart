// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import 'widget_registry.dart';

/// Result of resolving a widget class via the analyzer.
class ResolveResult {
  /// The widget mapping suitable for rfwtxt conversion.
  final WidgetMapping widgetMapping;

  /// Detailed resolved widget information including param types.
  final ResolvedWidget resolvedWidget;

  const ResolveResult({
    required this.widgetMapping,
    required this.resolvedWidget,
  });
}

/// Detailed information about a resolved widget class.
class ResolvedWidget {
  /// The class name of the widget.
  final String className;

  /// The Dart import URI (e.g., 'package:foo/bar.dart').
  final String dartImport;

  /// The resolved constructor parameters (excluding key).
  final List<ResolvedParam> params;

  const ResolvedWidget({
    required this.className,
    required this.dartImport,
    required this.params,
  });
}

/// A resolved constructor parameter with type information.
class ResolvedParam {
  /// The parameter name.
  final String name;

  /// The resolved type category.
  final ResolvedParamType type;

  /// Whether this parameter is required.
  final bool isRequired;

  /// Whether this parameter is nullable.
  final bool isNullable;

  /// The default value expression as a string, if any.
  final String? defaultValue;

  const ResolvedParam({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNullable,
    this.defaultValue,
  });
}

/// Categorization of resolved parameter types.
enum ResolvedParamType {
  string,
  int,
  double,
  bool,
  widget,
  optionalWidget,
  widgetList,
  voidCallback,
  other,
}

/// Resolves widget class constructors using the Dart analyzer
/// and produces [WidgetMapping] and [ResolvedWidget] objects.
class WidgetResolver {
  /// Resolves a single widget class from a [LibraryElement].
  ///
  /// Returns `null` if [widgetName] is not found, is not a Widget subclass,
  /// or is abstract.
  ResolveResult? resolveFromLibrary(
    LibraryElement library,
    String widgetName,
  ) {
    final classElement = library.getClass(widgetName);
    if (classElement == null) return null;
    if (classElement.isAbstract) return null;
    if (!_isWidgetSubclass(classElement)) return null;

    final packageName = _extractPackageName(library);
    return _buildResult(classElement, packageName, library);
  }

  /// Resolves multiple widget classes from a [LibraryElement].
  ///
  /// Returns a map of widget name → [ResolveResult] for each successfully
  /// resolved widget. Widgets that cannot be resolved are omitted.
  Map<String, ResolveResult> batchResolve(
    LibraryElement library,
    Set<String> widgetNames,
  ) {
    final results = <String, ResolveResult>{};
    for (final name in widgetNames) {
      final result = resolveFromLibrary(library, name);
      if (result != null) {
        results[name] = result;
      }
    }
    return results;
  }

  /// Builds a [ResolveResult] from a [ClassElement].
  ResolveResult? _buildResult(
    ClassElement classElement,
    String packageName,
    LibraryElement library,
  ) {
    final constructor = classElement.unnamedConstructor;
    if (constructor == null) return null;

    final params = constructor.formalParameters;

    // Filter out key/super.key params
    final filteredParams = params.where((p) => !_isKeyParam(p)).toList();

    // Categorize params
    final widgetParams = <FormalParameterElement>[];
    final handlerParams = <FormalParameterElement>[];
    final regularParams = <FormalParameterElement>[];

    for (final p in filteredParams) {
      if (_isVoidCallbackType(p.type)) {
        handlerParams.add(p);
      } else if (_isWidgetType(p.type)) {
        widgetParams.add(p);
      } else if (_isWidgetListType(p.type)) {
        widgetParams.add(p);
      } else {
        regularParams.add(p);
      }
    }

    // Infer child type and extract named slots
    final childTypeResult = _inferChildType(widgetParams);
    final childType = childTypeResult.childType;
    final childParam = childTypeResult.childParam;
    final namedSlots = childTypeResult.namedSlots;

    // Build param mappings (only regular params, not child/handler/named slots)
    final paramMappings = <String, ParamMapping>{};
    for (final p in regularParams) {
      final name = p.name;
      if (name == null) continue;
      paramMappings[name] = ParamMapping.direct(name);
    }

    // Build handler set
    final handlerSet = <String>{};
    for (final p in handlerParams) {
      final name = p.name;
      if (name == null) continue;
      handlerSet.add(name);
    }

    // Build named child slots map
    final namedChildSlots = <String, bool>{};
    for (final slot in namedSlots) {
      final name = slot.name;
      if (name == null) continue;
      namedChildSlots[name] = _isWidgetListType(slot.type);
    }

    // Determine rfwName and import
    // rfwName is just the class name — the import statement handles library scoping.
    final rfwName = classElement.name!;
    final importName = packageName;

    final widgetMapping = WidgetMapping(
      rfwName: rfwName,
      params: paramMappings,
      import: importName,
      childType: childType,
      childParam: childParam,
      handlerParams: handlerSet,
      namedChildSlots: namedChildSlots,
    );

    // Build ResolvedWidget
    final resolvedParams = <ResolvedParam>[];
    for (final p in filteredParams) {
      final name = p.name;
      if (name == null) continue;
      resolvedParams.add(ResolvedParam(
        name: name,
        type: _resolveParamType(p.type),
        isRequired: p.isRequired,
        isNullable: p.type.nullabilitySuffix == NullabilitySuffix.question,
        defaultValue: p.hasDefaultValue ? p.defaultValueCode : null,
      ));
    }

    final dartImport = library.uri.toString();

    final resolvedWidget = ResolvedWidget(
      className: classElement.name!,
      dartImport: dartImport,
      params: resolvedParams,
    );

    return ResolveResult(
      widgetMapping: widgetMapping,
      resolvedWidget: resolvedWidget,
    );
  }

  /// Checks if a [ClassElement] is a subclass of Widget
  /// (StatelessWidget or StatefulWidget).
  bool _isWidgetSubclass(ClassElement classElement) {
    final supertype = classElement.supertype;
    if (supertype == null) return false;

    // Check direct supertype and all supertypes
    if (supertype.element.name == 'Widget' ||
        supertype.element.name == 'StatelessWidget' ||
        supertype.element.name == 'StatefulWidget') {
      return true;
    }

    return supertype.allSupertypes.any(
      (s) =>
          s.element.name == 'Widget' ||
          s.element.name == 'StatelessWidget' ||
          s.element.name == 'StatefulWidget',
    );
  }

  /// Checks if a parameter is `key` or `super.key`.
  bool _isKeyParam(FormalParameterElement param) {
    if (param is SuperFormalParameterElement) return true;
    final name = param.name;
    if (name == 'key') {
      final typeName = param.type.getDisplayString();
      if (typeName.contains('Key')) return true;
    }
    return false;
  }

  /// Checks if a [DartType] is a Widget type (Widget or its subclasses).
  bool _isWidgetType(DartType type) {
    if (type is InterfaceType) {
      final name = type.element.name;
      if (name == 'Widget' ||
          name == 'StatelessWidget' ||
          name == 'StatefulWidget') {
        return true;
      }
      return type.allSupertypes.any(
        (s) =>
            s.element.name == 'Widget' ||
            s.element.name == 'StatelessWidget' ||
            s.element.name == 'StatefulWidget',
      );
    }
    return false;
  }

  /// Checks if a [DartType] is a `List<Widget>` type.
  bool _isWidgetListType(DartType type) {
    if (type is InterfaceType && type.element.name == 'List') {
      if (type.typeArguments.length == 1) {
        return _isWidgetType(type.typeArguments.first);
      }
    }
    return false;
  }

  /// Checks if a [DartType] is VoidCallback or `void Function()`.
  bool _isVoidCallbackType(DartType type) {
    // Check for VoidCallback typedef alias
    final alias = type.alias;
    if (alias != null && alias.element.name == 'VoidCallback') {
      return true;
    }

    // Check for raw void Function() type
    if (type is FunctionType) {
      final returnType = type.returnType;
      if (returnType is VoidType && type.formalParameters.isEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Extracts the package name from a [LibraryElement]'s URI.
  String _extractPackageName(LibraryElement library) {
    final uri = library.uri;
    if (uri.scheme == 'package') {
      return uri.pathSegments.first;
    }
    // Fallback: use the library name or a default
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'unknown';
  }

  /// Infers the [ChildType] from widget-type parameters.
  ///
  /// Priority:
  /// 1. `List<Widget>` → `childList`
  /// 2. 1 required `Widget` named `child` → `child` (+ other Widget? → namedSlots)
  /// 3. 1 `Widget?` named `child` (no others) → `optionalChild`
  /// 4. Multiple `Widget?` → `namedSlots`
  /// 5. None → `none`
  _ChildTypeResult _inferChildType(List<FormalParameterElement> widgetParams) {
    if (widgetParams.isEmpty) {
      return const _ChildTypeResult(ChildType.none, null, []);
    }

    // Check for List<Widget> first (highest priority)
    final listWidgetParams =
        widgetParams.where((p) => _isWidgetListType(p.type)).toList();
    if (listWidgetParams.isNotEmpty) {
      final listParam = listWidgetParams.first;
      return _ChildTypeResult(
        ChildType.childList,
        listParam.name,
        [],
      );
    }

    // Find required Widget named 'child'
    final requiredChildParam = widgetParams
        .where((p) =>
            p.name == 'child' &&
            p.isRequired &&
            _isWidgetType(p.type) &&
            !_isWidgetListType(p.type))
        .toList();

    if (requiredChildParam.isNotEmpty) {
      // Other Widget? params become named slots
      final otherWidgetParams = widgetParams
          .where((p) => p.name != 'child' && !_isWidgetListType(p.type))
          .toList();
      return _ChildTypeResult(
        ChildType.child,
        'child',
        otherWidgetParams,
      );
    }

    // Check for optional Widget? named 'child' with no other widget params
    final optionalChildParam = widgetParams
        .where((p) =>
            p.name == 'child' &&
            !p.isRequired &&
            _isWidgetType(p.type) &&
            !_isWidgetListType(p.type))
        .toList();

    final otherNonListWidgetParams = widgetParams
        .where((p) =>
            p.name != 'child' &&
            !_isWidgetListType(p.type) &&
            _isWidgetType(p.type))
        .toList();

    if (optionalChildParam.isNotEmpty && otherNonListWidgetParams.isEmpty) {
      return _ChildTypeResult(
        ChildType.optionalChild,
        'child',
        [],
      );
    }

    // Multiple Widget? params → namedSlots
    final allNonListWidgetParams = widgetParams
        .where((p) => !_isWidgetListType(p.type) && _isWidgetType(p.type))
        .toList();

    if (allNonListWidgetParams.length >= 2 ||
        (optionalChildParam.isNotEmpty &&
            otherNonListWidgetParams.isNotEmpty)) {
      return _ChildTypeResult(
        ChildType.namedSlots,
        null,
        allNonListWidgetParams,
      );
    }

    // Single Widget? (not named 'child')
    if (allNonListWidgetParams.length == 1) {
      return _ChildTypeResult(
        ChildType.namedSlots,
        null,
        allNonListWidgetParams,
      );
    }

    return const _ChildTypeResult(ChildType.none, null, []);
  }

  /// Resolves a [DartType] to a [ResolvedParamType].
  ResolvedParamType _resolveParamType(DartType type) {
    if (_isVoidCallbackType(type)) return ResolvedParamType.voidCallback;
    if (_isWidgetListType(type)) return ResolvedParamType.widgetList;
    if (_isWidgetType(type)) {
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        return ResolvedParamType.optionalWidget;
      }
      return ResolvedParamType.widget;
    }

    if (type is InterfaceType) {
      final name = type.element.name;
      switch (name) {
        case 'String':
          return ResolvedParamType.string;
        case 'int':
          return ResolvedParamType.int;
        case 'double':
          return ResolvedParamType.double;
        case 'bool':
          return ResolvedParamType.bool;
      }
    }

    // Check for dart:core types that might not be InterfaceType
    final displayString = type.getDisplayString();
    if (displayString == 'String' || displayString == 'String?') {
      return ResolvedParamType.string;
    }
    if (displayString == 'int' || displayString == 'int?') {
      return ResolvedParamType.int;
    }
    if (displayString == 'double' || displayString == 'double?') {
      return ResolvedParamType.double;
    }
    if (displayString == 'bool' || displayString == 'bool?') {
      return ResolvedParamType.bool;
    }

    return ResolvedParamType.other;
  }
}

/// Internal result of child type inference.
class _ChildTypeResult {
  final ChildType childType;
  final String? childParam;
  final List<FormalParameterElement> namedSlots;

  const _ChildTypeResult(this.childType, this.childParam, this.namedSlots);
}

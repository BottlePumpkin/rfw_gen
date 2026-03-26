// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';

/// Resolves `Icons.xxx` codepoints at build time using the Dart analyzer.
///
/// When `Icons.thermostat` appears in user code, the analyzer can evaluate
/// the constant to extract its `codePoint` integer — no hardcoded map needed.
class IconResolver {
  final ClassElement _iconsClass;

  IconResolver(this._iconsClass);

  /// Resolves [name] to a Material Icon codepoint, or `null` if not found.
  ///
  /// Uses `computeConstantValue()` to evaluate the `IconData` constant and
  /// extract its `codePoint` field.
  int? resolve(String name) {
    final field = _iconsClass.getField(name);
    if (field == null || !field.isConst || !field.isStatic) return null;
    final value = field.computeConstantValue();
    if (value == null) return null;
    return value.getField('codePoint')?.toIntValue();
  }

  /// Finds the `Icons` class from a [LibraryElement] by searching
  /// its imports and re-exports (e.g., `package:flutter/material.dart`).
  static ClassElement? findIconsClass(LibraryElement library) {
    for (final libImport in library.firstFragment.libraryImports) {
      final imported = libImport.importedLibrary;
      if (imported == null) continue;

      final iconsClass = imported.getClass('Icons');
      if (iconsClass != null) return iconsClass;

      for (final reExported in imported.exportedLibraries) {
        final result = _searchLibrary(reExported, depth: 0);
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Recursively searches a library and its re-exports for the `Icons` class.
  /// Limited to depth 3 to avoid excessive traversal.
  static ClassElement? _searchLibrary(LibraryElement library, {int depth = 0}) {
    if (depth > 3) return null;
    final iconsClass = library.getClass('Icons');
    if (iconsClass != null) return iconsClass;
    for (final reExported in library.exportedLibraries) {
      final result = _searchLibrary(reExported, depth: depth + 1);
      if (result != null) return result;
    }
    return null;
  }
}

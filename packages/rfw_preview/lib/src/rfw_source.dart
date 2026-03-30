import 'dart:io';
import 'dart:typed_data';

import 'package:rfw/rfw.dart';

/// Source for RFW widget library data.
///
/// Defines how to load the widget library — from an asset bundle,
/// an rfwtxt string, a local file, or raw binary bytes.
sealed class RfwSource {
  const RfwSource({required this.library});

  /// The library name under which this source is registered in the [Runtime].
  final LibraryName library;

  /// Load from a `.rfw` binary asset in the app bundle.
  ///
  /// ```dart
  /// RfwSource.asset(
  ///   'assets/custom_widgets.rfw',
  ///   library: LibraryName(['custom']),
  /// )
  /// ```
  const factory RfwSource.asset(
    String path, {
    required LibraryName library,
  }) = RfwAssetSource;

  /// Load from an rfwtxt string directly.
  ///
  /// Useful for hot-reload workflows during development.
  ///
  /// ```dart
  /// RfwSource.text(
  ///   'widget myWidget = Text(text: "Hello");',
  ///   library: LibraryName(['custom']),
  /// )
  /// ```
  const factory RfwSource.text(
    String rfwtxt, {
    required LibraryName library,
  }) = RfwTextSource;

  /// Load from raw `.rfw` binary bytes.
  ///
  /// ```dart
  /// RfwSource.binary(
  ///   bytes,
  ///   library: LibraryName(['custom']),
  /// )
  /// ```
  const factory RfwSource.binary(
    Uint8List bytes, {
    required LibraryName library,
  }) = RfwBinarySource;

  /// Load from a local `.rfwtxt` file on disk.
  ///
  /// Reads the file as a UTF-8 string and parses it as rfwtxt.
  /// Useful during development to preview generated `.rfwtxt` files
  /// without adding them to the asset bundle.
  ///
  /// ```dart
  /// RfwSource.file(
  ///   'lib/widgets.rfwtxt',
  ///   library: LibraryName(['main']),
  /// )
  /// ```
  const factory RfwSource.file(
    String path, {
    required LibraryName library,
  }) = RfwFileSource;
}

/// Loads RFW library from a `.rfw` binary asset.
final class RfwAssetSource extends RfwSource {
  const RfwAssetSource(this.path, {required super.library});

  /// Asset path (e.g., `'assets/custom_widgets.rfw'`).
  final String path;
}

/// Loads RFW library from an rfwtxt string.
final class RfwTextSource extends RfwSource {
  const RfwTextSource(this.rfwtxt, {required super.library});

  /// The rfwtxt source string.
  final String rfwtxt;
}

/// Loads RFW library from raw binary bytes.
final class RfwBinarySource extends RfwSource {
  const RfwBinarySource(this.bytes, {required super.library});

  /// The raw `.rfw` binary data.
  final Uint8List bytes;
}

/// Loads RFW library from a local `.rfwtxt` file.
final class RfwFileSource extends RfwSource {
  const RfwFileSource(this.path, {required super.library});

  /// File path to a `.rfwtxt` file (e.g., `'lib/widgets.rfwtxt'`).
  final String path;

  /// Reads the file content synchronously.
  String readAsString() => File(path).readAsStringSync();
}

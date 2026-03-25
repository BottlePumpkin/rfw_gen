/// Dev preview widget for rfw_gen.
///
/// Provides [RfwPreview], a convenience widget that renders generated
/// rfwtxt with automatic [Runtime] setup and custom widget support.
library;

export 'package:rfw/rfw.dart'
    show
        DataSource,
        DynamicContent,
        DynamicMap,
        FullyQualifiedWidgetName,
        LibraryName,
        LocalWidgetBuilder,
        LocalWidgetLibrary,
        Runtime;

export 'src/rfw_preview_widget.dart';
export 'src/rfw_source.dart';

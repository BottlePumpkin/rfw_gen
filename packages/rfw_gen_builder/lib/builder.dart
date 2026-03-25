import 'package:build/build.dart';

import 'src/local_widget_builder_builder.dart';
import 'src/rfw_widget_builder.dart';

/// Factory function for the `build_runner` integration.
Builder rfwWidgetBuilder(BuilderOptions options) => RfwWidgetBuilder(options);

/// Factory function for the LocalWidgetBuilder generator.
Builder rfwLocalWidgetBuilder(BuilderOptions options) =>
    LocalWidgetBuilderBuilder(options);

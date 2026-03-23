import 'package:build/build.dart';

import 'src/rfw_widget_builder.dart';

/// Factory function for the `build_runner` integration.
Builder rfwWidgetBuilder(BuilderOptions options) => RfwWidgetBuilder(options);

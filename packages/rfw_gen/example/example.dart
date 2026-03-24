// ignore_for_file: depend_on_referenced_packages
import 'package:rfw_gen/rfw_gen.dart';

/// Annotate a top-level function with @RfwWidget to generate RFW output.
///
/// Run: dart run build_runner build
/// Output: example.rfwtxt + example.rfw
@RfwWidget('greeting')
Widget buildGreeting() {
  return Container(
    color: Color(0xFF2196F3),
    padding: EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Hello, RFW!'),
        Text(DataRef('user.name')),
      ],
    ),
  );
}

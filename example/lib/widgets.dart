import 'package:flutter/widgets.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('greeting')
Widget buildGreeting() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Hello, RFW!'),
      SizedBox(height: 16.0),
      Container(
        color: Color(0xFF2196F3),
        padding: EdgeInsets.all(16.0),
        child: Text('Welcome'),
      ),
    ],
  );
}

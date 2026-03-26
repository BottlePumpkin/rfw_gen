import 'package:flutter/material.dart';

class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget({super.key, required this.condition, required this.childIfTrue, required this.childIfFalse});
  final bool condition;
  final Widget childIfTrue;
  final Widget childIfFalse;

  @override
  Widget build(BuildContext context) => condition ? childIfTrue : childIfFalse;
}

import 'package:flutter/material.dart';

class MystiqueSpinner extends StatelessWidget {
  const MystiqueSpinner({super.key, this.size = 'medium'});
  final String size;
  double get _dimension => switch (size) { 'small' => 16.0, 'medium' => 24.0, 'large' => 40.0, _ => 24.0 };

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: _dimension, height: _dimension, child: const CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF237AF2))));
  }
}

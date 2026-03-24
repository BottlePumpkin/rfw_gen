import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('RFW-only widget classes', () {
    test('SizedBoxShrink can be constructed', () {
      const w = SizedBoxShrink();
      expect(w.child, isNull);
    });

    test('SizedBoxShrink with child', () {
      const w = SizedBoxShrink(child: 'placeholder');
      expect(w.child, equals('placeholder'));
    });

    test('SizedBoxExpand can be constructed', () {
      const w = SizedBoxExpand();
      expect(w.child, isNull);
    });

    test('Rotation accepts all params', () {
      const w = Rotation(
        turns: 0.25,
        alignment: 'center',
        duration: 300,
        curve: 'easeIn',
        child: 'placeholder',
        onEnd: 'handler',
      );
      expect(w.turns, equals(0.25));
      expect(w.alignment, equals('center'));
      expect(w.duration, equals(300));
      expect(w.curve, equals('easeIn'));
      expect(w.child, equals('placeholder'));
      expect(w.onEnd, equals('handler'));
    });

    test('Scale accepts all params', () {
      const w = Scale(
        scale: 2.0,
        alignment: 'center',
        duration: 300,
        curve: 'easeOut',
        child: 'placeholder',
        onEnd: 'handler',
      );
      expect(w.scale, equals(2.0));
      expect(w.child, equals('placeholder'));
    });

    test('AnimationDefaults accepts all params', () {
      const w = AnimationDefaults(
        duration: 600,
        curve: 'fastOutSlowIn',
        child: 'placeholder',
      );
      expect(w.duration, equals(600));
      expect(w.curve, equals('fastOutSlowIn'));
      expect(w.child, equals('placeholder'));
    });
  });
}

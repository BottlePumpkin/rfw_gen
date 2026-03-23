import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

Expression parseExpression(String code) {
  final result = parseString(content: 'final x = $code;');
  final unit = result.unit;
  final decl = unit.declarations.first as TopLevelVariableDeclaration;
  return decl.variables.variables.first.initializer!;
}

void main() {
  late ExpressionConverter converter;

  setUp(() {
    converter = ExpressionConverter();
  });

  group('String literals', () {
    test('converts single-quoted string', () {
      final expr = parseExpression("'hello'");
      final result = converter.convert(expr);
      expect(result, isA<IrStringValue>());
      expect((result as IrStringValue).value, equals('hello'));
    });

    test('converts empty string', () {
      final expr = parseExpression("''");
      final result = converter.convert(expr);
      expect(result, isA<IrStringValue>());
      expect((result as IrStringValue).value, equals(''));
    });
  });

  group('Double literals', () {
    test('converts double value', () {
      final expr = parseExpression('24.0');
      final result = converter.convert(expr);
      expect(result, isA<IrNumberValue>());
      expect((result as IrNumberValue).value, equals(24.0));
    });

    test('converts negative double', () {
      // Negative literals parse as PrefixExpression('-', 3.14)
      final expr = parseExpression('-3.14');
      final result = converter.convert(expr);
      expect(result, isA<IrNumberValue>());
      expect((result as IrNumberValue).value, equals(-3.14));
    });
  });

  group('Int literals', () {
    test('converts integer value', () {
      final expr = parseExpression('42');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(42));
    });

    test('converts hex literal', () {
      final expr = parseExpression('0xFF000000');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(0xFF000000));
    });

    test('converts zero', () {
      final expr = parseExpression('0');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(0));
    });
  });

  group('Boolean literals', () {
    test('converts true', () {
      final expr = parseExpression('true');
      final result = converter.convert(expr);
      expect(result, isA<IrBoolValue>());
      expect((result as IrBoolValue).value, isTrue);
    });

    test('converts false', () {
      final expr = parseExpression('false');
      final result = converter.convert(expr);
      expect(result, isA<IrBoolValue>());
      expect((result as IrBoolValue).value, isFalse);
    });
  });

  group('List literals', () {
    test('converts empty list', () {
      final expr = parseExpression('[]');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      expect((result as IrListValue).values, isEmpty);
    });

    test('converts list of doubles', () {
      final expr = parseExpression('[1.0, 2.0, 3.0]');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(3));
      expect((list.values[0] as IrNumberValue).value, equals(1.0));
      expect((list.values[1] as IrNumberValue).value, equals(2.0));
      expect((list.values[2] as IrNumberValue).value, equals(3.0));
    });

    test('converts list of ints', () {
      final expr = parseExpression('[1, 2]');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(2));
      expect((list.values[0] as IrIntValue).value, equals(1));
      expect((list.values[1] as IrIntValue).value, equals(2));
    });
  });

  group('Color constructor', () {
    test('extracts int argument from Color(0xFFxxxxxx)', () {
      final expr = parseExpression('Color(0xFF112233)');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(0xFF112233));
    });

    test('extracts int argument from Color with decimal', () {
      final expr = parseExpression('Color(4278190080)');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(4278190080));
    });
  });

  group('EdgeInsets.all', () {
    test('converts EdgeInsets.all(16.0) to list with single value', () {
      final expr = parseExpression('EdgeInsets.all(16.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      expect((list.values[0] as IrNumberValue).value, equals(16.0));
    });

    test('converts EdgeInsets.all with int', () {
      final expr = parseExpression('EdgeInsets.all(8)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      // int gets promoted to double for EdgeInsets
      expect(list.values[0], isA<IrNumberValue>());
      expect((list.values[0] as IrNumberValue).value, equals(8.0));
    });
  });

  group('EdgeInsets.symmetric', () {
    test('converts symmetric with both horizontal and vertical', () {
      final expr =
          parseExpression('EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      // [left, top, right, bottom] = [h, v, h, v]
      expect(list.values, hasLength(4));
      expect((list.values[0] as IrNumberValue).value, equals(8.0));
      expect((list.values[1] as IrNumberValue).value, equals(4.0));
      expect((list.values[2] as IrNumberValue).value, equals(8.0));
      expect((list.values[3] as IrNumberValue).value, equals(4.0));
    });

    test('converts symmetric with only horizontal', () {
      final expr = parseExpression('EdgeInsets.symmetric(horizontal: 10.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(4));
      expect((list.values[0] as IrNumberValue).value, equals(10.0));
      expect((list.values[1] as IrNumberValue).value, equals(0.0));
      expect((list.values[2] as IrNumberValue).value, equals(10.0));
      expect((list.values[3] as IrNumberValue).value, equals(0.0));
    });

    test('converts symmetric with only vertical', () {
      final expr = parseExpression('EdgeInsets.symmetric(vertical: 5.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(4));
      expect((list.values[0] as IrNumberValue).value, equals(0.0));
      expect((list.values[1] as IrNumberValue).value, equals(5.0));
      expect((list.values[2] as IrNumberValue).value, equals(0.0));
      expect((list.values[3] as IrNumberValue).value, equals(5.0));
    });
  });

  group('EdgeInsets.only', () {
    test('converts only with all named params', () {
      final expr = parseExpression(
        'EdgeInsets.only(left: 1.0, top: 2.0, right: 3.0, bottom: 4.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(4));
      expect((list.values[0] as IrNumberValue).value, equals(1.0));
      expect((list.values[1] as IrNumberValue).value, equals(2.0));
      expect((list.values[2] as IrNumberValue).value, equals(3.0));
      expect((list.values[3] as IrNumberValue).value, equals(4.0));
    });

    test('converts only with partial named params (defaults to 0)', () {
      final expr = parseExpression('EdgeInsets.only(left: 16.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(4));
      expect((list.values[0] as IrNumberValue).value, equals(16.0));
      expect((list.values[1] as IrNumberValue).value, equals(0.0));
      expect((list.values[2] as IrNumberValue).value, equals(0.0));
      expect((list.values[3] as IrNumberValue).value, equals(0.0));
    });
  });

  group('EdgeInsets.fromLTRB', () {
    test('converts fromLTRB with four positional args', () {
      final expr = parseExpression('EdgeInsets.fromLTRB(1.0, 2.0, 3.0, 4.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(4));
      expect((list.values[0] as IrNumberValue).value, equals(1.0));
      expect((list.values[1] as IrNumberValue).value, equals(2.0));
      expect((list.values[2] as IrNumberValue).value, equals(3.0));
      expect((list.values[3] as IrNumberValue).value, equals(4.0));
    });
  });

  group('Enum values', () {
    test('converts MainAxisAlignment.center', () {
      final expr = parseExpression('MainAxisAlignment.center');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, equals('center'));
    });

    test('converts CrossAxisAlignment.start', () {
      final expr = parseExpression('CrossAxisAlignment.start');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, equals('start'));
    });

    test('converts TextAlign.left', () {
      final expr = parseExpression('TextAlign.left');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, equals('left'));
    });

    test('converts MainAxisSize.min', () {
      final expr = parseExpression('MainAxisSize.min');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, equals('min'));
    });

    test('converts BoxFit.cover', () {
      final expr = parseExpression('BoxFit.cover');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, equals('cover'));
    });

    test('converts all known enum prefixes', () {
      final knownEnums = {
        'VerticalDirection.up': 'up',
        'TextOverflow.ellipsis': 'ellipsis',
        'TextDirection.ltr': 'ltr',
        'Axis.horizontal': 'horizontal',
        'Clip.hardEdge': 'hardEdge',
        'StackFit.expand': 'expand',
        'FlexFit.tight': 'tight',
        'WrapAlignment.center': 'center',
        'WrapCrossAlignment.start': 'start',
      };

      for (final entry in knownEnums.entries) {
        final expr = parseExpression(entry.key);
        final result = converter.convert(expr);
        expect(result, isA<IrEnumValue>(), reason: 'Failed for ${entry.key}');
        expect(
          (result as IrEnumValue).value,
          equals(entry.value),
          reason: 'Failed for ${entry.key}',
        );
      }
    });
  });

  group('BorderRadius', () {
    test('converts BorderRadius.circular(8) to single-element radius list', () {
      final expr = parseExpression('BorderRadius.circular(8)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      final radius = list.values[0] as IrMapValue;
      expect((radius.entries['x'] as IrNumberValue).value, equals(8.0));
    });

    test('converts BorderRadius.circular with double', () {
      final expr = parseExpression('BorderRadius.circular(12.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      final radius = list.values[0] as IrMapValue;
      expect((radius.entries['x'] as IrNumberValue).value, equals(12.0));
    });

    test('converts BorderRadius.only with all corners', () {
      final expr = parseExpression(
        'BorderRadius.only('
        '  topLeft: Radius.circular(4),'
        '  topRight: Radius.circular(8),'
        '  bottomLeft: Radius.circular(12),'
        '  bottomRight: Radius.circular(16),'
        ')',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(4));
      expect((list.values[0] as IrMapValue).entries['x'], isA<IrNumberValue>());
    });

    test('converts BorderRadius.zero', () {
      final expr = parseExpression('BorderRadius.zero');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      final radius = list.values[0] as IrMapValue;
      expect((radius.entries['x'] as IrNumberValue).value, equals(0.0));
    });
  });

  group('Duration', () {
    test('converts Duration(milliseconds: 300) to int', () {
      final expr = parseExpression('Duration(milliseconds: 300)');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(300));
    });

    test('converts Duration(milliseconds: 0)', () {
      final expr = parseExpression('Duration(milliseconds: 0)');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(0));
    });
  });

  group('Curves', () {
    test('converts Curves.easeIn to string', () {
      final expr = parseExpression('Curves.easeIn');
      final result = converter.convert(expr);
      expect(result, isA<IrStringValue>());
      expect((result as IrStringValue).value, equals('easeIn'));
    });

    test('converts Curves.linear to string', () {
      final expr = parseExpression('Curves.linear');
      final result = converter.convert(expr);
      expect(result, isA<IrStringValue>());
      expect((result as IrStringValue).value, equals('linear'));
    });

    test('converts Curves.bounceOut to string', () {
      final expr = parseExpression('Curves.bounceOut');
      final result = converter.convert(expr);
      expect(result, isA<IrStringValue>());
      expect((result as IrStringValue).value, equals('bounceOut'));
    });
  });

  group('Unsupported expressions', () {
    test('throws for variable reference', () {
      final expr = parseExpression('myVariable');
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('throws for unknown function call', () {
      final expr = parseExpression('unknownFunc(1, 2)');
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('throws for unknown prefixed identifier', () {
      final expr = parseExpression('UnknownType.value');
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('UnsupportedExpressionError stores message', () {
      final error = UnsupportedExpressionError('test message', offset: 10);
      expect(error.message, equals('test message'));
      expect(error.offset, equals(10));
    });

    test('UnsupportedExpressionError is an Exception', () {
      final error = UnsupportedExpressionError('test');
      expect(error, isA<Exception>());
    });
  });
}

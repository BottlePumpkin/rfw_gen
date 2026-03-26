import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw_gen_builder/src/expression_converter.dart';
import 'package:rfw_gen_builder/src/ir.dart';
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
      final expr = parseExpression(
          'EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)');
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

  group('EdgeInsetsDirectional', () {
    test('converts EdgeInsetsDirectional.all(8)', () {
      final expr = parseExpression('EdgeInsetsDirectional.all(8.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = (result as IrListValue).values;
      expect(list.length, 1);
      expect((list[0] as IrNumberValue).value, 8.0);
    });

    test('converts EdgeInsetsDirectional.only(start: 16)', () {
      final expr = parseExpression('EdgeInsetsDirectional.only(start: 16.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = (result as IrListValue).values;
      expect((list[0] as IrNumberValue).value, 16.0); // start
      expect((list[1] as IrNumberValue).value, 0.0); // top
      expect((list[2] as IrNumberValue).value, 0.0); // end
      expect((list[3] as IrNumberValue).value, 0.0); // bottom
    });

    test('converts EdgeInsetsDirectional.fromSTEB', () {
      final expr = parseExpression(
        'EdgeInsetsDirectional.fromSTEB(8.0, 16.0, 8.0, 16.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = (result as IrListValue).values;
      expect(list.length, 4);
      expect((list[0] as IrNumberValue).value, 8.0);
      expect((list[1] as IrNumberValue).value, 16.0);
      expect((list[2] as IrNumberValue).value, 8.0);
      expect((list[3] as IrNumberValue).value, 16.0);
    });

    test('converts EdgeInsetsDirectional.symmetric', () {
      final expr = parseExpression(
        'EdgeInsetsDirectional.symmetric(horizontal: 12.0, vertical: 6.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = (result as IrListValue).values;
      expect(list.length, 4);
      expect((list[0] as IrNumberValue).value, 12.0); // start=horizontal
      expect((list[1] as IrNumberValue).value, 6.0); // top=vertical
      expect((list[2] as IrNumberValue).value, 12.0); // end=horizontal
      expect((list[3] as IrNumberValue).value, 6.0); // bottom=vertical
    });

    test('converts EdgeInsetsDirectional.only with all params', () {
      final expr = parseExpression(
        'EdgeInsetsDirectional.only(start: 1.0, top: 2.0, end: 3.0, bottom: 4.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = (result as IrListValue).values;
      expect(list.length, 4);
      expect((list[0] as IrNumberValue).value, 1.0);
      expect((list[1] as IrNumberValue).value, 2.0);
      expect((list[2] as IrNumberValue).value, 3.0);
      expect((list[3] as IrNumberValue).value, 4.0);
    });

    test('converts const EdgeInsetsDirectional.all(8)', () {
      final expr = parseExpression('const EdgeInsetsDirectional.all(8.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = (result as IrListValue).values;
      expect(list.length, 1);
      expect((list[0] as IrNumberValue).value, 8.0);
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

    test('converts ImageRepeat.repeat', () {
      final expr = parseExpression('ImageRepeat.repeat');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, equals('repeat'));
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

    test('Duration(seconds: 1) converts to 1000ms', () {
      final expr = parseExpression('Duration(seconds: 1)');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, 1000);
    });

    test('Duration(minutes: 1) converts to 60000ms', () {
      final expr = parseExpression('Duration(minutes: 1)');
      final result = converter.convert(expr);
      expect((result as IrIntValue).value, 60000);
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

  group('ImageProvider', () {
    test('converts NetworkImage to map with source', () {
      final expr =
          parseExpression("NetworkImage('https://example.com/img.png')");
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['source'] as IrStringValue).value,
          equals('https://example.com/img.png'));
      expect((map.entries['scale'] as IrNumberValue).value, equals(1.0));
    });

    test('converts AssetImage to map with source', () {
      final expr = parseExpression("AssetImage('assets/logo.png')");
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['source'] as IrStringValue).value,
          equals('assets/logo.png'));
      expect((map.entries['scale'] as IrNumberValue).value, equals(1.0));
    });

    test('converts NetworkImage with scale', () {
      final expr = parseExpression(
          "NetworkImage('https://example.com/img.png', scale: 2.0)");
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['scale'] as IrNumberValue).value, equals(2.0));
    });
  });

  group('SliverGridDelegate', () {
    test('converts SliverGridDelegateWithFixedCrossAxisCount', () {
      final expr = parseExpression(
        'SliverGridDelegateWithFixedCrossAxisCount('
        '  crossAxisCount: 2,'
        '  mainAxisSpacing: 4.0,'
        '  crossAxisSpacing: 4.0,'
        ')',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['crossAxisCount'] as IrIntValue).value, equals(2));
      expect(
          (map.entries['mainAxisSpacing'] as IrNumberValue).value, equals(4.0));
      expect((map.entries['crossAxisSpacing'] as IrNumberValue).value,
          equals(4.0));
    });

    test('converts SliverGridDelegateWithMaxCrossAxisExtent', () {
      final expr = parseExpression(
        'SliverGridDelegateWithMaxCrossAxisExtent('
        '  maxCrossAxisExtent: 200.0,'
        ')',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['maxCrossAxisExtent'] as IrNumberValue).value,
          equals(200.0));
    });
  });

  group('RfwIcon', () {
    test('converts RfwIcon.home to iconData map', () {
      final expr = parseExpression('RfwIcon.home');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect(map.entries['icon'], isA<IrIntValue>());
      expect(map.entries['fontFamily'], isA<IrStringValue>());
      expect((map.entries['fontFamily'] as IrStringValue).value,
          equals('MaterialIcons'));
    });

    test('converts RfwIcon.search to iconData map', () {
      final expr = parseExpression('RfwIcon.search');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect(map.entries['icon'], isA<IrIntValue>());
    });

    test('converts fitness icons (RfwIcon.fitnessCenter, timer, etc.)', () {
      for (final name in [
        'fitnessCenter',
        'timer',
        'directionsRun',
        'localFireDepartment',
        'schedule',
        'trendingUp',
        'emojiEvents',
        'selfImprovement',
        'monitorHeart',
      ]) {
        final expr = parseExpression('RfwIcon.$name');
        final result = converter.convert(expr);
        expect(result, isA<IrMapValue>(), reason: 'RfwIcon.$name');
        final map = result as IrMapValue;
        expect(map.entries['icon'], isA<IrIntValue>(),
            reason: 'RfwIcon.$name icon');
        expect(map.entries['fontFamily'], isA<IrStringValue>(),
            reason: 'RfwIcon.$name fontFamily');
      }
    });

    test('throws for unknown RfwIcon', () {
      final expr = parseExpression('RfwIcon.nonExistentIcon');
      expect(() => converter.convert(expr),
          throwsA(isA<UnsupportedExpressionError>()));
    });
  });

  group('Icons prefix (auto-convert to RfwIcon)', () {
    test('converts Icons.home to iconData map', () {
      final expr = parseExpression('Icons.home');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect(map.entries['icon'], isA<IrIntValue>());
      expect(map.entries['fontFamily'], isA<IrStringValue>());
      expect((map.entries['fontFamily'] as IrStringValue).value,
          equals('MaterialIcons'));
    });

    test('converts Icons.star to iconData map', () {
      final expr = parseExpression('Icons.star');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect(map.entries['icon'], isA<IrIntValue>());
    });

    test('throws for unmapped Icons with helpful message', () {
      final expr = parseExpression('Icons.nonExistentIcon');
      expect(
        () => converter.convert(expr),
        throwsA(
          allOf(
            isA<UnsupportedExpressionError>(),
            predicate<UnsupportedExpressionError>(
              (e) => e.message.contains('RfwIcon'),
            ),
          ),
        ),
      );
    });
  });

  group('double.infinity', () {
    test('throws with helpful message suggesting SizedBoxExpand', () {
      final expr = parseExpression('double.infinity');
      expect(
        () => converter.convert(expr),
        throwsA(
          allOf(
            isA<UnsupportedExpressionError>(),
            predicate<UnsupportedExpressionError>(
              (e) => e.message.contains('SizedBoxExpand'),
            ),
          ),
        ),
      );
    });
  });

  group('Handler conversion', () {
    test('converts RfwHandler.setState to IrSetStateValue', () {
      final expr = parseExpression("RfwHandler.setState('pressed', true)");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrSetStateValue>());
      final v = result as IrSetStateValue;
      expect(v.field, equals('pressed'));
      expect(v.value, isA<IrBoolValue>());
      expect((v.value as IrBoolValue).value, isTrue);
    });

    test('converts RfwHandler.setState with int value', () {
      final expr = parseExpression("RfwHandler.setState('count', 0)");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrSetStateValue>());
      final v = result as IrSetStateValue;
      expect(v.field, equals('count'));
      expect(v.value, isA<IrIntValue>());
    });

    test('converts RfwHandler.setStateFromArg', () {
      final expr = parseExpression("RfwHandler.setStateFromArg('sliderValue')");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrSetStateFromArgValue>());
      final v = result as IrSetStateFromArgValue;
      expect(v.field, equals('sliderValue'));
      expect(v.argName, equals('value'));
    });

    test('converts RfwHandler.setStateFromArg with custom arg name', () {
      final expr =
          parseExpression("RfwHandler.setStateFromArg('amount', 'newValue')");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrSetStateFromArgValue>());
      final v = result as IrSetStateFromArgValue;
      expect(v.argName, equals('newValue'));
    });

    test('converts RfwHandler.event without args', () {
      final expr = parseExpression("RfwHandler.event('button.click')");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrEventValue>());
      final v = result as IrEventValue;
      expect(v.name, equals('button.click'));
      expect(v.args, isEmpty);
    });

    test('converts RfwHandler.event with args map', () {
      final expr =
          parseExpression("RfwHandler.event('cart.add', {'itemId': 42})");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrEventValue>());
      final v = result as IrEventValue;
      expect(v.name, equals('cart.add'));
      expect(v.args['itemId'], isA<IrIntValue>());
    });

    test('converts RfwSetState direct constructor', () {
      final expr = parseExpression("RfwSetState('active', false)");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrSetStateValue>());
    });

    test('converts RfwSetStateFromArg direct constructor', () {
      final expr = parseExpression("RfwSetStateFromArg('amount')");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrSetStateFromArgValue>());
      final v = result as IrSetStateFromArgValue;
      expect(v.field, equals('amount'));
      expect(v.argName, equals('value'));
    });

    test('converts RfwEvent direct constructor', () {
      final expr = parseExpression("RfwEvent('nav.back')");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrEventValue>());
    });

    test('throws for non-handler expression', () {
      final expr = parseExpression("Color(0xFF000000)");
      expect(() => converter.convertHandler(expr),
          throwsA(isA<UnsupportedExpressionError>()));
    });
  });

  group('Dynamic references', () {
    test("converts DataRef('user.name') to IrDataRef", () {
      final expr = parseExpression("DataRef('user.name')");
      final result = converter.convert(expr);
      expect(result, isA<IrDataRef>());
      expect((result as IrDataRef).path, equals('user.name'));
    });

    test("converts ArgsRef('item.title') to IrArgsRef", () {
      final expr = parseExpression("ArgsRef('item.title')");
      final result = converter.convert(expr);
      expect(result, isA<IrArgsRef>());
      expect((result as IrArgsRef).path, equals('item.title'));
    });

    test("converts StateRef('isOpen') to IrStateRef", () {
      final expr = parseExpression("StateRef('isOpen')");
      final result = converter.convert(expr);
      expect(result, isA<IrStateRef>());
      expect((result as IrStateRef).path, equals('isOpen'));
    });
  });

  group('RfwConcat', () {
    test('converts RfwConcat with mixed parts', () {
      final expr =
          parseExpression("RfwConcat(['Hello, ', DataRef('name'), '!'])");
      final result = converter.convert(expr);
      expect(result, isA<IrConcat>());
      final concat = result as IrConcat;
      expect(concat.parts, hasLength(3));
      expect(concat.parts[0], isA<IrStringValue>());
      expect((concat.parts[0] as IrStringValue).value, equals('Hello, '));
      expect(concat.parts[1], isA<IrDataRef>());
      expect((concat.parts[1] as IrDataRef).path, equals('name'));
      expect(concat.parts[2], isA<IrStringValue>());
      expect((concat.parts[2] as IrStringValue).value, equals('!'));
    });
  });

  group('SetOrMapLiteral', () {
    test('converts simple map literal to IrMapValue', () {
      final expr = parseExpression("{'key': 'value', 'count': 1}");
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect(map.entries, hasLength(2));
      expect((map.entries['key'] as IrStringValue).value, equals('value'));
      expect((map.entries['count'] as IrIntValue).value, equals(1));
    });

    test('converts nested map with DataRef values', () {
      final expr = parseExpression("{'name': DataRef('user.name'), 'age': 25}");
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect(map.entries['name'], isA<IrDataRef>());
      expect((map.entries['name'] as IrDataRef).path, equals('user.name'));
      expect((map.entries['age'] as IrIntValue).value, equals(25));
    });
  });

  group('RfwSwitchValue', () {
    test('converts RfwSwitchValue with cases and default', () {
      final expr = parseExpression(
        "RfwSwitchValue(value: StateRef('status'), "
        "cases: {'active': 0xFF00FF00, 'inactive': 0xFFFF0000}, "
        "defaultCase: 0xFF888888)",
      );
      final result = converter.convert(expr);
      expect(result, isA<IrSwitchExpr>());
      final sw = result as IrSwitchExpr;
      expect(sw.value, isA<IrStateRef>());
      expect(sw.cases, hasLength(2));
      expect(sw.defaultCase, isA<IrIntValue>());
    });
  });

  group('IndexExpression', () {
    test("converts item['name'] to IrLoopVarRef", () {
      final expr = parseExpression("item['name']");
      final result = converter.convert(expr);
      expect(result, isA<IrLoopVarRef>());
      expect((result as IrLoopVarRef).path, equals('item.name'));
    });

    test("converts item['a']['b'] to IrLoopVarRef with dotted path", () {
      final expr = parseExpression("item['a']['b']");
      final result = converter.convert(expr);
      expect(result, isA<IrLoopVarRef>());
      expect((result as IrLoopVarRef).path, equals('item.a.b'));
    });
  });

  group('event handler dynamic payload', () {
    test('event with ArgsRef in payload', () {
      final expr = parseExpression(
          "RfwHandler.event('tap', {'id': ArgsRef('item.id'), 'label': 'click'})");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrEventValue>());
      final event = result as IrEventValue;
      expect(event.name, equals('tap'));
      expect(event.args['id'], isA<IrArgsRef>());
      expect((event.args['id'] as IrArgsRef).path, equals('item.id'));
      expect(event.args['label'], isA<IrStringValue>());
      expect((event.args['label'] as IrStringValue).value, equals('click'));
    });

    test('event with DataRef in payload', () {
      final expr = parseExpression(
          "RfwHandler.event('view', {'userId': DataRef('user.id')})");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrEventValue>());
      final event = result as IrEventValue;
      expect(event.args['userId'], isA<IrDataRef>());
      expect((event.args['userId'] as IrDataRef).path, equals('user.id'));
    });

    test('event with nested map containing DataRef', () {
      final expr = parseExpression(
          "RfwHandler.event('tap', {'action': {'url': DataRef('item.url')}, 'count': 1})");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrEventValue>());
      final event = result as IrEventValue;
      expect(event.args['action'], isA<IrMapValue>());
      final innerMap = event.args['action'] as IrMapValue;
      expect(innerMap.entries['url'], isA<IrDataRef>());
      expect((innerMap.entries['url'] as IrDataRef).path, equals('item.url'));
      expect(event.args['count'], isA<IrIntValue>());
      expect((event.args['count'] as IrIntValue).value, equals(1));
    });

    test('event with mixed dynamic refs in payload', () {
      final expr = parseExpression(
          "RfwHandler.event('submit', {'itemId': ArgsRef('id'), 'userId': DataRef('user.id'), 'active': StateRef('isActive')})");
      final result = converter.convertHandler(expr);
      expect(result, isA<IrEventValue>());
      final event = result as IrEventValue;
      expect(event.args['itemId'], isA<IrArgsRef>());
      expect(event.args['userId'], isA<IrDataRef>());
      expect(event.args['active'], isA<IrStateRef>());
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

  // -------------------------------------------------------------------------
  // InstanceCreationExpression (const prefix) tests
  // -------------------------------------------------------------------------

  group('const Color (InstanceCreationExpression)', () {
    test('converts const Color(0xFF112233)', () {
      final expr = parseExpression('const Color(0xFF112233)');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(0xFF112233));
    });
  });

  group('const EdgeInsets (InstanceCreationExpression)', () {
    test('converts const EdgeInsets.all(16.0)', () {
      final expr = parseExpression('const EdgeInsets.all(16.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      expect((list.values[0] as IrNumberValue).value, equals(16.0));
    });

    test('converts const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)',
        () {
      final expr = parseExpression(
          'const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(4));
      expect((list.values[0] as IrNumberValue).value, equals(8.0));
      expect((list.values[1] as IrNumberValue).value, equals(4.0));
    });

    test('converts const EdgeInsets.only(bottom: 4.0)', () {
      final expr = parseExpression('const EdgeInsets.only(bottom: 4.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(4));
      expect((list.values[3] as IrNumberValue).value, equals(4.0));
    });
  });

  group('const Duration (InstanceCreationExpression)', () {
    test('converts const Duration(milliseconds: 300)', () {
      final expr = parseExpression('const Duration(milliseconds: 300)');
      final result = converter.convert(expr);
      expect(result, isA<IrIntValue>());
      expect((result as IrIntValue).value, equals(300));
    });
  });

  group('const BorderRadius (InstanceCreationExpression)', () {
    test('converts const BorderRadius.circular(8)', () {
      final expr = parseExpression('const BorderRadius.circular(8)');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      final radius = list.values[0] as IrMapValue;
      expect((radius.entries['x'] as IrNumberValue).value, equals(8.0));
    });

    test('converts const BorderRadius.all(Radius.circular(20))', () {
      final expr =
          parseExpression('const BorderRadius.all(Radius.circular(20))');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      final radius = list.values[0] as IrMapValue;
      expect((radius.entries['x'] as IrNumberValue).value, equals(20.0));
    });

    test('converts BorderRadius.all without const', () {
      final expr = parseExpression('BorderRadius.all(Radius.circular(12))');
      final result = converter.convert(expr);
      expect(result, isA<IrListValue>());
      final list = result as IrListValue;
      expect(list.values, hasLength(1));
      final radius = list.values[0] as IrMapValue;
      expect((radius.entries['x'] as IrNumberValue).value, equals(12.0));
    });
  });

  group('const NetworkImage (InstanceCreationExpression)', () {
    test('converts const NetworkImage url', () {
      final expr =
          parseExpression("const NetworkImage('https://example.com/img.png')");
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['source'] as IrStringValue).value,
          equals('https://example.com/img.png'));
      expect((map.entries['scale'] as IrNumberValue).value, equals(1.0));
    });
  });

  // -------------------------------------------------------------------------
  // New type converter tests
  // -------------------------------------------------------------------------

  group('TextStyle', () {
    test('converts TextStyle with fontSize', () {
      final expr = parseExpression('TextStyle(fontSize: 24.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['fontSize'] as IrNumberValue).value, equals(24.0));
    });

    test('converts TextStyle with color and fontWeight', () {
      final expr = parseExpression(
          'TextStyle(color: Color(0xFFFF0000), fontWeight: FontWeight.bold)');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['color'] as IrIntValue).value, equals(0xFFFF0000));
      expect(
          (map.entries['fontWeight'] as IrStringValue).value, equals('bold'));
    });

    test('converts TextStyle with fontStyle italic', () {
      final expr = parseExpression('TextStyle(fontStyle: FontStyle.italic)');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect(
          (map.entries['fontStyle'] as IrStringValue).value, equals('italic'));
    });

    test('converts const TextStyle with multiple props', () {
      final expr = parseExpression(
          'const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['fontSize'] as IrNumberValue).value, equals(16.0));
      expect(
          (map.entries['fontWeight'] as IrStringValue).value, equals('bold'));
      expect((map.entries['color'] as IrIntValue).value, equals(0xFF1565C0));
    });
  });

  group('Alignment', () {
    test('converts Alignment(0.0, 0.0) to map', () {
      final expr = parseExpression('Alignment(0.0, 0.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['x'] as IrNumberValue).value, equals(0.0));
      expect((map.entries['y'] as IrNumberValue).value, equals(0.0));
    });

    test('converts const Alignment(-1.0, -1.0)', () {
      final expr = parseExpression('const Alignment(-1.0, -1.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['x'] as IrNumberValue).value, equals(-1.0));
      expect((map.entries['y'] as IrNumberValue).value, equals(-1.0));
    });
  });

  group('BoxDecoration', () {
    test('converts BoxDecoration with color', () {
      final expr = parseExpression('BoxDecoration(color: Color(0xFF2196F3))');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['type'] as IrStringValue).value, equals('box'));
      expect((map.entries['color'] as IrIntValue).value, equals(0xFF2196F3));
    });

    test('converts const BoxDecoration with gradient and borderRadius', () {
      final expr = parseExpression(
        'const BoxDecoration('
        '  gradient: LinearGradient('
        '    begin: Alignment(-1.0, -1.0),'
        '    end: Alignment(1.0, 1.0),'
        '    colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],'
        '  ),'
        '  borderRadius: BorderRadius.all(Radius.circular(16)),'
        ')',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['type'] as IrStringValue).value, equals('box'));
      expect(map.entries['gradient'], isA<IrMapValue>());
      expect(map.entries['borderRadius'], isA<IrListValue>());
    });
  });

  group('LinearGradient', () {
    test('converts LinearGradient with begin, end, colors', () {
      final expr = parseExpression(
        'LinearGradient('
        '  begin: Alignment(-1.0, 0.0),'
        '  end: Alignment(1.0, 0.0),'
        '  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],'
        ')',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['type'] as IrStringValue).value, equals('linear'));
      expect(map.entries['begin'], isA<IrMapValue>());
      expect(map.entries['end'], isA<IrMapValue>());
      final colors = map.entries['colors'] as IrListValue;
      expect(colors.values, hasLength(2));
    });
  });

  group('BoxShadow', () {
    test('converts BoxShadow with all params', () {
      final expr = parseExpression(
        'BoxShadow(color: Color(0x40000000), blurRadius: 8.0, offset: Offset(0.0, 4.0))',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['color'] as IrIntValue).value, equals(0x40000000));
      expect((map.entries['blurRadius'] as IrNumberValue).value, equals(8.0));
      final offset = map.entries['offset'] as IrMapValue;
      expect((offset.entries['x'] as IrNumberValue).value, equals(0.0));
      expect((offset.entries['y'] as IrNumberValue).value, equals(4.0));
    });
  });

  group('Offset', () {
    test('converts Offset(2.0, 3.0)', () {
      final expr = parseExpression('Offset(2.0, 3.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['x'] as IrNumberValue).value, equals(2.0));
      expect((map.entries['y'] as IrNumberValue).value, equals(3.0));
    });
  });

  group('IconThemeData', () {
    test('converts IconThemeData with color and size', () {
      final expr = parseExpression(
          'IconThemeData(color: Color(0xFF9C27B0), size: 40.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['color'] as IrIntValue).value, equals(0xFF9C27B0));
      expect((map.entries['size'] as IrNumberValue).value, equals(40.0));
    });

    test('converts const IconThemeData', () {
      final expr = parseExpression(
          'const IconThemeData(color: Color(0xFF9C27B0), size: 40.0)');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['color'] as IrIntValue).value, equals(0xFF9C27B0));
    });
  });

  group('const SliverGridDelegate (InstanceCreationExpression)', () {
    test('converts const SliverGridDelegateWithFixedCrossAxisCount', () {
      final expr = parseExpression(
        'const SliverGridDelegateWithFixedCrossAxisCount('
        '  crossAxisCount: 2,'
        '  mainAxisSpacing: 4.0,'
        ')',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = result as IrMapValue;
      expect((map.entries['crossAxisCount'] as IrIntValue).value, equals(2));
    });
  });

  group('Alignment constants', () {
    test('converts Alignment.center to map', () {
      final expr = parseExpression('Alignment.center');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['x'] as IrNumberValue).value, 0.0);
      expect((map['y'] as IrNumberValue).value, 0.0);
    });

    test('converts Alignment.topLeft to map', () {
      final expr = parseExpression('Alignment.topLeft');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['x'] as IrNumberValue).value, -1.0);
      expect((map['y'] as IrNumberValue).value, -1.0);
    });

    test('converts Alignment.bottomRight to map', () {
      final expr = parseExpression('Alignment.bottomRight');
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect((map['x'] as IrNumberValue).value, 1.0);
      expect((map['y'] as IrNumberValue).value, 1.0);
    });

    test('converts AlignmentDirectional.centerStart to map', () {
      final expr = parseExpression('AlignmentDirectional.centerStart');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['start'] as IrNumberValue).value, -1.0);
      expect((map['y'] as IrNumberValue).value, 0.0);
    });

    test('throws for unknown Alignment constant', () {
      final expr = parseExpression('Alignment.unknownName');
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });
  });

  group('Silent drop fixes', () {
    test('BoxDecoration with valid color still works', () {
      final expr = parseExpression('BoxDecoration(color: Color(0xFF000000))');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect(map.containsKey('color'), isTrue);
      expect(map.containsKey('type'), isTrue);
    });

    test('LinearGradient with valid colors list works', () {
      final expr = parseExpression(
        'LinearGradient(colors: [Color(0xFFFF0000), Color(0xFF0000FF)])',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect(map.containsKey('colors'), isTrue);
      expect(map.containsKey('type'), isTrue);
    });

    test('BoxDecoration boxShadow non-list falls through to convert()', () {
      // MethodInvocation is not ListLiteral — should not be silently dropped
      final expr = parseExpression(
        'BoxDecoration(boxShadow: getBoxShadows())',
      );
      // getBoxShadows() is a MethodInvocation which convert() cannot handle
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('BoxDecoration shape non-prefixed falls through to convert()', () {
      // MethodInvocation is not PrefixedIdentifier — should not be silently dropped
      final expr = parseExpression(
        'BoxDecoration(shape: getShape())',
      );
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('LinearGradient colors non-list falls through to convert()', () {
      final expr = parseExpression(
        'LinearGradient(colors: getColors())',
      );
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('LinearGradient stops non-list falls through to convert()', () {
      final expr = parseExpression(
        'LinearGradient(stops: getStops())',
      );
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('LinearGradient tileMode non-prefixed falls through to convert()', () {
      final expr = parseExpression(
        'LinearGradient(tileMode: getTileMode())',
      );
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('RadialGradient colors non-list falls through to convert()', () {
      final expr = parseExpression(
        'RadialGradient(colors: getColors())',
      );
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });

    test('RadialGradient stops non-list falls through to convert()', () {
      final expr = parseExpression(
        'RadialGradient(stops: getStops())',
      );
      expect(
        () => converter.convert(expr),
        throwsA(isA<UnsupportedExpressionError>()),
      );
    });
  });

  group('Default cases and prefix operators', () {
    test('TextStyle converts unknown property via generic convert', () {
      final expr = parseExpression(
        'TextStyle(fontSize: 24.0, backgroundColor: Color(0xFFFF0000))',
      );
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect(map.containsKey('fontSize'), isTrue);
      expect(map.containsKey('backgroundColor'), isTrue);
    });

    test('IconThemeData converts unknown property via generic convert', () {
      final expr = parseExpression(
        'IconThemeData(color: Color(0xFF000000), fill: 1.0)',
      );
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect(map.containsKey('color'), isTrue);
      expect(map.containsKey('fill'), isTrue);
    });

    test('converts prefix ! on BooleanLiteral', () {
      final expr = parseExpression('!true');
      final result = converter.convert(expr);
      expect(result, isA<IrBoolValue>());
      expect((result as IrBoolValue).value, isFalse);
    });

    test('converts prefix !false to true', () {
      final expr = parseExpression('!false');
      final result = converter.convert(expr);
      expect(result, isA<IrBoolValue>());
      expect((result as IrBoolValue).value, isTrue);
    });
  });

  group('Map literal safety', () {
    test('map literal with string keys works normally', () {
      final expr = parseExpression("{'name': 'test', 'value': 42}");
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect(map.containsKey('name'), isTrue);
      expect(map.containsKey('value'), isTrue);
    });

    test('set literal does not crash', () {
      final expr = parseExpression('{1, 2, 3}');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      expect((result as IrMapValue).entries, isEmpty);
    });

    test('map literal with non-string keys does not crash', () {
      final expr = parseExpression('{1: "one", 2: "two"}');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect(map.length, equals(2));
    });
  });

  group('SweepGradient', () {
    test('converts SweepGradient with colors', () {
      final expr = parseExpression(
        "SweepGradient(colors: [Color(0xFFFF0000), Color(0xFF0000FF)])",
      );
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'sweep');
      expect(map.containsKey('colors'), isTrue);
    });
  });

  group('Color constructors', () {
    test('Color.fromARGB(255, 0, 0, 0) converts correctly', () {
      final expr = parseExpression('Color.fromARGB(255, 0, 0, 0)');
      final result = converter.convert(expr);
      expect((result as IrIntValue).value, 0xFF000000);
    });

    test('Color.fromRGBO(255, 0, 0, 1.0) converts correctly', () {
      final expr = parseExpression('Color.fromRGBO(255, 0, 0, 1.0)');
      final result = converter.convert(expr);
      expect((result as IrIntValue).value, 0xFFFF0000);
    });
  });

  group('Border and BorderSide', () {
    test('converts BorderSide with color and width', () {
      final expr = parseExpression(
        'BorderSide(color: Color(0xFF000000), width: 2.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect(map.containsKey('color'), isTrue);
      expect((map['color'] as IrIntValue).value, 0xFF000000);
      expect(map.containsKey('width'), isTrue);
      expect((map['width'] as IrNumberValue).value, 2.0);
    });

    test('converts BorderSide with style', () {
      final expr = parseExpression(
        'BorderSide(color: Color(0xFF000000), width: 1.0, style: BorderStyle.solid)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['style'] as IrStringValue).value, 'solid');
    });

    test('converts Border.all', () {
      final expr = parseExpression(
        'Border.all(color: Color(0xFF000000), width: 1.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'box');
      expect(map.containsKey('sides'), isTrue);
      final sides = (map['sides'] as IrListValue).values;
      expect(sides, hasLength(4));
      // All sides should be identical
      for (final side in sides) {
        final sideMap = (side as IrMapValue).entries;
        expect((sideMap['color'] as IrIntValue).value, 0xFF000000);
        expect((sideMap['width'] as IrNumberValue).value, 1.0);
      }
    });

    test('converts Border with individual sides', () {
      final expr = parseExpression(
        'Border(top: BorderSide(color: Color(0xFFFF0000), width: 2.0), bottom: BorderSide(color: Color(0xFF0000FF), width: 1.0))',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'box');
      final sides = (map['sides'] as IrListValue).values;
      expect(sides, hasLength(4));
      // top side
      final top = (sides[0] as IrMapValue).entries;
      expect((top['color'] as IrIntValue).value, 0xFFFF0000);
      expect((top['width'] as IrNumberValue).value, 2.0);
      // right side (default empty)
      expect((sides[1] as IrMapValue).entries, isEmpty);
      // bottom side
      final bottom = (sides[2] as IrMapValue).entries;
      expect((bottom['color'] as IrIntValue).value, 0xFF0000FF);
      expect((bottom['width'] as IrNumberValue).value, 1.0);
      // left side (default empty)
      expect((sides[3] as IrMapValue).entries, isEmpty);
    });

    test('BoxDecoration with border converts', () {
      final expr = parseExpression(
        'BoxDecoration(color: Color(0xFF000000), border: Border.all(color: Color(0xFFFF0000)))',
      );
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect(map.containsKey('border'), isTrue);
      final border = (map['border'] as IrMapValue).entries;
      expect((border['type'] as IrStringValue).value, 'box');
      expect(border.containsKey('sides'), isTrue);
    });
  });

  group('VisualDensity', () {
    test('converts VisualDensity.compact to enum', () {
      final expr = parseExpression('VisualDensity.compact');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, 'compact');
    });

    test('converts VisualDensity.comfortable to enum', () {
      final expr = parseExpression('VisualDensity.comfortable');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, 'comfortable');
    });

    test('converts VisualDensity.standard to enum', () {
      final expr = parseExpression('VisualDensity.standard');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, 'standard');
    });

    test('converts VisualDensity.adaptivePlatformDensity to enum', () {
      final expr = parseExpression('VisualDensity.adaptivePlatformDensity');
      final result = converter.convert(expr);
      expect(result, isA<IrEnumValue>());
      expect((result as IrEnumValue).value, 'adaptivePlatformDensity');
    });

    test('converts VisualDensity constructor to map', () {
      final expr = parseExpression(
        'VisualDensity(horizontal: -2.0, vertical: -2.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['horizontal'] as IrNumberValue).value, -2.0);
      expect((map['vertical'] as IrNumberValue).value, -2.0);
    });

    test('converts VisualDensity constructor with positive values', () {
      final expr = parseExpression(
        'VisualDensity(horizontal: 4.0, vertical: 4.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['horizontal'] as IrNumberValue).value, 4.0);
      expect((map['vertical'] as IrNumberValue).value, 4.0);
    });

    test('converts const VisualDensity constructor to map', () {
      final expr = parseExpression(
        'const VisualDensity(horizontal: -1.0, vertical: 0.0)',
      );
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['horizontal'] as IrNumberValue).value, -1.0);
      expect((map['vertical'] as IrNumberValue).value, 0.0);
    });
  });

  group('ShapeBorder', () {
    test('converts RoundedRectangleBorder() with no args', () {
      final expr = parseExpression('RoundedRectangleBorder()');
      final result = converter.convert(expr);
      expect(result, isA<IrMapValue>());
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'rounded');
    });

    test('converts RoundedRectangleBorder with borderRadius', () {
      final expr = parseExpression(
        'RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))',
      );
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'rounded');
      expect(map.containsKey('borderRadius'), isTrue);
      expect(map['borderRadius'], isA<IrListValue>());
    });

    test('converts RoundedRectangleBorder with side and borderRadius', () {
      final expr = parseExpression(
        'RoundedRectangleBorder('
        '  side: BorderSide(color: Color(0xFF000000), width: 2.0),'
        '  borderRadius: BorderRadius.circular(12.0),'
        ')',
      );
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'rounded');
      expect(map.containsKey('side'), isTrue);
      final side = (map['side'] as IrMapValue).entries;
      expect((side['color'] as IrIntValue).value, 0xFF000000);
      expect((side['width'] as IrNumberValue).value, 2.0);
      expect(map.containsKey('borderRadius'), isTrue);
    });

    test('converts CircleBorder() with no args', () {
      final expr = parseExpression('CircleBorder()');
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'circle');
    });

    test('converts CircleBorder with side', () {
      final expr = parseExpression(
        'CircleBorder(side: BorderSide(color: Color(0xFFFF0000), width: 1.0))',
      );
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'circle');
      expect(map.containsKey('side'), isTrue);
      final side = (map['side'] as IrMapValue).entries;
      expect((side['color'] as IrIntValue).value, 0xFFFF0000);
    });

    test('converts StadiumBorder() with no args', () {
      final expr = parseExpression('StadiumBorder()');
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'stadium');
    });

    test('converts StadiumBorder with side', () {
      final expr = parseExpression(
        'StadiumBorder(side: BorderSide(color: Color(0xFF0000FF), width: 3.0))',
      );
      final result = converter.convert(expr);
      final map = (result as IrMapValue).entries;
      expect((map['type'] as IrStringValue).value, 'stadium');
      expect(map.containsKey('side'), isTrue);
    });
  });

  group('offset presence in UnsupportedExpressionError', () {
    test('unsupported EdgeInsets constructor includes offset', () {
      final expr = parseExpression(
          'EdgeInsets.lerp(EdgeInsets.zero, EdgeInsets.zero, 0.5)');
      expect(
        () => converter.convert(expr),
        throwsA(
          isA<UnsupportedExpressionError>()
              .having((e) => e.offset, 'offset', isNotNull),
        ),
      );
    });

    test('unsupported BorderRadius constructor includes offset', () {
      final expr = parseExpression('BorderRadius.lerp(null, null, 0.5)');
      expect(
        () => converter.convert(expr),
        throwsA(
          isA<UnsupportedExpressionError>()
              .having((e) => e.offset, 'offset', isNotNull),
        ),
      );
    });

    test('unknown Alignment constant includes offset', () {
      final expr = parseExpression('Alignment.customValue');
      expect(
        () => converter.convert(expr),
        throwsA(
          isA<UnsupportedExpressionError>()
              .having((e) => e.offset, 'offset', isNotNull),
        ),
      );
    });
  });
}

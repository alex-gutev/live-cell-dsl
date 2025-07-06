import 'package:live_cell/analyzer/exceptions.dart';
import 'package:live_cell/parser/index.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'build_test_utils.dart';

void main() {
  group('Cyclic definitions', () {
    test('Named cell cyclic definition', () {
      final tester = BuildTester(
          'a = b + 1; b = a + 2',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            ),
            Operator(
                name: '+',
                type: OperatorType.infix,
                precedence: 5,
                leftAssoc: true
            )
          ]
      );

      expect(tester.analyze, throwsA(isA<CyclicDefinitionError>()));
    });

    test('Named cell cyclic definition through intermediate cells', () {
      final tester = BuildTester(
          'a = b + 1; c = a + 3; b = c + 2',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            ),
            Operator(
                name: '+',
                type: OperatorType.infix,
                precedence: 5,
                leftAssoc: true
            )
          ]
      );

      expect(tester.analyze, throwsA(isA<CyclicDefinitionError>()));
    });

    test('Cyclic definition in function', () {
      final tester = BuildTester(
          'f(n) = {\n'
              'a = b + 1\n'
              'b = a + n\n'
              'a\n'
              '}',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            ),
            Operator(
                name: '+',
                type: OperatorType.infix,
                precedence: 5,
                leftAssoc: true
            )
          ]
      );

      expect(tester.analyze, throwsA(isA<CyclicDefinitionError>()));
    });

    test('Cyclic definition in nested function', () {
      final tester = BuildTester(
          'f(n) = {\n'
              'g(m) {'
              'a = b + 1\n'
              'b = a + m\n'
              'a\n'
              '}'
              'g(n)'
              '}',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            ),
            Operator(
                name: '+',
                type: OperatorType.infix,
                precedence: 5,
                leftAssoc: true
            )
          ]
      );

      expect(tester.analyze, throwsA(isA<CyclicDefinitionError>()));
    });

    test('Recursive functions', () {
      // Test that recursive functions are allowed

      final tester = BuildTester(
          'inc(n) = inc(n) + 1\n'
              'x = inc(y)',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            ),
            Operator(
                name: '+',
                type: OperatorType.infix,
                precedence: 5,
                leftAssoc: true
            )
          ]
      );

      expect(tester.analyze(), completes);
    });
  });
}
import 'package:live_cell/analyzer/index.dart';
import 'package:live_cell/builder/index.dart';
import 'package:live_cell/optimization/folding.dart';
import 'package:live_cell/parser/operators.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'build_test_utils.dart';

void main() {
  group('Importing all cells defined in module', () {
    test('Import a single module', () => BuildTester(
        'import(utils);'
        'var(x);'
        'y = inc(x);',

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
    ).addModule(
        name: 'utils',
        source: 'inc(n) = n + 1;'
            'external(+(a,b))'
    ).hasNamed(
        'x',
        tester: SpecTester.variable()
    ).hasApplication(
        operator: NamedCellId('inc', module: 'utils'),
        operands: [
          NamedCellId('x')
        ],

        tester: SpecTester.apply(
            operator: SpecTester.ref(
                NamedCellId('inc', module: 'utils')
            ),

            operands: [
              SpecTester.ref(NamedCellId('x'))
            ]
        )
    ).hasNamed('y',
      tester: SpecTester.ref(
          AppliedCellId(
            operator: NamedCellId('inc', module: 'utils'),
            operands: [NamedCellId('x')]
          )
      )
    ).hasNamed(
        'inc',
        module: 'utils'
    ).hasNamed(
        '+',
        module: 'utils'
    ).addOperation(SemanticAnalyzer())
     .addOperation(CellFolder())
        .run());

    test('Import a module that imports another module', () => BuildTester(
        'import(utils);'
            'var(x);'
            'y = inc(x);',

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
    ).addModule(
        name: 'utils',
        source: 'import(math);'
            'inc(n) = n + 1;'
    ).addModule(
        name: 'math',
        source: 'external(+(a,b));'
    ).hasNamed(
        'x',
        tester: SpecTester.variable()
    ).hasApplication(
        operator: NamedCellId('inc', module: 'utils'),
        operands: [
          NamedCellId('x')
        ],

        tester: SpecTester.apply(
            operator: SpecTester.ref(
                NamedCellId('inc', module: 'utils')
            ),

            operands: [
              SpecTester.ref(NamedCellId('x'))
            ]
        )
    ).hasNamed('y',
        tester: SpecTester.ref(
            AppliedCellId(
                operator: NamedCellId('inc', module: 'utils'),
                operands: [NamedCellId('x')]
            )
        )
    ).hasNamed(
        'inc',
        module: 'utils'
    ).hasNamed(
        '+',
        module: 'math'
    ).addOperation(SemanticAnalyzer())
        .addOperation(CellFolder())
        .run());

    test('Import multiple modules', () => BuildTester(
        'import(utils);'
            'import(math);'
            'var(x);'
            'y = inc(x) + 2',

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
    ).addModule(
        name: 'utils',
        source: 'inc(n) = n;'
    ).addModule(
        name: 'math',
        source: 'external(+(a,b));'
    ).hasNamed(
        'x',
        tester: SpecTester.variable()
    ).hasApplication(
        operator: NamedCellId('inc', module: 'utils'),
        operands: [
          NamedCellId('x')
        ],

        tester: SpecTester.apply(
            operator: SpecTester.ref(
                NamedCellId('inc', module: 'utils')
            ),

            operands: [
              SpecTester.ref(NamedCellId('x'))
            ]
        )
    ).hasNamed('y',
        tester: SpecTester.ref(
            AppliedCellId(
              operator: NamedCellId('+', module: 'math'),
              operands: [
                AppliedCellId(
                    operator: NamedCellId('inc', module: 'utils'),
                    operands: [NamedCellId('x')]
                ),
                ValueCellId(2)
              ]
            )
        )
    ).hasNamed(
        'inc',
        module: 'utils'
    ).hasNamed(
        '+',
        module: 'math'
    ).addOperation(SemanticAnalyzer())
        .addOperation(CellFolder())
        .run());

    test('Import multiple modules multiple times', () => BuildTester(
        'import(utils);'
            'import(math);'
            'var(x);'
            'y = inc(x) + 2',

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
    ).addModule(
        name: 'utils',
        source: 'import(math);'
            'inc(n) = n + 1;'
    ).addModule(
        name: 'math',
        source: 'external(+(a,b));'
    ).hasNamed(
        'x',
        tester: SpecTester.variable()
    ).hasApplication(
        operator: NamedCellId('inc', module: 'utils'),
        operands: [
          NamedCellId('x')
        ],

        tester: SpecTester.apply(
            operator: SpecTester.ref(
                NamedCellId('inc', module: 'utils')
            ),

            operands: [
              SpecTester.ref(NamedCellId('x'))
            ]
        )
    ).hasNamed('y',
        tester: SpecTester.ref(
            AppliedCellId(
                operator: NamedCellId('+', module: 'math'),
                operands: [
                  AppliedCellId(
                      operator: NamedCellId('inc', module: 'utils'),
                      operands: [NamedCellId('x')]
                  ),
                  ValueCellId(2)
                ]
            )
        )
    ).hasNamed(
        'inc',
        module: 'utils'
    ).hasNamed(
        '+',
        module: 'math'
    ).addOperation(SemanticAnalyzer())
        .addOperation(CellFolder())
        .run());

    test('Malformed declaration', () {
      final tester1 = BuildTester('import(1234)');
      final tester2 = BuildTester('import("hello")');
      final tester3 = BuildTester('import(f(x))');
      final tester4 = BuildTester('import(a, b, c)');
      final tester5 = BuildTester('import({a; b; c})');

      expect(tester1.run, throwsA(isA<BuildError>()
          .having((e) => e.error, 'Malformed Import Error', isA<MalformedImportError>())));

      expect(tester2.run, throwsA(isA<BuildError>()
          .having((e) => e.error, 'Malformed Import Error', isA<MalformedImportError>())));

      expect(tester3.run, throwsA(isA<BuildError>()
          .having((e) => e.error, 'Malformed Import Error', isA<MalformedImportError>())));

      expect(tester4.run, throwsA(isA<BuildError>()
          .having((e) => e.error, 'Malformed Import Error', isA<MalformedImportError>())));

      expect(tester5.run, throwsA(isA<BuildError>()
          .having((e) => e.error, 'Malformed Import Error', isA<MalformedImportError>())));
    });

    test('Malformed: Module not found', () {
      final tester = BuildTester('import(a-module)');

      expect(tester.run, throwsA(isA<BuildError>()
          .having((e) => e.error, 'Module Not Found Error', isA<ModuleNotFound>())));
    });
    
    test('Malformed: Circular Import', () {
      final tester = BuildTester('import(mod1)')
        .addModule(name: 'mod1', source: 'import(mod2)')
        .addModule(name: 'mod2', source: 'import(mod1)');

      expect(tester.run, throwsA(isA<BuildError>()
          .having((e) => e.error, 'Circular Import Error', isA<CircularImportError>())));
    });
  });
}
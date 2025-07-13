import 'package:live_cell/analyzer/index.dart';
import 'package:live_cell/builder/cell_spec.dart';
import 'package:live_cell/optimization/folding.dart';
import 'package:live_cell/parser/operators.dart';
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
  });
}
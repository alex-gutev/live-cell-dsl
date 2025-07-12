import 'package:live_cell/analyzer/index.dart';
import 'package:live_cell/builder/cell_spec.dart';
import 'package:live_cell/optimization/folding.dart';
import 'package:live_cell/parser/operators.dart';
import 'package:test/scaffolding.dart';

import 'build_test_utils.dart';

void main() {
  group('Importing all cells defined in module', () {
    test('Import another module', () => BuildTester(
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
  });
}
import 'package:live_cell/analyzer/index.dart';
import 'package:live_cell/builder/attributes.dart';
import 'package:live_cell/builder/cell_spec.dart';
import 'package:live_cell/optimization/folding.dart';
import 'package:live_cell/parser/index.dart';
import 'package:test/scaffolding.dart';

import 'build_test_utils.dart';

void main() {
  group('Constant cell folding', () {
    test('Constant cells', () => BuildTester(
        'a = 2;'
        'var(x);'
        'sum = a + x;'
        'external(+(x,y));',

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
        ])
        .addOperation(SemanticAnalyzer())
        .addOperation(CellFolder())
        .hasNamed('a',
          attributes: {
            Attributes.fold: true
          }
        )
        .hasNamed('x',
          attributes: {
            Attributes.fold: false
          }
        )
        .hasNamed('sum',
          attributes: {
            Attributes.fold: false
          }
        )
        .hasApplication(
          operator: NamedCellId('+'),
          operands: [
            NamedCellId('a'),
            NamedCellId('x')
          ],

          attributes: {
            Attributes.fold: false
          }
        )
        .run());

    test('Constant expression cells', () => BuildTester(
        'a = 2;'
        'var(x);'
        'sum = a + 1;'
        'external(+(x,y));',

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
        ])
        .addOperation(SemanticAnalyzer())
        .addOperation(CellFolder())
        .hasNamed('a',
          attributes: {
            Attributes.fold: true
          }
        )
        .hasNamed('x',
          attributes: {
            Attributes.fold: false
          }
        )
        .hasNamed('sum',
          attributes: {
            Attributes.fold: true
          }
        )
        .hasApplication(
          operator: NamedCellId('+'),
          operands: [
            NamedCellId('a'),
            ValueCellId(1)
          ],

          attributes: {
            Attributes.fold: true
          }
        )
        .run());

    test('Multilevel constant expression cells', () => BuildTester(
        'a = 2;'
        'var(x);'
        'c = a + 1;'
        'd = c + 5;'
        'sum = d + c;'
        'external(+(x,y));',

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
        ])
        .addOperation(SemanticAnalyzer())
        .addOperation(CellFolder())
        .hasNamed('a',
          attributes: {
            Attributes.fold: true
          }
        )
        .hasNamed('x',
          attributes: {
            Attributes.fold: false
          }
        )
        .hasNamed('c',
          attributes: {
            Attributes.fold: true
          }
        )
        .hasApplication(
          operator: NamedCellId('+'),
          operands: [
            NamedCellId('a'),
            ValueCellId(1)
          ],

          attributes: {
            Attributes.fold: true
          }
        )
        .hasNamed('d',
          attributes: {
            Attributes.fold: true
          }
        )
        .hasApplication(
          operator: NamedCellId('+'),
          operands: [
            NamedCellId('c'),
            ValueCellId(5)
          ],

          attributes: {
            Attributes.fold: true
          }
        )
        .hasNamed('sum',
          attributes: {
            Attributes.fold: true
          }
        )
        .hasApplication(
          operator: NamedCellId('+'),
          operands: [
            NamedCellId('d'),
            NamedCellId('c')
          ]
        )
        .run());

    test('Multilevel constant expression cells', () => BuildTester(
        'a = 2;'
        'f(x) = {'
        'b = a + 3;'
        'g(y) = {'
        'c = b + a + 8;'
        'y + c'
        '};'
        'g(x)'
        '};'
        'external(+(x,y));',

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
        ])
        .addOperation(SemanticAnalyzer())
        .addOperation(CellFolder())
        .hasNamed('a',
          attributes: {
            Attributes.fold: true
          }
        )
        .hasNamed('f',
          attributes: {
            Attributes.fold: true
          },
          tester: SpecTester.func(
              arguments: [NamedCellId('x')],
              definition: SpecTester.ref(
                AppliedCellId(
                  operator: NamedCellId('g'),
                  operands: [NamedCellId('x')]
                )
              ),
              tester: FunctionTester()
                .hasNamed('x',
                  attributes: {
                    Attributes.fold: false
                  }
                )
                .hasNamed('b',
                  attributes: {
                    Attributes.fold: true
                  }
                )
                .hasApplication(
                  operator: NamedCellId('g'),
                  operands: [NamedCellId('x')],
                  attributes: {
                    Attributes.fold: false
                  }
                )
                .hasNamed('g',
                  attributes: {
                    Attributes.fold: true
                  },
                  tester: SpecTester.func(
                      arguments: [NamedCellId('y')],
                      definition: SpecTester.ref(
                        AppliedCellId(
                          operator: NamedCellId('+'),
                          operands: [
                            NamedCellId('y'),
                            NamedCellId('c')
                          ]
                        )
                      ),
                      tester: FunctionTester()
                        .hasNamed('y',
                          attributes: {
                            Attributes.fold: false
                          }
                        )
                        .hasNamed('c',
                          attributes: {
                            Attributes.fold: true
                          }
                        )
                        .hasApplication(
                          operator: NamedCellId('+'),
                          operands: [NamedCellId('y'), NamedCellId('c')],
                          attributes: {
                            Attributes.fold: false
                          }
                        )
                  )
                )
          )
        )
        .run());
  });

  group('Function cell folding', () {
    test('Cells referencing functions are folded', () =>
      BuildTester('var(x); inc(n) = n + x; +n = inc; a = +n(x); b = +n(1); external(+(x,y));',
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
          ])
          .hasNamed('x',
            attributes: {
              Attributes.fold: false
            }
          )
          .hasNamed('inc',
            attributes: {
              Attributes.fold: true
            }
          )
          .hasNamed('+n',
            attributes: {
              Attributes.fold: true
            }
          )
          .hasNamed('a',
            attributes: {
              Attributes.fold: false
            }
          )
          .hasNamed('b',
            attributes: {
              Attributes.fold: true
            }
          )
          .addOperation(SemanticAnalyzer())
          .addOperation(CellFolder())
          .run());
  });
}
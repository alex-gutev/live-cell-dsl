import 'package:live_cell/builder/cell_spec.dart';
import 'package:live_cell/parser/index.dart';
import 'package:test/scaffolding.dart';

import 'build_test_utils.dart';

void main() {
  group('Simple declarations', () {
    test('Cells created for every declaration', () =>
      BuildTester('a\nb; another-cell')
          .hasCell(NamedCellId('a'))
          .hasCell(NamedCellId('b'))
          .hasCell(NamedCellId('another-cell'))
          .run());

    test('Cells created for expressions', () =>
        BuildTester('fn(a, b); g(x, y, z)')
            .hasNamed('a')
            .hasNamed('b')
            .hasNamed('x')
            .hasNamed('y')
            .hasNamed('z')
            .hasNamed('fn')
            .hasNamed('g')
            .hasApplication(
              operator: NamedCellId('fn'),
              operands: [
                NamedCellId('a'),
                NamedCellId('b')
              ]
            )
            .hasApplication(
              operator: NamedCellId('g'),
              operands: [
                NamedCellId('x'),
                NamedCellId('y'),
                NamedCellId('z')
              ]
            )
            .run());
  });
  
  group('Named cell definitions', () {
    test('Alias definitions', () =>
        BuildTester('a = b\nb = c', operators: [
          Operator(
              name: '=',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]).hasNamed('a', ExpressionTester.ref(NamedCellId('b')))
          .hasNamed('b', ExpressionTester.ref(NamedCellId('c')))
          .run());

    test('Chained alias definitions', () =>
        BuildTester('a = b = c', operators: [
          Operator(
              name: '=',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]).hasNamed('a', ExpressionTester.ref(NamedCellId('b')))
            .hasNamed('b', ExpressionTester.ref(NamedCellId('c')))
            .run());

    test('Later declarations do not overwrite earlier definitions.', () =>
        BuildTester('b = c; b; a = b', operators: [
          Operator(
              name: '=',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]).hasNamed('a', ExpressionTester.ref(NamedCellId('b')))
            .hasNamed('b', ExpressionTester.ref(NamedCellId('c')))
            .run());

    test('Expression definitions', () =>
        BuildTester('a = f(b, c)', operators: [
          Operator(
              name: '=',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]).hasNamed('a', ExpressionTester.ref(
          AppliedCellId(
            operator: NamedCellId('f'),
            operands: [
              NamedCellId('b'),
              NamedCellId('c')
            ]
          )
        ))
        .hasApplication(
            operator: NamedCellId('f'),
            operands: [
              NamedCellId('b'),
              NamedCellId('c')
            ],

            tester: ExpressionTester.apply(
                operator: ExpressionTester.ref(NamedCellId('f')),
                operands: [
                  ExpressionTester.ref(NamedCellId('b')),
                  ExpressionTester.ref(NamedCellId('c'))
                ]
            )
        )
        .run());

    test('Block definitions', () =>
        BuildTester('a = { b = c + 1; b}', operators: [
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
        ]).hasNamed('a', ExpressionTester.ref(NamedCellId('b')))
        .hasNamed('b', ExpressionTester.ref(
          AppliedCellId(
            operator: NamedCellId('+'),
            operands: [
              NamedCellId('c'),
              ValueCellId(1)
            ]
          )
        ))
        .hasApplication(
            operator: NamedCellId('+'),
            operands: [
              NamedCellId('c'),
              ValueCellId(1)
            ],
            tester: ExpressionTester.apply(
                operator: ExpressionTester.ref(NamedCellId('+')),
                operands: [
                  ExpressionTester.ref(NamedCellId('c')),
                  ExpressionTester.value(1)
                ]
            )
        )
        .run());
  });

  group('Function definitions', () {
    test('Single expression functions', () =>
        BuildTester('inc(n, d) = n + d\nx = inc(y, 1)',
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
        ).hasNamed('x', ExpressionTester.ref(
            AppliedCellId(
                operator: NamedCellId('inc'),
                operands: [
                  NamedCellId('y'),
                  ValueCellId(1)
                ]
            )
        )).hasApplication(
            operator: NamedCellId('inc'),
            operands: [
              NamedCellId('y'),
              ValueCellId(1)
            ],

            tester: ExpressionTester.apply(
              operator: ExpressionTester.ref(NamedCellId('inc')),
              operands: [
                ExpressionTester.ref(NamedCellId('y')),
                ExpressionTester.value(1)
              ]
            )
        ).hasNamed('inc', ExpressionTester.func(
            arguments: [NamedCellId('n'), NamedCellId('d')],
            definition: ExpressionTester.ref(
              AppliedCellId(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('n'),
                  NamedCellId('d')
                ]
              )
            ),
            tester: FunctionTester()
              .hasApplication(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('n'),
                  NamedCellId('d')
                ],

                tester: ExpressionTester.apply(
                    operator: ExpressionTester.ref(NamedCellId('+')),
                    operands: [
                      ExpressionTester.ref(NamedCellId('n')),
                      ExpressionTester.ref(NamedCellId('d'))
                    ]
                )
            )
        )).run());

    test('Multiple expression functions', () =>
        BuildTester('inc(n, d) = {'
            'sum = n + d; '
            'result = sum + 1\n'
            'result '
            '}\nx = inc(y, 1)',

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
        ).hasNamed('x', ExpressionTester.ref(
            AppliedCellId(
                operator: NamedCellId('inc'),
                operands: [
                  NamedCellId('y'),
                  ValueCellId(1)
                ]
            )
        )).hasApplication(
            operator: NamedCellId('inc'),
            operands: [
              NamedCellId('y'),
              ValueCellId(1)
            ],

            tester: ExpressionTester.apply(
                operator: ExpressionTester.ref(NamedCellId('inc')),
                operands: [
                  ExpressionTester.ref(NamedCellId('y')),
                  ExpressionTester.value(1)
                ]
            )
        ).hasNamed('inc', ExpressionTester.func(
            arguments: [NamedCellId('n'), NamedCellId('d')],
            definition: ExpressionTester.ref(NamedCellId('result')),
            tester: FunctionTester()
                .hasApplication(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('n'),
                  NamedCellId('d')
                ],

                tester: ExpressionTester.apply(
                    operator: ExpressionTester.ref(NamedCellId('+')),
                    operands: [
                      ExpressionTester.ref(NamedCellId('n')),
                      ExpressionTester.ref(NamedCellId('d'))
                    ]
                )
            )
        )).run());

    test('Multiple expression functions with irregular order', () =>
        BuildTester('inc(n, d) = {'
            'result = sum + 1\n'
            'sum = n + d; '
            'result '
            '}\nx = inc(y, 1)',

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
        ).hasNamed('x', ExpressionTester.ref(
            AppliedCellId(
                operator: NamedCellId('inc'),
                operands: [
                  NamedCellId('y'),
                  ValueCellId(1)
                ]
            )
        )).hasApplication(
            operator: NamedCellId('inc'),
            operands: [
              NamedCellId('y'),
              ValueCellId(1)
            ],

            tester: ExpressionTester.apply(
                operator: ExpressionTester.ref(NamedCellId('inc')),
                operands: [
                  ExpressionTester.ref(NamedCellId('y')),
                  ExpressionTester.value(1)
                ]
            )
        ).hasNamed('inc', ExpressionTester.func(
            arguments: [NamedCellId('n'), NamedCellId('d')],
            definition: ExpressionTester.ref(NamedCellId('result')),
            tester: FunctionTester()
                .hasApplication(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('n'),
                  NamedCellId('d')
                ],

                tester: ExpressionTester.apply(
                    operator: ExpressionTester.ref(NamedCellId('+')),
                    operands: [
                      ExpressionTester.ref(NamedCellId('n')),
                      ExpressionTester.ref(NamedCellId('d'))
                    ]
                )
            )
        )).run());

    test('Referencing cells defined outside function', () =>
        BuildTester('inc(n) = n + delta;'
            'delta = 1; '
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
        ).hasNamed('x', ExpressionTester.ref(
            AppliedCellId(
                operator: NamedCellId('inc'),
                operands: [
                  NamedCellId('y'),
                ]
            )
        )).hasApplication(
            operator: NamedCellId('inc'),
            operands: [
              NamedCellId('y'),
            ],

            tester: ExpressionTester.apply(
                operator: ExpressionTester.ref(NamedCellId('inc')),
                operands: [
                  ExpressionTester.ref(NamedCellId('y')),
                ]
            )
        ).hasNamed(
            'delta',
            ExpressionTester.value(1)
        ).hasNamed('inc', ExpressionTester.func(
            arguments: [NamedCellId('n')],
            definition: ExpressionTester.ref(
                AppliedCellId(
                    operator: NamedCellId('+'),
                    operands: [
                      NamedCellId('n'),
                      NamedCellId('delta')
                    ]
                )
            ),
            tester: FunctionTester()
                .hasApplication(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('n'),
                  NamedCellId('delta')
                ],

                tester: ExpressionTester.apply(
                    operator: ExpressionTester.ref(NamedCellId('+')),
                    operands: [
                      ExpressionTester.ref(NamedCellId('n')),
                      ExpressionTester.ref(NamedCellId('delta'))
                    ]
                )
            )
        )).run());
  });
}
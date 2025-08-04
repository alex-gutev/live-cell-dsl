import 'package:live_cell/builder/index.dart';
import 'package:live_cell/parser/index.dart';
import 'package:test/expect.dart';
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
        ]).hasNamed('a', tester: SpecTester.ref(NamedCellId('b')))
          .hasNamed('b', tester: SpecTester.ref(NamedCellId('c')))
          .run());

    test('Chained alias definitions', () =>
        BuildTester('a = b = c', operators: [
          Operator(
              name: '=',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]).hasNamed('a', tester: SpecTester.ref(NamedCellId('b')))
            .hasNamed('b', tester: SpecTester.ref(NamedCellId('c')))
            .run());

    test('Later declarations do not overwrite earlier definitions.', () =>
        BuildTester('b = c; b; a = b', operators: [
          Operator(
              name: '=',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]).hasNamed('a', tester: SpecTester.ref(NamedCellId('b')))
            .hasNamed('b', tester: SpecTester.ref(NamedCellId('c')))
            .run());

    test('Expression definitions', () =>
        BuildTester('a = f(b, c)', operators: [
          Operator(
              name: '=',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]).hasNamed('a', tester: SpecTester.ref(
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

            tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('f')),
                operands: [
                  SpecTester.ref(NamedCellId('b')),
                  SpecTester.ref(NamedCellId('c'))
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
        ]).hasNamed('a', tester: SpecTester.ref(NamedCellId('b')))
        .hasNamed('b', tester: SpecTester.ref(
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
            tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('+')),
                operands: [
                  SpecTester.ref(NamedCellId('c')),
                  SpecTester.value(1)
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
        ).hasNamed('x', tester: SpecTester.ref(
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

            tester: SpecTester.apply(
              operator: SpecTester.ref(NamedCellId('inc')),
              operands: [
                SpecTester.ref(NamedCellId('y')),
                SpecTester.value(1)
              ]
            )
        ).hasNamed('inc', tester: SpecTester.func(
            arguments: [NamedCellId('n'), NamedCellId('d')],
            definition: SpecTester.ref(
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

                tester: SpecTester.apply(
                    operator: SpecTester.ref(NamedCellId('+')),
                    operands: [
                      SpecTester.ref(NamedCellId('n')),
                      SpecTester.ref(NamedCellId('d'))
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
        ).hasNamed('x', tester: SpecTester.ref(
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

            tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('inc')),
                operands: [
                  SpecTester.ref(NamedCellId('y')),
                  SpecTester.value(1)
                ]
            )
        ).hasNamed('inc', tester: SpecTester.func(
            arguments: [NamedCellId('n'), NamedCellId('d')],
            definition: SpecTester.ref(NamedCellId('result')),
            tester: FunctionTester()
                .hasApplication(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('n'),
                  NamedCellId('d')
                ],

                tester: SpecTester.apply(
                    operator: SpecTester.ref(NamedCellId('+')),
                    operands: [
                      SpecTester.ref(NamedCellId('n')),
                      SpecTester.ref(NamedCellId('d'))
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
        ).hasNamed('x', tester: SpecTester.ref(
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

            tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('inc')),
                operands: [
                  SpecTester.ref(NamedCellId('y')),
                  SpecTester.value(1)
                ]
            )
        ).hasNamed('inc', tester: SpecTester.func(
            arguments: [NamedCellId('n'), NamedCellId('d')],
            definition: SpecTester.ref(NamedCellId('result')),
            tester: FunctionTester()
                .hasApplication(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('n'),
                  NamedCellId('d')
                ],

                tester: SpecTester.apply(
                    operator: SpecTester.ref(NamedCellId('+')),
                    operands: [
                      SpecTester.ref(NamedCellId('n')),
                      SpecTester.ref(NamedCellId('d'))
                    ]
                )
            )
        )).run());

    test('Referencing cells defined outside function', () =>
        BuildTester('inc(n) = n + delta;'
            'x = inc(y);'
            'delta = 1;',

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
        ).hasNamed('x', tester: SpecTester.ref(
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

            tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('inc')),
                operands: [
                  SpecTester.ref(NamedCellId('y')),
                ]
            )
        ).hasNamed(
            'delta',
            tester: SpecTester.value(1)
        ).hasNamed('inc', tester: SpecTester.func(
            arguments: [NamedCellId('n')],
            definition: SpecTester.ref(
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

                  tester: SpecTester.apply(
                      operator: SpecTester.ref(NamedCellId('+')),
                      operands: [
                        SpecTester.ref(NamedCellId('n')),
                        SpecTester.ref(NamedCellId('delta'))
                      ]
                  )
                )
                .hasNamed('delta', local: false)
        )).run());

    test('Shadowing cells defined outside function', () =>
        BuildTester('inc(n) = {'
            'x = n + delta;'
            'x;'
            '}\n'
            'x = inc(y);'
            'delta = 1;',

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
        ).hasNamed('x', tester: SpecTester.ref(
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

            tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('inc')),
                operands: [
                  SpecTester.ref(NamedCellId('y')),
                ]
            )
        ).hasNamed(
            'delta',
            tester: SpecTester.value(1)
        ).hasNamed('inc', tester: SpecTester.func(
            arguments: [NamedCellId('n')],
            definition: SpecTester.ref(NamedCellId('x')),
            tester: FunctionTester()
                .hasApplication(
                  operator: NamedCellId('+'),
                  operands: [
                    NamedCellId('n'),
                    NamedCellId('delta')
                  ],

                  tester: SpecTester.apply(
                      operator: SpecTester.ref(NamedCellId('+')),
                      operands: [
                        SpecTester.ref(NamedCellId('n')),
                        SpecTester.ref(NamedCellId('delta'))
                      ]
                  )
                )
                .hasNamed(
                  'x',
                  tester: SpecTester.ref(
                    AppliedCellId(
                      operator: NamedCellId('+'),
                      operands: [
                        NamedCellId('n'),
                        NamedCellId('delta')
                      ]
                    )
                  ),
                  local: true
                )
                .hasNamed('delta', local: false)
        )).run());

    test('Shadowing expression cells defined outside function', () =>
        BuildTester('add(a, b) = a + b;'
            'x = a + b',

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
        ).hasNamed('x', tester: SpecTester.ref(
            AppliedCellId(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('a'),
                  NamedCellId('b')
                ]
            )
        )).hasApplication(
            operator: NamedCellId('+'),
            operands: [
              NamedCellId('a'),
              NamedCellId('b')
            ],

            tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('+')),
                operands: [
                  SpecTester.ref(NamedCellId('a')),
                  SpecTester.ref(NamedCellId('b'))
                ]
            )
        ).hasNamed('add', tester: SpecTester.func(
            arguments: [NamedCellId('a'), NamedCellId('b')],
            definition: SpecTester.ref(
              AppliedCellId(
                operator: NamedCellId('+'),
                operands: [NamedCellId('a'), NamedCellId('b')]
              )
            ),
            tester: FunctionTester()
                .hasApplication(
                  operator: NamedCellId('+'),
                  operands: [
                    NamedCellId('a'),
                    NamedCellId('b')
                  ],

                  local: true,

                  tester: SpecTester.apply(
                    operator: SpecTester.ref(NamedCellId('+')),
                    operands: [
                      SpecTester.ref(NamedCellId('a')),
                      SpecTester.ref(NamedCellId('b'))
                    ]
                  )
                )
        )).run());

    test('Shadowing expression cells defined outside function', () =>
        BuildTester('add(a, b) = a + b;'
            'x = a + b',

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
        ).hasNamed('x', tester: SpecTester.ref(
            AppliedCellId(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('a'),
                  NamedCellId('b')
                ]
            )
        )).hasApplication(
            operator: NamedCellId('+'),
            operands: [
              NamedCellId('a'),
              NamedCellId('b')
            ],

            tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('+')),
                operands: [
                  SpecTester.ref(NamedCellId('a')),
                  SpecTester.ref(NamedCellId('b'))
                ]
            )
        ).hasNamed('add', tester: SpecTester.func(
            arguments: [NamedCellId('a'), NamedCellId('b')],
            definition: SpecTester.ref(
                AppliedCellId(
                    operator: NamedCellId('+'),
                    operands: [NamedCellId('a'), NamedCellId('b')]
                )
            ),
            tester: FunctionTester()
                .hasApplication(
                operator: NamedCellId('+'),
                operands: [
                  NamedCellId('a'),
                  NamedCellId('b')
                ],

                local: true,

                tester: SpecTester.apply(
                    operator: SpecTester.ref(NamedCellId('+')),
                    operands: [
                      SpecTester.ref(NamedCellId('a')),
                      SpecTester.ref(NamedCellId('b'))
                    ]
                )
            )
        )).run());

    test('Nested functions', () =>
      BuildTester('inc(n) = {'
          'x = add-delta(n)\n'
          'add-delta(m) = m + delta;'
          'x'
          '}\n'
          'delta = 1\n'
          'x = inc(y);',

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
      ).hasNamed('x', tester: SpecTester.ref(
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

          tester: SpecTester.apply(
              operator: SpecTester.ref(NamedCellId('inc')),
              operands: [
                SpecTester.ref(NamedCellId('y')),
              ]
          )
      ).hasNamed(
          'delta',
          tester: SpecTester.value(1)
      ).hasNamed('inc', tester: SpecTester.func(
          arguments: [NamedCellId('n')],
          definition: SpecTester.ref(NamedCellId('x')),
          tester: FunctionTester()
              .hasApplication(
                operator: NamedCellId('add-delta'),
                operands: [
                  NamedCellId('n'),
                ],

                tester: SpecTester.apply(
                    operator: SpecTester.ref(NamedCellId('add-delta')),
                    operands: [
                      SpecTester.ref(NamedCellId('n')),
                    ]
                )
              )
              .hasNamed(
                'x',
                tester: SpecTester.ref(
                  AppliedCellId(
                      operator: NamedCellId('add-delta'),
                      operands: [
                        NamedCellId('n'),
                      ]
                  )
                ),
                local: true
              )
              .hasNamed('add-delta', tester: SpecTester.func(
                arguments: [NamedCellId('m')],
                definition: SpecTester.ref(
                  AppliedCellId(
                    operator: NamedCellId('+'),
                    operands: [
                      NamedCellId('m'),
                      NamedCellId('delta')
                    ]
                  )
                ),

                tester: FunctionTester()
                  .hasApplication(
                    operator: NamedCellId('+'),
                    operands: [
                      NamedCellId('m'),
                      NamedCellId('delta')
                    ],

                    tester: SpecTester.apply(
                        operator: SpecTester.ref(NamedCellId('+')),
                        operands: [
                          SpecTester.ref(NamedCellId('m')),
                          SpecTester.ref(NamedCellId('delta'))
                        ]
                    ),

                    local: true
                  )
                  .hasNamed('delta', local: false)
              ))
      )).run());

    test('Recursive function', () =>
      BuildTester('f(x) = f(x - 1) + 1',
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
            ),
            Operator(
                name: '-',
                type: OperatorType.infix,
                precedence: 5,
                leftAssoc: true
            )
          ]
      ).hasNamed('f', tester: SpecTester.func(
        arguments: [NamedCellId('x')],
        definition: SpecTester.ref(
          AppliedCellId(
            operator: NamedCellId('+'),
            operands: [
              AppliedCellId(
                  operator: NamedCellId('f'),
                  operands: [
                    AppliedCellId(
                      operator: NamedCellId('-'),
                      operands: [
                        NamedCellId('x'),
                        ValueCellId(1)
                      ]
                    )
                  ]
              ),
              ValueCellId(1)
            ]
          )
        ),

        tester: FunctionTester().hasNamed('f', local: false)
      )).run());

    test('Mutually recursive functions', () =>
        BuildTester('f(x) = g(x) + 1;'
            'g(y) = f(y) + 2',
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
              ),
            ]
        ).hasNamed('f', tester: SpecTester.func(
            arguments: [NamedCellId('x')],
            definition: SpecTester.ref(
                AppliedCellId(
                    operator: NamedCellId('+'),
                    operands: [
                      AppliedCellId(
                          operator: NamedCellId('g'),
                          operands: [
                            NamedCellId('x'),
                          ]
                      ),
                      ValueCellId(1)
                    ]
                )
            ),

            tester: FunctionTester().hasNamed('g', local: false)
        )).hasNamed('g', tester: SpecTester.func(
            arguments: [NamedCellId('y')],
            definition: SpecTester.ref(
                AppliedCellId(
                    operator: NamedCellId('+'),
                    operands: [
                      AppliedCellId(
                          operator: NamedCellId('f'),
                          operands: [
                            NamedCellId('y'),
                          ]
                      ),
                      ValueCellId(2)
                    ]
                )
            ),

            tester: FunctionTester().hasNamed('f', local: false)
        )).run());
  });

  group('Variable cell declarations', () {
    test('Simple variable declarations', () =>
      BuildTester('var(a); var(b)')
        .hasNamed('a', tester: SpecTester.variable())
        .hasNamed('b', tester: SpecTester.variable())
        .run());

    test('Variable declarations nested in other cells', () =>
      BuildTester('f(x, var(y))')
        .hasNamed('x')
        .hasNamed('y', tester: SpecTester.variable())
        .hasApplication(
          operator: NamedCellId('f'),
          operands: [
            NamedCellId('x'),
            NamedCellId('y')
          ],

          tester: SpecTester.apply(
            operator: SpecTester.ref(NamedCellId('f')),
            operands: [
              SpecTester.ref(NamedCellId('x')),
              SpecTester.ref(NamedCellId('y'))
            ]
          )
        )
        .run());

    test('Variable declarations following cell declarations', () =>
      BuildTester('f(x, y); var(y)')
          .hasNamed('x')
          .hasNamed('y', tester: SpecTester.variable())
          .hasApplication(
            operator: NamedCellId('f'),
            operands: [
              NamedCellId('x'),
              NamedCellId('y')
            ],

            tester: SpecTester.apply(
              operator: SpecTester.ref(NamedCellId('f')),
              operands: [
                SpecTester.ref(NamedCellId('x')),
                SpecTester.ref(NamedCellId('y'))
              ]
            )
          )
          .run());

    test('Variable declarations preceding cell declarations', () =>
        BuildTester('var(y); f(x, y)')
            .hasNamed('x')
            .hasNamed('y', tester: SpecTester.variable())
            .hasApplication(
              operator: NamedCellId('f'),
              operands: [
                NamedCellId('x'),
                NamedCellId('y')
              ],

              tester: SpecTester.apply(
                operator: SpecTester.ref(NamedCellId('f')),
                operands: [
                  SpecTester.ref(NamedCellId('x')),
                  SpecTester.ref(NamedCellId('y'))
                ]
              )
            )
            .run());
  });

  group('External cell declarations', () {
    test('Named cells', () =>
      BuildTester('a; external(a); external(b)')
          .hasNamed('a', attributes: {
            Attributes.external: true
          })
          .hasNamed('b', attributes: {
            Attributes.external: true
          })
          .run());

    test('Function cells', () =>
        BuildTester(
            'c = a + b; external(+(a, b));',

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
        ).hasNamed('+',
            tester: SpecTester.func(
                arguments: [NamedCellId('a'), NamedCellId('b')],
                definition: SpecTester.stub(),
                tester: FunctionTester()
            ),

            attributes: {
              Attributes.external: true
            }
        ).run());

    test('Malformed: External declaration on defined cell', () {
      final tester = BuildTester(
          'a = b\n external(a)',

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
      expect(tester.run, throwsA(isA<BuildError>()));
    });

    test('Malformed: Redefining external cell', () {
      final tester = BuildTester(
          'external(a);a = b',

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
      expect(tester.run, throwsA(isA<BuildError>()));
    });

    test('Malformed: External declaration on defined function cell', () {
      final tester = BuildTester(
          'f(n) = n + 1\n external(f(n))',

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
      expect(tester.run, throwsA(isA<BuildError>()));
    });

    test('Malformed: Redefining external function cell', () {
      final tester = BuildTester(
          'external(f(n)); f(n) = n + 1',

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
      expect(tester.run, throwsA(isA<BuildError>()));
    });

    test('Malformed: literals in external declaration', () {
      final tester = BuildTester('external(123)');
      expect(tester.run, throwsA(isA<BuildError>()));
    });

    test('Malformed: Multiple cells in external declaration', () {
      final tester = BuildTester('external(a, b, c)');
      expect(tester.run, throwsA(isA<BuildError>()));
    });

    test('Malformed: Literals in function argument list', () {
      final tester = BuildTester('external(f(a, 1, b))');
      expect(tester.run, throwsA(isA<BuildError>()));
    });

    test('Malformed: Expressions in function argument list', () {
      final tester = BuildTester('external(f(a, g(x), b))');
      expect(tester.run, throwsA(isA<BuildError>()));
    });
  });

  group('Malformed definitions', () {
    test('Redefining Literal', () {
      final builder = BuildTester(
          '123 = a',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            )
          ]
      );

      expect(builder.run, throwsA(isA<BuildError>()));
    });

    test('Function with literal as identifier', () {
      final builder = BuildTester(
          '"fn"(x) = g(x)',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            )
          ]
      );

      expect(builder.run, throwsA(isA<BuildError>()));
    });

    test('Literals as argument names', () {
      final builder = BuildTester(
          'fn(x, y, 1) = g(x, y)',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            )
          ]
      );

      expect(builder.run, throwsA(isA<BuildError>()));
    });

    test('Expressions as argument names', () {
      final builder = BuildTester(
          'fn(x, y(z)) = g(x, y)',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            )
          ]
      );

      expect(builder.run, throwsA(isA<BuildError>()));
    });

    test('Empty block definition', () {
      final builder = BuildTester(
          'fn(x) = {}',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            )
          ]
      )..hasNamed('fn',
        tester: SpecTester.func(
            arguments: [NamedCellId('x')],

            // The definition doesn't matter. This tester is only added
            // to force the definition of `fn` to be built.
            definition: SpecTester.stub(),
            tester: FunctionTester()
        )
      );

      expect(builder.run, throwsA(isA<BuildError>()));
    });

    test('Multiple definitions for named cell', () {
      final builder = BuildTester(
          'a = b\nb = c\na = 2',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            )
          ]
      );

      expect(builder.run, throwsA(isA<BuildError>()));
    });

    test('Multiple definitions for function cell', () {
      final builder = BuildTester(
          'f(x) = x; g(x) = x; f(x) = z(x)',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            )
          ]
      );

      expect(builder.run, throwsA(isA<BuildError>()));
    });

    test('Redefining function argument cells', () {
      final builder = BuildTester(
          'add(a, b) = {'
              'a = b + 1;'
              'a + b'
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
      )..hasNamed('add',
          tester: SpecTester.func(
              arguments: [NamedCellId('a'), NamedCellId('b')],

              // The definition doesn't matter. This tester is only added
              // to force the definition of `fn` to be built.
              definition: SpecTester.stub(),
              tester: FunctionTester()
          )
      );

      expect(builder.run, throwsA(isA<BuildError>()));
    });
  });

  group('Malformed variable cell declarations', () {
    test('Literals', () {
      final tester = BuildTester('var(123)');

      expect(tester.run(), throwsA(isA<BuildError>()));
    });

    test('Expressions', () {
      final tester = BuildTester('var(f(x,y))');

      expect(tester.run(), throwsA(isA<BuildError>()));
    });

    test('Empty cell list', () {
      final tester = BuildTester('var()');

      expect(tester.run(), throwsA(isA<BuildError>()));
    });

    test('Incompatible var declaration with cell definition', () {
      final tester = BuildTester(
          'a = b; var(a)',

          operators: [
            Operator(
                name: '=',
                type: OperatorType.infix,
                precedence: 1,
                leftAssoc: false
            )
          ]
      );

      expect(tester.run(), throwsA(isA<BuildError>()));
    });
  });
}
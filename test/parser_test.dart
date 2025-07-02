import 'package:live_cell/lexer/index.dart';
import 'package:live_cell/parser/index.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

/// Parse a source string.
///
/// Returns a stream of the parsed [Expression]s.
Stream<Expression> parse(String src, {
  Iterable<Operator>? operators
}) => Stream.fromIterable([src])
    .transform(Lexer())
    .transform(Parser(OperatorTable(operators ?? [])));

/// Test that parsing a source stream produces the expected [Expression]s.
///
/// [operators] is an optional list of infix operators to register while
/// parsing [src].
Future<void> testParser(final String src, final List<Expression> expected, {
  Iterable<Operator>? operators
}) async {
  final expressions = parse(src, operators: operators);
  expect(await expressions.toList(), equals(expected));
}

void main() {
  group('Test parsing atoms', () {
    test('Identifiers', () async {
      await testParser(
          'a; bc; var1\nvar2',
        [
          NamedCell('a'),
          NamedCell('bc'),
          NamedCell('var1'),
          NamedCell('var2')
        ]
      );
    });

    test('Literals', () => testParser(
        '123; 2.125\n "hello world"\n an-identifier',
        [
          Constant(123),
          Constant(2.125),
          Constant('hello world'),
          NamedCell('an-identifier')
        ]
    ));
  });

  group('Test parsing application expressions', () {
    test('Application with one argument', () => testParser(
      'fn(arg1)',
      [
        Operation(
            operator: NamedCell('fn'),
            args: [NamedCell('arg1')]
        )
      ]
    ));

    test('Application with multiple arguments', () => testParser(
      'fn2(\nan-arg,234\n, another-arg)',
      [
        Operation(
            operator: NamedCell('fn2'),
            args: [
              NamedCell('an-arg'),
              Constant(234),
              NamedCell('another-arg')
            ]
        )
      ]
    ));

    test('Nested application expressions', () => testParser(
      'op(arg1, fn(arg2,\n3), "x")',
      [
        Operation(
          operator: NamedCell('op'),
          args: [
            NamedCell('arg1'),
            Operation(
                operator: NamedCell('fn'),
                args: [
                  NamedCell('arg2'),
                  Constant(3)
                ]
            ),
            Constant("x")
          ]
        )
      ]
    ));

    test('Expression as operator', () => testParser(
      'fn1(a, b, c)(arg1, "value", arg2)',
      [
        Operation(
          operator: Operation(
              operator: NamedCell('fn1'),
              args: [
                NamedCell('a'),
                NamedCell('b'),
                NamedCell('c')
              ]
          ),

          args: [
            NamedCell('arg1'),
            Constant("value"),
            NamedCell('arg2')
          ]
        )
      ]
    ));

    test('Malformed: Missing closing parenthesis', () {
      expect(() => parse('fn(a, b, c').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('fn(a, b, c;').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));
    });

    test('Malformed: Missing separator between arguments', () {
      expect(() => parse('fn(a, b c)').toList(),
        throwsA(isA<UnexpectedTokenParseError>()));
    });

    test('Malformed: Hard terminator in argument list', () {
      expect(() => parse('fn(a, b,; c)').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));
    });
  });

  group('Parenthesized expressions', () {
    test('Parenthesized identifier', () => testParser(
        '(an-id)',
        [
          NamedCell('an-id')
        ]
      ));

    test('Parenthesized literal', () => testParser(
        '(1234)',
        [
          Constant(1234)
        ]
      ));

    test('Parenthesized application', () => testParser(
      '(fn(a, b, c))',
      [
        Operation(
          operator: NamedCell('fn'),
          args: [
            NamedCell('a'),
            NamedCell('b'),
            NamedCell('c')
          ]
        )
      ]
    ));

    test('Parenthesized application operands', () => testParser(
      'fn((a), b)',
      [
        Operation(
          operator: NamedCell('fn'),
          args: [
            NamedCell('a'),
            NamedCell('b')
          ]
        )
      ]
    ));

    test('Nested parenthesized expressions', () => testParser(
      '((a))',
      [
        NamedCell('a')
      ]
    ));

    test('Soft terminators ignored in parenthesis', () => testParser(
      '(fn\n(a))',
      [
        Operation(
          operator: NamedCell('fn'),
          args: [
            NamedCell('a')
          ]
        )
      ]
    ));

    test('Malformed: Missing closing parenthesis', () {
      expect(() => parse('(a').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('((a)').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));
    });

    test('Malformed: hard terminator within parenthesis', () {
      // This test relies on the `,` being allowed only within
      // argument lists
      expect(() => parse('(fn;(a, b))').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));
    });
  });

  group('Blocks', () {
    test('Block with a single expression', () => testParser(
      '{\nfn(x,\ny) }',
      [
        Block(
          expressions: [
            Operation(
              operator: NamedCell('fn'),
              args: [
                NamedCell('x'),
                NamedCell('y')
              ]
            )
          ]
        )
      ]
    ));

    test('Block with multiple expressions', () => testParser(
      '{fn(a, b, c); g(x)\n\n123;\nu(arg1\n,arg2)}',
      [
        Block(
          expressions: [
            Operation(
                operator: NamedCell('fn'),
                args: [
                  NamedCell('a'),
                  NamedCell('b'),
                  NamedCell('c')
                ]
            ),

            Operation(
                operator: NamedCell('g'),
                args: [
                  NamedCell('x')
                ]
            ),

            Constant(123),

            Operation(
                operator: NamedCell('u'),
                args: [
                  NamedCell('arg1'),
                  NamedCell('arg2')
                ]
            )
          ]
        )
      ]
    ));

    test('Nested Blocks', () => testParser(
        '{ f1(a1); { f2(a1, a2)\n add(x,y)}; f3("1", x)}',
        [
          Block(
              expressions: [
                Operation(
                  operator: NamedCell('f1'),
                  args: [
                    NamedCell('a1')
                  ]
                ),

                Block(
                  expressions: [
                    Operation(
                        operator: NamedCell('f2'),
                        args: [
                          NamedCell('a1'),
                          NamedCell('a2')
                        ]
                    ),
                    Operation(
                        operator: NamedCell('add'),
                        args: [
                          NamedCell('x'),
                          NamedCell('y')
                        ]
                    )
                  ]
                ),

                Operation(
                    operator: NamedCell('f3'),
                    args: [
                      Constant("1"),
                      NamedCell('x')
                    ]
                )
              ]
          )
        ]
    ));

    test('Malformed: Missing closing brace', () {
      expect(() => parse('{a; b\n').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));
    });
  });

  group('Infix operators', () {
    test('Single operator', () => testParser(
      'a + b',
      [
        Operation(
            operator: NamedCell('+'),
            args: [
              NamedCell('a'),
              NamedCell('b')
            ]
        )
      ],

      operators: [
        Operator(
            name: '+',
            type: OperatorType.infix,
            precedence: 1,
            leftAssoc: true
        )
      ]
    ));

    test('Multiple operators with varying precedence', () => testParser(
        'a * b + c / d',
        [
          Operation(
            operator: NamedCell('+'),
            args: [
              Operation(
                  operator: NamedCell('*'),
                  args: [
                    NamedCell('a'),
                    NamedCell('b')
                  ]
              ),
              Operation(
                  operator: NamedCell('/'),
                  args: [
                    NamedCell('c'),
                    NamedCell('d')
                  ]
              )
            ]
          )
        ],

        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: true
          ),
          Operator(
              name: '*',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          ),
          Operator(
              name: '/',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          )
        ]
    ));

    test('Left associativity', () => testParser(
        'a + b + c + d',
        [
          Operation(
              operator: NamedCell('+'),
              args: [
                Operation(
                  operator: NamedCell('+'),
                  args: [
                    Operation(
                      operator: NamedCell('+'),
                      args: [
                        NamedCell('a'),
                        NamedCell('b')
                      ]
                    ),
                    NamedCell('c')
                  ]
                ),
                NamedCell('d')
              ]
          )
        ],

        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: true
          )
        ]
    ));

    test('Right associativity', () => testParser(
        'a + b + c + d',
        [
          Operation(
              operator: NamedCell('+'),
              args: [
                NamedCell('a'),
                Operation(
                    operator: NamedCell('+'),
                    args: [
                      NamedCell('b'),
                      Operation(
                          operator: NamedCell('+'),
                          args: [
                            NamedCell('c'),
                            NamedCell('d')
                          ]
                      ),
                    ]
                ),
              ]
          )
        ],

        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]
    ));

    test('Controlling precedence with parenthesis', () => testParser(
        'a * (b + c) / d',
        [
          Operation(
              operator: NamedCell('/'),
              args: [
                Operation(
                    operator: NamedCell('*'),
                    args: [
                      NamedCell('a'),
                      Operation(
                          operator: NamedCell('+'),
                          args: [
                            NamedCell('b'),
                            NamedCell('c')
                          ]
                      )
                    ]
                ),
                NamedCell('d')
              ]
          )
        ],

        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: true
          ),
          Operator(
              name: '*',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          ),
          Operator(
              name: '/',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          )
        ]
    ));

    test('Controlling associativity with parenthesis', () => testParser(
        'a + (b + c) + d',
        [
          Operation(
              operator: NamedCell('+'),
              args: [
                Operation(
                    operator: NamedCell('+'),
                    args: [
                      NamedCell('a'),
                      Operation(
                          operator: NamedCell('+'),
                          args: [
                            NamedCell('b'),
                            NamedCell('c')
                          ]
                      ),
                    ]
                ),
                NamedCell('d')
              ]
          )
        ],

        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: true
          )
        ]
    ));

    test('Application as infix operator operand', () => testParser(
        'a * b + f(c) / g(d, e)',
        [
          Operation(
              operator: NamedCell('+'),
              args: [
                Operation(
                    operator: NamedCell('*'),
                    args: [
                      NamedCell('a'),
                      NamedCell('b')
                    ]
                ),
                Operation(
                    operator: NamedCell('/'),
                    args: [
                      Operation(
                          operator: NamedCell('f'),
                          args: [
                            NamedCell('c')
                          ]
                      ),
                      Operation(
                          operator: NamedCell('g'),
                          args: [
                            NamedCell('d'),
                            NamedCell('e')
                          ]
                      ),
                    ]
                )
              ]
          )
        ],

        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: true
          ),
          Operator(
              name: '*',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          ),
          Operator(
              name: '/',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          )
        ]
    ));

    test('Infix operator as operand', () => testParser(
        'a + +',
        [
          Operation(
              operator: NamedCell('+'),
              args: [
                NamedCell('a'),
                NamedCell('+')
              ]
          )
        ],
        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: true
          )
        ]
    ));

    test('Soft terminators ignored in parenthesis', () => testParser(
        '(a * b\n + c /\n\n d)',
        [
          Operation(
              operator: NamedCell('+'),
              args: [
                Operation(
                    operator: NamedCell('*'),
                    args: [
                      NamedCell('a'),
                      NamedCell('b')
                    ]
                ),
                Operation(
                    operator: NamedCell('/'),
                    args: [
                      NamedCell('c'),
                      NamedCell('d')
                    ]
                )
              ]
          )
        ],

        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: true
          ),
          Operator(
              name: '*',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          ),
          Operator(
              name: '/',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          )
        ]
    ));

    test('Blocks as operands', () => testParser(
        'inc(n) = { next = n + 1; next}',
        [
          Operation(
            operator: NamedCell('='),
            args: [
              Operation(
                operator: NamedCell('inc'),
                args: [
                  NamedCell('n')
                ]
              ),
              Block(
                expressions: [
                  Operation(
                      operator: NamedCell('='),
                      args: [
                        NamedCell('next'),
                        Operation(
                          operator: NamedCell('+'),
                          args: [
                            NamedCell('n'),
                            Constant(1)
                          ]
                        )
                      ]
                  ),
                  NamedCell('next')
                ]
              )
            ]
          )
        ],

        operators: [
          Operator(
              name: '+',
              type: OperatorType.infix,
              precedence: 5,
              leftAssoc: true
          ),
          Operator(
              name: '=',
              type: OperatorType.infix,
              precedence: 1,
              leftAssoc: false
          )
        ]
    ));

    test('Malformed: Identifier not registered as operator', () {
      expect(() => parse('a + b').toList(),
        throwsA(isA<UnexpectedTokenParseError>()));
    });

    test('Malformed: missing operand', () {
      final operators = [
        Operator(
            name: '+',
            type: OperatorType.infix,
            precedence: 1,
            leftAssoc: true
        ),
        Operator(
            name: '*',
            type: OperatorType.infix,
            precedence: 5,
            leftAssoc: true
        ),
        Operator(
            name: '/',
            type: OperatorType.infix,
            precedence: 5,
            leftAssoc: true
        )
      ];

      expect(() => parse('a + ', operators: operators).toList(),
        throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('a * b + c /', operators: operators).toList(),
          throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('a * b / d +', operators: operators).toList(),
          throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('a * b\n + c / d', operators: operators).toList(),
          throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('a * b + \n c / d', operators: operators).toList(),
          throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('(a * b; + c / d)', operators: operators).toList(),
          throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('(a * b +; c / d)', operators: operators).toList(),
          throwsA(isA<UnexpectedTokenParseError>()));
    });
  });
}
import 'package:live_cell/lexer/index.dart';
import 'package:live_cell/parser/index.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

/// Parse a source string.
///
/// Returns a stream of the parsed [AstNode]s.
Stream<AstNode> parse(String src, {
  Iterable<Operator>? operators
}) => Stream.fromIterable([src])
    .transform(Lexer())
    .transform(Parser(OperatorTable(operators ?? [])));

/// Test that parsing a source stream produces the expected [AstNode]s.
///
/// [operators] is an optional list of infix operators to register while
/// parsing [src].
Future<void> testParser(final String src, final List<AstNode> expected, {
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
          Name('a'),
          Name('bc'),
          Name('var1'),
          Name('var2')
        ]
      );
    });

    test('Literals', () => testParser(
        '123; 2.125\n "hello world"\n an-identifier',
        [
          Value(123),
          Value(2.125),
          Value('hello world'),
          Name('an-identifier')
        ]
    ));
  });

  group('Test parsing application expressions', () {
    test('Application with one argument', () => testParser(
      'fn(arg1)',
      [
        Application(
            operator: Name('fn'),
            operands: [Name('arg1')]
        )
      ]
    ));

    test('Application with multiple arguments', () => testParser(
      'fn2(\nan-arg,234\n, another-arg)',
      [
        Application(
            operator: Name('fn2'),
            operands: [
              Name('an-arg'),
              Value(234),
              Name('another-arg')
            ]
        )
      ]
    ));

    test('Nested application expressions', () => testParser(
      'op(arg1, fn(arg2,\n3), "x")',
      [
        Application(
          operator: Name('op'),
          operands: [
            Name('arg1'),
            Application(
                operator: Name('fn'),
                operands: [
                  Name('arg2'),
                  Value(3)
                ]
            ),
            Value("x")
          ]
        )
      ]
    ));

    test('Expression as operator', () => testParser(
      'fn1(a, b, c)(arg1, "value", arg2)',
      [
        Application(
          operator: Application(
              operator: Name('fn1'),
              operands: [
                Name('a'),
                Name('b'),
                Name('c')
              ]
          ),

          operands: [
            Name('arg1'),
            Value("value"),
            Name('arg2')
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
          Name('an-id')
        ]
      ));

    test('Parenthesized literal', () => testParser(
        '(1234)',
        [
          Value(1234)
        ]
      ));

    test('Parenthesized application', () => testParser(
      '(fn(a, b, c))',
      [
        Application(
          operator: Name('fn'),
          operands: [
            Name('a'),
            Name('b'),
            Name('c')
          ]
        )
      ]
    ));

    test('Parenthesized application operands', () => testParser(
      'fn((a), b)',
      [
        Application(
          operator: Name('fn'),
          operands: [
            Name('a'),
            Name('b')
          ]
        )
      ]
    ));

    test('Nested parenthesized expressions', () => testParser(
      '((a))',
      [
        Name('a')
      ]
    ));

    test('Soft terminators ignored in parenthesis', () => testParser(
      '(fn\n(a))',
      [
        Application(
          operator: Name('fn'),
          operands: [
            Name('a')
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
            Application(
              operator: Name('fn'),
              operands: [
                Name('x'),
                Name('y')
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
            Application(
                operator: Name('fn'),
                operands: [
                  Name('a'),
                  Name('b'),
                  Name('c')
                ]
            ),

            Application(
                operator: Name('g'),
                operands: [
                  Name('x')
                ]
            ),

            Value(123),

            Application(
                operator: Name('u'),
                operands: [
                  Name('arg1'),
                  Name('arg2')
                ]
            )
          ]
        )
      ]
    ));

    test('Block with multiple expressions with hard terminators', () => testParser(
        '{fn(a, b, c); g(x)\n\n123;\nu(arg1\n,arg2);}',
        [
          Block(
              expressions: [
                Application(
                    operator: Name('fn'),
                    operands: [
                      Name('a'),
                      Name('b'),
                      Name('c')
                    ]
                ),

                Application(
                    operator: Name('g'),
                    operands: [
                      Name('x')
                    ]
                ),

                Value(123),

                Application(
                    operator: Name('u'),
                    operands: [
                      Name('arg1'),
                      Name('arg2')
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
                Application(
                  operator: Name('f1'),
                  operands: [
                    Name('a1')
                  ]
                ),

                Block(
                  expressions: [
                    Application(
                        operator: Name('f2'),
                        operands: [
                          Name('a1'),
                          Name('a2')
                        ]
                    ),
                    Application(
                        operator: Name('add'),
                        operands: [
                          Name('x'),
                          Name('y')
                        ]
                    )
                  ]
                ),

                Application(
                    operator: Name('f3'),
                    operands: [
                      Value("1"),
                      Name('x')
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

    test('Malformed: Missing terminator between expressions', () {
      expect(() => parse('{g(m) { f(x); };}').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));

      expect(() => parse('{g(m); { f(x); } u(y)}').toList(),
          throwsA(isA<UnexpectedTokenParseError>()));
    });
  });

  group('Infix operators', () {
    test('Single operator', () => testParser(
      'a + b',
      [
        Application(
            operator: Name('+'),
            operands: [
              Name('a'),
              Name('b')
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
          Application(
            operator: Name('+'),
            operands: [
              Application(
                  operator: Name('*'),
                  operands: [
                    Name('a'),
                    Name('b')
                  ]
              ),
              Application(
                  operator: Name('/'),
                  operands: [
                    Name('c'),
                    Name('d')
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
          Application(
              operator: Name('+'),
              operands: [
                Application(
                  operator: Name('+'),
                  operands: [
                    Application(
                      operator: Name('+'),
                      operands: [
                        Name('a'),
                        Name('b')
                      ]
                    ),
                    Name('c')
                  ]
                ),
                Name('d')
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
          Application(
              operator: Name('+'),
              operands: [
                Name('a'),
                Application(
                    operator: Name('+'),
                    operands: [
                      Name('b'),
                      Application(
                          operator: Name('+'),
                          operands: [
                            Name('c'),
                            Name('d')
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
          Application(
              operator: Name('/'),
              operands: [
                Application(
                    operator: Name('*'),
                    operands: [
                      Name('a'),
                      Application(
                          operator: Name('+'),
                          operands: [
                            Name('b'),
                            Name('c')
                          ]
                      )
                    ]
                ),
                Name('d')
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
          Application(
              operator: Name('+'),
              operands: [
                Application(
                    operator: Name('+'),
                    operands: [
                      Name('a'),
                      Application(
                          operator: Name('+'),
                          operands: [
                            Name('b'),
                            Name('c')
                          ]
                      ),
                    ]
                ),
                Name('d')
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
          Application(
              operator: Name('+'),
              operands: [
                Application(
                    operator: Name('*'),
                    operands: [
                      Name('a'),
                      Name('b')
                    ]
                ),
                Application(
                    operator: Name('/'),
                    operands: [
                      Application(
                          operator: Name('f'),
                          operands: [
                            Name('c')
                          ]
                      ),
                      Application(
                          operator: Name('g'),
                          operands: [
                            Name('d'),
                            Name('e')
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
          Application(
              operator: Name('+'),
              operands: [
                Name('a'),
                Name('+')
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
          Application(
              operator: Name('+'),
              operands: [
                Application(
                    operator: Name('*'),
                    operands: [
                      Name('a'),
                      Name('b')
                    ]
                ),
                Application(
                    operator: Name('/'),
                    operands: [
                      Name('c'),
                      Name('d')
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
          Application(
            operator: Name('='),
            operands: [
              Application(
                operator: Name('inc'),
                operands: [
                  Name('n')
                ]
              ),
              Block(
                expressions: [
                  Application(
                      operator: Name('='),
                      operands: [
                        Name('next'),
                        Application(
                          operator: Name('+'),
                          operands: [
                            Name('n'),
                            Value(1)
                          ]
                        )
                      ]
                  ),
                  Name('next')
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
import 'package:live_cell/lexer/index.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Test identifiers', () {
    test('Simple identifiers', () async {
      final src = Stream.fromIterable([
        'var1 + var2'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'var1'),
        IdToken(name: '+'),
        IdToken(name: 'var2'),
        Terminator(soft: true)
      ]));
    });

    test('Identifiers with symbols', () async {
      final src = Stream.fromIterable([
        'a+b*c +1 - d@!&='
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a+b*c'),
        IdToken(name: '+1'),
        IdToken(name: '-'),
        IdToken(name: 'd@!&='),
        Terminator(soft: true)
      ]));
    });

    test('Chunked input', () async {
      final src = Stream.fromIterable([
        'a-really-',
        'long-',
        'identifier'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a-really-long-identifier'),
        Terminator(soft: true)
      ]));
    });
  });

  group('Numbers', () {
    test('Integers', () async {
      final src = Stream.fromIterable([
        'a + 123 * 997'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a'),
        IdToken(name: '+'),
        Literal(value: 123),
        IdToken(name: '*'),
        Literal(value: 997),
        Terminator(soft: true)
      ]));
    });

    test('Floating point/reals', () async {
      final src = Stream.fromIterable([
        '1 + 0.25 * 123.125'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        Literal(value: 1),
        IdToken(name: '+'),
        Literal(value: 0.25),
        IdToken(name: '*'),
        Literal(value: 123.125),
        Terminator(soft: true)
      ]));
    });
  });

  group('Terminators', () {
    test('Soft terminators', () async {
      final src = Stream.fromIterable([
        'a + b\nc = d\n\nf = g'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a'),
        IdToken(name: '+'),
        IdToken(name: 'b'),
        Terminator(soft: true),
        IdToken(name: 'c'),
        IdToken(name: '='),
        IdToken(name: 'd'),
        Terminator(soft: true),
        Terminator(soft: true),
        IdToken(name: 'f'),
        IdToken(name: '='),
        IdToken(name: 'g'),
        Terminator(soft: true)
      ]));
    });
    test('Hard terminators', () async {
      final src = Stream.fromIterable([
        'a + b;c = d;;;f = g;'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a'),
        IdToken(name: '+'),
        IdToken(name: 'b'),
        Terminator(soft: false),
        IdToken(name: 'c'),
        IdToken(name: '='),
        IdToken(name: 'd'),
        Terminator(soft: false),
        IdToken(name: 'f'),
        IdToken(name: '='),
        IdToken(name: 'g'),
        Terminator(soft: false),
        Terminator(soft: true)
      ]));
    });
    test('Soft terminators chunked input', () async {
      final src = Stream.fromIterable([
        'a +',
        ' b\nc = d\n',
        '\nf = g'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a'),
        IdToken(name: '+'),
        IdToken(name: 'b'),
        Terminator(soft: true),
        IdToken(name: 'c'),
        IdToken(name: '='),
        IdToken(name: 'd'),
        Terminator(soft: true),
        Terminator(soft: true),
        IdToken(name: 'f'),
        IdToken(name: '='),
        IdToken(name: 'g'),
        Terminator(soft: true)
      ]));
    });
    test('Mixed soft and hard terminators', () async {
      final src = Stream.fromIterable([
        'a + b\nc = d;\n;f = g'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a'),
        IdToken(name: '+'),
        IdToken(name: 'b'),
        Terminator(soft: true),
        IdToken(name: 'c'),
        IdToken(name: '='),
        IdToken(name: 'd'),
        Terminator(soft: false),
        Terminator(soft: true),
        Terminator(soft: false),
        IdToken(name: 'f'),
        IdToken(name: '='),
        IdToken(name: 'g'),
        Terminator(soft: true)
      ]));
    });
  });

  group('Punctuation', () {
    test('Separators', () async {
      final src = Stream.fromIterable([
        'a, b,c , d,,,,,e'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a'),
        Separator(),
        IdToken(name: 'b'),
        Separator(),
        IdToken(name: 'c'),
        Separator(),
        IdToken(name: 'd'),
        Separator(),
        Separator(),
        Separator(),
        Separator(),
        Separator(),
        IdToken(name: 'e'),
        Terminator(soft: true)
      ]));
    });

    test('Parenthesis', () async {
      final src = Stream.fromIterable([
        'fn(a) b(((() )d (x)'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'fn'),
        ParenOpen(),
        IdToken(name: 'a'),
        ParenClose(),
        IdToken(name: 'b'),
        ParenOpen(),
        ParenOpen(),
        ParenOpen(),
        ParenOpen(),
        ParenClose(),
        ParenClose(),
        IdToken(name: 'd'),
        ParenOpen(),
        IdToken(name: 'x'),
        ParenClose(),
        Terminator(soft: true)
      ]));
    });

    test('Braces', () async {
      final src = Stream.fromIterable([
        'fn{a} b{{{{} }d {x}'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'fn'),
        BraceOpen(),
        IdToken(name: 'a'),
        BraceClose(),
        IdToken(name: 'b'),
        BraceOpen(),
        BraceOpen(),
        BraceOpen(),
        BraceOpen(),
        BraceClose(),
        BraceClose(),
        IdToken(name: 'd'),
        BraceOpen(),
        IdToken(name: 'x'),
        BraceClose(),
        Terminator(soft: true)
      ]));
    });
  });

  group('Whitespace and Comments', () {
    test('Whitespace', () async {
      final src = Stream.fromIterable([
        'a +   b\t\t\f   d\n'
        '   \t\f\t   x = y'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a'),
        IdToken(name: '+'),
        IdToken(name: 'b'),
        IdToken(name: 'd'),
        Terminator(soft: true),
        IdToken(name: 'x'),
        IdToken(name: '='),
        IdToken(name: 'y'),
        Terminator(soft: true)
      ]));
    });

    test('Comments', () async {
      final src = Stream.fromIterable([
        'a + b # This is a comment\n'
        'x = y #+ z;\n'
        '#This is a comment that',
        ' is broken into chunks'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        IdToken(name: 'a'),
        IdToken(name: '+'),
        IdToken(name: 'b'),
        Terminator(soft: true),
        IdToken(name: 'x'),
        IdToken(name: '='),
        IdToken(name: 'y'),
        Terminator(soft: true),
        Terminator(soft: true)
      ]));
    });
  });

  group('Strings', () {
    test('Simple double-quote delimited strings', () async {
      final src = Stream.fromIterable([
        '"hello world" + "bye"'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        Literal(value: 'hello world'),
        IdToken(name: '+'),
        Literal(value: 'bye'),
        Terminator(soft: true)
      ]));
    });

    test('Mixed with numbers, identifiers and punctuation', () async {
      final src = Stream.fromIterable([
        '("a"+"b"12)+ d'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        ParenOpen(),
        Literal(value: 'a'),
        IdToken(name: '+'),
        Literal(value: 'b'),
        Literal(value: 12),
        ParenClose(),
        IdToken(name: '+'),
        IdToken(name: 'd'),
        Terminator(soft: true)
      ]));
    });

    test('Containing punctuation', () async {
      final src = Stream.fromIterable([
        '"a(12+ c)"+ d'
      ]);

      final tokens = await src.transform(Lexer()).toList();

      expect(tokens, equals([
        Literal(value: 'a(12+ c)'),
        IdToken(name: '+'),
        IdToken(name: 'd'),
        Terminator(soft: true)
      ]));
    });

    test('Unclosed', () async {
      final src = Stream.fromIterable([
        '"hello world'
      ]);

      final tokens = src.transform(Lexer());

      expect(() async => await tokens.toList(), 
          throwsA(isA<UnclosedStringError>()));
    });
  });
}
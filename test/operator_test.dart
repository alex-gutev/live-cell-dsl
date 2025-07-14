import 'package:live_cell/builder/index.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'build_test_utils.dart';

void main() {
  group('Test declaring operators in source', () {
    test('Infix operators', () => BuildTester(
      'operator(=, infix, 1, right);'
      'operator(+, infix, 5, left);'
      'operator(*, infix, 10);'
      'x = a * b + c * d;'
      'y = z = a + b + c;'
      'w = a * b * c;'
      'var(a); var(b); var(c); var(d);'
    ).hasNamed('x',
      tester: SpecTester.ref(
        AppliedCellId(
          operator: NamedCellId('+'),
          operands: [
            AppliedCellId(
                operator: NamedCellId('*'),
                operands: [
                  NamedCellId('a'),
                  NamedCellId('b')
                ]
            ),
            AppliedCellId(
                operator: NamedCellId('*'),
                operands: [
                  NamedCellId('c'),
                  NamedCellId('d')
                ]
            )
          ]
        )
      )
    ).hasNamed('y',
        tester: SpecTester.ref(
          NamedCellId('z')
        )
    ).hasNamed('z',
        tester: SpecTester.ref(
          AppliedCellId(
            operator: NamedCellId('+'),
            operands: [
              AppliedCellId(
                  operator: NamedCellId('+'),
                  operands: [
                    NamedCellId('a'),
                    NamedCellId('b')
                  ]
              ),
              NamedCellId('c')
            ]
          )
        )
    ).hasNamed('w',
        tester: SpecTester.ref(
            AppliedCellId(
                operator: NamedCellId('*'),
                operands: [
                  AppliedCellId(
                      operator: NamedCellId('*'),
                      operands: [
                        NamedCellId('a'),
                        NamedCellId('b')
                      ]
                  ),
                  NamedCellId('c')
                ]
            )
        )
    ).run());

    test('Malformed operator declaration', () async {
      final sources = [
        'operator();',
        'operator(+);',
        'operator(+, infix);',
        'operator("+", infix, 100);',
        'operator(+, infix, invalid);',
        'operator(+, invalid, 100);',
        'operator(+, infix, 100, invalid);',
        'operator(+, infix, 100, left, 100);'
      ];

      for (final src in sources) {
        expect(BuildTester(src).run, throwsA(isA<BuildError>()));
      }
    });

    test('Duplicate operator declaration', () async {
      final tester = BuildTester(
        'operator(+, infix, 100);'
        'operator(+, infix, 10);'
      );

      expect(tester.run, throwsA(isA<BuildError>()));
    });
  });
}
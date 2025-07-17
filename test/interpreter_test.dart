import 'package:live_cell/builder/index.dart';
import 'package:live_cells_core/live_cells_core.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'interpreter_utils.dart';

void main() {
  group('Computed Cells', () {
    test('Computed cell with one variable', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'out = var(x) + 1;'
      ]);

      final x = tester.getVar(NamedCellId('x'));
      x.value = 1;

      final values = tester.observe(NamedCellId('out'));

      x.value = 2;
      x.value = 3;

      expect(values, equals([2, 3, 4]));
    });

    test('Computed cell with multiple variables', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'out = var(x) + var(y);'
      ]);

      final x = tester.getVar(NamedCellId('x'));
      final y = tester.getVar(NamedCellId('y'));

      x.value = 1;
      y.value = 10;

      final values = tester.observe(NamedCellId('out'));

      x.value = 2;
      x.value = 3;

      y.value = 25;

      MutableCell.batch(() {
        x.value = 14;
        y.value = 23;
      });

      expect(values, equals([11, 12, 13, 28, 37]));
    });

    test('Complex expression computed cell', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'var(x);',
        'var(y);',
        'var(z);',
        'sum = x + y;',
        'out = sum * z;'
      ]);

      final x = tester.getVar(NamedCellId('x'));
      final y = tester.getVar(NamedCellId('y'));
      final z = tester.getVar(NamedCellId('z'));

      x.value = 1;
      y.value = 10;
      z.value = 5;

      final values = tester.observe(NamedCellId('out'));

      x.value = 2;
      x.value = 3;

      y.value = 25;

      MutableCell.batch(() {
        x.value = 14;
        y.value = 23;
      });

      z.value = 10;

      expect(values, equals([55, 60, 65, 140, 185, 370]));
    });
  });

  group('Functions', () {
    test('Simple function', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'inc(n) = n + 1;',
        'out = inc(var(x));'
      ]);

      final x = tester.getVar(NamedCellId('x'));

      x.value = 1;

      final values = tester.observe(NamedCellId('out'));

      x.value = 2;
      x.value = 3;
      x.value = 10;

      expect(values, equals([2, 3, 4, 11]));
    });

    test('N-ary function', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'add(a, b) = a + b;',
        'out = add(var(x), var(y));'
      ]);

      final x = tester.getVar(NamedCellId('x'));
      final y = tester.getVar(NamedCellId('y'));

      x.value = 1;
      y.value = 2;

      final values = tester.observe(NamedCellId('out'));

      x.value = 5;
      y.value = 7;

      MutableCell.batch(() {
        x.value = 12;
        y.value = 37;
      });

      expect(values, equals([3, 7, 12, 49]));
    });

    test('Multi-expression function', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'frob(a, b) = {',
        ' result = c + d;'
        ' c = a * a;',
        ' d = b * b;',
        ' result'
        '};'
        'out = frob(var(x), var(y));'
      ]);

      final x = tester.getVar(NamedCellId('x'));
      final y = tester.getVar(NamedCellId('y'));

      x.value = 1;
      y.value = 2;

      final values = tester.observe(NamedCellId('out'));

      x.value = 3;
      y.value = 5;

      MutableCell.batch(() {
        x.value = 6;
        y.value = 4;
      });

      expect(values, equals([5, 13, 34, 52]));
    });

    test('Outer cell references', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'out = inc(x);',
        'inc(n) = n + delta;',
        'var(delta);',
        'var(x);'
      ]);

      final x = tester.getVar(NamedCellId('x'));
      final delta = tester.getVar(NamedCellId('delta'));

      x.value = 5;
      delta.value = 1;

      final values = tester.observe(NamedCellId('out'));

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 5;
      });

      expect(values, equals([6, 8, 9, 15]));
    });

    test('Nested Function', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'out = inc(x);',
        'inc(n) = {',
        ' _inc(m) = m + delta;',
        ' _inc(n)',
        '};',
        'var(delta);',
        'var(x);'
      ]);

      final x = tester.getVar(NamedCellId('x'));
      final delta = tester.getVar(NamedCellId('delta'));

      x.value = 5;
      delta.value = 1;

      final values = tester.observe(NamedCellId('out'));

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 5;
      });

      expect(values, equals([6, 8, 9, 15]));
    });

    test('Lexical Scope', () async {
      // This tests shadowing and ensures that cells are lexically scoped
      // rather than dynamically scoped.

      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'f(x) = {',
        ' delta = 5;',
        ' g(x + delta)',
        '};',
        'var(delta);'
        'g(x) = x + delta;'
        'out = f(x);',
        'var(x);'
      ]);

      final x = tester.getVar(NamedCellId('x'));
      final delta = tester.getVar(NamedCellId('delta'));

      x.value = 5;
      delta.value = 1;

      final values = tester.observe(NamedCellId('out'));

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 8;
      });

      expect(values, equals([11, 13, 14, 23]));
    });
  });
}
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
        ' result = c + d;',
        ' c = a * a;',
        ' d = b * b;',
        ' result',
        '};',
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

    test('Function Closure', () async {
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

    test('Nested Function Closure', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'out = inc(x);',
        'inc(n) = {',
        ' delta = 5;',
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
        delta.value = 3;
      });

      expect(values, equals([10, 12, 15]));
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
        'var(delta);',
        'g(x) = x + delta;',
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

    test('Lexical Scope Function Arguments', () async {
      // This tests shadowing and ensures that argument cells do not dynamically
      // shadow global cells with the same name

      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'f(x, delta) = {',
        ' g(x + delta)',
        '};',
        'var(delta);',
        'g(x) = x + delta;',
        'out = f(x, 5);',
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
    
    test('Higher order function with local closure', () async {
      final tester = InterpreterTester();
      
      await tester.build([
        'import(core);',
        'make-inc(n) = {',
        ' delta = n + 1;',
        ' inc(m) = m + delta;',
        ' inc',
        '};',
        'var(x);',
        'var(delta);',
        'f = make-inc(1);',
        'out = f(x);'
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

      expect(values, equals([7, 9, 12]));
    });

    test('Higher order function with local and global closure', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'make-inc(n) = {',
        ' inc(m) = m + n + delta;',
        ' inc',
        '};',
        'var(x);',
        'var(delta);',
        'f = make-inc(1);',
        'out = f(x);'
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

      expect(values, equals([7, 9, 10, 19]));
    });

    test('Higher order function with local + global closure and shadowing', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'make-inc(n) = {',
        ' inc(m) = m + n + delta;',
        ' inc',
        '};',
        'g(x) = {',
        ' delta = 10;'
        ' x + delta;',
        '};',
        'var(x);',
        'var(delta);',
        'f = make-inc(1);',
        'out = g(f(x));'
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

      expect(values, equals([17, 19, 20, 29]));
    });

    test('Recursive Function (Factorial)', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'factorial(n) = select(',
        '  n > 1,',
        '  n * factorial(n - 1),',
        '  1',
        ');',
        'out = factorial(var(x));'
      ]);

      final x = tester.getVar(NamedCellId('x'));

      x.value = 2;
      
      final values = tester.observe(NamedCellId('out'));
      
      x.value = 0;
      x.value = 5;
      x.value = 7;
      
      expect(values, equals([2, 1, 120, 5040]));
    });

    test('Tail-Recursive Function (Factorial)', () async {
      // NOTE: This test doesn't test tail call optimization. It only tests
      // that tail recursive functions are executed correctly.

      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'factorial(n) = {',
        '  calc(n, acc) = '
        '    select(',
        '      n > 1,',
        '      calc(n - 1, acc * n),',
        '      acc',
        '    );',
        '  calc(n, 1);'
        '};'
        'out = factorial(var(x));'
      ]);

      final x = tester.getVar(NamedCellId('x'));

      x.value = 2;

      final values = tester.observe(NamedCellId('out'));

      x.value = 0;
      x.value = 5;
      x.value = 7;

      expect(values, equals([2, 1, 120, 5040]));
    });

    test('Recursive Function (Fibonacci)', () async {
      final tester = InterpreterTester();

      await tester.build([
        'import(core);',
        'fib(n) = select(',
        '  n < 2,',
        '  1,',
        '  fib(n - 1) + fib(n - 2)',
        ');',
        'out = fib(var(x));'
      ]);

      final x = tester.getVar(NamedCellId('x'));

      x.value = 0;

      final values = tester.observe(NamedCellId('out'));

      x.value = 1;
      x.value = 2;
      x.value = 3;
      x.value = 4;
      x.value = 5;
      x.value = 6;

      expect(values, equals([1, 1, 2, 3, 5, 8, 13]));
    });
  });
}
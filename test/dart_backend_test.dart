import 'package:live_cells_core/live_cells_core.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'generated/single_argument_computed_cell.g.dart' as test1;
import 'generated/multi_argument_computed_cell.g.dart' as test2;
import 'generated/complex_expressions.g.dart' as test3;
import 'generated/simple_function.g.dart' as test4;
import 'generated/nary_function.g.dart' as test5;
import 'generated/multi_expression_function.g.dart' as test6;
import 'generated/function_closure.g.dart' as test7;
import 'generated/nested_functions.g.dart' as test8;
import 'generated/nested_function_closure.g.dart' as test9;
import 'generated/lexical_scope.g.dart' as test10;
import 'generated/lexical_scope_function_arguments.g.dart' as test11;
import 'generated/higher_order_function.g.dart' as test12;
import 'generated/higher_order_function_closure_local.g.dart' as test13;
import 'generated/higher_order_function_closure.g.dart' as test14;
import 'generated/higher_order_function_closure_scope.g.dart' as test15;
import 'generated/recursion.g.dart' as test16;
import 'generated/tail_recursion.g.dart' as test17;
import 'generated/recursion_fibonacci.g.dart' as test18;
import 'generated/mutual_recursion.g.dart' as test19;

void main() {
  group('Computed Cells', () {
    test('Computed cell with one variable', () {
      final x = test1.cells['x'] as MutableCell;
      x.value = 1;

      final values = observe(test1.cells['out']!);

      x.value = 2;
      x.value = 3;

      expect(values, equals([2, 3, 4]));
    });

    test('Computed cell with multiple variables', () {
      final x = test2.cells['x'] as MutableCell;
      final y = test2.cells['y'] as MutableCell;

      x.value = 1;
      y.value = 10;

      final values = observe(test2.cells['out']!);

      x.value = 2;
      x.value = 3;

      y.value = 25;

      MutableCell.batch(() {
        x.value = 14;
        y.value = 23;
      });

      expect(values, equals([11, 12, 13, 28, 37]));
    });

    test('Complex expression computed cell', () {
      final x = test3.cells['x'] as MutableCell;
      final y = test3.cells['y'] as MutableCell;
      final z = test3.cells['z'] as MutableCell;

      x.value = 1;
      y.value = 10;
      z.value = 5;

      final values = observe(test3.cells['out']!);

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
      final x = test4.cells['x'] as MutableCell;

      x.value = 1;

      final values = observe(test4.cells['out']!);

      x.value = 2;
      x.value = 3;
      x.value = 10;

      expect(values, equals([2, 3, 4, 11]));
    });

    test('N-ary function', () async {
      final x = test5.cells['x'] as MutableCell;
      final y = test5.cells['y'] as MutableCell;

      x.value = 1;
      y.value = 2;

      final values = observe(test5.cells['out']!);

      x.value = 5;
      y.value = 7;

      MutableCell.batch(() {
        x.value = 12;
        y.value = 37;
      });

      expect(values, equals([3, 7, 12, 49]));
    });

    test('Multi-expression function', () async {
      final x = test6.cells['x'] as MutableCell;
      final y = test6.cells['y'] as MutableCell;

      x.value = 1;
      y.value = 2;

      final values = observe(test6.cells['out']!);

      x.value = 3;
      y.value = 5;

      MutableCell.batch(() {
        x.value = 6;
        y.value = 4;
      });

      expect(values, equals([5, 13, 34, 52]));
    });

    test('Function Closure', () async {
      final x = test7.cells['x'] as MutableCell;
      final delta = test7.cells['delta'] as MutableCell;

      x.value = 5;
      delta.value = 1;

      final values = observe(test7.cells['out']!);

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 5;
      });

      expect(values, equals([6, 8, 9, 15]));
    });

    test('Nested Function', () async {
      final x = test8.cells['x'] as MutableCell;
      final delta = test8.cells['delta'] as MutableCell;

      x.value = 5;
      delta.value = 1;

      final values = observe(test8.cells['out']!);

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 5;
      });

      expect(values, equals([6, 8, 9, 15]));
    });

    test('Nested Function Closure', () async {
      final x = test9.cells['x'] as MutableCell;
      final delta = test9.cells['delta'] as MutableCell;

      x.value = 5;
      delta.value = 1;

      final values = observe(test9.cells['out']!);

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

      final x = test10.cells['x'] as MutableCell;
      final delta = test10.cells['delta'] as MutableCell;

      x.value = 5;
      delta.value = 1;

      final values = observe(test10.cells['out']!);

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

      final x = test11.cells['x'] as MutableCell;
      final delta = test11.cells['delta'] as MutableCell;

      x.value = 5;
      delta.value = 1;

      final values = observe(test11.cells['out']!);

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 8;
      });

      expect(values, equals([11, 13, 14, 23]));
    });

    test('Higher order function in global scope', () async {
      final op = test12.cells['op'] as MutableCell;
      final x = test12.cells['x'] as MutableCell;

      op.value = 'inc';
      x.value = 1;

      final values = observe(test12.cells['out']!);

      x.value = 2;
      x.value = 3;

      op.value = 'dec';
      x.value = 10;

      MutableCell.batch(() {
        x.value = 20;
        op.value = 'inc';
      });

      expect(values, equals([2, 3, 4, 2, 9, 21]));
    });

    test('Higher order function with local closure', () async {
      final x = test13.cells['x'] as MutableCell;
      final delta = test13.cells['delta'] as MutableCell;

      x.value = 5;
      delta.value = 1;

      final values = observe(test13.cells['out']!);

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 8;
      });

      expect(values, equals([7, 9, 12]));
    });

    test('Higher order function with local and global closure', () async {
      final x = test14.cells['x'] as MutableCell;
      final delta = test14.cells['delta'] as MutableCell;

      x.value = 5;
      delta.value = 1;

      final values = observe(test14.cells['out']!);

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 8;
      });

      expect(values, equals([7, 9, 10, 19]));
    });

    test('Higher order function with local + global closure and shadowing', () async {
      final x = test15.cells['x'] as MutableCell;
      final delta = test15.cells['delta'] as MutableCell;

      x.value = 5;
      delta.value = 1;

      final values = observe(test15.cells['out']!);

      x.value = 7;
      delta.value = 2;

      MutableCell.batch(() {
        x.value = 10;
        delta.value = 8;
      });

      expect(values, equals([17, 19, 20, 29]));
    });

    test('Recursive Function (Factorial)', () async {
      final x = test16.cells['x'] as MutableCell;

      x.value = 2;

      final values = observe(test16.cells['out']!);

      x.value = 0;
      x.value = 5;
      x.value = 7;

      expect(values, equals([2, 1, 120, 5040]));
    });

    test('Tail-Recursive Function (Factorial)', () async {
      // NOTE: This test doesn't test tail call optimization. It only tests
      // that tail recursive functions are executed correctly.

      final x = test17.cells['x'] as MutableCell;

      x.value = 2;

      final values = observe(test17.cells['out']!);

      x.value = 0;
      x.value = 5;
      x.value = 7;

      expect(values, equals([2, 1, 120, 5040]));
    });

    test('Recursive Function (Fibonacci)', () async {
      final x = test18.cells['x'] as MutableCell;

      x.value = 0;

      final values = observe(test18.cells['out']!);

      x.value = 1;
      x.value = 2;
      x.value = 3;
      x.value = 4;
      x.value = 5;
      x.value = 6;

      expect(values, equals([1, 1, 2, 3, 5, 8, 13]));
    });

    test('Mutually Recursive Functions', () async {
      final x = test19.cells['x'] as MutableCell;

      x.value = 0;

      final values = observe(test19.cells['out']!);

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

List observe(ValueCell cell) {
  final values = [];

  final watch = ValueCell.watch(() {
    values.add(cell());
  });

  addTearDown(watch.stop);

  return values;
}
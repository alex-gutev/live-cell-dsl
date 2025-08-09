import 'dart:io';

import 'package:live_cell/analyzer/index.dart';
import 'package:live_cell/backend/dart/dart_code_generator.dart';
import 'package:live_cell/builder/index.dart';
import 'package:live_cell/common/pipeline.dart';
import 'package:live_cell/interpreter/exceptions.dart';
import 'package:live_cell/lexer/index.dart';
import 'package:live_cell/modules/index.dart';
import 'package:live_cell/optimization/folding.dart';
import 'package:live_cell/parser/index.dart';
import 'package:live_cell/runtime/index.dart';
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
import 'generated/arithmetic.g.dart' as test20;
import 'generated/equality.g.dart' as test21;
import 'generated/comparison.g.dart' as test22;
import 'generated/boolean.g.dart' as test23;
import 'generated/branching.g.dart' as test24;
import 'generated/invalid_operator.g.dart' as test25;
import 'generated/arity_errors.g.dart' as test26;

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

  group('Built in functions', () {
    test('Arithmetic', () {
      final x = test20.cells['x'] as MutableCell;
      final y = test20.cells['y'] as MutableCell;

      x.value = 1;
      y.value = 2;

      final add = observe(test20.cells['out+']!);
      final sub = observe(test20.cells['out-']!);
      final mul = observe(test20.cells['out*']!);
      final div = observe(test20.cells['out/']!);
      final mod = observe(test20.cells['out%']!);

      MutableCell.batch(() {
        x.value = 4;
        y.value = 2;
      });

      MutableCell.batch(() {
        x.value = 8;
        y.value = 3;
      });

      MutableCell.batch(() {
        x.value = 0.5;
        y.value = 2;
      });

      expect(add, equals([3, 6, 11, 2.5]));
      expect(sub, equals([-1, 2, 5, -1.5]));
      expect(mul, equals([2, 8, 24, 1]));
      expect(div, equals([0.5, 2, 8/3, 0.5/2]));
      expect(mod, equals([1, 0, 2, 0.5]));
    });

    test('Equality', () {
      final x = test21.cells['x'] as MutableCell;
      final y = test21.cells['y'] as MutableCell;

      final eq = observe(test21.cells['out-eq']!);
      final neq = observe(test21.cells['out-neq']!);

      x.value = 5;
      y.value = 5;
      y.value = 6;

      x.value = 'hello';
      y.value = 'hello';
      x.value = 'bye';
      x.value = 0;

      expect(eq, equals([
        true,  // null == null
        false, // 5 == null
        true,  // 5 == 5
        false, // 5 == 6
        false, // 'hello' == 6
        true,  // 'hello' == 'hello'
        false, // 'bye' == 'hello'
        false, // 0 == 'hello'
      ]));

      expect(neq, equals([
        false, // null != null
        true,  // 5 != null
        false, // 5 != 5
        true,  // 5 != 6
        true,  // 'hello' != 6
        false, // 'hello' != 'hello'
        true,  // 'bye' != 'hello'
        true,  // 0 != 'hello'
      ]));
    });

    test('Comparison', () {
      final x = test22.cells['x'] as MutableCell;
      final y = test22.cells['y'] as MutableCell;

      x.value = 1;
      y.value = 2;

      final lt = observe(test22.cells['out-lt']!);
      final lte = observe(test22.cells['out-lte']!);
      final gt = observe(test22.cells['out-gt']!);
      final gte = observe(test22.cells['out-gte']!);

      x.value = 2;
      x.value = 3;
      y.value = 4.5;
      x.value = 8.125;

      expect(lt, equals([
        true,  // 1 < 2
        false, // 2 < 2
        false, // 3 < 2
        true,  // 3 < 4.5
        false, // 8.125 < 4.5
      ]));

      expect(lte, equals([
        true,  // 1 <= 2
        true,  // 2 <= 2
        false, // 3 <= 2
        true,  // 3 <= 4.5
        false, // 8.125 <= 4.5
      ]));

      expect(gt, equals([
        false,  // 1 > 2
        false, // 2 > 2
        true, // 3 > 2
        false,  // 3 > 4.5
        true, // 8.125 > 4.5
      ]));

      expect(gte, equals([
        false,  // 1 >= 2
        true,  // 2 >= 2
        true, // 3 >= 2
        false,  // 3 >= 4.5
        true, // 8.125 >= 4.5
      ]));
    });

    test('Boolean', () {
      final x = test23.cells['x'] as MutableCell;
      final y = test23.cells['y'] as MutableCell;

      x.value = false;
      y.value = false;

      final not = observe(test23.cells['out-not']!);
      final and = observe(test23.cells['out-and']!);
      final or = observe(test23.cells['out-or']!);

      y.value = true;
      x.value = true;
      y.value = false;

      expect(not, [
        true,  // not false
        false, // not true
      ]);

      expect(and, equals([
        false, // false and false
        false, // false and true
        true,  // true and true
        false, // true and false
      ]));

      expect(or, equals([
        false, // false or false
        true,  // false or true
        true,  // true or true
        true,  // true or false
      ]));
    });

    test('Branching', () {
      final a = test24.cells['a'] as MutableCell;
      final b = test24.cells['b'] as MutableCell;
      final cond = test24.cells['cond'] as MutableCell;

      cond.value = true;
      a.value = 'x';

      final values = observe(test24.cells['out']!);

      b.value = 'y';
      cond.value = false;

      b.value = 'z';
      a.value = 'w';
      cond.value = true;
      a.value = 'v';

      expect(values, ['x', 'x', 'y', 'z', 'z', 'w', 'v']);
    });
  });

  group('Errors', () {
    test('Operator is not a function', () {
      final f = test25.cells['f'] as MutableCell;
      final x = test25.cells['x'] as MutableCell;
      final out = test25.cells['out']!;

      x.value = 1;
      expect(() => out.value, throwsA(isA<NoSuchMethodError>()));

      f.value = 'inc';
      expect(() => out.value, throwsA(isA<NoSuchMethodError>()));
    });

    test('Incorrect number of arguments', () async {
      final a = test26.cells['a'] as MutableCell;
      final b = test26.cells['b'] as MutableCell;
      final c = test26.cells['c'] as MutableCell;

      a.value = 1;
      b.value = 2;
      c.value = 3;

      final tooFew = test26.cells['too-few']!;
      final tooMany = test26.cells['too-many']!;
      final correct = test26.cells['correct']!;

      expect(() => tooFew.value, throwsA(isA<ArityError>()));
      expect(() => tooMany.value, throwsA(isA<ArityError>()));

      expect(correct.value, equals(3));
    });

    test('Undefined external function', () async {
      final source = [
        'import(core);',
        'external(foo(a));',
        'out = foo(var(x));'
      ];

      final modulePath = '${Directory.current.path}/modules';
      final operators = OperatorTable([]);

      late final builder = CellBuilder(
          operatorTable: operators,
          loadModule: ModuleLoader(
              modulePath: modulePath,
              operators: operators
          )
      );

      final output = StringBuffer();

      final pipeline = Pipeline()
        ..add(SemanticAnalyzer())
        ..add(CellFolder())
        ..add(DartBackend(output));

      await builder.processSource(
          Stream.fromIterable(source)
              .transform(Lexer())
              .transform(Parser(operators))
      );

      expect(() => pipeline.run(builder.scope),
          throwsA(isA<MissingExternalCellError>()));
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
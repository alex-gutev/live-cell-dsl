import 'package:live_cell/builder/index.dart';
import 'package:live_cell/lexer/index.dart';
import 'package:live_cell/parser/index.dart';
import 'package:test/test.dart';

/// Signature of function for running cell expression tests
typedef RunTest = Future<void> Function();

/// Helper for testing the result of [CellBuilder].
class BuildTester {
  /// The builder
  final builder = CellBuilder();

  /// Input expression stream
  final Stream<Expression> expressions;

  /// Test output function
  late RunTest _runTest = () => builder.build(expressions);

  /// Create a tester using a given input string
  BuildTester(String src, {
    List<Operator>? operators
  }) : expressions = Stream.fromIterable([src])
      .transform(Lexer())
      .transform(Parser(OperatorTable(operators ?? [])));

  /// Add a test that checks that a cell with a given [id] has been built.
  ///
  /// If [tester] is not null, it used to test the definition of the cell.
  BuildTester hasCell(CellId id, [ExpressionTester? tester]) {
    final run = _runTest;

    _runTest = () async {
      await run();

      final cell = builder.scope.lookup(id);
      expect(cell, isNotNull);

      tester?.run(
          scope: builder.scope,
          expression: cell!.definition
      );
    };

    return this;
  }

  /// Add a test that checks that a cell named [name] has been built.
  ///
  /// If [tester] is not null, it used to test the definition of the cell.
  BuildTester hasNamed(String name, [ExpressionTester? tester]) =>
      hasCell(NamedCellId(name), tester);

  /// Add a test that checks that a cell for a given expression has been built.
  ///
  /// This methods checks whether the cell representing the expression
  /// with [operator] applied to [operands] has been built.
  ///
  /// If [tester] is not null, it used to test the definition of the cell.
  BuildTester hasApplication({
    required CellId operator,
    required List<CellId> operands,
    ExpressionTester? tester
  }) => hasCell(
      AppliedCellId(
          operator: operator,
          operands: operands
      ),
      tester
  );

  /// Run all tests
  Future<void> run() => _runTest();
}

/// Helper for testing the definition of a cell
sealed class ExpressionTester {
  ExpressionTester();

  /// Create a tester that tests a [CellRef] expression.
  ///
  /// [refId] is the ID of the cell that should be referenced.
  factory ExpressionTester.ref(CellId refId) = _RefExpressionTester;

  /// Create a tester that tests a [CellApplication] expression.
  ///
  /// This tester checks whether the definition of the cell is a
  /// [CellApplication], and runs [operator] on the operator and each tester in
  /// [operands] on the corresponding operands.
  factory ExpressionTester.apply({
    required ExpressionTester operator,
    required List<ExpressionTester> operands
  }) = _ApplyExpressionTester;

  /// Create a tester that checks whether a [CellExpression] is a constant [value].
  factory ExpressionTester.value(value) = _ValueExpressionTester;

  /// Run the test on a given cell definition [expression].
  void run({
    required CellTable scope,
    required CellExpression expression
  });
}

/// [CellRef] expression tester
class _RefExpressionTester extends ExpressionTester {
  final CellId refId;

  _RefExpressionTester(this.refId);

  @override
  void run({
    required CellTable scope,
    required CellExpression expression
  }) {
    expect(expression, isA<CellRef>());
    expect((expression as CellRef).get, equals(scope.get(refId)));
  }
}

/// [CellApplication] tester
class _ApplyExpressionTester extends ExpressionTester {
  final ExpressionTester operator;
  final List<ExpressionTester> operands;

  _ApplyExpressionTester({
    required this.operator,
    required this.operands
  });

  @override
  void run({required CellTable scope, required CellExpression expression}) {
    expect(expression, isA<CellApplication>());

    final apply = expression as CellApplication;

    operator.run(scope: scope, expression: apply.operator);

    expect(expression.operands.length, operands.length);

    for (var i = 0; i < operands.length; i++) {
      operands[i].run(scope: scope, expression: expression.operands[i]);
    }
  }
}

/// [ConstantValue] expression tester
class _ValueExpressionTester extends ExpressionTester {
  final dynamic value;

  _ValueExpressionTester(this.value);

  @override
  void run({required CellTable scope, required CellExpression expression}) {
    expect(expression, isA<ConstantValue>());
    expect((expression as ConstantValue).value, equals(value));
  }
}
import 'package:live_cell/analyzer/index.dart';
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
  final Stream<AstNode> expressions;

  /// Test output function
  late RunTest _runTest = () => builder.build(expressions);

  /// The scope in which the cells are built
  CellTable get scope => builder.scope;

  /// Create a tester using a given input string
  BuildTester(String src, {
    List<Operator>? operators
  }) : expressions = Stream.fromIterable([src])
      .transform(Lexer())
      .transform(Parser(OperatorTable(operators ?? [])));

  /// Add a test that checks that a cell with a given [id] has been built.
  ///
  /// If [tester] is not null, it used to test the definition of the cell.
  ///
  /// If [local] is true, the scope of the cell is tested that it is
  /// equal to [scope]. If [local] is false, the scope of the cell is tested
  /// that it is not equal to [scope].
  ///
  /// If [attributes] is not null, the cell is tested that it has each
  /// attribute in this map and with the expected value.
  BuildTester hasCell(CellId id, {
    ExpressionTester? tester,
    bool local = true,
    Map<String, dynamic>? attributes
  }) {
    final run = _runTest;

    _runTest = () async {
      await run();

      final cell = scope.lookup(id);
      expect(cell, isNotNull, reason: 'Cell not found `$id`');

      await tester?.test(
          scope: scope,
          expression: cell!.definition
      );

      if (local) {
        expect(cell!.scope, equals(scope));
      }
      else {
        expect(cell!.scope, isNot(equals(scope)));
      }

      if (attributes != null) {
        for (final entry in attributes.entries) {
          expect(cell.getAttribute(entry.key), equals(entry.value));
        }
      }
    };

    return this;
  }

  /// Add a test that checks that a cell named [name] has been built.
  ///
  /// If [tester] is not null, it used to test the definition of the cell.
  ///
  /// If [local] is true, the scope of the cell is tested that it is
  /// equal to [scope]. If [local] is false, the scope of the cell is tested
  /// that it is not equal to [scope].
  ///
  /// If [attributes] is not null, the cell is tested that it has each
  /// attribute in this map and with the expected value.
  BuildTester hasNamed(String name, {
    ExpressionTester? tester,
    bool local = true,
    Map<String, dynamic>? attributes
  }) => hasCell(NamedCellId(name),
      tester: tester,
      local: local,
      attributes: attributes
  );

  /// Add a test that checks that a cell for a given expression has been built.
  ///
  /// This methods checks whether the cell representing the expression
  /// with [operator] applied to [operands] has been built.
  ///
  /// If [tester] is not null, it used to test the definition of the cell.
  ///
  /// If [local] is true, the scope of the cell is tested that it is
  /// equal to [scope]. If [local] is false, the scope of the cell is tested
  /// that it is not equal to [scope].
  ///
  /// If [attributes] is not null, the cell is tested that it has each
  /// attribute in this map and with the expected value.
  BuildTester hasApplication({
    required CellId operator,
    required List<CellId> operands,
    ExpressionTester? tester,
    bool local = true,
    Map<String, dynamic>? attributes
  }) => hasCell(
      AppliedCellId(
          operator: operator,
          operands: operands
      ),

      tester: tester,
      local: local,
      attributes: attributes
  );

  /// Run all tests
  Future<void> run() => _runTest();

  /// Run all tests and perform semantic analysis
  Future<void> analyze() async {
    await run();

    final analyzer = SemanticAnalyzer(
        scope: scope
    );

    analyzer.analyze();
  }
}

/// A [BuildTester] for testing function local cells
class FunctionTester extends BuildTester {
  /// The scope in which the function local cells are defined
  late final CellTable _scope;

  @override
  CellTable get scope => _scope;

  FunctionTester() :
    super('') {
    _runTest = () async {};
  }

  @override
  FunctionTester hasCell(CellId id, {
    ExpressionTester? tester,
    bool local = true,
    Map<String, dynamic>? attributes
  }) {
    super.hasCell(id,
        tester: tester,
        local: local,
        attributes: attributes
    );
    return this;
  }

  @override
  FunctionTester hasNamed(String name, {
    ExpressionTester? tester,
    bool local = true,
    Map<String, dynamic>? attributes
  }) {
    super.hasNamed(name,
        tester: tester,
        local: local,
        attributes: attributes
    );
    return this;
  }

  @override
  FunctionTester hasApplication({
    required CellId operator,
    required List<CellId> operands,
    ExpressionTester? tester,
    bool local = true,
    Map<String, dynamic>? attributes
  }) {
    super.hasApplication(
        operator: operator,
        operands: operands,
        tester: tester,
        local: local,
        attributes: attributes
    );

    return this;
  }
}

/// Helper for testing the definition of a cell
sealed class ExpressionTester {
  ExpressionTester();

  /// Create a tester that tests [StubExpression]s.
  factory ExpressionTester.stub() = _StubExpressionTester;

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

  /// Create a tester that tests [FunctionExpression]s.
  ///
  /// This testers tests that the expressions is a [FunctionExpression] defining
  /// a function with a given list of [arguments]. The tester [definition] is
  /// used to test the expression defining the function and [tester] is run
  /// to test the cells local to the function.
  factory ExpressionTester.func({
    required List<CellId> arguments,
    required ExpressionTester definition,
    required FunctionTester tester
  }) = _FunctionExpressionTester;

  /// Create a test that tests [VariableValue] expressions.
  factory ExpressionTester.variable() = _VariableExpressionTester;

  /// Run the test on a given cell definition [expression].
  ///
  /// The difference between this method and [run] is that this method builds
  /// [DeferredExpression]s before calling [run].
  Future<void> test({
    required CellTable scope,
    required CellExpression expression
  }) => switch (expression) {
    final DeferredExpression deferred =>
      run(
          scope: scope,
          expression: deferred.build()
      ),

    _ => run(
        scope: scope,
        expression: expression
    )
  };

  /// Run the test on a given cell definition [expression].
  Future<void> run({
    required CellTable scope,
    required CellExpression expression
  });
}

class _StubExpressionTester extends ExpressionTester {
  @override
  Future<void> run({
    required CellTable scope,
    required CellExpression expression
  }) async =>
      expression is StubExpression;
}

/// [CellRef] expression tester
class _RefExpressionTester extends ExpressionTester {
  final CellId refId;

  _RefExpressionTester(this.refId);

  @override
  Future<void> run({
    required CellTable scope,
    required CellExpression expression
  }) async {
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
  Future<void> run({
    required CellTable scope,
    required CellExpression expression
  }) async {
    expect(expression, isA<CellApplication>());

    final apply = expression as CellApplication;

    await operator.test(
        scope: scope,
        expression: apply.operator
    );

    expect(expression.operands.length, operands.length);

    for (var i = 0; i < operands.length; i++) {
      await operands[i].test(
          scope: scope,
          expression: expression.operands[i]
      );
    }
  }
}

/// [ConstantValue] expression tester
class _ValueExpressionTester extends ExpressionTester {
  final dynamic value;

  _ValueExpressionTester(this.value);

  @override
  Future<void> run({
    required CellTable scope,
    required CellExpression expression
  }) async {
    expect(expression, isA<ConstantValue>());
    expect((expression as ConstantValue).value, equals(value));
  }
}

/// [VariableValue] expression tester
class _VariableExpressionTester extends ExpressionTester {
  @override
  Future<void> run({
    required CellTable scope,
    required CellExpression expression
  }) async => expression is VariableValue;
}

/// [FunctionExpression] tester
class _FunctionExpressionTester extends ExpressionTester {
  final List<CellId> arguments;
  final ExpressionTester definition;

  final FunctionTester tester;

  _FunctionExpressionTester({
    required this.arguments,
    required this.definition,
    required this.tester
  });

  @override
  Future<void> run({
    required CellTable scope,
    required CellExpression expression
  }) async {
    expect(expression, isA<FunctionExpression>());

    final func = expression as FunctionExpression;

    tester._scope = func.scope;
    expect(func.arguments, equals(arguments));

    definition.test(
        scope: func.scope,
        expression: func.definition
    );

    for (final arg in arguments) {
      tester.hasCell(arg);
    }

    await tester.run();
  }
}
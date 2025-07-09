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
    SpecTester? tester,
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
          spec: cell!.definition
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
    SpecTester? tester,
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
    SpecTester? tester,
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
    SpecTester? tester,
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
    SpecTester? tester,
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
    SpecTester? tester,
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
sealed class SpecTester {
  SpecTester();

  /// Create a tester that tests [Stub]s.
  factory SpecTester.stub() = _StubExpressionTester;

  /// Create a tester that tests [CellRef]s.
  ///
  /// [refId] is the ID of the cell that should be referenced.
  factory SpecTester.ref(CellId refId) = _RefExpressionTester;

  /// Create a tester that tests [ApplySpec]s.
  ///
  /// This tester checks whether the definition of the cell is an
  /// [ApplySpec], and runs [operator] on the operator and each tester in
  /// [operands] on the corresponding operand.
  factory SpecTester.apply({
    required SpecTester operator,
    required List<SpecTester> operands
  }) = _ApplyExpressionTester;

  /// Create a tester that checks whether a [ValueSpec] is a constant [value].
  factory SpecTester.value(value) = _ConstantTester;

  /// Create a tester that tests [FunctionExpression]s.
  ///
  /// This testers tests that the expressions is a [FunctionExpression] defining
  /// a function with a given list of [arguments]. The tester [definition] is
  /// used to test the [ValueSpec] defining the function and [tester] is run
  /// to test the cells local to the function.
  factory SpecTester.func({
    required List<CellId> arguments,
    required SpecTester definition,
    required FunctionTester tester
  }) = _FunctionTester;

  /// Create a test that tests [Variable]s.
  factory SpecTester.variable() = _VariableTester;

  /// Run the test on a given cell definition [spec].
  ///
  /// The difference between this method and [run] is that this method builds
  /// [DeferredExpression]s before calling [run].
  Future<void> test({
    required CellTable scope,
    required ValueSpec spec
  }) => switch (spec) {
    final DeferredExpression deferred =>
      run(
          scope: scope,
          spec: deferred.build()
      ),

    _ => run(
        scope: scope,
        spec: spec
    )
  };

  /// Run the test on a given cell definition [spec].
  Future<void> run({
    required CellTable scope,
    required ValueSpec spec
  });
}

class _StubExpressionTester extends SpecTester {
  @override
  Future<void> run({
    required CellTable scope,
    required ValueSpec spec
  }) async =>
      spec is Stub;
}

/// [CellRef] expression tester
class _RefExpressionTester extends SpecTester {
  final CellId refId;

  _RefExpressionTester(this.refId);

  @override
  Future<void> run({
    required CellTable scope,
    required ValueSpec spec
  }) async {
    expect(spec, isA<CellRef>());
    expect((spec as CellRef).get, equals(scope.get(refId)));
  }
}

/// [ApplySpec] tester
class _ApplyExpressionTester extends SpecTester {
  final SpecTester operator;
  final List<SpecTester> operands;

  _ApplyExpressionTester({
    required this.operator,
    required this.operands
  });

  @override
  Future<void> run({
    required CellTable scope,
    required ValueSpec spec
  }) async {
    expect(spec, isA<ApplySpec>());

    final apply = spec as ApplySpec;

    await operator.test(
        scope: scope,
        spec: apply.operator
    );

    expect(spec.operands.length, operands.length);

    for (var i = 0; i < operands.length; i++) {
      await operands[i].test(
          scope: scope,
          spec: spec.operands[i]
      );
    }
  }
}

/// [Constant] tester
class _ConstantTester extends SpecTester {
  final dynamic value;

  _ConstantTester(this.value);

  @override
  Future<void> run({
    required CellTable scope,
    required ValueSpec spec
  }) async {
    expect(spec, isA<Constant>());
    expect((spec as Constant).value, equals(value));
  }
}

/// [Variable] tester
class _VariableTester extends SpecTester {
  @override
  Future<void> run({
    required CellTable scope,
    required ValueSpec spec
  }) async => spec is Variable;
}

/// [FunctionExpression] tester
class _FunctionTester extends SpecTester {
  final List<CellId> arguments;
  final SpecTester definition;

  final FunctionTester tester;

  _FunctionTester({
    required this.arguments,
    required this.definition,
    required this.tester
  });

  @override
  Future<void> run({
    required CellTable scope,
    required ValueSpec spec
  }) async {
    expect(spec, isA<FunctionExpression>());

    final func = spec as FunctionExpression;

    tester._scope = func.scope;
    expect(func.arguments, equals(arguments));

    definition.test(
        scope: func.scope,
        spec: func.definition
    );

    for (final arg in arguments) {
      tester.hasCell(arg);
    }

    await tester.run();
  }
}
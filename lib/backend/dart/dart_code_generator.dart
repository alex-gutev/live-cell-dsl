import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../../builder/index.dart';
import 'dart_compiler.dart';
import 'dart_statement_compiler.dart';
import '../../common/pipeline.dart';

/// Generates code implementing the cells in a given [CellTable].
class DartBackend implements Operation {
  /// The output sink to which the generated code is written
  final StringSink sink;

  DartBackend(this.sink);

  @override
  void run(CellTable scope) {
    for (final cell in scope.cells) {
      _compileCell(cell);
    }
    
    for (final effect in scope.effects) {
      _compileEffect(effect);
    }

    final init = Method((b) => b
      ..name = 'init'
      ..body = Block((b) => b..statements.addAll(_initStatements))
    );

    final effectFields = scope.effects.map((e) => Field((b) => b
      ..name = _compiler.effectVar(e)
      ..modifier = FieldModifier.final$
      ..type = refer('CellWatcher')
      ..late = true
    ));

    final library = Library((b) => b
      ..directives.addAll([
        Directive.import('package:live_cell/runtime/index.dart'),
        Directive.import('package:live_cells_core/live_cells_core.dart')
      ])
      ..body.addAll(_compiler.functions.values.map((fn) => fn.definition))
      ..body.addAll(_cellFields.values)
      ..body.addAll(effectFields)
      ..body.add(Field((b) => b..name = 'cells'
        ..modifier = FieldModifier.final$
        ..assignment = literalMap(
            _cellFields.map((id, f) => MapEntry(id.toString(), refer(f.name))),
            refer('String'),
            refer('ValueCell')
        ).code
      ))
      ..body.add(init));

    final emitter = DartEmitter(useNullSafetySyntax: true);

    final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion
    );

    sink.write(
        formatter.format(
            library.accept(emitter).toString()
        )
    );
  }
  
  // Private

  /// The cell definition compiler
  final _compiler = DartCompiler();

  /// Map of [Field]s holding cell definitions
  final _cellFields = <CellId, Field>{};

  /// List of statements to include in the init function
  final _initStatements = <Code>[];
  
  /// Generate Dart code for a given cell [spec].
  void _compileCell(CellSpec spec) {
    if (spec is! ValueCellSpec && !spec.foldable() && !spec.isExternal()) {
      _cellFields[spec.id] = _makeCell(spec);
    }
  }

  /// Generate a [Field] that implements a given cell [spec].
  Field _makeCell(CellSpec spec) => _cellFields.putIfAbsent(spec.id, () {
    switch (spec.definition) {
      case Stub():
        // TODO: Proper exception type
        throw UnimplementedError();

      case Constant(:final value):
        return Field((b) => b
            ..name = _compiler.cellVar(spec)
            ..modifier = FieldModifier.final$
            ..assignment = refer('ValueCell')
                .property('value')
                .call([literal(value)])
                .code
        );

      case Variable():
        return Field((b) => b
            ..name = _compiler.cellVar(spec)
            ..modifier = FieldModifier.final$
            ..assignment = refer('MutableCell')
                .call([literalNull], {}, [refer('dynamic')])
                .code
        );

      default:
        final visitor = _ArgumentCellVisitor(
            generator: this,
            cell: spec
        );

        spec.definition.accept(visitor);

        final arguments = visitor.arguments
            .map((arg) => refer(_cellFields[arg.id]!.name));

        final valueFn = Method((b) => b
            ..lambda = true
            ..body = _compiler.compile(spec.definition).code
        );

        return Field((b) => b
            ..name = _compiler.cellVar(spec)
            ..modifier = FieldModifier.final$
            ..assignment = refer('ComputeCell')
                .call([], {
                  'arguments': literalSet(arguments),
                  'compute': valueFn.closure
                })
                .property('store')
                .call([])
                .code
        );
    }
  });

  // Effects

  /// Generate Dart code for a given effect [spec].
  void _compileEffect(EffectSpec spec) {
    final statementCompiler = DartStatementCompiler(
        compiler: _compiler
    );
    
    final arguments = <CellSpec>{};
    
    for (final arg in spec.arguments) {
      if (arg is ValueCellSpec || arg.foldable()) {
        arg.definition.accept(
          _ArgumentCellVisitor(
              generator: this,
              cell: arg, 
              arguments: arguments
          )
        );
      }
      else {
        arguments.add(arg);
      }
    }
    
    final statements = _compileEffectStatements(
        compiler: statementCompiler,
        spec: spec
    );

    final argCells = arguments.map((s) => refer(_compiler.cellVar(s)));

    final watcher = literalList(argCells)
        .property('watch')
        .call([
          Method((b) => b
            ..body = Block((b) => b..statements.addAll(
                statements.map((e) => e.statement)
            ))
          ).closure
        ]);

    _initStatements.add(
        refer(_compiler.effectVar(spec))
            .assign(watcher)
            .statement
    );
  }

  /// Generate the list of Dart statements making up the body of the effect
  Iterable<Expression> _compileEffectStatements({
    required DartStatementCompiler compiler,
    required EffectSpec spec
  }) sync* {
    for (final statement in spec.statements) {
      yield* compiler.compile(statement);
    }
  }
}

/// Determines the set of [arguments] reference by a given [ValueSpec].
class _ArgumentCellVisitor extends ValueSpecTreeVisitor {
  final DartBackend generator;

  /// Set of arguments referenced by the visited [ValueSpec].
  final Set<CellSpec> arguments;

  /// Set of all cells that were visited
  final _visited = <CellSpec>{};

  _ArgumentCellVisitor({
    required this.generator,
    required CellSpec cell,
    Set<CellSpec>? arguments
  }) : arguments = arguments ?? {} {
    _visited.add(cell);
  }

  @override
  void visitRef(CellRef spec) {
    _addArgument(spec.get);
  }

  @override
  void visitFunction(FunctionSpec spec) {
    spec.closure.forEach(_addArgument);
  }

  /// Add [cell] to the [arguments] set.
  void _addArgument(CellSpec cell) {
    if (!_visited.contains(cell)) {
      _visited.add(cell);

      if (cell is ValueCellSpec || cell.foldable()) {
        cell.definition.accept(this);
      }
      else {
        generator._makeCell(cell);
        arguments.add(cell);
      }
    }
  }
}
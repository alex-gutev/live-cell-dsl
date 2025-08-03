import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'dart_compiler.dart';
import '../../builder/attributes.dart';
import '../../builder/cell_spec.dart';
import '../../builder/cell_table.dart';
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

    final library = Library((b) => b
      ..directives.addAll([
        Directive.import('package:live_cell/runtime/index.dart'),
        Directive.import('package:live_cells_core/live_cells_core.dart')
      ])
      ..body.addAll(_compiler.functions.values)
      ..body.addAll(_cellFields.values)
      ..body.add(Field((b) => b..name = 'cells'
        ..modifier = FieldModifier.final$
        ..assignment = literalMap(
            _cellFields.map((id, f) => MapEntry(id.toString(), refer(f.name)))
        ).code
      )));

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
                .call([literalNull])
                .code
        );

      default:
        final visitor = _ArgumentCellVisitor(this);
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
}

/// Determines the set of [arguments] reference by a given [ValueSpec].
class _ArgumentCellVisitor extends ValueSpecTreeVisitor {
  final DartBackend generator;

  /// Set of arguments referenced by the visited [ValueSpec].
  final arguments = <CellSpec>{};

  _ArgumentCellVisitor(this.generator);

  @override
  void visitRef(CellRef spec) {
    _addArgument(spec.get);
  }

  @override
  void visitFunction(FunctionSpec spec) {
    spec.referencedCells.forEach(_addArgument);
  }

  /// Add [cell] to the [arguments] set.
  void _addArgument(CellSpec cell) {
    if (cell is ValueCellSpec || cell.foldable()) {
      cell.definition.accept(this);
    }
    else {
      generator._makeCell(cell);
      arguments.add(cell);
    }
  }
}
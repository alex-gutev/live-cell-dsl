import 'dart:io';

import 'package:live_cell/analyzer/index.dart';
import 'package:live_cell/builder/index.dart';
import 'package:live_cell/common/pipeline.dart';
import 'package:live_cell/interpreter/index.dart';
import 'package:live_cell/lexer/lexer.dart';
import 'package:live_cell/modules/index.dart';
import 'package:live_cell/optimization/folding.dart';
import 'package:live_cell/parser/index.dart';
import 'package:live_cells_core/live_cells_core.dart';
import 'package:test/scaffolding.dart';

/// Helper class for testing the cell interpreter
class InterpreterTester {
  /// Global operator table
  final operators = OperatorTable([]);

  /// Build [ValueCell]s from the definitions in [source].
  Future<void> build(List<String> source) async {
    await _builder.build(
      Stream.fromIterable(source)
          .transform(Lexer())
          .transform(Parser(operators))
    );

    final pipeline = Pipeline();

    pipeline.add(SemanticAnalyzer());
    pipeline.add(CellFolder());
    pipeline.run(_builder.scope);

    _interpreter.compile();
  }

  /// Get the [ValueCell] for the cell identified by [id].
  ValueCell get(CellId id) => _interpreter.get(id);

  /// Get the [MutableCell] for the variable cell identified by [id].
  MutableCell getVar(CellId id) => _interpreter.getVar(id);

  /// Return a list containing the values of the cell identified by [id].
  ///
  /// This list is updated whenever the value of the cell changes, even after
  /// this method returns.
  List observe(CellId id) {
    final values = [];
    final cell = get(id);

    final watch = ValueCell.watch(() {
      values.add(cell());
    });

    addTearDown(watch.stop);

    return values;
  }

  // Private

  /// Module search path
  final _modulePath = '${Directory.current.path}/modules';

  late final _builder = CellBuilder(
      operatorTable: operators,
      loadModule: ModuleLoader(
          modulePath: _modulePath,
          operators: operators
      )
  );

  late final _interpreter = Interpreter(_builder.scope);
}
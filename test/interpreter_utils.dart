import 'dart:convert';
import 'dart:io';

import 'package:live_cell/analyzer/index.dart';
import 'package:live_cell/builder/index.dart';
import 'package:live_cell/common/pipeline.dart';
import 'package:live_cell/interpreter/index.dart';
import 'package:live_cell/lexer/lexer.dart';
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
      loadModule: _findModule
  );

  late final _interpreter = Interpreter(_builder.scope);

  /// Find the module identified by [name].
  ModuleSource _findModule(String name) {
    final dir = Directory(_modulePath);

    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('/${name}.lc')) {
        return FileModuleSource(
            name: name,
            source: entity,
            operators: operators
        );
      }
    }

    throw ModuleNotFound(name);
  }
}

/// Loads a module from a given [source] file.
class FileModuleSource extends ModuleSource {
  /// The operator table which should be used while parsing [source].
  final OperatorTable operators;

  /// File containing the source code.
  final File source;

  @override
  Stream<AstNode> get nodes => source.openRead()
      .transform(utf8.decoder)
      .transform(Lexer())
      .transform(Parser(operators));

  const FileModuleSource({
    required super.name,
    required this.source,
    required this.operators
  });
}
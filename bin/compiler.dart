import 'dart:io';

import 'package:live_cell/builder/index.dart';
import 'package:live_cell/common/pipeline.dart';
import 'package:live_cell/modules/index.dart';
import 'package:live_cell/parser/index.dart';
import 'package:live_cell/analyzer/semantic_analyzer.dart';
import 'package:live_cell/backend/dart/dart_code_generator.dart';
import 'package:live_cell/optimization/folding.dart';

/// Manages the compilation process
class Compiler {
  /// Create a [Compiler].
  ///
  /// [modulePath] is the module search path
  Compiler({
    required String modulePath
  }) {
    _moduleLoader = ModuleLoader(
        modulePath: modulePath,
        operators: _operators
    );
  }

  /// Compile a [source] file to an [output] file.
  Future<void> compile({
    required String source,
    required String output
  }) async {
    final module = FileModuleSource(
        name: source,
        source: File(source),
        operators: _operators
    );

    final builder = CellBuilder(
        operatorTable: _operators,
        loadModule: _moduleLoader,
        module: ModuleSpec(source)
    );

    await builder.processSource(module.nodes);

    final outSink = File(output).openWrite();

    try {
      final pipeline = Pipeline()
          .add(SemanticAnalyzer())
          .add(CellFolder())
          .add(DartBackend(outSink));

      pipeline.run(builder.scope);
    }
    finally {
      await outSink.close();
    }
  }
  
  // Private

  /// Global operator table
  final _operators = OperatorTable([]);

  /// Module loader
  late final ModuleLoader _moduleLoader;
}
import 'dart:convert';
import 'dart:io';

import '../builder/index.dart';
import '../lexer/index.dart';
import '../parser/index.dart';

/// Loads a module from a given [source] file.
class FileModuleSource extends ModuleSource {
  /// The operator table which should be used while parsing [source].
  final OperatorTable operators;

  /// File containing the source code.
  final File source;

  @override
  Stream<AstNode> get nodes => source.openRead()
      .transform(utf8.decoder)
      .transform(Lexer(path: source.path))
      .transform(Parser(operators));

  const FileModuleSource({
    required super.name,
    required this.source,
    required this.operators
  });
}
import 'dart:io';

import 'package:live_cell/builder/index.dart';
import 'package:live_cell/parser/index.dart';

import 'file_module_source.dart';

/// Loads modules in a give module path.
class ModuleLoader {
  /// The operator table to use when parsing the module source
  final OperatorTable operators;

  /// Path in which to look for modules
  final String modulePath;

  ModuleLoader({
    required this.modulePath,
    required this.operators
  });

  /// Search for the module identified by [name] in [modulePath].
  ///
  /// If a module identified by [name] is found, a [ModuleSource] is returned,
  /// otherwise a [ModuleNotFound] exception is thrown.
  ModuleSource call(String name) {
    final dir = Directory(modulePath);

    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('/$name.lc')) {
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
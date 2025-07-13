import '../parser/index.dart';
import 'cell_spec.dart';
import 'special_operators.dart';

/// Load module function signature.
///
/// A load module function takes the [name] of the module and
/// should return a [ModuleSource] containing the source code
/// of the module.
///
/// If a module with the given [name] cannot be found, an exception
/// should be thrown.
typedef LoadModule = ModuleSource Function(String name);

/// Base class representing the source code of a module
abstract class ModuleSource {
  /// The name of the module
  final String name;

  /// The [AstNode]s of the declarations in the module
  Stream<AstNode> get nodes;

  const ModuleSource({
    required this.name,
  });
}

/// Module specification
class ModuleSpec {
  /// Path to the main source file of the module
  final String? path;

  /// Maps string identifiers to [CellId]s.
  final Map<String, NamedCellId> aliases;

  /// Set of identifiers exported by this module
  final Set<NamedCellId> exports;
  
  ModuleSpec(this.path, {
    Set<NamedCellId>? exports,
    Map<String, NamedCellId>? aliases,
  }) : exports = exports ?? {},
    aliases = aliases ?? {};

  /// Get a [CellId] for a given [name].
  ///
  /// If [name] is the name of an alias in [aliases], the aliased identifier
  /// is returned. Otherwise a new identifier in this module is returned.
  NamedCellId namedId(String name) =>
      aliases[name] ?? NamedCellId(name, module: path);

  /// Create aliases for all identifier exported by [module] into this module.
  void importAll(ModuleSpec module) {
    for (final id in module.exports) {
      if (aliases.containsKey(id.name)) {
        // TODO: Proper exception type
        throw Exception('Conflicting import');
      }
      else {
        aliases[id.name] = id;
      }
    }
  }
}

/// The core module containing the special operators.
final kCoreModule = ModuleSpec('live_cell.core',
  exports: Operators.operatorIds
);